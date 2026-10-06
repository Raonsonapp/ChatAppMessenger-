import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/neon_backdrop.dart';
import '../../widgets/user_avatar.dart';
import '../edit_profile_screen.dart';
import 'privacy_settings_screen.dart';
import 'notifications_settings_screen.dart';
import 'appearance_settings_screen.dart';
import 'language_settings_screen.dart';
import 'storage_settings_screen.dart';
import 'help_screen.dart';
import 'about_screen.dart';
import 'delete_account_screen.dart';
import 'account_screen.dart';
import 'lists_screen.dart';
import 'chats_settings_screen.dart';
import 'accessibility_settings_screen.dart';
import 'linked_devices_screen.dart';
import '../coming_soon_screen.dart';
import '../../l10n/l10n.dart';
import '../../theme/app_scope.dart';
import 'plus_screen.dart';
import '../business/business_center_screen.dart';

/// Танзимот — экрани воҳиди пурра, мисли WhatsApp: сарлавҳаи профил дар боло
/// (расм/ном/телефони воқеӣ), сонаш ҳамаи бахшҳои воқеии барнома. Ҳар банд
/// ба экрани ВОҚЕИИ худаш мебарад — ягон банди "холӣ" нест.
///
/// "Назорати волидон" ҳоло backend надорад (пайвасти ҷудогонаи ҳисоби
/// волидайн/кӯдак), бинобар ин экрани ҳалоли "омода нест"-ро мекушояд —
/// мувофиқи қоидаи "ҳеҷ чизи қалбакӣ".
class SettingsHomeScreen extends StatelessWidget {
  const SettingsHomeScreen({super.key});

  Future<void> _inviteFriend(BuildContext context) async {
    final phone = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
    final text = trf('k459', [phone]);
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('k353'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final phone = FirebaseAuth.instance.currentUser?.phoneNumber ?? '—';

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
                    // Сарлавҳаи профил — расм/ном/телефони воқеӣ, зер карданаш
                    // ба таҳрири профил мебарад.
                    if (uid != null)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                          child: GlassContainer(
                            borderRadius: 18,
                            padding: const EdgeInsets.all(14),
                            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                              stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
                              builder: (context, snapshot) {
                                final data = snapshot.data?.data();
                                final name = data?['name'] as String?;
                                final shown = (name == null || name.isEmpty) ? tr('k002') : name;
                                return Row(
                                  children: [
                                    UserAvatar(name: shown, photoUrl: data?['photoUrl'] as String?, size: 52),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(shown, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
                                          const SizedBox(height: 2),
                                          Text(phone, style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                                        ],
                                      ),
                                    ),
                                    Icon(LucideIcons.chevron_right, color: AppColors.textSecondary.withValues(alpha: 0.6), size: 17),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
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
                        icon: LucideIcons.store,
                        label: tr('k619'),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BusinessCenterScreen()),
                        ),
                        showDivider: false,
                      ),
                    ]),
                    const SizedBox(height: 14),
                    _sectionCard(context, [
                      _row(
                        context,
                        icon: LucideIcons.user,
                        label: tr('k443'),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountScreen())),
                      ),
                      _row(
                        context,
                        icon: LucideIcons.shield,
                        label: tr('k174'),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacySettingsScreen())),
                      ),
                      _row(
                        context,
                        icon: Icons.list_alt_rounded,
                        label: tr('k444'),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ListsScreen())),
                      ),
                      _row(
                        context,
                        icon: LucideIcons.smartphone,
                        label: tr('k411'),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LinkedDevicesScreen())),
                        showDivider: false,
                      ),
                    ]),
                    const SizedBox(height: 14),
                    _sectionCard(context, [
                      _row(
                        context,
                        icon: LucideIcons.message_circle,
                        label: tr('k044'),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatsSettingsScreen())),
                      ),
                      _row(
                        context,
                        icon: LucideIcons.eye,
                        label: tr('k147'),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppearanceSettingsScreen())),
                      ),
                      _row(
                        context,
                        icon: LucideIcons.bell,
                        label: tr('k146'),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsSettingsScreen())),
                      ),
                      _row(
                        context,
                        icon: LucideIcons.database,
                        label: tr('k182'),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StorageSettingsScreen())),
                        showDivider: false,
                      ),
                    ]),
                    const SizedBox(height: 14),
                    _sectionCard(context, [
                      _row(
                        context,
                        icon: LucideIcons.users,
                        label: tr('k445'),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ComingSoonScreen(title: tr('k445'), icon: LucideIcons.users)),
                        ),
                      ),
                      _row(
                        context,
                        icon: Icons.accessibility_new_rounded,
                        label: tr('k446'),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccessibilitySettingsScreen())),
                        showDivider: false,
                      ),
                    ]),
                    const SizedBox(height: 14),
                    _sectionCard(context, [
                      _row(
                        context,
                        icon: LucideIcons.globe,
                        label: tr('k183'),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageSettingsScreen())),
                        showDivider: false,
                      ),
                    ]),
                    const SizedBox(height: 14),
                    _sectionCard(context, [
                      _row(
                        context,
                        icon: LucideIcons.circle_question_mark,
                        label: tr('k169'),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen())),
                      ),
                      _row(
                        context,
                        icon: Icons.ios_share_rounded,
                        label: tr('k447'),
                        onTap: () => _inviteFriend(context),
                      ),
                      _row(
                        context,
                        icon: LucideIcons.info,
                        label: tr('k139'),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
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
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DeleteAccountScreen())),
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
