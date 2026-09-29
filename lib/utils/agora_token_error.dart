import '../l10n/l10n.dart';
import '../services/agora_token_service.dart';

/// Хатои гирифтани token-и зангро ба забони фаҳмо табдил медиҳад.
String describeAgoraTokenError(AgoraTokenFailure failure) {
  return switch (failure.kind) {
    AgoraTokenFailureKind.notSignedIn => tr('k366'),
    AgoraTokenFailureKind.network => tr('k367'),
    AgoraTokenFailureKind.notConfigured => tr('k398'),
    // Сабаби сервер ҳамроҳ карда мешавад: бе он маълум намешавад, ки
    // ҳуҷҷати занг ёфт нашуд ё корбар воқеан иштирокчӣ нест.
    AgoraTokenFailureKind.notAllowed =>
      failure.reason == null ? tr('k399') : '${tr('k399')} (${failure.reason})',
    AgoraTokenFailureKind.server => tr('k400'),
  };
}
