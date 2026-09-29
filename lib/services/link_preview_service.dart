import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config/otp_server_config.dart';

/// Пешнамоиши ҳавола.
class LinkPreview {
  final String url;
  final String? title;
  final String? description;
  final String? image;
  final String? siteName;

  const LinkPreview({
    required this.url,
    this.title,
    this.description,
    this.image,
    this.siteName,
  });

  bool get isUseful => (title ?? description ?? image) != null;

  factory LinkPreview.fromJson(Map<String, dynamic> json) => LinkPreview(
        url: (json['url'] ?? '') as String,
        title: json['title'] as String?,
        description: json['description'] as String?,
        image: json['image'] as String?,
        siteName: json['siteName'] as String?,
      );
}

/// Пешнамоишро аз сервер мегирад.
///
/// Сервер онро кэш мекунад, бинобар ин як ҳавола дар гурӯҳи калон бор-бор
/// кашида намешавад.
class LinkPreviewService {
  /// Ҳаволаҳои дар матн ёфтшуда.
  static final RegExp urlPattern = RegExp(
    r'(https?://[^\s<>"]+)|(\bwww\.[^\s<>"]+)',
    caseSensitive: false,
  );

  /// Аввалин ҳаволаи матн, ё `null`.
  static String? firstUrl(String text) {
    final match = urlPattern.firstMatch(text);
    if (match == null) return null;
    final raw = match.group(0)!;
    // Аломатҳои охири ҷумла набояд ба ҳавола дохил шаванд.
    final cleaned = raw.replaceFirst(RegExp(r'[.,;:!?)\]]+$'), '');
    return cleaned.startsWith('http') ? cleaned : 'https://$cleaned';
  }

  /// Кэши хотира — ҳангоми ҳар кашидани рӯйхат дархост такрор намешавад.
  static final Map<String, LinkPreview?> _cache = {};

  static Future<LinkPreview?> fetch(String url) async {
    if (_cache.containsKey(url)) return _cache[url];

    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (idToken == null) return null;

    try {
      final response = await http
          .post(
            Uri.parse('${OtpServerConfig.baseUrl}/api/link-preview'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({'url': url}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        _cache[url] = null;
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final raw = data['preview'];
      if (raw is! Map<String, dynamic>) {
        _cache[url] = null;
        return null;
      }

      final preview = LinkPreview.fromJson(raw);
      final result = preview.isUseful ? preview : null;
      _cache[url] = result;
      return result;
    } catch (_) {
      // Хатогӣ кэш КАРДА НАМЕШАВАД: шояд интернет лаҳзае набуд.
      return null;
    }
  }
}
