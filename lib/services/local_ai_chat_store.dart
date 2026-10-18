import 'dart:convert';

import 'package:chatapp/models/chat_message.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// History for a user's private AI assistant is stored on this device only.
/// The prompt is still sent to the configured AI provider to produce a reply,
/// but conversation history is not written to Firestore.
class LocalAiChatStore {
  LocalAiChatStore._();

  static final LocalAiChatStore instance = LocalAiChatStore._();
  static const int maxMessages = 300;

  String _messagesKey(String uid) => 'chatapp.ai_history.$uid';
  String _migrationKey(String uid) => 'chatapp.ai_history_migrated.$uid';

  Future<List<ChatMessage>> load(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_messagesKey(uid));
    if (raw == null || raw.isEmpty) return <ChatMessage>[];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <ChatMessage>[];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(_messageFromJson)
          .toList(growable: true);
    } catch (_) {
      // A malformed cache must never prevent the AI screen from opening.
      return <ChatMessage>[];
    }
  }

  Future<ChatMessage> add({
    required String uid,
    required String text,
    required String senderId,
    required bool isAI,
    String? mediaUrl,
    String? mediaType,
  }) async {
    final messages = await load(uid);
    final message = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text,
      senderId: senderId,
      isAI: isAI,
      timestamp: DateTime.now(),
      mediaUrl: mediaUrl,
      mediaType: mediaType,
    );
    messages.add(message);
    final first = messages.length > maxMessages ? messages.length - maxMessages : 0;
    await _save(uid, messages.skip(first).toList(growable: false));
    return message;
  }

  Future<void> delete(String uid, String messageId) async {
    final messages = await load(uid);
    messages.removeWhere((message) => message.id == messageId);
    await _save(uid, messages);
  }

  Future<void> clear(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_messagesKey(uid));
  }

  Future<bool> isLegacyMigrationComplete(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_migrationKey(uid)) ?? false;
  }

  Future<void> migrateLegacyMessages(
    String uid,
    List<ChatMessage> legacyMessages,
  ) async {
    final current = await load(uid);
    final knownIds = current.map((message) => message.id).toSet();
    for (final message in legacyMessages) {
      if (!knownIds.contains(message.id)) current.add(message);
    }
    current.sort((a, b) => (a.timestamp ?? DateTime(1970))
        .compareTo(b.timestamp ?? DateTime(1970)));
    final first = current.length > maxMessages ? current.length - maxMessages : 0;
    await _save(uid, current.skip(first).toList(growable: false));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_migrationKey(uid), true);
  }

  Map<String, dynamic> _messageToJson(ChatMessage message) => {
        'id': message.id,
        'text': message.text,
        'senderId': message.senderId,
        'isAI': message.isAI,
        'timestamp': message.timestamp?.toIso8601String(),
        'mediaUrl': message.mediaUrl,
        'mediaType': message.mediaType,
      };

  ChatMessage _messageFromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        text: json['text']?.toString() ?? '',
        senderId: json['senderId']?.toString() ?? '',
        isAI: json['isAI'] == true,
        timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? ''),
        mediaUrl: json['mediaUrl']?.toString(),
        mediaType: json['mediaType']?.toString(),
      );

  Future<void> _save(String uid, List<ChatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _messagesKey(uid),
      jsonEncode(messages.map(_messageToJson).toList(growable: false)),
    );
  }
}
