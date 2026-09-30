import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_conversation.dart';
import 'push_service.dart';

/// Натиҷаи фиристодани паёми умумӣ.
class BroadcastResult {
  const BroadcastResult({required this.sent, required this.failed});

  final int sent;
  final int failed;

  bool get allSent => failed == 0;
}

/// Паёми умумӣ — ҳамон тарзе ки WhatsApp кор мекунад: як матн ба чанд чати
/// шахсӣ ҷудогона фиристода мешавад. Ҳар қабулкунанда паёмро дар чати худ
/// мебинад ва намедонад ки он ба каси дигар низ рафтааст.
///
/// Ин гурӯҳ нест ва чати умумӣ насохта мешавад — паёмҳо воқеан дар
/// `conversations/{id}/messages` менишинанд.
class BroadcastService {
  BroadcastService._();

  /// Ҳадди қабулкунандагон — то як пахши тасодуфӣ садҳо навиштанро ба Firestore
  /// накунад.
  static const int maxRecipients = 50;

  static Future<BroadcastResult> send({
    required String fromUid,
    required String fromName,
    required Map<String, String> recipients,
    required String text,
  }) async {
    final message = text.trim();
    if (message.isEmpty || recipients.isEmpty) {
      return const BroadcastResult(sent: 0, failed: 0);
    }

    final db = FirebaseFirestore.instance;
    var sent = 0;
    var failed = 0;

    for (final entry in recipients.entries.take(maxRecipients)) {
      final toUid = entry.key;
      if (toUid == fromUid) continue;
      try {
        final conversationId = AppConversation.idFor(fromUid, toUid);
        final convoRef = db.collection('conversations').doc(conversationId);

        // Сӯҳбат метавонад ҳанӯз набошад — онро месозем.
        await convoRef.set({
          'participants': [fromUid, toUid],
          'participantNames': {fromUid: fromName, toUid: entry.value},
        }, SetOptions(merge: true));

        await convoRef.collection('messages').add({
          'text': message,
          'senderId': fromUid,
          'isAI': false,
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
          // Нишонаи хидматӣ: паём аз пахши умумӣ омадааст. Барои ҳисоботи
          // оянда лозим мешавад, ба корбар нишон дода намешавад.
          'viaBroadcast': true,
        });

        await convoRef.set({
          'lastMessage': message,
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastSenderId': fromUid,
          'lastMessageType': FieldValue.delete(),
          'unread': {toUid: FieldValue.increment(1)},
          'archivedBy': FieldValue.arrayRemove([fromUid, toUid]),
          'deletedBy': FieldValue.arrayRemove([fromUid, toUid]),
        }, SetOptions(merge: true));

        await PushService.notify(
          toUid: toUid,
          title: fromName,
          body: message,
          data: {
            'type': 'message',
            'conversationId': conversationId,
            'senderUid': fromUid,
            'text': message,
          },
        );
        sent++;
      } catch (_) {
        // Як қабулкунандаи баста набояд боқимондаро нигоҳ дорад.
        failed++;
      }
    }

    return BroadcastResult(sent: sent, failed: failed);
  }
}
