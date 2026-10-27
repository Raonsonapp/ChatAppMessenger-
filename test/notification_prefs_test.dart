import 'package:chatapp/services/notification_prefs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('incoming call sound and vibration default to enabled', () async {
    expect(await NotificationPrefs.read('callSound'), isTrue);
    expect(await NotificationPrefs.read('callVibration'), isTrue);
  });

  test('incoming call preferences persist independently', () async {
    await NotificationPrefs.save('callSound', false);
    await NotificationPrefs.save('callVibration', true);
    await NotificationPrefs.save('notificationSound', false);

    expect(await NotificationPrefs.read('callSound'), isFalse);
    expect(await NotificationPrefs.read('callVibration'), isTrue);
    expect(await NotificationPrefs.read('notificationSound'), isFalse);
  });
}
