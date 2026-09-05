import 'package:cloud_firestore/cloud_firestore.dart';

enum CallType { audio, video }

enum CallOutcome { ringing, completed, missed, declined }

/// Ҳуҷҷати `calls/{id}` — сабти воқеии таърихи занг байни ду корбар.
/// Худи занг (садо/видео) шабеҳсозишуда аст (UI-и пурра), зеро занги
/// воқеӣ ба хидмати WebRTC/сигналии беруна ниёз дорад — дар ин лоиҳа
/// пайваст нашудааст.
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
      callerName: (data['callerName'] ?? 'Корбар') as String,
      calleeId: (data['calleeId'] ?? '') as String,
      calleeName: (data['calleeName'] ?? 'Корбар') as String,
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

  String otherName(String currentUid) => currentUid == callerId ? calleeName : callerName;
  String otherUid(String currentUid) => currentUid == callerId ? calleeId : callerId;
  bool isOutgoing(String currentUid) => currentUid == callerId;
}
