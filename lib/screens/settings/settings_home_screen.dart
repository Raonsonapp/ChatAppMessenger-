import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/neon_backdrop.dart';
import '../../utils/snackbar_utils.dart';
import 'privacy_settings_screen.dart';
import 'notifications_settings_screen.dart';

class SettingsHomeScreen extends StatelessWidget {
  const SettingsHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                      icon: const Icon(LucideIcons.arrow_left, color: AppColors.textPrimary, size: 20),
                    ),
                    const Text(
                      'Танзимот',
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
                        label: 'Махфият',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PrivacySettingsScreen()),
                        ),
                      ),
                      _row(
                        context,
                        icon: LucideIcons.bell,
                        label: 'Огоҳиномаҳо',
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
                        label: 'Намуди зоҳирӣ',
                        onTap: () => showComingSoonSnack(context, 'Намуди зоҳирӣ'),
                      ),
                      _row(
                        context,
                        icon: LucideIcons.database,
                        label: 'Захира ва маълумот',
                        onTap: () => showComingSoonSnack(context, 'Захира ва маълумот'),
                      ),
                      _row(
                        context,
                        icon: LucideIcons.globe,
                        label: 'Забон',
                        onTap: () => showComingSoonSnack(context, 'Забон'),
                      ),
                    ]),
                    const SizedBox(height: 14),
                    _sectionCard(context, [
                      _row(
                        context,
                        icon: LucideIcons.circle_question_mark,
                        label: 'Кӯмак',
                        onTap: () => showComingSoonSnack(context, 'Кӯмак'),
                      ),
                      _row(
                        context,
                        icon: LucideIcons.info,
                        label: 'Дар бораи ChatApp',
                        onTap: () => showComingSoonSnack(context, 'Дар бораи барнома'),
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
  }) {
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
                  Icon(icon, color: AppColors.neonCyan, size: 19),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14.5)),
                  ),
                  Icon(LucideIcons.chevron_right, color: AppColors.textSecondary.withValues(alpha: 0.6), size: 17),
                ],
              ),
            ),
          ),
        ),
        if (showDivider) const Divider(color: AppColors.glassBorder, height: 1),
      ],
    );
  }
}
