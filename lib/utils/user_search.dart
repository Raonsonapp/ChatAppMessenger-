import 'phone.dart';

/// Ҳудуди ҳуҷҷатҳое, ки ҳангоми ҷустуҷӯи корбар хонда мешаванд.
///
/// Ҷустуҷӯ дар тарафи барнома иҷро мешавад, бинобар ин корбароне, ки берун аз
/// ин ҳудуд монданд, умуман ёфт намешаванд. Ҳудуди пештара 50 буд — яъне пас
/// аз 50 корбар қисми одамон «дар ChatApp нестанд» менамуданд.
const int kUserSearchLimit = 500;

/// Оё ҳуҷҷати корбар ба дархости ҷустуҷӯ мувофиқ аст.
///
/// Рақами телефон бо калиди муқоиса санҷида мешавад, то `+992 55 999 47 51`,
/// `992559994751` ва `0559994751` як шахс ҳисоб шаванд.
bool userMatchesQuery(Map<String, dynamic> data, String query) {
  final q = query.trim();
  if (q.isEmpty) return false;

  final name = (data['name'] ?? '') as String;
  if (name.toLowerCase().contains(q.toLowerCase())) return true;

  // `@username` низ ҷустуҷӯ мешавад — вагарна ин майдон танҳо ороишӣ мемонад.
  // `@`-и дархост бароварда мешавад, то «@shahron» ва «shahron» як бошанд.
  final username = (data['username'] ?? '') as String;
  if (username.isNotEmpty) {
    final needle = q.startsWith('@') ? q.substring(1) : q;
    if (needle.isNotEmpty && username.toLowerCase().contains(needle.toLowerCase())) return true;
  }

  final nickname = (data['nickname'] ?? '') as String;
  if (nickname.isNotEmpty && nickname.toLowerCase().contains(q.toLowerCase())) return true;

  final phone = (data['phone'] ?? '') as String;
  final queryKey = phoneMatchKey(q);
  if (queryKey.isNotEmpty && phoneMatchKey(phone) == queryKey) return true;

  return phone.contains(q);
}
