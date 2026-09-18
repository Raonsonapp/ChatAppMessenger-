import '../l10n/l10n.dart';
import '../services/media_download_service.dart';

/// Хатои нигоҳдории файлро ба забони фаҳмо табдил медиҳад.
String describeDownloadError(Object error) {
  if (error is DownloadFailure) {
    return switch (error.kind) {
      DownloadFailureKind.network => tr('k367'),
      DownloadFailureKind.noPermission => tr('k378'),
      DownloadFailureKind.saveFailed => tr('k379'),
    };
  }
  return tr('k379');
}
