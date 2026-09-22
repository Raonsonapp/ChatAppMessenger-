import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'compression_service.dart';
import 'storage_service.dart';

/// Интихоби расм/видео/ҳуҷҷат ва боркунии воқеии онҳо.
///
/// Файлҳо ба Cloudflare R2 бор мешаванд (ниг. `StorageService`), на ба
/// Firebase Storage.
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

  /// Боркунии расм — пеш аз фиристодан фишурда мешавад.
  static Future<String> uploadImage(XFile file, String folderPath) async {
    return uploadFile(File(file.path), file.name, folderPath);
  }

  /// Боркунии ҳар файл (акс, овоз, видео, ҳуҷҷат) ва бозгашти URL.
  ///
  /// Акс ва видео пеш аз фиристодан фишурда мешаванд — мисли WhatsApp.
  /// Ҳуҷҷат, овоз ва GIF дасторасӣ намешаванд: фишурдани онҳо ё маъно
  /// надорад, ё файлро вайрон мекунад.
  static Future<String> uploadFile(File file, String name, String folderPath) async {
    final prepared = await _compressIfUseful(file, name);
    return StorageService.upload(prepared.file, prepared.name, folderPath);
  }

  /// Файлро вобаста ба навъаш фишурда, номи навро бармегардонад.
  static Future<({File file, String name})> _compressIfUseful(
    File file,
    String name,
  ) async {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';

    if (_imageExtensions.contains(ext)) {
      final compressed = await CompressionService.compressImage(file);
      if (identical(compressed, file)) return (file: file, name: name);
      // Натиҷа ҳамеша JPEG аст, бинобар ин ном бояд мувофиқ бошад —
      // вагарна Content-Type нодуруст мешавад ва браузер файлро
      // зеркашӣ мекунад, на нишон медиҳад.
      return (file: compressed, name: _withExtension(name, 'jpg'));
    }

    if (_videoExtensions.contains(ext)) {
      final compressed = await CompressionService.compressVideo(file);
      if (identical(compressed, file)) return (file: file, name: name);
      return (file: compressed, name: _withExtension(name, 'mp4'));
    }

    return (file: file, name: name);
  }

  /// GIF дар рӯйхат нест: фишурдан анимацияро нобуд мекунад.
  static const Set<String> _imageExtensions = {
    'jpg', 'jpeg', 'png', 'heic', 'heif', 'webp',
  };

  static const Set<String> _videoExtensions = {
    'mp4', 'mov', '3gp', 'mkv', 'avi', 'm4v', 'webm',
  };

  static String _withExtension(String name, String extension) {
    final dot = name.lastIndexOf('.');
    final base = dot <= 0 ? name : name.substring(0, dot);
    return '$base.$extension';
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
