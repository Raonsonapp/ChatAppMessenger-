import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../services/bot_studio_service.dart';
import '../theme/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/neon_backdrop.dart';

class BotStudioScreen extends StatefulWidget {
  const BotStudioScreen({super.key});

  @override
  State<BotStudioScreen> createState() => _BotStudioScreenState();
}

class _BotStudioScreenState extends State<BotStudioScreen> {
  static const _tasks = <String, String>{
    'general': 'Ёрдамчии умумӣ',
    'diamond_donation': 'Роҳнамои донати алмаз',
    'faq': 'Саволу ҷавоб (FAQ)',
    'support': 'Дастгирии корбарон',
    'custom': 'Вазифаи дигар',
  };

  static const _actionLabels = <String, String>{
    'answer_questions': 'Ҷавоб ба саволҳо',
    'faq': 'Ҷавобҳои омода',
    'donation_guide': 'Роҳнамои донат',
    'collect_feedback': 'Ҷамъ кардани пешниҳодҳо',
    'handoff_to_admin': 'Ирсол ба админ',
  };

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instructionsController = TextEditingController();
  final Set<String> _actions = {'answer_questions'};
  List<Map<String, dynamic>> _bots = [];
  String _task = 'general';
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBots();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _loadBots() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bots = await BotStudioService.listBots();
      if (!mounted) return;
      setState(() {
        _bots = bots;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _changeTask(String? value) {
    if (value == null) return;
    setState(() {
      _task = value;
      if (value == 'diamond_donation') {
        _actions.add('donation_guide');
      }
    });
  }

  Future<void> _createBot() async {
    if (_saving) return;
    if (_nameController.text.trim().length < 2) {
      setState(() => _error = 'Номи ботро аз 2 аломат зиёд нависед.');
      return;
    }
    if (_task == 'diamond_donation' && !_actions.contains('donation_guide')) {
      setState(() => _error = 'Барои ботҳои донати алмаз «Роҳнамои донат»-ро интихоб кунед.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await BotStudioService.createBot(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        task: _task,
        instructions: _instructionsController.text.trim(),
        actions: _actions.toList(),
      );
      _nameController.clear();
      _descriptionController.clear();
      _instructionsController.clear();
      setState(() {
        _task = 'general';
        _actions
          ..clear()
          ..add('answer_questions');
      });
      await _loadBots();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Бот ҳамчун лоиҳа сабт шуд.')),
      );
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteBot(String id) async {
    try {
      await BotStudioService.deleteBot(id);
      await _loadBots();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NeonBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 18, 10),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(LucideIcons.arrow_left, color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bot Studio',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Ботро бе навиштани код созед',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.neonEmerald.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.neonEmerald.withValues(alpha: 0.4)),
                      ),
                      child: Icon(LucideIcons.bot, color: AppColors.neonEmerald, size: 22),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                  children: [
                    GlassContainer(
                      borderRadius: 22,
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(LucideIcons.sparkles, color: AppColors.neonEmerald, size: 20),
                              const SizedBox(width: 9),
                              Text(
                                'Боти нав',
                                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 17),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _field('Номи бот', _nameController, hint: 'Масалан: Diamond Helper', maxLength: 40),
                          const SizedBox(height: 12),
                          _field('Тавсифи кӯтоҳ', _descriptionController, hint: 'Бот барои чӣ лозим аст?', maxLength: 160),
                          const SizedBox(height: 12),
                          Text('Вазифаи асосӣ', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _task,
                            dropdownColor: AppColors.surface,
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                            decoration: _decoration(),
                            items: _tasks.entries.map((entry) => DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value),
                            )).toList(),
                            onChanged: _changeTask,
                          ),
                          const SizedBox(height: 14),
                          Text('Амалиётҳои иҷозатдодашуда', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 2,
                            children: _actionLabels.entries.map((entry) {
                              final selected = _actions.contains(entry.key);
                              return FilterChip(
                                selected: selected,
                                label: Text(entry.value),
                                labelStyle: TextStyle(
                                  color: selected ? AppColors.background : AppColors.textPrimary,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                                selectedColor: AppColors.neonEmerald,
                                checkmarkColor: AppColors.background,
                                backgroundColor: AppColors.surface,
                                side: BorderSide(color: selected ? AppColors.neonEmerald : AppColors.glassBorder),
                                onSelected: (value) => setState(() {
                                  if (value) {
                                    _actions.add(entry.key);
                                  } else {
                                    _actions.remove(entry.key);
                                  }
                                }),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),
                          _field(
                            'Дастури бот',
                            _instructionsController,
                            hint: 'Масалан: бо забони тоҷикӣ кӯтоҳ ҷавоб деҳ. Агар савол дар бораи донати алмаз бошад, танҳо қадамҳои расмиро фаҳмон.',
                            maxLength: 2000,
                            maxLines: 4,
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              color: AppColors.neonCyan.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(LucideIcons.shield_check, color: AppColors.neonCyan, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Ключҳои API-ро ба ин форма нанависед. Ин версия конфигуратсияи ботро месабт; пайваст кардани API ё пардохти воқеӣ баъд аз танзими сервер фаъол мешавад.',
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5, height: 1.45),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12.5)),
                          ],
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _saving ? null : _createBot,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.neonEmerald,
                                foregroundColor: AppColors.background,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              icon: _saving
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(LucideIcons.plus, size: 18),
                              label: Text(_saving ? 'Сабт шуда истодааст…' : 'Сохтани бот'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Ботҳои ман',
                            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 17),
                          ),
                        ),
                        IconButton(
                          onPressed: _loading ? null : _loadBots,
                          icon: Icon(LucideIcons.refresh_cw, color: AppColors.textSecondary, size: 19),
                        ),
                      ],
                    ),
                    if (_loading)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(22),
                          child: CircularProgressIndicator(color: AppColors.neonEmerald),
                        ),
                      )
                    else if (_bots.isEmpty)
                      GlassContainer(
                        borderRadius: 16,
                        padding: const EdgeInsets.all(18),
                        child: Text(
                          'Ҳоло бот нест. Аввалин ботро аз формаи боло созед.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      )
                    else
                      ..._bots.map(_botCard),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _botCard(Map<String, dynamic> bot) {
    final id = bot['id'] as String? ?? '';
    final task = bot['task'] as String? ?? 'general';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassContainer(
        borderRadius: 17,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.neonCyan.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(LucideIcons.bot, color: AppColors.neonCyan, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bot['name'] as String? ?? 'Боти нав',
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _tasks[task] ?? 'Вазифаи дигар',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Лоиҳа • ҳоло фаъол нест',
                    style: TextStyle(color: AppColors.neonEmerald, fontSize: 10.5, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Нест кардан',
              onPressed: id.isEmpty ? null : () => _deleteBot(id),
              icon: Icon(LucideIcons.trash_2, color: AppColors.textSecondary, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    required String hint,
    required int maxLength,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLength: maxLength,
          maxLines: maxLines,
          minLines: 1,
          style: TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
          decoration: _decoration(hint: hint),
        ),
      ],
    );
  }

  InputDecoration _decoration({String? hint}) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.7), fontSize: 12),
        filled: true,
        fillColor: AppColors.surface.withValues(alpha: 0.8),
        counterStyle: TextStyle(color: AppColors.textSecondary, fontSize: 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: AppColors.neonEmerald, width: 1.3),
        ),
      );
}
