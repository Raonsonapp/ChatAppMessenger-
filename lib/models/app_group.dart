import 'package:cloud_firestore/cloud_firestore.dart';

/// Ҳуҷҷати `groups/{id}` — гурӯҳи воқеии чат бо якчанд аъзо.
class AppGroup {
  final String id;
  final String name;
  final List<String> members;
  final Map<String, String> memberNames;
  final List<String> admins;
  final String createdBy;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final String? lastSenderId;

  AppGroup({
    required this.id,
    required this.name,
    required this.members,
    required this.memberNames,
    required this.admins,
    required this.createdBy,
    this.lastMessage = '',
    this.lastMessageTime,
    this.lastSenderId,
  });

  factory AppGroup.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final rawNames = (data['memberNames'] as Map<String, dynamic>?) ?? {};
    return AppGroup(
      id: doc.id,
      name: (data['name'] ?? 'Гурӯҳ') as String,
      members: List<String>.from(data['members'] as List? ?? []),
      memberNames: rawNames.map((k, v) => MapEntry(k, v as String)),
      admins: List<String>.from(data['admins'] as List? ?? []),
      createdBy: (data['createdBy'] ?? '') as String,
      lastMessage: (data['lastMessage'] ?? '') as String,
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate(),
      lastSenderId: data['lastSenderId'] as String?,
    );
  }
}
