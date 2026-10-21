import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/neon_backdrop.dart';
import '../services/otp_bot_service.dart';
import 'complete_profile_screen.dart';
import 'chat_list_screen.dart';
import '../l10n/l10n.dart';
import '../theme/app_scope.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  const OtpScreen({super.key, required this.phoneNumber});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> with SingleTickerProviderStateMixin {
  static const _resendCooldown = 60;

  final TextEditingController _codeController = TextEditingController();
  bool _isVerifying = false;
  bool _isResending = false;
  bool _showDoorAnimation = false;
  late final AnimationController _doorController;
  String? _errorText;
  int _secondsLeft = _resendCooldown;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _doorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
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
    setState(() => _isResending = true);

    final opened = await OtpBotService.openTelegramBot(widget.phoneNumber);

    if (!mounted) return;
    setState(() => _isResending = false);
    if (opened) {
      _startCountdown();
    } else {
      setState(() => _errorText = tr('k125'));
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _timer?.cancel();
    _doorController.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length < 6) {
      setState(() => _errorText = tr('k126'));
      return;
    }
    setState(() {
      _isVerifying = true;
      _errorText = null;
    });

    try {
      // Рамз тавассути боти Telegram фиристода шуда буд; сервери мо онро
      // тасдиқ карда, ба ивазаш Firebase custom token медиҳад.
      final token = await OtpBotService.verifyCode(phone: widget.phoneNumber, code: code);
      final userCredential = await FirebaseAuth.instance.signInWithCustomToken(token);
      final uid = userCredential.user?.uid;
      if (uid == null) throw Exception(tr('k127'));

      // Рақамро ҳозир сабт мекунем, на дар экрани профил. Сервер онро аллакай
      // тасдиқ кардааст, ва маҳз ҳамин майдон аст, ки дигарон ҳангоми ҷустуҷӯи
      // контакт бо он корбарро меёбанд — агар он набошад, корбар барои ҳама
      // ноаён мемонад.
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      await userRef.set({'phone': widget.phoneNumber}, SetOptions(merge: true));

      final userDoc = await userRef.get();
      if (!mounted) return;

      // "Корбари кӯҳна" маънои "ҳуҷҷат ҳаст"-ро надорад: NotificationService
      // ҳангоми вуруд fcmToken навишта, ҳуҷҷатро худаш месозад. Бидуни ин
      // санҷиш корбари нав экрани профилро мегузарад ва бе ном мемонад.
      final hasProfile = (userDoc.data()?['name'] as String?)?.trim().isNotEmpty ?? false;

      setState(() => _showDoorAnimation = true);
      await _doorController.forward();
      await Future<void>.delayed(const Duration(milliseconds: 180));
      if (!mounted) return;

      if (hasProfile) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ChatListScreen()),
          (route) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => CompleteProfileScreen(phoneNumber: widget.phoneNumber)),
          (route) => false,
        );
      }
    } on OtpVerifyException catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _errorText = e.message;
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _errorText = e.message ?? tr('k128');
      });
    } catch (e) {
      // Ҳар хатои дигар (масалан навиштан ба Firestore ҳангоми набудани
      // интернет) пештар гирифта намешуд: тугма то абад чарх мезад ва
      // корбар дар экрани вуруд банд мемонд.
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _errorText = tr('k128');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          NeonBackdrop(
            child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(LucideIcons.arrow_left, color: AppColors.textPrimary, size: 20),
                ),
                const SizedBox(height: 12),
                Text(
                  tr('k129'),
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  trf('k130', [widget.phoneNumber]),
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
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 8,
                    ),
                    decoration: InputDecoration(
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
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background),
                          )
                        : Text(tr('k131'), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: _isResending
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.neonEmerald),
                        )
                      : TextButton(
                          onPressed: _secondsLeft > 0 ? null : _resendCode,
                          child: Text(
                            _secondsLeft > 0
                                ? trf('k132', [_secondsLeft])
                                : tr('k133'),
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
          if (_showDoorAnimation) _buildDoorAnimation(),
        ],
      ),
    );
  }

  Widget _buildDoorAnimation() {
    return Positioned.fill(
      child: Container(
        color: AppColors.background.withValues(alpha: 0.88),
        alignment: Alignment.center,
        child: AnimatedBuilder(
          animation: _doorController,
          builder: (context, child) {
            final progress = Curves.easeOutCubic.transform(_doorController.value);
            return SizedBox(
              width: 176,
              height: 190,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    bottom: 18,
                    child: Opacity(
                      opacity: progress,
                      child: Transform.translate(
                        offset: Offset(38 * (1 - progress), 0),
                        child: const Text('🧍', style: TextStyle(fontSize: 48)),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 28,
                    top: 4,
                    child: Container(
                      width: 112,
                      height: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.neonEmerald, width: 2),
                        color: AppColors.neonEmerald.withValues(alpha: 0.10),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 28,
                    top: 4,
                    child: Transform(
                      alignment: Alignment.centerLeft,
                      transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(-1.15 * progress),
                      child: Container(
                        width: 112,
                        height: 160,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: AppColors.surface,
                          border: Border.all(color: AppColors.neonEmerald, width: 2),
                        ),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Icon(Icons.circle, size: 9, color: AppColors.neonEmerald),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    child: Opacity(
                      opacity: progress,
                      child: Text(
                        tr('k131'),
                        style: TextStyle(
                          color: AppColors.neonEmerald,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
