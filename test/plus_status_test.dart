import 'package:chatapp/services/plus_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ҳолати Plus дар тарафи барнома.
///
/// Барнома ҳуқуқ НАМЕДИҲАД — онро сервер менависад. Вале барнома мӯҳлатро
/// ҳисоб мекунад ва маҳз ин ҷо хатои хомӯш пайдо мешавад: обунаи гузашта
/// ҳамчун фаъол нишон дода мешавад, чун `active: true` дар ҳуҷҷат монда.
void main() {
  final past = DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch;
  final future = DateTime.now().add(const Duration(days: 10)).millisecondsSinceEpoch;

  group('fromUserDoc', () {
    test('ҳуҷҷати бе plus фаъол нест', () {
      expect(PlusStatus.fromUserDoc(null).active, isFalse);
      expect(PlusStatus.fromUserDoc({}).active, isFalse);
      expect(PlusStatus.fromUserDoc({'name': 'A'}).active, isFalse);
    });

    test('мӯҳлати гузашта фаъол нест, ҳарчанд active: true бошад', () {
      final status = PlusStatus.fromUserDoc({
        'plus': {'active': true, 'expiresAt': past},
      });
      expect(status.active, isFalse);
    });

    test('мӯҳлати оянда фаъол аст', () {
      final status = PlusStatus.fromUserDoc({
        'plus': {'active': true, 'expiresAt': future},
      });
      expect(status.active, isTrue);
    });

    test('expiresAt-и null — бе мӯҳлат, фаъол', () {
      final status = PlusStatus.fromUserDoc({
        'plus': {'active': true, 'expiresAt': null},
      });
      expect(status.active, isTrue);
      expect(status.expiresAt, isNull);
    });

    test('active-и сатрӣ қабул намешавад', () {
      // Маълумоти нодуруст набояд Plus-ро фаъол кунад.
      final status = PlusStatus.fromUserDoc({
        'plus': {'active': 'true', 'expiresAt': null},
      });
      expect(status.active, isFalse);
    });

    test('plus-и на-Map барномаро вайрон намекунад', () {
      expect(PlusStatus.fromUserDoc({'plus': 'yes'}).active, isFalse);
      expect(PlusStatus.fromUserDoc({'plus': 7}).active, isFalse);
      expect(PlusStatus.fromUserDoc({'plus': const []}).active, isFalse);
    });

    test('соҳиб ҳатто бе ҳуҷҷати plus фаъол аст', () {
      final status = PlusStatus.fromUserDoc(null, isOwner: true);
      expect(status.active, isTrue);
      expect(status.isOwner, isTrue);
      expect(status.source, PlusSource.owner);
      expect(status.expiresAt, isNull);
    });

    test('соҳиб бо мӯҳлати гузашта ҳам фаъол мемонад', () {
      final status = PlusStatus.fromUserDoc({
        'plus': {'active': false, 'expiresAt': past},
      }, isOwner: true);
      expect(status.active, isTrue);
    });

    test('сарчашма хонда мешавад', () {
      expect(
        PlusStatus.fromUserDoc({'plus': {'active': true, 'source': 'owner_grant'}}).source,
        PlusSource.ownerGrant,
      );
      expect(
        PlusStatus.fromUserDoc({'plus': {'active': true, 'source': 'trial'}}).source,
        PlusSource.trial,
      );
      expect(
        PlusStatus.fromUserDoc({'plus': {'active': true, 'source': 'ҳаҷв'}}).source,
        PlusSource.none,
      );
    });
  });

  group('canStartTrial', () {
    test('корбари нав моҳи муфт гирифта метавонад', () {
      expect(PlusStatus.fromUserDoc(null).canStartTrial, isTrue);
    });

    test('баъди истифода — не', () {
      final status = PlusStatus.fromUserDoc({
        'plus': {'active': false, 'trialUsed': true},
      });
      expect(status.canStartTrial, isFalse);
    });

    test('ҳангоми Plus-и фаъол — не', () {
      final status = PlusStatus.fromUserDoc({
        'plus': {'active': true, 'expiresAt': future, 'trialUsed': false},
      });
      expect(status.canStartTrial, isFalse);
    });

    test('соҳиб моҳи муфт намехоҳад', () {
      expect(PlusStatus.fromUserDoc(null, isOwner: true).canStartTrial, isFalse);
    });

    test('мӯҳлати гузашта ва trial истифоданашуда — мумкин', () {
      // Грант тамом шуд, вале моҳи муфт ҳанӯз гирифта нашудааст.
      final status = PlusStatus.fromUserDoc({
        'plus': {'active': true, 'expiresAt': past, 'trialUsed': false},
      });
      expect(status.canStartTrial, isTrue);
    });
  });

  group('fromServer', () {
    test('ҷавоби сервер хонда мешавад', () {
      final status = PlusStatus.fromServer({
        'isOwner': false,
        'active': true,
        'source': 'trial',
        'expiresAt': future,
        'trialUsed': true,
      });
      expect(status.active, isTrue);
      expect(status.source, PlusSource.trial);
      expect(status.trialUsed, isTrue);
      expect(status.expiresAt, isNotNull);
    });

    test('ҷавоби холӣ фаъол нест', () {
      final status = PlusStatus.fromServer({});
      expect(status.active, isFalse);
      expect(status.isOwner, isFalse);
      expect(status.expiresAt, isNull);
    });
  });
}
