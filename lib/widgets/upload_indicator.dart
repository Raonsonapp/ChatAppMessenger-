import 'package:flutter/material.dart';

import '../services/storage_service.dart';

/// Нишондиҳандаи боркунӣ бо фоиз.
///
/// Ҳангоми фиристодани видеои калон давраи беохир ҳељ чиз намефаҳмонад —
/// ин виҷет ҳиссаи воқеии боршударо нишон медиҳад.
class UploadIndicator extends StatelessWidget {
  const UploadIndicator({super.key, required this.color, this.size = 22});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double?>(
      valueListenable: StorageService.progress,
      builder: (context, value, _) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                // `null` — давраи беохир (ҳанӯз оғоз нашуда ё ҳуҷҷат дар
                // Firestore навишта мешавад).
                value: value,
                strokeWidth: 2,
                color: color,
              ),
              if (value != null && size >= 20)
                Text(
                  '${(value * 100).round()}',
                  style: TextStyle(
                    color: color,
                    fontSize: size * 0.34,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
