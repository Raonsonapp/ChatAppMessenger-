import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/glass_container.dart';
import '../widgets/neon_backdrop.dart';
import 'chat_list_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Future<User?> _authFuture;

  @override
  void initState() {
    super.initState();
    _authFuture = _ensureSignedIn();
  }

  Future<User?> _ensureSignedIn() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser != null) return auth.currentUser;
    final credential = await auth.signInAnonymously();
    return credential.user;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: _authFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _buildLoading();
        }
        if (snapshot.hasError || snapshot.data == null) {
          return _buildError(snapshot.error);
        }
        return const ChatListScreen();
      },
    );
  }

  Widget _buildLoading() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NeonBackdrop(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLogo(size: 56),
              const SizedBox(height: 22),
              const CircularProgressIndicator(color: AppColors.neonEmerald),
              const SizedBox(height: 16),
              const Text('Пайвастшавӣ ба Firebase...', style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(Object? error) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NeonBackdrop(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GlassContainer(
              borderRadius: 20,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.neonCyan, size: 40),
                  const SizedBox(height: 12),
                  const Text(
                    'Пайвастшавӣ ба Firebase ноком шуд',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Санҷед, ки дар Firebase Console → Authentication → Sign-in method '
                    'усули "Anonymous" фаъол аст.\n\n$error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonEmerald,
                      foregroundColor: AppColors.background,
                    ),
                    onPressed: () => setState(() => _authFuture = _ensureSignedIn()),
                    child: const Text('Аз нав кӯшиш кунед'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
