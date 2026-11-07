import 'package:flutter_test/flutter_test.dart';
import 'package:sosiego/data/content/content_repository.dart';
import 'package:sosiego/data/content/use_case_impls.dart';

/// HU-06.2 (orden de resolución) y medición de HU-06.8 sobre el asset.
/// El tiempo se mide en el PC con la muestra de la base: sirve de alarma contra
/// regresiones, no sustituye la medición en el dispositivo de referencia.
void main() {
  late ContentRepository repo;
  late SearchVersesImpl search;
  setUpAll(() {
    repo = ContentRepository('assets/db/content.db');
    search = SearchVersesImpl(repo);
  });
  tearDownAll(() => repo.close());

  test(
    'HU-06.2 (a) una referencia gana: lista versículos, sin atajo de tema',
    () {
      final r = search.call('Juan 3:16');
      expect(r.reference, isNotNull);
      expect(r.referenceVerses, isNotEmpty);
      expect(r.topic, isNull);
      expect(r.textMatches, isEmpty);
    },
  );

  test(
    'HU-06.2 (b) un tema por nombre da el atajo, sin tildes ni mayúsculas',
    () {
      final r = search.call('ANSIEDAD');
      expect(r.reference, isNull);
      expect(r.topic, isNotNull);
      expect(r.topic!.slug, 'ansiedad');
      expect(search.call('Antes de dormir').topic?.isMoment, isTrue);
    },
  );

  test('HU-06.2 (c) otra entrada se busca como texto', () {
    final r = search.call('escucha');
    expect(r.reference, isNull);
    expect(r.topic, isNull);
    expect(r.textMatches, isNotEmpty);
    expect(r.textMatches.length, lessThanOrEqualTo(30));
  });

  test(
    'HU-06.8 medición: búsqueda de texto en menos de 200 ms (muestra, PC)',
    () {
      search.call('escucha'); // calienta
      final sw = Stopwatch()..start();
      for (final q in [
        'escu',
        'senor escucha',
        'sencillez',
        'ansiedad',
        'juan 3 16',
      ]) {
        search.call(q);
      }
      sw.stop();
      final perQuery = sw.elapsedMilliseconds / 5;
      // ignore: avoid_print
      print(
        'MEDICION búsqueda: ${perQuery.toStringAsFixed(1)} ms por consulta',
      );
      expect(perQuery, lessThan(200));
    },
  );
}
