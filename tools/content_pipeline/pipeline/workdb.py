"""work.db: base de trabajo del pipeline (NO viaja en la app).

Guarda, para poder rehacer solo lo que cambie y explicar el origen de cada texto (spec §5):
la fuente y su licencia, el texto ingerido, y cada salida del modelo con su prompt, modelo,
temperatura y semilla.
"""
from __future__ import annotations

import sqlite3
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_PATH = ROOT / "work" / "work.db"

SCHEMA = """
CREATE TABLE IF NOT EXISTS pmeta (key TEXT PRIMARY KEY, value TEXT NOT NULL);

CREATE TABLE IF NOT EXISTS sources (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  url TEXT NOT NULL,
  license_declared TEXT NOT NULL,        -- lo que la fuente declara (texto literal)
  license_evidence TEXT NOT NULL,        -- donde se leyo (archivo/URL)
  downloaded_at TEXT NOT NULL,           -- ISO 8601 UTC
  sha256 TEXT NOT NULL,
  local_file TEXT NOT NULL,
  verse_count INTEGER NOT NULL,
  chapter_count INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS verses_raw (
  id INTEGER PRIMARY KEY,                -- libro*1000000 + capitulo*1000 + versiculo
  book_id INTEGER NOT NULL,
  chapter INTEGER NOT NULL,
  verse INTEGER NOT NULL,
  text TEXT NOT NULL,
  text_norm TEXT NOT NULL,
  source_id INTEGER NOT NULL REFERENCES sources(id),
  UNIQUE (book_id, chapter, verse)
);

CREATE TABLE IF NOT EXISTS generations (
  id INTEGER PRIMARY KEY,
  stage TEXT NOT NULL,                   -- 'tag' | 'reflection' | 'chapter'
  key TEXT NOT NULL,                     -- p. ej. verse_id o 'verse|kind|tema'
  model TEXT NOT NULL,
  prompt TEXT NOT NULL,
  temperature REAL NOT NULL,
  seed INTEGER NOT NULL,
  response TEXT,                         -- ultima respuesta cruda
  valid INTEGER NOT NULL DEFAULT 0,
  error TEXT,
  attempts INTEGER NOT NULL DEFAULT 1,
  duration_s REAL,
  created_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_gen_stage_key ON generations(stage, key);

CREATE TABLE IF NOT EXISTS verse_scores (
  verse_id INTEGER PRIMARY KEY REFERENCES verses_raw(id),
  card_score REAL NOT NULL,
  generation_id INTEGER REFERENCES generations(id)
);
CREATE TABLE IF NOT EXISTS verse_tags (
  verse_id INTEGER NOT NULL REFERENCES verses_raw(id),
  theme_slug TEXT NOT NULL,
  weight REAL NOT NULL,
  generation_id INTEGER REFERENCES generations(id),
  PRIMARY KEY (verse_id, theme_slug)
);
-- revision por muestra de etiquetas (coincidencia humano vs modelo)
CREATE TABLE IF NOT EXISTS tag_review (
  verse_id INTEGER PRIMARY KEY REFERENCES verses_raw(id),
  model_themes TEXT NOT NULL,            -- 'ansiedad,miedo' (peso >= 0.6)
  human_themes TEXT NOT NULL,
  agree INTEGER NOT NULL,                -- 1 si los conjuntos coinciden
  reviewed_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS similar (
  verse_id INTEGER NOT NULL,
  rank INTEGER NOT NULL,
  similar_id INTEGER NOT NULL,
  score REAL NOT NULL,
  model TEXT NOT NULL,
  PRIMARY KEY (verse_id, rank)
);

CREATE TABLE IF NOT EXISTS moment_candidates (
  moment_slug TEXT NOT NULL,
  verse_id INTEGER NOT NULL REFERENCES verses_raw(id),
  score REAL NOT NULL,
  generation_id INTEGER REFERENCES generations(id),
  selected INTEGER NOT NULL DEFAULT 0,   -- 1 = elegido por la persona
  rank INTEGER,                          -- orden dentro del momento (1..n) al elegir
  PRIMARY KEY (moment_slug, verse_id)
);

CREATE TABLE IF NOT EXISTS chapter_summaries (
  book_id INTEGER NOT NULL,
  chapter INTEGER NOT NULL,
  summary_es TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','approved')),
  generation_id INTEGER REFERENCES generations(id),
  PRIMARY KEY (book_id, chapter)
);

CREATE TABLE IF NOT EXISTS daily_plan (
  month_day TEXT PRIMARY KEY,            -- 'MM-DD', 366 filas
  verse_id INTEGER NOT NULL REFERENCES verses_raw(id)
);

CREATE TABLE IF NOT EXISTS reflections (
  id INTEGER PRIMARY KEY,
  verse_id INTEGER NOT NULL REFERENCES verses_raw(id),
  kind TEXT NOT NULL CHECK (kind IN ('daily','emotion','moment')),
  theme_slug TEXT,
  moment_slug TEXT,
  context_text TEXT NOT NULL DEFAULT '',
  reflection_text TEXT NOT NULL DEFAULT '',
  application_text TEXT NOT NULL DEFAULT '',
  prayer_text TEXT NOT NULL DEFAULT '',
  word_count INTEGER NOT NULL DEFAULT 0,
  sensitive INTEGER NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','approved','rejected')),
  validation_errors TEXT,
  generation_id INTEGER REFERENCES generations(id),
  edited INTEGER NOT NULL DEFAULT 0,
  review_seconds INTEGER NOT NULL DEFAULT 0,
  reviewed_at TEXT,
  notes TEXT
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_reflection_slot
  ON reflections(verse_id, kind, COALESCE(theme_slug,''), COALESCE(moment_slug,''));
CREATE INDEX IF NOT EXISTS idx_refl_status ON reflections(status, kind);

CREATE TABLE IF NOT EXISTS review_log (
  id INTEGER PRIMARY KEY,
  reflection_id INTEGER NOT NULL REFERENCES reflections(id),
  action TEXT NOT NULL,                  -- approved | edited_approved | rejected | skipped
  seconds INTEGER NOT NULL,
  at TEXT NOT NULL
);
"""


def now_iso() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def connect(path: Path | str = DEFAULT_PATH) -> sqlite3.Connection:
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    con = sqlite3.connect(path)
    con.executescript(SCHEMA)
    return con


def get_meta(con: sqlite3.Connection, key: str, default: str | None = None) -> str | None:
    row = con.execute("SELECT value FROM pmeta WHERE key=?", (key,)).fetchone()
    return row[0] if row else default


def set_meta(con: sqlite3.Connection, key: str, value) -> None:
    con.execute("INSERT INTO pmeta(key,value) VALUES (?,?) "
                "ON CONFLICT(key) DO UPDATE SET value=excluded.value", (key, str(value)))
