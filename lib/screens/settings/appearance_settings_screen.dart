import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../theme/app_theme.dart';
import '../../theme/theme_controller.dart';
import '../../theme/wallpaper_controller.dart';
import '../../theme/text_scale_controller.dart';
import '../../services/media_service.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/neon_backdrop.dart';
import '../../l10n/l10n.dart';
import '../../theme/app_scope.dart';

class AppearanceSettingsScreen extends StatefulWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  State<AppearanceSettingsScreen> createState() => _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState extends State<AppearanceSettingsScreen> {
  Future<void> _select(bool dark) async {
    await themeController.setDark(dark);
    if (mounted) setState(() {});
  }

  /// Заминаи чат — акс аз галерея интихоб ва ба ҳофизаи дастгоҳ нусха мешавад.
  Future<void> _pickWallpaper() async {
    final file = await MediaService.pickFromGallery();
    if (file == null) return;
    await wallpaperController.setFromPath(file.path);
    if (mounted) setState(() {});
  }

  Future<void> _clearWallpaper() async {
    await wallpaperController.clear();
    if (mounted) setState(() {});
  }

  Future<void> _setTextScale(double value) async {
    await textScaleController.setScale(value);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
    final isDark = themeController.isDark;

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
                      tr('k147'),
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 20),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        tr('k148'),
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    GlassContainer(
                      borderRadius: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Column(
                        children: [
                          _option(
                            icon: LucideIcons.moon,
                            label: tr('k149'),
                            description: tr('k150'),
                            selected: isDark,
                            onTap: () => _select(true),
                          ),
                          Divider(color: AppColors.glassBorder, height: 1),
                          _option(
                            icon: LucideIcons.sun,
                            label: tr('k151'),
                            description: tr('k152'),
                            selected: !isDark,
                            onTap: () => _select(false),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        tr('k280'),
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    GlassContainer(
                      borderRadius: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Column(
                        children: [
                          _option(
                            icon: LucideIcons.image,
                            label: tr('k281'),
                            description: tr('k282'),
                            selected: false,
                            onTap: _pickWallpaper,
                            showMark: false,
                          ),
                          if (wallpaperController.path != null) ...[
                            Divider(color: AppColors.glassBorder, height: 1),
                            _option(
                              icon: LucideIcons.trash,
                              label: tr('k283'),
                              description: tr('k284'),
                              selected: false,
                              onTap: _clearWallpaper,
                              showMark: false,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        tr('k322'),
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    GlassContainer(
                      borderRadius: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Column(
                        children: [
                          _option(
                            icon: LucideIcons.type,
                            label: tr('k323'),
                            description: tr('k326'),
                            selected: textScaleController.scale == 0.9,
                            onTap: () => _setTextScale(0.9),
                          ),
                          Divider(color: AppColors.glassBorder, height: 1),
                          _option(
                            icon: LucideIcons.type,
                            label: tr('k324'),
                            description: tr('k327'),
                            selected: textScaleController.scale == 1.0,
                            onTap: () => _setTextScale(1.0),
                          ),
                          Divider(color: AppColors.glassBorder, height: 1),
                          _option(
                            icon: LucideIcons.type,
                            label: tr('k325'),
                            description: tr('k328'),
                            selected: textScaleController.scale == 1.15,
                            onTap: () => _setTextScale(1.15),
                          ),
                        ],
                      ),
                    ),
                    if (wallpaperController.file != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          wallpaperController.file!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _option({
    required IconData icon,
    required String label,
    required String description,
    required bool selected,
    required VoidCallback onTap,
    bool showMark = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          child: Row(
            children: [
              Icon(icon, color: selected ? AppColors.neonEmerald : AppColors.neonCyan, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.85), fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (!showMark)
                Icon(LucideIcons.chevron_right, color: AppColors.textSecondary.withValues(alpha: 0.6), size: 18)
              else if (selected)
                Icon(LucideIcons.check, color: AppColors.neonEmerald, size: 20)
              else
                Icon(
                  LucideIcons.circle,
                  color: AppColors.textSecondary.withValues(alpha: 0.4),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
