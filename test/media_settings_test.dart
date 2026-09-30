import 'package:chatapp/services/media_settings_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Қоидаҳои «Сарфаи трафик» ва «Боркунии худкор».
///
/// Ин ҷо маҳз мантиқи қарор санҷида мешавад, на SharedPreferences: агар
/// «сарфа» медиаро бор кунад, ваъдаи барнома дурӯғ мешавад.
void main() {
  // Танзимот дар SharedPreferences навишта мешавад — дар санҷиш нусхаи
  // хотиравӣ истифода мешавад.
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('Сифати медиа', () {
    test('аслӣ тамоман фишурда намешавад', () async {
      final settings = MediaSettingsController();
      await settings.setQuality(MediaQuality.original);
      expect(settings.skipImageCompression, isTrue);
      expect(settings.imageQuality, 100);
    });

    test('стандартӣ — 1600 px ва 80%', () async {
      final settings = MediaSettingsController();
      await settings.setQuality(MediaQuality.standard);
      expect(settings.skipImageCompression, isFalse);
      expect(settings.imageMaxSide, 1600);
      expect(settings.imageQuality, 80);
    });

    test('сарфакор аз стандартӣ хурдтар аст', () async {
      final saver = MediaSettingsController();
      await saver.setQuality(MediaQuality.saver);
      final standard = MediaSettingsController();
      await standard.setQuality(MediaQuality.standard);

      expect(saver.imageMaxSide, lessThan(standard.imageMaxSide));
      expect(saver.imageQuality, lessThan(standard.imageQuality));
    });
  });

  group('Боркунии худкор', () {
    test('«Сарфаи трафик» ҳамаро хомӯш мекунад', () async {
      final settings = MediaSettingsController();
      await settings.setAutoDownloadWifi(AutoDownloadLevel.all);
      await settings.setAutoDownloadMobile(AutoDownloadLevel.all);
      await settings.setDataSaver(true);

      expect(settings.effectiveLevel, AutoDownloadLevel.none);
      expect(settings.allowsPhotoAutoDownload, isFalse);
      expect(settings.allowsAudioAutoDownload, isFalse);
      expect(settings.allowsVideoAutoDownload, isFalse);
    });

    test('«Расмҳо» овоз ва видеоро бор намекунад', () async {
      final settings = MediaSettingsController();
      await settings.setAutoDownloadWifi(AutoDownloadLevel.photos);

      expect(settings.allowsPhotoAutoDownload, isTrue);
      expect(settings.allowsAudioAutoDownload, isFalse);
      expect(settings.allowsVideoAutoDownload, isFalse);
    });

    test('«Расм ва овоз» видеоро бор намекунад', () async {
      final settings = MediaSettingsController();
      await settings.setAutoDownloadWifi(AutoDownloadLevel.photosAudio);

      expect(settings.allowsPhotoAutoDownload, isTrue);
      expect(settings.allowsAudioAutoDownload, isTrue);
      expect(settings.allowsVideoAutoDownload, isFalse);
    });

    test('«Ҳама медиа» ҳамаро иҷозат медиҳад', () async {
      final settings = MediaSettingsController();
      await settings.setAutoDownloadWifi(AutoDownloadLevel.all);

      expect(settings.allowsPhotoAutoDownload, isTrue);
      expect(settings.allowsAudioAutoDownload, isTrue);
      expect(settings.allowsVideoAutoDownload, isTrue);
    });

    test('«Ҳеҷ чиз» ҳатто расмро бор намекунад', () async {
      final settings = MediaSettingsController();
      await settings.setAutoDownloadWifi(AutoDownloadLevel.none);
      expect(settings.allowsPhotoAutoDownload, isFalse);
    });

    test('пешфарз дар шабакаи номаълум қоидаи Wi-Fi аст', () {
      final settings = MediaSettingsController();
      // Бе `load()` шабака «дигар» мемонад — яъне маҳдудияти мобилӣ татбиқ
      // намешавад ва корбар аксҳои худро мебинад.
      expect(settings.network, NetworkKind.other);
      expect(settings.effectiveLevel, settings.autoDownloadWifi);
    });
  });
}
