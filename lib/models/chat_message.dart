import 'package:cloud_firestore/cloud_firestore.dart';

/// Ҳар ҳуҷҷат дар `.../messages` ба ин сохтор мувофиқат мекунад:
/// { text, senderId, isAI, createdAt, replyToText?, replyToSenderId?,
///   deleted?, read?, mediaUrl?, mediaType?, mediaDuration?, mediaName?,
///   mediaSize?, edited?, deletedFor? }
///
/// mediaType: image | gif | sticker | audio | video | document | location | poll
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

  /// Давомнокӣ бо сония — барои `audio` ва `video`.
  final int? mediaDuration;

  /// Номи аслии файл — барои `document`.
  final String? mediaName;

  /// Ҳаҷми файл бо байт — барои `document`.
  final int? mediaSize;

  /// Паём аз чати дигар нусхабардорӣ шудааст.
  final bool forwarded;

  /// Матни паём пас аз фиристодан тағйир дода шудааст.
  final bool edited;

  /// Корбароне, ки паёмро танҳо барои худ нест кардаанд.
  final List<String> deletedFor;

  /// Пурсиш (poll): савол, вариантҳо ва овозҳо — `{uid: индекси вариант}`.
  final String? pollQuestion;
  final List<String> pollOptions;
  final Map<String, int> pollVotes;

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
    this.mediaDuration,
    this.mediaName,
    this.mediaSize,
    this.forwarded = false,
    this.edited = false,
    this.deletedFor = const [],
    this.pollQuestion,
    this.pollOptions = const [],
    this.pollVotes = const {},
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
      mediaDuration: (data['mediaDuration'] as num?)?.toInt(),
      mediaName: data['mediaName'] as String?,
      mediaSize: (data['mediaSize'] as num?)?.toInt(),
      forwarded: (data['forwarded'] ?? false) as bool,
      edited: (data['edited'] ?? false) as bool,
      deletedFor: List<String>.from(data['deletedFor'] as List? ?? []),
      pollQuestion: data['pollQuestion'] as String?,
      pollOptions: List<String>.from(data['pollOptions'] as List? ?? []),
      pollVotes: ((data['pollVotes'] as Map<String, dynamic>?) ?? {})
          .map((k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0)),
      reactions: rawReactions.map((k, v) => MapEntry(k, v as String)),
    );
  }
}
