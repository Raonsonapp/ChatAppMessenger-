import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

import '../theme/app_theme.dart';
import '../models/app_call.dart';
import '../services/agora_config.dart';
import '../widgets/neon_backdrop.dart';

enum _CallStage { connecting, ringing, connected, ended }

/// Экрани занги воқеӣ — садо/видео тавассути Agora RTC интиқол мешавад.
/// Занговар (caller) ҳуҷҷати нав дар `calls` месозад ва ба канал ҳамроҳ
/// мешавад; гиранда (callee) бо [existingCallId] ба ҳамон канал ҳамроҳ
/// мешавад. Пайвастшавӣ бо рӯйдоди воқеии onUserJoined муайян мешавад.
class CallScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final CallType type;
  final String? existingCallId;
  const CallScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    required this.type,
    this.existingCallId,
  });

  bool get isCaller => existingCallId == null;

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  _CallStage _stage = _CallStage.connecting;
  String? _error;
  RtcEngine? _engine;
  String? _channelId;
  int? _remoteUid;
  Timer? _ringTimeout;
  Timer? _durationTimer;
  int _seconds = 0;
  bool _muted = false;
  bool _speakerOn = true;
  bool _videoOn = true;
  bool _everConnected = false;
  bool _finalized = false;
  DocumentReference<Map<String, dynamic>>? _callDoc;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _callDocSub;

  String get _currentUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _videoOn = widget.type == CallType.video;
    _start();
  }

  Future<void> _start() async {
    final camGranted = widget.type == CallType.video ? await Permission.camera.request() : PermissionStatus.granted;
    final micGranted = await Permission.microphone.request();
    if (!camGranted.isGranted && widget.type == CallType.video) {
      setState(() => _error = 'Барои занги видеоӣ иҷозати камера лозим аст');
      return;
    }
    if (!micGranted.isGranted) {
      setState(() => _error = 'Барои занг иҷозати микрофон лозим аст');
      return;
    }

    if (widget.isCaller) {
      final myName = FirebaseAuth.instance.currentUser?.displayName ?? 'Ман';
      final doc = await FirebaseFirestore.instance.collection('calls').add(
        AppCall.newCallMap(
          callerId: _currentUid,
          callerName: myName,
          calleeId: widget.otherUserId,
          calleeName: widget.otherUserName,
          type: widget.type,
        ),
      );
      _callDoc = doc;
      _channelId = doc.id;
    } else {
      _channelId = widget.existingCallId;
      _callDoc = FirebaseFirestore.instance.collection('calls').doc(_channelId);
    }

    _watchCallDoc();
    await _joinChannel();

    if (widget.isCaller) {
      setState(() => _stage = _CallStage.ringing);
      _ringTimeout = Timer(const Duration(seconds: 45), () {
        if (!_everConnected) _endCall(outcome: CallOutcome.missed);
      });
    }
  }

  void _watchCallDoc() {
    _callDocSub = _callDoc?.snapshots().listen((snap) {
      final outcome = snap.data()?['outcome'] as String?;
      if (!_everConnected && (outcome == 'declined' || outcome == 'missed')) {
        _endCall(outcome: null, alreadyFinalizedRemotely: true);
      }
    });
  }

  Future<void> _joinChannel() async {
    try {
      final engine = createAgoraRtcEngine();
      _engine = engine;
      await engine.initialize(RtcEngineContext(
        appId: kAgoraAppId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      engine.registerEventHandler(RtcEngineEventHandler(
        onUserJoined: (connection, remoteUid, elapsed) {
          _ringTimeout?.cancel();
          if (!mounted) return;
          setState(() {
            _remoteUid = remoteUid;
            _stage = _CallStage.connected;
            _everConnected = true;
          });
          _durationTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
            if (mounted) setState(() => _seconds++);
          });
        },
        onUserOffline: (connection, remoteUid, reason) {
          if (!mounted) return;
          _endCall(outcome: CallOutcome.completed);
        },
        onError: (err, msg) {
          if (!mounted) return;
          setState(() => _error = 'Хатои занг: $msg');
        },
      ));

      await engine.enableAudio();
      if (widget.type == CallType.video) {
        await engine.enableVideo();
        await engine.startPreview();
      }
      await engine.setEnableSpeakerphone(_speakerOn);

      await engine.joinChannel(
        token: '',
        channelId: _channelId!,
        uid: 0,
        options: ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishCameraTrack: widget.type == CallType.video,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ),
      );

      if (!widget.isCaller && mounted) {
        setState(() => _stage = _CallStage.connecting);
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Пайваст нашуд: $e');
    }
  }

  Future<void> _endCall({CallOutcome? outcome, bool alreadyFinalizedRemotely = false}) async {
    if (_finalized) return;
    _finalized = true;
    _ringTimeout?.cancel();
    _durationTimer?.cancel();
    await _callDocSub?.cancel();

    if (!alreadyFinalizedRemotely) {
      final finalOutcome = outcome ?? (_everConnected ? CallOutcome.completed : (widget.isCaller ? CallOutcome.missed : CallOutcome.declined));
      await _callDoc?.update({
        'outcome': finalOutcome.name,
        'durationSeconds': _seconds,
      });
    }

    try {
      await _engine?.leaveChannel();
      await _engine?.release();
    } catch (_) {}

    if (mounted) {
      setState(() => _stage = _CallStage.ended);
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _ringTimeout?.cancel();
    _durationTimer?.cancel();
    _callDocSub?.cancel();
    if (!_finalized) {
      _finalized = true;
      _callDoc?.update({
        'outcome': (_everConnected ? CallOutcome.completed : (widget.isCaller ? CallOutcome.missed : CallOutcome.declined)).name,
        'durationSeconds': _seconds,
      });
      _engine?.leaveChannel();
      _engine?.release();
    }
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = widget.type == CallType.video;
    final connected = _stage == _CallStage.connected;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _endCall();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (isVideo && connected && _remoteUid != null && _engine != null)
              AgoraVideoView(
                controller: VideoViewController.remote(
                  rtcEngine: _engine!,
                  canvas: VideoCanvas(uid: _remoteUid),
                  connection: RtcConnection(channelId: _channelId),
                ),
              )
            else
              const NeonBackdrop(child: SizedBox.expand()),
            SafeArea(
              child: Column(
                children: [
                  if (!(isVideo && connected)) ...[
                    const SizedBox(height: 40),
                    Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.neonGradient),
                      child: Center(
                        child: Text(
                          widget.otherUserName.isNotEmpty ? widget.otherUserName[0].toUpperCase() : '?',
                          style: const TextStyle(color: AppColors.background, fontWeight: FontWeight.w800, fontSize: 48),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Text(
                    widget.otherUserName,
                    style: TextStyle(
                      color: (isVideo && connected) ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      shadows: (isVideo && connected) ? [const Shadow(blurRadius: 8, color: Colors.black)] : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error ??
                        (connected
                            ? _formatDuration(_seconds)
                            : (widget.isCaller ? (isVideo ? 'Занги видеоӣ...' : 'Занг мезанад...') : 'Пайваст шудан...')),
                    style: TextStyle(
                      color: (isVideo && connected) ? Colors.white70 : AppColors.textSecondary.withOpacity(0.85),
                      fontSize: 14.5,
                    ),
                  ),
                  const Spacer(),
                  if (isVideo && connected && _videoOn && _engine != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 16, bottom: 16),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: 100,
                          height: 140,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: AgoraVideoView(
                            controller: VideoViewController(
                              rtcEngine: _engine!,
                              canvas: const VideoCanvas(uid: 0),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _controlButton(
                          icon: _muted ? LucideIcons.mic_off : LucideIcons.mic,
                          active: _muted,
                          onTap: () {
                            setState(() => _muted = !_muted);
                            _engine?.muteLocalAudioStream(_muted);
                          },
                        ),
                        if (isVideo)
                          _controlButton(
                            icon: _videoOn ? LucideIcons.video : LucideIcons.video_off,
                            active: !_videoOn,
                            onTap: () {
                              setState(() => _videoOn = !_videoOn);
                              _engine?.enableLocalVideo(_videoOn);
                            },
                          ),
                        if (isVideo)
                          _controlButton(
                            icon: LucideIcons.refresh_cw,
                            active: false,
                            onTap: () => _engine?.switchCamera(),
                          ),
                        _controlButton(
                          icon: LucideIcons.volume_2,
                          active: _speakerOn,
                          onTap: () {
                            setState(() => _speakerOn = !_speakerOn);
                            _engine?.setEnableSpeakerphone(_speakerOn);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  GestureDetector(
                    onTap: () => _endCall(),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.redAccent),
                      child: const Icon(LucideIcons.phone_off, color: Colors.white, size: 26),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _controlButton({required IconData icon, required bool active, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? AppColors.neonEmerald : Colors.white.withOpacity(0.15),
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: active ? AppColors.background : Colors.white, size: 22),
      ),
    );
  }
}
