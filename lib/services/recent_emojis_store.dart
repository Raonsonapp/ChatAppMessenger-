import 'package:shared_preferences/shared_preferences.dart';

/// Нигоҳдории умумии "чизҳои ба наздикӣ истифодашуда" (эмоҷӣ ё стикер) дар
/// ҳофизаи дастгоҳ — на дар Firestore, зеро он танҳо вобаста ба ҳамин
/// дастгоҳ аст.
class _RecentStore {
  final String key;
  final int max;
  const _RecentStore(this.key, {this.max = 32});

  Future<List<String>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(key) ?? const [];
    } catch (_) {
      return const [];
    }
  }

  Future<List<String>> markUsed(String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getStringList(key) ?? <String>[];
      final updated = [value, ...current.where((e) => e != value)];
      final capped = updated.take(max).toList();
      await prefs.setStringList(key, capped);
      return capped;
    } catch (_) {
      return const [];
    }
  }
}

/// Эмоҷиҳои ба наздикӣ истифодашуда (панели эмоҷӣ ва реаксияҳо).
class RecentEmojisStore {
  static const _store = _RecentStore('recent_emojis_v1');
  static Future<List<String>> load() => _store.load();
  static Future<List<String>> markUsed(String emoji) => _store.markUsed(emoji);
}

/// Стикерҳои ба наздикӣ истифодашуда.
class RecentStickersStore {
  static const _store = _RecentStore('recent_stickers_v1', max: 16);
  static Future<List<String>> load() => _store.load();
  static Future<List<String>> markUsed(String sticker) => _store.markUsed(sticker);
}
