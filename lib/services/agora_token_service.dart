import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config/otp_server_config.dart';

/// Token барои ҳамроҳ шудан ба канали Agora.
///
/// App Certificate ҳељ гоҳ дар барнома намемонад: онро аз APK кашида гирифтан
/// мумкин аст ва баъд ҳар кас метавонад бо ҳисоби мо занг занад. Бинобар ин
/// token дар сервер сохта мешавад ва барнома танҳо онро мегирад.
class AgoraTokenService {
  /// Token ва маълумоти ҳамроҳшавӣ барои [channelName].
  ///
  /// Сервер дастрасиро САНҶИДА мебарояд: корбар бояд иштирокчии ҳамон занг ё
  /// узви ҳамон гурӯҳ бошад.
  static Future<AgoraCredentials> fetch(String channelName) async {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (idToken == null) {
      throw const AgoraTokenFailure(AgoraTokenFailureKind.notSignedIn);
    }

    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('${OtpServerConfig.baseUrl}/api/agora-token'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({'channelName': channelName}),
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw const AgoraTokenFailure(AgoraTokenFailureKind.network);
    }

    if (response.statusCode == 503) {
      throw const AgoraTokenFailure(AgoraTokenFailureKind.notConfigured);
    }
    if (response.statusCode == 403) {
      // Сервер сабаби аниқро мегӯяд: `call-not-found`, `not-a-participant`,
      // `group-not-found`, `not-a-member`. Бе он «token нашуд» ҳељ чиз
      // намефаҳмонад ва хатогиро ёфтан душвор мешавад.
      String? reason;
      try {
        reason = (jsonDecode(response.body) as Map<String, dynamic>)['error'] as String?;
      } catch (_) {}
      throw AgoraTokenFailure(AgoraTokenFailureKind.notAllowed, reason);
    }
    if (response.statusCode == 401) {
      throw const AgoraTokenFailure(AgoraTokenFailureKind.notSignedIn);
    }
    if (response.statusCode != 200) {
      throw const AgoraTokenFailure(AgoraTokenFailureKind.server);
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final appId = data['appId'] as String?;
    final uid = data['uid'];
    if (appId == null || appId.isEmpty || uid is! int) {
      throw const AgoraTokenFailure(AgoraTokenFailureKind.server);
    }

    return AgoraCredentials(
      appId: appId,
      // `null` — лоиҳа дар ҳолати «App ID only» аст ва token лозим нест.
      token: data['token'] as String?,
      uid: uid,
      expiresInSeconds: (data['expiresInSeconds'] as int?) ?? 0,
    );
  }
}

class AgoraCredentials {
  final String appId;
  final String? token;
  final int uid;
  final int expiresInSeconds;

  const AgoraCredentials({
    required this.appId,
    required this.token,
    required this.uid,
    required this.expiresInSeconds,
  });

  /// Agora сатри холиро ҳамчун «бе token» мефаҳмад.
  String get tokenOrEmpty => token ?? '';
}

enum AgoraTokenFailureKind {
  notSignedIn,
  network,
  notConfigured,
  notAllowed,
  server,
}

class AgoraTokenFailure implements Exception {
  final AgoraTokenFailureKind kind;

  /// Сабаби аниқи сервер — барои ташхис.
  final String? reason;

  const AgoraTokenFailure(this.kind, [this.reason]);

  @override
  String toString() =>
      'AgoraTokenFailure(${kind.name}${reason == null ? '' : ', $reason'})';
}
