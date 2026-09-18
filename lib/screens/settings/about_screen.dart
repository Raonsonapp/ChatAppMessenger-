import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/neon_backdrop.dart';
import '../../widgets/app_logo.dart';
import '../../l10n/l10n.dart';
import '../../theme/app_scope.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  // Бо `version` дар pubspec.yaml мувофиқ нигоҳ дошта шавад.
  static const String appVersion = '1.0.0';

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
                      tr('k139'),
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 20),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    const SizedBox(height: 12),
                    const Center(child: AppLogo(size: 72)),
                    const SizedBox(height: 14),
                    Center(
                      child: Text(
                        'ChatApp',
                        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 22),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        trf('k140', [appVersion]),
                        style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.85), fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 24),
                    GlassContainer(
                      borderRadius: 18,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('k141'),
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 13.5, height: 1.5),
                          ),
                          const SizedBox(height: 16),
                          Divider(color: AppColors.glassBorder, height: 1),
                          const SizedBox(height: 16),
                          _infoRow(LucideIcons.shield_check, tr('k142'), tr('k143')),
                          const SizedBox(height: 12),
                          _infoRow(LucideIcons.database, tr('k144'), tr('k145')),
                          const SizedBox(height: 12),
                          _infoRow(LucideIcons.video, tr('k047'), 'Agora RTC'),
                          const SizedBox(height: 12),
                          _infoRow(LucideIcons.bell, tr('k146'), 'Firebase Cloud Messaging'),
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

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.neonCyan, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.85), fontSize: 12.5)),
            ],
          ),
        ),
      ],
    );
  }
}
