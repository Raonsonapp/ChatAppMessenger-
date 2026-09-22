import 'package:agora_rtc_engine/agora_rtc_engine.dart';

import '../l10n/l10n.dart';

/// Хатоҳои Agora — фаҳмондан ва ҷудо кардани ҷиддӣ аз ғайриҷиддӣ.
///
/// Пештар ҲАР хатои Agora тамоми экрани зангро ба ҳолати хато мегузаронд.
/// Вале бисёре аз онҳо ғайриҷиддӣ мебошанд (масалан гарнитураи Bluetooth
/// пайваст нашуд) ва занг ба ҳар ҳол кор мекунад — дар натиҷа занги солим
/// «вайрон» менамуд.
class CallError {
  /// Оё ин хато занги воқеиро қатъ мекунад?
  static bool isFatal(ErrorCodeType code) => _fatal.contains(code);

  /// Танҳо хатоҳое ки пайвастшавиро имконнопазир мекунанд.
  static const Set<ErrorCodeType> _fatal = {
    ErrorCodeType.errInvalidAppId,
    ErrorCodeType.errInvalidChannelName,
    ErrorCodeType.errInvalidToken,
    ErrorCodeType.errTokenExpired,
    ErrorCodeType.errJoinChannelRejected,
    ErrorCodeType.errNoPermission,
  };

  /// Матни фаҳмо барои корбар.
  ///
  /// Барои хатоҳои танзимот сабаби АСЛӢ гуфта мешавад: «кор намекунад»
  /// ҳељ чиз намефаҳмонад, вале «дар Agora Certificate фаъол аст» маҳз он
  /// чизест, ки ислоҳ карданӣ аст.
  static String describe(ErrorCodeType code, String message) {
    return switch (code) {
      ErrorCodeType.errInvalidAppId => tr('k394'),
      ErrorCodeType.errInvalidToken || ErrorCodeType.errTokenExpired => tr('k395'),
      ErrorCodeType.errInvalidChannelName => tr('k396'),
      ErrorCodeType.errJoinChannelRejected => tr('k397'),
      ErrorCodeType.errNoPermission => tr('k014'),
      _ => trf('k016', [message.isEmpty ? code.name : message]),
    };
  }
}
