import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../l10n/l10n.dart';
import '../theme/app_scope.dart';

/// Дастгоҳҳои пайвастшуда. Ин барнома ҳоло ҳамгомсозии бисёрдастгоҳӣ
/// (ба мисли Telegram/WhatsApp Web) надорад, бинобар ин мо рӯйхати
/// қалбакии дастгоҳҳои "дигар"-ро намесозем — танҳо маълумоти ВОҚЕИИ
/// ҳамин нишастро аз FirebaseAuth нишон медиҳем.
class LinkedDevicesScreen extends StatelessWidget {
  const LinkedDevicesScreen({super.key});

  String _formatDate(DateTime? d) {
    if (d == null) return '—';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year}, ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
    final user = FirebaseAuth.instance.currentUser;
    final created = user?.metadata.creationTime;
    final lastSignIn = user?.metadata.lastSignInTime;
    final phone = user?.phoneNumber ?? '—';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundSecondary,
        foregroundColor: AppColors.textPrimary,
        title: Text(tr('k411'), style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassContainer(
            borderRadius: 18,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppColors.neonGradient),
                  child: Icon(LucideIcons.smartphone, color: AppColors.background, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('k414'), style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(phone, style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.callGreen.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(tr('k415'), style: TextStyle(color: AppColors.callGreen, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassContainer(
            borderRadius: 18,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row(tr('k415'), _formatDate(created)),
                const SizedBox(height: 10),
                _row(tr('k416'), _formatDate(lastSignIn)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              tr('k417'),
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Text(value, style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
