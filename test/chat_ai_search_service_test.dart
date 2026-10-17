import 'package:flutter_test/flutter_test.dart';
import 'package:chatapp/services/chat_ai_search_service.dart';

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
}
