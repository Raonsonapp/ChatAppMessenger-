import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Quick replies are personal templates, stored locally on this device.
class QuickReply {
  const QuickReply({required this.shortcut, required this.message});

  final String shortcut;
  final String message;

  Map<String, String> toJson() => {'shortcut': shortcut, 'message': message};

  factory QuickReply.fromJson(Map<String, dynamic> json) => QuickReply(
        shortcut: (json['shortcut'] ?? '').toString(),
        message: (json['message'] ?? '').toString(),
      );
}

class QuickReplyService {
  static const _storageKey = 'chatapp_quick_replies_v1';

  static Future<List<QuickReply>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((item) => QuickReply.fromJson(Map<String, dynamic>.from(item)))
          .where((item) => item.shortcut.trim().isNotEmpty && item.message.trim().isNotEmpty)
          .toList(growable: false);
    } on FormatException {
      return const [];
    } on TypeError {
      return const [];
    }
  }

  static Future<void> save(List<QuickReply> replies) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = <String, QuickReply>{};
    for (final reply in replies) {
      final shortcut = reply.shortcut.trim().replaceFirst(RegExp(r'^/+'), '');
      final message = reply.message.trim();
      if (shortcut.isEmpty || message.isEmpty) continue;
      normalized[shortcut] = QuickReply(shortcut: shortcut, message: message);
    }
    await prefs.setString(
      _storageKey,
      jsonEncode(normalized.values.map((reply) => reply.toJson()).toList()),
    );
  }

  static Future<void> upsert(QuickReply reply) async {
    final replies = await load();
    final key = reply.shortcut.trim().replaceFirst(RegExp(r'^/+'), '');
    final next = replies.where((item) => item.shortcut != key).toList();
    next.add(QuickReply(shortcut: key, message: reply.message.trim()));
    await save(next);
  }

  static Future<void> remove(String shortcut) async {
    final key = shortcut.trim().replaceFirst(RegExp(r'^/+'), '');
    await save((await load()).where((item) => item.shortcut != key).toList());
  }
}
