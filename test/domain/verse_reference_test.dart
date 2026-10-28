import 'package:flutter_test/flutter_test.dart';
import 'package:sosiego/domain/verse_reference.dart';

void main() {
  group('parseReference', () {
    test('libro, capítulo y versículo', () {
      expect(parseReference('Juan 3:16'), const VerseReference(43, 3, 16));
    });

    test('ignora mayúsculas y tildes', () {
      expect(parseReference('GENESIS 1:1'), const VerseReference(1, 1, 1));
      expect(parseReference('génesis 1:1'), const VerseReference(1, 1, 1));
    });

    test('abreviaturas con y sin punto', () {
      expect(parseReference('Sal. 23:1'), const VerseReference(19, 23, 1));
      expect(parseReference('sal 23'), const VerseReference(19, 23));
    });

    test('libros numerados', () {
      expect(
        parseReference('1 Corintios 13:4'),
        const VerseReference(46, 13, 4),
      );
      expect(parseReference('1Co 13:4'), const VerseReference(46, 13, 4));
      expect(parseReference('2 Timoteo 3:16'), const VerseReference(55, 3, 16));
    });

    test('singular "Salmo"', () {
      expect(parseReference('Salmo 91'), const VerseReference(19, 91));
    });

    test('solo capítulo no tiene verseId', () {
      expect(parseReference('Juan 3')!.verseId, isNull);
    });

    test('verseId compuesto', () {
      expect(parseReference('Juan 3:16')!.verseId, 43003016);
    });

    test('texto libre devuelve null', () {
      expect(parseReference('paz en la tormenta'), isNull);
      expect(parseReference('Marte 3:16'), isNull);
      expect(parseReference(''), isNull);
    });

    test('capítulo o versículo cero son inválidos', () {
      expect(parseReference('Juan 0:1'), isNull);
      expect(parseReference('Juan 3:0'), isNull);
    });
  });

  test('catálogo tiene 66 libros con ids 1..66', () {
    expect(bibleBooks.length, 66);
    expect(bibleBooks.map((b) => b.id), List.generate(66, (i) => i + 1));
  });
}
