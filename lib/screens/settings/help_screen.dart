import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/neon_backdrop.dart';

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
  static const List<_Faq> _faqs = [
    _Faq(
      'Чӣ тавр ворид мешавам?',
      'Рақами телефони худро нависед ва тугмаи "Кушодани бот дар Telegram"-ро пахш кунед. '
          'Дар бот рақами худро мубодила кунед — бот рамзи 6-рақама мефиристад. '
          'Ҳамон рамзро дар барнома нависед.',
    ),
    _Faq(
      'Рамз намеояд, чӣ кунам?',
      'Мутмаин шавед, ки дар бот маҳз ҳамон рақамеро мубодила кардед, ки дар барнома навиштед. '
          'Агар рамз наомад, 60 сония сабр карда, тугмаи "Кушодани бот барои рамзи нав"-ро пахш кунед. '
          'Рамз 5 дақиқа эътибор дорад.',
    ),
    _Faq(
      'Чӣ тавр чати нав оғоз мекунам?',
      'Дар вкладкаи "Чатҳо" тугмаи "+"-ро пахш кунед. Рӯйхати контактҳои телефони шумо кушода мешавад. '
          'Контактҳое, ки аллакай дар ChatApp сабт шудаанд, нишона доранд.',
    ),
    _Faq(
      'Чаро контакти ман дар рӯйхат нест?',
      'Он шахс бояд аввал дар ChatApp сабти ном кунад. Ҳамчунин иҷозаи дастрасӣ ба контактҳо лозим аст — '
          'онро дар танзимоти Android барои ChatApp тафтиш кунед.',
    ),
    _Faq(
      'Занги садоӣ ва видеоӣ чӣ тавр кор мекунад?',
      'Дар чат тугмаи занг ё видеоро пахш кунед. Барои кор кардани занг, иҷозаи микрофон ва камера лозим аст. '
          'Ҳар ду тараф бояд интернети устувор дошта бошанд.',
    ),
    _Faq(
      'Гурӯҳ, ҷамъият ва канал чӣ фарқ доранд?',
      'Гурӯҳ — сӯҳбати якчанд нафар, ҳама менависанд. Ҷамъият — якчанд гурӯҳро муттаҳид мекунад. '
          'Канал — танҳо соҳиб менависад, дигарон мехонанд.',
    ),
    _Faq(
      'Статус чанд вақт мемонад?',
      'Статус 24 соат пас аз гузоштан худкор нопадид мешавад.',
    ),
    _Faq(
      'Огоҳиномаҳо намеоянд',
      'Дар "Танзимот → Огоҳиномаҳо" тафтиш кунед, ки огоҳиномаи паёмҳо фаъол бошад. '
          'Ҳамчунин дар танзимоти Android иҷозаи огоҳиномаро барои ChatApp фаъол кунед.',
    ),
  ];

  final Set<int> _expanded = {};

  @override
  Widget build(BuildContext context) {
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
                      'Кӯмак',
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
