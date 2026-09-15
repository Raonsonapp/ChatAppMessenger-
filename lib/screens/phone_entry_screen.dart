import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/neon_backdrop.dart';
import '../services/otp_bot_service.dart';
import 'otp_screen.dart';
import '../l10n/l10n.dart';

class PhoneEntryScreen extends StatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  State<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends State<PhoneEntryScreen> {
  final TextEditingController _codeController = TextEditingController(text: '992');
  final TextEditingController _numberController = TextEditingController();
  bool _isOpeningBot = false;
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

    final phone = _fullPhoneNumber;
    final opened = await OtpBotService.openTelegramBot(phone);

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
                const SizedBox(height: 28),
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
                          keyboardType: TextInputType.phone,
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
    );
  }
}
