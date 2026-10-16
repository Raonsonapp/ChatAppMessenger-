import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../l10n/l10n.dart';
import '../services/voice_transcription_service.dart';
import '../theme/app_theme.dart';

/// Тугмаи A барои гирифтани матни паёми овозӣ.
class VoiceTranscriptPanel extends StatefulWidget {
  const VoiceTranscriptPanel({super.key, required this.audioUrl});
  final String audioUrl;

  @override
  State<VoiceTranscriptPanel> createState() => _VoiceTranscriptPanelState();
}

class _VoiceTranscriptPanelState extends State<VoiceTranscriptPanel> {
  bool _loading = false;
  String? _transcript;
  String? _error;

  Future<void> _transcribe() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(tr('k700'), style: TextStyle(color: AppColors.textPrimary)),
        content: Text(tr('k709'), style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(tr('k242')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(tr('k694')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await VoiceTranscriptionService.transcribe(widget.audioUrl);
      if (!mounted) return;
      setState(() => _transcript = result);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error is VoiceTranscriptionFailure
          ? error.message
          : tr('k487'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 2, 6, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: _loading ? null : _transcribe,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.neonCyan.withValues(alpha: .16),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.neonCyan.withValues(alpha: .7)),
                    ),
                    child: _loading
                        ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5))
                        : Text('A', style: TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.w900, fontSize: 13)),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    _loading ? tr('k701') : tr('k700'),
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          if (_transcript != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.glassFill,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: SelectableText(_transcript!, style: TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.35))),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: tr('k432'),
                    onPressed: () => Clipboard.setData(ClipboardData(text: _transcript!)),
                    icon: Icon(LucideIcons.copy, size: 16, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 6),
              child: Text(_error!, style: const TextStyle(color: Colors.orangeAccent, fontSize: 11.5)),
            ),
        ],
      ),
    );
  }
}
