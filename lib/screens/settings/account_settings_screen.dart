import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../l10n/l10n.dart';
import '../../services/account_service.dart';
import '../../theme/app_scope.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/neon_backdrop.dart';
import '../edit_profile_screen.dart';
import 'blocked_users_screen.dart';
import 'delete_account_screen.dart';
import 'linked_devices_screen.dart';

/// Ҳисоб: маълумоти шахсӣ, бехатарӣ ва баромадан.
///
/// Ин ҷо танҳо чизҳое ҳастанд, ки воқеан кор мекунанд. Passkey, парол, почта ва
/// 2FA дар ChatApp ҳанӯз нестанд — вуруд бо рақами телефон ва рамзи Telegram
/// иҷро мешавад, бинобар ин бандҳои холӣ намоиш дода намешаванд.
class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NeonBackdrop(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 20, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(LucideIcons.arrow_left, color: AppColors.textPrimary, size: 20),
                    ),
                    Text(
                      tr('k506'),
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 20),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    _sectionLabel(tr('k519')),
                    GlassContainer(
                      borderRadius: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Column(
                        children: [
                          if (uid != null)
                            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                              stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
                              builder: (context, snapshot) {
                                final username = (snapshot.data?.data()?['username'] as String?)?.trim() ?? '';
                                return _row(
                                  context,
                                  icon: LucideIcons.at_sign,
                                  label: tr('k511'),
                                  value: username.isEmpty ? '—' : '@$username',
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                                  ),
                                );
                              },
                            ),
                          // Рақам аз Firebase Auth меояд — иваз кардани он
                          // тасдиқи нави рамз мехоҳад, бинобар ин ин ҷо танҳо
                          // нишон дода мешавад.
                          _row(
                            context,
                            icon: LucideIcons.phone,
                            label: tr('k544'),
                            value: user?.phoneNumber ?? '—',
                            showDivider: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _sectionLabel(tr('k520')),
                    GlassContainer(
                      borderRadius: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Column(
                        children: [
                          _row(
                            context,
                            icon: LucideIcons.monitor_smartphone,
                            label: tr('k494'),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const LinkedDevicesScreen()),
                            ),
                          ),
                          _row(
                            context,
                            icon: LucideIcons.user_x,
                            label: tr('k320'),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const BlockedUsersScreen()),
                            ),
                            showDivider: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassContainer(
                      borderRadius: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Column(
                        children: [
                          _row(
                            context,
                            icon: LucideIcons.log_out,
                            label: tr('k521'),
                            onTap: () => _confirmSignOut(context),
                          ),
                          _row(
                            context,
                            icon: LucideIcons.trash,
                            label: tr('k385'),
                            danger: true,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const DeleteAccountScreen()),
                            ),
                            showDivider: false,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(tr('k521'), style: TextStyle(color: AppColors.textPrimary, fontSize: 17)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(tr('k277'), style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(tr('k521'), style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await AccountService.signOut();
    if (!context.mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? value,
    VoidCallback? onTap,
    bool showDivider = true,
    bool danger = false,
  }) {
    final tint = danger ? Colors.redAccent : AppColors.neonCyan;
    final labelColor = danger ? Colors.redAccent : AppColors.textPrimary;
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              child: Row(
                children: [
                  Icon(icon, color: tint, size: 19),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(color: labelColor, fontWeight: FontWeight.w600, fontSize: 14.5),
                    ),
                  ),
                  if (value != null)
                    Text(
                      value,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  if (onTap != null) ...[
                    const SizedBox(width: 6),
                    Icon(
                      LucideIcons.chevron_right,
                      color: AppColors.textSecondary.withValues(alpha: 0.6),
                      size: 17,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (showDivider) Divider(color: AppColors.glassBorder, height: 1),
      ],
    );
  }
}
