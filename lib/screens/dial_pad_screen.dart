import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_theme.dart';
import '../models/app_call.dart';
import 'call_screen.dart';
import '../l10n/l10n.dart';
import '../utils/user_search.dart';
import '../theme/app_scope.dart';

/// Рақамгир — WhatsApp-услуб. Азбаски занг танҳо байни корбарони ин барнома
/// (Agora) воқеӣ кор мекунад, рақами воридшуда дар байни корбарони
/// бақайдгирифташуда ҷустуҷӯ мешавад — агар ёфт шавад, занг сар мешавад;
/// вагарна хабари ҳалол нишон дода мешавад (на занги қалбакӣ).
class DialPadScreen extends StatefulWidget {
  const DialPadScreen({super.key});

  @override
  State<DialPadScreen> createState() => _DialPadScreenState();
}

class _DialPadScreenState extends State<DialPadScreen> {
  String _number = '';
  bool _searching = false;

  static const _keys = [
    ['1', ''], ['2', 'ABC'], ['3', 'DEF'],
    ['4', 'GHI'], ['5', 'JKL'], ['6', 'MNO'],
    ['7', 'PQRS'], ['8', 'TUV'], ['9', 'WXYZ'],
    ['*', ''], ['0', '+'], ['#', ''],
  ];

  void _tap(String digit) => setState(() => _number += digit);
  void _backspace() {
    if (_number.isEmpty) return;
    setState(() => _number = _number.substring(0, _number.length - 1));
  }

  Future<void> _call(CallType type) async {
    if (_number.trim().isEmpty) return;
    setState(() => _searching = true);
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final snapshot = await FirebaseFirestore.instance.collection('users').limit(kUserSearchLimit).get();
    final match = snapshot.docs.where((doc) {
      if (doc.id == currentUid) return false;
      return userMatchesQuery(doc.data(), _number.trim());
    }).toList();
    if (!mounted) return;
    setState(() => _searching = false);
    if (match.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('k229'))));
      return;
    }
    final data = match.first.data();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          otherUserId: match.first.id,
          otherUserName: (data['name'] ?? tr('k002')) as String,
          type: type,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundSecondary,
        foregroundColor: AppColors.textPrimary,
        title: Text(tr('k427'), style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),
          Text(
            _number.isEmpty ? ' ' : _number,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 30, fontWeight: FontWeight.w600, letterSpacing: 2),
          ),
          const Spacer(),
          ...List.generate(4, (row) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(3, (col) {
                  final key = _keys[row * 3 + col];
                  return _padKey(key[0], key[1]);
                }),
              ),
            );
          }),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Material(
                color: AppColors.callGreen,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _searching ? null : () => _call(CallType.audio),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: _searching
                        ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background))
                        : Icon(LucideIcons.phone, color: AppColors.background, size: 26),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Material(
                color: AppColors.accent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _searching ? null : () => _call(CallType.video),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Icon(LucideIcons.video, color: AppColors.background, size: 26),
                  ),
                ),
              ),
              if (_number.isNotEmpty) ...[
                const SizedBox(width: 20),
                IconButton(
                  onPressed: _backspace,
                  icon: Icon(Icons.backspace_outlined, color: AppColors.textSecondary, size: 22),
                ),
              ],
            ],
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _padKey(String digit, String letters) {
    return InkWell(
      borderRadius: BorderRadius.circular(36),
      onTap: () => _tap(digit),
      child: Container(
        width: 68,
        height: 68,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.glassFill, border: Border.all(color: AppColors.glassBorder)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(digit, style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w600)),
            if (letters.isNotEmpty)
              Text(letters, style: TextStyle(color: AppColors.textSecondary, fontSize: 9, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }
}
