import 'package:flutter_test/flutter_test.dart';
import 'package:sosiego/domain/share_text.dart';

void main() {
  group('HU-09 texto y enlace', () {
    test(
      'HU-09.5 el enlace es https://{dominio}/v/{slug}-{capitulo}-{versiculo}',
      () {
        expect(
          verseLink(bookSlug: 'juan', chapter: 3, verse: 16),
          'https://sosiego.app/v/juan-3-16',
        );
        expect(
          verseLink(
            bookSlug: '1-corintios',
            chapter: 13,
            verse: 4,
            domain: 'https://x.test',
          ),
          'https://x.test/v/1-corintios-13-4',
        );
        expect(shareDomainUrl, startsWith('https://'));
      },
    );

    test('HU-09.5 el slug sale del nombre sin tildes y con guiones', () {
      expect(bookSlugFromName('Juan'), 'juan');
      expect(bookSlugFromName('1 Corintios'), '1-corintios');
      expect(bookSlugFromName('Génesis'), 'genesis');
      expect(bookSlugFromName('2 Crónicas'), '2-cronicas');
    });

    test('HU-09.4 el texto sigue el formato «texto» / referencia / enlace', () {
      final t = buildShareText(
        verseText: 'Jehová es mi pastor; nada me faltará.',
        reference: 'Salmos 23:1',
        link: 'https://sosiego.app/v/salmos-23-1',
      );
      expect(t.split('\n'), [
        '«Jehová es mi pastor; nada me faltará.»',
        'Salmos 23:1',
        'https://sosiego.app/v/salmos-23-1',
      ]);
    });

    test(
      'HU-09.4 «Para {nombre}» va entre la referencia y el enlace solo si hay',
      () {
        final con = buildShareText(
          verseText: 'x',
          reference: 'Juan 3:16',
          link: 'https://sosiego.app/v/juan-3-16',
          dedication: '  mamá ',
        );
        expect(con.split('\n'), [
          '«x»',
          'Juan 3:16',
          'Para mamá',
          'https://sosiego.app/v/juan-3-16',
        ]);
        for (final vacio in [null, '', '   ', '\n']) {
          final sin = buildShareText(
            verseText: 'x',
            reference: 'Juan 3:16',
            link: 'https://sosiego.app/v/juan-3-16',
            dedication: vacio,
          );
          expect(sin.contains('Para'), isFalse, reason: 'dedicatoria "$vacio"');
          expect(sin.split('\n').length, 3);
        }
      },
    );

    test('HU-09.1 la dedicatoria tiene un máximo de 30 caracteres', () {
      expect(cleanDedication('a' * 45)!.length, maxDedicationLength);
      expect(maxDedicationLength, 30);
      expect(cleanDedication('b' * 30), 'b' * 30);
      expect(cleanDedication('Para ti\ncon cariño'), 'Para ti con cariño');
      expect(cleanDedication('   '), isNull);
      expect(cleanDedication('🙂' * 40)!.runes.length, 30);
    });

    test('HU-09.5 la dedicatoria nunca va dentro del enlace', () {
      final link = verseLink(bookSlug: 'juan', chapter: 3, verse: 16);
      final texto = buildShareText(
        verseText: 'x',
        reference: 'Juan 3:16',
        link: link,
        dedication: 'mamá querida',
      );
      expect(link.contains('mam'), isFalse);
      expect(texto.split('\n').last, link);
      final sin = buildShareText(
        verseText: 'x',
        reference: 'Juan 3:16',
        link: link,
      );
      expect(sin.split('\n').last, link);
    });

    test(
      'HU-09.4 WhatsApp: wa.me con el texto codificado (espacios como %20)',
      () {
        final texto = buildShareText(
          verseText: 'Porque de tal manera amó Dios & el mundo',
          reference: 'Juan 3:16',
          link: 'https://sosiego.app/v/juan-3-16',
          dedication: 'José',
        );
        final uri = whatsappUri(texto);
        expect(uri.host, 'wa.me');
        expect(uri.toString(), startsWith('https://wa.me/?text='));
        expect(uri.toString().contains(' '), isFalse);
        expect(uri.toString().contains('+'), isFalse);
        expect(uri.toString().contains('%0A'), isTrue);
        expect(uri.toString().contains('%26'), isTrue);
        expect(uri.queryParameters['text'], texto);
      },
    );

    test('HU-09.2 en la tarjeta el enlace se muestra sin https://', () {
      expect(
        displayLink('https://sosiego.app/v/juan-3-16'),
        'sosiego.app/v/juan-3-16',
      );
    });
  });
}
