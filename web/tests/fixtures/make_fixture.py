"""Genera una content.db minima con el DDL exacto de la seccion 6 del spec.

Uso:
  python tests/fixtures/make_fixture.py RUTA/content.db                    # muestra pequena
  python tests/fixtures/make_fixture.py RUTA/content.db --synthetic 31100  # prueba de carga

IMPORTANTE: los versiculos de la muestra son solo para probar la web (pueden
tener erratas); NO son la fuente textual de la RV1909. El content.db real lo
genera el pipeline de contenido (frente B).
"""
from __future__ import annotations

import argparse
import sqlite3
import unicodedata
from pathlib import Path

# DDL copiado literalmente de la seccion 6 del spec (content.db).
DDL = """
CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT NOT NULL);
-- claves: translation='RV1909', content_version, built_at, content_hash, source_url

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
"""

# (osis, nombre_es, slug, testamento, capitulos)
BOOKS = [
    ("Gen", "Génesis", "genesis", "AT", 50), ("Exod", "Éxodo", "exodo", "AT", 40),
    ("Lev", "Levítico", "levitico", "AT", 27), ("Num", "Números", "numeros", "AT", 36),
    ("Deut", "Deuteronomio", "deuteronomio", "AT", 34), ("Josh", "Josué", "josue", "AT", 24),
    ("Judg", "Jueces", "jueces", "AT", 21), ("Ruth", "Rut", "rut", "AT", 4),
    ("1Sam", "1 Samuel", "1-samuel", "AT", 31), ("2Sam", "2 Samuel", "2-samuel", "AT", 24),
    ("1Kgs", "1 Reyes", "1-reyes", "AT", 22), ("2Kgs", "2 Reyes", "2-reyes", "AT", 25),
    ("1Chr", "1 Crónicas", "1-cronicas", "AT", 29), ("2Chr", "2 Crónicas", "2-cronicas", "AT", 36),
    ("Ezra", "Esdras", "esdras", "AT", 10), ("Neh", "Nehemías", "nehemias", "AT", 13),
    ("Esth", "Ester", "ester", "AT", 10), ("Job", "Job", "job", "AT", 42),
    ("Ps", "Salmos", "salmos", "AT", 150), ("Prov", "Proverbios", "proverbios", "AT", 31),
    ("Eccl", "Eclesiastés", "eclesiastes", "AT", 12), ("Song", "Cantares", "cantares", "AT", 8),
    ("Isa", "Isaías", "isaias", "AT", 66), ("Jer", "Jeremías", "jeremias", "AT", 52),
    ("Lam", "Lamentaciones", "lamentaciones", "AT", 5), ("Ezek", "Ezequiel", "ezequiel", "AT", 48),
    ("Dan", "Daniel", "daniel", "AT", 12), ("Hos", "Oseas", "oseas", "AT", 14),
    ("Joel", "Joel", "joel", "AT", 3), ("Amos", "Amós", "amos", "AT", 9),
    ("Obad", "Abdías", "abdias", "AT", 1), ("Jonah", "Jonás", "jonas", "AT", 4),
    ("Mic", "Miqueas", "miqueas", "AT", 7), ("Nah", "Nahúm", "nahum", "AT", 3),
    ("Hab", "Habacuc", "habacuc", "AT", 3), ("Zeph", "Sofonías", "sofonias", "AT", 3),
    ("Hag", "Hageo", "hageo", "AT", 2), ("Zech", "Zacarías", "zacarias", "AT", 14),
    ("Mal", "Malaquías", "malaquias", "AT", 4),
    ("Matt", "Mateo", "mateo", "NT", 28), ("Mark", "Marcos", "marcos", "NT", 16),
    ("Luke", "Lucas", "lucas", "NT", 24), ("John", "Juan", "juan", "NT", 21),
    ("Acts", "Hechos", "hechos", "NT", 28), ("Rom", "Romanos", "romanos", "NT", 16),
    ("1Cor", "1 Corintios", "1-corintios", "NT", 16), ("2Cor", "2 Corintios", "2-corintios", "NT", 13),
    ("Gal", "Gálatas", "galatas", "NT", 6), ("Eph", "Efesios", "efesios", "NT", 6),
    ("Phil", "Filipenses", "filipenses", "NT", 4), ("Col", "Colosenses", "colosenses", "NT", 4),
    ("1Thess", "1 Tesalonicenses", "1-tesalonicenses", "NT", 5),
    ("2Thess", "2 Tesalonicenses", "2-tesalonicenses", "NT", 3),
    ("1Tim", "1 Timoteo", "1-timoteo", "NT", 6), ("2Tim", "2 Timoteo", "2-timoteo", "NT", 4),
    ("Titus", "Tito", "tito", "NT", 3), ("Phlm", "Filemón", "filemon", "NT", 1),
    ("Heb", "Hebreos", "hebreos", "NT", 13), ("Jas", "Santiago", "santiago", "NT", 5),
    ("1Pet", "1 Pedro", "1-pedro", "NT", 5), ("2Pet", "2 Pedro", "2-pedro", "NT", 3),
    ("1John", "1 Juan", "1-juan", "NT", 5), ("2John", "2 Juan", "2-juan", "NT", 1),
    ("3John", "3 Juan", "3-juan", "NT", 1), ("Jude", "Judas", "judas", "NT", 1),
    ("Rev", "Apocalipsis", "apocalipsis", "NT", 22),
]

# (libro_id, capitulo, versiculo, texto). Muestra para pruebas de la web.
SAMPLE = [
    (1, 1, 1, "EN el principio crió Dios los cielos y la tierra."),
    (1, 1, 2, "Y la tierra estaba desordenada y vacía, y las tinieblas estaban sobre la faz del abismo, y el Espíritu de Dios se movía sobre la faz de las aguas."),
    (1, 50, 26, "Y murió José de edad de ciento diez años; y lo embalsamaron, y fue puesto en un ataúd en Egipto."),
    (2, 1, 1, "ESTOS son los nombres de los hijos de Israel, que entraron en Egipto con Jacob; cada uno entró con su familia:"),
    (2, 1, 2, "Rubén, Simeón, Leví, y Judá;"),
    (19, 23, 1, "JEHOVÁ es mi pastor; nada me faltará."),
    (19, 23, 2, "En lugares de delicados pastos me hará yacer: Junto á aguas de reposo me pastoreará."),
    (40, 11, 28, "Venid á mí todos los que estáis trabajados y cargados, que yo os haré descansar."),
    (43, 3, 16, "Porque de tal manera amó Dios al mundo, que ha dado á su Hijo unigénito, para que todo aquel que en él creyere, no se pierda, mas tenga vida eterna."),
    (66, 22, 20, "El que da testimonio de estas cosas, dice: Ciertamente voy en breve. Amén, sí, ven, Señor Jesús."),
    (66, 22, 21, "La gracia de nuestro Señor Jesucristo sea con todos vosotros. Amén."),
]


def norm(text: str) -> str:
    """minusculas, sin tildes ni signos (equivale a la normalizacion del spec)."""
    d = unicodedata.normalize("NFD", text.lower())
    d = "".join(c for c in d if unicodedata.category(c) != "Mn")
    return " ".join("".join(c if c.isalnum() else " " for c in d).split())


def make(path: Path, synthetic: int = 0) -> Path:
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        path.unlink()
    db = sqlite3.connect(path)
    db.executescript(DDL)
    db.executemany(
        "INSERT INTO meta VALUES (?, ?)",
        [("translation", "RV1909"), ("content_version", "fixture-1"),
         ("built_at", "2026-10-28T00:00:00Z"), ("content_hash", "fixture"),
         ("source_url", "https://example.invalid/fixture")],
    )
    db.executemany(
        "INSERT INTO books VALUES (?,?,?,?,?,?,?)",
        [(i, o, n, s, t, c, s) for i, (o, n, s, t, c) in enumerate(BOOKS, 1)],
    )
    rows = list(SAMPLE)
    if synthetic:
        # Reparte `synthetic` versiculos de relleno en los 66 libros, para medir tiempos.
        per_book = max(1, synthetic // 66)
        for b in range(1, 67):
            for k in range(per_book):
                ch, v = k // 30 + 1, k % 30 + 1
                rows.append((b, ch, v,
                             f"Versículo de relleno número {k + 1} del libro {b}, para la prueba de carga. " * 2))
        rows = list({(b, c, v): (b, c, v, t) for b, c, v, t in rows}.values())
    db.executemany(
        "INSERT INTO verses (id, book_id, chapter, verse, text, text_norm) VALUES (?,?,?,?,?,?)",
        [(b * 1_000_000 + c * 1000 + v, b, c, v, t, norm(t)) for b, c, v, t in rows],
    )
    db.execute("INSERT INTO verses_fts(verses_fts) VALUES('rebuild')")
    db.commit()
    db.close()
    return path


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("out", type=Path)
    ap.add_argument("--synthetic", type=int, default=0, help="N versiculos de relleno para prueba de carga")
    a = ap.parse_args()
    print(make(a.out, a.synthetic))
