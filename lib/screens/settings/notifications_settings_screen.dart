import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/neon_backdrop.dart';
import '../../l10n/l10n.dart';
import '../../services/notification_prefs.dart';
import '../../theme/app_scope.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  bool _messageNotifications = true;
  bool _sound = true;
  bool _vibration = true;
  bool _showPreview = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Интихоби огоҳинома ба худи телефон тааллуқ дорад. Аз сервер хонда
    // намешавад, то танзимоти ин дастгоҳ бо дастгоҳи дигар омехта нашавад.
    final values = await Future.wait([
      NotificationPrefs.read('messageNotifications'),
      NotificationPrefs.read('notificationSound'),
      NotificationPrefs.read('notificationVibration'),
      NotificationPrefs.read('notificationPreview'),
    ]);
    _messageNotifications = values[0];
    _sound = values[1];
    _vibration = values[2];
    _showPreview = values[3];
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _update(String key, bool value) async {
    // Танҳо дар ҳамин дастгоҳ нигоҳ дошта мешавад; ҳеҷ навиштани Firestore.
    await NotificationPrefs.save(key, value);
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
                padding: const EdgeInsets.fromLTRB(10, 10, 20, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(LucideIcons.arrow_left, color: AppColors.textPrimary, size: 20),
                    ),
                    Text(
                      tr('k146'),
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 20),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(color: AppColors.neonEmerald))
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        children: [
                          GlassContainer(
                            borderRadius: 18,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Column(
                              children: [
                                _switchRow(tr('k170'), _messageNotifications, (v) {
                                  setState(() => _messageNotifications = v);
                                  _update('messageNotifications', v);
                                }),
                                Divider(color: AppColors.glassBorder, height: 1),
                                _switchRow(tr('k171'), _sound, (v) {
                                  setState(() => _sound = v);
                                  _update('notificationSound', v);
                                }),
                                Divider(color: AppColors.glassBorder, height: 1),
                                _switchRow(tr('k172'), _vibration, (v) {
                                  setState(() => _vibration = v);
                                  _update('notificationVibration', v);
                                }),
                                Divider(color: AppColors.glassBorder, height: 1),
                                _switchRow(tr('k173'), _showPreview, (v) {
                                  setState(() => _showPreview = v);
                                  _update('notificationPreview', v);
                                }, showDivider: false),
                              ],
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

  Widget _switchRow(String title, bool value, ValueChanged<bool> onChanged, {bool showDivider = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
          ),
          Switch(value: value, onChanged: onChanged, activeThumbColor: AppColors.neonEmerald),
        ],
      ),
    );
  }
}
