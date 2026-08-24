import 'package:cloud_firestore/cloud_firestore.dart';

/// Ҳуҷҷати `conversations/{id}` — сӯҳбати воқеӣ байни ду корбари
/// бо телефон бақайдгирифташуда.
class AppConversation {
  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final String? lastSenderId;

  AppConversation({
    required this.id,
    required this.participants,
    required this.participantNames,
    this.lastMessage = '',
    this.lastMessageTime,
    this.lastSenderId,
  });

  factory AppConversation.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final rawNames = (data['participantNames'] as Map<String, dynamic>?) ?? {};
    return AppConversation(
      id: doc.id,
      participants: List<String>.from(data['participants'] as List? ?? []),
      participantNames: rawNames.map((k, v) => MapEntry(k, v as String)),
      lastMessage: (data['lastMessage'] ?? '') as String,
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate(),
      lastSenderId: data['lastSenderId'] as String?,
    );
  }

  /// Номи тарафи муқобил барои корбари ҷорӣ
  String otherName(String currentUid) {
    final uid = otherUid(currentUid);
    return participantNames[uid] ?? 'Корбар';
  }

  String otherUid(String currentUid) {
    return participants.firstWhere((p) => p != currentUid, orElse: () => '');
  }

  /// ID-и якхела барои ҳар ҷуфти корбар (новобаста аз тартиб)
  static String idFor(String uidA, String uidB) {
    final sorted = [uidA, uidB]..sort();
    return sorted.join('_');
  }
}
