import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../theme/app_theme.dart';
import '../../theme/accessibility_controller.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/neon_backdrop.dart';
import '../../l10n/l10n.dart';
import '../../theme/app_scope.dart';

/// Имкониятҳои воқеии дастрасӣ: контрасти баланд (мавзӯи дигари рангҳо дар
/// тамоми барнома, фавран намоён) ва камтар аниматсия (гузариши соддаи
/// экранҳо аз ин лаҳза сар карда). Ҳарду дар SharedPreferences нигоҳ дошта
/// мешаванд — ниг. `accessibility_controller.dart`.
class AccessibilitySettingsScreen extends StatelessWidget {
  const AccessibilitySettingsScreen({super.key});

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
                      tr('k446'),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Column(
                        children: [
                          _switchRow(
                            icon: Icons.contrast_rounded,
                            label: tr('k449'),
                            description: tr('k450'),
                            value: accessibilityController.highContrast,
                            onChanged: accessibilityController.setHighContrast,
                          ),
                          Divider(color: AppColors.glassBorder, height: 1),
                          _switchRow(
                            icon: Icons.motion_photos_off_outlined,
                            label: tr('k451'),
                            description: tr('k452'),
                            value: accessibilityController.reduceMotion,
                            onChanged: accessibilityController.setReduceMotion,
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

  Widget _switchRow({
    required IconData icon,
    required String label,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool showDivider = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.neonCyan, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14.5)),
                const SizedBox(height: 2),
                Text(description, style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.85), fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.neonEmerald,
          ),
        ],
      ),
    );
  }
}
