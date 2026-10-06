import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/empty_state.dart';
import '../models/app_call.dart';
import 'call_screen.dart';
import '../sheets/contact_picker_sheet.dart';
import '../l10n/l10n.dart';
import '../theme/app_scope.dart';

/// Зангҳои банақшагирифташуда — воқеан дар Firestore (`scheduledCalls`)
/// нигоҳ дошта мешаванд. Дар вақти муайяншуда огоҳинома АВТОМАТӢ фиристода
/// намешавад (ин ба backend-и алоҳида ниёз дорад) — корбар бояд худаш ба
/// ин саҳифа баргардад ва "Занг задан" зер кунад. Мо ин маҳдудиятро пинҳон
/// намекунем.
class ScheduledCallsScreen extends StatelessWidget {
  const ScheduledCallsScreen({super.key});

  CollectionReference<Map<String, dynamic>> get _ref =>
      FirebaseFirestore.instance.collection('scheduledCalls');

  void _openCreate(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ContactPickerSheet(
        onSelected: (user) async {
          Navigator.pop(context);
          final time = await _pickDateTime(context);
          if (time == null) return;
          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid == null) return;
          await _ref.add({
            'createdBy': uid,
            'withUid': user['uid'],
            'withName': user['name'],
            'type': CallType.audio.name,
            'time': Timestamp.fromDate(time),
          });
        },
      ),
    );
  }

  Future<DateTime?> _pickDateTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: DateTime.now(),
    );
    if (date == null || !context.mounted) return null;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _delete(String id) => _ref.doc(id).delete();

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundSecondary,
        foregroundColor: AppColors.textPrimary,
        title: Text(tr('k432'), style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            onPressed: () => _openCreate(context),
            icon: Icon(LucideIcons.plus, color: AppColors.accent),
          ),
        ],
      ),
      body: currentUid == null
          ? const SizedBox.shrink()
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _ref.where('createdBy', isEqualTo: currentUid).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator(color: AppColors.accent));
                }
                final docs = snapshot.data!.docs.toList()
                  ..sort((a, b) {
                    final ta = (a.data()['time'] as Timestamp?)?.toDate() ?? DateTime.now();
                    final tb = (b.data()['time'] as Timestamp?)?.toDate() ?? DateTime.now();
                    return ta.compareTo(tb);
                  });
                if (docs.isEmpty) {
                  return EmptyState(icon: LucideIcons.timer, title: tr('k432'), description: tr('k439'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(14),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final data = docs[i].data();
                    final time = (data['time'] as Timestamp?)?.toDate();
                    final name = (data['withName'] ?? '') as String;
                    final type = (data['type'] == 'video') ? CallType.video : CallType.audio;
                    return GlassContainer(
                      borderRadius: 16,
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Icon(type == CallType.video ? LucideIcons.video : LucideIcons.phone, color: AppColors.callGreen, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14.5)),
                                if (time != null)
                                  Text(
                                    '${time.day.toString().padLeft(2, '0')}.${time.month.toString().padLeft(2, '0')}.${time.year} · ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CallScreen(otherUserId: data['withUid'] as String, otherUserName: name, type: type),
                              ),
                            ),
                            icon: Icon(LucideIcons.phone_call, color: AppColors.accent, size: 19),
                          ),
                          IconButton(
                            onPressed: () => _delete(docs[i].id),
                            icon: Icon(LucideIcons.trash, color: AppColors.missedRed, size: 18),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
