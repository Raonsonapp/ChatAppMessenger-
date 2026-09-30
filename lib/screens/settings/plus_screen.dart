import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../l10n/l10n.dart';
import '../../services/plus_service.dart';
import '../../theme/app_scope.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/neon_backdrop.dart';
import '../../widgets/plus_badge.dart';
import 'admin_panel_screen.dart';
import 'appearance_settings_screen.dart';

/// ChatApp Plus: ҳолат, моҳи муфт ва — барои соҳиб — гузаргоҳ ба панели соҳиб.
class PlusScreen extends StatefulWidget {
  const PlusScreen({super.key});

  @override
  State<PlusScreen> createState() => _PlusScreenState();
}

class _PlusScreenState extends State<PlusScreen> {
  /// Ҳолат аз сервер. Танҳо сервер медонад, ки кӣ соҳиб аст.
  PlusStatus _status = PlusStatus.none;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final status = await PlusService.refresh();
      if (!mounted) return;
      setState(() {
        _status = status;
        _loading = false;
      });
    } on PlusFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _describe(failure.code);
      });
    }
  }

  Future<void> _startTrial() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final status = await PlusService.startTrial();
      if (!mounted) return;
      setState(() {
        _status = status;
        _busy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('k592'))));
    } on PlusFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = _describe(failure.code);
      });
    }
  }

  static String _describe(String code) => switch (code) {
        'trial-not-available' => tr('k593'),
        'not-owner' => tr('k609'),
        'user-not-found' => tr('k610'),
        'network' || 'bad-response' => tr('k611'),
        _ => tr('k543'),
      };

  String get _sourceLabel => switch (_status.source) {
        PlusSource.owner => tr('k590'),
        PlusSource.ownerGrant => tr('k596'),
        PlusSource.trial => tr('k597'),
        PlusSource.purchase => tr('k598'),
        PlusSource.none => tr('k589'),
      };

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
                      tr('k587'),
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? Center(child: CircularProgressIndicator(color: AppColors.neonEmerald))
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        children: [
                          _statusCard(),
                          const SizedBox(height: 16),
                          _featuresCard(),
                          const SizedBox(height: 16),
                          _purchaseNote(),
                          if (_status.isOwner) ...[
                            const SizedBox(height: 16),
                            _ownerEntry(),
                          ],
                          if (_error != null) ...[
                            const SizedBox(height: 14),
                            Text(
                              _error!,
                              style: const TextStyle(color: Colors.redAccent, fontSize: 12.5),
                            ),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusCard() {
    final expiresAt = _status.expiresAt;
    return GlassContainer(
      borderRadius: 18,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _status.active ? tr('k588') : tr('k589'),
                style: TextStyle(
                  color: _status.active ? AppColors.neonEmerald : AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              const SizedBox(width: 10),
              PlusBadge(status: _status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _sourceLabel,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          if (_status.active) ...[
            const SizedBox(height: 4),
            Text(
              expiresAt == null ? tr('k595') : '${tr('k594')} ${_formatDate(expiresAt)}',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
          if (_status.canStartTrial) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonEmerald,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _busy ? null : _startTrial,
                child: _busy
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.background,
                        ),
                      )
                    : Text(
                        tr('k591'),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                      ),
              ),
            ),
          ],
          if (!_status.active && _status.trialUsed) ...[
            const SizedBox(height: 10),
            Text(
              tr('k593'),
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
            ),
          ],
        ],
      ),
    );
  }

  /// Имкониятҳо. Ин ҷо танҳо онҳое ҳастанд, ки воқеан кор мекунанд — рӯйхати
  /// ваъдаҳо гузоштан корбарро фиреб медиҳад.
  Widget _featuresCard() {
    return GlassContainer(
      borderRadius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        children: [
          _feature(LucideIcons.palette, tr('k616'), () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AppearanceSettingsScreen()),
            );
          }),
          _feature(LucideIcons.badge_check, tr('k617'), null, last: true),
        ],
      ),
    );
  }

  Widget _feature(IconData icon, String label, VoidCallback? onTap, {bool last = false}) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
              child: Row(
                children: [
                  Icon(icon, color: AppColors.neonCyan, size: 19),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14.5,
                      ),
                    ),
                  ),
                  if (onTap != null)
                    Icon(
                      LucideIcons.chevron_right,
                      color: AppColors.textSecondary.withValues(alpha: 0.6),
                      size: 17,
                    ),
                ],
              ),
            ),
          ),
        ),
        if (!last) Divider(color: AppColors.glassBorder, height: 1),
      ],
    );
  }

  /// Хариди обуна ҳанӯз нест ва инро рӯирост мегӯем.
  Widget _purchaseNote() {
    return GlassContainer(
      borderRadius: 16,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.info, color: AppColors.textSecondary, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('k612'),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  tr('k613'),
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ownerEntry() {
    return GlassContainer(
      borderRadius: 18,
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              children: [
                const Text('♛', style: TextStyle(color: Color(0xFFFFC857), fontSize: 17)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tr('k599'),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                    ),
                  ),
                ),
                Icon(
                  LucideIcons.chevron_right,
                  color: AppColors.textSecondary.withValues(alpha: 0.6),
                  size: 17,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}.${two(local.month)}.${local.year}';
  }
}
