import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../l10n/l10n.dart';
import '../../services/device_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_scope.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/neon_backdrop.dart';

/// Дастгоҳҳое ки ба ҳамин ҳисоб пайвастанд.
///
/// Рӯйхат аз `users/{uid}/devices` меояд — ҳамон ҷое ки ҳар дастгоҳ ҳангоми
/// сабти токени огоҳӣ худро менависад.
class LinkedDevicesScreen extends StatefulWidget {
  const LinkedDevicesScreen({super.key});

  @override
  State<LinkedDevicesScreen> createState() => _LinkedDevicesScreenState();
}

class _LinkedDevicesScreenState extends State<LinkedDevicesScreen> {
  String? _currentToken;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final token = await NotificationService.resolveCurrentToken();
    if (!mounted) return;
    setState(() => _currentToken = token);
  }

  Future<void> _unlink(LinkedDevice device) async {
    final uid = DeviceService.currentUid;
    if (uid == null || _busy) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(tr('k500'), style: TextStyle(color: AppColors.textPrimary, fontSize: 17)),
        content: Text(device.label, style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(tr('k277'), style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(tr('k500'), style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await DeviceService.unlink(uid, device);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('k501'))));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('k543'))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
    final uid = DeviceService.currentUid;

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
                      tr('k494'),
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 20),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: uid == null
                    ? Center(child: Text(tr('k502'), style: TextStyle(color: AppColors.textSecondary)))
                    : StreamBuilder<List<LinkedDevice>>(
                        stream: DeviceService.watch(uid, currentToken: _currentToken),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator(color: AppColors.neonEmerald));
                          }
                          final devices = snapshot.data ?? const <LinkedDevice>[];
                          if (devices.isEmpty) {
                            return Center(
                              child: Text(tr('k502'), style: TextStyle(color: AppColors.textSecondary)),
                            );
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            itemCount: devices.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) => _deviceCard(devices[index]),
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

  Widget _deviceCard(LinkedDevice device) {
    final last = device.lastActive;
    return GlassContainer(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(
            device.platform == 'Android' || device.platform == 'iOS'
                ? LucideIcons.smartphone
                : LucideIcons.monitor,
            color: AppColors.neonCyan,
            size: 22,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.label,
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14.5),
                ),
                const SizedBox(height: 3),
                Text(
                  device.isCurrent
                      ? tr('k499')
                      : last == null
                          ? tr('k503')
                          : '${tr('k503')}: ${_formatDate(last)}',
                  style: TextStyle(
                    color: device.isCurrent ? AppColors.neonEmerald : AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (!device.isCurrent)
            IconButton(
              onPressed: _busy ? null : () => _unlink(device),
              icon: const Icon(LucideIcons.log_out, color: Colors.redAccent, size: 19),
              tooltip: tr('k500'),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}.${two(local.month)}.${local.year} ${two(local.hour)}:${two(local.minute)}';
  }
}
