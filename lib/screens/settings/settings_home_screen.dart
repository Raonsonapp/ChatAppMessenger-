
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
import 'account_settings_screen.dart';
import 'lists_screen.dart';
import 'chats_settings_screen.dart';
import 'accessibility_settings_screen.dart';
import 'linked_devices_screen.dart';
import '../coming_soon_screen.dart';
import '../../l10n/l10n.dart';
import '../../theme/app_scope.dart';
import 'plus_screen.dart';
import '../business/business_center_screen.dart';
import '../bot_studio_screen.dart';
import '../../widgets/plus_badge.dart';
import '../../services/plus_service.dart';

/// Settings home: existing Firebase profile and routes are retained.
/// Visual style: dark surface, green accents, subtle ChatApp neon profile.
class SettingsHomeScreen extends StatelessWidget {
  const SettingsHomeScreen({super.key});

  Future<void> _inviteFriend(BuildContext context) async {
    final phone = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
    final text = trf('k459', [phone]);
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('k353'))),
      );
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
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        LucideIcons.arrow_left,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        tr('k181'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    if (uid != null)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EditProfileScreen(),
                            ),
                          ),
                          child: GlassContainer(
                            borderRadius: 22,
                            padding: EdgeInsets.zero,
                            child: StreamBuilder<
                                DocumentSnapshot<Map<String, dynamic>>>(
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(uid)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                final data = snapshot.data?.data();
                                final rawName =
                                    (data?['name'] as String?)?.trim() ?? '';
                                final name =
                                    rawName.isEmpty ? tr('k002') : rawName;
                                final username =
                                    (data?['username'] as String?)?.trim() ??
                                        '';
                                final about =
                                    (data?['about'] as String?)?.trim() ?? '';
                                final second = username.isNotEmpty
                                    ? '@$username'
                                    : (about.isNotEmpty ? about : phone);

                                return Stack(
                                  children: [
                                    Positioned(
                                      top: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        height: 74,
                                        decoration: BoxDecoration(
                                          gradient: AppColors.neonGradient,
                                          borderRadius:
                                              const BorderRadius.vertical(
                                            top: Radius.circular(22),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        18,
                                        28,
                                        18,
                                        16,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          UserAvatar(
                                            name: name,
                                            photoUrl: data?['photoUrl'] as String?,
                                            size: 72,
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  name,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color:
                                                        AppColors.textPrimary,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 21,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              PlusBadge(
                                                status: PlusStatus.fromUserDoc(
                                                  data,
                                                ),
                                                compact: true,
                                              ),
                                            ],
                                          ),
                                          if (second.isNotEmpty) ...[
                                            const SizedBox(height: 5),
                                            Text(
                                              second,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color:
                                                    AppColors.textSecondary,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                          if (phone.isNotEmpty) ...[
                                            const SizedBox(height: 3),
                                            Text(
                                              phone,
                                              style: TextStyle(
                                                color:
                                                    AppColors.textSecondary,
                                                fontSize: 12.5,
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                LucideIcons.pencil,
                                                size: 15,
                                                color: Color(0xFF25D366),
                                              ),
                                              const SizedBox(width: 7),
                                              Text(
                                                tr('k115'),
                                                style: const TextStyle(
                                                  color: Color(0xFF25D366),
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 14),

                    // Account and subscription
                    _sectionCard(context, [
                      _row(
                        context,
                        icon: LucideIcons.sparkles,
                        label: tr('k587'),
                        description: 'Имтиёзҳо ва имкониятҳои Plus',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PlusScreen(),
                          ),
                        ),
                      ),
                      _row(
                        context,
                        icon: LucideIcons.circle_user,
                        label: tr('k506'),
                        description: 'Маълумоти ҳисоб ва амният',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AccountSettingsScreen(),
                          ),
                        ),
                      ),
                      _row(
                        context,
                        icon: LucideIcons.bot,
                        label: 'Bot Studio',
                        description: 'Ботҳои шахсӣ созед ва идора кунед',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BotStudioScreen(),
                          ),
                        ),
                      ),
                      _row(
                        context,
                        icon: LucideIcons.store,
                        label: tr('k619'),
                        description: 'Воситаҳои тиҷоратӣ ва хизматрасонӣ',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BusinessCenterScreen(),
                          ),
                        ),
                        showDivider: false,
                      ),
                    ]),
                    const SizedBox(height: 14),

                    // Privacy and devices
                    _sectionCard(context, [
                      _row(
                        context,
                        icon: LucideIcons.shield,
                        label: tr('k174'),
                        description: 'Кӣ маълумот ва ҳолати шуморо мебинад',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PrivacySettingsScreen(),
                          ),
                        ),
                      ),
                      _row(
                        context,
                        icon: Icons.list_alt_rounded,
                        label: tr('k444'),
                        description: 'Идоракунии рӯйхатҳо ва алоқаҳо',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ListsScreen(),
                          ),
                        ),
                      ),
                      _row(
                        context,
                        icon: LucideIcons.smartphone,
                        label: tr('k411'),
                        description: 'Истифодаи ChatApp дар дастгоҳҳои дигар',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LinkedDevicesScreen(),
                          ),
                        ),
                        showDivider: false,
                      ),
                    ]),
                    const SizedBox(height: 14),

                    // Chats, appearance, notifications and storage
                    _sectionCard(context, [
                      _row(
                        context,
                        icon: LucideIcons.message_circle,
                        label: tr('k044'),
                        description: 'Таърихи чат, нусха ва андозаи матн',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ChatsSettingsScreen(),
                          ),
                        ),
                      ),
                      _row(
                        context,
                        icon: LucideIcons.eye,
                        label: tr('k147'),
                        description: 'Мавзӯъ, замина ва андозаи ҳарф',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AppearanceSettingsScreen(),
                          ),
                        ),
                      ),
                      _row(
                        context,
                        icon: LucideIcons.bell,
                        label: tr('k146'),
                        description: 'Овозҳои паём, гурӯҳ ва занг',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const NotificationsSettingsScreen(),
                          ),
                        ),
                      ),
                      _row(
                        context,
                        icon: LucideIcons.database,
                        label: tr('k182'),
                        description: 'Истифодаи шабака ва фазои дастгоҳ',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StorageSettingsScreen(),
                          ),
                        ),
                        showDivider: false,
                      ),
                    ]),
                    const SizedBox(height: 14),

                    // Other settings
                    _sectionCard(context, [
                      _row(
                        context,
                        icon: LucideIcons.users,
                        label: tr('k445'),
                        description: 'Танзимоти оила ва назорат',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ComingSoonScreen(
                              title: tr('k445'),
                              icon: LucideIcons.users,
                            ),
                          ),
                        ),
                      ),
                      _row(
                        context,
                        icon: Icons.accessibility_new_rounded,
                        label: tr('k446'),
                        description: 'Контраст, ҳаракат ва дастрасӣ',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AccessibilitySettingsScreen(),
                          ),
                        ),
                        showDivider: false,
                      ),
                    ]),
                    const SizedBox(height: 14),
                    _sectionCard(context, [
                      _row(
                        context,
                        icon: LucideIcons.globe,
                        label: tr('k183'),
                        description: 'Забони интерфейси барнома',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LanguageSettingsScreen(),
                          ),
                        ),
                        showDivider: false,
                      ),
                    ]),
                    const SizedBox(height: 14),

                    // Help and app information
                    _sectionCard(context, [
                      _row(
                        context,
                        icon: LucideIcons.circle_question_mark,
                        label: tr('k169'),
                        description: 'Маркази кӯмак ва сиёсати махфият',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HelpScreen(),
                          ),
                        ),
                      ),
                      _row(
                        context,
                        icon: Icons.ios_share_rounded,
                        label: tr('k447'),
                        description: 'ChatApp-ро ба дӯстатон пешниҳод кунед',
                        onTap: () => _inviteFriend(context),
                      ),
                      _row(
                        context,
                        icon: LucideIcons.info,
                        label: tr('k139'),
                        description: 'Маълумот дар бораи ChatApp',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AboutScreen(),
                          ),
                        ),
                        showDivider: false,
                      ),
                    ]),
                    const SizedBox(height: 14),

                    // Keep the destructive action separate.
                    _sectionCard(context, [
                      _row(
                        context,
                        icon: LucideIcons.trash,
                        label: tr('k385'),
                        description: 'Ҳисобро нест кардан',
                        danger: true,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DeleteAccountScreen(),
                          ),
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

  Widget _sectionCard(BuildContext context, List<Widget> children) {
    // Flat WhatsApp-style settings groups: clean dark canvas, no heavy cards.
    return Column(children: children);
  }

  Widget _row(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    String? description,
    bool showDivider = true,
    bool danger = false,
  }) {
    final tint = danger ? Colors.redAccent : const Color(0xFF8B9698);
    final labelColor =
        danger ? Colors.redAccent : AppColors.textPrimary;

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 13,
                horizontal: 12,
              ),
              child: Row(
                children: [
                  Icon(icon, color: tint, size: 19),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            color: labelColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                        if (description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: TextStyle(
                              color: AppColors.textSecondary.withValues(alpha: 0.92),
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    LucideIcons.chevron_right,
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                    size: 17,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            color: Color(0xFF202629),
            height: 1,
            indent: 46,
            endIndent: 10,
          ),
      ],
    );
  }
}
