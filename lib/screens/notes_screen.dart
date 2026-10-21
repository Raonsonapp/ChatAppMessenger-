import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
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
  int _accentIndex = 0;
  double _fontSize = 16;
  static const _accents = <Color>[Color(0xFF00E5A8), Color(0xFF00D9FF), Color(0xFFB56BFF), Color(0xFFFF4FD8), Color(0xFFFFB547), Color(0xFFFF5E7E)];
  Color get _accent => _accents[_accentIndex.clamp(0, _accents.length - 1)];

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
      setState(() { _notes = notes; _accentIndex = (prefs.getInt('chatapp_notes_accent_v1') ?? 0).clamp(0, _accents.length - 1); _fontSize = (prefs.getDouble('chatapp_notes_font_v1') ?? 16).clamp(13, 23); _loading = false; });
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

  Future<void> _settings() async {
    var accent = _accentIndex;
    var size = _fontSize;
    await showModalBottomSheet<void>(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: BoxDecoration(color: AppColors.backgroundSecondary, borderRadius: const BorderRadius.vertical(top: Radius.circular(26)), border: Border.all(color: AppColors.glassBorder)),
        child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(LucideIcons.settings_2, color: _accent), const SizedBox(width: 10), Text('Танзимоти заметкаҳо', style: TextStyle(color: AppColors.textPrimary, fontSize: 19, fontWeight: FontWeight.w800))]),
          const SizedBox(height: 20), Text('Ранги неон', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)), const SizedBox(height: 12),
          Wrap(spacing: 12, runSpacing: 12, children: List.generate(_accents.length, (i) => InkWell(onTap: () => setSheet(() => accent = i), borderRadius: BorderRadius.circular(28), child: Container(width: 38, height: 38, decoration: BoxDecoration(color: _accents[i].withValues(alpha: .16), shape: BoxShape.circle, border: Border.all(color: _accents[i], width: accent == i ? 3 : 1), boxShadow: accent == i ? [BoxShadow(color: _accents[i].withValues(alpha: .35), blurRadius: 10)] : []), child: accent == i ? Icon(LucideIcons.check, color: _accents[i], size: 18) : null)))),
          const SizedBox(height: 20), Row(children: [Text('Андозаи ҳарф', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)), const Spacer(), Text('${size.round()} px', style: TextStyle(color: _accents[accent]))]),
          Slider(value: size, min: 13, max: 23, divisions: 10, activeColor: _accents[accent], onChanged: (v) => setSheet(() => size = v)),
          SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () async { setState(() { _accentIndex = accent; _fontSize = size; }); final prefs = await SharedPreferences.getInstance(); await prefs.setInt('chatapp_notes_accent_v1', accent); await prefs.setDouble('chatapp_notes_font_v1', size); if (ctx.mounted) Navigator.pop(ctx); }, icon: const Icon(LucideIcons.check), label: const Text('Сабт кардани танзимот'), style: FilledButton.styleFrom(backgroundColor: _accents[accent], foregroundColor: Colors.black))),
        ])),
      )),
    );
  }

  Future<void> _edit([_Note? old]) async {
    final title = TextEditingController(text: old?.title ?? '');
    final body = TextEditingController(text: old?.body ?? '');
    final bodyFocus = FocusNode();
    var selectedAccent = (old?.accent ?? _accentIndex).clamp(0, _accents.length - 1);
    var isPinned = old?.pinned ?? false;
    var isChecklist = old?.checklist ?? false;
    final undoStack = <TextEditingValue>[];
    final redoStack = <TextEditingValue>[];
    void applyBodyEdit(String text, int cursor) {
      undoStack.add(body.value);
      if (undoStack.length > 100) undoStack.removeAt(0);
      redoStack.clear();
      body.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: cursor.clamp(0, text.length)),
      );
    }
    final note = await showModalBottomSheet<_Note>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            border: Border.all(color: _accents[selectedAccent].withValues(alpha: .65)),
            boxShadow: [BoxShadow(color: _accents[selectedAccent].withValues(alpha: .10), blurRadius: 22)],
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    Expanded(child: Text(old == null ? 'Заметкаи нав' : 'Таҳрири заметка', style: TextStyle(color: AppColors.textPrimary, fontSize: 21, fontWeight: FontWeight.w800))),
                    IconButton(tooltip: 'Неон', onPressed: () async {
                      final picked = await showModalBottomSheet<int>(
                        context: ctx,
                        backgroundColor: AppColors.surface,
                        builder: (s) => SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Wrap(
                              spacing: 12,
                              children: List.generate(_accents.length, (i) =>
                                IconButton(
                                  onPressed: () => Navigator.pop(s, i),
                                  icon: Icon(
                                    i == selectedAccent ? LucideIcons.circle_check : LucideIcons.circle,
                                    color: _accents[i],
                                    size: 28,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                      if (picked != null) setSheet(() => selectedAccent = picked);
                    }, icon: Icon(LucideIcons.palette, color: _accents[selectedAccent])),
                    PopupMenuButton<String>(icon: Icon(LucideIcons.ellipsis, color: AppColors.textPrimary), onSelected: (v) async {
                      switch (v) {
                        case 'pin': setSheet(() => isPinned = !isPinned); break;
                        case 'checklist': applyBodyEdit('${body.text}${body.text.isEmpty ? '' : '\n'}☐  ', body.text.length + 3); setSheet(() => isChecklist = true); break;
                        case 'bullet': applyBodyEdit('${body.text}${body.text.isEmpty ? '' : '\n'}•  ', body.text.length + 3); setSheet(() {}); break;
                        case 'number': applyBodyEdit('${body.text}${body.text.isEmpty ? '' : '\n'}1.  ', body.text.length + 4); setSheet(() {}); break;
                        case 'date': body.text = '${body.text}${body.text.isEmpty ? '' : '\n'}${DateTime.now().toLocal().toString().substring(0, 16)}'; setSheet(() {}); break;
                        case 'copy': await Clipboard.setData(ClipboardData(text: '${title.text}\n\n${body.text}')); if (ctx.mounted) _message('Матн нусхабардорӣ шуд'); break;
                        case 'share': await SharePlus.instance.share(ShareParams(text: '${title.text}\n\n${body.text}')); break;
                        case 'delete': Navigator.pop(ctx); if (old != null && mounted) await _delete(old); return;
                      }
                    }, itemBuilder: (_) => [
                      PopupMenuItem(value: 'pin', child: ListTile(dense: true, leading: Icon(LucideIcons.pin), title: Text(isPinned ? 'Аз боло гирифтан' : 'Мустаҳкам кардан'))),
                      const PopupMenuItem(value: 'checklist', child: ListTile(dense: true, leading: Icon(LucideIcons.list_checks), title: Text('Рӯйхати чекӣ'))),
                      const PopupMenuItem(value: 'bullet', child: ListTile(dense: true, leading: Icon(LucideIcons.list), title: Text('Рӯйхати буллетӣ'))),
                      const PopupMenuItem(value: 'number', child: ListTile(dense: true, leading: Icon(LucideIcons.list_ordered), title: Text('Рӯйхати рақамдор'))),
                      const PopupMenuItem(value: 'date', child: ListTile(dense: true, leading: Icon(LucideIcons.calendar), title: Text('Иловаи сана ва вақт'))),
                      const PopupMenuItem(value: 'copy', child: ListTile(dense: true, leading: Icon(LucideIcons.copy), title: Text('Нусхабардорӣ'))),
                      const PopupMenuItem(value: 'share', child: ListTile(dense: true, leading: Icon(LucideIcons.share_2), title: Text('Мубодила кардан'))),
                      if (old != null) const PopupMenuItem(value: 'delete', child: ListTile(dense: true, leading: Icon(LucideIcons.trash), title: Text('Нест кардан'))),
                    ]),
                  ]),
                  const SizedBox(height: 16),
                  TextField(
                    controller: title, maxLength: 90,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(color: AppColors.textPrimary),
                    decoration: _decoration('Сарлавҳаи заметка', LucideIcons.type),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: body, focusNode: bodyFocus, minLines: 5, maxLines: 12, maxLength: 6000,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(color: AppColors.textPrimary, height: 1.45, fontSize: _fontSize),
                    decoration: _decoration('Матни заметка', LucideIcons.notebook_pen),
                  ),
                  const SizedBox(height: 4),
                  Wrap(spacing: 2, children: [
                    IconButton(tooltip: 'Ғафс', onPressed: () { final s = body.selection; final a = s.start < 0 ? body.text.length : s.start; final b = s.end < 0 ? a : s.end; final selected = body.text.substring(a,b); body.value = body.value.copyWith(text: body.text.replaceRange(a,b,'**$selected**'), selection: TextSelection.collapsed(offset: a+selected.length+4)); setSheet(() {}); }, icon: const Icon(LucideIcons.bold)),
                    IconButton(tooltip: 'Курсив', onPressed: () { final s = body.selection; final a = s.start < 0 ? body.text.length : s.start; final b = s.end < 0 ? a : s.end; final selected = body.text.substring(a,b); body.value = body.value.copyWith(text: body.text.replaceRange(a,b,'_${selected}_'), selection: TextSelection.collapsed(offset: a+selected.length+2)); setSheet(() {}); }, icon: const Icon(LucideIcons.italic)),
                    IconButton(tooltip: 'Зерхат', onPressed: () { final s = body.selection; final a = s.start < 0 ? body.text.length : s.start; final b = s.end < 0 ? a : s.end; final selected = body.text.substring(a,b); body.value = body.value.copyWith(text: body.text.replaceRange(a,b,'<u>$selected</u>'), selection: TextSelection.collapsed(offset: a+selected.length+7)); setSheet(() {}); }, icon: const Icon(LucideIcons.underline)),
                    IconButton(tooltip: 'Рӯйхат', onPressed: () { body.text = '${body.text}${body.text.isEmpty ? '' : '\n'}•  '; setSheet(() {}); }, icon: const Icon(LucideIcons.list)),
                    IconButton(tooltip: 'Undo', onPressed: undoStack.isEmpty ? null : () { redoStack.add(body.value); body.value = undoStack.removeLast(); setSheet(() {}); }, icon: const Icon(LucideIcons.undo_2)),
                    IconButton(tooltip: 'Redo', onPressed: redoStack.isEmpty ? null : () { undoStack.add(body.value); body.value = redoStack.removeLast(); setSheet(() {}); }, icon: const Icon(LucideIcons.redo_2)),
                  ]),
                  Text('${body.text.trim().isEmpty ? 0 : body.text.trim().split(RegExp(r'\\s+')).length} калима · ${body.text.length} аломат', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  const SizedBox(height: 8),
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
                        title: t.isEmpty ? 'Заметкаи нав' : t,
                        body: b,
                        updatedAt: DateTime.now().millisecondsSinceEpoch,
                        accent: selectedAccent, pinned: isPinned, checklist: isChecklist,
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
    ));
    title.dispose();
    body.dispose();
    bodyFocus.dispose();
    if (note == null || !mounted) return;
    setState(() {
      final i = _notes.indexWhere((n) => n.id == note.id);
      if (i < 0) { _notes.insert(0, note); } else { _notes[i] = note; }
      _notes.sort((a, b) { if (a.pinned != b.pinned) return a.pinned ? -1 : 1; return b.updatedAt.compareTo(a.updatedAt); });
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
        title: Text('Заметкаҳо', style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(tooltip: 'Танзимот', onPressed: _settings, icon: Icon(LucideIcons.settings_2, color: _accent)),
          PopupMenuButton<String>(icon: Icon(LucideIcons.ellipsis, color: AppColors.textPrimary), onSelected: (v) { if (v == 'new') _edit(); if (v == 'settings') _settings(); if (v == 'sort') setState(() => _notes.sort((a,b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()))); }, itemBuilder: (_) => const [
            PopupMenuItem(value: 'new', child: ListTile(dense: true, leading: Icon(LucideIcons.square_pen), title: Text('Заметкаи нав'))),
            PopupMenuItem(value: 'settings', child: ListTile(dense: true, leading: Icon(LucideIcons.settings_2), title: Text('Танзимот'))),
            PopupMenuItem(value: 'sort', child: ListTile(dense: true, leading: Icon(LucideIcons.arrow_down_a_z), title: Text('Ҷобаҷокунии номҳо'))),
          ]),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        backgroundColor: _accent,
        foregroundColor: Colors.black,
        icon: const Icon(LucideIcons.plus),
        label: const Text('Заметкаи нав', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_accent.withValues(alpha: .20), AppColors.neonCyan.withValues(alpha: .10)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Row(children: [
              Container(width: 48, height: 48,
                decoration: BoxDecoration(color: AppColors.neonEmerald.withValues(alpha: .16), borderRadius: BorderRadius.circular(16)),
                child: Icon(LucideIcons.notebook_pen, color: _accent, size: 25)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Заметкаҳои ман', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Фикрҳо, рӯйхатҳо ва нақшаҳо — танҳо дар ҳамин дастгоҳ', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.35)),
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
              hintText: 'Ҷустуҷӯи заметка...', hintStyle: TextStyle(color: AppColors.textSecondary),
              prefixIcon: Icon(LucideIcons.search, color: _accent),
              filled: true, fillColor: AppColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(child: _loading
          ? Center(child: CircularProgressIndicator(color: _accent))
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
                              child: Icon(note.checklist ? LucideIcons.list_checks : LucideIcons.notebook_pen, color: _accents[note.accent.clamp(0, _accents.length - 1)], size: 19)),
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
                              Text('${_date(note.updatedAt)} · ${note.body.trim().isEmpty ? 0 : note.body.trim().split(RegExp(r'\\s+')).length} калима', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                            ])),
                            const SizedBox(width: 4),
                            if (note.pinned) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(LucideIcons.pin, size: 16)),
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
  final int accent;
  final bool pinned;
  final bool checklist;
  const _Note({required this.id, required this.title, required this.body, required this.updatedAt, this.accent = 0, this.pinned = false, this.checklist = false});
  factory _Note.fromJson(Map<String, dynamic> json) => _Note(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    body: json['body'] as String? ?? '',
    updatedAt: json['updatedAt'] as int? ?? 0,
    accent: json['accent'] as int? ?? 0,
    pinned: json['pinned'] as bool? ?? false,
    checklist: json['checklist'] as bool? ?? false,
  );
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'body': body, 'updatedAt': updatedAt, 'accent': accent, 'pinned': pinned, 'checklist': checklist};
}
