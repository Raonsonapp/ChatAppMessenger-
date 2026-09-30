import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/ledger_entry.dart';

/// Дафтари бизнес — сабтҳои шахсии соҳиби ҳисоб.
///
/// Дар зерколлексияи `users/{uid}/ledger` мемонад: ин маълумоти хеле шахсист
/// (кӣ ба ман чанд қарздор аст) ва ҳељ кас ба ҷуз соҳиб набояд онро бинад.
class LedgerService {
  LedgerService._();

  /// Ҳадди сабтҳои хондашаванда. Дафтари калонтар аз ин барои телефон вазнин
  /// аст ва ба ҳар ҳол варақ задан лозим мешавад.
  static const int fetchLimit = 500;

  static CollectionReference<Map<String, dynamic>> _ref(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('ledger');

  static Stream<List<LedgerEntry>> watch(String uid) {
    return _ref(uid).limit(fetchLimit).snapshots().map((snapshot) {
      final entries = snapshot.docs.map(LedgerEntry.fromDoc).toList();
      // Наваш дар боло. Сабти ҳанӯз бе мӯҳри сервер низ дар боло меистад,
      // вагарна сабти нави корбар дар охир пайдо мешавад.
      entries.sort((a, b) {
        final at = a.createdAt, bt = b.createdAt;
        if (at == null && bt == null) return 0;
        if (at == null) return -1;
        if (bt == null) return 1;
        return bt.compareTo(at);
      });
      return entries;
    });
  }

  static Future<void> add(String uid, LedgerEntry entry) =>
      _ref(uid).add(entry.toMap());

  /// Қарзро пӯшида ё аз нав кушода қайд мекунад.
  static Future<void> setSettled(String uid, String id, bool settled) =>
      _ref(uid).doc(id).set({'settled': settled}, SetOptions(merge: true));

  static Future<void> delete(String uid, String id) => _ref(uid).doc(id).delete();
}
