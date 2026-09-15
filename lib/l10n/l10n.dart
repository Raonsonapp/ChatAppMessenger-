import 'strings_tj.dart';
import 'strings_ru.dart';
import 'strings_en.dart';

enum AppLanguage {
  tj('tj', 'Тоҷикӣ'),
  ru('ru', 'Русский'),
  en('en', 'English');

  final String code;
  final String label;
  const AppLanguage(this.code, this.label);

  static AppLanguage fromCode(String? code) {
    return AppLanguage.values.firstWhere(
      (l) => l.code == code,
      orElse: () => AppLanguage.tj,
    );
  }
}

class L10n {
  static AppLanguage language = AppLanguage.tj;

  static Map<String, String> get _active => switch (language) {
        AppLanguage.tj => stringsTj,
        AppLanguage.ru => stringsRu,
        AppLanguage.en => stringsEn,
      };
}

/// Матни тарҷумашуда. Агар дар забони фаъол набошад, ба тоҷикӣ бармегардад.
String tr(String key) => L10n._active[key] ?? stringsTj[key] ?? key;

/// Матни дорои ҷойгузор: `{0}`, `{1}` ва ғ.
String trf(String key, List<Object?> args) {
  var text = tr(key);
  for (var i = 0; i < args.length; i++) {
    text = text.replaceAll('{$i}', '${args[i]}');
  }
  return text;
}
