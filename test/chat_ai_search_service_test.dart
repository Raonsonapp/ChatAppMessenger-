import 'dart:convert';

import 'package:chatapp/services/chat_ai_search_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ChatAiSearchService intent detection', () {
    test('recognizes explicit Tajik web-search requests', () {
      expect(ChatAiSearchService.isSearchQuestion('Аз интернет дар бораи шоир ҷустуҷӯ кун'), isTrue);
      expect(ChatAiSearchService.isSearchQuestion('Гуглда ёб: таърихи Тоҷикистон'), isTrue);
      expect(ChatAiSearchService.isSearchQuestion('Интернетда ёб: достони Рӯдакӣ'), isTrue);
    });

    test('recognizes English and Russian web-search requests', () {
      expect(ChatAiSearchService.isSearchQuestion('Search the web for renewable energy'), isTrue);
      expect(ChatAiSearchService.isSearchQuestion('Найди в интернете историю Самарканда'), isTrue);
    });

    test('does not route ordinary questions to web search', () {
      expect(ChatAiSearchService.isSearchQuestion('Салом, аҳволат чӣ хел?'), isFalse);
      expect(ChatAiSearchService.isSearchQuestion('2 + 2 чанд мешавад?'), isFalse);
      expect(ChatAiSearchService.isSearchQuestion('Write me a short poem'), isFalse);
    });
  });

  group('ChatAiSearchService online routing', () {
    test('does not send ordinary AI questions to the network', () async {
      var requests = 0;
      final client = MockClient((request) async {
        requests++;
        return http.Response('', 200);
      });
      final service = ChatAiSearchService(client: client);

      expect(await service.answerIfSearch('Explain gravity simply'), isNull);
      expect(requests, 0);
      client.close();
    });

    test('uses DuckDuckGo results first and includes source links', () async {
      final client = MockClient((request) async {
        expect(request.url.host, 'html.duckduckgo.com');
        return http.Response(
          '<a class="result__a" href="https://example.com/page">Example title</a>'
          '<div class="result__snippet">Useful <b>summary</b></div>',
          200,
          headers: {'content-type': 'text/html; charset=utf-8'},
        );
      });
      final service = ChatAiSearchService(client: client);

      final answer = await service.answerIfSearch('search the web for example topic');

      expect(answer, isNotNull);
      expect(answer, contains('DuckDuckGo'));
      expect(answer, contains('Example title'));
      expect(answer, contains('Useful summary'));
      expect(answer, contains('https://example.com/page'));
      client.close();
    });

    test('falls back to Wikipedia when DuckDuckGo has no results', () async {
      var wikipediaCalled = false;
      final client = MockClient((request) async {
        if (request.url.host == 'html.duckduckgo.com') {
          return http.Response('<html><body>No results</body></html>', 200);
        }
        if (request.url.host == 'en.wikipedia.org') {
          wikipediaCalled = true;
          return http.Response(
            jsonEncode({
              'query': {
                'search': [
                  {'title': 'Dushanbe', 'snippet': 'Capital city of Tajikistan'}
                ]
              }
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('', 500);
      });
      final service = ChatAiSearchService(client: client);

      final answer = await service.answerIfSearch('ҷустуҷӯ кун Dushanbe');

      expect(wikipediaCalled, isTrue);
      expect(answer, contains('Wikipedia'));
      expect(answer, contains('Dushanbe'));
      expect(answer, contains('https://en.wikipedia.org/wiki/Dushanbe'));
      client.close();
    });

    test('asks for a topic when the search query is empty', () async {
      var requests = 0;
      final client = MockClient((request) async {
        requests++;
        return http.Response('', 500);
      });
      final service = ChatAiSearchService(client: client);

      final answer = await service.answerIfSearch('ҷустуҷӯ кун');

      expect(answer, contains('Чиро дар интернет ҷустуҷӯ кунам?'));
      expect(requests, 0);
      client.close();
    });

    test('reports when both online providers are unavailable', () async {
      final client = MockClient((request) async => http.Response('', 503));
      final service = ChatAiSearchService(client: client);

      final answer = await service.answerIfSearch('search online for a topic');

      expect(answer, contains('Online search is unavailable'));
      client.close();
    });
  });
}
