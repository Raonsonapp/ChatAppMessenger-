import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// САБТ: интихоби воқеии расм аз галерея/камера ва боркунии воқеӣ ба
/// Cloud Storage. Ягон қисми ин hard-code/fake нест.
class MediaService {
  static final ImagePicker _picker = ImagePicker();

  static Future<XFile?> pickFromGallery() {
    return _picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 1600);
  }

  static Future<XFile?> pickFromCamera() {
    return _picker.pickImage(source: ImageSource.camera, imageQuality: 80, maxWidth: 1600);
  }

  /// Интихоби файли GIF бе фишурдасозӣ (тавассути file_picker), то
  /// анимация вайрон нашавад.
  static Future<XFile?> pickGif() async {
    final files = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['gif']);
    if (files.isEmpty) return null;
    return files.first.xFile;
  }

  /// Боркунии расм ба Firebase Storage, бозгашти URL-и воқеӣ
  static Future<String> uploadImage(XFile file, String folderPath) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    final ref = FirebaseStorage.instance.ref().child('$folderPath/$fileName');
    final uploadTask = await ref.putFile(File(file.path));
    return uploadTask.ref.getDownloadURL();
  }
}
