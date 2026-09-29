import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config/otp_server_config.dart';
import '../l10n/l10n.dart';

/// Тарҷумаи матни паём.
///
/// Тарҷумонро сервер даъват мекунад: калиди хидмат дар барнома намемонад ва
/// натиҷа барои ҳама кэш мешавад.
class TranslateService {
  /// Кэши хотира — ҳамон паёмро дубора тарҷума кардан лозим нест.
  static final Map<String, String> _cache = {};

  /// Матни тарҷумашуда.
  ///
  /// Хато мепартояд, агар тарҷума нашавад — матни аслиро ҳамчун «тарҷума»
  /// баргардонидан корбарро фиреб медиҳад.
  static Future<String> translate(String text, {String? target}) async {
    final language = target ?? L10n.language.code;
    final key = '$language|$text';
    final cached = _cache[key];
    if (cached != null) return cached;

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
            body: jsonEncode({'text': text, 'target': language}),
          )
          .timeout(const Duration(seconds: 20));
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

    _cache[key] = translated;
    return translated;
  }
}

enum TranslateFailureKind { notSignedIn, network, notConfigured, failed }

class TranslateFailure implements Exception {
  final TranslateFailureKind kind;
  const TranslateFailure(this.kind);

  /// Матни фаҳмо барои корбар.
  String get message => switch (kind) {
        TranslateFailureKind.notSignedIn => tr('k366'),
        TranslateFailureKind.network => tr('k367'),
        TranslateFailureKind.notConfigured => tr('k486'),
        TranslateFailureKind.failed => tr('k487'),
      };

  @override
  String toString() => 'TranslateFailure(${kind.name})';
}
