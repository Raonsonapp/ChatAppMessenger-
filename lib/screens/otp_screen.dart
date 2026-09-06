import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/neon_backdrop.dart';
import 'complete_profile_screen.dart';
import 'chat_list_screen.dart';

class OtpScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;
  final int? resendToken;
  const OtpScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
    this.resendToken,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const _resendCooldown = 60;

  final TextEditingController _codeController = TextEditingController();
  bool _isVerifying = false;
  bool _isResending = false;
  String? _errorText;
  late String _verificationId = widget.verificationId;
  int? _resendToken;
  int _secondsLeft = _resendCooldown;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _resendToken = widget.resendToken;
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendCooldown);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  Future<void> _resendCode() async {
    if (_secondsLeft > 0 || _isResending) return;
    setState(() {
      _isResending = true;
      _errorText = null;
    });

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: widget.phoneNumber,
      forceResendingToken: _resendToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!mounted) return;
        setState(() {
          _isResending = false;
          _errorText = e.message ?? 'Хатои тасдиқ. Аз нав кӯшиш кунед.';
        });
      },
      codeSent: (String verificationId, int? resendToken) {
        if (!mounted) return;
        setState(() {
          _isResending = false;
          _verificationId = verificationId;
          _resendToken = resendToken;
        });
        _startCountdown();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Рамзи нав фиристода шуд')),
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length < 6) {
      setState(() => _errorText = 'Рамзи 6-рақамаро пурра ворид кунед');
      return;
    }
    setState(() {
      _isVerifying = true;
      _errorText = null;
    });

    try {
      // САБТ: тасдиқи воқеии рамзи OTP тавассути Firebase
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: code,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final uid = userCredential.user?.uid;
      if (uid == null) throw Exception('UID нест');

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!mounted) return;

      if (userDoc.exists) {
        // Корбари мавҷуда — мустақим ба Home
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ChatListScreen()),
          (route) => false,
        );
      } else {
        // Корбари нав — пур кардани профил
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => CompleteProfileScreen(phoneNumber: widget.phoneNumber)),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _errorText = e.message ?? 'Рамз нодуруст аст';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NeonBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.arrow_left, color: AppColors.textPrimary, size: 20),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Рамзи тасдиқро ворид кунед',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ба ${widget.phoneNumber} SMS фиристода шуд',
                  style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.85), fontSize: 13),
                ),
                const SizedBox(height: 28),
                GlassContainer(
                  borderRadius: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 8,
                    ),
                    decoration: const InputDecoration(
                      counterText: '',
                      hintText: '______',
                      hintStyle: TextStyle(color: AppColors.textSecondary, letterSpacing: 8),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 10),
                  Text(_errorText!, style: const TextStyle(color: Colors.redAccent, fontSize: 12.5)),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonEmerald,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _isVerifying ? null : _verifyCode,
                    child: _isVerifying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background),
                          )
                        : const Text('Тасдиқ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: _isResending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.neonEmerald),
                        )
                      : TextButton(
                          onPressed: _secondsLeft > 0 ? null : _resendCode,
                          child: Text(
                            _secondsLeft > 0
                                ? 'Рамзро аз нав фиристодан ($_secondsLeft с)'
                                : 'Рамзро аз нав фиристодан',
                            style: TextStyle(
                              color: _secondsLeft > 0 ? AppColors.textSecondary : AppColors.neonEmerald,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
