import 'package:cloud_firestore/cloud_firestore.dart';

/// Навъи эълон дар Бозор.
///
/// Чор навъ як коллексия ва як экранро истифода мебарад — сохтори онҳо якхела
/// аст (соҳиб, сарлавҳа, тавсиф, нарх, шаҳр, расм) ва ҷудо кардани онҳо ба
/// чор система танҳо такрори код медод.
enum ListingKind {
  product('product'),
  service('service'),
  job('job'),
  ad('ad');

  const ListingKind(this.code);
  final String code;

  static ListingKind fromCode(String? code) {
    for (final kind in ListingKind.values) {
      if (kind.code == code) return kind;
    }
    return ListingKind.product;
  }
}

/// Як эълон: маҳсулот, хизмат, ҷойи кор ё эълони одӣ.
class Listing {
  const Listing({
    required this.id,
    required this.kind,
    required this.ownerId,
    required this.ownerName,
    required this.title,
    this.description = '',
    this.price,
    this.city = '',
    this.category = '',
    this.images = const [],
    this.active = true,
    this.createdAt,
  });

  final String id;
  final ListingKind kind;
  final String ownerId;
  final String ownerName;
  final String title;
  final String description;

  /// Нарх ё маош. `null` — нишон дода нашудааст (барои эълон ва баъзе хизматҳо
  /// ин ҳолати муқаррарӣ аст).
  final num? price;

  final String city;
  final String category;
  final List<String> images;
  final bool active;
  final DateTime? createdAt;

  String? get coverImage => images.isEmpty ? null : images.first;

  factory Listing.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    final rawPrice = data['price'];
    return Listing(
      id: doc.id,
      kind: ListingKind.fromCode(data['kind'] as String?),
      ownerId: (data['ownerId'] ?? '') as String,
      ownerName: (data['ownerName'] ?? '') as String,
      title: (data['title'] ?? '') as String,
      description: (data['description'] ?? '') as String,
      price: rawPrice is num ? rawPrice : null,
      city: (data['city'] ?? '') as String,
      category: (data['category'] ?? '') as String,
      images: (data['images'] as List?)?.whereType<String>().toList() ?? const [],
      active: (data['active'] ?? true) as bool,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'kind': kind.code,
        'ownerId': ownerId,
        'ownerName': ownerName,
        'title': title,
        'titleLower': title.toLowerCase(),
        'description': description,
        if (price != null) 'price': price,
        'city': city,
        'category': category,
        'images': images,
        'active': active,
        'createdAt': FieldValue.serverTimestamp(),
      };

  /// Оё эълон ба дархости ҷустуҷӯ мувофиқ аст.
  ///
  /// Ҷустуҷӯ дар тарафи барнома иҷро мешавад — ҳамон тарзе ки ҷустуҷӯи корбар
  /// кор мекунад. Ин индекси муштаракро талаб намекунад.
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return title.toLowerCase().contains(q) ||
        description.toLowerCase().contains(q) ||
        city.toLowerCase().contains(q) ||
        category.toLowerCase().contains(q);
  }
}
