import 'package:cloud_firestore/cloud_firestore.dart';

/// Дар Firestore дархости `where(arrayContains: ...)` якҷоя бо `orderBy(...)`
/// индекси мураккаб талаб мекунад, вагарна FAILED_PRECONDITION медиҳад. Барои
/// он ки барнома бидуни сохтани индекси дастӣ дар Firebase Console кор кунад,
/// `orderBy`-ро аз дархост мебардорем ва натиҷаро дар ин ҷо мураттаб мекунем.
/// Рӯйхати чатҳо/зангҳои як корбар хурд аст, пас ин арзон аст.
List<QueryDocumentSnapshot<Map<String, dynamic>>> sortByTimeDesc(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  String field,
) {
  final sorted = [...docs];
  sorted.sort((a, b) {
    final aTime = a.data()[field];
    final bTime = b.data()[field];
    // Ҳуҷҷатҳои бе вақт (масалан ҳанӯз serverTimestamp нагирифта) ба охир.
    if (aTime is! Timestamp) return bTime is Timestamp ? 1 : 0;
    if (bTime is! Timestamp) return -1;
    return bTime.compareTo(aTime);
  });
  return sorted;
}
