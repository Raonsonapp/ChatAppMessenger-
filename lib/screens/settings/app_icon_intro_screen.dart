import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../l10n/l10n.dart';
import '../../theme/app_scope.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/neon_backdrop.dart';
import 'app_icon_picker_screen.dart';

/// Intro screen in the flow: Plus → Change app icon → Update app icon → icon grid.
class AppIconIntroScreen extends StatelessWidget {
  const AppIconIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NeonBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 16, 0),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(LucideIcons.arrow_left, color: AppColors.textPrimary, size: 21),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                  children: [
                    SizedBox(
                      height: 240,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            left: 14,
                            top: 52,
                            child: Transform.rotate(
                              angle: -0.18,
                              child: Image.asset(
                                'assets/app_icons/chatapp_icon_06.png',
                                width: 124,
                                height: 124,
                                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 14,
                            top: 52,
                            child: Transform.rotate(
                              angle: 0.18,
                              child: Image.asset(
                                'assets/app_icons/chatapp_icon_02.png',
                                width: 124,
                                height: 124,
                                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                              ),
                            ),
                          ),
                          Container(
                            width: 150,
                            height: 150,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(color: AppColors.glassBorder, width: 1.4),
                              boxShadow: [
                                BoxShadow(color: AppColors.neonEmerald.withValues(alpha: 0.24), blurRadius: 26),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(25),
                              child: Image.asset(
                                'assets/app_icons/chatapp_icon_01.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Icon(LucideIcons.message_circle, size: 74, color: AppColors.neonEmerald),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 24,
                            left: 28,
                            child: Icon(LucideIcons.sparkles, size: 24, color: AppColors.textPrimary),
                          ),
                          Positioned(
                            right: 32,
                            bottom: 26,
                            child: Icon(LucideIcons.sparkles, size: 20, color: AppColors.neonCyan),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      tr('k643'),
                      textAlign: TextAlign.start,
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 28, height: 1.18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tr('k644'),
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 16, height: 1.45),
                    ),
                    const SizedBox(height: 28),
                    GlassContainer(
                      borderRadius: 18,
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(LucideIcons.smartphone, color: AppColors.neonCyan, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(tr('k676'), style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                                const SizedBox(height: 4),
                                Text(tr('k646'), style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.35)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.neonEmerald,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AppIconPickerScreen()),
                    ),
                    child: Text(tr('k676'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
