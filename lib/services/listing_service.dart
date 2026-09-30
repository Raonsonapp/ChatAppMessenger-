import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/listing.dart';

/// Эълонҳои Бозор: маҳсулот, хизмат, ҷойи кор ва эълон.
///
/// Ҳама дар як коллексияи `listings` бо майдони `kind` мемонанд. Дархост танҳо
/// аз рӯи `kind` филтр мешавад ва тартиб дар тарафи барнома дода мешавад —
/// бинобар ин индекси муштарак лозим нест.
class ListingService {
  ListingService._();

  static CollectionReference<Map<String, dynamic>> get _ref =>
      FirebaseFirestore.instance.collection('listings');

  /// Ҳадди эълонҳои хондашаванда дар як дархост.
  static const int fetchLimit = 200;

  static Stream<List<Listing>> watchKind(ListingKind kind) {
    return _ref
        .where('kind', isEqualTo: kind.code)
        .limit(fetchLimit)
        .snapshots()
        .map(_toSortedList);
  }

  static Stream<List<Listing>> watchMine(String uid) {
    return _ref
        .where('ownerId', isEqualTo: uid)
        .limit(fetchLimit)
        .snapshots()
        .map(_toSortedList);
  }

  /// Ҷустуҷӯи умумӣ дар ҳама навъҳо — барои «Ҳамаро ҷустуҷӯ кунед».
  static Future<List<Listing>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final snapshot = await _ref.limit(fetchLimit).get();
    return _toSortedList(snapshot).where((l) => l.matches(q)).toList();
  }

  static List<Listing> _toSortedList(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final items = snapshot.docs
        .map(Listing.fromDoc)
        .where((listing) => listing.active && listing.title.isNotEmpty)
        .toList();
    // Наваш дар боло. Эълони бе `createdAt` (навиштани маҳаллӣ, ҳанӯз бе
    // мӯҳри сервер) низ дар боло меистад — вагарна корбар эълони худашро
    // фавран намебинад.
    items.sort((a, b) {
      final at = a.createdAt, bt = b.createdAt;
      if (at == null && bt == null) return 0;
      if (at == null) return -1;
      if (bt == null) return 1;
      return bt.compareTo(at);
    });
    return items;
  }

  /// Эълони нав месозад ва ID-и онро бармегардонад.
  static Future<String> create(Listing listing) async {
    final doc = await _ref.add(listing.toMap());
    return doc.id;
  }

  static Future<void> delete(String id) => _ref.doc(id).delete();

  /// Эълонро пинҳон мекунад бе нест кардан — таърихи сӯҳбатҳо бо харидор
  /// боқӣ мемонад.
  static Future<void> deactivate(String id) =>
      _ref.doc(id).set({'active': false}, SetOptions(merge: true));
}
