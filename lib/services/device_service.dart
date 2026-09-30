import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Сабти дастгоҳҳое ки ба ҳисоб пайваст шудаанд.
///
/// Маълумот воқеӣ аст: ҳар дастгоҳ ҳангоми сабти токени FCM худро дар
/// `users/{uid}/devices/{id}` менависад. Экрани «Дастгоҳҳои пайваст» ҳамин
/// ҳуҷҷатҳоро нишон медиҳад — ҳеҷ чизи сохта нест.
class LinkedDevice {
  const LinkedDevice({
    required this.id,
    required this.platform,
    required this.osVersion,
    required this.lastActive,
    required this.isCurrent,
  });

  final String id;
  final String platform;
  final String osVersion;
  final DateTime? lastActive;
  final bool isCurrent;

  /// Номи хондашаванда: «Android 13 (API 33)» ё «iOS 17.2».
  String get label {
    final os = osVersion.trim();
    if (os.isEmpty) return platform;
    // Дар Android `operatingSystemVersion` аллакай калимаи «Android»-ро дорад.
    if (os.toLowerCase().contains(platform.toLowerCase())) return os;
    return '$platform $os';
  }
}

class DeviceService {
  DeviceService._();

  static const int _maxOsVersionChars = 80;

  /// Хэши устувори FNV-1a (64-бит) — ҳамчун ID-и ҳуҷҷат.
  ///
  /// `String.hashCode` дар Dart байни иҷроҳо кафолат дода нашудааст, бинобар ин
  /// хэши худамонро менависем: ҳамон токен ҳамеша ҳамон ID медиҳад ва токени
  /// пурра (ки маълумоти ҳассос аст) ҳамчун ID дар Firestore намемонад.
  static String fingerprint(String token) {
    var hash = BigInt.parse('14695981039346656037');
    final mask = (BigInt.one << 64) - BigInt.one;
    final prime = BigInt.parse('1099511628211');
    for (final byte in token.codeUnits) {
      hash = (hash ^ BigInt.from(byte & 0xFF)) & mask;
      hash = (hash * prime) & mask;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }

  static String get _platform {
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }

  static String get _osVersion {
    try {
      final raw = Platform.operatingSystemVersion.trim();
      return raw.length > _maxOsVersionChars ? raw.substring(0, _maxOsVersionChars) : raw;
    } catch (_) {
      return '';
    }
  }

  static DocumentReference<Map<String, dynamic>> _ref(String uid, String id) =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('devices').doc(id);

  /// Дастгоҳи ҷориро сабт мекунад ё вақти фаъолияташро нав мекунад.
  static Future<void> register(String uid, String token) async {
    try {
      await _ref(uid, fingerprint(token)).set({
        'platform': _platform,
        'osVersion': _osVersion,
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Сабти дастгоҳ хизмати иловагӣ аст — набояд вуруд ё огоҳиҳоро вайрон кунад.
    }
  }

  /// Ҳангоми баромадан сабти дастгоҳро мебарорад.
  static Future<void> unregister(String uid, String token) async {
    try {
      await _ref(uid, fingerprint(token)).delete();
    } catch (_) {}
  }

  /// Дастгоҳи дигарро ҷудо мекунад: сабт нест мешавад ва токенаш аз рӯйхати
  /// FCM бароварда мешавад, то ба он дастгоҳ дигар огоҳӣ нарасад.
  static Future<void> unlink(String uid, LinkedDevice device) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final snap = await userRef.get();
    final tokens = (snap.data()?['fcmTokens'] as List?)?.whereType<String>().toList() ?? const <String>[];
    final match = tokens.where((t) => fingerprint(t) == device.id).toList();

    final batch = FirebaseFirestore.instance.batch();
    batch.delete(_ref(uid, device.id));
    if (match.isNotEmpty) {
      batch.set(userRef, {'fcmTokens': FieldValue.arrayRemove(match)}, SetOptions(merge: true));
    }
    await batch.commit();
  }

  static Stream<List<LinkedDevice>> watch(String uid, {String? currentToken}) {
    final currentId = currentToken == null ? null : fingerprint(currentToken);
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('devices')
        .snapshots()
        .map((snap) {
      final devices = snap.docs.map((doc) {
        final data = doc.data();
        return LinkedDevice(
          id: doc.id,
          platform: (data['platform'] as String?) ?? 'Unknown',
          osVersion: (data['osVersion'] as String?) ?? '',
          lastActive: (data['lastActive'] as Timestamp?)?.toDate(),
          isCurrent: doc.id == currentId,
        );
      }).toList();
      // Дастгоҳи ҷорӣ дар боло, баъд аз рӯи фаъолияти охирин.
      devices.sort((a, b) {
        if (a.isCurrent != b.isCurrent) return a.isCurrent ? -1 : 1;
        final at = a.lastActive, bt = b.lastActive;
        if (at == null && bt == null) return 0;
        if (at == null) return 1;
        if (bt == null) return -1;
        return bt.compareTo(at);
      });
      return devices;
    });
  }

  static String? get currentUid => FirebaseAuth.instance.currentUser?.uid;
}
