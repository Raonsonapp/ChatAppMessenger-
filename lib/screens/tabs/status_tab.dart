import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class StatusTab extends StatelessWidget {
  const StatusTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
      children: [
        Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: const Icon(Icons.person_rounded, color: AppColors.textSecondary, size: 26),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.neonGradient),
                    child: const Icon(Icons.add_rounded, color: AppColors.background, size: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Тарихи ман', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                  Text(
                    'Барои иловаи навсозӣ зер кунед',
                    style: TextStyle(color: AppColors.textSecondary.withOpacity(0.8), fontSize: 12.5),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        Text(
          'ЯГОН НАВСОЗӢ НЕСТ',
          style: TextStyle(
            color: AppColors.textSecondary.withOpacity(0.6),
            fontSize: 11.5,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Навсозиҳои дӯстони шумо дар ин ҷо намоён мешаванд',
          style: TextStyle(color: AppColors.textSecondary.withOpacity(0.7), fontSize: 12.5),
        ),
      ],
    );
  }
}
