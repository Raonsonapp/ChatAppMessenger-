import 'package:chatapp/services/app_update_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppUpdateInfo', () {
    test('reads build number and APK from a GitHub release', () {
      final update = AppUpdateInfo.fromReleaseJson({
        'tag_name': 'chatapp-v1.0.2-build42',
        'html_url': 'https://github.com/Raonsonapp/ChatAppMessenger-/releases/tag/chatapp-v1.0.2-build42',
        'body': 'Automatic Android update.\n\nversionCode: 42',
        'assets': [
          {
            'name': 'ChatApp.apk',
            'browser_download_url': 'https://github.com/Raonsonapp/ChatAppMessenger-/releases/download/chatapp-v1.0.2-build42/ChatApp.apk',
          },
        ],
      });

      expect(update.versionCode, 42);
      expect(update.tagName, 'chatapp-v1.0.2-build42');
      expect(update.downloadUrl, endsWith('/ChatApp.apk'));
    });

    test('rejects a release without versionCode', () {
      expect(
        () => AppUpdateInfo.fromReleaseJson({
          'tag_name': 'v1.0.2',
          'body': 'No build metadata',
          'assets': [
            {
              'name': 'ChatApp.apk',
              'browser_download_url': 'https://github.com/Raonsonapp/ChatAppMessenger-/releases/download/v1.0.2/ChatApp.apk',
            },
          ],
        }),
        throwsFormatException,
      );
    });

    test('rejects APK URLs outside GitHub release hosts', () {
      expect(
        () => AppUpdateInfo.fromReleaseJson({
          'tag_name': 'v1.0.2',
          'body': 'versionCode: 42',
          'assets': [
            {
              'name': 'ChatApp.apk',
              'browser_download_url': 'https://evil.example/ChatApp.apk',
            },
          ],
        }),
        throwsFormatException,
      );
    });
  });
}
