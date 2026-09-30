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

  /// Ҳама чатҳо ва гурӯҳҳои корбарро хонда қайд мекунад.
  ///
  /// Танҳо онҳое навишта мешаванд ки воқеан ҳисоби нохонда доранд — то як
  /// пахши тугма садҳо навиштани бефоида ба Firestore накунад. Натиҷа шумораи
  /// чатҳои тағйирёфта аст.
  static Future<int> markAllRead(String uid) async {
    final db = FirebaseFirestore.instance;
    final conversations = await db
        .collection('conversations')
        .where('participants', arrayContains: uid)
        .get();
    final groups = await db.collection('groups').where('members', arrayContains: uid).get();

    final targets = <DocumentReference<Map<String, dynamic>>>[];
    for (final doc in [...conversations.docs, ...groups.docs]) {
      final unread = doc.data()['unread'];
      final mine = unread is Map ? unread[uid] : null;
      if (mine is num && mine > 0) targets.add(doc.reference);
    }
    if (targets.isEmpty) return 0;

    // Ҳудуди як batch дар Firestore 500 амал аст.
    const chunk = 400;
    for (var start = 0; start < targets.length; start += chunk) {
      final batch = db.batch();
      for (final ref in targets.skip(start).take(chunk)) {
        batch.set(ref, {'unread': {uid: 0}}, SetOptions(merge: true));
      }
      await batch.commit();
    }
    return targets.length;
  }

  /// Чатро ҳамчун нохонда қайд мекунад — то корбар баъдтар ба он баргардад.
  ///
  /// Як нишони нохонда гузошта мешавад, на ҳисоби воқеӣ: ҳадаф хотиррасон
  /// кардан аст, на ҳисоб кардани паёмҳо.
  static Future<void> markUnread(String conversationId, String uid) {
    return _ref(conversationId).set({
      'unread': {uid: 1},
    }, SetOptions(merge: true));
  }
}
