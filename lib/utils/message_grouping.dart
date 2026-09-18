import '../models/chat_message.dart';

/// `true` — агар паём идомаи паёми пешина бошад: ҳамон фиристанда ва фарқи
/// вақт то 2 дақиқа. Чунин паёмҳо дар WhatsApp ба ҳам наздик кашида мешаванд
/// ва номи фиристанда такрор намешавад.
bool isGroupedWithPrevious(ChatMessage? previous, ChatMessage current) {
  if (previous == null) return false;
  if (previous.senderId != current.senderId) return false;
  if (previous.isAI != current.isAI) return false;

  final a = previous.timestamp;
  final b = current.timestamp;
  if (a == null || b == null) return false;
  return b.difference(a).inMinutes.abs() < 2;
}
