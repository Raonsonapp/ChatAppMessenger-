import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/neon_backdrop.dart';
import 'otp_screen.dart';

class PhoneEntryScreen extends StatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  State<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends State<PhoneEntryScreen> {
  final TextEditingController _codeController = TextEditingController(text: '992');
  final TextEditingController _numberController = TextEditingController();
  bool _isSending = false;
  String? _errorText;

  @override
  void dispose() {
    _codeController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  String get _fullPhoneNumber {
    final code = _codeController.text.trim();
    final number = _numberController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    return '+$code$number';
  }

  Future<void> _sendCode() async {
    final number = _numberController.text.trim();
    if (number.replaceAll(RegExp(r'[^0-9]'), '').length < 7) {
      setState(() => _errorText = 'Рақами телефонро дуруст ворид кунед');
      return;
    }
    setState(() {
      _isSending = true;
      _errorText = null;
    });

    final phone = _fullPhoneNumber;

    // САБТ: дархости воқеии SMS тавассути Firebase Phone Authentication
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Дар баъзе дастгоҳҳо Android худкор SMS-ро мехонад
        await FirebaseAuth.instance.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!mounted) return;
        setState(() {
          _isSending = false;
          _errorText = e.message ?? 'Хатои тасдиқ. Аз нав кӯшиш кунед.';
        });
      },
      codeSent: (String verificationId, int? resendToken) {
        if (!mounted) return;
        setState(() => _isSending = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(verificationId: verificationId, phoneNumber: phone),
          ),
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
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
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Рақами телефони худро ворид кунед',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  'Мо ба ин рақам SMS бо рамзи тасдиқ мефиристем',
                  style: TextStyle(color: AppColors.textSecondary.withOpacity(0.85), fontSize: 13),
                ),
                const SizedBox(height: 28),
                GlassContainer(
                  borderRadius: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      const Text(
                        '+',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(
                        width: 48,
                        child: TextField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                          decoration: const InputDecoration(border: InputBorder.none),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 24,
                        color: AppColors.glassBorder,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _numberController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                          decoration: const InputDecoration(
                            hintText: '90 123 45 67',
                            hintStyle: TextStyle(color: AppColors.textSecondary),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
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
                    onPressed: _isSending ? null : _sendCode,
                    child: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background),
                          )
                        : const Text('Идома', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
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
