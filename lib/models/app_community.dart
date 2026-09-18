import 'package:cloud_firestore/cloud_firestore.dart';
import '../l10n/l10n.dart';

/// Ҳуҷҷати `communities/{id}` — ҷамъияте, ки якчанд гурӯҳро дар як ҷо
/// ҷамъ мекунад. Барои соддагӣ, ҳар ҷамъият як чати умумӣ (Эълонҳо) дорад.
class AppCommunity {
  final String id;
  final String name;
  final String description;
  final List<String> members;
  final Map<String, String> memberNames;
  final List<String> admins;
  final String createdBy;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final String? lastSenderId;

  /// Навъи охирин паём (`image`, `audio`, `video`, `document`, `sticker`,
  /// `location`) — бо ёрии он матни кӯтоҳ бо забони бинанда сохта мешавад.
  final String? lastMessageType;

  /// Номи файл барои охирин паёми навъи `document`.
  final String? lastMessageName;

  /// Акси ҷамъият.
  final String? photoUrl;

  /// Шумораи паёмҳои нохондашуда барои ҳар узв.
  final Map<String, int> unread;

  AppCommunity({
    required this.id,
    required this.name,
    required this.description,
    required this.members,
    required this.memberNames,
    required this.admins,
    required this.createdBy,
    this.lastMessage = '',
    this.lastMessageTime,
    this.lastSenderId,
    this.lastMessageType,
    this.lastMessageName,
    this.photoUrl,
    this.unread = const {},
  });

  int unreadFor(String uid) => unread[uid] ?? 0;

  factory AppCommunity.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final rawNames = (data['memberNames'] as Map<String, dynamic>?) ?? {};
    return AppCommunity(
      id: doc.id,
      name: (data['name'] ?? tr('k004')) as String,
      description: (data['description'] ?? '') as String,
      members: List<String>.from(data['members'] as List? ?? []),
      memberNames: rawNames.map((k, v) => MapEntry(k, v as String)),
      admins: List<String>.from(data['admins'] as List? ?? []),
      createdBy: (data['createdBy'] ?? '') as String,
      lastMessage: (data['lastMessage'] ?? '') as String,
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate(),
      lastSenderId: data['lastSenderId'] as String?,
      lastMessageType: data['lastMessageType'] as String?,
      lastMessageName: data['lastMessageName'] as String?,
      photoUrl: data['photoUrl'] as String?,
      unread: ((data['unread'] as Map<String, dynamic>?) ?? {})
          .map((k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0)),
    );
  }
}
