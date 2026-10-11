import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../l10n/l10n.dart';
import '../../services/launcher_icon_service.dart';
import '../../services/plus_service.dart';
import '../../theme/app_scope.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/neon_backdrop.dart';

class AppIconPickerScreen extends StatefulWidget {
  const AppIconPickerScreen({super.key});

  @override
  State<AppIconPickerScreen> createState() => _AppIconPickerScreenState();
}

class _AppIconPickerScreenState extends State<AppIconPickerScreen> {
  int _selected = 1;
  bool _loading = true;
  bool _saving = false;
  bool _plusActive = false;
  String? _error;

  static const _names = [
    'Emerald', 'Ocean Blue', 'Sunset', 'Royal Gold', 'Crimson',
    'Neon Purple', 'Mint Green', 'Aqua', 'Silver', 'Pink Violet',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final icon = await LauncherIconService.selectedIcon();
      final plus = await PlusService.refresh();
      if (!mounted) return;
      setState(() {
        _selected = icon;
        _plusActive = plus.active;
        _loading = false;
      });
    } on PlusFailure catch (_) {
      if (!mounted) return;
      setState(() {
        _selected = 1;
        _plusActive = false;
        _loading = false;
        _error = tr('k611');
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = tr('k611');
      });
    }
  }

  Future<void> _choose(int icon) async {
    if (_saving || !_plusActive || icon == _selected) return;
    setState(() { _saving = true; _error = null; });
    try {
      final result = await LauncherIconService.setIcon(icon);
      if (!mounted) return;
      setState(() { _selected = result; _saving = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('k650'))),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() { _saving = false; _error = tr('k651'); });
    }
  }

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NeonBackdrop(
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 20, 8),
              child: Row(children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(LucideIcons.arrow_left, color: AppColors.textPrimary, size: 20),
                ),
                Expanded(child: Text(tr('k643'), style: TextStyle(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 20,
                ))),
              ]),
            ),
            Expanded(child: _loading
              ? Center(child: CircularProgressIndicator(color: AppColors.neonEmerald))
              : ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 28), children: [
                  Text(tr('k644'), style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
                  const SizedBox(height: 14),
                  if (!_plusActive)
                    GlassContainer(borderRadius: 16, padding: const EdgeInsets.all(14), child: Row(children: [
                      Icon(LucideIcons.lock, color: AppColors.neonCyan, size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Text(tr('k645'), style: TextStyle(color: AppColors.textPrimary, fontSize: 13.5))),
                    ])),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12.5)),
                  ],
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 10,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, crossAxisSpacing: 9, mainAxisSpacing: 12,
                      childAspectRatio: 0.78,
                    ),
                    itemBuilder: (context, index) {
                      final icon = index + 1;
                      final selected = icon == _selected;
                      return Opacity(
                        opacity: _plusActive ? 1 : 0.55,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _plusActive ? () => _choose(icon) : null,
                            borderRadius: BorderRadius.circular(18),
                            child: GlassContainer(
                              borderRadius: 18,
                              padding: const EdgeInsets.all(12),
                              child: Column(children: [
                                Expanded(child: Center(child: Image.asset(
                                  'assets/app_icons/chatapp_icon_${icon.toString().padLeft(2, '0')}.png',
                                  width: 72, height: 72, fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Icon(LucideIcons.message_circle, size: 68, color: AppColors.neonEmerald),
                                ))),
                                const SizedBox(height: 8),
                                Row(children: [
                                  Expanded(child: Text(_names[index], maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 12.5))),
                                  if (selected) Icon(LucideIcons.circle_check, color: AppColors.neonEmerald, size: 19),
                                ]),
                                if (_saving && selected) ...[
                                  const SizedBox(height: 5),
                                  LinearProgressIndicator(color: AppColors.neonEmerald, minHeight: 2),
                                ],
                              ]),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  Text(tr('k646'), style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4)),
                ])),
          ]),
        ),
      ),
    );
  }
}
