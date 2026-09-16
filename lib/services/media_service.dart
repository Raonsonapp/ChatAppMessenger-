import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// САБТ: интихоби воқеии расм/видео/ҳуҷҷат ва боркунии воқеӣ ба
/// Cloud Storage. Ягон қисми ин hard-code/fake нест.
class MediaService {
  static final ImagePicker _picker = ImagePicker();

  static Future<XFile?> pickFromGallery() {
    return _picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 1600);
  }

  static Future<XFile?> pickFromCamera() {
    return _picker.pickImage(source: ImageSource.camera, imageQuality: 80, maxWidth: 1600);
  }

  /// Видео аз галерея. Маҳдудияти вақт барои он ки файл хеле калон нашавад.
  static Future<XFile?> pickVideoFromGallery() {
    return _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 5),
    );
  }

  /// Сабти видео бо камера.
  static Future<XFile?> recordVideo() {
    return _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(minutes: 5),
    );
  }

  /// Интихоби файли GIF бе фишурдасозӣ (тавассути file_picker), то
  /// анимация вайрон нашавад.
  static Future<XFile?> pickGif() async {
    final files = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['gif']);
    if (files.isEmpty) return null;
    return files.first.xFile;
  }

  /// Ҳуҷҷат (PDF, Word, Excel, архив ва ғ.).
  static Future<PlatformFile?> pickDocument() async {
    final files = await FilePicker.pickFiles(type: FileType.any);
    if (files.isEmpty) return null;
    return files.first;
  }

  /// Боркунии расм ба Firebase Storage, бозгашти URL-и воқеӣ
  static Future<String> uploadImage(XFile file, String folderPath) async {
    return uploadFile(File(file.path), file.name, folderPath);
  }

  /// Боркунии ҳар файл (овоз, видео, ҳуҷҷат) ва бозгашти URL.
  static Future<String> uploadFile(File file, String name, String folderPath) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_$name';
    final ref = FirebaseStorage.instance.ref().child('$folderPath/$fileName');
    final uploadTask = await ref.putFile(file);
    return uploadTask.ref.getDownloadURL();
  }

  /// Ҳаҷми файл ба шакли хондашаванда.
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Давомнокӣ ба шакли `1:05`.
  static String formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
