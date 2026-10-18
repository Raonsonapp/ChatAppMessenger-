import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/neon_backdrop.dart';
import '../../widgets/app_logo.dart';
import '../../l10n/l10n.dart';
import '../../theme/app_scope.dart';
import '../../services/app_update_service.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  final AppUpdateService _updates = AppUpdateService.instance;
  String _versionLabel = '...';
  bool _checking = false;
  bool _downloading = false;
  bool _hasDownloadedApk = false;
  double _downloadProgress = 0;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final version = await _updates.currentVersionLabel();
      if (mounted) setState(() => _versionLabel = version);
    } catch (_) {
      if (mounted) setState(() => _versionLabel = 'номаълум');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _checkForUpdates() async {
    if (_checking || _downloading) return;
    setState(() => _checking = true);
    try {
      final update = await _updates.checkForUpdate();
      if (!mounted) return;
      if (update == null) {
        _showMessage('ChatApp нав аст. Навсозӣ лозим нест.');
        return;
      }
      final shouldDownload = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Навсозии ChatApp дастрас аст'),
          content: Text(
            'Версияи нав: ${update.tagName}\n'
            'Рақами сохт: ${update.versionCode}\n\n'
            'APK зеркашӣ шуда, насбкунандаи Android кушода мешавад. '
            'Паёмҳо ва маълумоти барнома бояд нигоҳ дошта шаванд.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Баъдтар'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Навсозӣ'),
            ),
          ],
        ),
      );
      if (shouldDownload == true && mounted) await _downloadAndInstall(update);
    } on InstallPermissionRequired {
      await _openInstallSettings();
    } on AppUpdateException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Навсозӣ санҷида нашуд. Интернетро санҷ ва боз кӯшиш кун.');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _downloadAndInstall(AppUpdateInfo update) async {
    setState(() {
      _downloading = true;
      _downloadProgress = 0;
    });
    try {
      await _updates.downloadAndInstall(
        update,
        onProgress: (value) {
          if (mounted) setState(() => _downloadProgress = value);
        },
      );
      if (mounted) setState(() => _hasDownloadedApk = true);
    } on InstallPermissionRequired {
      if (mounted) setState(() => _hasDownloadedApk = true);
      await _openInstallSettings();
    } on AppUpdateException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('APK зеркашӣ нашуд. Интернетро санҷ ва боз кӯшиш кун.');
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _openInstallSettings() async {
    _showMessage(
      'Барои насб, иҷозати «Install unknown apps / Насби барномаҳои ношинос»-ро барои ChatApp фаъол кун. Баъд ба ин саҳифа баргашта «Идомаи насб»-ро пахш кун.',
    );
    try {
      await _updates.openInstallPermissionSettings();
    } catch (_) {
      _showMessage('Танзимоти иҷозати насб кушода нашуд.');
    }
  }

  Future<void> _continueInstall() async {
    try {
      await _updates.continueInstall();
    } on InstallPermissionRequired {
      await _openInstallSettings();
    } on AppUpdateException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Насбкунанда кушода нашуд. Боз кӯшиш кун.');
    }
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
                      tr('k139'),
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 20),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    const SizedBox(height: 12),
                    const Center(child: AppLogo(size: 72)),
                    const SizedBox(height: 14),
                    Center(
                      child: Text(
                        'ChatApp',
                        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 22),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        'Версия: $_versionLabel',
                        style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.85), fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 14),
                    GlassContainer(
                      borderRadius: 18,
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FilledButton.icon(
                            onPressed: _checking || _downloading ? null : _checkForUpdates,
                            icon: _checking
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.system_update_alt),
                            label: Text(_checking ? 'Навсозӣ санҷида мешавад...' : 'Санҷидани навсозӣ'),
                          ),
                          if (_downloading) ...[
                            const SizedBox(height: 12),
                            LinearProgressIndicator(value: _downloadProgress > 0 ? _downloadProgress : null),
                            const SizedBox(height: 6),
                            Text(
                              _downloadProgress > 0
                                  ? 'Зеркашӣ: ${(_downloadProgress * 100).round()}%'
                                  : 'APK зеркашӣ мешавад...',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                          if (_hasDownloadedApk && !_downloading) ...[
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: _continueInstall,
                              icon: const Icon(Icons.install_mobile),
                              label: const Text('Идомаи насб'),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            'Навсозӣ аз GitHub Release гирифта мешавад. Барои насб иҷозати Android лозим шуда метавонад. Ҳангоми истифодаи ҳамон имзои release барнома бе uninstall нав мешавад.',
                            style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.9), fontSize: 12, height: 1.45),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    GlassContainer(
                      borderRadius: 18,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('k141'),
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 13.5, height: 1.5),
                          ),
                          const SizedBox(height: 16),
                          Divider(color: AppColors.glassBorder, height: 1),
                          const SizedBox(height: 16),
                          _infoRow(LucideIcons.shield_check, tr('k142'), tr('k143')),
                          const SizedBox(height: 12),
                          _infoRow(LucideIcons.database, tr('k144'), tr('k145')),
                          const SizedBox(height: 12),
                          _infoRow(LucideIcons.video, tr('k047'), 'Agora RTC'),
                          const SizedBox(height: 12),
                          _infoRow(LucideIcons.bell, tr('k146'), 'Firebase Cloud Messaging'),
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

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.neonCyan, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.85), fontSize: 12.5)),
            ],
          ),
        ),
      ],
    );
  }
}
