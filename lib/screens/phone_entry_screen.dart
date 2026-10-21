import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/neon_backdrop.dart';
import '../services/otp_bot_service.dart';
import 'otp_screen.dart';
import '../l10n/l10n.dart';
import '../theme/app_scope.dart';

class PhoneEntryScreen extends StatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  State<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends State<PhoneEntryScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _phoneAnimation;
  late final AnimationController _flightController;
  final TextEditingController _codeController = TextEditingController(text: '992');
  final TextEditingController _numberController = TextEditingController();
  final FocusNode _numberFocusNode = FocusNode();
  bool _isTypingPhone = false;
  bool _isOpeningBot = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _phoneAnimation = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _flightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _numberFocusNode.addListener(() {
      if (!mounted) return;
      setState(() => _isTypingPhone = _numberFocusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _phoneAnimation.dispose();
    _flightController.dispose();
    _numberFocusNode.dispose();
    _codeController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  String get _fullPhoneNumber {
    final code = _codeController.text.trim();
    final number = _numberController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    return '+$code$number';
  }

  Future<void> _openBotAndContinue() async {
    final number = _numberController.text.trim();
    if (number.replaceAll(RegExp(r'[^0-9]'), '').length < 7) {
      setState(() => _errorText = tr('k134'));
      return;
    }
    setState(() {
      _isOpeningBot = true;
      _errorText = null;
    });
    _flightController.forward(from: 0);

    final phone = _fullPhoneNumber;
    bool opened;
    try {
      opened = await OtpBotService.openTelegramBot(phone);
    } catch (_) {
      // Бе ин тугма то абад чарх мезад ва корбар вориди барнома намешуд.
      opened = false;
    }

    if (!mounted) return;
    setState(() => _isOpeningBot = false);

    if (!opened) {
      setState(() => _errorText = tr('k135'));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OtpScreen(phoneNumber: phone)),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NeonBackdrop(
        child: SafeArea(
          child: SingleChildScrollView(
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
                  tr('k136'),
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  tr('k137'),
                  style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.85), fontSize: 13),
                ),
                const SizedBox(height: 18),
                Center(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_phoneAnimation, _flightController]),
                    builder: (context, child) {
                      final ringOpacity = 0.16 + (_phoneAnimation.value * 0.20);
                      return SizedBox(
                        width: 238,
                        height: 112,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              left: 8,
                              top: 8,
                              child: Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.neonEmerald.withValues(alpha: 0.08),
                                  border: Border.all(
                                    color: AppColors.neonEmerald.withValues(alpha: ringOpacity),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.neonEmerald.withValues(alpha: ringOpacity),
                                      blurRadius: 18,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: AnimatedScale(
                                  duration: const Duration(milliseconds: 180),
                                  scale: _isTypingPhone ? 0.94 : 1,
                                  child: Text(
                                    _isTypingPhone ? '🙈' : '🐵',
                                    style: const TextStyle(fontSize: 52),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 5,
                              top: 29,
                              child: Container(
                                width: 66,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: AppColors.glassBorder),
                                ),
                                child: Icon(
                                  LucideIcons.message_circle,
                                  color: AppColors.neonCyan,
                                  size: 25,
                                ),
                              ),
                            ),
                            if (_isOpeningBot || _flightController.isAnimating)
                              Positioned(
                                left: 85 + (_flightController.value * 86),
                                top: 35 - (12 * (1 - (_flightController.value - 0.5).abs() * 2)),
                                child: Transform.rotate(
                                  angle: 0.15,
                                  child: Icon(
                                    LucideIcons.send,
                                    color: AppColors.neonEmerald,
                                    size: 22,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    tr('k136'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
                const SizedBox(height: 14),
                GlassContainer(
                  borderRadius: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        '+',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(
                        width: 48,
                        child: TextField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
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
                          focusNode: _numberFocusNode,
                          keyboardType: TextInputType.phone,
                          onChanged: (_) => setState(() {}),
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                          decoration: InputDecoration(
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
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonEmerald,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _isOpeningBot ? null : _openBotAndContinue,
                    icon: _isOpeningBot
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background),
                          )
                        : const Icon(LucideIcons.send, size: 18),
                    label: Text(tr('k138'), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
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
