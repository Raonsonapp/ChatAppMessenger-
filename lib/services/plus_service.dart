import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config/otp_server_config.dart';

/// Аз куҷо Plus омадааст.
enum PlusSource { owner, purchase, ownerGrant, trial, none }

/// Ҳолати ChatApp Plus-и корбар.
///
/// МУҲИМ: барнома ҳуқуқро НАМЕДИҲАД ва намесозад. Он танҳо майдони
/// `users/{uid}.plus`-ро мехонад, ки қоидаҳои Firestore барои барнома
/// хонданӣ кардаанд — онро танҳо сервер менависад. Ҳамин тавр `isPlus = true`
/// дар тарафи барнома ҳељ маъно надорад.
class PlusStatus {
  const PlusStatus({
    required this.active,
    required this.isOwner,
    required this.source,
    this.expiresAt,
    this.trialUsed = false,
  });

  final bool active;
  final bool isOwner;
  final PlusSource source;

  /// `null` — бе мӯҳлат (соҳиб ё lifetime).
  final DateTime? expiresAt;

  final bool trialUsed;

  static const PlusStatus none = PlusStatus(
    active: false,
    isOwner: false,
    source: PlusSource.none,
  );

  /// Оё синни озмоишӣ дархост шуданаш мумкин аст.
  ///
  /// Ин танҳо пешбинии интерфейс аст — қарори ниҳоӣ дар сервер гирифта мешавад.
  bool get canStartTrial => !active && !trialUsed && !isOwner;

  /// Ҳолат аз ҳуҷҷати корбар.
  ///
  /// `isOwner` ин ҷо ҳисоб КАРДА НАМЕШАВАД: соҳибро танҳо сервер медонад
  /// (`/api/plus/me`). Агар барнома онро худаш мешумурд, ҳар кас панели
  /// админро кушода метавонист.
  factory PlusStatus.fromUserDoc(Map<String, dynamic>? data, {bool isOwner = false}) {
    final raw = data?['plus'];
    if (raw is! Map) {
      return PlusStatus(active: isOwner, isOwner: isOwner, source: isOwner ? PlusSource.owner : PlusSource.none);
    }
    final expiresAt = _toDate(raw['expiresAt']);
    final active = raw['active'] == true &&
        (expiresAt == null || expiresAt.isAfter(DateTime.now()));
    return PlusStatus(
      active: isOwner || active,
      isOwner: isOwner,
      source: isOwner ? PlusSource.owner : _sourceOf(raw['source'] as String?),
      expiresAt: isOwner ? null : expiresAt,
      trialUsed: raw['trialUsed'] == true,
    );
  }

  factory PlusStatus.fromServer(Map<String, dynamic> json) {
    final millis = json['expiresAt'];
    return PlusStatus(
      active: json['active'] == true,
      isOwner: json['isOwner'] == true,
      source: _sourceOf(json['source'] as String?),
      expiresAt: millis is num ? DateTime.fromMillisecondsSinceEpoch(millis.toInt()) : null,
      trialUsed: json['trialUsed'] == true,
    );
  }

  static PlusSource _sourceOf(String? code) => switch (code) {
        'owner' => PlusSource.owner,
        'purchase' => PlusSource.purchase,
        'owner_grant' => PlusSource.ownerGrant,
        'trial' => PlusSource.trial,
        _ => PlusSource.none,
      };

  static DateTime? _toDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is num) return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    if (value is DateTime) return value;
    return null;
  }
}

/// Хатои амали Plus — то интерфейс сабаби аниқро нишон диҳад.
class PlusFailure implements Exception {
  const PlusFailure(this.code);
  final String code;
}

class PlusService {
  PlusService._();

  /// Мӯҳлатҳои гранти соҳиб — ҳамонҳое ки сервер қабул мекунад.
  static const List<String> grantDurations = ['7d', '30d', '1y', 'lifetime'];

  /// Ҷараёни ҳолати Plus аз ҳуҷҷати корбар.
  ///
  /// `isOwner` бояд аз `refresh()` гирифта шавад ва ин ҷо дода шавад — вагарна
  /// нишони соҳиб дар ҷараён намоён намешавад.
  static Stream<PlusStatus> watch(String uid, {bool isOwner = false}) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => PlusStatus.fromUserDoc(doc.data(), isOwner: isOwner));
  }

  /// Ҳолатро аз сервер мепурсад. Танҳо ҳамин роҳ мегӯяд, ки кӣ соҳиб аст.
  static Future<PlusStatus> refresh() async {
    final response = await _send('GET', '/api/plus/me');
    return PlusStatus.fromServer(response);
  }

  /// Синни озмоишии як моҳа. Сервер қарор мегирад — аз ҷумла «аллакай
  /// истифода шудааст».
  static Future<PlusStatus> startTrial() async {
    final response = await _send('POST', '/api/plus/trial');
    return PlusStatus.fromServer(response);
  }

  /// Гранти соҳиб. Агар корбар соҳиб набошад, сервер 403 медиҳад.
  static Future<PlusStatus> grant({required String uid, required String duration}) async {
    final response = await _send('POST', '/api/plus/grant', body: {'uid': uid, 'duration': duration});
    return PlusStatus.fromServer(response);
  }

  static Future<PlusStatus> revoke({required String uid}) async {
    final response = await _send('POST', '/api/plus/revoke', body: {'uid': uid});
    return PlusStatus.fromServer(response);
  }

  static Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw const PlusFailure('not-signed-in');

    final uri = Uri.parse('${OtpServerConfig.baseUrl}$path');
    final headers = {
      'Authorization': 'Bearer $token',
      if (body != null) 'Content-Type': 'application/json',
    };

    final http.Response response;
    try {
      response = method == 'GET'
          ? await http.get(uri, headers: headers).timeout(const Duration(seconds: 20))
          : await http
              .post(uri, headers: headers, body: body == null ? null : jsonEncode(body))
              .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw const PlusFailure('network');
    }

    final Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw const PlusFailure('bad-response');
    }

    if (response.statusCode != 200) {
      throw PlusFailure((decoded['error'] as String?) ?? 'http-${response.statusCode}');
    }
    return decoded;
  }
}
