import 'package:flutter_test/flutter_test.dart';
import 'package:sosiego/domain/spoken_reference.dart';

void main() {
  group('HU-08 texto hablado', () {
    test('HU-08.3 la referencia se dice «Juan, capítulo 3, versículo 16»', () {
      expect(spokenReference('Juan', 3, 16), 'Juan, capítulo 3, versículo 16');
      expect(
        spokenReference('Salmos', 23, 1),
        'Salmos, capítulo 23, versículo 1',
      );
    });

    test('HU-08.3 los libros numerados se dicen con ordinal', () {
      expect(
        spokenReference('1 Corintios', 13, 4),
        'Primera de Corintios, capítulo 13, versículo 4',
      );
      expect(
        spokenReference('1 Samuel', 17, 47),
        'Primero de Samuel, capítulo 17, versículo 47',
      );
      expect(
        spokenReference('2 Crónicas', 7, 14),
        'Segundo de Crónicas, capítulo 7, versículo 14',
      );
    });

    test('HU-08.3 con bloques extra lee versículo, contexto, reflexión, aplicación y oración', () {
      final s = listenSegments(
        bookName: 'Juan',
        chapter: 3,
        verse: 16,
        verseText: 'Porque de tal manera amó Dios…',
        extraBlocks: ['Contexto', 'Reflexión', '  ', 'Aplicación', 'Oración'],
      );
      expect(s, [
        'Juan, capítulo 3, versículo 16',
        'Porque de tal manera amó Dios…',
        'Contexto',
        'Reflexión',
        'Aplicación',
        'Oración',
      ]);
      expect(listenBlockPause, const Duration(milliseconds: 500));
    });

    test('HU-08.6 las velocidades son 0.4, 0.5 y 0.6; lo desconocido cae en Normal', () {
      expect(VoiceSpeed.slow.rate, 0.4);
      expect(VoiceSpeed.normal.rate, 0.5);
      expect(VoiceSpeed.fast.rate, 0.6);
      expect(VoiceSpeed.fromRate(0.6), VoiceSpeed.fast);
      expect(VoiceSpeed.fromRate(null), VoiceSpeed.normal);
      expect(VoiceSpeed.fromRate(0.77), VoiceSpeed.normal);
    });

    test('HU-08.2 prefiere es-CO y si no es-US, es-MX o es-ES', () {
      expect(pickSpanishLocale(['en-US', 'es-ES', 'es-CO', 'es-MX']), 'es-CO');
      expect(pickSpanishLocale(['en-US', 'es-ES', 'es-MX', 'es-US']), 'es-US');
      expect(pickSpanishLocale(['es-ES', 'es-MX']), 'es-MX');
      expect(pickSpanishLocale(['fr-FR', 'es-ES']), 'es-ES');
      expect(pickSpanishLocale(['es_CO', 'es_ES']), 'es_CO');
    });

    test('HU-08.7 sin voz en español no hay idioma elegido', () {
      expect(pickSpanishLocale(['en-US', 'fr-FR', 'pt-BR']), isNull);
      expect(pickSpanishLocale(const []), isNull);
    });
  });
}
