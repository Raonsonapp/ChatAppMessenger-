import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_scope.dart';
import '../theme/chat_theme_controller.dart';
import '../theme/wallpaper_controller.dart';

/// Заминаи чатро зери рӯйхати паёмҳо мегузорад.
class ChatWallpaper extends StatelessWidget {
  final Widget child;
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
        final path = style.wallpaperPath;
        if (path != null) {
          final file = File(path);
          if (file.existsSync()) return _image(file);
        }
        if (style.wallpaperDesign != null) {
          return ChatWallpaperArtwork(
            design: style.wallpaperDesign!,
            child: child,
          );
        }
        final color = style.wallpaperColor;
        if (color != null) return Container(color: Color(color), child: child);
        final shared = wallpaperController.file;
        if (shared != null) return _image(shared);
        return child;
      },
    );
  }

  Widget _image(File file) => Container(
        decoration: BoxDecoration(
          image: DecorationImage(image: FileImage(file), fit: BoxFit.cover),
        ),
        child: child,
      );
}

/// Заминаҳои интихобшавандаи 2D, 3D ва манзара — бе API ва бе зеркашии тасвир.
class ChatWallpaperArtwork extends StatelessWidget {
  final String design;
  final Widget child;

  const ChatWallpaperArtwork({super.key, required this.design, required this.child});

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _WallpaperArtworkPainter(design),
        child: child,
      );
}

class _WallpaperArtworkPainter extends CustomPainter {
  final String design;
  const _WallpaperArtworkPainter(this.design);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final paint = Paint();
    final colors = switch (design) {
      '2d_aurora' => [const Color(0xFF063A46), const Color(0xFF40216D)],
      '2d_grid' => [const Color(0xFF071C2C), const Color(0xFF123D55)],
      '2d_waves' => [const Color(0xFF062D38), const Color(0xFF144B68)],
      '2d' => [const Color(0xFF081D35), const Color(0xFF35145C)],
      '3d_crystal' => [const Color(0xFF170D35), const Color(0xFF204C67)],
      '3d_orbit' => [const Color(0xFF071A31), const Color(0xFF174A48)],
      '3d_mesh' => [const Color(0xFF20102C), const Color(0xFF154B55)],
      '3d' => [const Color(0xFF061A24), const Color(0xFF143D52)],
      'landscape' => [const Color(0xFF112B46), const Color(0xFF536D8A)],
      _ => [const Color(0xFF0A0E14), const Color(0xFF101820)],
    };
    paint.shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    ).createShader(rect);
    canvas.drawRect(rect, paint);
    paint.shader = null;

    if (design.startsWith('2d')) {
      paint.color = (design == '2d_aurora' ? const Color(0xFF8B5CF6) : design == '2d_grid' ? const Color(0xFF38BDF8) : const Color(0xFF23D5AB)).withValues(alpha: 0.34);
      canvas.drawCircle(Offset(size.width * .82, size.height * .18), size.shortestSide * .24, paint);
      paint.color = const Color(0xFF7B61FF).withValues(alpha: 0.42);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width * .05, size.height * .58, size.width * .56, size.height * .28),
          const Radius.circular(22),
        ),
        paint,
      );
      paint.color = const Color(0xFF36BFFA).withValues(alpha: 0.35);
      canvas.drawCircle(Offset(size.width * .73, size.height * .78), size.shortestSide * .16, paint);
    } else if (design.startsWith('3d')) {
      final s = size.shortestSide * .22;
      final centers = [
        Offset(size.width * .24, size.height * .35),
        Offset(size.width * .70, size.height * .62),
        Offset(size.width * .76, size.height * .20),
      ];
      for (var i = 0; i < centers.length; i++) {
        final center = centers[i];
        final top = Path()
          ..moveTo(center.dx, center.dy - s)
          ..lineTo(center.dx + s, center.dy - s * .48)
          ..lineTo(center.dx, center.dy)
          ..lineTo(center.dx - s, center.dy - s * .48)
          ..close();
        paint.color = (design == '3d_crystal' ? const Color(0xFFF0ABFC) : design == '3d_orbit' ? const Color(0xFF67E8F9) : const Color(0xFF5EEAD4)).withValues(alpha: .46 - i * .08);
        canvas.drawPath(top, paint);
        final left = Path()
          ..moveTo(center.dx - s, center.dy - s * .48)
          ..lineTo(center.dx, center.dy)
          ..lineTo(center.dx, center.dy + s)
          ..lineTo(center.dx - s, center.dy + s * .48)
          ..close();
        paint.color = const Color(0xFF2563EB).withValues(alpha: .55);
        canvas.drawPath(left, paint);
        final right = Path()
          ..moveTo(center.dx, center.dy)
          ..lineTo(center.dx + s, center.dy - s * .48)
          ..lineTo(center.dx + s, center.dy + s * .48)
          ..lineTo(center.dx, center.dy + s)
          ..close();
        paint.color = const Color(0xFF9333EA).withValues(alpha: .55);
        canvas.drawPath(right, paint);
      }
    } else if (design == 'landscape') {
      paint.color = const Color(0xFFFFD166).withValues(alpha: .88);
      canvas.drawCircle(Offset(size.width * .76, size.height * .22), size.shortestSide * .09, paint);
      final back = Path()
        ..moveTo(0, size.height * .70)
        ..lineTo(size.width * .24, size.height * .28)
        ..lineTo(size.width * .43, size.height * .63)
        ..lineTo(size.width * .62, size.height * .34)
        ..lineTo(size.width, size.height * .72)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      paint.color = const Color(0xFF6D91B8);
      canvas.drawPath(back, paint);
      final front = Path()
        ..moveTo(0, size.height * .82)
        ..lineTo(size.width * .29, size.height * .53)
        ..lineTo(size.width * .52, size.height * .80)
        ..lineTo(size.width * .79, size.height * .48)
        ..lineTo(size.width, size.height * .78)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      paint.color = const Color(0xFF1B7A68);
      canvas.drawPath(front, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WallpaperArtworkPainter oldDelegate) =>
      oldDelegate.design != design;
}
