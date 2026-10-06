import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/neon_backdrop.dart';
import '../../l10n/l10n.dart';
import '../../theme/app_scope.dart';
import '../coming_soon_screen.dart';
import 'linked_devices_screen.dart';
import 'privacy_settings_screen.dart';
import 'delete_account_screen.dart';
import '../../services/account_service.dart';
import '../edit_profile_screen.dart';

/// "Аккаунт" — рақами воқеии телефон (аз FirebaseAuth), пайвандҳо ба
/// Махфият, Дастгоҳҳои пайвастшуда ва нест кардани ҳисоб.
///
/// "Тағйири рақами телефон" ҳоло экрани ҳалоли "омода нест"-ро мекушояд:
/// тасдиқи рақам тавассути боти Telegram кор мекунад, вале server-и мо
/// рамзи наверификатсияшударо ба ҳамин ҳисоби ҳозира пайваст карда
/// наметавонад (боти OTP ба ҳар рақам token-и ҳисоби НАВ медиҳад) — сохтани
/// ин бехатар ниёз ба тағйироти backend дорад, ки дар доираи ин кор нест.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  void _openChangeNumber(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ComingSoonScreen(title: tr('k448'), icon: LucideIcons.smartphone)),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
    final phone = FirebaseAuth.instance.currentUser?.phoneNumber ?? '—';
    final uid = FirebaseAuth.instance.currentUser?.uid;

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
                      tr('k443'),
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 20),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    GlassContainer(
                      borderRadius: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Column(
                        children: [
                          // `@username` — ягона дар тамоми барнома. Ҷустуҷӯ
                          // одамро аз рӯи он низ меёбад, бинобар ин он ин ҷо
                          // ҷои аввалро мегирад.
                          if (uid != null)
                            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(uid)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                final username =
                                    (snapshot.data?.data()?['username'] as String?)?.trim() ?? '';
                                return ListTile(
                                  leading: Icon(LucideIcons.at_sign, color: AppColors.neonCyan, size: 19),
                                  title: Text(tr('k511'),
                                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                                  subtitle: Text(username.isEmpty ? '—' : '@$username',
                                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                                  trailing: Icon(LucideIcons.chevron_right, color: AppColors.textSecondary, size: 17),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                                  ),
                                );
                              },
                            ),
                          if (uid != null) Divider(color: AppColors.glassBorder, height: 1),
                          ListTile(
                            leading: Icon(LucideIcons.phone, color: AppColors.neonCyan, size: 19),
                            title: Text(tr('k458'), style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: Text(phone, style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                          ),
                          Divider(color: AppColors.glassBorder, height: 1),
                          ListTile(
                            leading: Icon(Icons.sync_alt_rounded, color: AppColors.neonCyan, size: 19),
                            title: Text(tr('k448'), style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                            trailing: Icon(LucideIcons.chevron_right, color: AppColors.textSecondary, size: 17),
                            onTap: () => _openChangeNumber(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    GlassContainer(
                      borderRadius: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(LucideIcons.shield, color: AppColors.neonCyan, size: 19),
                            title: Text(tr('k174'), style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                            trailing: Icon(LucideIcons.chevron_right, color: AppColors.textSecondary, size: 17),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacySettingsScreen())),
                          ),
                          Divider(color: AppColors.glassBorder, height: 1),
                          ListTile(
                            leading: Icon(LucideIcons.smartphone, color: AppColors.neonCyan, size: 19),
                            title: Text(tr('k411'), style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                            trailing: Icon(LucideIcons.chevron_right, color: AppColors.textSecondary, size: 17),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LinkedDevicesScreen())),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    GlassContainer(
                      borderRadius: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(LucideIcons.log_out, color: AppColors.neonCyan, size: 19),
                            title: Text(tr('k521'),
                                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                            onTap: () => _confirmSignOut(context),
                          ),
                          Divider(color: AppColors.glassBorder, height: 1),
                          ListTile(
                            leading: Icon(LucideIcons.trash, color: Colors.redAccent, size: 19),
                            title: Text(tr('k385'), style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600, fontSize: 14)),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DeleteAccountScreen())),
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

  /// Баромадан аз ҳисоб бо тасдиқ.
  ///
  /// AccountService.signOut токени огоҳии ҳамин дастгоҳро низ мебардорад —
  /// бе он дастгоҳи бароммада паёмҳои шахсиро гирифтанро давом медиҳад.
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
}
