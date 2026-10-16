import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/neon_backdrop.dart';
import '../../theme/app_scope.dart';

/// Иваз кардани рақами телефон бо тасдиқи SMS аз Firebase Authentication.
class ChangePhoneScreen extends StatefulWidget {
  const ChangePhoneScreen({super.key});

  @override
  State<ChangePhoneScreen> createState() => _ChangePhoneScreenState();
}

class _ChangePhoneScreenState extends State<ChangePhoneScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  String? _verificationId;
  int? _resendToken;
  bool _sending = false;
  bool _saving = false;
  String? _message;
  String? _error;

  @override
  void initState() {
    super.initState();
    final current = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
    _phoneController.text = current.startsWith('+992') ? '+992' : '';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode({bool resend = false}) async {
    final phone = _phoneController.text.trim().replaceAll(' ', '');
    if (!phone.startsWith('+') || phone.length < 9) {
      setState(() => _error = 'Рақамро бо рамзи кишвар нависед, масалан +992900000000.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
      _message = null;
    });
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        forceResendingToken: resend ? _resendToken : null,
        verificationCompleted: (credential) async {
          await _applyCredential(credential);
        },
        verificationFailed: (e) {
          if (!mounted) return;
          setState(() {
            _sending = false;
            _error = e.message ?? 'Рақамро тасдиқ карда нашуд.';
          });
        },
        codeSent: (verificationId, resendToken) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _sending = false;
            _message = 'Рамзи SMS фиристода шуд.';
          });
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
          if (mounted) setState(() => _sending = false);
        },
      );
    } catch (e) {
      if (mounted) setState(() {
        _sending = false;
        _error = 'Хато ҳангоми фиристодани SMS: $e';
      });
    }
  }

  Future<void> _confirmCode() async {
    final verificationId = _verificationId;
    final code = _codeController.text.trim();
    if (verificationId == null || code.length < 6) {
      setState(() => _error = 'Рамзи шашрақамаи SMS-ро ворид кунед.');
      return;
    }
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: code,
    );
    await _applyCredential(credential);
  }

  Future<void> _applyCredential(PhoneAuthCredential credential) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (mounted) setState(() {
      _saving = true;
      _error = null;
      _message = null;
    });
    try {
      await user.updatePhoneNumber(credential);
      await user.reload();
      final phone = FirebaseAuth.instance.currentUser?.phoneNumber ??
          _phoneController.text.trim();
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'phone': phone,
        'phoneNumber': phone,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      setState(() {
        _saving = false;
        _sending = false;
        _message = 'Рақами телефон бомуваффақият иваз шуд.';
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _sending = false;
        _error = e.code == 'requires-recent-login'
            ? 'Барои иваз кардани рақам аз нав ворид шавед ва такрор кунед.'
            : (e.message ?? 'Рақам иваз нашуд.');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _sending = false;
        _error = 'Рақам иваз нашуд: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NeonBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  ),
                  Expanded(
                    child: Text(
                      'Иваз кардани рақами телефон',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 19,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Рақами навро бо рамзи кишвар ворид кунед. Барои тасдиқ SMS меояд.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Рақами нав (+992...)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _sending || _saving ? null : () => _sendCode(),
                  child: _sending
                      ? const CircularProgressIndicator()
                      : const Text('Фиристодани рамзи SMS'),
                ),
              ),
              if (_verificationId != null) ...[
                const SizedBox(height: 20),
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Рамзи шашрақама',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _confirmCode,
                    child: _saving
                        ? const CircularProgressIndicator()
                        : const Text('Тасдиқ ва сабт'),
                  ),
                ),
                TextButton(
                  onPressed: _sending ? null : () => _sendCode(resend: true),
                  child: const Text('Аз нав фиристодани SMS'),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              ],
              if (_message != null) ...[
                const SizedBox(height: 12),
                Text(_message!, style: TextStyle(color: AppColors.neonEmerald)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
