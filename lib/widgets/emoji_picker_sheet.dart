import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/app_theme.dart';
import 'glass_container.dart';
import '../l10n/l10n.dart';
import '../theme/app_scope.dart';
import '../services/recent_emojis_store.dart';

/// Як категорияи эмоҷӣ: ном (тугмаи боло) ва рӯйхати аломатҳо.
class _EmojiCategory {
  final IconData icon;
  final String Function() label;
  final List<String> emojis;
  const _EmojiCategory(this.icon, this.label, this.emojis);
}

/// Панели интихоби emoji — ҷустуҷӯ, категорияҳо (бо табҳои боло) ва
/// "ба наздикӣ истифодашуда" (дар ҳофизаи дастгоҳ нигоҳ дошта мешавад).
/// Панел кушода мемонад то корбар якчанд emoji интихоб кунад ва бо
/// тугмаи "галочка" пӯшад.
class EmojiPickerSheet extends StatefulWidget {
  final ValueChanged<String> onEmojiSelected;
  const EmojiPickerSheet({super.key, required this.onEmojiSelected});

  @override
  State<EmojiPickerSheet> createState() => _EmojiPickerSheetState();
}

class _EmojiPickerSheetState extends State<EmojiPickerSheet> {
  static const List<String> _smileys = [
    '😀', '😁', '😂', '🤣', '😊', '😍', '😘', '😗', '😉', '😜', '🤪', '😎',
    '🥳', '🤩', '😇', '🙂', '🙃', '😌', '😴', '🤤', '😷', '🤒', '🤕', '🤯',
    '🥶', '🥵', '😱', '😨', '😢', '😭', '😤', '😡', '🤬', '🤔', '🤨', '😐',
    '😶', '🙄', '😬', '🤐', '😳', '🥺', '😔', '😞', '😟', '😕', '🙁', '☹️',
    '😮', '😲', '🥱', '😏', '😒', '🤭', '🤫', '🫡', '🥹', '😵', '🤠', '🥸',
  ];
  static const List<String> _people = [
    '👍', '👎', '👏', '🙌', '🙏', '💪', '🤝', '👋', '✌️', '🤞', '👌', '🤌',
    '👉', '👈', '👆', '👇', '✋', '🖐️', '🤙', '💅', '👶', '🧒', '👦', '👧',
    '🧑', '👨', '👩', '🧓', '👴', '👵', '😺', '❤️', '🧡', '💛', '💚', '💙',
    '💜', '🖤', '🤍', '💯', '💔', '💕', '💞',
  ];
  static const List<String> _animals = [
    '🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐨', '🐯', '🦁', '🐮',
    '🐷', '🐸', '🐵', '🙈', '🙉', '🙊', '🐔', '🐧', '🐦', '🐤', '🦆', '🦅',
    '🦉', '🦄', '🐴', '🐝', '🐛', '🦋', '🐌', '🐞', '🐢', '🐍', '🐙', '🦀',
    '🐬', '🐳', '🐠', '🐟',
  ];
  static const List<String> _food = [
    '🍎', '🍐', '🍊', '🍋', '🍌', '🍉', '🍇', '🍓', '🍒', '🍑', '🥭', '🍍',
    '🥝', '🍅', '🥑', '🥦', '🥕', '🌽', '🍕', '🍔', '🍟', '🌭', '🥪', '🌮',
    '🌯', '🍜', '🍝', '🍣', '🍤', '🍩', '🍪', '🎂', '🍰', '🍫', '🍬', '🍭',
    '☕', '🍵', '🧃', '🥤',
  ];
  static const List<String> _activities = [
    '⚽', '🏀', '🏈', '⚾', '🎾', '🏐', '🏉', '🎱', '🏓', '🏸', '🥊', '🎮',
    '🎲', '🎯', '🎳', '🎸', '🎤', '🎧', '🎨', '🎬', '🧩', '🏆', '🥇', '🎖️',
  ];
  static const List<String> _travel = [
    '🚗', '🚕', '🚌', '🚓', '🚑', '🚒', '🚲', '🛵', '✈️', '🚀', '🚁', '⛵',
    '🚢', '🗺️', '🗽', '🗼', '🏖️', '🏔️', '🏕️', '🌋', '🏙️', '🌅', '🌃', '🌙',
    '☀️', '⭐', '🌈', '⛈️', '❄️', '🔥',
  ];
  static const List<String> _objects = [
    '📱', '💻', '⌚', '📷', '🎥', '📺', '💡', '🔦', '🕯️', '📚', '✏️', '📝',
    '📎', '✂️', '🔑', '🔒', '🔔', '🎁', '🎉', '🎈', '📌', '📍', '🧷', '🪙',
  ];
  static const List<String> _symbols = [
    '✨', '⚡', '💥', '💫', '💢', '💦', '💨', '🕉️', '☮️', '✅', '❌', '❓',
    '❗', '💤', '🔞', '📵', '♻️', '〽️', '✴️', '🆗', '🆕', '🔝', '🔥', '💯',
  ];
  static const List<String> _flags = [
    '🏳️', '🏴', '🏁', '🚩', '🏳️‍🌈', '🇹🇯', '🇷🇺', '🇺🇸', '🇬🇧', '🇫🇷', '🇩🇪', '🇨🇳',
    '🇯🇵', '🇰🇷', '🇮🇳', '🇹🇷', '🇦🇪', '🇸🇦', '🇮🇷', '🇺🇿', '🇰🇿', '🇰🇬', '🇦🇫', '🇵🇰',
  ];

  // Эзоҳ: барои ин табҳо иконаҳои стандартии Material (`Icons.*`) истифода
  // мешаванд, на LucideIcons — то аз номи дурусти иконаи бастаи
  // flutter_lucide вобаста набошем (баъзе номҳо дар версияҳои гуногун фарқ
  // мекунанд) ва билд вайрон нашавад.
  List<_EmojiCategory> get _categories => [
        _EmojiCategory(Icons.access_time_rounded, () => tr('k398'), _recent),
        _EmojiCategory(Icons.emoji_emotions_outlined, () => tr('k399'), _smileys),
        _EmojiCategory(Icons.people_outline_rounded, () => tr('k400'), _people),
        _EmojiCategory(Icons.pets_rounded, () => tr('k401'), _animals),
        _EmojiCategory(Icons.lunch_dining_rounded, () => tr('k402'), _food),
        _EmojiCategory(Icons.sports_basketball_outlined, () => tr('k403'), _activities),
        _EmojiCategory(Icons.flight_outlined, () => tr('k404'), _travel),
        _EmojiCategory(Icons.lightbulb_outline_rounded, () => tr('k405'), _objects),
        _EmojiCategory(Icons.auto_awesome_outlined, () => tr('k406'), _symbols),
        _EmojiCategory(Icons.flag_outlined, () => tr('k407'), _flags),
      ];

  List<String> _recent = const [];
  int _tab = 1; // аз "Табассумҳо" оғоз мешавад (0 "Ба наздикӣ" метавонад холӣ бошад)
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadRecent();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text.trim()));
  }

  Future<void> _loadRecent() async {
    final recent = await RecentEmojisStore.load();
    if (!mounted) return;
    setState(() {
      _recent = recent;
      if (recent.isNotEmpty) _tab = 0;
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _select(String emoji) async {
    widget.onEmojiSelected(emoji);
    final updated = await RecentEmojisStore.markUsed(emoji);
    if (mounted) setState(() => _recent = updated);
  }

  List<String> get _searchResults {
    if (_query.isEmpty) return const [];
    // Ҷустуҷӯи ягона: ҳамаи эмоҷиҳои ҳамаи категорияҳо якҷоя, бе такрор.
    final all = <String>{};
    for (final c in _categories.skip(1)) {
      all.addAll(c.emojis);
    }
    // Азбаски эмоҷӣ худаш номи матнӣ надорад, ҷустуҷӯ рӯйи категорияҳои
    // мувофиқ мегардад (масалан "саг" категорияи ҳайвонотро нишон медиҳад
    // нест — бинобар ин танҳо аз рӯйи худи аломат ҷустуҷӯ мекунем агар
    // корбар худи эмоҷиро гузорад, вагарна тамоми феҳрист нишон дода мешавад).
    return all.where((e) => e.contains(_query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
    final categories = _categories;
    final showSearch = _query.isNotEmpty;
    final active = categories[_tab].emojis;
    final grid = showSearch ? _searchResults : active;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      child: GlassContainer(
        borderRadius: 24,
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: AppColors.glassBorder, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.glassFill,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.search, color: AppColors.textSecondary, size: 17),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                            decoration: InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              hintText: tr('k408'),
                              hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(LucideIcons.check, color: AppColors.accent, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (!showSearch)
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (context, i) {
                    final selected = i == _tab;
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _tab = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected ? AppColors.accent.withValues(alpha: 0.18) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: selected ? AppColors.accent : AppColors.glassBorder),
                        ),
                        child: Icon(categories[i].icon, size: 18, color: selected ? AppColors.accent : AppColors.textSecondary),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              height: 230,
              child: grid.isEmpty
                  ? Center(
                      child: Text(
                        showSearch ? tr('k409') : '🙂',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    )
                  : GridView.builder(
                      padding: EdgeInsets.zero,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
                      itemCount: grid.length,
                      itemBuilder: (context, index) {
                        final emoji = grid[index];
                        return InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => _select(emoji),
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
