import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _paused = false;
  bool _locked = false;
  bool _dragCancel = false;
  bool _isSending = false;

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
    if (_starting || _isSending) return;
    _isSending = true;
    _timer?.cancel();
    _amplitudeTimer?.cancel();
    try {
      final path = await _recorder.stop();
      if (path == null) {
        widget.onCancel();
        return;
      }
      final file = File(path);
      if (!await file.exists() || _elapsed.inMilliseconds < 500) {
        await file.delete().catchError((_) => file);
        widget.onCancel();
        return;
      }
      widget.onRecorded(file, _elapsed, Waveform.compress(_samples));
    } catch (_) {
      if (mounted) setState(() => _error = 'Сабти овоз нигоҳ дошта нашуд. Боз кӯшиш кунед.');
    } finally {
      _isSending = false;
    }
  }

  Future<void> _togglePause() async {
    if (_starting || _isSending) return;
    try {
      if (_paused) {
        await _recorder.resume();
        if (!mounted) return;
        setState(() => _paused = false);
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted && !_paused) setState(() => _elapsed += const Duration(seconds: 1));
        });
        _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
          try {
            final amp = await _recorder.getAmplitude();
            _samples.add(Waveform.normalize(amp.current));
          } catch (_) {}
        });
      } else {
        await _recorder.pause();
        _timer?.cancel();
        _amplitudeTimer?.cancel();
        if (mounted) setState(() => _paused = true);
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Таваққуфи сабт дастгирӣ намешавад.');
    }
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_starting || _isSending) return;
    if (details.delta.dy < -2 && details.localPosition.dy < 0 && !_locked) {
      HapticFeedback.selectionClick();
      setState(() => _locked = true);
    }
    if (details.delta.dx < -2 && details.localPosition.dx < -85 && !_dragCancel) {
      HapticFeedback.selectionClick();
      setState(() => _dragCancel = true);
    }
  }

  Future<void> _onDragEnd(DragEndDetails details) async {
    if (_dragCancel) {
      await _cancel();
      return;
    }
    // If the finger was released after sliding up, keep the recorder locked;
    // otherwise send the voice message, matching the WhatsApp hold gesture.
    if (!_locked) await _send();
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
          Expanded(child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13))),
          IconButton(onPressed: widget.onCancel, icon: Icon(LucideIcons.x, color: AppColors.textSecondary, size: 20)),
        ],
      );
    }
    return GestureDetector(
      onHorizontalDragUpdate: _locked ? null : _onDragUpdate,
      onVerticalDragUpdate: _locked ? null : _onDragUpdate,
      onHorizontalDragEnd: _locked ? null : _onDragEnd,
      onVerticalDragEnd: _locked ? null : _onDragEnd,
      child: Row(
        children: [
          IconButton(
            tooltip: 'Нест кардани сабт',
            onPressed: _starting ? null : _cancel,
            icon: const Icon(LucideIcons.trash, color: Colors.redAccent, size: 20),
          ),
          Container(
            width: 9, height: 9,
            decoration: BoxDecoration(color: _paused ? AppColors.textSecondary : Colors.redAccent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(MediaService.formatDuration(_elapsed),
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontFeatures: const [FontFeature.tabularFigures()])),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_locked ? LucideIcons.lock : LucideIcons.mic, size: 15, color: AppColors.neonCyan),
                    const SizedBox(width: 6),
                    Expanded(child: Text(
                      _locked ? 'Сабт қулф шуд' : _dragCancel ? 'Барои бекор кардан раҳо кунед' : '↑ Қулф кунед   ← Бекор кунед',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _dragCancel ? Colors.redAccent : AppColors.textSecondary, fontSize: 11),
                    )),
                  ],
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 20,
                  child: Row(
                    children: List.generate(22, (i) {
                      final v = _samples.isEmpty ? 0.25 : _samples[_samples.length * i ~/ 22].clamp(0.08, 1.0);
                      return Expanded(child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        height: 5 + v * 15,
                        decoration: BoxDecoration(
                          color: _paused ? AppColors.textSecondary : AppColors.neonCyan.withValues(alpha: 0.45 + v * 0.5),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ));
                    }),
                  ),
                ),
              ],
            ),
          ),
          if (_locked) ...[
            IconButton(tooltip: _paused ? 'Давом додан' : 'Таваққуф', onPressed: _togglePause,
              icon: Icon(_paused ? LucideIcons.play : LucideIcons.pause, color: AppColors.textPrimary)),
            IconButton.filled(
              tooltip: 'Фиристодан',
              onPressed: _starting || _isSending ? null : _send,
              style: IconButton.styleFrom(backgroundColor: AppColors.neonCyan, foregroundColor: AppColors.background),
              icon: const Icon(LucideIcons.send),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(LucideIcons.chevrons_up, color: _dragCancel ? Colors.redAccent : AppColors.neonCyan, size: 23),
            ),
        ],
      ),
    );
  }
}
