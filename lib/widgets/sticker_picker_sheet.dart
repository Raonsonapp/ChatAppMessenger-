import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'glass_container.dart';
import '../l10n/l10n.dart';
import '../theme/app_scope.dart';
import '../services/recent_emojis_store.dart';

/// Феҳристи стикерҳо. Азбаски дар лоиҳа расмҳои воқеии стикер (PNG/WebP)
/// мавҷуд нестанд, стикерҳо ҳамчун эмоҷии калон (шабеҳи стикер, бе замина)
/// пешниҳод мешаванд — тугма зер шавад, фавран фиристода мешавад.
///
/// Дорои категорияҳо ва "ба наздикӣ истифодашуда" (дар ҳофизаи дастгоҳ).
class StickerPickerSheet extends StatefulWidget {
  final ValueChanged<String> onStickerSelected;
  const StickerPickerSheet({super.key, required this.onStickerSelected});

  @override
  State<StickerPickerSheet> createState() => _StickerPickerSheetState();
}

class _StickerPickerSheetState extends State<StickerPickerSheet> {
  static const List<String> _reactions = [
    '😂', '😍', '🥳', '😎', '🤩', '😭', '😡', '🤯',
    '👍', '👏', '🙏', '💪', '❤️', '🔥', '🎉', '💯',
    '🤝', '👋', '😴', '🤔', '😱', '🥰', '😅', '🙌',
  ];
  static const List<String> _animals = [
    '🐶', '🐱', '🐼', '🦄', '🐸', '🐵', '🦊', '🐧',
  ];

  List<String> _recent = const [];
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final recent = await RecentStickersStore.load();
    if (!mounted) return;
    setState(() {
      _recent = recent;
      _tab = recent.isNotEmpty ? 0 : 1;
    });
  }

  Future<void> _select(String sticker) async {
    Navigator.pop(context);
    widget.onStickerSelected(sticker);
    await RecentStickersStore.markUsed(sticker);
  }

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
    final tabs = <(String, List<String>)>[
      (tr('k398'), _recent),
      (tr('k399'), _reactions),
      (tr('k401'), _animals),
    ];
    final active = tabs[_tab].$2;

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
              children: [
                Expanded(
                  child: Text(tr('k243'), style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 32,
              child: Row(
                children: List.generate(tabs.length, (i) {
                  final selected = i == _tab;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setState(() => _tab = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.accent.withValues(alpha: 0.18) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: selected ? AppColors.accent : AppColors.glassBorder),
                        ),
                        child: Text(
                          tabs[i].$1,
                          style: TextStyle(fontSize: 12, color: selected ? AppColors.accent : AppColors.textSecondary),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: active.isEmpty
                  ? Center(child: Text('🙂', style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6), fontSize: 13)))
                  : GridView.builder(
                      padding: EdgeInsets.zero,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4),
                      itemCount: active.length,
                      itemBuilder: (context, index) {
                        final sticker = active[index];
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _select(sticker),
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
