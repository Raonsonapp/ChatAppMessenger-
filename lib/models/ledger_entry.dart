import 'package:cloud_firestore/cloud_firestore.dart';

/// Навъи сабт дар дафтар.
enum LedgerKind {
  /// Касе ба ман қарздор аст (мол дода шуд, пул ҳанӯз нест).
  debt('debt'),

  /// Ман ба касе қарздорам.
  credit('credit'),

  /// Даромад — фурӯши пардохтшуда.
  income('income'),

  /// Хароҷот.
  expense('expense');

  const LedgerKind(this.code);
  final String code;

  static LedgerKind fromCode(String? code) {
    for (final kind in LedgerKind.values) {
      if (kind.code == code) return kind;
    }
    return LedgerKind.debt;
  }

  /// Оё ин сабт ба тавозун мусбат меафзояд.
  ///
  /// Даромад ва қарзи ба ман — мусбат; хароҷот ва қарзи ман — манфӣ.
  bool get isPositive => this == LedgerKind.debt || this == LedgerKind.income;
}

/// Як сабти дафтари бизнес.
///
/// Дафтар ба худи соҳиб тааллуқ дорад: он сабти шахсии ӯст, тарафи дуюм онро
/// намебинад ва тасдиқ намекунад. Ба ҳамин сабаб он ҳељ системаи фармоиш талаб
/// намекунад ва пурра кор мекунад.
class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.kind,
    required this.title,
    required this.amount,
    this.note = '',
    this.settled = false,
    this.createdAt,
  });

  final String id;
  final LedgerKind kind;

  /// Ном: харидор, фурӯшанда ё сабаби хароҷот.
  final String title;

  /// Ҳамеша мусбат нигоҳ дошта мешавад; аломат аз `kind` меояд.
  final num amount;

  final String note;

  /// Оё қарз пӯшида шудааст. Барои даромад ва хароҷот маъно надорад.
  final bool settled;

  final DateTime? createdAt;

  /// Таъсир ба тавозун. Қарзи пӯшидашуда ба тавозун дохил намешавад.
  num get signedAmount {
    if (settled && (kind == LedgerKind.debt || kind == LedgerKind.credit)) return 0;
    return kind.isPositive ? amount : -amount;
  }

  factory LedgerEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    final rawAmount = data['amount'];
    return LedgerEntry(
      id: doc.id,
      kind: LedgerKind.fromCode(data['kind'] as String?),
      title: (data['title'] ?? '') as String,
      amount: rawAmount is num ? rawAmount.abs() : 0,
      note: (data['note'] ?? '') as String,
      settled: (data['settled'] ?? false) as bool,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'kind': kind.code,
        'title': title,
        // Аломат нигоҳ дошта намешавад — вагарна сабти «-500»-и навъи хароҷот
        // ду маротиба манфӣ мешуд.
        'amount': amount.abs(),
        'note': note,
        'settled': settled,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

/// Ҳисоби умумии дафтар.
class LedgerSummary {
  const LedgerSummary({
    required this.owedToMe,
    required this.owedByMe,
    required this.income,
    required this.expense,
  });

  final num owedToMe;
  final num owedByMe;
  final num income;
  final num expense;

  /// Фоида: даромад минус хароҷот. Қарзҳо ба фоида дохил намешаванд — онҳо
  /// ҳанӯз пул нестанд.
  num get profit => income - expense;

  /// Тавозуни умумӣ бо назардошти қарзҳои кушода.
  num get balance => income - expense + owedToMe - owedByMe;

  static LedgerSummary from(Iterable<LedgerEntry> entries) {
    num owedToMe = 0, owedByMe = 0, income = 0, expense = 0;
    for (final entry in entries) {
      switch (entry.kind) {
        case LedgerKind.debt:
          if (!entry.settled) owedToMe += entry.amount;
        case LedgerKind.credit:
          if (!entry.settled) owedByMe += entry.amount;
        case LedgerKind.income:
          income += entry.amount;
        case LedgerKind.expense:
          expense += entry.amount;
      }
    }
    return LedgerSummary(
      owedToMe: owedToMe,
      owedByMe: owedByMe,
      income: income,
      expense: expense,
    );
  }
}
