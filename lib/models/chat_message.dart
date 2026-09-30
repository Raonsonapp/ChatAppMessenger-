import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/waveform.dart';

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

  /// Кӣ паёмро гирифт ва кӣ хонд.
  ///
  /// Рӯйхат нигоҳ дошта мешавад, на танҳо «ҳа/не»: дар гурӯҳ фарқ кардан
  /// лозим аст, ки кадом узв паёмро гирифт ва кадомаш хонд.
  final List<String> deliveredTo;
  final List<String> readBy;

  /// Ҳолати фиристодан — танҳо дар дастгоҳи ФИРИСТАНДА маъно дорад.
  final MessageStatus status;

  /// Шиносаи маҳаллӣ, ки пеш аз фиристодан сохта мешавад.
  ///
  /// Бе он такрори паём ҳангоми бозфиристодан пешгирӣ намешавад: агар
  /// навиштан ноком шавад, вале дар асл ба сервер расида бошад, кӯшиши дуюм
  /// нусхаи дуюмро месозад.
  final String? clientId;
  final String? mediaUrl;
  final String? mediaType;

  /// Давомнокӣ бо сония — барои `audio` ва `video`.
  final int? mediaDuration;

  /// Мавҷи садо (0…1) — қиматҳои воқеии микрофон ҳангоми сабт.
  ///
  /// Холӣ бошад, плеер хати оддиро нишон медиҳад. Бандҳои тасодуфӣ кашида
  /// намешаванд: он қуллаҳоеро нишон медод, ки ба садо рабте надоранд.
  final List<double> waveform;

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
    this.deliveredTo = const [],
    this.readBy = const [],
    this.status = MessageStatus.sent,
    this.clientId,
    this.mediaUrl,
    this.mediaType,
    this.mediaDuration,
    this.waveform = const [],
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
      deliveredTo: List<String>.from(data['deliveredTo'] as List? ?? const []),
      readBy: List<String>.from(data['readBy'] as List? ?? const []),
      clientId: data['clientId'] as String?,
      // Ҳуҷҷат дар Firestore аст, яъне фиристодан аллакай муваффақ шуд.
      status: MessageStatus.sent,
      mediaUrl: data['mediaUrl'] as String?,
      mediaType: data['mediaType'] as String?,
      mediaDuration: (data['mediaDuration'] as num?)?.toInt(),
      waveform: Waveform.parse(data['waveform']),
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


/// Ҳолати фиристодани паём — мисли WhatsApp.
///
/// `sending` ва `failed` танҳо дар дастгоҳи фиристанда вуҷуд доранд: паёме
/// ки ҳанӯз ба сервер нарасидааст, дар Firestore ҳуҷҷат надорад.
enum MessageStatus { sending, sent, delivered, read, failed }

extension MessageDelivery on ChatMessage {
  /// Ҳолати воқеӣ барои нишонаҳои ✓/✓✓ дар назди паёми ХУДАМ.
  ///
  /// [others] — иштирокчиёни дигар (дар чати шахсӣ якто, дар гурӯҳ ҳама).
  /// Дар гурӯҳ ✓✓ вақте нишон дода мешавад, ки ҲАМА гирифта/хонда бошанд —
  /// ҳамон тавре ки WhatsApp мекунад.
  MessageStatus deliveryStatus(List<String> others) {
    if (status == MessageStatus.sending || status == MessageStatus.failed) {
      return status;
    }
    if (others.isEmpty) return MessageStatus.sent;

    final everyoneRead = others.every(readBy.contains);
    if (everyoneRead) return MessageStatus.read;

    // Хондан гирифтанро дар бар мегирад: агар корбар хонда бошад, вале дар
    // `deliveredTo` набошад (масалан навсозии кӯҳна), ӯ ба ҳар ҳол гирифтааст.
    final everyoneGot = others.every(
      (uid) => deliveredTo.contains(uid) || readBy.contains(uid),
    );
    if (everyoneGot) return MessageStatus.delivered;

    // Майдонҳои кӯҳна: паёмҳои пеш аз ин навсозӣ `readBy` надоранд.
    if (read) return MessageStatus.read;
    return MessageStatus.sent;
  }
}
