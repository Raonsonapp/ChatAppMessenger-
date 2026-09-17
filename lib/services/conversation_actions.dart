import 'package:cloud_firestore/cloud_firestore.dart';

/// Амалҳои рӯйхати чатҳо: мустаҳкам, бойгонӣ, хомӯш.
///
/// Ҳар як аз инҳо танҳо ба як корбар тааллуқ дорад, бинобар ин дар ҳуҷҷати
/// сӯҳбат ҳамчун рӯйхати uid-ҳо нигоҳ дошта мешавад — тарафи муқобил чати
/// худро мустақилона идора мекунад.
class ConversationActions {
  static DocumentReference<Map<String, dynamic>> _ref(String conversationId) =>
      FirebaseFirestore.instance.collection('conversations').doc(conversationId);

  static Future<void> setPinned(String conversationId, String uid, bool pinned) {
    return _ref(conversationId).set({
      'pinnedBy': pinned ? FieldValue.arrayUnion([uid]) : FieldValue.arrayRemove([uid]),
    }, SetOptions(merge: true));
  }

  static Future<void> setArchived(String conversationId, String uid, bool archived) {
    return _ref(conversationId).set({
      'archivedBy': archived ? FieldValue.arrayUnion([uid]) : FieldValue.arrayRemove([uid]),
    }, SetOptions(merge: true));
  }

  static Future<void> setMuted(String conversationId, String uid, bool muted) {
    return _ref(conversationId).set({
      'mutedBy': muted ? FieldValue.arrayUnion([uid]) : FieldValue.arrayRemove([uid]),
    }, SetOptions(merge: true));
  }

  /// Чатро танҳо барои ҳамин корбар нест мекунад: он аз рӯйхат мебарояд ва
  /// таърихи паёмҳо барои ӯ пинҳон мешавад. Тарафи муқобил чати худро пурра
  /// мебинад — мисли WhatsApp. Паёми нав чатро дубора бармегардонад.
  static Future<void> deleteForMe(String conversationId, String uid) async {
    await _ref(conversationId).set({
      'deletedBy': FieldValue.arrayUnion([uid]),
      'unread': {uid: 0},
    }, SetOptions(merge: true));

    // Паёмҳо дар як дархост пинҳон карда мешаванд; ҳудуди як batch 500 амал
    // аст, бинобар ин онҳоро ба қисмҳо тақсим мекунем.
    final messages = await _ref(conversationId).collection('messages').get();
    final db = FirebaseFirestore.instance;
    const chunk = 400;
    for (var i = 0; i < messages.docs.length; i += chunk) {
      final batch = db.batch();
      for (final doc in messages.docs.skip(i).take(chunk)) {
        batch.update(doc.reference, {
          'deletedFor': FieldValue.arrayUnion([uid]),
        });
      }
      await batch.commit();
    }
  }

  static Future<void> markRead(String conversationId, String uid) {
    return _ref(conversationId).set({
      'unread': {uid: 0},
    }, SetOptions(merge: true));
  }
}
