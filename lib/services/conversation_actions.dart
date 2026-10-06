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

  /// Чатро ба "Интихобшуда" (Favorites) илова/хориҷ мекунад — мисли
  /// мустаҳкам кардан, вале рӯйхати алоҳида дорад.
  static Future<void> setFavorite(String conversationId, String uid, bool favorite) {
    return _ref(conversationId).set({
      'favoriteBy': favorite ? FieldValue.arrayUnion([uid]) : FieldValue.arrayRemove([uid]),
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

  /// Ҳамаи чатҳои шахсии дорои паёми нохонда барои ин корбарро якбора
  /// хондашуда қайд мекунад (тугмаи "Ҳама хонда шуд" дар менюи 3-нуқта).
  /// Танҳо сӯҳбатҳои 1ба1-ро фаро мегирад — гурӯҳҳо ҳоло ин амалро надоранд.
  static Future<int> markAllRead(String uid) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('conversations')
        .where('participants', arrayContains: uid)
        .get();
    final toUpdate = snapshot.docs.where((doc) {
      final unread = (doc.data()['unread'] as Map<String, dynamic>?) ?? {};
      return ((unread[uid] as num?)?.toInt() ?? 0) > 0;
    }).toList();
    if (toUpdate.isEmpty) return 0;
    final db = FirebaseFirestore.instance;
    const chunk = 400;
    for (var i = 0; i < toUpdate.length; i += chunk) {
      final batch = db.batch();
      for (final doc in toUpdate.skip(i).take(chunk)) {
        batch.set(doc.reference, {
          'unread': {uid: 0},
        }, SetOptions(merge: true));
      }
      await batch.commit();
    }
    return toUpdate.length;
  }
}
