import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_scope.dart';
import '../theme/chat_theme_controller.dart';
import '../theme/wallpaper_controller.dart';

/// Заминаи чатро зери рӯйхати паёмҳо мегузорад.
///
/// Ду сатҳ: замина барои ҲАМИН чат (агар гузошта шуда бошад) ва заминаи
/// умумии барнома. Замина барои ҳамин чат бартарӣ дорад — вагарна интихоби
/// алоҳида маъно надошт.
class ChatWallpaper extends StatelessWidget {
  final Widget child;

  /// Шиносаи чат — барои заминаи алоҳида. `null` — танҳо заминаи умумӣ.
  final String? chatId;

  const ChatWallpaper({super.key, required this.child, this.chatId});

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);

    return AnimatedBuilder(
      animation: chatThemeController,
      builder: (context, _) {
        final style = chatId == null
            ? const ChatStyle()
            : chatThemeController.styleFor(chatId!);

        // 1. Акси ҳамин чат.
        final path = style.wallpaperPath;
        if (path != null) {
          final file = File(path);
          if (file.existsSync()) return _image(file);
        }

        // 2. Ранги якрангаи ҳамин чат.
        final color = style.wallpaperColor;
        if (color != null) {
          return Container(color: Color(color), child: child);
        }

        // 3. Заминаи умумии барнома.
        final shared = wallpaperController.file;
        if (shared != null) return _image(shared);

        return child;
      },
    );
  }

  Widget _image(File file) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(image: FileImage(file), fit: BoxFit.cover),
      ),
      child: child,
    );
  }
}
