import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Сифати медиаи фиристодашаванда.
enum MediaQuality {
  /// Бе фишурдан — файл ҳамон тавре меравад, ки ҳаст.
  original,

  /// Стандартӣ: 1600 px, JPEG 80 — ҳамон тартиби пештара.
  standard,

  /// Сарфакор: 1024 px, JPEG 60 — барои интернети сует.
  saver,
}

/// Чӣ ҳангоми боркунии худкор бор шавад.
enum AutoDownloadLevel {
  none,
  photos,
  photosAudio,
  all,
}

/// Навъи шабакаи ҳозира. Ҳеҷ гумон нест — аз худи система гирифта мешавад.
enum NetworkKind { wifi, mobile, other }

/// Танзимоти маълумот ва медиа.
///
/// Дар SharedPreferences нигоҳ дошта мешавад: ин интихобҳо ба ҳамин дастгоҳ ва
/// ба тарифи ҳамин корбар тааллуқ доранд, на ба ҳисоб.
class MediaSettingsController extends ChangeNotifier {
  static const String _qualityKey = 'media_quality';
  static const String _wifiKey = 'auto_download_wifi';
  static const String _mobileKey = 'auto_download_mobile';
  static const String _saverKey = 'data_saver';

  MediaQuality _quality = MediaQuality.standard;
  AutoDownloadLevel _wifi = AutoDownloadLevel.all;
  AutoDownloadLevel _mobile = AutoDownloadLevel.photos;
  bool _dataSaver = false;
  NetworkKind _network = NetworkKind.other;

  MediaQuality get quality => _quality;
  AutoDownloadLevel get autoDownloadWifi => _wifi;
  AutoDownloadLevel get autoDownloadMobile => _mobile;
  bool get dataSaver => _dataSaver;
  NetworkKind get network => _network;

  StreamSubscription<List<ConnectivityResult>>? _networkSub;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _quality = _parseQuality(prefs.getString(_qualityKey));
    _wifi = _parseLevel(prefs.getString(_wifiKey), AutoDownloadLevel.all);
    _mobile = _parseLevel(prefs.getString(_mobileKey), AutoDownloadLevel.photos);
    _dataSaver = prefs.getBool(_saverKey) ?? false;
    await _watchNetwork();
  }

  Future<void> _watchNetwork() async {
    try {
      _network = _mapNetwork(await Connectivity().checkConnectivity());
      _networkSub?.cancel();
      _networkSub = Connectivity().onConnectivityChanged.listen((results) {
        final kind = _mapNetwork(results);
        if (kind == _network) return;
        _network = kind;
        notifyListeners();
      }, onError: (_) {});
    } catch (_) {
      // Дар платформае ки плагин дастгирӣ намешавад — «дигар» мемонад ва
      // қоидаи Wi-Fi истифода мешавад.
      _network = NetworkKind.other;
    }
  }

  static NetworkKind _mapNetwork(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet)) {
      return NetworkKind.wifi;
    }
    if (results.contains(ConnectivityResult.mobile)) return NetworkKind.mobile;
    return NetworkKind.other;
  }

  /// Дараҷаи боркунии худкор барои шабакаи ҳозира.
  ///
  /// Ҳангоми сарфаи трафик ҳеҷ чиз худкор бор намешавад — маҳз ҳамин маънои
  /// «сарфа» аст.
  AutoDownloadLevel get effectiveLevel {
    if (_dataSaver) return AutoDownloadLevel.none;
    return _network == NetworkKind.mobile ? _mobile : _wifi;
  }

  bool get allowsPhotoAutoDownload => effectiveLevel != AutoDownloadLevel.none;

  bool get allowsAudioAutoDownload => switch (effectiveLevel) {
        AutoDownloadLevel.photosAudio || AutoDownloadLevel.all => true,
        _ => false,
      };

  bool get allowsVideoAutoDownload => effectiveLevel == AutoDownloadLevel.all;

  /// Ҳадди калонии тарафи расм ҳангоми фиристодан.
  int get imageMaxSide => switch (_quality) {
        MediaQuality.original => 0, // 0 — бе тағйири андоза
        MediaQuality.standard => 1600,
        MediaQuality.saver => 1024,
      };

  int get imageQuality => switch (_quality) {
        MediaQuality.original => 100,
        MediaQuality.standard => 80,
        MediaQuality.saver => 60,
      };

  /// Ҳангоми сифати «аслӣ» расм тамоман фишурда намешавад.
  bool get skipImageCompression => _quality == MediaQuality.original;

  Future<void> setQuality(MediaQuality value) async {
    if (_quality == value) return;
    _quality = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_qualityKey, value.name);
  }

  Future<void> setAutoDownloadWifi(AutoDownloadLevel value) async {
    if (_wifi == value) return;
    _wifi = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_wifiKey, value.name);
  }

  Future<void> setAutoDownloadMobile(AutoDownloadLevel value) async {
    if (_mobile == value) return;
    _mobile = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mobileKey, value.name);
  }

  Future<void> setDataSaver(bool value) async {
    if (_dataSaver == value) return;
    _dataSaver = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_saverKey, value);
  }

  static MediaQuality _parseQuality(String? raw) {
    for (final value in MediaQuality.values) {
      if (value.name == raw) return value;
    }
    return MediaQuality.standard;
  }

  static AutoDownloadLevel _parseLevel(String? raw, AutoDownloadLevel fallback) {
    for (final value in AutoDownloadLevel.values) {
      if (value.name == raw) return value;
    }
    return fallback;
  }

  @override
  void dispose() {
    _networkSub?.cancel();
    super.dispose();
  }
}

/// Як нусха барои тамоми барнома.
final MediaSettingsController mediaSettings = MediaSettingsController();
