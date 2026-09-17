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

  static Future<void> markRead(String conversationId, String uid) {
    return _ref(conversationId).set({
      'unread': {uid: 0},
    }, SetOptions(merge: true));
  }
}
