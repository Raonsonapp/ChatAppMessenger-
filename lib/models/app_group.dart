import 'package:cloud_firestore/cloud_firestore.dart';
import '../l10n/l10n.dart';

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

  /// Шумораи паёмҳои нохондашуда барои ҳар узв.
  final Map<String, int> unread;

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
    this.unread = const {},
  });

  int unreadFor(String uid) => unread[uid] ?? 0;

  factory AppGroup.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final rawNames = (data['memberNames'] as Map<String, dynamic>?) ?? {};
    final rawUnread = (data['unread'] as Map<String, dynamic>?) ?? {};
    return AppGroup(
      id: doc.id,
      name: (data['name'] ?? tr('k005')) as String,
      members: List<String>.from(data['members'] as List? ?? []),
      memberNames: rawNames.map((k, v) => MapEntry(k, v as String)),
      admins: List<String>.from(data['admins'] as List? ?? []),
      createdBy: (data['createdBy'] ?? '') as String,
      lastMessage: (data['lastMessage'] ?? '') as String,
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate(),
      lastSenderId: data['lastSenderId'] as String?,
      unread: rawUnread.map((k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0)),
    );
  }
}
