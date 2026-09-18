import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

/// Нигоҳдории медиаи қабулшуда дар худи дастгоҳ.
///
/// Акс ва видео ба галерея мераванд (то дар «Галерея»-и телефон дида шаванд),
/// ҳуҷҷатҳо бошанд ба папкаи файлҳои барнома.
class MediaDownloadService {
  /// Акси интернетиро ба галерея нигоҳ медорад.
  static Future<void> saveImage(String url, {String? name}) =>
      _saveToGallery(url, name: name, isVideo: false);

  /// Видеои интернетиро ба галерея нигоҳ медорад.
  static Future<void> saveVideo(String url, {String? name}) =>
      _saveToGallery(url, name: name, isVideo: true);

  static Future<void> _saveToGallery(
    String url, {
    String? name,
    required bool isVideo,
  }) async {
    final file = await _download(url);

    // Иҷозат танҳо ҳангоми ниёз пурсида мешавад — на ҳангоми оғози барнома.
    if (!await Gal.hasAccess(toAlbum: true)) {
      final granted = await Gal.requestAccess(toAlbum: true);
      if (!granted) throw const DownloadFailure(DownloadFailureKind.noPermission);
    }

    try {
      if (isVideo) {
        await Gal.putVideo(file.path, album: _album);
      } else {
        await Gal.putImage(file.path, album: _album);
      }
    } on GalException catch (e) {
      throw DownloadFailure(
        e.type == GalExceptionType.accessDenied
            ? DownloadFailureKind.noPermission
            : DownloadFailureKind.saveFailed,
      );
    }
  }

  /// Ҳуҷҷатро ба папкаи ҳуҷҷатҳои барнома мегузорад ва роҳашро бармегардонад.
  static Future<String> saveDocument(String url, String name) async {
    final file = await _download(url);

    try {
      final dir = await getApplicationDocumentsDirectory();
      final target = File('${dir.path}/$_album/${_safeName(name)}');
      await target.parent.create(recursive: true);
      await file.copy(target.path);
      return target.path;
    } catch (_) {
      throw const DownloadFailure(DownloadFailureKind.saveFailed);
    }
  }

  static const _album = 'ChatApp';

  /// Файл аз кэш гирифта мешавад — агар аллакай зеркашӣ шуда бошад, такрор
  /// аз интернет кашида намешавад.
  static Future<File> _download(String url) async {
    try {
      return await DefaultCacheManager().getSingleFile(url);
    } catch (_) {
      throw const DownloadFailure(DownloadFailureKind.network);
    }
  }

  static String _safeName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    return cleaned.isEmpty ? 'file' : cleaned;
  }
}

enum DownloadFailureKind { network, noPermission, saveFailed }

class DownloadFailure implements Exception {
  final DownloadFailureKind kind;
  const DownloadFailure(this.kind);

  @override
  String toString() => 'DownloadFailure(${kind.name})';
}
