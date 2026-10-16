import 'package:google_mlkit_translation/google_mlkit_translation.dart';

import '../l10n/l10n.dart';

/// Тарҷумаи ройгони дохили телефон тавассути Google ML Kit.
class TranslateService {
  static final Map<String, String> _cache = {};

  static TranslateLanguage? _language(String code) => switch (code) {
        'en' => TranslateLanguage.english,
        'ru' => TranslateLanguage.russian,
        _ => null,
      };

  static Future<String> translate(String text, {String? target}) async {
    final targetCode = target ?? L10n.language.code;
    final key = '$targetCode|$text';
    final cached = _cache[key];
    if (cached != null) return cached;

    final targetLanguage = _language(targetCode);
    if (targetLanguage == null) {
      throw const TranslateFailure(TranslateFailureKind.unsupportedLanguage);
    }

    final identifier = OnDeviceLanguageIdentifier(confidenceThreshold: 0.5);
    TranslateLanguage sourceLanguage;
    try {
      final detected = await identifier.identifyLanguage(text);
      sourceLanguage = _language(detected ?? '') ?? TranslateLanguage.english;
    } finally {
      await identifier.close();
    }
    if (sourceLanguage == targetLanguage) return text;

    final manager = OnDeviceTranslatorModelManager();
    final translator = OnDeviceTranslator(
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
    );
    try {
      for (final language in [sourceLanguage.bcpCode, targetLanguage.bcpCode]) {
        if (!await manager.isModelDownloaded(language)) {
          await manager.downloadModel(language);
        }
      }
      final translated = await translator.translateText(text);
      if (translated.trim().isEmpty) {
        throw const TranslateFailure(TranslateFailureKind.failed);
      }
      _cache[key] = translated;
      return translated;
    } catch (error) {
      if (error is TranslateFailure) rethrow;
      throw const TranslateFailure(TranslateFailureKind.failed);
    } finally {
      translator.close();
    }
  }
}

enum TranslateFailureKind { unsupportedLanguage, failed }

class TranslateFailure implements Exception {
  final TranslateFailureKind kind;
  const TranslateFailure(this.kind);

  String get message => switch (kind) {
        TranslateFailureKind.unsupportedLanguage => tr('k703'),
        TranslateFailureKind.failed => tr('k487'),
      };

  @override
  String toString() => 'TranslateFailure(${kind.name})';
}
