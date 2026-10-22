import 'package:chatapp/services/local_ai_chat_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('LocalAiChatStore', () {
    test('stores history locally and keeps users separate', () async {
      final store = LocalAiChatStore.instance;
      await store.add(uid: 'alice', text: 'Hello', senderId: 'alice', isAI: false);
      await store.add(uid: 'alice', text: 'Hi', senderId: 'ai_bot', isAI: true);

      expect((await store.load('alice')).map((message) => message.text), ['Hello', 'Hi']);
      expect(await store.load('bob'), isEmpty);
    });

    test('deletes one message and clears only the selected user history', () async {
      final store = LocalAiChatStore.instance;
      final first = await store.add(uid: 'alice', text: 'One', senderId: 'alice', isAI: false);
      await store.add(uid: 'alice', text: 'Two', senderId: 'alice', isAI: false);
      await store.add(uid: 'bob', text: 'Bob history', senderId: 'bob', isAI: false);

      await store.delete('alice', first.id);
      expect((await store.load('alice')).map((message) => message.text), ['Two']);

      await store.clear('alice');
      expect(await store.load('alice'), isEmpty);
      expect((await store.load('bob')).single.text, 'Bob history');
    });

    test('limits local history to maxMessages', () async {
      final store = LocalAiChatStore.instance;
      for (var i = 0; i < LocalAiChatStore.maxMessages + 1; i++) {
        await store.add(uid: 'alice', text: 'message-$i', senderId: 'alice', isAI: false);
      }

      final messages = await store.load('alice');
      expect(messages, hasLength(LocalAiChatStore.maxMessages));
      expect(messages.first.text, 'message-1');
      expect(messages.last.text, 'message-${LocalAiChatStore.maxMessages}');
    });

    test('records one-time legacy migration completion', () async {
      final store = LocalAiChatStore.instance;
      expect(await store.isLegacyMigrationComplete('alice'), isFalse);
      await store.migrateLegacyMessages('alice', []);
      expect(await store.isLegacyMigrationComplete('alice'), isTrue);
    });
  });
}
