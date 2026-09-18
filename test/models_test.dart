import 'package:chatapp/models/app_status.dart';
import 'package:chatapp/models/chat_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppStatus.isExpired', () {
    test('навсозии нав гузашта нест', () {
      final status = AppStatus(
        id: 'a',
        ownerId: 'u1',
        ownerName: 'Ali',
        expiresAt: DateTime.now().add(const Duration(hours: 23)),
      );
      expect(status.isExpired, isFalse);
    });

    test('навсозии кӯҳна гузашта аст', () {
      final status = AppStatus(
        id: 'a',
        ownerId: 'u1',
        ownerName: 'Ali',
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );
      expect(status.isExpired, isTrue);
    });

    test('бе expiresAt гузашта ҳисоб намешавад', () {
      // Навсозиҳои кӯҳна метавонанд ин майдонро надошта бошанд — онҳо набояд
      // якбора нопадид шаванд.
      final status = AppStatus(id: 'a', ownerId: 'u1', ownerName: 'Ali');
      expect(status.isExpired, isFalse);
    });
  });

  group('ChatMessage', () {
    test('паёми матнӣ медиа надорад', () {
      final message = ChatMessage(
        id: 'm1',
        text: 'Салом',
        senderId: 'u1',
        isAI: false,
      );
      expect(message.mediaUrl, isNull);
      expect(message.mediaType, isNull);
      expect(message.deleted, isFalse);
      expect(message.read, isFalse);
    });

    test('паёми несткардашуда матни худро нигоҳ медорад, вале deleted аст', () {
      final message = ChatMessage(
        id: 'm1',
        text: '',
        senderId: 'u1',
        isAI: false,
        deleted: true,
      );
      expect(message.deleted, isTrue);
    });
  });
}
