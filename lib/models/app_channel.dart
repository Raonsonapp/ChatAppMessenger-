import 'package:cloud_firestore/cloud_firestore.dart';

/// Ҳуҷҷати `channels/{id}` — канали пахши WhatsApp/Telegram-тарз: танҳо
/// соҳиб (ownerId) паём мефиристад, дигарон танҳо мехонанд/обуна мешаванд.
class AppChannel {
  final String id;
  final String name;
  final String description;
  final String ownerId;
  final String ownerName;
  final List<String> followers;
  final String lastMessage;
  final DateTime? lastMessageTime;

  AppChannel({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.ownerName,
    required this.followers,
    this.lastMessage = '',
    this.lastMessageTime,
  });

  factory AppChannel.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return AppChannel(
      id: doc.id,
      name: (data['name'] ?? 'Канал') as String,
      description: (data['description'] ?? '') as String,
      ownerId: (data['ownerId'] ?? '') as String,
      ownerName: (data['ownerName'] ?? '') as String,
      followers: List<String>.from(data['followers'] as List? ?? []),
      lastMessage: (data['lastMessage'] ?? '') as String,
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate(),
    );
  }
}
