import 'package:cloud_firestore/cloud_firestore.dart';
import '../l10n/l10n.dart';

/// Ҳуҷҷати `conversations/{id}` — сӯҳбати воқеӣ байни ду корбари
/// бо телефон бақайдгирифташуда.
class AppConversation {
  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final String? lastSenderId;

  /// Шумораи паёмҳои нохондашуда барои ҳар иштирокчӣ: `{uid: 3}`.
  ///
  /// Он ҳангоми фиристодан зиёд ва ҳангоми кушодани чат сифр карда мешавад —
  /// ин аз ҳисоб кардани паёмҳо дар рӯйхат хеле арзонтар аст ва ба индекси
  /// мураккаб ниёз надорад.
  final Map<String, int> unread;

  /// Корбароне, ки ин сӯҳбатро мустаҳкам / бойгонӣ / хомӯш кардаанд.
  final List<String> pinnedBy;
  final List<String> archivedBy;
  final List<String> mutedBy;

  AppConversation({
    required this.id,
    required this.participants,
    required this.participantNames,
    this.lastMessage = '',
    this.lastMessageTime,
    this.lastSenderId,
    this.unread = const {},
    this.pinnedBy = const [],
    this.archivedBy = const [],
    this.mutedBy = const [],
  });

  factory AppConversation.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final rawNames = (data['participantNames'] as Map<String, dynamic>?) ?? {};
    final rawUnread = (data['unread'] as Map<String, dynamic>?) ?? {};
    return AppConversation(
      id: doc.id,
      participants: List<String>.from(data['participants'] as List? ?? []),
      participantNames: rawNames.map((k, v) => MapEntry(k, v as String)),
      lastMessage: (data['lastMessage'] ?? '') as String,
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate(),
      lastSenderId: data['lastSenderId'] as String?,
      unread: rawUnread.map((k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0)),
      pinnedBy: List<String>.from(data['pinnedBy'] as List? ?? []),
      archivedBy: List<String>.from(data['archivedBy'] as List? ?? []),
      mutedBy: List<String>.from(data['mutedBy'] as List? ?? []),
    );
  }

  /// Номи тарафи муқобил барои корбари ҷорӣ
  String otherName(String currentUid) {
    final uid = otherUid(currentUid);
    return participantNames[uid] ?? tr('k002');
  }

  int unreadFor(String currentUid) => unread[currentUid] ?? 0;

  bool isPinned(String currentUid) => pinnedBy.contains(currentUid);
  bool isArchived(String currentUid) => archivedBy.contains(currentUid);
  bool isMuted(String currentUid) => mutedBy.contains(currentUid);

  String otherUid(String currentUid) {
    return participants.firstWhere((p) => p != currentUid, orElse: () => '');
  }

  /// ID-и якхела барои ҳар ҷуфти корбар (новобаста аз тартиб)
  static String idFor(String uidA, String uidB) {
    final sorted = [uidA, uidB]..sort();
    return sorted.join('_');
  }
}
