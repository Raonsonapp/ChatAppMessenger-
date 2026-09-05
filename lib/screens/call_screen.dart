import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_theme.dart';
import '../models/app_call.dart';
import '../widgets/neon_backdrop.dart';

/// Экрани занг — тарҳи пурраи UI-и WhatsApp (занг задан → пайвастшавӣ →
/// суҳбат бо вақтсанҷ → қатъ кардан), бо сабти воқеии таърих дар Firestore.
/// ЭЗОҲ: интиқоли воқеии садо/видео (WebRTC) дар ин лоиҳа пайваст нашудааст —
/// он ба хидмати сигналии беруна ниёз дорад. Ин экран UI-и пурра ва
/// таърихи воқеии зангро таъмин мекунад.
class CallScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final CallType type;
  const CallScreen({super.key, required this.otherUserId, required this.otherUserName, required this.type});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

enum _CallStage { ringing, connected, ended }

class _CallScreenState extends State<CallScreen> {
  _CallStage _stage = _CallStage.ringing;
  Timer? _ringTimer;
  Timer? _durationTimer;
  int _seconds = 0;
  bool _muted = false;
  bool _speakerOn = false;
  bool _videoOn = true;
  DocumentReference<Map<String, dynamic>>? _callDoc;
  bool _ended = false;

  String get _currentUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _videoOn = widget.type == CallType.video;
    _startCall();
  }

  Future<void> _startCall() async {
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

    _ringTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted || _ended) return;
      setState(() => _stage = _CallStage.connected);
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _seconds++);
      });
    });
  }

  Future<void> _endCall({CallOutcome? forcedOutcome}) async {
    if (_ended) return;
    _ended = true;
    _ringTimer?.cancel();
    _durationTimer?.cancel();
    final outcome = forcedOutcome ?? (_stage == _CallStage.connected ? CallOutcome.completed : CallOutcome.missed);
    await _callDoc?.update({
      'outcome': outcome.name,
      'durationSeconds': _seconds,
    });
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _ringTimer?.cancel();
    _durationTimer?.cancel();
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
        backgroundColor: AppColors.background,
        body: NeonBackdrop(
          child: SafeArea(
            child: Column(
              children: [
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
                Text(
                  widget.otherUserName,
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  _stage == _CallStage.ringing
                      ? (isVideo ? 'Занги видеоӣ...' : 'Занг мезанад...')
                      : _formatDuration(_seconds),
                  style: TextStyle(color: AppColors.textSecondary.withOpacity(0.85), fontSize: 14.5),
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
                        onTap: () => setState(() => _muted = !_muted),
                      ),
                      if (isVideo)
                        _controlButton(
                          icon: _videoOn ? LucideIcons.video : LucideIcons.video_off,
                          active: !_videoOn,
                          onTap: () => setState(() => _videoOn = !_videoOn),
                        ),
                      _controlButton(
                        icon: LucideIcons.volume_2,
                        active: _speakerOn,
                        onTap: () => setState(() => _speakerOn = !_speakerOn),
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
          color: active ? AppColors.neonEmerald : AppColors.glassFill,
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Icon(icon, color: active ? AppColors.background : AppColors.textPrimary, size: 22),
      ),
    );
  }
}
