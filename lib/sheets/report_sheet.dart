import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../l10n/l10n.dart';
import '../services/report_service.dart';
import '../theme/app_scope.dart';
import '../theme/app_theme.dart';

/// Варақаи шикоят.
///
/// Пас аз фиристодан бастан ҳатмист: корбар набояд шакк кунад, ки шикоят
/// рафт ё не.
class ReportSheet extends StatefulWidget {
  const ReportSheet({
    super.key,
    required this.target,
    required this.targetId,
    this.contextPath,
    this.contentSnapshot,
    this.onBlockAlso,
  });

  final ReportTarget target;
  final String targetId;
  final String? contextPath;
  final String? contentSnapshot;

  /// Агар дода шавад, банди «ва манъ кардан» нишон дода мешавад.
  final Future<void> Function()? onBlockAlso;

  @override
  State<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<ReportSheet> {
  ReportReason? _reason;
  final _details = TextEditingController();
  bool _alsoBlock = true;
  bool _sending = false;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  static const _labels = {
    ReportReason.spam: 'k403',
    ReportReason.abuse: 'k404',
    ReportReason.violence: 'k405',
    ReportReason.sexual: 'k406',
    ReportReason.scam: 'k407',
    ReportReason.other: 'k408',
  };

  Future<void> _submit() async {
    final reason = _reason;
    if (reason == null || _sending) return;
    setState(() => _sending = true);

    var ok = true;
    try {
      await ReportService.submit(
        target: widget.target,
        targetId: widget.targetId,
        reason: reason,
        details: _details.text,
        contextPath: widget.contextPath,
        contentSnapshot: widget.contentSnapshot,
      );
      if (_alsoBlock && widget.onBlockAlso != null) {
        await widget.onBlockAlso!();
      }
    } catch (_) {
      ok = false;
    }

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? tr('k409') : tr('k410'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: Border.all(color: AppColors.glassBorder),
        ),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.glassBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(LucideIcons.flag, color: Colors.redAccent, size: 19),
                  const SizedBox(width: 9),
                  Text(
                    tr('k411'),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ..._labels.entries.map((entry) {
                final selected = _reason == entry.key;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: _sending ? null : () => setState(() => _reason = entry.key),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                      child: Row(
                        children: [
                          Icon(
                            selected
                                ? LucideIcons.circle_check
                                : LucideIcons.circle,
                            size: 18,
                            color: selected
                                ? AppColors.neonEmerald
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Text(
                              tr(entry.value),
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              TextField(
                controller: _details,
                enabled: !_sending,
                maxLines: 3,
                maxLength: 1000,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: tr('k412'),
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                  ),
                  filled: true,
                  fillColor: AppColors.glassFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.glassBorder),
                  ),
                ),
              ),
              if (widget.onBlockAlso != null)
                CheckboxListTile(
                  value: _alsoBlock,
                  onChanged: _sending
                      ? null
                      : (v) => setState(() => _alsoBlock = v ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppColors.neonEmerald,
                  title: Text(
                    tr('k413'),
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
                  ),
                ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    disabledBackgroundColor:
                        Colors.redAccent.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  onPressed: _reason == null || _sending ? null : _submit,
                  child: _sending
                      ? const SizedBox(
                          width: 19,
                          height: 19,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          tr('k414'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
