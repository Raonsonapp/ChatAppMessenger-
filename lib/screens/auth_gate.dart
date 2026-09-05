import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_theme.dart';
import '../widgets/neon_backdrop.dart';
import '../widgets/incoming_call_listener.dart';
import '../services/notification_service.dart';
import 'chat_list_screen.dart';
import 'welcome_screen.dart';

/// Гардиши воридшавӣ: агар корбар аллакай бо телефон ворид шуда бошад,
/// мустақим ChatListScreen; акс ҳолат, WelcomeScreen (телефон → OTP).
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _tokenRegisteredForUid;

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
        final user = snapshot.data;
        if (user != null) {
          if (_tokenRegisteredForUid != user.uid) {
            _tokenRegisteredForUid = user.uid;
            NotificationService.registerTokenForCurrentUser();
          }
          return const IncomingCallListener(child: ChatListScreen());
        }
        return const WelcomeScreen();
      },
    );
  }
}
