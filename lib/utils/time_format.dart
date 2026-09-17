/// Вақти кӯтоҳ барои рӯйхатҳо: «14:05» барои имрӯз, «7/9» барои рӯзҳои гузашта.
///
/// Ин мантиқ дар панҷ виҷет такрор мешуд — акнун як ҷо ҷойгир аст.
String formatChatTime(DateTime? t) {
  if (t == null) return '';
  final now = DateTime.now();
  if (now.difference(t).inDays >= 1) return '${t.day}/${t.month}';
  final h = t.hour.toString().padLeft(2, '0');
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m';
}
