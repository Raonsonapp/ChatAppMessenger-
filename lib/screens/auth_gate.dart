import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_theme.dart';
import '../widgets/neon_backdrop.dart';
import '../widgets/incoming_call_listener.dart';
import '../services/notification_service.dart';
import '../services/presence_service.dart';
import 'chat_list_screen.dart';
import 'complete_profile_screen.dart';
import 'welcome_screen.dart';
import '../services/notification_prefs.dart';
import '../theme/app_scope.dart';

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
    AppScope.watch(context);
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
            PresenceService.instance.start();
          }
          // Ворид шудан кофӣ нест: корбар метавонад бе ном монда бошад
          // (масалан вуруд буриданашуда). Бе ном ӯро дигарон ҳангоми
          // ҷустуҷӯи контакт ёфта наметавонанд, бинобар ин ӯро боз ба
          // экрани профил мефиристем.
          return _ProfileGate(uid: user.uid);
        }
        return const WelcomeScreen();
      },
    );
  }
}

/// Пеш аз нишон додани чатҳо тафтиш мекунад, ки профил пур карда шудааст.
class _ProfileGate extends StatelessWidget {
  final String uid;
  const _ProfileGate({required this.uid});

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: NeonBackdrop(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.neonEmerald),
              ),
            ),
          );
        }
        final data = snapshot.data!.data();
        // Танзимоти огоҳинома дар ҳофизаи дастгоҳ нусхабардорӣ мешавад — вақти
        // нишон додани огоҳинома Firestore дастрас нест.
        NotificationPrefs.saveAll(data?['settings'] as Map<String, dynamic>?);
        final name = (data?['name'] as String?)?.trim() ?? '';
        if (name.isEmpty) {
          final phone = (data?['phone'] as String?) ?? '';
          return CompleteProfileScreen(phoneNumber: phone);
        }
        return const IncomingCallListener(child: ChatListScreen());
      },
    );
  }
}
