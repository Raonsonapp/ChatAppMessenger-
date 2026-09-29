import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Қайди «гирифта шуд» ва «хонда шуд» барои паёмҳо.
///
/// Ин маълумот дар худи ҳуҷҷати паём нигоҳ дошта мешавад, на дар ҳолати
/// маҳаллӣ: тирчаҳои ✓✓ бояд дар ҳамаи дастгоҳҳо якхела бошанд ва пас аз
/// аз нав кушодани барнома нест нашаванд.
class MessageStatusService {
  /// Ҳадди як баста — Firestore то 500 амалро қабул мекунад.
  static const _batchLimit = 400;

  /// Паёмҳои дидашударо ҳамчун «расид» қайд мекунад.
  ///
  /// Ин ҳангоми КУШОДА ШУДАНИ рӯйхати паёмҳо даъват мешавад — яъне паём ба
  /// дастгоҳ расид, ҳарчанд корбар онро ҳанӯз нахонда бошад.
  static Future<void> markDelivered(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) =>
      _mark(docs, 'deliveredTo');

  /// Паёмҳоро ҳамчун «хонда шуд» қайд мекунад.
  static Future<void> markRead(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) =>
      _mark(docs, 'readBy', alsoLegacyRead: true);

  static Future<void> _mark(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String field, {
    bool alsoLegacyRead = false,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || docs.isEmpty) return;

    // Танҳо паёмҳои КАСИ ДИГАР ва танҳо онҳое ки ҳанӯз қайд нашудаанд.
    // Бе ин филтр ҳар кушодани чат садҳо навиштани беҳудаи Firestore месозад.
    final pending = docs.where((doc) {
      final data = doc.data();
      if (data['senderId'] == uid) return false;
      final marked = List<String>.from(data[field] as List? ?? const []);
      return !marked.contains(uid);
    }).toList();

    if (pending.isEmpty) return;

    final db = FirebaseFirestore.instance;
    for (var i = 0; i < pending.length; i += _batchLimit) {
      final chunk = pending.skip(i).take(_batchLimit);
      final batch = db.batch();
      for (final doc in chunk) {
        batch.update(doc.reference, {
          field: FieldValue.arrayUnion([uid]),
          // Майдони кӯҳна нигоҳ дошта мешавад, то нусхаҳои кӯҳнаи барнома
          // тирчаҳоро дуруст нишон диҳанд.
          if (alsoLegacyRead) 'read': true,
        });
      }
      // Хатогӣ фурӯ бурда мешавад: қайди ҳолат набояд хондани чатро вайрон
      // кунад.
      try {
        await batch.commit();
      } catch (_) {
        return;
      }
    }
  }
}
