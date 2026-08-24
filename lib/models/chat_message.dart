import 'package:cloud_firestore/cloud_firestore.dart';

/// Ҳар ҳуҷҷат дар `.../messages` ба ин сохтор мувофиқат мекунад:
/// { text, senderId, isAI, createdAt, replyToText?, replyToSenderId?,
///   deleted?, read? }
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
  });

  factory ChatMessage.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
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
    );
  }
}
