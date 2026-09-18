import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

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
import '../../l10n/l10n.dart';
import '../../theme/app_scope.dart';

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
