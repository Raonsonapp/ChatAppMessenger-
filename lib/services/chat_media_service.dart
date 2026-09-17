import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import 'media_service.dart';

/// Фиристодани файл ба ҳар навъи сӯҳбат (шахсӣ, гурӯҳ, ҷамъият, канал).
///
/// Ҳар чор экран як мантиқро истифода мебаранд ва танҳо бо роҳи Firestore ва
/// папкаи Storage фарқ мекунанд, бинобар ин он дар ин ҷо ҷамъ карда шудааст —
/// вагарна ҳар функсияи нави медиа бояд чор маротиба нусхабардорӣ шавад.
class ChatMediaService {
  /// `true` — агар фиристода шуд.
  static Future<bool> sendFile({
    required CollectionReference<Map<String, dynamic>> messagesRef,
    required DocumentReference<Map<String, dynamic>> parentRef,
    required String storageFolder,
    required File file,
    required String name,
    required String mediaType,
    required String preview,
    int? durationSeconds,
    int? sizeBytes,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    final url = await MediaService.uploadFile(file, name, storageFolder);
    await messagesRef.add({
      'text': '',
      'senderId': uid,
      'isAI': false,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
      'mediaUrl': url,
      'mediaType': mediaType,
      if (durationSeconds != null) 'mediaDuration': durationSeconds,
      if (sizeBytes != null) 'mediaSize': sizeBytes,
      if (mediaType == 'document') 'mediaName': name,
    });
    await parentRef.set({
      'lastMessage': preview,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': uid,
    }, SetOptions(merge: true));
    return true;
  }

  static Future<bool> sendVideo({
    required CollectionReference<Map<String, dynamic>> messagesRef,
    required DocumentReference<Map<String, dynamic>> parentRef,
    required String storageFolder,
    required XFile picked,
  }) {
    return sendFile(
      messagesRef: messagesRef,
      parentRef: parentRef,
      storageFolder: storageFolder,
      file: File(picked.path),
      name: picked.name,
      mediaType: 'video',
      preview: '🎥 Видео',
    );
  }

  static Future<bool> sendDocument({
    required CollectionReference<Map<String, dynamic>> messagesRef,
    required DocumentReference<Map<String, dynamic>> parentRef,
    required String storageFolder,
    required PlatformFile picked,
  }) async {
    final path = picked.path;
    if (path == null) return false;
    final file = File(path);
    // PlatformFile ҳаҷмро намедиҳад — онро аз худи файл мегирем.
    final size = await file.length();
    return sendFile(
      messagesRef: messagesRef,
      parentRef: parentRef,
      storageFolder: storageFolder,
      file: file,
      name: picked.name,
      mediaType: 'document',
      preview: '📄 ${picked.name}',
      sizeBytes: size,
    );
  }

  static Future<bool> sendVoice({
    required CollectionReference<Map<String, dynamic>> messagesRef,
    required DocumentReference<Map<String, dynamic>> parentRef,
    required String storageFolder,
    required File file,
    required Duration duration,
  }) async {
    final sent = await sendFile(
      messagesRef: messagesRef,
      parentRef: parentRef,
      storageFolder: storageFolder,
      file: file,
      name: 'voice.m4a',
      mediaType: 'audio',
      preview: '🎤 Паёми овозӣ',
      durationSeconds: duration.inSeconds,
    );
    // Файли муваққатӣ дигар лозим нест.
    await file.delete().catchError((_) => file);
    return sent;
  }
}
