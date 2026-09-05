import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'glass_container.dart';

/// Феҳристи стикерҳо. Азбаски дар лоиҳа расмҳои воқеии стикер (PNG/WebP)
/// мавҷуд нестанд, стикерҳо ҳамчун эмоҷии калон (шабеҳи стикер, бе замина)
/// пешниҳод мешаванд — тугма зер шавад, фавран фиристода мешавад.
class StickerPickerSheet extends StatelessWidget {
  final ValueChanged<String> onStickerSelected;
  const StickerPickerSheet({super.key, required this.onStickerSelected});

  static const List<String> _stickers = [
    '😂', '😍', '🥳', '😎', '🤩', '😭', '😡', '🤯',
    '👍', '👏', '🙏', '💪', '❤️', '🔥', '🎉', '💯',
    '🤝', '👋', '😴', '🤔', '😱', '🥰', '😅', '🙌',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: GlassContainer(
        borderRadius: 24,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(color: AppColors.glassBorder, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Стикерҳо', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: GridView.builder(
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4),
                itemCount: _stickers.length,
                itemBuilder: (context, index) {
                  final sticker = _stickers[index];
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Navigator.pop(context);
                        onStickerSelected(sticker);
                      },
                      child: Center(child: Text(sticker, style: const TextStyle(fontSize: 44))),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
