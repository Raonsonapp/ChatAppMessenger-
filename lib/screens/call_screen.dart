import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:floating/floating.dart';

import '../theme/app_theme.dart';
import '../models/app_call.dart';
import '../widgets/neon_backdrop.dart';
import '../l10n/l10n.dart';
import '../widgets/user_avatar.dart';
import '../theme/app_scope.dart';
import '../services/push_service.dart';
import '../services/call_error.dart';
import '../services/agora_token_service.dart';
import '../utils/agora_token_error.dart';
import '../services/agora_engine_manager.dart';

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
    // Ҳар хатои ин ҷо пештар ба ҳељ ҷо намерасид: экран дар ҳолати аввала
    // мемонд ва корбар намедонист, ки чаро занг намеравад.
    try {
      await _startCall();
    } catch (e) {
      if (mounted) setState(() => _error = trf('k017', [e]));
    }
  }

  Future<void> _startCall() async {
    final camGranted = widget.type == CallType.video ? await Permission.camera.request() : PermissionStatus.granted;
    final micGranted = await Permission.microphone.request();
    if (!mounted) return;
    if (!camGranted.isGranted && widget.type == CallType.video) {
      setState(() => _error = tr('k013'));
      return;
    }
    if (!micGranted.isGranted) {
      setState(() => _error = tr('k014'));
      return;
    }

    if (widget.isCaller) {
      final myName = FirebaseAuth.instance.currentUser?.displayName ?? tr('k015');
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

      // Бе ин занг ТАНҲО он вақт садо медиҳад, ки барномаи гиранда кушода
      // бошад. Тамоми системаи огоҳиномаи занг (экрани пурра, тугмаҳои
      // «Қабул»/«Рад») сохта шуда буд, вале ҳељ кас онро намефиристод —
      // яъне дар ҳаёти воқеӣ занг ҳељ гоҳ намерасид.
      unawaited(_ringCallee(doc.id, myName));
    } else {
      _channelId = widget.existingCallId;
      _callDoc = FirebaseFirestore.instance.collection('calls').doc(_channelId);
    }

    if (!mounted) return;
    _watchCallDoc();
    await _joinChannel();

    if (widget.isCaller && mounted) {
      setState(() => _stage = _CallStage.ringing);
      _ringTimeout = Timer(const Duration(seconds: 45), () {
        if (!_everConnected) _endCall(outcome: CallOutcome.missed);
      });
    }
  }

  /// Ба гиранда огоҳиномаи занг мефиристад.
  ///
  /// Хатогии он набояд худи зангро вайрон кунад: шояд гиранда барномаро
  /// кушода бошад ва зангро аз IncomingCallListener гирад.
  Future<void> _ringCallee(String callId, String callerName) async {
    try {
      await PushService.notify(
        toUid: widget.otherUserId,
        title: callerName,
        body: widget.type == CallType.video ? tr('k121') : tr('k122'),
        data: {
          'type': 'incoming_call',
          'callId': callId,
          'callerId': _currentUid,
          'callerName': callerName,
          'callType': widget.type == CallType.video ? 'video' : 'audio',
        },
      );
    } catch (_) {
      // Огоҳинома нарасид — вале занг ба ҳар ҳол давом мекунад.
    }
  }

  /// Ба гиранда хабар медиҳад, ки занги ҷавобнадодашуда буд.
  Future<void> _notifyMissed() async {
    final myName = FirebaseAuth.instance.currentUser?.displayName ?? tr('k015');
    try {
      await PushService.notify(
        toUid: widget.otherUserId,
        title: myName,
        body: widget.type == CallType.video ? tr('k401') : tr('k402'),
        data: {
          'type': 'missed_call',
          'callId': _channelId ?? '',
          'callerId': _currentUid,
          'callerName': myName,
          'callType': widget.type == CallType.video ? 'video' : 'audio',
        },
      );
    } catch (_) {
      // Огоҳинома нарасид — занг ба ҳар ҳол дар таърих мемонад.
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

  /// Оё аллакай як бори дигар кӯшиш кардем? Бознамоии беохир лозим нест.
  bool _retriedJoin = false;

  /// Муҳаррикро пурра озод карда, аз нав ҳамроҳ мешавад.
  Future<void> _retryJoin() async {
    await _cancelPip();
    _engine = null;
    await AgoraEngineManager.disposeActive();
    if (!mounted || _finalized) return;
    await _joinChannel();
  }

  /// Token-и нав мегирад ва ба Agora медиҳад.
  ///
  /// Бе ин занги аз як соат дарозтар дар миёна қатъ мешавад.
  Future<void> _renewToken() async {
    final channelId = _channelId;
    if (channelId == null) return;
    try {
      final fresh = await AgoraTokenService.fetch(channelId);
      final token = fresh.token;
      if (token != null) await _engine?.renewToken(token);
    } catch (_) {
      // Навкунӣ нашуд — занг то мӯҳлати token давом мекунад.
    }
  }

  /// Хатои гузоштани роҳи садо набояд худи зангро вайрон кунад.
  Future<void> _applySpeakerRoute() async {
    try {
      await _engine?.setEnableSpeakerphone(_speakerOn);
    } catch (_) {
      // Дар баъзе дастгоҳҳо (гарнитураи Bluetooth ва ғ.) ин кор намекунад.
    }
  }

  Future<void> _joinChannel() async {
    try {
      // Token ва App ID аз сервер гирифта мешаванд: App Certificate калиди
      // махфист ва дар барнома намемонад. Сервер ҳамчунин месанҷад, ки оё ин
      // корбар ҳақ дорад ба ин канал дарояд.
      final AgoraCredentials credentials;
      try {
        credentials = await AgoraTokenService.fetch(_channelId!);
      } on AgoraTokenFailure catch (failure) {
        if (mounted) setState(() => _error = describeAgoraTokenError(failure));
        return;
      }
      if (!mounted) return;

      // Муҳаррик тавассути идоракунанда сохта мешавад: он кӯҳнаро ҲАМЕША
      // озод мекунад. Бе ин занги дуюм хатои -17 мегирифт — Agora мегӯяд
      // «аллакай дар канал».
      final engine = await AgoraEngineManager.create(RtcEngineContext(
        appId: credentials.appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));
      if (!mounted) {
        await AgoraEngineManager.disposeActive();
        return;
      }
      _engine = engine;

      engine.registerEventHandler(RtcEngineEventHandler(
        // Роҳи садо (динамик) танҳо ПАС АЗ ҳамроҳ шудан ба канал гузошта
        // мешавад: пеш аз он модули садо ҳанӯз фаъол нест ва Agora хатои
        // ERR_NOT_READY (-3) медиҳад — маҳз ҳамин занг заданро вайрон мекард.
        onJoinChannelSuccess: (connection, elapsed) {
          _applySpeakerRoute();
          // PiP танҳо пас аз ҳамроҳ шудан маъно дорад.
          _preparePip();
        },
        // Token мӯҳлат дорад. Занги дароз бе навкунӣ дар миёна қатъ мешуд.
        onTokenPrivilegeWillExpire: (connection, token) {
          _renewToken();
        },
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
        // Agora хатои token-ро аксар вақт маҳз аз ин ҷо хабар медиҳад,
        // на аз `onError`. Бе ин экран то абад «Пайваст мешавад…» мемонад.
        onConnectionStateChanged: (connection, state, reason) {
          if (!mounted || !CallError.isFatalReason(reason)) return;
          setState(() => _error = CallError.describeReason(reason));
        },
        onError: (err, msg) {
          // Танҳо хатои ҷиддӣ зангро қатъ мекунад. Пештар ҳар огоҳии хурд
          // (масалан гарнитураи Bluetooth) занги солимро «вайрон» нишон
          // медод.
          if (!mounted || !CallError.isFatal(err)) return;

          // «Аллакай дар канал» — ҳолати боқимондаи муҳаррик. Як бор
          // худкор аз нав кӯшиш мекунем: барои корбар ин назар ба
          // хатои фаҳмонашаванда хеле беҳтар аст.
          if (err == ErrorCodeType.errJoinChannelRejected && !_retriedJoin) {
            _retriedJoin = true;
            _retryJoin();
            return;
          }
          setState(() => _error = CallError.describe(err, msg));
        },
      ));

      await engine.enableAudio();
      if (widget.type == CallType.video) {
        await engine.enableVideo();
        await engine.startPreview();
      }

      await engine.joinChannel(
        token: credentials.tokenOrEmpty,
        channelId: _channelId!,
        uid: credentials.uid,
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
      if (mounted) setState(() => _error = trf('k017', [e]));
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
      try {
        await _callDoc?.update({
          'outcome': finalOutcome.name,
          'durationSeconds': _seconds,
        });
      } catch (_) {}

      // Занги ҷавобнадодашуда бояд НАМОЁН бошад: бе огоҳинома гиранда ҳељ
      // гоҳ намефаҳмад, ки ба ӯ занг зада буданд.
      if (finalOutcome == CallOutcome.missed && widget.isCaller) {
        unawaited(_notifyMissed());
      }
    }

    _engine = null;
    await AgoraEngineManager.disposeActive();

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
    }
    // Бе ин барнома пас аз занг ҳам ҳангоми баромадан хурд мешавад.
    _cancelPip();
    // Муҳаррик ҲАМЕША озод карда мешавад, на танҳо ҳангоми қатъи оддӣ.
    //
    // Пештар он танҳо дар дохили `if (!_finalized)` озод мешуд: агар экран
    // пас аз қатъи занг ё ҳангоми хато пӯшида мешуд, муҳаррик зинда мемонд
    // ва занги оянда хатои -17 мегирифт.
    _engine = null;
    AgoraEngineManager.disposeActiveUnawaited();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
    final isVideo = widget.type == CallType.video;
    final connected = _stage == _CallStage.connected;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _endCall();
      },
      // Дар реҷаи тирезаи хурд танҳо видео нишон дода мешавад: тугмаҳо дар
      // чунин андоза истифоданашавандаанд ва танҳо ҷойро мегиранд.
      child: PiPSwitcher(
        childWhenEnabled: Container(
          color: Colors.black,
          child: (isVideo && connected && _remoteUid != null && _engine != null)
              ? _videoView(large: true)
              : const SizedBox.expand(),
        ),
        childWhenDisabled: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (isVideo && connected && _remoteUid != null && _engine != null)
              // Зер кардани тирезаи хурд ҷойҳоро иваз мекунад.
              _videoView(large: true)
            else
              const NeonBackdrop(child: SizedBox.expand()),
            SafeArea(
              child: Column(
                children: [
                  if (!(isVideo && connected)) ...[
                    const SizedBox(height: 40),
                    UserAvatar(name: widget.otherUserName, uid: widget.otherUserId, size: 120),
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
                            : (widget.isCaller ? (isVideo ? tr('k018') : tr('k019')) : tr('k020'))),
                    style: TextStyle(
                      color: (isVideo && connected) ? Colors.white70 : AppColors.textSecondary.withValues(alpha: 0.85),
                      fontSize: 14.5,
                    ),
                  ),
                  const Spacer(),
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
                            _applySpeakerRoute();
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
            // Тирезаи хурд дар БОЛОИ ҳама: онро кашидан ва зер кардан
            // мумкин аст, бинобар ин он набояд зери тугмаҳо монад.
            if (isVideo && connected && _videoOn && _engine != null)
              _floatingVideo(context),
          ],
        ),
        ),
      ),
    );
  }

  /// Реҷаи тирезаи хурди система (PiP).
  ///
  /// Ба корбар имкон медиҳад, ки ҳангоми занг барномаро тарк кунад ва
  /// видео дар гӯшаи экран боқӣ монад — мисли WhatsApp.
  final Floating _floating = Floating();
  bool _pipReady = false;

  /// Реҷаи PiP-ро омода мекунад: ҳангоми баромадан аз барнома система
  /// худаш тирезаро хурд мекунад.
  Future<void> _preparePip() async {
    if (widget.type != CallType.video) return;
    try {
      if (!await _floating.isPipAvailable) return;
      await _floating.enable(const OnLeavePiP(
        // 9:16 — видеои занг амудӣ аст.
        aspectRatio: Rational(9, 16),
      ));
      _pipReady = true;
    } catch (_) {
      // Дар баъзе дастгоҳҳо PiP нест — занг ба ҳар ҳол кор мекунад.
    }
  }

  Future<void> _cancelPip() async {
    if (!_pipReady) return;
    _pipReady = false;
    try {
      await _floating.cancelOnLeavePiP();
    } catch (_) {}
  }

  /// Кадом видео дар тирезаи калон аст — худам ё ҳамсӯҳбат.
  ///
  /// Зер кардани тирезаи хурд ҷойҳоро иваз мекунад, ҳамон тавре ки дар
  /// WhatsApp.
  bool _selfIsLarge = false;

  /// Гӯшаи тирезаи хурд: 0 — рости боло, 1 — рости поён, 2 — чапи поён,
  /// 3 — чапи боло.
  int _corner = 1;

  Widget _videoView({required bool large}) {
    final engine = _engine;
    if (engine == null) return const SizedBox.shrink();

    // Тирезаи калон: агар ҷойҳо иваз шуда бошанд, дар он ҷо ХУДАМ ҳастам.
    final showSelf = large ? _selfIsLarge : !_selfIsLarge;

    if (showSelf) {
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: engine,
          canvas: const VideoCanvas(uid: 0),
        ),
      );
    }

    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: engine,
        canvas: VideoCanvas(uid: _remoteUid),
        connection: RtcConnection(channelId: _channelId),
      ),
    );
  }

  /// Тирезаи хурди видео — кашиданашаванда ва зершаванда.
  Widget _floatingVideo(BuildContext context) {
    const width = 104.0;
    const height = 146.0;
    const margin = 16.0;

    final padding = MediaQuery.of(context).padding;

    // Ҷойгиршавӣ аз гӯша ҳисоб мешавад, на аз координатаҳои сахт — вагарна
    // дар экранҳои гуногун ҷои нодуруст мешавад.
    final top = _corner == 0 || _corner == 3;
    final left = _corner == 2 || _corner == 3;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      top: top ? padding.top + margin + 56 : null,
      bottom: top ? null : padding.bottom + margin + 150,
      left: left ? margin : null,
      right: left ? null : margin,
      child: GestureDetector(
        // Зер кардан — иваз кардани ҷойҳо.
        onTap: () => setState(() => _selfIsLarge = !_selfIsLarge),
        // Кашидан — гузаштан ба гӯшаи наздиктарин.
        onPanEnd: (details) {
          final velocity = details.velocity.pixelsPerSecond;
          setState(() {
            final goLeft = velocity.dx < -120 || (velocity.dx <= 120 && left);
            final goTop = velocity.dy < -120 || (velocity.dy <= 120 && top);
            _corner = goTop ? (goLeft ? 3 : 0) : (goLeft ? 2 : 1);
          });
        },
        child: Container(
          width: width,
          height: height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white24),
            boxShadow: const [
              BoxShadow(color: Colors.black38, blurRadius: 12),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _videoView(large: false),
              // Ишораи хурд, ки тирезаро зер кардан мумкин аст.
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(LucideIcons.repeat,
                      size: 11, color: Colors.white70),
                ),
              ),
            ],
          ),
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
          color: active ? AppColors.neonEmerald : Colors.white.withValues(alpha: 0.15),
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: active ? AppColors.background : Colors.white, size: 22),
      ),
    );
  }
}
