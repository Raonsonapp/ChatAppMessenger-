import 'package:flutter/material.dart';

import '../theme/wallpaper_controller.dart';

/// Заминаи интихобкардаи корбарро зери рӯйхати паёмҳо мегузорад.
///
/// Агар замина интихоб нашуда бошад, ҳељ чиз иваз намешавад — виҷет танҳо
/// фарзандашро бармегардонад.
class ChatWallpaper extends StatelessWidget {
  final Widget child;
  const ChatWallpaper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final file = wallpaperController.file;
    if (file == null) return child;
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(image: FileImage(file), fit: BoxFit.cover),
      ),
      child: child,
    );
  }
}
