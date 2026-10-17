import 'dart:convert';

import 'package:http/http.dart' as http;

/// Ҷустуҷӯи мустақими веб аз телефони корбар.
/// Калиди API ва дархост ба сервери Render лозим нест.
/// Аввал DuckDuckGo HTML; агар натиҷа наояд, Wikipedia Search API.
class ChatAiSearchService {
  ChatAiSearchService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static final RegExp _intent = RegExp(
    r'(ҷустуҷӯ|ҷустуҷӯ кун|аз интернет|дар интернет|аз гугл|гуглда|google|search (?:the )?web|search online|look up|find online|интернетда ёб|найди в интернете|поиск в интернете|поищи)',
    caseSensitive: false,
  );

  static bool isSearchQuestion(String prompt) => _intent.hasMatch(prompt);

  /// Барои саволҳои одӣ null; барои дархости ҷустуҷӯ ҷавоб бо истинод.
  Future<String?> answerIfSearch(String prompt) async {
    if (!isSearchQuestion(prompt)) return null;
    final query = _extractQuery(prompt);
    if (query.isEmpty) return _localized(
      prompt,
      'Чиро дар интернет ҷустуҷӯ кунам? Савол ё мавзӯъро навис.',
      'Что искать в интернете? Напишите вопрос или тему.',
      'What should I search for? Enter a question or topic.',
    );

    try {
      final results = await _searchDuckDuckGo(query);
      if (results.isNotEmpty) return _formatResults(query, results, prompt, 'DuckDuckGo');
    } catch (_) {
      // Ҷустуҷӯи асосӣ дастнорас аст: ба манбаи эҳтиётӣ мегузарем.
    }

    try {
      final results = await _searchWikipedia(query);
      if (results.isNotEmpty) return _formatResults(query, results, prompt, 'Wikipedia');
    } catch (_) {
      // Ҳар ду манбаъ дастнорасанд; ба корбар ошкоро хабар медиҳем.
    }

    return _localized(
      prompt,
      'Ҳоло натиҷаҳои интернет дастрас нестанд. Баъдтар боз кӯшиш кун.',
      'Сейчас результаты поиска недоступны. Попробуйте позже.',
      'Online search is unavailable right now. Please try again later.',
    );
  }

  static String _extractQuery(String prompt) {
    var query = prompt.trim();
    query = query.replaceFirst(
      RegExp(
        r'^(?:лутфан\s+)?(?:дар интернет\s+)?(?:ҷустуҷӯ(?:\s+кун)?|аз интернет ёб|аз гугл ёб|гуглда ёб|интернетда ёб|search (?:the )?web for|search online for|look up|find online|найди в интернете|поищи|поиск в интернете)\s*[:,-]?\s*',
        caseSensitive: false,
      ),
      '',
    );
    query = query.replaceAll(RegExp(r'\s+'), ' ').trim();
    return query.length > 180 ? query.substring(0, 180) : query;
  }

  Future<List<ChatAiWebResult>> _searchDuckDuckGo(String query) async {
    final uri = Uri.https('html.duckduckgo.com', '/html/', {'q': query});
    final response = await _client.get(uri, headers: {
      'User-Agent': 'Mozilla/5.0 (compatible; ChatAppMessenger/1.0)',
      'Accept': 'text/html',
    }).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return const [];

    final html = response.body;
    final anchors = RegExp(
      r'<a\b([^>]*\bclass=["\x27][^"\x27]*\bresult__a\b[^"\x27]*["\x27][^>]*)>(.*?)</a>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(html);
    final snippets = RegExp(
      r'<(?:a|div)\b[^>]*\bclass=["\x27][^"\x27]*\bresult__snippet\b[^"\x27]*["\x27][^>]*>(.*?)</(?:a|div)>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(html).map((m) => _cleanHtml(m.group(1) ?? '')).toList();

    final results = <ChatAiWebResult>[];
    for (final match in anchors) {
      final attrs = match.group(1) ?? '';
      final hrefMatch = RegExp(r'\bhref=["\x27]([^"\x27]+)["\x27]', caseSensitive: false).firstMatch(attrs);
      if (hrefMatch == null) continue;
      final title = _cleanHtml(match.group(2) ?? '');
      final url = _unwrapDuckDuckGoUrl(_decodeEntities(hrefMatch.group(1) ?? ''));
      if (title.isEmpty || !url.startsWith('http')) continue;
      if (results.any((r) => r.url == url)) continue;
      final index = results.length;
      results.add(ChatAiWebResult(
        title: title,
        url: url,
        snippet: index < snippets.length ? snippets[index] : '',
      ));
      if (results.length == 5) break;
    }
    return results;
  }

  Future<List<ChatAiWebResult>> _searchWikipedia(String query) async {
    final uri = Uri.https('en.wikipedia.org', '/w/api.php', {
      'action': 'query',
      'list': 'search',
      'srsearch': query,
      'format': 'json',
      'utf8': '1',
      'srlimit': '5',
    });
    final response = await _client.get(uri, headers: {
      'User-Agent': 'ChatAppMessenger/1.0 (web search fallback)',
      'Accept': 'application/json',
    }).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return const [];
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return const [];
    final queryData = decoded['query'];
    if (queryData is! Map<String, dynamic> || queryData['search'] is! List) {
      return const [];
    }
    final results = <ChatAiWebResult>[];
    for (final item in queryData['search'] as List) {
      if (item is! Map<String, dynamic>) continue;
      final title = (item['title'] ?? '').toString().trim();
      if (title.isEmpty) continue;
      final slug = title.replaceAll(' ', '_');
      results.add(ChatAiWebResult(
        title: title,
        url: 'https://en.wikipedia.org/wiki/${Uri.encodeComponent(slug).replaceAll('%2F', '/')}',
        snippet: _cleanHtml((item['snippet'] ?? '').toString()),
      ));
    }
    return results;
  }

  static String _formatResults(
    String query,
    List<ChatAiWebResult> results,
    String prompt,
    String source,
  ) {
    final buffer = StringBuffer()
      ..writeln(_localized(
        prompt,
        'Натиҷаҳои ҷустуҷӯ барои «$query» (манбаъ: $source):',
        'Результаты поиска по запросу «$query» (источник: $source):',
        'Search results for “$query” (source: $source):',
      ));
    for (var i = 0; i < results.length; i++) {
      final item = results[i];
      buffer
        ..writeln()
        ..writeln('${i + 1}. ${item.title}');
      if (item.snippet.isNotEmpty) buffer.writeln(item.snippet);
      buffer.writeln(item.url);
    }
    buffer.writeln(_localized(
      prompt,
      '\nИн истинодҳо натиҷаи ҷустуҷӯ мебошанд; пеш аз истифода маълумотро аз манбаъ санҷ.',
      '\nЭто результаты поиска; проверьте информацию в источнике перед использованием.',
      '\nThese are search results; verify details on the source pages before relying on them.',
    ));
    return buffer.toString().trim();
  }

  static String _localized(String prompt, String tj, String ru, String en) {
    if (RegExp(r'[ҒғҚқҲҳҶҷӢӣӮӯ]').hasMatch(prompt) ||
        RegExp(r'(ҷустуҷӯ|интернетда|гуглда|обу ҳаво)', caseSensitive: false).hasMatch(prompt)) {
      return tj;
    }
    if (RegExp(r'[А-Яа-яЁё]').hasMatch(prompt)) return ru;
    return en;
  }

  static String _unwrapDuckDuckGoUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final target = uri.queryParameters['uddg'];
      if (target != null && target.startsWith('http')) return target;
      if (url.startsWith('//')) return 'https:$url';
      return url;
    } catch (_) {
      return url;
    }
  }

  static String _cleanHtml(String value) =>
      _decodeEntities(value.replaceAll(RegExp(r'<[^>]*>'), ' '))
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

  static String _decodeEntities(String value) {
    return value
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ')
        .replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
          final code = int.tryParse(m.group(1) ?? '');
          return code == null ? m.group(0)! : String.fromCharCode(code);
        })
        .replaceAllMapped(RegExp(r'&#x([0-9a-f]+);', caseSensitive: false), (m) {
          final code = int.tryParse(m.group(1) ?? '', radix: 16);
          return code == null ? m.group(0)! : String.fromCharCode(code);
        });
  }
}

class ChatAiWebResult {
  final String title;
  final String url;
  final String snippet;

  const ChatAiWebResult({
    required this.title,
    required this.url,
    required this.snippet,
  });
}
