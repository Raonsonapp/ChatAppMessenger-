import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Чӣ гузориш дода мешавад.
enum ReportTarget { user, message, group, community }

/// Сабаби гузориш.
enum ReportReason { spam, abuse, violence, sexual, scam, other }

/// Гузориш дар бораи корбар, паём ё гурӯҳ.
///
/// Гузоришҳо дар коллексияи алоҳида нигоҳ дошта мешаванд, ки корбар онро
/// хонда наметавонад: касе набояд бубинад, ки кӣ ба ӯ шикоят кардааст.
class ReportService {
  static Future<void> submit({
    required ReportTarget target,
    required String targetId,
    required ReportReason reason,
    String? details,
    String? contextPath,
    String? contentSnapshot,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('not-signed-in');

    await FirebaseFirestore.instance.collection('reports').add({
      'reporterId': uid,
      'target': target.name,
      'targetId': targetId,
      'reason': reason.name,
      if (details != null && details.trim().isNotEmpty)
        'details': details.trim().substring(0, details.trim().length.clamp(0, 1000)),
      // Роҳи ҳуҷҷат — то модератор мазмуни аслиро ёфта тавонад.
      if (contextPath != null) 'contextPath': contextPath,
      // Нусхаи мазмун дар лаҳзаи шикоят: агар муаллиф онро нест кунад,
      // гузориш бе далел мемонад.
      if (contentSnapshot != null)
        'contentSnapshot':
            contentSnapshot.substring(0, contentSnapshot.length.clamp(0, 2000)),
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'open',
    });
  }
}
