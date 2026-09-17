import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/app_call.dart';
import '../services/agora_config.dart';
import '../theme/app_theme.dart';
import '../widgets/group_avatar.dart';
import '../widgets/neon_backdrop.dart';
import '../l10n/l10n.dart';

/// Занги гурӯҳӣ — ҳамаи аъзоён ба як канали Agora ҳамроҳ мешаванд.
///
/// Фарқи он аз занги шахсӣ дар ду чиз аст: канал аз рӯи гурӯҳ сохта мешавад,
/// на аз рӯи як ҳуҷҷати занг, ва барои ҳар узв як ҳуҷҷати `calls` сохта
/// мешавад, то занг дар дастгоҳи ҳар кадоми онҳо садо диҳад.
class GroupCallScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final CallType type;

  /// Ҳангоми оғоз кардани занг — номи аъзоён, то ба ҳар кадом ҳуҷҷат сохта шавад.
  final Map<String, String> memberNames;

  /// Ҳангоми ҳамроҳ шудан ба занги мавҷуда — канали умумии он.
  final String? joinChannelId;

  const GroupCallScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.type,
    this.memberNames = const {},
    this.joinChannelId,
  });

  bool get isStarter => joinChannelId == null;

  @override
  State<GroupCallScreen> createState() => _GroupCallScreenState();
}

class _GroupCallScreenState extends State<GroupCallScreen> {
  RtcEngine? _engine;
  String? _channelId;
  String? _error;
  final Set<int> _remoteUids = {};
  final List<DocumentReference<Map<String, dynamic>>> _createdCalls = [];

  Timer? _durationTimer;
  int _seconds = 0;
  bool _joined = false;
  bool _muted = false;
  bool _speakerOn = true;
  bool _videoOn = true;
  bool _finalized = false;

  String get _currentUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _videoOn = widget.type == CallType.video;
    _start();
  }

  Future<void> _start() async {
    final camGranted =
        widget.type == CallType.video ? await Permission.camera.request() : PermissionStatus.granted;
    final micGranted = await Permission.microphone.request();
    if (widget.type == CallType.video && !camGranted.isGranted) {
      setState(() => _error = tr('k013'));
      return;
    }
    if (!micGranted.isGranted) {
      setState(() => _error = tr('k014'));
      return;
    }

    _channelId = widget.joinChannelId ??
        'group_${widget.groupId}_${DateTime.now().millisecondsSinceEpoch}';

    if (widget.isStarter) await _ringMembers();
    await _joinChannel();
  }

  /// Барои ҳар узви дигар як ҳуҷҷати занг — то дар дастгоҳи ӯ занг садо диҳад.
  Future<void> _ringMembers() async {
    final myName = widget.memberNames[_currentUid] ?? tr('k015');
    final calls = FirebaseFirestore.instance.collection('calls');
    for (final entry in widget.memberNames.entries) {
      if (entry.key == _currentUid) continue;
      try {
        final doc = await calls.add(AppCall.newGroupCallMap(
          callerId: _currentUid,
          callerName: myName,
          calleeId: entry.key,
          calleeName: entry.value,
          type: widget.type,
          channelId: _channelId!,
          groupId: widget.groupId,
          groupName: widget.groupName,
        ));
        _createdCalls.add(doc);
      } catch (_) {
        // Як узв ҷавоб надод — занг барои дигарон бояд идома ёбад.
      }
    }
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
        onJoinChannelSuccess: (connection, elapsed) {
          if (!mounted) return;
          setState(() => _joined = true);
          _durationTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
            if (mounted) setState(() => _seconds++);
          });
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          if (!mounted) return;
          setState(() => _remoteUids.add(remoteUid));
        },
        onUserOffline: (connection, remoteUid, reason) {
          if (!mounted) return;
          setState(() => _remoteUids.remove(remoteUid));
        },
        onError: (err, msg) {
          if (!mounted) return;
          setState(() => _error = trf('k016', [msg]));
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
    } catch (e) {
      if (mounted) setState(() => _error = trf('k017', [e]));
    }
  }

  Future<void> _endCall() async {
    if (_finalized) return;
    _finalized = true;
    _durationTimer?.cancel();

    // Ҳуҷҷатҳое, ки худам сохтам, бояд аз ҳолати «занг мезанад» бароянд —
    // вагарна дар дастгоҳи аъзоён занг то абад садо медиҳад.
    for (final doc in _createdCalls) {
      await doc.update({
        'outcome': (_remoteUids.isEmpty ? CallOutcome.missed : CallOutcome.completed).name,
        'durationSeconds': _seconds,
      }).catchError((_) {});
    }

    try {
      await _engine?.leaveChannel();
      await _engine?.release();
    } catch (_) {}

    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    if (!_finalized) {
      _finalized = true;
      for (final doc in _createdCalls) {
        doc.update({
          'outcome': (_remoteUids.isEmpty ? CallOutcome.missed : CallOutcome.completed).name,
          'durationSeconds': _seconds,
        }).catchError((_) {});
      }
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
            const NeonBackdrop(child: SizedBox.expand()),
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  GroupAvatar(size: 72),
                  const SizedBox(height: 12),
                  Text(
                    widget.groupName,
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 20),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _error ??
                        (_joined
                            ? '${_formatDuration(_seconds)} · ${trf('k291', [_remoteUids.length + 1])}'
                            : tr('k292')),
                    style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.9), fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Expanded(child: _buildGrid(isVideo)),
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
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: _endCall,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.redAccent),
                      child: const Icon(LucideIcons.phone_off, color: Colors.white, size: 26),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Тӯри иштирокчиён: барои видео — тасвир, барои садо — нишона.
  Widget _buildGrid(bool isVideo) {
    final engine = _engine;
    final tiles = <Widget>[];

    if (engine != null && isVideo && _videoOn) {
      tiles.add(AgoraVideoView(
        controller: VideoViewController(rtcEngine: engine, canvas: const VideoCanvas(uid: 0)),
      ));
    } else {
      tiles.add(_audioTile(LucideIcons.user));
    }

    for (final uid in _remoteUids) {
      if (engine != null && isVideo) {
        tiles.add(AgoraVideoView(
          controller: VideoViewController.remote(
            rtcEngine: engine,
            canvas: VideoCanvas(uid: uid),
            connection: RtcConnection(channelId: _channelId),
          ),
        ));
      } else {
        tiles.add(_audioTile(LucideIcons.user));
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.count(
        crossAxisCount: tiles.length <= 1 ? 1 : 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: tiles
            .map((tile) => ClipRRect(borderRadius: BorderRadius.circular(14), child: tile))
            .toList(),
      ),
    );
  }

  Widget _audioTile(IconData icon) {
    return Container(
      color: AppColors.surface,
      alignment: Alignment.center,
      child: Icon(icon, color: AppColors.textSecondary, size: 34),
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
          color: active ? AppColors.neonEmerald : Colors.white.withValues(alpha: 0.15),
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: active ? AppColors.background : Colors.white, size: 22),
      ),
    );
  }
}
