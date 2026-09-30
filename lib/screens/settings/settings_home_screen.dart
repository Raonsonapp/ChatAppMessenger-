import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:share_plus/share_plus.dart';

import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/neon_backdrop.dart';
import 'privacy_settings_screen.dart';
import 'notifications_settings_screen.dart';
import 'appearance_settings_screen.dart';
import 'language_settings_screen.dart';
import 'storage_settings_screen.dart';
import 'help_screen.dart';
import 'about_screen.dart';
import 'delete_account_screen.dart';
import 'account_settings_screen.dart';
import 'plus_screen.dart';
import 'linked_devices_screen.dart';
import '../edit_profile_screen.dart';
import '../../widgets/user_avatar.dart';
import '../../l10n/l10n.dart';
import '../../theme/app_scope.dart';
import '../../widgets/plus_badge.dart';
import '../../services/plus_service.dart';

class SettingsHomeScreen extends StatelessWidget {
  const SettingsHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
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
                      tr('k181'),
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 20),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    _profileHub(context),
                    const SizedBox(height: 14),
                    _sectionCard(context, [
                      _row(
                        context,
                        icon: LucideIcons.sparkles,
                        label: tr('k587'),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PlusScreen()),
                        ),
                      ),
                      _row(
                        context,
                        icon: LucideIcons.circle_user,
                        label: tr('k506'),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AccountSettingsScreen()),
                        ),
                      ),
                      _row(
                        context,
                        icon: LucideIcons.monitor_smartphone,
                        label: tr('k494'),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LinkedDevicesScreen()),
                        ),
                        showDivider: false,
                      ),
                    ]),
                    const SizedBox(height: 14),
                    _sectionCard(context, [
                      _row(
                        context,
                        icon: LucideIcons.shield,
                        label: tr('k174'),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PrivacySettingsScreen()),
                        ),
                      ),
                      _row(
                        context,
                        icon: LucideIcons.bell,
                        label: tr('k146'),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NotificationsSettingsScreen()),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 14),
                    _sectionCard(context, [
                      _row(
                        context,
                        icon: LucideIcons.eye,
                        label: tr('k147'),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AppearanceSettingsScreen()),
                        ),
                      ),
                      _row(
                        context,
                        icon: LucideIcons.database,
                        label: tr('k182'),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const StorageSettingsScreen()),
                        ),
                      ),
                      _row(
                        context,
                        icon: LucideIcons.globe,
                        label: tr('k183'),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LanguageSettingsScreen()),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 14),
                    _sectionCard(context, [
                      _row(
                        context,
                        icon: LucideIcons.circle_question_mark,
                        label: tr('k169'),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const HelpScreen()),
                        ),
                      ),
                      _row(
                        context,
                        icon: LucideIcons.info,
                        label: tr('k139'),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AboutScreen()),
                        ),
                      ),
                      _row(
                        context,
                        icon: LucideIcons.user_plus,
                        label: tr('k510'),
                        onTap: () => _inviteFriend(context),
                        showDivider: false,
                      ),
                    ]),
                    const SizedBox(height: 14),
                    // Нест кардани ҳисоб дар охир ва бо ранги сурх — то
                    // тасодуфан пахш нашавад.
                    _sectionCard(context, [
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
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Корти профил дар болои танзимот — мисли WhatsApp ва Telegram.
  ///
  /// Ном, `@username` ва акс воқеӣ аз `users/{uid}` меоянд; пахш ба экрани
  /// таҳрири профил мебарад.
  Widget _profileHub(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final phone = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';

    return GlassContainer(
      borderRadius: 18,
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditProfileScreen()),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: uid == null
                  ? null
                  : FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data();
                final rawName = (data?['name'] as String?)?.trim() ?? '';
                final name = rawName.isEmpty ? tr('k002') : rawName;
                final username = (data?['username'] as String?)?.trim() ?? '';
                final about = (data?['about'] as String?)?.trim() ?? '';
                // Сатри дуюм: `@username`, вагарна «Дар бораи», вагарна рақам.
                final second = username.isNotEmpty
                    ? '@$username'
                    : (about.isNotEmpty ? about : phone);

                return Row(
                  children: [
                    UserAvatar(name: name, photoUrl: data?['photoUrl'] as String?, size: 56),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16.5,
                                  ),
                                ),
                              ),
                              // Нишон аз ҳамон ҳуҷҷат меояд, ки сервер
                              // менависад — барнома онро худаш намесозад.
                              PlusBadge(
                                status: PlusStatus.fromUserDoc(data),
                                compact: true,
                              ),
                            ],
                          ),
                          if (second.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              second,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(LucideIcons.chevron_right, color: AppColors.textSecondary.withValues(alpha: 0.6), size: 18),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Даъвати дӯст — матни даъват ба варақаи мубодилаи худи система дода мешавад.
  Future<void> _inviteFriend(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: tr('k518'),
        sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  Widget _sectionCard(BuildContext context, List<Widget> children) {
    return GlassContainer(
      borderRadius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(children: children),
    );
  }

  Widget _row(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
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
                    child: Text(label, style: TextStyle(color: labelColor, fontWeight: FontWeight.w600, fontSize: 14.5)),
                  ),
                  Icon(LucideIcons.chevron_right, color: AppColors.textSecondary.withValues(alpha: 0.6), size: 17),
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
