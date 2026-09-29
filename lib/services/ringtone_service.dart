import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

/// Садо ва ларзиши занги воридотӣ.
///
/// Талаби асосӣ: садо бояд ҲАТМАН қатъ шавад — ҳангоми қабул, рад, ҷавоб
/// надодан ё пӯшидани экран. Рингтони бандмонда аз набудани рингтон бадтар
/// аст, бинобар ин ҳар роҳи хуруҷ [stop]-ро даъват мекунад.
class RingtoneService {
  RingtoneService._();
  static final RingtoneService instance = RingtoneService._();

  AudioPlayer? _player;
  Timer? _autoStop;
  bool _vibrating = false;

  /// Занг пас аз ин муддат худаш хомӯш мешавад — ҳатто агар коде
  /// [stop]-ро даъват накунад.
  static const _maxDuration = Duration(seconds: 45);

  /// Оё ҳозир занг садо медиҳад?
  bool get isRinging => _player != null || _vibrating;

  /// Садо ва ларзишро оғоз мекунад.
  ///
  /// [withSound] ва [withVibration] аз танзимоти корбар меоянд.
  Future<void> start({
    bool withSound = true,
    bool withVibration = true,
  }) async {
    await stop();

    _autoStop = Timer(_maxDuration, stop);

    if (withVibration) {
      unawaited(_startVibration());
    }

    if (!withSound) return;

    try {
      final player = AudioPlayer();
      _player = player;
      // Режими занг: садо аз баландгӯяк меравад ва бо садоҳои дигар омехта
      // намешавад.
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(1);
      await player.play(AssetSource(_assetPath));
    } catch (_) {
      // Файли садо нест ё дастгоҳ иҷозат надод — ларзиш ба ҳар ҳол ҳаст.
      await _disposePlayer();
    }
  }

  static const _assetPath = 'sounds/ringtone.wav';

  Future<void> _startVibration() async {
    try {
      if (await Vibration.hasVibrator() != true) return;
      _vibrating = true;
      // Намунаи занг: 1 сония ларзиш, 1 сония таваққуф.
      Vibration.vibrate(
        pattern: const [0, 1000, 1000],
        repeat: 0,
      );
    } catch (_) {
      _vibrating = false;
    }
  }

  /// Ҳамаи садо ва ларзишро қатъ мекунад. Бехатар аст, ки чанд бор даъват
  /// шавад.
  Future<void> stop() async {
    _autoStop?.cancel();
    _autoStop = null;

    if (_vibrating) {
      _vibrating = false;
      try {
        await Vibration.cancel();
      } catch (_) {}
    }

    await _disposePlayer();
  }

  Future<void> _disposePlayer() async {
    final player = _player;
    _player = null;
    if (player == null) return;
    try {
      await player.stop();
    } catch (_) {}
    try {
      await player.dispose();
    } catch (_) {}
  }
}
