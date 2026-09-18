import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/neon_backdrop.dart';
import '../l10n/l10n.dart';

/// Натиҷаи экрани сохтани пурсиш.
class PollDraft {
  final String question;
  final List<String> options;
  const PollDraft(this.question, this.options);
}

/// Сохтани пурсиш: савол ва то 12 вариант — мисли WhatsApp.
class CreatePollScreen extends StatefulWidget {
  const CreatePollScreen({super.key});

  @override
  State<CreatePollScreen> createState() => _CreatePollScreenState();
}

class _CreatePollScreenState extends State<CreatePollScreen> {
  static const int _maxOptions = 12;

  final TextEditingController _question = TextEditingController();
  final List<TextEditingController> _options = [
    TextEditingController(),
    TextEditingController(),
  ];

  @override
  void dispose() {
    _question.dispose();
    for (final c in _options) {
      c.dispose();
    }
    super.dispose();
  }

  /// Пурсиш савол ва ҳадди ақал ду вариант талаб мекунад.
  bool get _isValid {
    if (_question.text.trim().isEmpty) return false;
    return _options.where((c) => c.text.trim().isNotEmpty).length >= 2;
  }

  void _addOption() {
    if (_options.length >= _maxOptions) return;
    setState(() => _options.add(TextEditingController()));
  }

  void _removeOption(int index) {
    if (_options.length <= 2) return;
    setState(() {
      _options.removeAt(index).dispose();
    });
  }

  void _submit() {
    final options = _options.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
    Navigator.pop(context, PollDraft(_question.text.trim(), options));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NeonBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 16, 6),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(LucideIcons.x, color: AppColors.textPrimary, size: 21),
                    ),
                    Expanded(
                      child: Text(
                        tr('k346'),
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _isValid ? _submit : null,
                      child: Text(
                        tr('k350'),
                        style: TextStyle(
                          color: _isValid ? AppColors.neonEmerald : AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                  children: [
                    _field(_question, tr('k347'), autofocus: true),
                    const SizedBox(height: 18),
                    for (var i = 0; i < _options.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Expanded(child: _field(_options[i], trf('k348', [i + 1]))),
                            if (_options.length > 2)
                              IconButton(
                                onPressed: () => _removeOption(i),
                                icon: Icon(LucideIcons.x, color: AppColors.textSecondary, size: 17),
                              ),
                          ],
                        ),
                      ),
                    if (_options.length < _maxOptions)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _addOption,
                          icon: Icon(LucideIcons.plus, size: 16, color: AppColors.neonEmerald),
                          label: Text(
                            tr('k349'),
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String hint, {bool autofocus = false}) {
    return GlassContainer(
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }
}
