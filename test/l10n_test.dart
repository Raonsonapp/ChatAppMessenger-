import 'package:chatapp/l10n/l10n.dart';
import 'package:chatapp/l10n/strings_en.dart';
import 'package:chatapp/l10n/strings_ru.dart';
import 'package:chatapp/l10n/strings_tj.dart';
import 'package:flutter_test/flutter_test.dart';

/// Се забон бояд якхела пурра бошанд.
///
/// Агар калид дар як забон илова шаваду дар дигараш не, барнома хомӯшона ба
/// тоҷикӣ бармегардад — корбари русзабон матни тоҷикиро мебинад ва инро ҳељ
/// кас пай намебарад. Ин санҷиш маҳз ҳамин ҳолатро мегирад.
void main() {
  group('Пуррагии тарҷумаҳо', () {
    test('калидҳои се забон бояд мувофиқ бошанд', () {
      final tj = stringsTj.keys.toSet();
      final ru = stringsRu.keys.toSet();
      final en = stringsEn.keys.toSet();

      expect(
        ru.difference(tj),
        isEmpty,
        reason: 'Дар русӣ ҳаст, вале дар тоҷикӣ нест',
      );
      expect(
        en.difference(tj),
        isEmpty,
        reason: 'Дар англисӣ ҳаст, вале дар тоҷикӣ нест',
      );
      expect(
        tj.difference(ru),
        isEmpty,
        reason: 'Тарҷумаи русӣ намерасад',
      );
      expect(
        tj.difference(en),
        isEmpty,
        reason: 'Тарҷумаи англисӣ намерасад',
      );
    });

    test('ҳељ матн холӣ набошад', () {
      for (final entry in {'tj': stringsTj, 'ru': stringsRu, 'en': stringsEn}.entries) {
        for (final pair in entry.value.entries) {
          expect(
            pair.value.trim(),
            isNotEmpty,
            reason: '${entry.key}/${pair.key} холӣ аст',
          );
        }
      }
    });

    test('ҷойгузорҳо дар ҳар се забон якхела бошанд', () {
      final placeholder = RegExp(r'\{\d+\}');

      for (final key in stringsTj.keys) {
        final expected = placeholder
            .allMatches(stringsTj[key]!)
            .map((m) => m.group(0)!)
            .toSet();

        for (final entry in {'ru': stringsRu, 'en': stringsEn}.entries) {
          final value = entry.value[key];
          if (value == null) continue;
          final actual =
              placeholder.allMatches(value).map((m) => m.group(0)!).toSet();
          expect(
            actual,
            expected,
            // Ҷойгузори гумшуда маънои онро дорад, ки ном ё рақам умуман
            // нишон дода намешавад — ин дар экран хеле намоён аст.
            reason: '${entry.key}/$key: ҷойгузорҳо мувофиқ нестанд',
          );
        }
      }
    });
  });

  group('tr ва trf', () {
    test('калиди номаълум худи калидро бармегардонад', () {
      expect(tr('key-that-does-not-exist'), 'key-that-does-not-exist');
    });

    test('ҳангоми набудани тарҷума ба тоҷикӣ бармегардад', () {
      L10n.language = AppLanguage.en;
      addTearDown(() => L10n.language = AppLanguage.tj);
      expect(tr('k002'), stringsEn['k002']);
    });

    test('trf ҷойгузорҳоро иваз мекунад', () {
      L10n.language = AppLanguage.tj;
      final key = stringsTj.entries
          .firstWhere((e) => e.value.contains('{0}'))
          .key;
      expect(trf(key, ['ЧИЗ']), contains('ЧИЗ'));
      expect(trf(key, ['ЧИЗ']), isNot(contains('{0}')));
    });
  });
}
