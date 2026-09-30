import 'dart:math' as math;

/// Мавҷи садо — қиматҳои воқеии баландии овоз, на бандҳои тасодуфӣ.
///
/// Амплитуда ҳангоми САБТ аз худи микрофон гирифта мешавад (`record` пакет) ва
/// бо паём нигоҳ дошта мешавад. Гиранда ҳамон қиматҳоро мекашад.
///
/// Тарзи дигар — декоди файли садо дар телефони гиранда — вазнин аст ва
/// кашидани бандҳои ТАСОДУФӢ фиреб мебуд: корбар қуллаҳоеро мебинад, ки ба
/// садо ҳељ рабте надоранд.
class Waveform {
  Waveform._();

  /// Чанд банд нигоҳ дошта мешавад.
  ///
  /// 40 банд барои хати чат кофист ва дар ҳуҷҷат камтар аз 100 байт мегирад.
  static const int bars = 40;

  /// Амплитудаи `record` дар дБ аст ва манфӣ (аз тақрибан -45 то 0).
  static const double _minDb = -45;

  /// Як қимати дБ-ро ба 0…1 табдил медиҳад.
  static double normalize(double db) {
    if (db.isNaN || db.isInfinite) return 0;
    final clamped = db.clamp(_minDb, 0.0);
    return (clamped - _minDb) / -_minDb;
  }

  /// Намунаҳоро ба маҷмӯаи ниҳоии `bars` банд табдил медиҳад.
  ///
  /// Намунаҳо метавонанд аз `bars` зиёд ё кам бошанд — сабт метавонад 2 сония ё
  /// 2 дақиқа давом кунад. Дар ҳарду ҳолат натиҷа ҳамон дарозӣ дорад.
  ///
  /// Ҳар банд ҳамчун адади 0…100 бармегардад, то дар Firestore ҷои кам гирад.
  static List<int> compress(List<double> samples, {int bars = Waveform.bars}) {
    if (bars <= 0) return const [];
    if (samples.isEmpty) return List<int>.filled(bars, 0);

    final result = <int>[];
    for (var i = 0; i < bars; i++) {
      final start = (i * samples.length / bars).floor();
      final end = math.max(start + 1, ((i + 1) * samples.length / bars).floor());
      var peak = 0.0;
      for (var j = start; j < end && j < samples.length; j++) {
        if (samples[j] > peak) peak = samples[j];
      }
      result.add((peak.clamp(0.0, 1.0) * 100).round());
    }
    return result;
  }

  /// Бандҳои хондашуда аз ҳуҷҷат ба 0…1.
  ///
  /// Маълумоти нодуруст (сатр, null, рақами берун аз ҳудуд) партофта мешавад —
  /// паёми як корбар набояд экрани дигаронро вайрон кунад.
  static List<double> parse(Object? raw) {
    if (raw is! List) return const [];
    final values = <double>[];
    for (final item in raw) {
      if (item is! num) continue;
      values.add((item / 100).clamp(0.0, 1.0));
    }
    return values;
  }

  /// Барои кашидан: банди хеле хурд низ бояд дида шавад, вагарна хати садо
  /// ҷойҳои холӣ пайдо мекунад.
  static double displayHeight(double value) => 0.12 + value * 0.88;
}
