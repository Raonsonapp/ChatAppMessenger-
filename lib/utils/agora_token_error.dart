import '../l10n/l10n.dart';
import '../services/agora_token_service.dart';

/// Хатои гирифтани token-и зангро ба забони фаҳмо табдил медиҳад.
String describeAgoraTokenError(AgoraTokenFailure failure) {
  return switch (failure.kind) {
    AgoraTokenFailureKind.notSignedIn => tr('k366'),
    AgoraTokenFailureKind.network => tr('k367'),
    AgoraTokenFailureKind.notConfigured => tr('k398'),
    AgoraTokenFailureKind.notAllowed => tr('k399'),
    AgoraTokenFailureKind.server => tr('k400'),
  };
}
