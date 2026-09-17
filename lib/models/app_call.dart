import 'package:cloud_firestore/cloud_firestore.dart';
import '../l10n/l10n.dart';

enum CallType { audio, video }

enum CallOutcome { ringing, completed, missed, declined }

/// Ҳуҷҷати `calls/{id}` — сабти занг. Худи садо ва видео тавассути Agora RTC
/// интиқол мешавад; ин ҳуҷҷат барои занг задан (ringing), таърих ва натиҷа аст.
///
/// Барои занги гурӯҳӣ барои ҳар узв як ҳуҷҷати алоҳида сохта мешавад, вале
/// ҳамаашон як `channelId`-и умумӣ доранд — ҳама ба ҳамон канал ҳамроҳ мешаванд.
class AppCall {
  final String id;
  final String callerId;
  final String callerName;
  final String calleeId;
  final String calleeName;
  final CallType type;
  final CallOutcome outcome;
  final DateTime? createdAt;
  final int durationSeconds;
  final List<String> participants;

  AppCall({
    required this.id,
    required this.callerId,
    required this.callerName,
    required this.calleeId,
    required this.calleeName,
    required this.type,
    required this.outcome,
    required this.participants,
    this.createdAt,
    this.durationSeconds = 0,
  });

  factory AppCall.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return AppCall(
      id: doc.id,
      callerId: (data['callerId'] ?? '') as String,
      callerName: (data['callerName'] ?? tr('k002')) as String,
      calleeId: (data['calleeId'] ?? '') as String,
      calleeName: (data['calleeName'] ?? tr('k002')) as String,
      type: (data['type'] == 'video') ? CallType.video : CallType.audio,
      outcome: CallOutcome.values.firstWhere(
        (o) => o.name == (data['outcome'] ?? 'completed'),
        orElse: () => CallOutcome.completed,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      durationSeconds: (data['durationSeconds'] ?? 0) as int,
      participants: List<String>.from(data['participants'] as List? ?? []),
    );
  }

  static Map<String, dynamic> newCallMap({
    required String callerId,
    required String callerName,
    required String calleeId,
    required String calleeName,
    required CallType type,
  }) {
    return {
      'callerId': callerId,
      'callerName': callerName,
      'calleeId': calleeId,
      'calleeName': calleeName,
      'type': type == CallType.video ? 'video' : 'audio',
      'outcome': CallOutcome.ringing.name,
      'createdAt': FieldValue.serverTimestamp(),
      'durationSeconds': 0,
      'participants': [callerId, calleeId],
    };
  }

  /// Барои занги гурӯҳӣ — id ва номи гурӯҳ; барои занги шахсӣ `null`.
  static Map<String, dynamic> newGroupCallMap({
    required String callerId,
    required String callerName,
    required String calleeId,
    required String calleeName,
    required CallType type,
    required String channelId,
    required String groupId,
    required String groupName,
  }) {
    return {
      ...newCallMap(
        callerId: callerId,
        callerName: callerName,
        calleeId: calleeId,
        calleeName: calleeName,
        type: type,
      ),
      'channelId': channelId,
      'groupId': groupId,
      'groupName': groupName,
    };
  }

  String otherName(String currentUid) => currentUid == callerId ? calleeName : callerName;
  String otherUid(String currentUid) => currentUid == callerId ? calleeId : callerId;
  bool isOutgoing(String currentUid) => currentUid == callerId;
}
