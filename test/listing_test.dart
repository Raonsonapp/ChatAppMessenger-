import 'package:chatapp/models/listing.dart';
import 'package:flutter_test/flutter_test.dart';

Listing listing({
  String title = 'Samsung A51',
  String description = '',
  String city = '',
  String category = '',
  List<String> images = const [],
}) {
  return Listing(
    id: 'l1',
    kind: ListingKind.product,
    ownerId: 'a',
    ownerName: 'A',
    title: title,
    description: description,
    city: city,
    category: category,
    images: images,
  );
}

void main() {
  group('ListingKind', () {
    test('коди маълум хонда мешавад', () {
      expect(ListingKind.fromCode('service'), ListingKind.service);
      expect(ListingKind.fromCode('job'), ListingKind.job);
      expect(ListingKind.fromCode('ad'), ListingKind.ad);
    });

    test('коди номаълум ба маҳсулот бармегардад', () {
      // Эълони навъи номаълум набояд экрани Бозорро вайрон кунад.
      expect(ListingKind.fromCode('spaceship'), ListingKind.product);
      expect(ListingKind.fromCode(null), ListingKind.product);
      expect(ListingKind.fromCode(''), ListingKind.product);
    });
  });

  group('matches', () {
    test('сарлавҳа бе назардошти ҳарфи калон ёфт мешавад', () {
      expect(listing().matches('samsung'), isTrue);
      expect(listing().matches('SAMSUNG'), isTrue);
      expect(listing().matches('a51'), isTrue);
    });

    test('тавсиф, шаҳр ва категория низ ҷустуҷӯ мешаванд', () {
      expect(listing(description: 'ҳолати хуб').matches('ҳолати'), isTrue);
      expect(listing(city: 'Душанбе').matches('душанбе'), isTrue);
      expect(listing(category: 'Телефон').matches('телефон'), isTrue);
    });

    test('дархости холӣ ҳамаро мегирад', () {
      expect(listing().matches(''), isTrue);
      expect(listing().matches('   '), isTrue);
    });

    test('матни номувофиқ ёфт намешавад', () {
      expect(listing().matches('трактор'), isFalse);
    });
  });

  group('coverImage', () {
    test('бе расм null', () {
      expect(listing().coverImage, isNull);
    });

    test('аввалин расм ҳамчун муқова', () {
      expect(listing(images: const ['a.jpg', 'b.jpg']).coverImage, 'a.jpg');
    });
  });

  group('toMap', () {
    test('нархи null тамоман навишта намешавад', () {
      // Навиштани `price: null` ба Firestore тартибдиҳиро вайрон мекунад ва
      // «нарх нишон дода нашудааст»-ро аз «нархи сифр» ҷудо карда намешавад.
      final map = listing().toMap();
      expect(map.containsKey('price'), isFalse);
    });

    test('нархи сифр навишта мешавад', () {
      const free = Listing(
        id: 'l1',
        kind: ListingKind.ad,
        ownerId: 'a',
        ownerName: 'A',
        title: 'Муфт',
        price: 0,
      );
      expect(free.toMap()['price'], 0);
    });

    test('titleLower барои ҷустуҷӯи оянда навишта мешавад', () {
      expect(listing(title: 'Samsung A51').toMap()['titleLower'], 'samsung a51');
    });
  });
}
