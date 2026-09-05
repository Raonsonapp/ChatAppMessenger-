import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/app_theme.dart';
import 'glass_container.dart';

/// Панели интихоби emoji — рӯйхати эмоҷиҳои маъмул дар шакли grid.
/// Панел кушода мемонад то корбар якчанд emoji интихоб кунад ва бо
/// тугмаи "Тайёр" пӯшад.
class EmojiPickerSheet extends StatelessWidget {
  final ValueChanged<String> onEmojiSelected;
  const EmojiPickerSheet({super.key, required this.onEmojiSelected});

  static const List<String> _emojis = [
    '😀', '😁', '😂', '🤣', '😊', '😍', '😘', '😗',
    '😉', '😜', '🤪', '😎', '🥳', '🤩', '😇', '🙂',
    '🙃', '😌', '😴', '🤤', '😷', '🤒', '🤕', '🤯',
    '🥶', '😱', '😨', '😢', '😭', '😤', '😡', '🤬',
    '🤔', '🤨', '😐', '😶', '🙄', '😬', '🤐', '😳',
    '🥺', '😔', '😞', '😟', '😕', '🙁', '☹️', '😮',
    '👍', '👎', '👏', '🙌', '🙏', '💪', '🤝', '👋',
    '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '💯',
    '🔥', '✨', '🎉', '🎂', '🎁', '⭐', '☀️', '🌙',
    '🐶', '🐱', '🐼', '🦄', '🍕', '🍔', '☕', '🍎',
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Эмоҷиҳо', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.check, color: AppColors.neonEmerald, size: 20),
                ),
              ],
            ),
            SizedBox(
              height: 260,
              child: GridView.builder(
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
                itemCount: _emojis.length,
                itemBuilder: (context, index) {
                  final emoji = _emojis[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => onEmojiSelected(emoji),
                    child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
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
