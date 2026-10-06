import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/app_theme.dart';
import '../l10n/l10n.dart';
import '../theme/app_scope.dart';

/// Экрани ҳалол барои хусусиятҳое, ки ҳанӯз backend-и воқеӣ надоранд.
///
/// Мувофиқи қоидаи "ҳеҷ чизи қалбакӣ" — агар хусусияте кор карда
/// натавонад (масалан, фиристодани паём ба якчанд нафар якбора бо backend-и
/// алоҳида), мо тугмаеро намесозем, ки гӯё кор мекунад, вале воқеан не.
/// Ба ҷои он ҳамин экрани возеҳро нишон медиҳем.
class ComingSoonScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  const ComingSoonScreen({super.key, required this.title, this.icon = LucideIcons.hammer});

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundSecondary,
        foregroundColor: AppColors.textPrimary,
        title: Text(title, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(color: AppColors.glassFill, shape: BoxShape.circle, border: Border.all(color: AppColors.glassBorder)),
                child: Icon(icon, color: AppColors.textSecondary, size: 30),
              ),
              const SizedBox(height: 18),
              Text(
                tr('k418'),
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                tr('k419'),
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
