import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../theme/app_theme.dart';
import '../services/media_service.dart';
import '../l10n/l10n.dart';
import '../theme/app_scope.dart';
import '../utils/waveform.dart';

/// Сабти паёми овозӣ. Ҳангоми сабт ба ҷои майдони матн нишон дода мешавад:
/// вақти гузашта, тугмаи бекор кардан ва тугмаи фиристодан.
class VoiceRecorderBar extends StatefulWidget {
  /// Файли сабтшуда ва давомнокии он.
  /// `waveform` — қиматҳои воқеии баландии овоз (0…100), ки ҳангоми сабт аз
  /// микрофон гирифта шудаанд. Гиранда ҳамонҳоро мекашад.
  final void Function(File file, Duration duration, List<int> waveform) onRecorded;
  final VoidCallback onCancel;

  const VoiceRecorderBar({super.key, required this.onRecorded, required this.onCancel});

  @override
  State<VoiceRecorderBar> createState() => _VoiceRecorderBarState();
}

class _VoiceRecorderBarState extends State<VoiceRecorderBar> {
  final AudioRecorder _recorder = AudioRecorder();
  Timer? _timer;

  /// Таймери ҷудо барои амплитуда: он бояд аз ҳисоби сония зуд-зудтар
  /// хонда шавад, вагарна мавҷ ҳамвор ва бемаънӣ мешавад.
  Timer? _amplitudeTimer;
  final List<double> _samples = [];
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

    // Ҳар 100 мс як намуна. Барои сабти як дақиқа ин 600 намуна аст, ки баъд
    // ба 40 банд фишурда мешавад.
    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
      try {
        final amplitude = await _recorder.getAmplitude();
        _samples.add(Waveform.normalize(amplitude.current));
      } catch (_) {
        // Дар баъзе дастгоҳҳо амплитуда дастрас нест — он вақт мавҷ холӣ
        // мемонад ва хати оддӣ нишон дода мешавад. Ин сабтро вайрон намекунад.
      }
    });
  }

  Future<void> _cancel() async {
    _timer?.cancel();
    _amplitudeTimer?.cancel();
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
    _amplitudeTimer?.cancel();
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
    widget.onRecorded(file, _elapsed, Waveform.compress(_samples));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _amplitudeTimer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
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
