import 'package:chatapp/l10n/l10n.dart';
import 'package:chatapp/widgets/stream_error_notice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_test/flutter_test.dart';

/// Огоҳии нокомии ҷараён.
///
/// Бе он хатои Firestore ҳамчун рӯйхати ХОЛӢ дида мешуд ва корбар фикр мекард
/// ки маълумоташ гум шудааст. Санҷиш таъмин мекунад, ки матн воқеан пайдо
/// мешавад ва ҳарду ҳолат (пурра ва ҷамъушуда) кор мекунанд.
void main() {
  testWidgets('матни хато нишон дода мешавад', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: StreamErrorNotice())),
    );
    expect(find.text(tr('k641')), findsOneWidget);
    expect(find.byIcon(LucideIcons.cloud_off), findsOneWidget);
  });

  testWidgets('ҳолати ҷамъушуда низ матнро нишон медиҳад', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: StreamErrorNotice(compact: true))),
    );
    expect(find.text(tr('k641')), findsOneWidget);
  });

  testWidgets('хатои додашуда интерфейсро вайрон намекунад', (tester) async {
    // Матни хатои Firestore ба корбар нишон дода намешавад — он танҳо дар
    // debug чоп мешавад.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StreamErrorNotice(error: Exception('permission-denied')),
        ),
      ),
    );
    expect(find.text(tr('k641')), findsOneWidget);
    expect(find.textContaining('permission-denied'), findsNothing);
  });
}
