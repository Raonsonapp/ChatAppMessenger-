import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_theme.dart';
import '../widgets/neon_backdrop.dart';
import 'chat_list_screen.dart';
import 'welcome_screen.dart';

/// Гардиши воридшавӣ: агар корбар аллакай бо телефон ворид шуда бошад,
/// мустақим ChatListScreen; акс ҳолат, WelcomeScreen (телефон → OTP).
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: NeonBackdrop(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.neonEmerald),
              ),
            ),
          );
        }
        if (snapshot.hasData) {
          return const ChatListScreen();
        }
        return const WelcomeScreen();
      },
    );
  }
}
