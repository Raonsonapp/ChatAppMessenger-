import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_theme.dart';
import '../theme/wallpaper_controller.dart';
import '../theme/app_scope.dart';
import '../widgets/glass_container.dart';
import '../widgets/chat_wallpaper.dart';
import '../l10n/l10n.dart';

/// Мавзӯи чат — замина (ранг/акс) барои ҳамин чат, на тамоми барнома.
/// Воқеан дар ҳофизаи дастгоҳ нигоҳ дошта мешавад (ниг. WallpaperController).
class ChatThemeScreen extends StatefulWidget {
  final String chatId;
  final String chatTitle;
  const ChatThemeScreen({super.key, required this.chatId, required this.chatTitle});

  @override
  State<ChatThemeScreen> createState() => _ChatThemeScreenState();
}

class _ChatThemeScreenState extends State<ChatThemeScreen> {
  static const List<Color> _presets = [
    Color(0xFF0B141A), // Пешфарз (торик)
    Color(0xFF1F2C34),
    Color(0xFF1C3A52),
    Color(0xFF2B2140),
    Color(0xFF23321F),
    Color(0xFF3A1E24),
    Color(0xFF1E3A34),
    Color(0xFF332418),
  ];

  Future<void> _pickFromGallery() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    await wallpaperController.setImageForChat(widget.chatId, picked.path);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('k426'))));
  }

  Future<void> _applyColor(Color color) async {
    await wallpaperController.setColorForChat(widget.chatId, color.toARGB32());
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('k426'))));
  }

  Future<void> _reset() async {
    await wallpaperController.clearForChat(widget.chatId);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('k426'))));
  }

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundSecondary,
        foregroundColor: AppColors.textPrimary,
        title: Text(tr('k420'), style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Пешнамоиш — мисли паёмҳои воқеӣ дар болои заминаи интихобшуда.
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              height: 160,
              child: ChatWallpaper(
                chatId: widget.chatId,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: AppColors.neonGradient,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(widget.chatTitle, style: TextStyle(color: AppColors.background, fontSize: 12.5, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(tr('k421'), style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          GlassContainer(
            borderRadius: 16,
            padding: const EdgeInsets.all(4),
            child: ListTile(
              leading: Icon(Icons.restore_rounded, color: AppColors.accent, size: 20),
              title: Text(tr('k421'), style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
              onTap: _reset,
            ),
          ),
          const SizedBox(height: 20),
          Text(tr('k424'), style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: _presets.map((c) {
              return GestureDetector(
                onTap: () => _applyColor(c),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.glassBorder, width: 2),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          GlassContainer(
            borderRadius: 16,
            padding: const EdgeInsets.all(4),
            child: ListTile(
              leading: Icon(LucideIcons.image, color: AppColors.accent, size: 20),
              title: Text(tr('k109'), style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
              onTap: _pickFromGallery,
            ),
          ),
        ],
      ),
    );
  }
}
