-- content.db v2: solo lectura en la app. Esquema EXACTO de la seccion 6 del Spec SDD.
-- Las claves de meta se llenan al construir (ver pipeline/contentdb.py); aqui solo van
-- los valores por defecto que nunca deben quedar sin definir.
PRAGMA journal_mode = DELETE;
PRAGMA foreign_keys = ON;

CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT NOT NULL);
-- claves: translation='RV1909', content_version, built_at, content_hash, source_url,
--         help_line_text, help_line_number (HU-13.2), schema_version,
--         verse_count_expected, is_sample

CREATE TABLE books (
  id        INTEGER PRIMARY KEY,                 -- 1..66
  osis      TEXT NOT NULL UNIQUE,                -- 'John'
  name_es   TEXT NOT NULL,                       -- 'Juan'
  slug      TEXT NOT NULL UNIQUE,                -- 'juan' (para /v/juan-3-16)
  testament TEXT NOT NULL CHECK (testament IN ('AT','NT')),
  chapters  INTEGER NOT NULL,
  aliases   TEXT NOT NULL                        -- 'jn|jua|juan' para buscar por referencia
);

CREATE TABLE verses (
  id               INTEGER PRIMARY KEY,          -- libro*1000000 + capitulo*1000 + versiculo
  book_id          INTEGER NOT NULL REFERENCES books(id),
  chapter          INTEGER NOT NULL,
  verse            INTEGER NOT NULL,
  text             TEXT NOT NULL,
  text_norm        TEXT NOT NULL,                -- minusculas, sin tildes ni signos
  card_score       REAL NOT NULL DEFAULT 0,      -- 0..1: se entiende solo
  is_card_eligible INTEGER NOT NULL DEFAULT 0,
  UNIQUE (book_id, chapter, verse)
);
CREATE INDEX idx_verses_eligible ON verses(id) WHERE is_card_eligible = 1;

CREATE VIRTUAL TABLE verses_fts USING fts5(
  text_norm, content='verses', content_rowid='id',
  tokenize='unicode61 remove_diacritics 2'
);
-- Despues de cargar los versiculos: INSERT INTO verses_fts(verses_fts) VALUES('rebuild');

CREATE TABLE chapters (
  book_id    INTEGER NOT NULL REFERENCES books(id),
  chapter    INTEGER NOT NULL,
  summary_es TEXT NOT NULL,                      -- una linea, revisada
  PRIMARY KEY (book_id, chapter)
);

CREATE TABLE themes (
  id      INTEGER PRIMARY KEY,
  slug    TEXT NOT NULL UNIQUE,                  -- 'ansiedad'
  name_es TEXT NOT NULL,
  kind    TEXT NOT NULL CHECK (kind IN ('emotion','topic')),
  icon    TEXT NOT NULL,
  sort    INTEGER NOT NULL
);
CREATE TABLE verse_themes (                      -- solo pesos >= 0.3
  theme_id INTEGER NOT NULL REFERENCES themes(id),
  verse_id INTEGER NOT NULL REFERENCES verses(id),
  weight   REAL NOT NULL CHECK (weight BETWEEN 0 AND 1),
  PRIMARY KEY (theme_id, verse_id)
) WITHOUT ROWID;
CREATE INDEX idx_verse_themes_weight ON verse_themes(theme_id, weight DESC);

CREATE TABLE moments (
  id INTEGER PRIMARY KEY, slug TEXT NOT NULL UNIQUE, name_es TEXT NOT NULL,
  description TEXT NOT NULL, icon TEXT NOT NULL, sort INTEGER NOT NULL
);
CREATE TABLE moment_verses (
  moment_id INTEGER NOT NULL REFERENCES moments(id),
  verse_id  INTEGER NOT NULL REFERENCES verses(id),
  rank      INTEGER NOT NULL,
  PRIMARY KEY (moment_id, verse_id)
) WITHOUT ROWID;

CREATE TABLE verse_similar (                     -- solo entre versiculos elegibles
  verse_id   INTEGER NOT NULL REFERENCES verses(id),
  rank       INTEGER NOT NULL,                   -- 1..10
  similar_id INTEGER NOT NULL REFERENCES verses(id),
  score      REAL NOT NULL,
  PRIMARY KEY (verse_id, rank)
) WITHOUT ROWID;

CREATE TABLE reflections (
  id               INTEGER PRIMARY KEY,
  verse_id         INTEGER NOT NULL REFERENCES verses(id),
  kind             TEXT NOT NULL CHECK (kind IN ('daily','emotion','moment')),
  theme_id         INTEGER REFERENCES themes(id),   -- si kind = 'emotion'
  moment_id        INTEGER REFERENCES moments(id),  -- si kind = 'moment'
  context_text     TEXT NOT NULL,
  reflection_text  TEXT NOT NULL,
  application_text TEXT NOT NULL,
  prayer_text      TEXT NOT NULL,
  word_count       INTEGER NOT NULL,
  reading_seconds  INTEGER NOT NULL,                -- word_count / 150 * 60
  sensitive        INTEGER NOT NULL DEFAULT 0,
  status           TEXT NOT NULL CHECK (status = 'approved')  -- solo se exportan aprobadas
);
CREATE INDEX idx_reflections_theme  ON reflections(kind, theme_id);
CREATE INDEX idx_reflections_moment ON reflections(kind, moment_id);
CREATE INDEX idx_reflections_verse  ON reflections(verse_id);

CREATE TABLE daily_calendar (                    -- 366 filas, incluye 02-29
  month_day     TEXT PRIMARY KEY,                 -- 'MM-DD'
  verse_id INTEGER NOT NULL REFERENCES verses(id), reflection_id INTEGER REFERENCES reflections(id)
) WITHOUT ROWID;

-- Linea de ayuda (HU-13.2). PLACEHOLDER: NO es un numero real. Verificar con una fuente
-- oficial antes de publicar; `export --release` se niega a exportar mientras diga PLACEHOLDER.
INSERT INTO meta(key, value) VALUES
  ('translation', 'RV1909'),
  ('schema_version', '2'),
  ('help_line_text', 'PLACEHOLDER (a verificar con fuente oficial): texto de la linea de ayuda'),
  ('help_line_number', 'PLACEHOLDER-NO-VERIFICADO');
