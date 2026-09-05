import 'package:cloud_firestore/cloud_firestore.dart';

/// Ҳуҷҷати `statuses/{uid}/items/{id}` — як навсозии статус (мисли Stories).
/// Статусҳо пас аз 24 соат "гузашта" ҳисоб мешаванд (тибқи expiresAt).
class AppStatus {
  final String id;
  final String ownerId;
  final String ownerName;
  final String? text;
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final List<String> viewedBy;

  AppStatus({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    this.text,
    this.imageUrl,
    this.createdAt,
    this.expiresAt,
    this.viewedBy = const [],
  });

  bool get isExpired {
    final exp = expiresAt;
    if (exp == null) return false;
    return DateTime.now().isAfter(exp);
  }

  factory AppStatus.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return AppStatus(
      id: doc.id,
      ownerId: (data['ownerId'] ?? '') as String,
      ownerName: (data['ownerName'] ?? 'Корбар') as String,
      text: data['text'] as String?,
      imageUrl: data['imageUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      viewedBy: List<String>.from(data['viewedBy'] as List? ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    final now = DateTime.now();
    return {
      'ownerId': ownerId,
      'ownerName': ownerName,
      if (text != null) 'text': text,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(now.add(const Duration(hours: 24))),
      'viewedBy': <String>[],
    };
  }
}
