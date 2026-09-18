import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

/// Идоракунии кэши медиа — ҳам дар хотира, ҳам дар диск.
///
/// `cached_network_image` файлҳоро дар папкаи муваққатӣ нигоҳ медорад. Бе
/// роҳи тозакунӣ он метавонад то гигабайтҳо расад, бинобар ин корбар бояд
/// ҳам андозаи онро бубинад ва ҳам тоза карда тавонад.
class MediaCache {
  /// Номи папкаи кэши `flutter_cache_manager`.
  static const _diskFolder = 'libCachedImageData';

  /// Андозаи кэши диск бо байт.
  static Future<int> diskSizeBytes() async {
    try {
      final temp = await getTemporaryDirectory();
      final dir = Directory('${temp.path}/$_diskFolder');
      if (!await dir.exists()) return 0;

      var total = 0;
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          try {
            total += await entity.length();
          } catch (_) {
            // Файл дар ҳамин лаҳза нест шуда метавонад — ин хатогӣ нест.
          }
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  /// Андозаи кэши тасвирҳо дар хотира бо байт.
  static int memorySizeBytes() =>
      PaintingBinding.instance.imageCache.currentSizeBytes;

  /// Шумораи тасвирҳо дар хотира.
  static int memoryCount() => PaintingBinding.instance.imageCache.currentSize;

  /// Ҳамаи кэшро тоза мекунад ва шумораи байтҳои озодшударо бармегардонад.
  static Future<int> clear() async {
    final freedMemory = memorySizeBytes();
    final freedDisk = await diskSizeBytes();

    final cache = PaintingBinding.instance.imageCache;
    cache.clear();
    cache.clearLiveImages();

    try {
      await DefaultCacheManager().emptyCache();
    } catch (_) {
      // Агар папка кушода набошад, кэши хотира ҳам бас аст.
    }

    return freedMemory + freedDisk;
  }
}
