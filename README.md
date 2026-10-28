# Sosiego

Versículos de la Biblia (Reina-Valera 1909) en un feed vertical. Android, sin registro, sin conexión.
Spec completa: documento «Spec SDD MVP: App de Versículos».

## Estado: fase 0 (esqueleto)

- Capas: `lib/domain` (Dart puro, probado), `lib/data` (SQLite), `lib/features` (UI).
- `content.db`: se copia del asset al primer arranque y se reemplaza si el asset trae una `content_version` mayor.
- FTS5 verificado en SQLite empaquetado (`sqlite3_flutter_libs`).
- `assets/db/content.db` es de **muestra** (texto ficticio). La base real sale del pipeline.

## Primeros pasos

```bash
# Este repo aún no tiene la carpeta android/. Genérala una sola vez:
flutter create --platforms=android --org app.sosiego --project-name sosiego .

flutter pub get
flutter analyze
flutter test
flutter run
```

Fija la versión de Flutter con FVM (`fvm use stable`) y súbela al repo (`.fvmrc`).
Los números de versión de `pubspec.yaml` son un punto de partida: ejecuta `flutter pub upgrade --major-versions` y deja que `pubspec.lock` fije lo que funcione.

## Datos

```bash
python tools/content_pipeline/make_sample_db.py assets/db/content.db   # regenera la muestra
cd tools/content_pipeline && python -m unittest test_schema -v          # pruebas del esquema
```

Si cambias `schema_content.sql`, actualiza también la sección 6 de la spec.

## Fuentes (pendiente)

Descarga Lora y Atkinson Hyperlegible (licencia OFL) a `assets/fonts/` y descomenta el bloque `fonts:` de `pubspec.yaml`.

## Siguiente (fase 1)

Feed vertical con `FeedSelector`, tarjeta de versículo, búsqueda por referencia (`parseReference`) y texto (FTS5), favoritos en `user.db`.
