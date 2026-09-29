import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../l10n/l10n.dart';
import '../models/app_call.dart';
import '../theme/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/neon_backdrop.dart';
import 'call_screen.dart';

/// Клавиатураи рақамӣ барои занг.
///
/// Рақам ҷустуҷӯ мешавад: занг танҳо ба корбари ChatApp меравад, бинобар ин
/// рӯйхати корбарон аз Firestore хонда мешавад ва номи ёфташуда нишон дода
/// мешавад — вагарна корбар намедонад, ки ба кӣ занг мезанад.
class DialPadScreen extends StatefulWidget {
  const DialPadScreen({super.key});

  @override
  State<DialPadScreen> createState() => _DialPadScreenState();
}

class _DialPadScreenState extends State<DialPadScreen> {
  String _number = '';
  bool _searching = false;

  void _press(String key) {
    // Рақами хеле дароз маъно надорад ва экранро мешиканад.
    if (_number.length >= 20) return;
    HapticFeedback.selectionClick();
    setState(() => _number += key);
  }

  void _backspace() {
    if (_number.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _number = _number.substring(0, _number.length - 1));
  }

  void _clear() => setState(() => _number = '');

  /// Корбарро бо рақам меёбад ва занг мезанад.
  Future<void> _call(CallType type) async {
    final digits = _number.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.length < 5) return;

    setState(() => _searching = true);
    Map<String, dynamic>? found;
    String? foundId;
    try {
      // Рақам метавонад бо «+» ё бе он сабт шуда бошад — ҳарду санҷида
      // мешаванд.
      for (final candidate in {digits, digits.startsWith('+') ? digits.substring(1) : '+$digits'}) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('phone', isEqualTo: candidate)
            .limit(1)
            .get();
        if (snapshot.docs.isNotEmpty) {
          found = snapshot.docs.first.data();
          foundId = snapshot.docs.first.id;
          break;
        }
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() => _searching = false);

    if (found == null || foundId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('k461'))),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          otherUserId: foundId!,
          otherUserName: (found!['name'] as String?) ?? tr('k002'),
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
      body: NeonBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 20, 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(LucideIcons.arrow_left,
                          color: AppColors.textPrimary, size: 20),
                    ),
                    Text(
                      tr('k462'),
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 19,
                      ),
                    ),
                  ],
                ),
              ),
              // Рақам дар ҷои холии боло — то дар экранҳои хурд ҳам ҷой шавад.
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _number.isEmpty ? tr('k463') : _number,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _number.isEmpty
                                ? AppColors.textSecondary.withValues(alpha: 0.45)
                                : AppColors.textPrimary,
                            fontSize: _number.length > 13 ? 24 : 31,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                        if (_number.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: TextButton(
                              onPressed: _clear,
                              child: Text(
                                tr('k464'),
                                style: TextStyle(
                                    color: AppColors.textSecondary, fontSize: 12.5),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              _keypad(),
              _actions(),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _keypad() {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['*', '0', '#'],
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: rows
            .map((row) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: row.map(_key).toList(),
                ))
            .toList(),
      ),
    );
  }

  Widget _key(String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: _PressableCircle(
        onTap: () => _press(value),
        child: Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 25,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _actions() {
    final enabled = _number.length >= 5 && !_searching;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _PressableCircle(
            size: 52,
            onTap: enabled ? () => _call(CallType.video) : null,
            child: Icon(LucideIcons.video,
                color: enabled
                    ? AppColors.neonCyan
                    : AppColors.textSecondary.withValues(alpha: 0.4),
                size: 21),
          ),
          _PressableCircle(
            size: 64,
            background: enabled
                ? AppColors.neonEmerald
                : AppColors.neonEmerald.withValues(alpha: 0.25),
            onTap: enabled ? () => _call(CallType.audio) : null,
            child: _searching
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: AppColors.background, strokeWidth: 2),
                  )
                : Icon(LucideIcons.phone, color: AppColors.background, size: 24),
          ),
          _PressableCircle(
            size: 52,
            onTap: _number.isEmpty ? null : _backspace,
            child: Icon(LucideIcons.delete,
                color: _number.isEmpty
                    ? AppColors.textSecondary.withValues(alpha: 0.4)
                    : AppColors.textSecondary,
                size: 21),
          ),
        ],
      ),
    );
  }
}

/// Тугмаи мудаввар бо аниматсияи зеркунӣ.
class _PressableCircle extends StatefulWidget {
  const _PressableCircle({
    required this.child,
    required this.onTap,
    this.size = 68,
    this.background,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double size;
  final Color? background;

  @override
  State<_PressableCircle> createState() => _PressableCircleState();
}

class _PressableCircleState extends State<_PressableCircle> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;

    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _down = true),
      onTapUp: disabled ? null : (_) => setState(() => _down = false),
      onTapCancel: disabled ? null : () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.92 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.background ?? AppColors.glassFill,
            border: widget.background == null
                ? Border.all(color: AppColors.glassBorder)
                : null,
          ),
          alignment: Alignment.center,
          child: widget.child,
        ),
      ),
    );
  }
}
