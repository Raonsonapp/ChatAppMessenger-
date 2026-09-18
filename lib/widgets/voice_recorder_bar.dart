import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../theme/app_theme.dart';
import '../services/media_service.dart';
import '../l10n/l10n.dart';

/// Сабти паёми овозӣ. Ҳангоми сабт ба ҷои майдони матн нишон дода мешавад:
/// вақти гузашта, тугмаи бекор кардан ва тугмаи фиристодан.
class VoiceRecorderBar extends StatefulWidget {
  /// Файли сабтшуда ва давомнокии он.
  final void Function(File file, Duration duration) onRecorded;
  final VoidCallback onCancel;

  const VoiceRecorderBar({super.key, required this.onRecorded, required this.onCancel});

  @override
  State<VoiceRecorderBar> createState() => _VoiceRecorderBarState();
}

class _VoiceRecorderBarState extends State<VoiceRecorderBar> {
  final AudioRecorder _recorder = AudioRecorder();
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  String? _path;
  bool _starting = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    if (!await _recorder.hasPermission()) {
      if (!mounted) return;
      setState(() {
        _starting = false;
        _error = tr('k317');
      });
      return;
    }

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);

    if (!mounted) return;
    setState(() {
      _path = path;
      _starting = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  Future<void> _cancel() async {
    _timer?.cancel();
    await _recorder.cancel();
    final path = _path;
    if (path != null) {
      // Файли нимкораро нигоҳ надорем.
      await File(path).delete().catchError((_) => File(path));
    }
    widget.onCancel();
  }

  Future<void> _send() async {
    _timer?.cancel();
    final path = await _recorder.stop();
    if (path == null) {
      widget.onCancel();
      return;
    }
    final file = File(path);
    if (!await file.exists() || _elapsed.inMilliseconds < 500) {
      // Пахши тасодуфӣ — чизе намефиристем.
      await file.delete().catchError((_) => file);
      widget.onCancel();
      return;
    }
    widget.onRecorded(file, _elapsed);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Row(
        children: [
          Expanded(
            child: Text(_error!, style: TextStyle(color: Colors.redAccent, fontSize: 13)),
          ),
          IconButton(
            onPressed: widget.onCancel,
            icon: Icon(LucideIcons.x, color: AppColors.textSecondary, size: 20),
          ),
        ],
      );
    }

    return Row(
      children: [
        IconButton(
          onPressed: _starting ? null : _cancel,
          icon: Icon(LucideIcons.trash, color: Colors.redAccent, size: 20),
        ),
        Container(
          width: 9,
          height: 9,
          decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Text(
          MediaService.formatDuration(_elapsed),
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: _starting ? null : _send,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppColors.neonGradient),
            child: Icon(LucideIcons.send, color: AppColors.background, size: 20),
          ),
        ),
      ],
    );
  }
}
