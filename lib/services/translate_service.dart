import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:http/http.dart' as http;

import '../config/otp_server_config.dart';
import '../l10n/l10n.dart';

/// Аввал тарҷумаи ройгони дохили телефон; агар забон дастгирӣ нашавад,
/// сервер Gemini-ро истифода мебарад (калид танҳо дар сервер мемонад).
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
      final translated = await _translateViaServer(text, targetCode);
      _cache[key] = translated;
      return translated;
    }

    final identifier = LanguageIdentifier(confidenceThreshold: 0.5);
    String detected;
    try {
      detected = await identifier.identifyLanguage(text);
    } finally {
      await identifier.close();
    }

    TranslateLanguage? sourceLanguage;
    for (final language in TranslateLanguage.values) {
      if (language.bcpCode == detected) {
        sourceLanguage = language;
        break;
      }
    }
    if (sourceLanguage == null) {
      final translated = await _translateViaServer(text, targetCode);
      _cache[key] = translated;
      return translated;
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
    } catch (_) {
      // Агар модели дохилӣ дар дастгоҳ кор накунад, сервер метавонад Gemini-ро истифода барад.
      final translated = await _translateViaServer(text, targetCode);
      _cache[key] = translated;
      return translated;
    } finally {
      translator.close();
    }
  }

  static Future<String> _translateViaServer(String text, String target) async {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (idToken == null) {
      throw const TranslateFailure(TranslateFailureKind.notSignedIn);
    }

    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('${OtpServerConfig.baseUrl}/api/translate'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({'text': text, 'target': target}),
          )
          .timeout(const Duration(seconds: 30));
    } catch (_) {
      throw const TranslateFailure(TranslateFailureKind.network);
    }

    if (response.statusCode == 503) {
      throw const TranslateFailure(TranslateFailureKind.notConfigured);
    }
    if (response.statusCode != 200) {
      throw const TranslateFailure(TranslateFailureKind.failed);
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final translated = data['text'] as String?;
    if (translated == null || translated.trim().isEmpty) {
      throw const TranslateFailure(TranslateFailureKind.failed);
    }
    return translated;
  }
}

enum TranslateFailureKind { notSignedIn, network, notConfigured, unsupportedLanguage, failed }

class TranslateFailure implements Exception {
  final TranslateFailureKind kind;
  const TranslateFailure(this.kind);

  String get message => switch (kind) {
        TranslateFailureKind.notSignedIn => tr('k366'),
        TranslateFailureKind.network => tr('k367'),
        TranslateFailureKind.notConfigured => tr('k486'),
        TranslateFailureKind.unsupportedLanguage => tr('k703'),
        TranslateFailureKind.failed => tr('k487'),
      };

  @override
  String toString() => 'TranslateFailure(${kind.name})';
}
