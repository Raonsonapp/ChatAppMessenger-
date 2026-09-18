import 'package:flutter/widgets.dart';

/// Пул байни танзимоти глобалӣ (мавзӯъ, забон, андозаи ҳарфҳо) ва экранҳо.
///
/// Рангҳо ва матнҳо дар барнома аз тағйирёбандаҳои статикӣ хонда мешаванд
/// (`AppColors`, `tr`). Ин зуд ва содда аст, вале як камбудии ҷиддӣ дошт:
/// вақте мавзӯъ ё забон иваз мешуд, танҳо ҳамон экране нав мешуд, ки худаш
/// `setState` мекард. Экранҳои дар зери он монда (рӯйхати чатҳо, худи чат ва
/// ғайра) бо ранг ва забони кӯҳна мемонданд — Flutter экрани дохили маршрутро
/// ҳангоми аз нав сохта шудани MaterialApp аз нав намесозад.
///
/// `AppScope` ин холигиро мебандад: ҳар экран дар `build` ба он обуна мешавад,
/// ва ҳангоми тағйири танзимот [version] иваз шуда, ҳамаи обунашудагон — дар
/// ҳар куҷои маршрутҳо бошанд — аз нав сохта мешаванд.
class AppScope extends InheritedWidget {
  /// Ҳангоми ҳар тағйири танзимот зиёд мешавад.
  final int version;

  const AppScope({super.key, required this.version, required super.child});

  /// Дар аввали `build`-и ҳар экран даъват мешавад.
  static void watch(BuildContext context) {
    context.dependOnInheritedWidgetOfExactType<AppScope>();
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => oldWidget.version != version;
}
