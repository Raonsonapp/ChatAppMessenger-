import 'package:agora_rtc_engine/agora_rtc_engine.dart';

import 'media_settings_controller.dart';

/// Танзими рамзгузори видеои занг.
///
/// Агора бе ин ҳамеша профили пешфарзро мегирад. Ҳангоми «Сарфаи трафик» ё
/// сифати сарфакор видеоро хурдтар мефиристем: дар интернети сути мобилӣ
/// видеои 640×360 воқеан мегузарад, дар ҳоле ки 960×540 канда мешавад.
class CallVideoProfile {
  CallVideoProfile._();

  static VideoEncoderConfiguration forCurrentSettings() {
    final low = mediaSettings.dataSaver || mediaSettings.quality == MediaQuality.saver;
    if (low) {
      return const VideoEncoderConfiguration(
        dimensions: VideoDimensions(width: 640, height: 360),
        frameRate: 15,
        bitrate: 500,
        degradationPreference: DegradationPreference.maintainFramerate,
      );
    }
    return const VideoEncoderConfiguration(
      dimensions: VideoDimensions(width: 960, height: 540),
      frameRate: 24,
      bitrate: 1200,
      degradationPreference: DegradationPreference.maintainQuality,
    );
  }

  /// Профилро ба муҳаррик медиҳад. Хатои он набояд зангро вайрон кунад —
  /// занги бе профил аз занги набуда беҳтар аст.
  static Future<void> apply(RtcEngine engine) async {
    try {
      await engine.setVideoEncoderConfiguration(forCurrentSettings());
    } catch (_) {}
  }
}
