import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';

/// Идоракунии муҳаррики Agora.
///
/// Муҳаррик дар тамоми барнома ЯКТОст: `createAgoraRtcEngine()` ҳамон
/// муҳаррики нативиро бармегардонад. Агар занги пештара онро озод накарда
/// бошад, занги нав хатои `-17` (ERR_JOIN_CHANNEL_REJECTED) мегирад — Agora
/// мегӯяд «корбар аллакай дар канал аст».
///
/// Маҳз ҳамин хатогӣ зангро баъд аз як-ду кӯшиш мешикаст: экрани занг
/// метавонад бе даъвати «қатъ кардан» пӯшида шавад (бозгашт, хато, ҷаҳиш ба
/// экрани дигар) ва он гоҳ муҳаррик зинда мемонд.
///
/// Ин ҷо ҲАМЕША пеш аз сохтани муҳаррики нав, кӯҳна озод карда мешавад.
class AgoraEngineManager {
  AgoraEngineManager._();

  static RtcEngine? _active;

  /// Озодкунии ҷорӣ. Сохтани муҳаррики нав интизори анҷоми он мешавад —
  /// вагарна ду амал бо ҳам бархӯрд мекунанд.
  static Future<void>? _disposing;

  /// Муҳаррики тайёр бармегардонад ва кӯҳнаро озод мекунад.
  static Future<RtcEngine> create(RtcEngineContext context) async {
    await disposeActive();

    final engine = createAgoraRtcEngine();
    _active = engine;
    await engine.initialize(context);
    return engine;
  }

  /// Муҳаррики ҷориро озод мекунад. Бехатар аст, ки чанд бор даъват шавад.
  static Future<void> disposeActive() async {
    // Агар озодкунӣ аллакай рафта истода бошад, интизор мешавем.
    final pending = _disposing;
    if (pending != null) {
      await pending;
      return;
    }

    final engine = _active;
    if (engine == null) return;

    _active = null;
    final future = _release(engine);
    _disposing = future;
    try {
      await future;
    } finally {
      _disposing = null;
    }
  }

  static Future<void> _release(RtcEngine engine) async {
    try {
      await engine.leaveChannel();
    } catch (_) {
      // Шояд аллакай берун аз канал бошад — ин хато нест.
    }
    try {
      // `sync: true` ҳатмист: бе он озодкунӣ дар паснамо мемонад ва
      // муҳаррики нав пеш аз анҷоми он сохта шуда, боз ҳамон хатои -17
      // мегирад.
      await engine.release(sync: true);
    } catch (error) {
      debugPrint('Озод кардани муҳаррики Agora нашуд: $error');
    }
  }

  /// Барои `dispose()`, ки интизор шуда наметавонад.
  ///
  /// Озодкунӣ дар паснамо давом мекунад, вале занги оянда интизори анҷоми
  /// он мешавад.
  static void disposeActiveUnawaited() {
    // ignore: discarded_futures — натиҷа дар `_disposing` нигоҳ дошта мешавад.
    disposeActive();
  }
}
