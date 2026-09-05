import 'package:cloud_firestore/cloud_firestore.dart';

/// Ҳар ҳуҷҷат дар `.../messages` ба ин сохтор мувофиқат мекунад:
/// { text, senderId, isAI, createdAt, replyToText?, replyToSenderId?,
///   deleted?, read?, mediaUrl?, mediaType? }
class ChatMessage {
  final String id;
  final String text;
  final String senderId;
  final bool isAI;
  final DateTime? timestamp;
  final String? replyToText;
  final String? replyToSenderId;
  final bool deleted;
  final bool read;
  final String? mediaUrl;
  final String? mediaType;
  final Map<String, String> reactions;

  ChatMessage({
    required this.id,
    required this.text,
    required this.senderId,
    required this.isAI,
    this.timestamp,
    this.replyToText,
    this.replyToSenderId,
    this.deleted = false,
    this.read = false,
    this.mediaUrl,
    this.mediaType,
    this.reactions = const {},
  });

  factory ChatMessage.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final rawReactions = (data['reactions'] as Map<String, dynamic>?) ?? {};
    return ChatMessage(
      id: doc.id,
      text: (data['text'] ?? '') as String,
      senderId: (data['senderId'] ?? '') as String,
      isAI: (data['isAI'] ?? false) as bool,
      timestamp: (data['createdAt'] as Timestamp?)?.toDate(),
      replyToText: data['replyToText'] as String?,
      replyToSenderId: data['replyToSenderId'] as String?,
      deleted: (data['deleted'] ?? false) as bool,
      read: (data['read'] ?? false) as bool,
      mediaUrl: data['mediaUrl'] as String?,
      mediaType: data['mediaType'] as String?,
      reactions: rawReactions.map((k, v) => MapEntry(k, v as String)),
    );
  }
}
