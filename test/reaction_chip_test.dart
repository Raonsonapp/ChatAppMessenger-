import 'package:chatapp/widgets/reaction_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ҳубоби вокунишҳо.
///
/// Санҷиши асосӣ: вокунишҳои зиёдатӣ бояд ҳамчун «+N» нишон дода шаванд, на
/// хомӯшона гум шаванд — вагарна корбар фикр мекунад ки вокуниши ӯ нарасид.
Widget wrap(List<String> reactions) {
  return MaterialApp(
    home: Scaffold(body: Center(child: ReactionChip(reactions: reactions))),
  );
}

void main() {
  testWidgets('рӯйхати холӣ чизе намекашад', (tester) async {
    await tester.pumpWidget(wrap(const []));
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('то се вокуниш пурра нишон дода мешавад', (tester) async {
    await tester.pumpWidget(wrap(const ['❤️', '😂', '👍']));
    await tester.pumpAndSettle();
    expect(find.text('❤️ 😂 👍'), findsOneWidget);
    expect(find.textContaining('+'), findsNothing);
  });

  testWidgets('вокунишҳои зиёдатӣ ҳамчун +N нишон дода мешаванд', (tester) async {
    await tester.pumpWidget(wrap(const ['❤️', '😂', '👍', '🔥', '🎉']));
    await tester.pumpAndSettle();
    expect(find.text('❤️ 😂 👍'), findsOneWidget);
    expect(find.text('+2'), findsOneWidget);
  });

  testWidgets('як вокуниш бе +N', (tester) async {
    await tester.pumpWidget(wrap(const ['🔥']));
    await tester.pumpAndSettle();
    expect(find.text('🔥'), findsOneWidget);
    expect(find.textContaining('+'), findsNothing);
  });

  testWidgets('вокуниши нав аниматсияро оғоз мекунад', (tester) async {
    await tester.pumpWidget(wrap(const ['❤️']));
    await tester.pumpAndSettle();

    // Ҷустуҷӯ ба дохили ҳубоб маҳдуд мешавад: MaterialApp худаш низ
    // `ScaleTransition` истифода мебарад ва бе маҳдудият «too many elements».
    ScaleTransition scale() => tester.widget<ScaleTransition>(find.descendant(
          of: find.byType(ReactionChip),
          matching: find.byType(ScaleTransition),
        ));
    expect(scale().scale.value, closeTo(1, 0.001));

    await tester.pumpWidget(wrap(const ['❤️', '😂']));
    await tester.pump();
    // Аниматсия аз сифр сар мешавад — яъне ҳубоб ҷаҳид.
    expect(scale().scale.value, lessThan(1));

    await tester.pumpAndSettle();
    expect(scale().scale.value, closeTo(1, 0.001));
  });

  testWidgets('кашидани такрорӣ бе тағйир аниматсия намедиҳад', (tester) async {
    // Бе ин варақ задани чат ҳубобҳои ҷаҳанда медод.
    await tester.pumpWidget(wrap(const ['❤️']));
    await tester.pumpAndSettle();

    await tester.pumpWidget(wrap(const ['❤️']));
    await tester.pump();
    final scale = tester.widget<ScaleTransition>(find.descendant(
      of: find.byType(ReactionChip),
      matching: find.byType(ScaleTransition),
    ));
    expect(scale.scale.value, closeTo(1, 0.001));
  });
}
