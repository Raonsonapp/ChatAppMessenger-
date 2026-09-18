import 'package:firebase_core/firebase_core.dart';

import '../l10n/l10n.dart';

/// Хатои боркунии файлро ба забони фаҳмо табдил медиҳад.
///
/// Матни хоми Firebase («[firebase_storage/object-not-found] No object exists
/// at the desired reference») ба корбар ҳељ чиз намефаҳмонад ва сабаби аслиро
/// пинҳон мекунад: аксаран Cloud Storage дар лоиҳаи Firebase умуман фаъол
/// нашудааст ё қоидаҳои он иҷозат намедиҳанд.
String describeUploadError(Object error) {
  if (error is FirebaseException) {
    switch (error.code) {
      case 'object-not-found':
      case 'bucket-not-found':
      case 'project-not-found':
        return tr('k365');
      case 'unauthorized':
      case 'unauthenticated':
        return tr('k366');
      case 'retry-limit-exceeded':
      case 'canceled':
        return tr('k367');
    }
    return error.message ?? error.code;
  }
  return '$error';
}
