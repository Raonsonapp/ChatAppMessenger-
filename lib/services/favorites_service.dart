import 'package:cloud_firestore/cloud_firestore.dart';

/// Контактҳои дӯстдошта — барои зангҳои зуд.
///
/// Рӯйхат дар ҳуҷҷати худи корбар нигоҳ дошта мешавад, бинобар ин ба
/// коллексияи нав ва қоидаҳои нав ниёз надорад.
class FavoritesService {
  static DocumentReference<Map<String, dynamic>> _ref(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid);

  /// Ба рӯйхат илова мекунад ё аз он мебарорад.
  ///
  /// `true` — агар илова шуда бошад.
  static Future<bool> toggle(String uid, String otherUid) async {
    final snapshot = await _ref(uid).get();
    final current =
        List<String>.from(snapshot.data()?['favorites'] as List? ?? const []);
    final adding = !current.contains(otherUid);

    await _ref(uid).set({
      'favorites': adding
          ? FieldValue.arrayUnion([otherUid])
          : FieldValue.arrayRemove([otherUid]),
    }, SetOptions(merge: true));

    return adding;
  }

  /// Ҷараёни рӯйхати дӯстдоштаҳо.
  static Stream<List<String>> watch(String uid) {
    return _ref(uid).snapshots().map(
          (doc) =>
              List<String>.from(doc.data()?['favorites'] as List? ?? const []),
        );
  }
}
