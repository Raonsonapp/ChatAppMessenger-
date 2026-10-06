import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/neon_backdrop.dart';
import '../../l10n/l10n.dart';
import '../../services/media_cache.dart';
import '../../services/media_settings_controller.dart';
import '../../theme/app_scope.dart';

class StorageSettingsScreen extends StatefulWidget {
  const StorageSettingsScreen({super.key});

  @override
  State<StorageSettingsScreen> createState() => _StorageSettingsScreenState();
}

class _StorageSettingsScreenState extends State<StorageSettingsScreen> {
  int? _chats;
  int? _groups;
  int? _communities;
  bool _loading = true;
  int _diskCache = 0;
  bool _clearing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _refreshDiskCache() async {
    final size = await MediaCache.diskSizeBytes();
    if (!mounted) return;
    setState(() => _diskCache = size);
  }

  Future<void> _load() async {
    unawaited(_refreshDiskCache());
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final db = FirebaseFirestore.instance;
    // count() танҳо шумораро мегирад — ҳуҷҷатҳо боргирӣ намешаванд.
    final results = await Future.wait([
      db.collection('conversations').where('participants', arrayContains: uid).count().get(),
      db.collection('groups').where('members', arrayContains: uid).count().get(),
      db.collection('communities').where('members', arrayContains: uid).count().get(),
    ]);

    if (!mounted) return;
    setState(() {
      _chats = results[0].count;
      _groups = results[1].count;
      _communities = results[2].count;
      _loading = false;
    });
  }

  Future<void> _clearImageCache() async {
    if (_clearing) return;
    setState(() => _clearing = true);

    // Ҳам хотира, ҳам диск тоза мешавад — вагарна файлҳои зеркашишуда
    // мемонанд ва «тозакунӣ» бесамар менамояд.
    final freed = await MediaCache.clear();

    if (!mounted) return;
    setState(() {
      _clearing = false;
      _diskCache = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(trf('k184', [_formatBytes(freed)]))),
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return trf('k185', [bytes]);
    if (bytes < 1024 * 1024) return trf('k186', [(bytes / 1024).toStringAsFixed(1)]);
    return trf('k187', [(bytes / (1024 * 1024)).toStringAsFixed(1)]);
  }

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
    final cache = PaintingBinding.instance.imageCache;

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
                      tr('k182'),
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 20),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    // САРФАИ ТРАФИК
                    GlassContainer(
                      borderRadius: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: SwitchListTile(
                        value: mediaSettings.dataSaver,
                        onChanged: (value) async {
                          await mediaSettings.setDataSaver(value);
                          if (mounted) setState(() {});
                        },
                        activeThumbColor: AppColors.neonEmerald,
                        title: Text(
                          tr('k524'),
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                          ),
                        ),
                        subtitle: Text(
                          tr('k532'),
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.35),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // СИФАТИ МЕДИА
                    _sectionLabel(tr('k522')),
                    GlassContainer(
                      borderRadius: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Column(
                        children: [
                          for (final entry in <(MediaQuality, String, String)>[
                            (MediaQuality.original, tr('k529'), '100%'),
                            (MediaQuality.standard, tr('k530'), '1600 px · 80%'),
                            (MediaQuality.saver, tr('k531'), '1024 px · 60%'),
                          ])
                            _choice(
                              label: entry.$2,
                              description: entry.$3,
                              selected: mediaSettings.quality == entry.$1,
                              last: entry.$1 == MediaQuality.saver,
                              onTap: () async {
                                await mediaSettings.setQuality(entry.$1);
                                if (mounted) setState(() {});
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // БОРКУНИИ ХУДКОР
                    _sectionLabel(tr('k523')),
                    GlassContainer(
                      borderRadius: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Column(
                        children: [
                          _autoDownloadRow(
                            icon: LucideIcons.wifi,
                            label: tr('k527'),
                            level: mediaSettings.autoDownloadWifi,
                            onPick: (value) async {
                              await mediaSettings.setAutoDownloadWifi(value);
                              if (mounted) setState(() {});
                            },
                          ),
                          Divider(color: AppColors.glassBorder, height: 1),
                          _autoDownloadRow(
                            icon: LucideIcons.signal,
                            label: tr('k526'),
                            level: mediaSettings.autoDownloadMobile,
                            onPick: (value) async {
                              await mediaSettings.setAutoDownloadMobile(value);
                              if (mounted) setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        tr('k188'),
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    GlassContainer(
                      borderRadius: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      child: _loading
                          ? Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(child: CircularProgressIndicator(color: AppColors.neonEmerald)),
                            )
                          : Column(
                              children: [
                                _statRow(LucideIcons.message_circle, tr('k189'), _chats),
                                Divider(color: AppColors.glassBorder, height: 1),
                                _statRow(LucideIcons.users, tr('k190'), _groups),
                                Divider(color: AppColors.glassBorder, height: 1),
                                _statRow(LucideIcons.hash, tr('k046'), _communities),
                              ],
                            ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        tr('k191'),
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    GlassContainer(
                      borderRadius: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      child: Column(
                        children: [
                          _statRowText(
                            LucideIcons.image,
                            tr('k192'),
                            trf('k193', [cache.currentSize, _formatBytes(cache.currentSizeBytes)]),
                          ),
                          Divider(color: AppColors.glassBorder, height: 1),
                          _statRowText(
                            LucideIcons.hard_drive,
                            tr('k375'),
                            _formatBytes(_diskCache),
                          ),
                          Divider(color: AppColors.glassBorder, height: 1),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _clearing ? null : _clearImageCache,
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                child: Row(
                                  children: [
                                    if (_clearing)
                                      SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          color: Colors.redAccent,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    else
                                      Icon(LucideIcons.trash, color: Colors.redAccent, size: 18),
                                    SizedBox(width: 14),
                                    Text(
                                      tr('k194'),
                                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        tr('k195'),
                        style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.75), fontSize: 12, height: 1.4),
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

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: AppColors.textSecondary.withValues(alpha: 0.7),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _choice({
    required String label,
    required String description,
    required bool selected,
    required bool last,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              child: Row(
                children: [
                  Icon(
                    selected ? LucideIcons.circle_check : LucideIcons.circle,
                    color: selected ? AppColors.neonEmerald : AppColors.textSecondary,
                    size: 19,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          description,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
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

  static String _levelLabel(AutoDownloadLevel level) => switch (level) {
        AutoDownloadLevel.none => tr('k533'),
        AutoDownloadLevel.photos => tr('k534'),
        AutoDownloadLevel.photosAudio => tr('k535'),
        AutoDownloadLevel.all => tr('k536'),
      };

  /// Сатри боркунии худкор барои як навъи шабака.
  ///
  /// Ҳангоми фаъол будани «Сарфаи трафик» интихоб маъно надорад — он ҳамеша
  /// «ҳеҷ чиз» аст, бинобар ин сатр хомӯш нишон дода мешавад.
  Widget _autoDownloadRow({
    required IconData icon,
    required String label,
    required AutoDownloadLevel level,
    required Future<void> Function(AutoDownloadLevel) onPick,
  }) {
    final disabled = mediaSettings.dataSaver;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: disabled ? null : () => _pickLevel(level, onPick),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: disabled ? AppColors.textSecondary : AppColors.neonCyan,
                size: 19,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: disabled ? AppColors.textSecondary : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5,
                  ),
                ),
              ),
              Text(
                disabled ? tr('k533') : _levelLabel(level),
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(width: 6),
              Icon(
                LucideIcons.chevron_right,
                color: AppColors.textSecondary.withValues(alpha: 0.6),
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickLevel(
    AutoDownloadLevel current,
    Future<void> Function(AutoDownloadLevel) onPick,
  ) async {
    final picked = await showModalBottomSheet<AutoDownloadLevel>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.glassBorder),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final level in AutoDownloadLevel.values)
                ListTile(
                  leading: Icon(
                    level == current ? LucideIcons.circle_check : LucideIcons.circle,
                    color: level == current ? AppColors.neonEmerald : AppColors.textSecondary,
                    size: 19,
                  ),
                  title: Text(
                    _levelLabel(level),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                    ),
                  ),
                  onTap: () => Navigator.pop(sheetContext, level),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) await onPick(picked);
  }

  Widget _statRow(IconData icon, String label, int? value) {
    return _statRowText(icon, label, value == null ? '—' : '$value');
  }

  Widget _statRowText(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.neonCyan, size: 18),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
          ),
          Text(value, style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.9), fontSize: 13)),
        ],
      ),
    );
  }
}
