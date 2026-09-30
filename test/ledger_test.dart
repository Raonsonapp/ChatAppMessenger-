import 'package:chatapp/models/ledger_entry.dart';
import 'package:flutter_test/flutter_test.dart';

LedgerEntry entry(LedgerKind kind, num amount, {bool settled = false}) {
  return LedgerEntry(id: 'e', kind: kind, title: 'X', amount: amount, settled: settled);
}

/// Ҳисоби дафтар.
///
/// Ин ҷо пули воқеии корбар ҳисоб мешавад. Хатои як аломат маънои онро дорад,
/// ки соҳиби дукон рақами хатоеро мебинад ва ба он бовар мекунад — бинобар ин
/// ҳар ҳолат алоҳида қулф карда шудааст.
void main() {
  group('LedgerKind', () {
    test('коди номаълум ба қарз бармегардад', () {
      expect(LedgerKind.fromCode('nonsense'), LedgerKind.debt);
      expect(LedgerKind.fromCode(null), LedgerKind.debt);
    });

    test('аломати навъҳо', () {
      expect(LedgerKind.debt.isPositive, isTrue);
      expect(LedgerKind.income.isPositive, isTrue);
      expect(LedgerKind.credit.isPositive, isFalse);
      expect(LedgerKind.expense.isPositive, isFalse);
    });
  });

  group('signedAmount', () {
    test('даромад мусбат, хароҷот манфӣ', () {
      expect(entry(LedgerKind.income, 500).signedAmount, 500);
      expect(entry(LedgerKind.expense, 500).signedAmount, -500);
    });

    test('қарзи пӯшида ба тавозун дохил намешавад', () {
      expect(entry(LedgerKind.debt, 500, settled: true).signedAmount, 0);
      expect(entry(LedgerKind.credit, 500, settled: true).signedAmount, 0);
    });

    test('«пӯшида» ба даромад ва хароҷот дахл надорад', () {
      // Даромад ҳатто бо settled: true ҳамчун даромад мемонад — он аллакай
      // рӯй додааст.
      expect(entry(LedgerKind.income, 500, settled: true).signedAmount, 500);
      expect(entry(LedgerKind.expense, 500, settled: true).signedAmount, -500);
    });
  });

  group('toMap', () {
    test('аломат нигоҳ дошта намешавад', () {
      // Вагарна хароҷоти «-500» ду маротиба манфӣ мешуд.
      final map = LedgerEntry(id: 'e', kind: LedgerKind.expense, title: 'X', amount: -500).toMap();
      expect(map['amount'], 500);
    });
  });

  group('LedgerSummary', () {
    test('дафтари холӣ сифр медиҳад', () {
      final summary = LedgerSummary.from(const []);
      expect(summary.profit, 0);
      expect(summary.balance, 0);
    });

    test('фоида = даромад − хароҷот, бе қарзҳо', () {
      final summary = LedgerSummary.from([
        entry(LedgerKind.income, 1000),
        entry(LedgerKind.expense, 300),
        // Қарз ҳанӯз пул нест — ба фоида дохил намешавад.
        entry(LedgerKind.debt, 5000),
      ]);
      expect(summary.income, 1000);
      expect(summary.expense, 300);
      expect(summary.profit, 700);
    });

    test('тавозун қарзҳои кушодаро ҳисоб мекунад', () {
      final summary = LedgerSummary.from([
        entry(LedgerKind.income, 1000),
        entry(LedgerKind.expense, 300),
        entry(LedgerKind.debt, 500),
        entry(LedgerKind.credit, 200),
      ]);
      expect(summary.owedToMe, 500);
      expect(summary.owedByMe, 200);
      expect(summary.balance, 1000 - 300 + 500 - 200);
    });

    test('қарзи пӯшида аз тавозун мебарояд', () {
      final open = LedgerSummary.from([entry(LedgerKind.debt, 500)]);
      final closed = LedgerSummary.from([entry(LedgerKind.debt, 500, settled: true)]);
      expect(open.owedToMe, 500);
      expect(closed.owedToMe, 0);
      expect(closed.balance, 0);
    });

    test('тавозуни манфӣ имконпазир аст', () {
      final summary = LedgerSummary.from([
        entry(LedgerKind.expense, 900),
        entry(LedgerKind.credit, 100),
      ]);
      expect(summary.profit, -900);
      expect(summary.balance, -1000);
    });
  });
}
