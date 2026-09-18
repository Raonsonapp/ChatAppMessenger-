import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/neon_backdrop.dart';
import '../../l10n/l10n.dart';
import '../../theme/app_scope.dart';

class _Faq {
  final String question;
  final String answer;
  const _Faq(this.question, this.answer);
}

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  static final List<_Faq> _faqs = [
    _Faq(
      tr('k153'),
      tr('k154'),
    ),
    _Faq(
      tr('k155'),
      tr('k156'),
    ),
    _Faq(
      tr('k157'),
      tr('k158'),
    ),
    _Faq(
      tr('k159'),
      tr('k160'),
    ),
    _Faq(
      tr('k161'),
      tr('k162'),
    ),
    _Faq(
      tr('k163'),
      tr('k164'),
    ),
    _Faq(
      tr('k165'),
      tr('k166'),
    ),
    _Faq(
      tr('k167'),
      tr('k168'),
    ),
  ];

  final Set<int> _expanded = {};

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NeonBackdrop(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 20, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(LucideIcons.arrow_left, color: AppColors.textPrimary, size: 20),
                    ),
                    Text(
                      tr('k169'),
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 20),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: _faqs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final faq = _faqs[index];
                    final isOpen = _expanded.contains(index);
                    return GlassContainer(
                      borderRadius: 16,
                      padding: EdgeInsets.zero,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => setState(() {
                            if (isOpen) {
                              _expanded.remove(index);
                            } else {
                              _expanded.add(index);
                            }
                          }),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(LucideIcons.life_buoy, color: AppColors.neonCyan, size: 18),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        faq.question,
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      isOpen ? LucideIcons.chevron_up : LucideIcons.chevron_down,
                                      color: AppColors.textSecondary.withValues(alpha: 0.6),
                                      size: 18,
                                    ),
                                  ],
                                ),
                                if (isOpen) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    faq.answer,
                                    style: TextStyle(
                                      color: AppColors.textSecondary.withValues(alpha: 0.9),
                                      fontSize: 13,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
