# Pruebas de calidad: cómo correrlas (spec, sección 10)

Entorno: `C:\Users\andre\AppData\Local\Pub\Cache\bin\fvm.bat flutter ...` (no el Flutter global) y `C:\Python312\python.exe`.

| Qué | Comando |
| --- | --- |
| Todas las pruebas + cobertura | `fvm flutter test --coverage` |
| Cobertura de `lib/domain/` (meta 90 %) | `python tools/coverage_domain.py --verbose` (falla bajo 90 %) |
| Trazabilidad HU a prueba | `python -X utf8 tools/trace.py` (`--strict` también falla con pendientes; `--json`) |
| Casos compartidos de normalización | `test/domain/normalize_shared_cases_test.dart` lee `tools/shared/normalize_cases.json` |
| Golden (todos) | `fvm flutter test test/golden` |
| Regenerar golden | `fvm flutter test --update-goldens test/golden/screens_golden_test.dart` (el feed: `.../feed_golden_test.dart`) |

## Trazabilidad

`tools/trace.py` lee los criterios `N.` de cada `### HU-NN` del spec y busca `HU-NN.M` en los nombres de prueba de `test/`, `integration_test/` y `tools/content_pipeline/tests/`. Falla si un criterio no tiene prueba ni registro, si una prueba cita un ID inexistente o si el registro está mal formado. Los criterios de medición o revisión manual se registran en `tools/trace_registry.json` (`tipo`, `resultado` ok o pendiente, `detalle`); el registro manda sobre las pruebas, y una cita solo en `integration_test/` avisa porque necesita dispositivo.

## Golden

- Viven en `test/golden/goldens/`, etiquetados `golden` (`dart_test.yaml`). Cargan las fuentes reales (Lora, Atkinson, Roboto y Material Icons del SDK) con `loadGoldenFonts()`; sin eso flutter_test dibuja bloques.
- **Se generaron en Windows.** El spec exige Linux en CI: hay que regenerarlos allí una vez y versionar esos PNG; en Windows pueden diferir por antialiasing.
- Los del feed usan `?parecidos=43003016` (orden fijo) y se generaron con la UI intermedia del rediseño: regenerarlos y revisarlos a ojo cuando el rediseño termine.
- Limitación: el `SegmentedButton` de Guardados se dibuja como bloque porque su `TextStyle` no fija `fontFamily` (ver hallazgos en el informe).

## Integración y rendimiento (emulador `sosiego_pixel`)

Antes: `mkdir /d/tmp/sosiego_device.lock` (candado; `rmdir` al terminar), emulador encendido con `ANDROID_AVD_HOME=D:\dev\caches\android-avd`.

```
powershell -File tools\run_integration.ps1 offline      # modo avión + flujo completo (HU-01.5)
powershell -File tools\run_integration.ps1 performance  # flutter drive --profile: cuadros lentos, búsqueda, chip
powershell -File tools\run_integration.ps1 startup      # am start -W: arranque en frío (< 2000 ms)
```

Los objetivos (arranque < 2 s, 5 % de cuadros > 16 ms, búsqueda < 200 ms, chip < 300 ms) son del dispositivo físico de referencia; en emulador son orientativos. Anotar el resultado en `tools/trace_registry.json` (`resultado: ok`) con la cifra en `detalle`.
