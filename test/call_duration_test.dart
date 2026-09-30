import 'package:chatapp/models/app_call.dart';
import 'package:flutter_test/flutter_test.dart';

/// Давомнокии занг дар таърих.
///
/// `durationSeconds` кайҳо дар Firestore сабт мешуд, вале ҳељ ҷо нишон дода
/// намешуд. Ин санҷиш шаклро қулф мекунад ва, муҳимтар, намегузорад ки барои
/// занги ноанҷом «0:00» навишта шавад — он хонандаро гумроҳ мекунад.
AppCall call({
  required CallOutcome outcome,
  required int seconds,
}) {
  return AppCall(
    id: 'c1',
    callerId: 'a',
    callerName: 'A',
    calleeId: 'b',
    calleeName: 'B',
    type: CallType.audio,
    outcome: outcome,
    durationSeconds: seconds,
    participants: const ['a', 'b'],
  );
}

void main() {
  test('дақиқа ва сония', () {
    expect(call(outcome: CallOutcome.completed, seconds: 125).formattedDuration, '2:05');
    expect(call(outcome: CallOutcome.completed, seconds: 5).formattedDuration, '0:05');
    expect(call(outcome: CallOutcome.completed, seconds: 60).formattedDuration, '1:00');
  });

  test('занги аз як соат дарозтар соатро нишон медиҳад', () {
    expect(call(outcome: CallOutcome.completed, seconds: 3750).formattedDuration, '1:02:30');
  });

  test('занги ноанҷом давомнокӣ надорад', () {
    expect(call(outcome: CallOutcome.missed, seconds: 0).formattedDuration, isNull);
    expect(call(outcome: CallOutcome.declined, seconds: 0).formattedDuration, isNull);
  });

  test('занги анҷомёфта бо сифр давомнокӣ надорад', () {
    // Ин ҳолат воқеан рӯй медиҳад: занг пайваст шуд ва дарҳол қатъ гардид.
    // Навиштани «0:00» дар таърих бемаънист.
    expect(call(outcome: CallOutcome.completed, seconds: 0).formattedDuration, isNull);
  });
}
