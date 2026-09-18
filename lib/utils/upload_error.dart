import '../l10n/l10n.dart';
import '../services/storage_service.dart';

/// Хатои боркунии файлро ба забони фаҳмо табдил медиҳад.
///
/// Матни хоми хизматрасон ба корбар ҳељ чиз намефаҳмонад ва сабаби аслиро
/// пинҳон мекунад.
String describeUploadError(Object error) {
  if (error is StorageFailure) {
    return switch (error.kind) {
      StorageFailureKind.notConfigured => tr('k368'),
      StorageFailureKind.missingFile => tr('k369'),
      StorageFailureKind.noPublicUrl => tr('k370'),
      StorageFailureKind.rejected => tr('k371'),
      StorageFailureKind.network => tr('k367'),
      StorageFailureKind.notSignedIn => tr('k366'),
      StorageFailureKind.tooLarge => tr('k373'),
      StorageFailureKind.tooManyUploads => tr('k374'),
      StorageFailureKind.uploadFailed || StorageFailureKind.server => tr('k372'),
    };
  }
  return '$error';
}
