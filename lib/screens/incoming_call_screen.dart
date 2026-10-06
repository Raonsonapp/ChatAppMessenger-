import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_theme.dart';
import '../models/app_call.dart';
import '../widgets/neon_backdrop.dart';
import 'call_screen.dart';
import 'group_call_screen.dart';
import '../l10n/l10n.dart';
import '../widgets/user_avatar.dart';
import '../theme/app_scope.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/ringtone_service.dart';

/// Экрани занги воридотӣ — намоён мешавад вақте ки корбари дигар занг
/// мезанад (тавассути IncomingCallListener). Қабул → CallScreen (ба ҳамон
/// канали Agora ҳамроҳ мешавад); Рад → ҳуҷҷати calls/{id} 'declined' мешавад.
class IncomingCallScreen extends StatefulWidget {
  final String callId;
  final String callerId;
  final String callerName;
  final CallType type;

  /// Барои занги гурӯҳӣ — канали умумӣ ва маълумоти гурӯҳ; вагарна `null`.
  final String? channelId;
  final String? groupId;
  final String? groupName;
  const IncomingCallScreen({
    super.key,
    required this.callId,
    required this.callerId,
    required this.callerName,
    required this.type,
    this.channelId,
    this.groupId,
    this.groupName,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _callSub;

  @override
  void initState() {
    super.initState();
    _startRinging();
    _watchCall();
  }

  @override
  void dispose() {
    _callSub?.cancel();
    // Ҳар роҳи хуруҷ садоро қатъ мекунад — рингтони бандмонда аз набудани
    // рингтон бадтар аст.
    RingtoneService.instance.stop();
    super.dispose();
  }

  Future<void> _startRinging() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    var withSound = true;
    var withVibration = true;
    if (uid != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final settings = doc.data()?['settings'] as Map<String, dynamic>?;
        withSound = (settings?['callSound'] ?? true) == true;
        withVibration = (settings?['vibration'] ?? true) == true;
      } catch (_) {}
    }
    if (!mounted) return;
    await RingtoneService.instance.start(
      withSound: withSound,
      withVibration: withVibration,
    );
  }

  /// Агар зангзананда қатъ кунад, экран худаш пӯшида мешавад — вагарна
  /// садо то 45 сония идома меёбад ва корбар «занги арвоҳ»-ро мебинад.
  /// Ҳангоми қабул ё рад кардан аз тарафи ХУДАМ назораткунанда бояд
  /// хомӯш бошад — вагарна он экранро мепӯшад ва занги навкушодашударо
  /// мекушад.
  bool _handledLocally = false;

  void _watchCall() {
    _callSub = FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.callId)
        .snapshots()
        .listen((snap) {
      if (_handledLocally || !mounted) return;

      final outcome = snap.data()?['outcome'] as String?;

      // ТАНҲО қатъи занг аз тарафи ДИГАР экранро мепӯшад.
      //
      // `completed` дар ин ҷо санҷида НАМЕШАВАД: маҳз ҳамин қимат ҳангоми
      // қабул кардан гузошта мешавад. Азбаски Firestore навиштанро фавран
      // аз кэши маҳаллӣ бармегардонад, назораткунанда пеш аз кушода шудани
      // экрани занг кор мекард ва онро мепӯшид — яъне қабул кардан худаш
      // зангро мекушт.
      if (outcome != 'declined' && outcome != 'missed') return;

      RingtoneService.instance.stop();
      Navigator.of(context).maybePop();
    }, onError: (_) {});
  }

  bool get isGroupCall => widget.groupId != null && widget.channelId != null;

  Future<void> _decline() async {
    _handledLocally = true;
    await RingtoneService.instance.stop();
    try {
      await FirebaseFirestore.instance
          .collection('calls')
          .doc(widget.callId)
          .update({'outcome': 'declined'});
    } catch (_) {}
    if (mounted) Navigator.of(context).pop();
  }

  void _accept() {
    // Аввал назораткунанда хомӯш карда мешавад, баъд ҳама чизи дигар:
    // навиштани `outcome` фавран ба назораткунанда мерасад.
    _handledLocally = true;
    _callSub?.cancel();
    _callSub = null;

    // Садо ПЕШ АЗ ҳама чиз қатъ мешавад: вагарна он ҳангоми кушода шудани
    // экрани занг боз чанд сония садо медиҳад.
    RingtoneService.instance.stop();
    final context = this.context;
    // Занги гурӯҳӣ ба канали умумӣ мебарад, на ба ҳуҷҷати як занг.
    FirebaseFirestore.instance.collection('calls').doc(widget.callId).update({
      'outcome': CallOutcome.completed.name,
    }).catchError((_) {});

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => isGroupCall
            ? GroupCallScreen(
                groupId: widget.groupId!,
                groupName: widget.groupName ?? tr('k293'),
                type: widget.type,
                joinChannelId: widget.channelId,
              )
            : CallScreen(
                otherUserId: widget.callerId,
                otherUserName: widget.callerName,
                type: widget.type,
                existingCallId: widget.callId,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
    final isVideo = widget.type == CallType.video;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: NeonBackdrop(
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 50),
                UserAvatar(name: widget.callerName, uid: widget.callerId, size: 120),
                const SizedBox(height: 20),
                Text(widget.callerName, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 22)),
                const SizedBox(height: 8),
                Text(
                  isVideo ? tr('k121') : tr('k122'),
                  style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.85), fontSize: 14.5),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _actionButton(
                        icon: LucideIcons.phone_off,
                        color: Colors.redAccent,
                        label: tr('k123'),
                        onTap: _decline,
                      ),
                      _actionButton(
                        icon: isVideo ? LucideIcons.video : LucideIcons.phone,
                        color: AppColors.neonEmerald,
                        label: tr('k124'),
                        onTap: _accept,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionButton({required IconData icon, required Color color, required String label, required VoidCallback onTap}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
      ],
    );
  }
}
