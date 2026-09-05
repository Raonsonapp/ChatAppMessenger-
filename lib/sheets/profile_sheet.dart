import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/settings/settings_home_screen.dart';

class ProfileSheet extends StatelessWidget {
  const ProfileSheet({super.key});

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pop();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final phone = FirebaseAuth.instance.currentUser?.phoneNumber ?? '—';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: GlassContainer(
        borderRadius: 24,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: AppColors.glassBorder, borderRadius: BorderRadius.circular(4)),
            ),
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.neonGradient),
              child: const Icon(LucideIcons.user, color: AppColors.background, size: 28),
            ),
            const SizedBox(height: 12),
            if (uid != null)
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
                builder: (context, snapshot) {
                  final name = snapshot.data?.data()?['name'] as String?;
                  return Text(
                    (name == null || name.isEmpty) ? 'Корбар' : name,
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15),
                  );
                },
              ),
            const SizedBox(height: 2),
            Text(phone, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 18),
            _menuRow(
              icon: LucideIcons.user,
              label: 'Профили ман',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
              },
            ),
            const SizedBox(height: 8),
            _menuRow(
              icon: LucideIcons.settings,
              label: 'Танзимот',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsHomeScreen()));
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _signOut(context),
                icon: const Icon(LucideIcons.log_out, color: AppColors.neonCyan, size: 18),
                label: const Text('Баромадан', style: TextStyle(color: AppColors.textPrimary)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.glassBorder),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuRow({required IconData icon, required String label, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              Icon(icon, color: AppColors.neonCyan, size: 19),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
              ),
              Icon(LucideIcons.chevron_right, color: AppColors.textSecondary.withValues(alpha: 0.6), size: 17),
            ],
          ),
        ),
      ),
    );
  }
}
