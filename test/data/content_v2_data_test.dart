import 'package:flutter_test/flutter_test.dart';
import 'package:sosiego/data/content/content_repository.dart';
import 'package:sosiego/domain/content_models.dart';
import 'package:sqlite3/sqlite3.dart';

/// Pruebas de datos del spec 10 que pueden correr sobre el asset de la app
/// (hoy una muestra; con el contenido completo se endurecen los mínimos).
void main() {
  late Database db;
  late ContentRepository repo;
  setUpAll(() {
    db = sqlite3.open('assets/db/content.db', mode: OpenMode.readOnly);
    repo = ContentRepository('assets/db/content.db');
  });
  tearDownAll(() {
    db.dispose();
    repo.close();
  });

  test('datos 2: integrity_check ok y sin violaciones de claves', () {
    expect(db.select('PRAGMA integrity_check').first.values.first, 'ok');
    expect(db.select('PRAGMA foreign_key_check'), isEmpty);
  });

  test('datos 3: todo versículo elegible tiene 10 parecidos elegibles', () {
    final bad = db.select(
      'SELECT v.id FROM verses v WHERE v.is_card_eligible = 1 AND '
      '(SELECT COUNT(*) FROM verse_similar s WHERE s.verse_id = v.id) != 10',
    );
    expect(bad, isEmpty);
    final notEligible = db.select(
      'SELECT 1 FROM verse_similar s JOIN verses v ON v.id = s.similar_id '
      'WHERE v.is_card_eligible = 0',
    );
    expect(notEligible, isEmpty);
  });

  test('datos 5: daily_calendar tiene 366 filas e incluye el 02-29', () {
    expect(db.select('SELECT COUNT(*) c FROM daily_calendar').first['c'], 366);
    expect(repo.dailyEntry(DateTime(2028, 2, 29)), isNotNull);
  });

  test('datos 10: FTS5 disponible', () {
    expect(repo.hasFts5, isTrue);
  });

  test('HU-02.2 10 emociones y 12 momentos en orden sort', () {
    expect(repo.themes(kind: ThemeKind.emotion), hasLength(10));
    expect(repo.moments(), hasLength(12));
    final sorts = repo.moments().map((m) => m.sort).toList();
    expect(sorts, [...sorts]..sort());
  });

  test('HU-13.2 la línea de ayuda viene de meta', () {
    expect(repo.meta('help_line_text'), isNotNull);
    expect(repo.meta('help_line_number'), isNotNull);
  });

  test('reflections solo exporta aprobadas (CHECK)', () {
    expect(
      db.select("SELECT 1 FROM reflections WHERE status != 'approved'"),
      isEmpty,
    );
  });
}
