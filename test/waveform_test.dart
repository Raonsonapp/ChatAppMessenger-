import 'package:chatapp/utils/waveform.dart';
import 'package:flutter_test/flutter_test.dart';

/// Мавҷи садо аз амплитудаи ВОҚЕИИ микрофон сохта мешавад.
///
/// Санҷиши асосӣ: дарозии натиҷа ҳамеша якхела аст, ҳарчанд сабт 2 сония ё
/// 2 дақиқа бошад — вагарна хати садо дар чат андозаи гуногун мегирифт.
void main() {
  group('normalize', () {
    test('хомӯшӣ ба сифр, баландии пурра ба як', () {
      expect(Waveform.normalize(-45), 0);
      expect(Waveform.normalize(0), 1);
    });

    test('қимати аз ҳудуд берун маҳдуд мешавад', () {
      expect(Waveform.normalize(-100), 0);
      expect(Waveform.normalize(10), 1);
    });

    test('NaN ва беохир барномаро вайрон намекунанд', () {
      expect(Waveform.normalize(double.nan), 0);
      expect(Waveform.normalize(double.negativeInfinity), 0);
      expect(Waveform.normalize(double.infinity), 0);
    });

    test('миёна тақрибан дар мобайн', () {
      expect(Waveform.normalize(-22.5), closeTo(0.5, 0.01));
    });
  });

  group('compress', () {
    test('дарозӣ ҳамеша ба bars баробар аст', () {
      for (final count in [1, 5, 40, 137, 5000]) {
        final samples = List<double>.generate(count, (i) => (i % 10) / 10);
        expect(Waveform.compress(samples).length, Waveform.bars, reason: 'намунаҳо: $count');
      }
    });

    test('намунаҳои холӣ сифрҳо медиҳанд', () {
      final result = Waveform.compress(const []);
      expect(result.length, Waveform.bars);
      expect(result.every((v) => v == 0), isTrue);
    });

    test('қулла нигоҳ дошта мешавад, на миёна', () {
      // Дар ҳар гурӯҳ як қуллаи баланд ҳаст — он бояд дида шавад, вагарна
      // овози баланд ҳамчун хомӯшӣ менамуд.
      final samples = List<double>.filled(80, 0.0);
      samples[0] = 1.0;
      final result = Waveform.compress(samples, bars: 2);
      expect(result.first, 100);
      expect(result.last, 0);
    });

    test('натиҷа дар ҳудуди 0…100 аст', () {
      final samples = [-5.0, 0.0, 0.5, 1.0, 9.0];
      for (final value in Waveform.compress(samples)) {
        expect(value, inInclusiveRange(0, 100));
      }
    });

    test('bars-и сифр рӯйхати холӣ медиҳад', () {
      expect(Waveform.compress(const [0.5], bars: 0), isEmpty);
    });
  });

  group('parse', () {
    test('рӯйхати адад хонда мешавад', () {
      expect(Waveform.parse([0, 50, 100]), [0, 0.5, 1]);
    });

    test('маълумоти нодуруст партофта мешавад', () {
      expect(Waveform.parse(null), isEmpty);
      expect(Waveform.parse('салом'), isEmpty);
      expect(Waveform.parse(42), isEmpty);
      // Элементҳои нодуруст партофта мешаванд, дурустҳо мемонанд.
      expect(Waveform.parse([50, 'x', null, 100]), [0.5, 1]);
    });

    test('қимати берун аз ҳудуд маҳдуд мешавад', () {
      expect(Waveform.parse([-20, 500]), [0, 1]);
    });
  });

  group('displayHeight', () {
    test('банди хомӯш низ дида мешавад', () {
      // Вагарна хати садо ҷойҳои холӣ пайдо мекард.
      expect(Waveform.displayHeight(0), greaterThan(0));
      expect(Waveform.displayHeight(1), 1);
    });
  });
}
