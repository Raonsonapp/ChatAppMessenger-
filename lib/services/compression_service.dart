import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';

/// Фишурдани акс ва видео пеш аз боркунӣ — мисли WhatsApp ва Instagram.
///
/// Сабаб танҳо ҷои анбор нест: дар Тоҷикистон интернет на ҳама ҷо тез аст ва
/// трафик пул меарзад. Фиристодани акси 8 МБ ба ҷои 300 КБ маънои 25 маротиба
/// зиёдтар интизорӣ ва трафикро дорад — ҳам барои фиристанда, ҳам барои
/// гиранда, ки онро зеркашӣ мекунад.
class CompressionService {
  /// Ҳиссаи фишурдашудаи видеои ҷорӣ (0…1). `null` — ҳоло чизе фишурда
  /// намешавад.
  ///
  /// Фишурдани видеои дароз метавонад даҳҳо сония кашад. Бе ин корбар
  /// фикр мекунад, ки барнома овезон шудааст.
  static final ValueNotifier<double?> progress = ValueNotifier<double?>(null);

  /// Тарафи дарози акс пас аз фишурдан.
  static const int _maxImageSide = 1600;

  /// Сифати JPEG. 80 — ҳадди оддие ки фарқи чашмрас намедиҳад.
  static const int _imageQuality = 80;

  /// Аксҳои аз ин хурдтар фишурда намешаванд — фоида надорад.
  static const int _imageSkipBytes = 120 * 1024;

  /// Видеоҳои аз ин хурдтар фишурда намешаванд.
  static const int _videoSkipBytes = 2 * 1024 * 1024;

  /// Акси фишурдашуда. Ҳангоми ҳар гуна нокомӣ файли аслӣ бармегардад —
  /// фиристода нашудани акс аз калон будани он бадтар аст.
  static Future<File> compressImage(File file) async {
    try {
      final original = await file.length();
      if (original <= _imageSkipBytes) return file;

      // GIF фишурда намешавад: анимация нобуд мешавад.
      if (file.path.toLowerCase().endsWith('.gif')) return file;

      final dir = await getTemporaryDirectory();
      final target =
          '${dir.path}/cmp_${DateTime.now().microsecondsSinceEpoch}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        target,
        quality: _imageQuality,
        minWidth: _maxImageSide,
        minHeight: _maxImageSide,
        // Аксҳои аз камера гирифташуда метавонанд чаппа бошанд: EXIF
        // ба худи пиксел табдил дода мешавад, вагарна пас аз фишурдан
        // акс чаппа мемонад.
        autoCorrectionAngle: true,
      );
      if (result == null) return file;

      final compressed = File(result.path);
      final size = await compressed.length();

      // Агар фишурдан фоида надода бошад, аслиро мефиристем.
      if (size >= original) return file;

      debugPrint('Акс фишурда шуд: $original → $size байт');
      return compressed;
    } catch (error) {
      debugPrint('Фишурдани акс нашуд: $error');
      return file;
    }
  }

  /// Видеои фишурдашуда.
  ///
  /// Видеои муосири телефон метавонад садҳо мегабайт бошад — беш аз ҳадди
  /// боркунӣ. Бе фишурдан чунин видео умуман фиристода намешуд.
  static Future<File> compressVideo(File file) async {
    try {
      final original = await file.length();
      if (original <= _videoSkipBytes) return file;

      // Обуна ҳатмист: бе он худи китобхона огоҳӣ медиҳад ва мо ҳељ
      // пешравиро намебинем.
      progress.value = 0;
      final subscription = VideoCompress.compressProgress$.subscribe((value) {
        progress.value = (value / 100).clamp(0.0, 1.0);
      });

      final MediaInfo? info;
      try {
        info = await VideoCompress.compressVideo(
          file.absolute.path,
          quality: VideoQuality.MediumQuality,
          deleteOrigin: false,
          includeAudio: true,
        );
      } finally {
        subscription.unsubscribe();
        progress.value = null;
      }

      final path = info?.path;
      if (path == null) return file;

      final compressed = File(path);
      if (!await compressed.exists()) return file;

      final size = await compressed.length();
      if (size >= original) return file;

      debugPrint('Видео фишурда шуд: $original → $size байт');
      return compressed;
    } catch (error) {
      debugPrint('Фишурдани видео нашуд: $error');
      progress.value = null;
      return file;
    }
  }

  /// Фишурдани видеоро қатъ мекунад (масалан корбар аз экран баромад).
  static Future<void> cancelVideoCompression() async {
    try {
      await VideoCompress.cancelCompression();
    } catch (_) {}
  }
}
