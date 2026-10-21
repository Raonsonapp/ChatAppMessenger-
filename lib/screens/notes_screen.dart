import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/l10n.dart';
import '../theme/app_scope.dart';
import '../theme/app_theme.dart';

/// Notes stay on this device; they are not uploaded to Firebase.
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});
  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  static const _key = 'chatapp_private_notes_v1';
  List<_Note> _notes = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      final values = raw == null ? <dynamic>[] : jsonDecode(raw) as List<dynamic>;
      final notes = values.whereType<Map<String, dynamic>>().map(_Note.fromJson).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      if (!mounted) return;
      setState(() { _notes = notes; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _message(tr('k741'));
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_notes.map((n) => n.toJson()).toList()));
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _edit([_Note? old]) async {
    final title = TextEditingController(text: old?.title ?? '');
    final body = TextEditingController(text: old?.body ?? '');
    final note = await showModalBottomSheet<_Note>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(old == null ? tr('k732') : tr('k733'),
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 21, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: title, maxLength: 90,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(color: AppColors.textPrimary),
                    decoration: _decoration(tr('k734'), LucideIcons.type),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: body, minLines: 5, maxLines: 12, maxLength: 6000,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(color: AppColors.textPrimary, height: 1.45),
                    decoration: _decoration(tr('k735'), LucideIcons.notebook_pen),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: () {
                      final t = title.text.trim();
                      final b = body.text.trim();
                      if (t.isEmpty && b.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(tr('k736'))));
                        return;
                      }
                      Navigator.pop(ctx, _Note(
                        id: old?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
                        title: t.isEmpty ? tr('k737') : t,
                        body: b,
                        updatedAt: DateTime.now().millisecondsSinceEpoch,
                      ));
                    },
                    icon: const Icon(LucideIcons.check),
                    label: Text(tr('k738')),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.neonEmerald,
                      foregroundColor: AppColors.isDark ? AppColors.background : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    title.dispose();
    body.dispose();
    if (note == null || !mounted) return;
    setState(() {
      final i = _notes.indexWhere((n) => n.id == note.id);
      if (i < 0) { _notes.insert(0, note); } else { _notes[i] = note; }
      _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    });
    try { await _save(); } catch (_) { if (mounted) _message(tr('k741')); }
  }

  InputDecoration _decoration(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: AppColors.textSecondary),
    prefixIcon: Icon(icon, color: AppColors.neonEmerald, size: 19),
    filled: true,
    fillColor: AppColors.surface,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.glassBorder)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.glassBorder)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.neonEmerald, width: 1.5)),
  );

  Future<void> _delete(_Note note) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(tr('k739'), style: TextStyle(color: AppColors.textPrimary)),
        content: Text(tr('k740'), style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('k715'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('k631'), style: TextStyle(color: AppColors.missedRed))),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    setState(() => _notes.removeWhere((n) => n.id == note.id));
    try { await _save(); } catch (_) { if (mounted) _message(tr('k741')); }
  }

  String _date(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    final now = DateTime.now();
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return d.year == now.year && d.month == now.month && d.day == now.day
        ? '$hour:$minute' : '$day.$month.' + d.year.toString();
  }

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
    final query = _query.trim().toLowerCase();
    final filtered = _notes.where((n) =>
      query.isEmpty || n.title.toLowerCase().contains(query) || n.body.toLowerCase().contains(query)).toList();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(tr('k731'), style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [IconButton(tooltip: tr('k732'), onPressed: () => _edit(),
          icon: Icon(LucideIcons.square_pen, color: AppColors.neonEmerald))],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        backgroundColor: AppColors.neonEmerald,
        foregroundColor: AppColors.isDark ? AppColors.background : Colors.white,
        icon: const Icon(LucideIcons.plus),
        label: Text(tr('k732'), style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.neonEmerald.withValues(alpha: .20), AppColors.neonCyan.withValues(alpha: .10)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Row(children: [
              Container(width: 48, height: 48,
                decoration: BoxDecoration(color: AppColors.neonEmerald.withValues(alpha: .16), borderRadius: BorderRadius.circular(16)),
                child: Icon(LucideIcons.notebook_pen, color: AppColors.neonEmerald, size: 25)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tr('k742'), style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(tr('k743'), style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.35)),
              ])),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            style: TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: tr('k744'), hintStyle: TextStyle(color: AppColors.textSecondary),
              prefixIcon: Icon(LucideIcons.search, color: AppColors.textSecondary),
              filled: true, fillColor: AppColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(child: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.neonEmerald))
          : filtered.isEmpty
            ? Center(child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(LucideIcons.notebook_text, size: 52, color: AppColors.textSecondary.withValues(alpha: .7)),
                  const SizedBox(height: 14),
                  Text(_query.isEmpty ? tr('k745') : tr('k746'), textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(tr('k747'), textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, height: 1.4)),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: () => _edit(),
                    icon: const Icon(LucideIcons.plus),
                    label: Text(tr('k732')),
                  ),
                ]),
              ))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final note = filtered[index];
                  return Dismissible(
                    key: ValueKey(note.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(color: AppColors.missedRed, borderRadius: BorderRadius.circular(18)),
                      child: const Icon(LucideIcons.trash, color: Colors.white)),
                    confirmDismiss: (_) async { await _delete(note); return false; },
                    child: Material(
                      color: AppColors.surface, borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => _edit(note), onLongPress: () => _delete(note),
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.glassBorder)),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Container(width: 38, height: 38,
                              decoration: BoxDecoration(color: AppColors.neonEmerald.withValues(alpha: .13), borderRadius: BorderRadius.circular(12)),
                              child: Icon(LucideIcons.notebook_pen, color: AppColors.neonEmerald, size: 19)),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(note.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 14.5)),
                              if (note.body.isNotEmpty) ...[
                                const SizedBox(height: 5),
                                Text(note.body, maxLines: 3, overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: AppColors.textSecondary, height: 1.35, fontSize: 13)),
                              ],
                              const SizedBox(height: 8),
                              Text(_date(note.updatedAt), style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                            ])),
                            const SizedBox(width: 4),
                            Icon(LucideIcons.chevron_right, color: AppColors.textSecondary, size: 18),
                          ]),
                        ),
                      ),
                    ),
                  );
                },
              )),
      ]),
    );
  }
}

class _Note {
  final String id;
  final String title;
  final String body;
  final int updatedAt;
  const _Note({required this.id, required this.title, required this.body, required this.updatedAt});
  factory _Note.fromJson(Map<String, dynamic> json) => _Note(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    body: json['body'] as String? ?? '',
    updatedAt: json['updatedAt'] as int? ?? 0,
  );
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'body': body, 'updatedAt': updatedAt};
}
