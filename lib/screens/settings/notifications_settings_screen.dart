import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/neon_backdrop.dart';
import '../../l10n/l10n.dart';
import '../../services/notification_prefs.dart';
import '../../theme/app_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

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
  String? _callRingtonePath;

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
    final prefs = await SharedPreferences.getInstance();
    _callRingtonePath = prefs.getString('call_ringtone_path');
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _update(String key, bool value) async {
    // Танҳо дар ҳамин дастгоҳ нигоҳ дошта мешавад; ҳеҷ навиштани Firestore.
    await NotificationPrefs.save(key, value);
  }

  Future<void> _pickCallRingtone() async {
    final result = await FilePicker.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
      withData: false,
    );
    final path = result?.files.single.path;
    if (path == null || path.isEmpty || !File(path).existsSync()) return;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final extension = result!.files.single.extension ?? 'audio';
      final savedPath =
          '${directory.path}${Platform.pathSeparator}call_ringtone.$extension';
      await File(path).copy(savedPath);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('call_ringtone_path', savedPath);
      if (!mounted) return;
      setState(() => _callRingtonePath = savedPath);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Оҳанг нигоҳ дошта нашуд: $error')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Оҳанги занг нав карда шуд')),
    );
  }

  Future<void> _resetCallRingtone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('call_ringtone_path');
    if (!mounted) return;
    setState(() => _callRingtonePath = null);
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
                            child: ListTile(
                              leading: Icon(LucideIcons.music, color: AppColors.neonEmerald),
                              title: Text('Оҳанги занг', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                _callRingtonePath == null
                                    ? 'Оҳанги стандартии ChatApp'
                                    : _callRingtonePath!.split(Platform.pathSeparator).last,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                              trailing: PopupMenuButton<String>(
                                icon: Icon(LucideIcons.ellipsis_vertical, color: AppColors.textSecondary),
                                onSelected: (value) {
                                  if (value == 'choose') _pickCallRingtone();
                                  if (value == 'default') _resetCallRingtone();
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(value: 'choose', child: Text('Интихоб аз телефон')),
                                  if (_callRingtonePath != null)
                                    const PopupMenuItem(value: 'default', child: Text('Оҳанги стандартӣ')),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
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
