import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

/// Copia `content.db` del asset al directorio de documentos en el primer
/// arranque y lo reemplaza cuando el asset trae una `content_version` mayor.
class ContentDbInstaller {
  ContentDbInstaller({
    required this.loadAsset,
    required this.targetDir,
    this.fileName = 'content.db',
  });

  /// Lee los bytes del asset (en la app: `rootBundle.load`).
  final Future<Uint8List> Function() loadAsset;
  final String targetDir;
  final String fileName;

  String get targetPath => p.join(targetDir, fileName);

  /// Garantiza que haya una base válida e instalada. Devuelve su ruta.
  Future<String> ensureInstalled() async {
    await Directory(targetDir).create(recursive: true);
    final bytes = await loadAsset();
    final bundled = _versionOfBytes(bytes);
    final installed = _versionOfFile(targetPath);
    if (installed == null || isNewer(bundled, installed)) {
      await _atomicWrite(bytes);
    }
    return targetPath;
  }

  Future<void> _atomicWrite(Uint8List bytes) async {
    final tmp = File('$targetPath.tmp');
    await tmp.writeAsBytes(bytes, flush: true);
    await tmp.rename(targetPath);
  }

  String? _versionOfFile(String path) {
    final file = File(path);
    if (!file.existsSync()) return null;
    try {
      final db = sqlite3.open(path, mode: OpenMode.readOnly);
      try {
        return _readVersion(db);
      } finally {
        db.dispose();
      }
    } on SqliteException {
      return null; // base corrupta: se reinstala
    }
  }

  String _versionOfBytes(Uint8List bytes) {
    final tmp = File(p.join(targetDir, '.probe-$fileName'));
    tmp.writeAsBytesSync(bytes, flush: true);
    try {
      final db = sqlite3.open(tmp.path, mode: OpenMode.readOnly);
      try {
        return _readVersion(db) ??
            (throw StateError('content.db sin meta.content_version'));
      } finally {
        db.dispose();
      }
    } finally {
      tmp.deleteSync();
    }
  }

  String? _readVersion(Database db) {
    final rows = db.select(
      "SELECT value FROM meta WHERE key = 'content_version'",
    );
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  /// Compara versiones tipo `1.2.3` o `0.0.1-sample` (se ignora el sufijo).
  static bool isNewer(String candidate, String current) {
    List<int> parts(String v) =>
        v.split('-').first.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final a = parts(candidate);
    final b = parts(current);
    for (var i = 0; i < 3; i++) {
      final x = i < a.length ? a[i] : 0;
      final y = i < b.length ? b[i] : 0;
      if (x != y) return x > y;
    }
    return false;
  }
}
