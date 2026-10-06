import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/wallpaper_controller.dart';
import '../theme/app_scope.dart';

/// Заминаи чатро зери рӯйхати паёмҳо мегузорад.
///
/// Агар `chatId` дода шуда бошад ва ҳамон чат заминаи ХОС дошта бошад
/// (ранги якранг ё акс аз галерея — ниг. `ChatThemeScreen`), он истифода
/// мешавад. Вагарна заминаи умумии барнома (агар интихоб шуда бошад)
/// истифода мешавад. Агар ҳељ кадоме интихоб нашуда бошад, ҳељ чиз иваз
/// намешавад — виҷет танҳо фарзандашро бармегардонад.
class ChatWallpaper extends StatelessWidget {
  final Widget child;
  final String? chatId;
  const ChatWallpaper({super.key, required this.child, this.chatId});

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
    final id = chatId;
    final raw = id == null ? null : wallpaperController.rawFor(id);

    if (raw != null && raw.startsWith('color:')) {
      final value = int.tryParse(raw.substring('color:'.length));
      if (value != null) {
        return Container(color: Color(value), child: child);
      }
    }

    final imagePath = raw ?? wallpaperController.path;
    if (imagePath == null) return child;
    final file = File(imagePath);
    if (!file.existsSync()) return child;
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(image: FileImage(file), fit: BoxFit.cover),
      ),
      child: child,
    );
  }
}
