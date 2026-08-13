import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class CallsTab extends StatelessWidget {
  const CallsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.call_outlined, color: AppColors.textSecondary.withOpacity(0.5), size: 56),
            const SizedBox(height: 16),
            const Text('Ягон занг нест', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              'Зангҳои шумо дар ин ҷо намоён мешаванд',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary.withOpacity(0.8), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
