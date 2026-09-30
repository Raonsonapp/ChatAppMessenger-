import 'package:chatapp/services/device_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Хэши дастгоҳ бояд устувор бошад.
///
/// ID-и ҳуҷҷати дастгоҳ аз токени FCM сохта мешавад. Агар хэш байни иҷроҳо
/// тағйир ёбад, ҳар маротиба дастгоҳи «нав» пайдо мешавад ва рӯйхат бо
/// такрорҳо пур мешавад. Бинобар ин ҳамин сатрҳо махсус қулф карда шудаанд.
void main() {
  group('DeviceService.fingerprint', () {
    test('ҳамон токен ҳамон ID медиҳад', () {
      const token = 'fZ9k:APA91bHqExampleToken_1234567890';
      expect(DeviceService.fingerprint(token), DeviceService.fingerprint(token));
    });

    test('токенҳои гуногун ID-и гуногун медиҳанд', () {
      expect(
        DeviceService.fingerprint('token-a'),
        isNot(DeviceService.fingerprint('token-b')),
      );
    });

    test('дарозии ID ҳамеша 16 рақами шонздаҳӣ аст', () {
      for (final token in ['a', '', 'APA91bH' * 30, 'токен-тоҷикӣ']) {
        final id = DeviceService.fingerprint(token);
        expect(id.length, 16, reason: 'токен: $token');
        expect(RegExp(r'^[0-9a-f]{16}$').hasMatch(id), isTrue, reason: id);
      }
    });

    test('қимати FNV-1a барои сатри холӣ асоси устувор аст', () {
      // Қимати аслии offset basis-и FNV-1a — агар алгоритм тасодуфан иваз
      // шавад, ҳамин санҷиш онро мегирад.
      expect(DeviceService.fingerprint(''), 'cbf29ce484222325');
    });

    test('ID-и токен ҳарфи токенро ошкор намекунад', () {
      const token = 'secret-fcm-token-value';
      final id = DeviceService.fingerprint(token);
      expect(id.contains('secret'), isFalse);
      expect(token.contains(id), isFalse);
    });
  });

  group('LinkedDevice.label', () {
    test('нусхаи Android калимаи платформаро дубора такрор намекунад', () {
      const device = LinkedDevice(
        id: 'a',
        platform: 'Android',
        osVersion: 'Android 13 (API 33)',
        lastActive: null,
        isCurrent: true,
      );
      expect(device.label, 'Android 13 (API 33)');
    });

    test('агар нусха платформаро надошта бошад, он илова мешавад', () {
      const device = LinkedDevice(
        id: 'a',
        platform: 'iOS',
        osVersion: '17.2',
        lastActive: null,
        isCurrent: false,
      );
      expect(device.label, 'iOS 17.2');
    });

    test('нусхаи холӣ танҳо номи платформаро медиҳад', () {
      const device = LinkedDevice(
        id: 'a',
        platform: 'Android',
        osVersion: '   ',
        lastActive: null,
        isCurrent: false,
      );
      expect(device.label, 'Android');
    });
  });
}
