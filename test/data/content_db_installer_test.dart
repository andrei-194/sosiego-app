import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sosiego/data/content/content_db_installer.dart';
import 'package:sosiego/data/content/content_repository.dart';

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
    expect(repo.search('confia').map((v) => v.reference), ['Proverbios 3:5']);
  });

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
