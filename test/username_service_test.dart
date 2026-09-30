import 'package:chatapp/services/username_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Санҷиши шакли `@username`.
///
/// Ягонагӣ дар Firestore таъмин мешавад, вале шакл дар барнома санҷида
/// мешавад — ва маҳз ҳамин ҷо хатоҳо пайдо мешаванд: `@` дучанд, фосила,
/// ҳарфи кирилликӣ, номи аз рақам сар шуда.
void main() {
  group('normalize', () {
    test('`@` ва фосилаҳоро мебарорад', () {
      expect(UsernameService.normalize('  @shahron  '), 'shahron');
      expect(UsernameService.normalize('@@shahron'), 'shahron');
    });

    test('калид ҳамеша хурдҳарф аст', () {
      expect(UsernameService.key('@ShahRON'), 'shahron');
      expect(UsernameService.key('shahron'), UsernameService.key('SHAHRON'));
    });
  });

  group('isValid', () {
    test('номҳои дуруст қабул мешаванд', () {
      for (final name in ['shahron', '@shahron', 'chat_app', 'user1234', 'a_b_c_d']) {
        expect(UsernameService.isValid(name), isTrue, reason: name);
      }
    });

    test('номи кӯтоҳ рад мешавад', () {
      expect(UsernameService.isValid('abc'), isFalse);
      expect(UsernameService.isValid('abcd'), isFalse);
      expect(UsernameService.isValid('abcde'), isTrue);
    });

    test('номи аз ҳад дароз рад мешавад', () {
      expect(UsernameService.isValid('a' * 32), isTrue);
      expect(UsernameService.isValid('a' * 33), isFalse);
    });

    test('ҳарфи аввал бояд ҳарф бошад — на рақам ва на _', () {
      expect(UsernameService.isValid('1shahron'), isFalse);
      expect(UsernameService.isValid('_shahron'), isFalse);
    });

    test('фосила, нуқта ва ҳарфи кирилликӣ рад мешаванд', () {
      for (final name in ['shah ron', 'shah.ron', 'шахрон', 'shah-ron', 'shah@ron']) {
        expect(UsernameService.isValid(name), isFalse, reason: name);
      }
    });

    test('номи холӣ рад мешавад', () {
      expect(UsernameService.isValid(''), isFalse);
      expect(UsernameService.isValid('@'), isFalse);
    });
  });
}
