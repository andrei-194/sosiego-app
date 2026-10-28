"""Construccion y cierre de content.db v2 (lo comparten make_sample_db.py y export.py)."""
from __future__ import annotations

import hashlib
import sqlite3
from datetime import datetime, timezone
from pathlib import Path

from . import books_data, taxonomy

HERE = Path(__file__).resolve().parent.parent
SCHEMA_PATH = HERE / "schema_content.sql"
SCHEMA_VERSION = "2"

# tablas de contenido, con el orden fijo de columnas usado para el hash
HASH_TABLES = [
    ("books", "id"), ("verses", "id"), ("chapters", "book_id, chapter"), ("themes", "id"),
    ("verse_themes", "theme_id, verse_id"), ("moments", "id"),
    ("moment_verses", "moment_id, verse_id"), ("verse_similar", "verse_id, rank"),
    ("reflections", "id"), ("daily_calendar", "month_day"),
]
HASH_META_EXCLUDE = ("content_hash", "built_at")


class ExportError(RuntimeError):
    pass


def create(path: Path) -> sqlite3.Connection:
    path = Path(path)
    if path.exists():
        path.unlink()
    path.parent.mkdir(parents=True, exist_ok=True)
    con = sqlite3.connect(path)
    con.executescript(SCHEMA_PATH.read_text(encoding="utf-8"))
    books_data.insert_books(con)
    return con


def insert_taxonomy(con: sqlite3.Connection) -> tuple[dict[str, int], dict[str, int]]:
    """Inserta themes y moments; devuelve (slug->id de temas, slug->id de momentos)."""
    tid: dict[str, int] = {}
    for i, t in enumerate(taxonomy.THEMES, start=1):
        con.execute("INSERT INTO themes(id,slug,name_es,kind,icon,sort) VALUES (?,?,?,?,?,?)",
                    (i, t.slug, t.name_es, t.kind, t.icon, i))
        tid[t.slug] = i
    mid: dict[str, int] = {}
    for i, m in enumerate(taxonomy.MOMENTS, start=1):
        con.execute("INSERT INTO moments(id,slug,name_es,description,icon,sort) VALUES (?,?,?,?,?,?)",
                    (i, m.slug, m.name_es, m.description, m.icon, i))
        mid[m.slug] = i
    return tid, mid


def set_meta(con: sqlite3.Connection, **kv: str) -> None:
    for k, v in kv.items():
        con.execute("INSERT INTO meta(key,value) VALUES (?,?) "
                    "ON CONFLICT(key) DO UPDATE SET value=excluded.value", (k, str(v)))


def compute_hash(con: sqlite3.Connection) -> str:
    h = hashlib.sha256()
    meta = con.execute("SELECT key, value FROM meta ORDER BY key").fetchall()
    for k, v in meta:
        if k not in HASH_META_EXCLUDE:
            h.update(f"meta|{k}|{v}\n".encode())
    for table, order in HASH_TABLES:
        h.update(f"#{table}\n".encode())
        for row in con.execute(f"SELECT * FROM {table} ORDER BY {order}"):
            h.update(("|".join("" if c is None else repr(c) for c in row) + "\n").encode())
    return h.hexdigest()


def finalize(con: sqlite3.Connection, path: Path, *, content_version: str, source_url: str,
             verse_count_expected: int, is_sample: bool, built_at: str | None = None) -> str:
    """FTS rebuild, meta, hash, integrity_check, foreign_key_check, VACUUM. Devuelve el hash."""
    con.execute("INSERT INTO verses_fts(verses_fts) VALUES('rebuild')")
    set_meta(
        con,
        content_version=content_version,
        built_at=built_at or datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        source_url=source_url,
        verse_count_expected=verse_count_expected,
        is_sample="1" if is_sample else "0",
        schema_version=SCHEMA_VERSION,
    )
    con.commit()
    digest = compute_hash(con)
    set_meta(con, content_hash=digest)
    con.commit()
    res = con.execute("PRAGMA integrity_check").fetchall()
    if res != [("ok",)]:
        raise ExportError(f"integrity_check fallo: {res}")
    fk = con.execute("PRAGMA foreign_key_check").fetchall()
    if fk:
        raise ExportError(f"foreign_key_check fallo: {fk[:5]}")
    con.execute("INSERT INTO verses_fts(verses_fts) VALUES('integrity-check')")
    con.commit()
    con.execute("VACUUM")
    con.close()
    return digest
