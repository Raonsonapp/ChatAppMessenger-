import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Матни нофиристодаи ҳар чат — мисли WhatsApp.
///
/// Дар ҳофизаи дастгоҳ нигоҳ дошта мешавад, на дар Firestore: нависта
/// нафиристода танҳо ба ҳамин дастгоҳ тааллуқ дорад ва ҳамсӯҳбат набояд онро
/// бубинад. Дар хотира як нусхаи ҳозира нигоҳ дошта мешавад, то рӯйхати чатҳо
/// онро бе интизорӣ хонда тавонад.
class DraftStore extends ChangeNotifier {
  static const String _prefsKey = 'chat_drafts';

  final Map<String, String> _drafts = {};

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _drafts
        ..clear()
        ..addAll(decoded.map((k, v) => MapEntry(k, '$v')));
    } catch (_) {
      // Нависта гум шуд — ин ҳалокатовар нест.
    }
  }

  String? read(String chatId) {
    final value = _drafts[chatId];
    return (value == null || value.isEmpty) ? null : value;
  }

  Future<void> write(String chatId, String text) async {
    final trimmed = text.trim();
    final previous = _drafts[chatId];
    if (trimmed.isEmpty) {
      if (previous == null) return;
      _drafts.remove(chatId);
    } else {
      if (previous == trimmed) return;
      _drafts[chatId] = trimmed;
    }
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(_drafts));
    } catch (_) {
      // Дар ин сессия ба ҳар ҳол дар хотира ҳаст.
    }
  }
}

/// Як нусха барои тамоми барнома.
final DraftStore draftStore = DraftStore();
