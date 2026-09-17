import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/chat_message.dart';

/// Паёмҳои ситорадор (starred messages) — мисли WhatsApp.
///
/// Нусхаи паём дар `users/{uid}/starred/{id}` нигоҳ дошта мешавад, на дар худи
/// ҳуҷҷати паём. Ин ду бартарӣ дорад: дигар иштирокчиён ситораи маро намебинанд
/// ва барои рӯйхат ба collectionGroup-запрос ва индекси мураккаб ниёз нест.
class StarService {
  static CollectionReference<Map<String, dynamic>>? get _ref {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(uid).collection('starred');
  }

  /// Роҳи ҳуҷҷати паём ба id-и ҳуҷҷат табдил меёбад — `/` дар id иҷозат нест.
  static String _idFor(DocumentReference<Map<String, dynamic>> messageRef) {
    return messageRef.path.replaceAll('/', '~');
  }

  static Future<bool> isStarred(DocumentReference<Map<String, dynamic>> messageRef) async {
    final ref = _ref;
    if (ref == null) return false;
    try {
      final doc = await ref.doc(_idFor(messageRef)).get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  /// `true` бармегардонад, агар паём ҳоло ситорадор шуда бошад.
  static Future<bool> toggle({
    required DocumentReference<Map<String, dynamic>> messageRef,
    required ChatMessage message,
    required String chatTitle,
  }) async {
    final ref = _ref;
    if (ref == null) return false;
    final doc = ref.doc(_idFor(messageRef));
    if ((await doc.get()).exists) {
      await doc.delete();
      return false;
    }
    await doc.set({
      'sourcePath': messageRef.path,
      'chatTitle': chatTitle,
      'text': message.text,
      'senderId': message.senderId,
      'starredAt': FieldValue.serverTimestamp(),
      'originalAt': message.timestamp == null ? null : Timestamp.fromDate(message.timestamp!),
      if (message.mediaUrl != null) 'mediaUrl': message.mediaUrl,
      if (message.mediaType != null) 'mediaType': message.mediaType,
      if (message.mediaName != null) 'mediaName': message.mediaName,
      if (message.mediaSize != null) 'mediaSize': message.mediaSize,
      if (message.mediaDuration != null) 'mediaDuration': message.mediaDuration,
    });
    return true;
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> watch() {
    final ref = _ref;
    if (ref == null) return const Stream.empty();
    return ref.orderBy('starredAt', descending: true).snapshots();
  }

  static Future<void> remove(String docId) async {
    await _ref?.doc(docId).delete();
  }
}
