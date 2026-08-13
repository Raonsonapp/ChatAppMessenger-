import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class CommunitiesTab extends StatelessWidget {
  const CommunitiesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_rounded, color: AppColors.textSecondary.withOpacity(0.5), size: 56),
            const SizedBox(height: 16),
            const Text('Ягон ҷамъият нест', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              'Ҷамъиятҳо якчанд гурӯҳро дар як ҷо ҷамъ мекунанд',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary.withOpacity(0.8), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
