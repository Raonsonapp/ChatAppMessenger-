import 'package:chatapp/models/status_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Шакли статус ҳамчун се рақам дар Firestore мемонад.
///
/// Маҳз ҳамин ҷо хатари воқеӣ ҳаст: рақами кӯҳна, нодуруст ё берун аз ҳудуд
/// набояд экрани дидани статусро вайрон кунад — вагарна статуси як корбар
/// барномаро бо RangeError мекушад.
void main() {
  group('fromMap', () {
    test('маълумоти дуруст хонда мешавад', () {
      final style = StatusStyle.fromMap({
        'styleBackground': 3,
        'styleFont': 2,
        'styleAlign': 0,
      });
      expect(style.background, 3);
      expect(style.font, 2);
      expect(style.align, 0);
    });

    test('статуси кӯҳна бе шакл заминаи аввалро мегирад', () {
      final style = StatusStyle.fromMap({'text': 'салом'});
      expect(style.background, 0);
      expect(style.font, 0);
      // Ҷойгиршавии пешфарз — марказ, ҳамон тавре ки пештар буд.
      expect(style.align, 1);
    });

    test('рақами берун аз ҳудуд ба пешфарз бармегардад', () {
      final style = StatusStyle.fromMap({
        'styleBackground': 999,
        'styleFont': -1,
        'styleAlign': 7,
      });
      expect(style.background, 0);
      expect(style.font, 0);
      expect(style.align, 1);
    });

    test('навъи нодуруст барномаро вайрон намекунад', () {
      final style = StatusStyle.fromMap({
        'styleBackground': 'сабз',
        'styleFont': null,
        'styleAlign': true,
      });
      expect(style.background, 0);
      expect(style.align, 1);
    });

    test('рақами каср ба адад табдил мешавад', () {
      final style = StatusStyle.fromMap({'styleBackground': 2.0});
      expect(style.background, 2);
    });
  });

  group('намуд', () {
    test('ҳар замина ду ранг дорад', () {
      for (final colors in StatusStyle.backgrounds) {
        expect(colors.length, 2);
      }
    });

    test('номи ҳарфҳо ба рӯйхати услубҳо мувофиқ аст', () {
      expect(StatusStyle.fontNames.length, StatusStyle.fonts.length);
    });

    test('матн дар заминаи равшан торик мешавад ва баръакс', () {
      // Заминаи 10 — қаймоқӣ (равшан), заминаи 1 — кабуди торик.
      const light = StatusStyle(background: 10);
      const dark = StatusStyle(background: 1);
      expect(light.textColor.computeLuminance(), lessThan(0.1));
      expect(dark.textColor, Colors.white);
    });

    test('ҳадди аққал як заминаи равшан ҳаст', () {
      // Бе ин мантиқи ранги матн ҳељ гоҳ кор намекунад ва коди мурда мемонад.
      final anyLight = StatusStyle.backgrounds.indexed.any((entry) {
        return StatusStyle(background: entry.$1).textColor != Colors.white;
      });
      expect(anyLight, isTrue);
    });

    test('матни дароз ҳарфи хурдтар мегирад', () {
      const style = StatusStyle();
      final short = style.fontSizeFor('Салом');
      final long = style.fontSizeFor('С' * 200);
      expect(long, lessThan(short));
    });

    test('ҷойгиршавӣ дуруст табдил мешавад', () {
      expect(const StatusStyle(align: 0).textAlign, TextAlign.left);
      expect(const StatusStyle(align: 1).textAlign, TextAlign.center);
      expect(const StatusStyle(align: 2).textAlign, TextAlign.right);
    });

    test('toMap ва fromMap як шаклро медиҳанд', () {
      const style = StatusStyle(background: 7, font: 3, align: 2);
      final restored = StatusStyle.fromMap(style.toMap());
      expect(restored.background, style.background);
      expect(restored.font, style.font);
      expect(restored.align, style.align);
    });
  });
}
