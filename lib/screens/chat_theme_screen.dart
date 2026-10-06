import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../l10n/l10n.dart';
import '../services/media_service.dart';
import '../theme/app_scope.dart';
import '../theme/app_theme.dart';
import '../theme/chat_theme_controller.dart';
import '../widgets/glass_container.dart';
import '../widgets/neon_backdrop.dart';

/// Намуди як чат: маҷмӯа, ранг, нишона ва замина.
///
/// Ҳар тағйир ФАВРАН ба худи чат татбиқ мешавад — на танҳо ба пешнамоиш.
class ChatThemeScreen extends StatefulWidget {
  const ChatThemeScreen({super.key, required this.chatId, required this.title});

  final String chatId;
  final String title;

  /// Нишонаҳои дастраси чат — дар як ҷо, то экрани чат ҳамонҳоро истифода
  /// барад.
  static const Map<String, IconData> icons = {
    'message': LucideIcons.message_circle,
    'heart': LucideIcons.heart,
    'star': LucideIcons.star,
    'zap': LucideIcons.zap,
    'sparkles': LucideIcons.sparkles,
    'moon': LucideIcons.moon,
    'sun': LucideIcons.sun,
    'music': LucideIcons.music,
    'camera': LucideIcons.camera,
    'coffee': LucideIcons.coffee,
    'rocket': LucideIcons.rocket,
    'flower': LucideIcons.flower,
  };

  /// Нишонаи чат аз номи нигоҳдошташуда.
  static IconData? iconByName(String? name) => name == null ? null : icons[name];

  @override
  State<ChatThemeScreen> createState() => _ChatThemeScreenState();
}

class _ChatThemeScreenState extends State<ChatThemeScreen> {
  ChatStyle get _style => chatThemeController.styleFor(widget.chatId);

  Future<void> _apply(ChatStyle style) =>
      chatThemeController.update(widget.chatId, style);

  Future<void> _pickWallpaper() async {
    final file = await MediaService.pickFromGallery();
    if (file == null || !mounted) return;
    await chatThemeController.setWallpaperFromPath(widget.chatId, file.path);
  }

  /// Нишонаҳои дастрас — аз ҳамон маҷмӯае ки тамоми барнома истифода мебарад.
  static const _icons = ChatThemeScreen.icons;

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);

    return AnimatedBuilder(
      animation: chatThemeController,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: NeonBackdrop(
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                      children: [
                        _preview(),
                        const SizedBox(height: 20),
                        _sectionLabel(tr('k425')),
                        _presetGrid(),
                        const SizedBox(height: 20),
                        _sectionLabel(tr('k426')),
                        _colorGrid(),
                        const SizedBox(height: 20),
                        _sectionLabel(tr('k427')),
                        _iconGrid(),
                        const SizedBox(height: 20),
                        _sectionLabel(tr('k428')),
                        _wallpaperOptions(),
                        const SizedBox(height: 22),
                        _resetButton(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 20, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(LucideIcons.arrow_left,
                color: AppColors.textPrimary, size: 20),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('k429'),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 19,
                  ),
                ),
                Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 9),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.textSecondary.withValues(alpha: 0.7),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  /// Пешнамоиши зинда — ҳамон рангу заминае ки дар чат хоҳад буд.
  Widget _preview() {
    final style = _style;
    final preset = ChatThemeController.presetById(style.presetId);
    final bubble = Color(style.bubbleColor ?? preset?.bubble.toARGB32() ??
        AppColors.neonEmerald.toARGB32());
    final wallpaperColor = style.wallpaperColor ?? preset?.wallpaper.toARGB32();
    final wallpaperFile = style.wallpaperPath == null
        ? null
        : File(style.wallpaperPath!);

    return Container(
      height: 148,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
        color: wallpaperColor != null
            ? Color(wallpaperColor)
            : AppColors.backgroundSecondary,
        image: wallpaperFile != null && wallpaperFile.existsSync()
            ? DecorationImage(image: FileImage(wallpaperFile), fit: BoxFit.cover)
            : null,
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _previewBubble(tr('k430'), AppColors.surface, AppColors.textPrimary, false),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: _previewBubble(tr('k431'), bubble, AppColors.background, true),
          ),
        ],
      ),
    );
  }

  Widget _previewBubble(String text, Color bg, Color fg, bool mine) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14).copyWith(
          bottomRight: mine ? const Radius.circular(4) : null,
          bottomLeft: mine ? null : const Radius.circular(4),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _presetGrid() {
    return Wrap(
      spacing: 9,
      runSpacing: 9,
      children: ChatThemeController.presets.map((preset) {
        final selected = _style.presetId == preset.id;
        return GestureDetector(
          onTap: () => _apply(_style.copyWith(
            presetId: preset.id,
            // Маҷмӯа рангҳои дастиро иваз мекунад — вагарна интихоби нав
            // намоён намешавад.
            bubbleColor: preset.bubble.toARGB32(),
            accentColor: preset.accent.toARGB32(),
            wallpaperColor: preset.wallpaper.toARGB32(),
            wallpaperPath: null,
          )),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
            width: 96,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: preset.wallpaper,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: selected ? preset.accent : AppColors.glassBorder,
                width: selected ? 2 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: preset.accent.withValues(alpha: 0.35),
                        blurRadius: 12,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 26,
                      height: 12,
                      decoration: BoxDecoration(
                        color: preset.bubble,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const Spacer(),
                    if (selected)
                      Icon(LucideIcons.check, size: 13, color: preset.accent),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  tr(preset.nameKey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _colorGrid() {
    return Wrap(
      spacing: 11,
      runSpacing: 11,
      children: ChatThemeController.palette.map((color) {
        final selected = _style.bubbleColor == color.toARGB32();
        return GestureDetector(
          // Ранги дастӣ маҷмӯаро бекор мекунад: вагарна ду интихоб ҳамзамон
          // «фаъол» менамуданд.
          onTap: () => _apply(_style.copyWith(
            bubbleColor: color.toARGB32(),
            accentColor: color.toARGB32(),
            presetId: null,
          )),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? Colors.white : Colors.transparent,
                width: 2.5,
              ),
              boxShadow: selected
                  ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 12)]
                  : null,
            ),
            child: selected
                ? const Icon(LucideIcons.check, color: Colors.white, size: 19)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _iconGrid() {
    return Wrap(
      spacing: 11,
      runSpacing: 11,
      children: _icons.entries.map((entry) {
        final selected = _style.icon == entry.key;
        final accent = Color(_style.accentColor ?? AppColors.neonEmerald.toARGB32());
        return GestureDetector(
          onTap: () => _apply(
            _style.copyWith(icon: selected ? null : entry.key),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: selected
                  ? accent.withValues(alpha: 0.16)
                  : AppColors.glassFill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? accent : AppColors.glassBorder,
                width: selected ? 2 : 1,
              ),
            ),
            child: Icon(
              entry.value,
              size: 21,
              color: selected ? accent : AppColors.textSecondary,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _wallpaperOptions() {
    return GlassContainer(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Column(
        children: [
          _option(LucideIcons.image, tr('k432'), _pickWallpaper),
          Divider(color: AppColors.glassBorder, height: 1),
          _option(LucideIcons.palette, tr('k433'), _pickWallpaperColor),
          if (_style.wallpaperPath != null || _style.wallpaperColor != null) ...[
            Divider(color: AppColors.glassBorder, height: 1),
            _option(
              LucideIcons.trash,
              tr('k434'),
              () => _apply(_style.copyWith(
                wallpaperPath: null,
                wallpaperColor: null,
              )),
              danger: true,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickWallpaperColor() async {
    final chosen = await showModalBottomSheet<Color>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: AppColors.glassBorder),
        ),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('k433'),
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 11,
              runSpacing: 11,
              children: [
                const Color(0xFF0A0E14),
                const Color(0xFF07131F),
                const Color(0xFF120A1C),
                const Color(0xFF05070F),
                const Color(0xFF07140F),
                const Color(0xFF1A0E0A),
                const Color(0xFF0D0D0D),
                const Color(0xFF14161A),
              ]
                  .map((c) => GestureDetector(
                        onTap: () => Navigator.pop(sheetContext, c),
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: c,
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );

    if (chosen == null) return;
    await _apply(_style.copyWith(
      wallpaperColor: chosen.toARGB32(),
      wallpaperPath: null,
    ));
  }

  Widget _option(IconData icon, String label, VoidCallback onTap,
      {bool danger = false}) {
    final color = danger ? Colors.redAccent : AppColors.textPrimary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          child: Row(
            children: [
              Icon(icon,
                  size: 19,
                  color: danger ? Colors.redAccent : AppColors.neonCyan),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                      color: color, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resetButton() {
    if (_style.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.glassBorder),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        ),
        onPressed: () => chatThemeController.reset(widget.chatId),
        child: Text(
          tr('k435'),
          style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 14),
        ),
      ),
    );
  }
}
