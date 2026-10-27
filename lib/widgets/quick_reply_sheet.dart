import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../services/quick_reply_service.dart';
import '../theme/app_theme.dart';
import 'glass_container.dart';

class QuickReplySheet extends StatefulWidget {
  const QuickReplySheet({super.key, required this.onSelected, this.manageMode = false});

  final ValueChanged<String> onSelected;
  final bool manageMode;

  @override
  State<QuickReplySheet> createState() => _QuickReplySheetState();
}

class _QuickReplySheetState extends State<QuickReplySheet> {
  List<QuickReply> _replies = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final replies = await QuickReplyService.load();
    if (!mounted) return;
    setState(() {
      _replies = replies;
      _loading = false;
    });
  }

  Future<void> _edit([QuickReply? reply]) async {
    final shortcut = TextEditingController(text: reply?.shortcut ?? '');
    final message = TextEditingController(text: reply?.message ?? '');
    final result = await showDialog<QuickReply>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(reply == null ? 'Ҷавоби зуд илова кунед' : 'Таҳрири ҷавоби зуд',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: shortcut,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Миёнабур (масалан, чура)',
                prefixText: '/',
                labelStyle: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: message,
              minLines: 3,
              maxLines: 6,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Матни ҷавоб',
                labelStyle: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Бекор')),
          FilledButton(
            onPressed: () {
              final key = shortcut.text.trim().replaceFirst(RegExp(r'^/+'), '');
              final text = message.text.trim();
              if (key.isNotEmpty && text.isNotEmpty) {
                Navigator.pop(dialogContext, QuickReply(shortcut: key, message: text));
              }
            },
            child: const Text('Захира'),
          ),
        ],
      ),
    );
    shortcut.dispose();
    message.dispose();
    if (result == null) return;
    await QuickReplyService.upsert(result);
    await _load();
  }

  Future<void> _delete(QuickReply reply) async {
    await QuickReplyService.remove(reply.shortcut);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
        child: GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(widget.manageMode ? 'Ҷавобҳои зуд — танзимот' : 'Ҷавобҳои зуд',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    tooltip: 'Илова',
                    onPressed: () => _edit(),
                    icon: Icon(LucideIcons.plus, color: AppColors.neonEmerald),
                  ),
                ],
              ),
              if (_loading)
                const Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())
              else if (_replies.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text('Ҳоло ҷавоби омода нест. Бо + ҷавоб илова кунед.',
                      textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _replies.length,
                    separatorBuilder: (_, __) => Divider(color: AppColors.glassBorder, height: 1),
                    itemBuilder: (_, index) {
                      final reply = _replies[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('/${reply.shortcut}', style: TextStyle(color: AppColors.neonEmerald, fontWeight: FontWeight.w700)),
                        subtitle: Text(reply.message, maxLines: 3, overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: AppColors.textSecondary)),
                        onTap: () => widget.manageMode ? _edit(reply) : widget.onSelected(reply.message),
                        trailing: widget.manageMode
                            ? IconButton(onPressed: () => _delete(reply), icon: Icon(LucideIcons.trash, color: Colors.redAccent))
                            : Icon(LucideIcons.corner_down_left, color: AppColors.textSecondary),
                      );
                    },
                  ),
                ),
              if (!widget.manageMode)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(onPressed: () => _edit(), child: const Text('Илова кардани ҷавоб')),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
