import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/lamp_pull_reveal.dart';
import 'phone_entry_screen.dart';
import '../l10n/l10n.dart';
import '../theme/app_scope.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
    // Корбар бояд сими чароғро кашад, то чароғ равшан шуда, мундариҷаи
    // воқеии хушомадгӯӣ (бо худи ҳамон тугмаи "Давом" ва мантиқи аслии он)
    // пайдо шавад. Ин танҳо намоиши визуалӣ аст — аутентификатсияи воқеӣ
    // (PhoneEntryScreen → OtpScreen) бетағйир мемонад.
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LampPullReveal(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppLogo(size: 96),
              const SizedBox(height: 24),
              Text(
                tr('k215'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                tr('k216'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.85),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonEmerald,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PhoneEntryScreen()),
                  ),
                  child: Text(
                    tr('k068'),
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
