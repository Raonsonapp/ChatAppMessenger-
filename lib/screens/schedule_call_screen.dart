import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../l10n/l10n.dart';
import '../models/app_call.dart';
import '../theme/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/neon_backdrop.dart';

/// Банақшагирии занг.
///
/// Занг дар `scheduledCalls` сабт мешавад; вақтҳо бо феҳристҳои воқеии
/// система интихоб мешаванд, ҳељ сана дар код нест.
class ScheduleCallScreen extends StatefulWidget {
  const ScheduleCallScreen({super.key});

  @override
  State<ScheduleCallScreen> createState() => _ScheduleCallScreenState();
}

class _ScheduleCallScreenState extends State<ScheduleCallScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();

  late DateTime _start;
  late DateTime _end;
  CallType _type = CallType.video;
  bool _needsApproval = false;
  int _reminderMinutes = 15;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Пешфарз: соати расидаи наздиктарин, то корбар вақти гузаштаро
    // тасодуфан нагузорад.
    final now = DateTime.now();
    _start = DateTime(now.year, now.month, now.day, now.hour + 1);
    _end = _start.add(const Duration(minutes: 30));
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final base = isStart ? _start : _end;
    final date = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (date == null || !mounted) return;
    setState(() {
      final updated = DateTime(date.year, date.month, date.day, base.hour, base.minute);
      if (isStart) {
        _start = updated;
        // Анҷом ҳељ гоҳ пеш аз оғоз набошад.
        if (_end.isBefore(_start)) _end = _start.add(const Duration(minutes: 30));
      } else {
        _end = updated.isBefore(_start) ? _start.add(const Duration(minutes: 30)) : updated;
      }
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final base = isStart ? _start : _end;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: base.hour, minute: base.minute),
    );
    if (time == null || !mounted) return;
    setState(() {
      final updated =
          DateTime(base.year, base.month, base.day, time.hour, time.minute);
      if (isStart) {
        _start = updated;
        if (_end.isBefore(_start)) _end = _start.add(const Duration(minutes: 30));
      } else {
        _end = updated.isBefore(_start) ? _start.add(const Duration(minutes: 30)) : updated;
      }
    });
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _saving) return;
    setState(() => _saving = true);

    var ok = true;
    try {
      await FirebaseFirestore.instance.collection('scheduledCalls').add({
        'ownerId': uid,
        'participants': [uid],
        'title': _title.text.trim().isEmpty ? tr('k465') : _title.text.trim(),
        'description': _description.text.trim(),
        'startAt': Timestamp.fromDate(_start),
        'endAt': Timestamp.fromDate(_end),
        'type': _type == CallType.video ? 'video' : 'audio',
        'needsApproval': _needsApproval,
        'reminderMinutes': _reminderMinutes,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      ok = false;
    }

    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? tr('k466') : tr('k467'))),
    );
  }

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
                padding: const EdgeInsets.fromLTRB(10, 10, 20, 6),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(LucideIcons.arrow_left,
                          color: AppColors.textPrimary, size: 20),
                    ),
                    Expanded(
                      child: Text(
                        tr('k468'),
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 19,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 26),
                  children: [
                    _field(_title, tr('k465'), LucideIcons.type),
                    const SizedBox(height: 11),
                    _field(_description, tr('k469'), LucideIcons.file_text,
                        lines: 3),
                    const SizedBox(height: 18),
                    _dateTimeRow(tr('k470'), _start, isStart: true),
                    const SizedBox(height: 11),
                    _dateTimeRow(tr('k471'), _end, isStart: false),
                    const SizedBox(height: 18),
                    _typeRow(),
                    const SizedBox(height: 11),
                    _approvalRow(),
                    const SizedBox(height: 11),
                    _reminderRow(),
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 50,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.neonEmerald,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: AppColors.background, strokeWidth: 2),
                              )
                            : Text(
                                tr('k472'),
                                style: TextStyle(
                                  color: AppColors.background,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
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

  Widget _field(TextEditingController controller, String hint, IconData icon,
      {int lines = 1}) {
    return GlassContainer(
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: lines > 1 ? 14 : 0),
            child: Icon(icon, size: 18, color: AppColors.neonCyan),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: lines,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14.5),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.6)),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateTimeRow(String label, DateTime value, {required bool isStart}) {
    return GlassContainer(
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(LucideIcons.calendar, size: 18, color: AppColors.neonCyan),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () => _pickDate(isStart: isStart),
            child: Text(
              _formatDate(value),
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () => _pickTime(isStart: isStart),
            child: Text(
              _formatTime(value),
              style: TextStyle(
                  color: AppColors.neonEmerald,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeRow() {
    return GlassContainer(
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(LucideIcons.video, size: 18, color: AppColors.neonCyan),
          const SizedBox(width: 11),
          Expanded(
            child: Text(tr('k473'),
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ),
          for (final type in CallType.values)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: GestureDetector(
                onTap: () => setState(() => _type = type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: _type == type
                        ? AppColors.neonEmerald.withValues(alpha: 0.18)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _type == type
                          ? AppColors.neonEmerald
                          : AppColors.glassBorder,
                    ),
                  ),
                  child: Text(
                    type == CallType.video ? tr('k474') : tr('k475'),
                    style: TextStyle(
                      color: _type == type
                          ? AppColors.neonEmerald
                          : AppColors.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _approvalRow() {
    return GlassContainer(
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: SwitchListTile(
        value: _needsApproval,
        onChanged: (v) => setState(() => _needsApproval = v),
        contentPadding: EdgeInsets.zero,
        activeThumbColor: AppColors.neonEmerald,
        title: Text(
          tr('k476'),
          style: TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
        ),
      ),
    );
  }

  Widget _reminderRow() {
    const options = [0, 5, 15, 30, 60];
    return GlassContainer(
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(LucideIcons.bell, size: 18, color: AppColors.neonCyan),
          const SizedBox(width: 11),
          Expanded(
            child: Text(tr('k477'),
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ),
          DropdownButton<int>(
            value: _reminderMinutes,
            underline: const SizedBox.shrink(),
            dropdownColor: AppColors.surface,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
            items: options
                .map((m) => DropdownMenuItem(
                      value: m,
                      child: Text(m == 0 ? tr('k478') : trf('k479', [m])),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _reminderMinutes = v ?? 15),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year}';
  }

  static String _formatTime(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.hour)}:${two(d.minute)}';
  }
}
