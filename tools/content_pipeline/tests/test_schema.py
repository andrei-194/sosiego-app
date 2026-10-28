"""Pruebas del esquema content.db v2 (spec §6). Migrado de unittest a pytest.

Trabajan sobre una base vacia creada SOLO con schema_content.sql (fixture `schema_con`), salvo
las dos ultimas, que usan la muestra.
"""
import sqlite3

import pytest

from pipeline import books_data, contentdb, normalize

# columnas exactas del spec §6: tabla -> [(nombre, tipo, notnull, pk)]
EXPECTED_COLUMNS = {
    "meta": [("key", "TEXT", 0, 1), ("value", "TEXT", 1, 0)],
    "books": [("id", "INTEGER", 0, 1), ("osis", "TEXT", 1, 0), ("name_es", "TEXT", 1, 0), ("slug", "TEXT", 1, 0),
              ("testament", "TEXT", 1, 0), ("chapters", "INTEGER", 1, 0), ("aliases", "TEXT", 1, 0)],
    "verses": [("id", "INTEGER", 0, 1), ("book_id", "INTEGER", 1, 0), ("chapter", "INTEGER", 1, 0),
               ("verse", "INTEGER", 1, 0), ("text", "TEXT", 1, 0), ("text_norm", "TEXT", 1, 0),
               ("card_score", "REAL", 1, 0), ("is_card_eligible", "INTEGER", 1, 0)],
    "chapters": [("book_id", "INTEGER", 1, 1), ("chapter", "INTEGER", 1, 2), ("summary_es", "TEXT", 1, 0)],
    "themes": [("id", "INTEGER", 0, 1), ("slug", "TEXT", 1, 0), ("name_es", "TEXT", 1, 0),
               ("kind", "TEXT", 1, 0), ("icon", "TEXT", 1, 0), ("sort", "INTEGER", 1, 0)],
    "verse_themes": [("theme_id", "INTEGER", 1, 1), ("verse_id", "INTEGER", 1, 2), ("weight", "REAL", 1, 0)],
    "moments": [("id", "INTEGER", 0, 1), ("slug", "TEXT", 1, 0), ("name_es", "TEXT", 1, 0),
                ("description", "TEXT", 1, 0), ("icon", "TEXT", 1, 0), ("sort", "INTEGER", 1, 0)],
    "moment_verses": [("moment_id", "INTEGER", 1, 1), ("verse_id", "INTEGER", 1, 2), ("rank", "INTEGER", 1, 0)],
    "verse_similar": [("verse_id", "INTEGER", 1, 1), ("rank", "INTEGER", 1, 2), ("similar_id", "INTEGER", 1, 0),
                      ("score", "REAL", 1, 0)],
    "reflections": [("id", "INTEGER", 0, 1), ("verse_id", "INTEGER", 1, 0), ("kind", "TEXT", 1, 0),
                    ("theme_id", "INTEGER", 0, 0), ("moment_id", "INTEGER", 0, 0),
                    ("context_text", "TEXT", 1, 0), ("reflection_text", "TEXT", 1, 0),
                    ("application_text", "TEXT", 1, 0), ("prayer_text", "TEXT", 1, 0),
                    ("word_count", "INTEGER", 1, 0), ("reading_seconds", "INTEGER", 1, 0),
                    ("sensitive", "INTEGER", 1, 0), ("status", "TEXT", 1, 0)],
    "daily_calendar": [("month_day", "TEXT", 1, 1), ("verse_id", "INTEGER", 1, 0),
                       ("reflection_id", "INTEGER", 0, 0)],
}


@pytest.mark.parametrize("table", sorted(EXPECTED_COLUMNS))
def test_columnas_exactas_segun_spec(schema_con, table):
    cols = [(r[1], r[2], r[3], r[5]) for r in schema_con.execute(f"PRAGMA table_info({table})")]
    expected = EXPECTED_COLUMNS[table]
    # PRAGMA da notnull=0 para 'INTEGER PRIMARY KEY' y 'key TEXT PRIMARY KEY': el spec tampoco lo exige
    norm = [(n, t, nn if pk == 0 else EXPECTED_COLUMNS[table][i][2], pk) for i, (n, t, nn, pk) in enumerate(cols)]
    assert norm == expected


def test_solo_las_tablas_del_spec(schema_con):
    names = {r[0] for r in schema_con.execute(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'verses_fts_%'")}
    assert names == set(EXPECTED_COLUMNS) | {"verses_fts"}


@pytest.mark.parametrize("table", ["verse_themes", "moment_verses", "verse_similar", "daily_calendar"])
def test_tablas_without_rowid(schema_con, table):
    row = next(r for r in schema_con.execute("PRAGMA table_list") if r[1] == table)
    assert row[4] == 1, f"{table} debe ser WITHOUT ROWID"


@pytest.mark.parametrize("table", ["meta", "books", "verses", "chapters", "themes", "moments", "reflections"])
def test_tablas_con_rowid(schema_con, table):
    row = next(r for r in schema_con.execute("PRAGMA table_list") if r[1] == table)
    assert row[4] == 0


def test_indices_del_spec(schema_con):
    idx = {r[0]: r[1] for r in schema_con.execute("SELECT name, sql FROM sqlite_master WHERE type='index' AND sql IS NOT NULL")}
    assert set(idx) == {"idx_verses_eligible", "idx_verse_themes_weight", "idx_reflections_theme",
                        "idx_reflections_moment", "idx_reflections_verse"}
    assert "WHERE is_card_eligible = 1" in idx["idx_verses_eligible"]      # indice PARCIAL
    assert "weight DESC" in idx["idx_verse_themes_weight"]
    plan = " ".join(str(r) for r in schema_con.execute(
        "EXPLAIN QUERY PLAN SELECT id FROM verses WHERE is_card_eligible = 1 ORDER BY id"))
    assert "idx_verses_eligible" in plan


def test_sin_triggers_el_fts_se_llena_con_rebuild(schema_con):
    assert schema_con.execute("SELECT COUNT(*) FROM sqlite_master WHERE type='trigger'").fetchone()[0] == 0
    books_data.insert_books(schema_con)
    schema_con.execute("INSERT INTO verses VALUES (43003016, 43, 3, 16, 'Amó Dios al mundo', ?, 0.9, 1)",
                       (normalize.normalize("Amó Dios al mundo"),))
    assert schema_con.execute("SELECT COUNT(*) FROM verses_fts WHERE verses_fts MATCH 'amo'").fetchone()[0] == 0
    schema_con.execute("INSERT INTO verses_fts(verses_fts) VALUES('rebuild')")
    assert schema_con.execute("SELECT rowid FROM verses_fts WHERE verses_fts MATCH 'amo'").fetchall() == [(43003016,)]


def test_fts_tokenizer_sin_tildes_ni_enie(schema_con):
    books_data.insert_books(schema_con)
    t = "Confía en el Señor con todo tu corazón"
    schema_con.execute("INSERT INTO verses VALUES (20003005, 20, 3, 5, ?, ?, 0.8, 1)", (t, normalize.normalize(t)))
    schema_con.execute("INSERT INTO verses_fts(verses_fts) VALUES('rebuild')")
    for q in ("confia", "senor", "corazon", "conf*"):
        assert schema_con.execute("SELECT rowid FROM verses_fts WHERE verses_fts MATCH ?", (q,)).fetchall() == [(20003005,)]


def test_fts5_disponible(schema_con):
    assert schema_con.execute("SELECT sqlite_compileoption_used('ENABLE_FTS5')").fetchone()[0] == 1


def test_reflexion_solo_aprobada(schema_con):
    books_data.insert_books(schema_con)
    schema_con.execute("INSERT INTO verses VALUES (43003016, 43, 3, 16, 't', 't', 0.9, 1)")
    ok = "INSERT INTO reflections(verse_id,kind,context_text,reflection_text,application_text,prayer_text,word_count,reading_seconds,status) VALUES (43003016,'daily','c','r','a','p',100,40,?)"
    schema_con.execute(ok, ("approved",))
    for bad in ("draft", "rejected", "pending"):
        with pytest.raises(sqlite3.IntegrityError):
            schema_con.execute(ok, (bad,))


def test_reflexion_kind_y_sensitive_por_defecto(schema_con):
    books_data.insert_books(schema_con)
    schema_con.execute("INSERT INTO verses VALUES (43003016, 43, 3, 16, 't', 't', 0.9, 1)")
    with pytest.raises(sqlite3.IntegrityError):
        schema_con.execute("INSERT INTO reflections(verse_id,kind,context_text,reflection_text,application_text,prayer_text,word_count,reading_seconds,status) VALUES (43003016,'otro','c','r','a','p',100,40,'approved')")
    schema_con.execute("INSERT INTO reflections(verse_id,kind,context_text,reflection_text,application_text,prayer_text,word_count,reading_seconds,status) VALUES (43003016,'daily','c','r','a','p',100,40,'approved')")
    assert schema_con.execute("SELECT sensitive FROM reflections").fetchone()[0] == 0


def test_checks_de_dominio(schema_con):
    with pytest.raises(sqlite3.IntegrityError):
        schema_con.execute("INSERT INTO books VALUES (1,'Gen','Génesis','genesis','XX',50,'gn')")
    with pytest.raises(sqlite3.IntegrityError):
        schema_con.execute("INSERT INTO themes VALUES (1,'x','X','otro','i',1)")
    schema_con.execute("INSERT INTO themes VALUES (1,'ansiedad','Ansiedad','emotion','waves',1)")
    books_data.insert_books(schema_con)
    schema_con.execute("INSERT INTO verses VALUES (1001001, 1, 1, 1, 't', 't', 0.9, 1)")
    with pytest.raises(sqlite3.IntegrityError):
        schema_con.execute("INSERT INTO verse_themes VALUES (1, 1001001, 1.5)")
    with pytest.raises(sqlite3.IntegrityError):
        schema_con.execute("INSERT INTO verse_themes VALUES (1, 1001001, -0.1)")
    schema_con.execute("INSERT INTO verse_themes VALUES (1, 1001001, 0.7)")


def test_unicidad(schema_con):
    books_data.insert_books(schema_con)
    with pytest.raises(sqlite3.IntegrityError):
        schema_con.execute("INSERT INTO books VALUES (99,'Gen','X','x','AT',1,'x')")   # osis repetido
    with pytest.raises(sqlite3.IntegrityError):
        schema_con.execute("INSERT INTO books VALUES (99,'X','X','genesis','AT',1,'x')")   # slug repetido
    schema_con.execute("INSERT INTO verses VALUES (43003016, 43, 3, 16, 't', 't', 0.9, 1)")
    with pytest.raises(sqlite3.IntegrityError):
        schema_con.execute("INSERT INTO verses VALUES (99, 43, 3, 16, 't', 't', 0.9, 1)")


def test_claves_foraneas_activas(schema_con):
    with pytest.raises(sqlite3.IntegrityError):
        schema_con.execute("INSERT INTO verses VALUES (43003016, 43, 3, 16, 't', 't', 0.9, 1)")   # libro inexistente


def test_meta_trae_linea_de_ayuda_placeholder_y_no_un_numero_real(schema_con):
    meta = dict(schema_con.execute("SELECT key, value FROM meta"))
    assert "PLACEHOLDER" in meta["help_line_text"]
    assert "PLACEHOLDER" in meta["help_line_number"]
    assert not any(ch.isdigit() for ch in meta["help_line_number"])
    assert meta["translation"] == "RV1909"


def test_build_de_la_muestra_pasa_integridad(content_db_path, db):
    assert db.execute("PRAGMA integrity_check").fetchone() == ("ok",)


def test_muestra_es_determinista(tmp_path):
    import make_sample_db
    a, b = tmp_path / "a.db", tmp_path / "b.db"
    assert make_sample_db.build(a) == make_sample_db.build(b)
    assert contentdb.SCHEMA_VERSION == "2"
