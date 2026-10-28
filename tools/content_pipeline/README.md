# Pipeline de contenido de Sosiego (offline)

Convierte la Reina-Valera 1909 en `content.db` v2 (esquema exacto de la sección 6 del
`Spec SDD MVP App de Versículos.md`). Solo necesita Python 3.12 en tu computador; Ollama es
opcional hasta la etapa de etiquetado. Nada de lo que hay aquí toca `lib/`, `assets/` ni `pubspec.yaml`.

## Puesta en marcha

```powershell
cd tools\content_pipeline
C:\Python312\python.exe -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
.\.venv\Scripts\python.exe -m pytest              # 239 pruebas; usa la muestra v2 por defecto
```

Las etapas se lanzan con `python -I run.py <etapa> ...` (modo aislado: Python no carga módulos del
directorio actual ni de variables de entorno mientras lee archivos descargados).

## Mapa de archivos

| Archivo | Para qué |
| --- | --- |
| `schema_content.sql` | DDL de `content.db` v2, copia exacta de la sección 6 (+ claves `help_line_*` en `meta`) |
| `pipeline/books_data.py` | **Única fuente de verdad** de los 66 libros: osis, nombre, slug, testamento, capítulos, alias |
| `pipeline/normalize.py` | Normalización de texto (minúsculas, sin tildes/ñ ni signos); casos compartidos con Dart en `tools/shared/normalize_cases.json` |
| `pipeline/taxonomy.py` | 10 emociones, 5 temas de apoyo, 12 momentos, umbrales y cuotas |
| `pipeline/editorial.py` | Guía editorial (§5) para el prompt, términos prohibidos y validadores de reflexiones |
| `pipeline/contentdb.py` | Construcción y cierre de `content.db` (FTS `rebuild`, hash, integrity, FK, VACUUM) |
| `pipeline/workdb.py` | Esquema de `work.db` (fuente, texto ingerido, cada generación con prompt/modelo/temperatura/semilla) |
| `pipeline/{ingest,tag,similar,moments,reflections,review,export,quality}.py` | Etapas, cada una con CLI |
| `make_sample_db.py` | Genera `out/content_v2.sample.db` (muestra ficticia, determinista) |
| `tests/` | Pruebas de datos (las 10 de §10), del esquema, de libros, de normalización y de las etapas |
| `data/rv1909_expected.json` | Conteo de versículos **fijado en la ingesta** (lo lee la prueba de datos 1) |
| `work/` | `work.db`, descargas (`work/raw/<fecha>/`), informes de calidad. No se versiona |
| `out/` | Salidas: muestra y `content.db` exportado. No se versiona |

## Etapas y comandos

```powershell
$py = ".\.venv\Scripts\python.exe"

# 1. Ingesta (descarga a un directorio NUEVO y vacío; aborta si la fuente no declara dominio público)
& $py -I run.py ingest --raw-dir work\raw\2026-10-28
#    ya descargado:  ... --zip-only        verificación cruzada:  --cross-check work\raw\<otra>\spaRV1909_vpl.zip
#    fijar el conteo: --pin  (reescribe data\rv1909_expected.json)

# 2. Etiquetado (Ollama; el modelo debe estar en `ollama list`, el pipeline NO descarga modelos)
& $py -I run.py tag --model qwen2.5:7b --sample 50          # muestra reproducible
& $py -I run.py tag --model qwen2.5:7b                      # todos los versículos pendientes (reanudable)
& $py -I run.py tag --model qwen2.5:7b --task chapters      # resumen de una línea por capítulo (borrador)

# 3. Parecidos (necesita: pip install sentence-transformers; modelo BAAI/bge-m3, MIT)
& $py -I run.py similar --model BAAI/bge-m3                 # `--backend hash` para ensayar sin modelo

# 4. Momentos: el modelo propone, tú eliges 15-20
& $py -I run.py moments candidates --model qwen2.5:7b
& $py -I run.py moments choose --moment antes-de-dormir     # interactivo (uno por momento)

# 5. Reflexiones: plan (366 días del calendario + 685 plazas) y borradores
& $py -I run.py reflections plan
& $py -I run.py reflections generate --model qwen2.5:7b --limit 20
& $py -I run.py reflections status

# 6. Revisión humana (100% de las reflexiones; solo `approved` se exporta)
& $py -I run.py review reflections --only-valid             # a aprobar / e editar / s sensible / r rechazar / k saltar
& $py -I run.py review stats                                 # tiempos y ediciones
& $py -I run.py review tags --sample 300                     # revisión de etiquetas por muestra
& $py -I run.py review tags-report                           # % de coincidencia humano vs modelo

# 7. Exportación -> out\content.db + pruebas de datos (nunca escribe en assets\)
& $py -I run.py export --out out\content.db
& $py -I run.py export --out out\content.db --release --help-line-text "..." --help-line-number "..."
```

`export` hace: tablas, índices, `INSERT INTO verses_fts(verses_fts) VALUES('rebuild')`,
`PRAGMA integrity_check`, `PRAGMA foreign_key_check`, `VACUUM`, `meta.content_version`
(entero creciente; por defecto `AAAAMMDDHHMM` UTC), `meta.content_hash` (SHA-256 del contenido) y corre
`tests/test_data_invariants.py` contra el archivo. Si falla, sale con código 1: no empaquetar.

### Prueba de calidad del modelo (50 versículos, spec §5)

```powershell
& $py -I run.py quality --model qwen2.5:7b --n 50 --time-budget-min 100
```

Trabaja en `work\quality_<modelo>.db` y escribe `work\quality_report_<modelo>.json`. Mide JSON
válido, citas ajenas, términos prohibidos, palabras fuera de rango y tiempos (con estimación del total).
El criterio (c) "80% se acepta sin reescritura mayor" es humano: el informe da un sustituto automático
(pasa todos los validadores al primer intento) y la muestra queda lista para leerla con `review`.

## Pruebas

```powershell
& $py -m pytest                                  # contra la muestra v2 (se reconstruye en un temporal)
& $py -m pytest --content-db out\content.db      # contra cualquier content.db (o SOSIEGO_CONTENT_DB=ruta)
$env:SOSIEGO_RELEASE = "1"; & $py -m pytest --content-db out\content.db   # añade las puertas de publicación
```

Las 10 pruebas de la §10 están en `tests/test_data_invariants.py` (`test_01_...` a `test_10_...`).
Puertas `release`: línea de ayuda real (no `PLACEHOLDER`), 685 reflexiones aprobadas, no es muestra.

**Normalización compartida con Dart.** `tools/shared/normalize_cases.json` es la lista de casos
(tildes, ñ, mayúsculas, signos, espacios). La prueba Python (`tests/test_normalize.py`) ya la usa.
**Pendiente:** la prueba Dart equivalente (la añadirá el agente de la app) debe leer el mismo JSON y
comprobar `normalize(input) == expected` con la regla: minúsculas → NFD → quitar marcas combinantes
(la `ñ` pasa a `n`, igual que FTS5 `remove_diacritics 2`) → todo lo que no sea letra o número pasa a
espacio → colapsar y recortar espacios.

## Fuente y licencia (ingesta real, 28-oct-2026)

- Fuente: eBible.org, `spaRV1909` (Santa Biblia, Reina Valera 1909), USFM. URL:
  `https://ebible.org/Scriptures/spaRV1909_usfm.zip`.
- Licencia declarada por la fuente: **Public Domain / Dominio Público**, en dos lugares verificables:
  `copr.htm` dentro del zip y la ficha `https://ebible.org/find/details.php?id=spaRV1909` ("public domain").
  La ingesta aborta si no encuentra esa declaración. Evidencia, URL, fecha y SHA-256 quedan en `work.db` (`sources`).
- Conteo: 31.102 entradas `\v` en la fuente; **18 vienen vacías** (cambios de versificación de la RV1909,
  p. ej. Números 12:16; también vacías en el formato VPL de la misma fuente). Se cargan **31.084 versículos**
  y 1.189 capítulos. Ese 31.084 es el conteo fijado (`data/rv1909_expected.json`, con la lista de las 18).
  Consecuencia para la app: **hay saltos en la numeración** de versículos (p. ej. Job 38:38 → 38:42); "siguiente
  versículo" debe usar el siguiente existente, no `verse + 1`.
- Verificación sin pérdidas: parseo USFM (palabras con etiquetas Strong, `\add`, `\+w` anidado) comparado verso a
  verso con el formato VPL de la misma fuente: 0 diferencias en los 31.102 versículos. Capítulos y versículos contiguos.

## Cambios del esquema respecto a la fase 0 (lo que debe seguir el código Dart)

`content.db` v2 (`meta.schema_version = '2'`). Todo lo siguiente es el esquema de la §6 tal cual:

| Tabla | Columnas v2 | Cambio frente a la fase 0 |
| --- | --- | --- |
| `meta` | `key, value` | + `help_line_text`, `help_line_number` (PLACEHOLDER hasta verificar), `schema_version`, `verse_count_expected`, `is_sample` |
| `books` | `id, osis, name_es, slug, testament, chapters, aliases` | antes `name, abbr, chapter_count`; ahora `aliases` = `'jn\|jua\|juan'` |
| `verses` | `id, book_id, chapter, verse, text, text_norm, card_score, is_card_eligible` | igual; sin triggers; índice parcial `idx_verses_eligible ON verses(id) WHERE is_card_eligible = 1`; FTS se llena con `rebuild` |
| `chapters` | `book_id, chapter, summary_es` | antes `verse_count` |
| `themes` | `id INTEGER, slug, name_es, kind ('emotion'\|'topic'), icon, sort` | antes `id TEXT, label, emoji` |
| `verse_themes` | `theme_id, verse_id, weight` (WITHOUT ROWID, PK `(theme_id, verse_id)`) | `theme_id` ahora entero; solo pesos ≥ 0.3 |
| `moments` | `id INTEGER, slug, name_es, description, icon, sort` | antes `id TEXT, label` |
| `moment_verses` | `moment_id, verse_id, rank` (WITHOUT ROWID) | + `rank` |
| `verse_similar` | `verse_id, rank, similar_id, score` (WITHOUT ROWID) | + `score`; solo entre elegibles |
| `reflections` | `id, verse_id, kind, theme_id, moment_id, context_text, reflection_text, application_text, prayer_text, word_count, reading_seconds, sensitive, status` | antes `title, body, prayer`; ahora 4 bloques y `theme_id`/`moment_id`; `status` solo `'approved'` |
| `daily_calendar` | `month_day, verse_id, reflection_id` (WITHOUT ROWID) | igual (366 filas) |

Taxonomía: temas `id` 1..15 (10 emociones `kind='emotion'` en orden `sort`, luego 5 `topic`), momentos `id` 1..12.
Slugs de emoción: ansiedad, tristeza, gratitud, miedo, soledad, perdon, esperanza, cansancio, enojo, duda.
Slugs de momento: al-despertar, antes-de-dormir, antes-de-comer, antes-de-un-viaje, antes-de-una-cita-medica,
familiar-enfermo, entrevista-o-examen, problemas-de-dinero, perdida-de-un-ser-querido, nacimiento-o-cumpleanos,
reconciliarse, dar-gracias.

`meta.content_version` es un **entero como texto** (muestra: `"1"`; real: `AAAAMMDDHHMM`): la app debe compararlo como número.

## Línea de ayuda (HU-13)

`meta.help_line_text` y `meta.help_line_number` salen con valores **PLACEHOLDER** deliberadamente: no se
inventa ningún número. Verificarlos con una fuente oficial antes de publicar y pasarlos con `export --release`
(que se niega a exportar mientras diga PLACEHOLDER).

## Decisiones y límites conocidos

- Resúmenes de capítulo (`chapters.summary_es`, NOT NULL, "una línea, revisada"): el spec no los asigna a una etapa.
  `tag --task chapters` genera borradores; no hay CLI de revisión propio, así que quedan en `draft` y el export
  escribe `''` salvo que estén `approved` (con `--strict`/`--release` falla). Decidir si se revisan o se posponen.
- `daily_calendar` usa un año bisiesto de referencia; la reflexión del 02-29 puede ser nula (el spec fija 365 reflexiones del día).
- El umbral de elegibilidad es 0.6 (spec §4) y se calibra con la muestra revisada a mano.
- Los términos prohibidos (`editorial.py`) son una primera lista; se afina con la revisión. El registro tú/usted
  solo produce advertencia (el versículo citado puede traer «tu»).
- Ollama usa `format` con JSON Schema (salida estructurada), `temperature 0.2` y `seed 42` (+1 por reintento, el valor
  usado queda guardado).

## Resultado de la prueba de calidad (qwen2.5:7b, 50 versículos, 28-oct-2026)

Informe completo: `work/quality_report_qwen2_5_7b.json`; muestra en `work/quality_qwen2_5_7b.db`.

| Criterio | Resultado |
| --- | --- |
| (a) JSON válido, etiquetas | 100 % (50/50, a la primera) |
| (a) JSON válido, reflexiones | 100 % (46/46, con salida estructurada) |
| (b) reflexiones con cita ajena | 0 |
| (c) sustituto automático: pasa validadores al primer intento | 23,9 %; tras reintentos 91,3 % |
| Términos prohibidos en borradores | 3 |
| Palabras fuera de rango | 1 |
| Tiempos | etiqueta 14,1 s, reflexión 55,5 s (1,89 intentos de media) |
| Estimación total | etiquetar todos los versículos ~121,7 h; 685 reflexiones ~10,6 h |

**No determinado:** el criterio (c) real ("80 % se acepta sin reescritura mayor") requiere lectura humana de
las 46 reflexiones (`review reflections` sobre `work/quality_qwen2_5_7b.db`). El 23,9 % al primer intento es solo un
sustituto automático estricto; no es una medida de calidad editorial. Etiquetar los 31.084 versículos con este modelo
en CPU es poco práctico (~122 h): conviene etiquetar solo candidatos pre-filtrados o usar un modelo/GPU más rápido.
