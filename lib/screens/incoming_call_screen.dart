import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_theme.dart';
import '../models/app_call.dart';
import '../widgets/neon_backdrop.dart';
import 'call_screen.dart';

/// Экрани занги воридотӣ — намоён мешавад вақте ки корбари дигар занг
/// мезанад (тавассути IncomingCallListener). Қабул → CallScreen (ба ҳамон
/// канали Agora ҳамроҳ мешавад); Рад → ҳуҷҷати calls/{id} 'declined' мешавад.
class IncomingCallScreen extends StatelessWidget {
  final String callId;
  final String callerId;
  final String callerName;
  final CallType type;
  const IncomingCallScreen({
    super.key,
    required this.callId,
    required this.callerId,
    required this.callerName,
    required this.type,
  });

  Future<void> _decline(BuildContext context) async {
    await FirebaseFirestore.instance.collection('calls').doc(callId).update({'outcome': 'declined'});
    if (context.mounted) Navigator.of(context).pop();
  }

  void _accept(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CallScreen(otherUserId: callerId, otherUserName: callerName, type: type, existingCallId: callId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = type == CallType.video;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: NeonBackdrop(
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 50),
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.neonGradient),
                  child: Center(
                    child: Text(
                      callerName.isNotEmpty ? callerName[0].toUpperCase() : '?',
                      style: const TextStyle(color: AppColors.background, fontWeight: FontWeight.w800, fontSize: 48),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(callerName, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 22)),
                const SizedBox(height: 8),
                Text(
                  isVideo ? 'Занги видеоии воридотӣ...' : 'Занги воридотӣ...',
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
                        label: 'Рад кардан',
                        onTap: () => _decline(context),
                      ),
                      _actionButton(
                        icon: isVideo ? LucideIcons.video : LucideIcons.phone,
                        color: AppColors.neonEmerald,
                        label: 'Қабул',
                        onTap: () => _accept(context),
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
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
      ],
    );
  }
}
