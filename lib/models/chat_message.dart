import 'package:cloud_firestore/cloud_firestore.dart';

/// Ҳар ҳуҷҷат дар `chats/{chatId}/messages` ба ин сохтор мувофиқат мекунад:
/// { text: string, senderId: string, isAI: bool, createdAt: Timestamp }
/// "isMe" дар Firestore захира намешавад — он вобаста ба корбари ҷорӣ аст,
/// бинобар ин дар вақти рендер (senderId == currentUid) ҳисоб карда мешавад.
class ChatMessage {
  final String id;
  final String text;
  final String senderId;
  final bool isAI;
  final DateTime? timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.senderId,
    required this.isAI,
    this.timestamp,
  });

  factory ChatMessage.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return ChatMessage(
      id: doc.id,
      text: (data['text'] ?? '') as String,
      senderId: (data['senderId'] ?? '') as String,
      isAI: (data['isAI'] ?? false) as bool,
      timestamp: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
