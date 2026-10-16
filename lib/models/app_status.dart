import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import 'status_style.dart';

/// Ҳуҷҷати `statuses/{uid}/items/{id}` — як навсозии статус (мисли Stories).
/// Статусҳо пас аз 24 соат "гузашта" ҳисоб мешаванд (тибқи expiresAt).
class AppStatus {
  final String id;
  final String ownerId;
  final String ownerName;
  final String? text;
  final String? imageUrl;
  final String? musicUrl;
  final String? musicName;
  final String? stickerEmoji;
  final List<List<Offset>> drawingStrokes;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final List<String> viewedBy;

  /// Шакли матн — барои статуси матнӣ. Барои акс истифода намешавад.
  final StatusStyle style;

  AppStatus({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    this.text,
    this.imageUrl,
    this.musicUrl,
    this.musicName,
    this.stickerEmoji,
    this.drawingStrokes = const [],
    this.createdAt,
    this.expiresAt,
    this.viewedBy = const [],
    this.style = const StatusStyle(),
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
      ownerName: (data['ownerName'] ?? tr('k002')) as String,
      text: data['text'] as String?,
      imageUrl: data['imageUrl'] as String?,
      musicUrl: data['musicUrl'] as String?,
      musicName: data['musicName'] as String?,
      stickerEmoji: data['stickerEmoji'] as String?,
      drawingStrokes: ((data['drawingStrokes'] as List?) ?? const [])
          .whereType<List>()
          .map((stroke) => stroke.whereType<Map>().map((point) {
                final x = (point['x'] as num?)?.toDouble() ?? 0.0;
                final y = (point['y'] as num?)?.toDouble() ?? 0.0;
                return Offset(x.clamp(0.0, 1.0).toDouble(), y.clamp(0.0, 1.0).toDouble());
              }).toList())
          .toList(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      viewedBy: List<String>.from(data['viewedBy'] as List? ?? []),
      style: StatusStyle.fromMap(data),
    );
  }

  Map<String, dynamic> toMap() {
    final now = DateTime.now();
    return {
      'ownerId': ownerId,
      'ownerName': ownerName,
      if (text != null) 'text': text,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (musicUrl != null) 'musicUrl': musicUrl,
      if (musicName != null) 'musicName': musicName,
      if (stickerEmoji != null) 'stickerEmoji': stickerEmoji,
      'drawingStrokes': drawingStrokes.map((stroke) => stroke.map((point) => {'x': point.dx, 'y': point.dy}).toList()).toList(),
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(now.add(const Duration(hours: 24))),
      'viewedBy': <String>[],
      ...style.toMap(),
    };
  }
}
