import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sosiego/data/content/content_db_installer.dart';
import 'package:sosiego/data/content/content_repository.dart';
import 'package:sosiego/domain/content_models.dart';
import 'package:sqlite3/sqlite3.dart';

/// Usa el content.db de muestra del repo como "asset" y el SQLite del sistema.
Uint8List _sampleBytes() => File('assets/db/content.db').readAsBytesSync();

void main() {
  late Directory tmp;

  setUp(() => tmp = Directory.systemTemp.createTempSync('sosiego_test'));
  tearDown(() => tmp.deleteSync(recursive: true));

  ContentDbInstaller installer() => ContentDbInstaller(
    targetDir: tmp.path,
    loadAsset: () async => _sampleBytes(),
  );

  test('primer arranque copia la base', () async {
    final path = await installer().ensureInstalled();
    expect(File(path).existsSync(), isTrue);
    final repo = ContentRepository(path);
    addTearDown(repo.close);
    expect(repo.contentVersion, isNotEmpty);
  });

  test('FTS5 funciona y busca sin tildes', () async {
    final repo = ContentRepository(await installer().ensureInstalled());
    addTearDown(repo.close);
    expect(repo.hasFts5, isTrue);
    // «Hay descanso para quien confía en Dios» lleva tilde en el texto.
    final found = repo.searchText('confia').map((v) => v.reference);
    expect(found, contains('1 Samuel 16:7'));
  });

  test('instala el esquema v2: libros, temas, momentos y calendario', () async {
    final repo = ContentRepository(await installer().ensureInstalled());
    addTearDown(repo.close);
    expect(repo.themes(kind: ThemeKind.emotion), hasLength(10));
    expect(repo.moments(), hasLength(12));
    expect(repo.meta('schema_version'), '2');
    expect(repo.dailyVerseFor(DateTime(2028, 2, 29)), isNotNull);
    expect(repo.byId(43003016)!.bookSlug, 'juan');
  });

  test(
    'reemplaza una copia de otro esquema aunque la versión no sea menor',
    () async {
      final dir = Directory(tmp.path)..createSync(recursive: true);
      final old = sqlite3.open(p.join(dir.path, 'content.db'));
      old.execute(
        'CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
      );
      old.execute("INSERT INTO meta VALUES ('content_version', '99.0.0')");
      old.dispose();
      final repo = ContentRepository(await installer().ensureInstalled());
      addTearDown(repo.close);
      expect(repo.meta('schema_version'), '2');
    },
  );

  test('no reescribe si la versión instalada es igual', () async {
    final path = await installer().ensureInstalled();
    final before = File(path).lastModifiedSync();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await installer().ensureInstalled();
    expect(File(path).lastModifiedSync(), before);
  });

  test('reinstala si el archivo está corrupto', () async {
    File(p.join(tmp.path, 'content.db')).writeAsStringSync('no soy sqlite');
    final path = await installer().ensureInstalled();
    final repo = ContentRepository(path);
    addTearDown(repo.close);
    expect(repo.hasFts5, isTrue);
  });

  group('isNewer', () {
    test('compara versiones numéricas', () {
      expect(ContentDbInstaller.isNewer('1.0.1', '1.0.0'), isTrue);
      expect(ContentDbInstaller.isNewer('1.10.0', '1.9.0'), isTrue);
      expect(ContentDbInstaller.isNewer('1.0.0', '1.0.0'), isFalse);
      expect(ContentDbInstaller.isNewer('0.9.9', '1.0.0'), isFalse);
    });

    test('ignora el sufijo', () {
      expect(ContentDbInstaller.isNewer('0.0.2-sample', '0.0.1'), isTrue);
    });
  });
}
