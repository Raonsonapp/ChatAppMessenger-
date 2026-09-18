import 'l10n.dart';

/// Матни кӯтоҳи паём барои рӯйхати чатҳо ва экрани фиристодан.
///
/// Матни `lastMessage` дар Firestore бо забони фиристанда сабт мешавад, вале
/// гиранда метавонад забони дигар дошта бошад. Барои ҳамин дар ҳуҷҷат навъи
/// паём (`lastMessageType`) низ нигоҳ дошта мешавад ва матн ҳангоми нишон
/// додан бо забони худи бинанда сохта мешавад.
///
/// [fallback] барои паёмҳои кӯҳна лозим аст — онҳо ҳанӯз навъ надоранд.
String mediaPreviewLabel(String? type, {String? fallback, String? name}) {
  switch (type) {
    case 'image':
    case 'gif':
      return tr('k311');
    case 'audio':
      return tr('k312');
    case 'video':
      return tr('k313');
    case 'sticker':
      return tr('k314');
    case 'contact':
      return tr('k315');
    case 'location':
      return tr('k286');
    case 'document':
      return trf('k316', [name ?? '']);
  }
  return fallback ?? '';
}
