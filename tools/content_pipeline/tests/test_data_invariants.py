"""Las 10 pruebas de datos de la seccion 10 del spec, sobre CUALQUIER content.db.

  pytest                                  # contra la muestra v2
  pytest --content-db ruta/content.db     # contra el real (o SOSIEGO_CONTENT_DB=ruta)

Mas las puertas de publicacion (marker `release`, solo con SOSIEGO_RELEASE=1).
"""
import json
import os
import re
import sqlite3
from pathlib import Path

import pytest

from pipeline import books_data, editorial, taxonomy
from pipeline.normalize import normalize

ROOT = Path(__file__).resolve().parent.parent
SHARED_CASES = ROOT.parent / "shared" / "normalize_cases.json"
EXPECTED = ROOT / "data" / "rv1909_expected.json"
CONTROL_WORDS = ["dios", "amor", "paz", "senor"]      # palabras de control del FTS (prueba 8)


# 1 ---------------------------------------------------------------------------------------
def test_01_total_de_versiculos_es_el_conteo_fijado(db, meta):
    total = db.execute("SELECT COUNT(*) FROM verses").fetchone()[0]
    assert total == int(meta["verse_count_expected"]), "no coincide con meta.verse_count_expected"
    if meta.get("is_sample") != "1":
        pinned = json.loads(EXPECTED.read_text("utf-8"))["total_verses"]
        assert total == pinned, f"el conteo fijado en la ingesta es {pinned}"
        assert db.execute("SELECT COUNT(*) FROM chapters").fetchone()[0] == 1189


# 2 ---------------------------------------------------------------------------------------
def test_02_integridad_y_claves_foraneas(db):
    assert db.execute("PRAGMA integrity_check").fetchall() == [("ok",)]
    assert db.execute("PRAGMA foreign_key_check").fetchall() == []


# 3 ---------------------------------------------------------------------------------------
def test_03_elegibles_tienen_10_parecidos_elegibles(db):
    bad = db.execute("""
        SELECT v.id FROM verses v
        WHERE v.is_card_eligible = 1
          AND (SELECT COUNT(*) FROM verse_similar s WHERE s.verse_id = v.id) != 10""").fetchall()
    assert bad == [], f"elegibles sin 10 parecidos: {bad[:5]}"
    to_non_eligible = db.execute("""
        SELECT s.verse_id, s.similar_id FROM verse_similar s
        JOIN verses t ON t.id = s.similar_id WHERE t.is_card_eligible = 0""").fetchall()
    assert to_non_eligible == []
    from_non_eligible = db.execute("""
        SELECT DISTINCT s.verse_id FROM verse_similar s
        JOIN verses f ON f.id = s.verse_id WHERE f.is_card_eligible = 0""").fetchall()
    assert from_non_eligible == []
    assert db.execute("SELECT COUNT(*) FROM verse_similar WHERE verse_id = similar_id").fetchone()[0] == 0


def test_03b_parecidos_maximo_2_del_mismo_libro_y_ranks_1_a_10(db):
    rows = db.execute("""
        SELECT s.verse_id, v.book_id, COUNT(*) c FROM verse_similar s
        JOIN verses v ON v.id = s.similar_id GROUP BY s.verse_id, v.book_id HAVING c > 2""").fetchall()
    assert rows == []
    bad = db.execute("SELECT 1 FROM verse_similar WHERE rank NOT BETWEEN 1 AND 10").fetchall()
    assert bad == []


# 4 ---------------------------------------------------------------------------------------
@pytest.mark.parametrize("slug", taxonomy.EMOTION_SLUGS)
def test_04_cada_emocion_tiene_al_menos_40_versiculos_fuertes(db, slug):
    n = db.execute("""
        SELECT COUNT(*) FROM verse_themes vt JOIN themes t ON t.id = vt.theme_id
        WHERE t.slug = ? AND t.kind = 'emotion' AND vt.weight >= ?""",
                   (slug, taxonomy.EMOTION_STRONG_WEIGHT)).fetchone()[0]
    assert n >= taxonomy.MIN_VERSES_PER_EMOTION, f"{slug}: {n}"


@pytest.mark.parametrize("slug", taxonomy.MOMENT_SLUGS)
def test_04_cada_momento_tiene_al_menos_15_versiculos(db, slug):
    n = db.execute("""
        SELECT COUNT(*) FROM moment_verses mv JOIN moments m ON m.id = mv.moment_id
        WHERE m.slug = ?""", (slug,)).fetchone()[0]
    assert n >= taxonomy.MIN_VERSES_PER_MOMENT, f"{slug}: {n}"


def test_04b_taxonomia_completa_y_pesos_validos(db):
    emotions = [r[0] for r in db.execute("SELECT slug FROM themes WHERE kind='emotion' ORDER BY sort")]
    moments = [r[0] for r in db.execute("SELECT slug FROM moments ORDER BY sort")]
    assert emotions == taxonomy.EMOTION_SLUGS
    assert moments == taxonomy.MOMENT_SLUGS
    assert db.execute("SELECT COUNT(*) FROM verse_themes WHERE weight < ?",
                      (taxonomy.THEME_MIN_WEIGHT,)).fetchone()[0] == 0, "verse_themes solo guarda pesos >= 0.3"


# 5 ---------------------------------------------------------------------------------------
def test_05_calendario_366_filas_con_29_de_febrero(db):
    days = [r[0] for r in db.execute("SELECT month_day FROM daily_calendar")]
    assert len(days) == 366 and len(set(days)) == 366
    assert "02-29" in days
    assert all(re.fullmatch(r"(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])", d) for d in days)
    assert db.execute("""SELECT COUNT(*) FROM daily_calendar c LEFT JOIN verses v ON v.id = c.verse_id
                         WHERE v.id IS NULL""").fetchone()[0] == 0
    assert db.execute("""SELECT COUNT(*) FROM daily_calendar c LEFT JOIN reflections r ON r.id = c.reflection_id
                         WHERE c.reflection_id IS NOT NULL AND r.id IS NULL""").fetchone()[0] == 0
    # el calendario solo usa versiculos elegibles
    assert db.execute("""SELECT COUNT(*) FROM daily_calendar c JOIN verses v ON v.id = c.verse_id
                         WHERE v.is_card_eligible = 0""").fetchone()[0] == 0


def test_05b_reflexion_del_calendario_es_del_mismo_versiculo(db):
    bad = db.execute("""SELECT c.month_day FROM daily_calendar c JOIN reflections r ON r.id = c.reflection_id
                        WHERE r.verse_id != c.verse_id OR r.kind != 'daily'""").fetchall()
    assert bad == []


# 6 ---------------------------------------------------------------------------------------
def _reflections(db):
    return db.execute("""SELECT id, verse_id, kind, theme_id, moment_id, context_text, reflection_text,
                                application_text, prayer_text, word_count, reading_seconds, sensitive, status
                         FROM reflections""").fetchall()


def test_06_reflexiones_90_a_150_palabras_aprobadas_sin_referencias_ajenas(db):
    problems = []
    for (rid, vid, kind, th, mo, c, r, a, p, wc, rs, sens, status) in _reflections(db):
        n = editorial.word_count(c, r, a, p)
        if not (editorial.MIN_WORDS <= n <= editorial.MAX_WORDS):
            problems.append((rid, "palabras", n))
        if n != wc:
            problems.append((rid, "word_count no coincide", wc, n))
        if status != "approved":
            problems.append((rid, "status", status))
        foreign = editorial.foreign_references(" ".join((c, r, a, p)), vid)
        if foreign:
            problems.append((rid, "referencias ajenas", foreign))
        if not all(x.strip() for x in (c, r, a, p)):
            problems.append((rid, "bloque vacio"))
        if rs != editorial.reading_seconds(wc):
            problems.append((rid, "reading_seconds", rs))
        if kind == "emotion" and (th is None or mo is not None):
            problems.append((rid, "emotion requiere theme_id y no moment_id"))
        if kind == "moment" and (mo is None or th is not None):
            problems.append((rid, "moment requiere moment_id y no theme_id"))
        if kind == "daily" and (th is not None or mo is not None):
            problems.append((rid, "daily no lleva theme_id ni moment_id"))
    assert problems == [], problems[:5]


# 7 ---------------------------------------------------------------------------------------
def test_07_sin_terminos_prohibidos(db):
    problems = []
    for row in _reflections(db):
        found = editorial.forbidden_terms_in(" ".join(row[5:9]))
        if found:
            problems.append((row[0], found))
    assert problems == [], problems[:5]


# 8 ---------------------------------------------------------------------------------------
@pytest.mark.parametrize("word", CONTROL_WORDS)
def test_08_busqueda_fts_devuelve_resultados_para_palabras_de_control(db, word):
    n = db.execute("SELECT COUNT(*) FROM verses_fts WHERE verses_fts MATCH ?", (word,)).fetchone()[0]
    assert n > 0, word


def test_08b_busqueda_sin_tildes_con_prefijo_y_bm25(db):
    rows = db.execute("""SELECT rowid, bm25(verses_fts) FROM verses_fts
                         WHERE verses_fts MATCH 'sen*' ORDER BY bm25(verses_fts) LIMIT 30""").fetchall()
    assert rows, "prefijo 'sen*' debe encontrar 'Señor' normalizado"
    assert len(rows) <= 30


# 9 ---------------------------------------------------------------------------------------
def test_09_normalizacion_python_igual_a_la_lista_compartida():
    data = json.loads(SHARED_CASES.read_text("utf-8"))
    assert len(data["cases"]) >= 20
    bad = [(c["id"], normalize(c["input"]), c["expected"])
           for c in data["cases"] if normalize(c["input"]) != c["expected"]]
    assert bad == []


def test_09b_text_norm_de_la_base_sigue_la_misma_funcion(db):
    bad = [(i,) for i, t, tn in db.execute("SELECT id, text, text_norm FROM verses") if normalize(t) != tn]
    assert bad == [], bad[:5]


# 10 --------------------------------------------------------------------------------------
def test_10_fts5_disponible(db):
    assert db.execute("SELECT sqlite_compileoption_used('ENABLE_FTS5')").fetchone()[0] == 1


# ---------------------------------------------------------------- invariantes adicionales
def test_ids_de_versiculo_son_libro_capitulo_versiculo(db):
    bad = db.execute("""SELECT id FROM verses
                        WHERE id != book_id*1000000 + chapter*1000 + verse""").fetchall()
    assert bad == []


def test_66_libros_coinciden_con_la_tabla_unica(db):
    rows = db.execute("SELECT id, osis, name_es, slug, testament, chapters, aliases FROM books ORDER BY id").fetchall()
    assert rows == [(b.id, b.osis, b.name_es, b.slug, b.testament, b.chapters, b.aliases_str)
                    for b in books_data.BOOKS]


def test_versiculos_dentro_de_rango_de_capitulos(db):
    bad = db.execute("""SELECT v.id FROM verses v JOIN books b ON b.id = v.book_id
                        WHERE v.chapter < 1 OR v.chapter > b.chapters OR v.verse < 1""").fetchall()
    assert bad == []


def test_card_score_y_elegibilidad_coherentes(db):
    bad = db.execute("""SELECT id FROM verses WHERE card_score NOT BETWEEN 0 AND 1
                        OR is_card_eligible != (card_score >= ?)""", (taxonomy.CARD_SCORE_THRESHOLD,)).fetchall()
    assert bad == []


def test_meta_claves_obligatorias(meta):
    for k in ("translation", "content_version", "built_at", "content_hash", "source_url",
              "help_line_text", "help_line_number", "schema_version"):
        assert meta.get(k), f"falta meta.{k}"
    assert meta["translation"] == "RV1909"
    assert meta["content_version"].isdigit(), "content_version debe comparar como entero en la app"
    assert len(meta["content_hash"]) == 64


def test_content_hash_corresponde_al_contenido(db, meta):
    from pipeline import contentdb
    assert contentdb.compute_hash(db) == meta["content_hash"]


def test_no_hay_reflexiones_sin_aprobar_ni_texto_de_muestra_en_real(db, meta):
    assert db.execute("SELECT COUNT(*) FROM reflections WHERE status != 'approved'").fetchone()[0] == 0
    if meta.get("is_sample") != "1":
        n = db.execute("SELECT COUNT(*) FROM reflections WHERE context_text LIKE '%[MUESTRA]%'").fetchone()[0]
        assert n == 0
        n = db.execute("SELECT COUNT(*) FROM verses WHERE text LIKE '%[MUESTRA]%'").fetchone()[0]
        assert n == 0


def test_hay_reflexiones_sensibles_en_la_muestra(db, meta):
    if meta.get("is_sample") == "1":
        assert db.execute("SELECT COUNT(*) FROM reflections WHERE sensitive = 1").fetchone()[0] >= 3
        kinds = {r[0] for r in db.execute("SELECT DISTINCT kind FROM reflections")}
        assert kinds == {"daily", "emotion", "moment"}


# ---------------------------------------------------------------- puertas de publicacion
release = pytest.mark.skipif(os.environ.get("SOSIEGO_RELEASE") != "1",
                             reason="solo antes de publicar (SOSIEGO_RELEASE=1)")


@release
def test_release_linea_de_ayuda_verificada(meta):
    assert "PLACEHOLDER" not in meta["help_line_text"]
    assert "PLACEHOLDER" not in meta["help_line_number"]
    assert re.fullmatch(r"[0-9+ ]{3,20}", meta["help_line_number"])


@release
def test_release_685_reflexiones_aprobadas(db):
    daily = db.execute("SELECT COUNT(*) FROM reflections WHERE kind='daily'").fetchone()[0]
    assert daily >= taxonomy.REFLECTIONS_DAILY
    per_emotion = dict(db.execute("""SELECT t.slug, COUNT(*) FROM reflections r JOIN themes t ON t.id=r.theme_id
                                     WHERE r.kind='emotion' GROUP BY t.slug"""))
    assert all(per_emotion.get(s, 0) >= taxonomy.REFLECTIONS_PER_EMOTION for s in taxonomy.EMOTION_SLUGS)
    per_moment = dict(db.execute("""SELECT m.slug, COUNT(*) FROM reflections r JOIN moments m ON m.id=r.moment_id
                                    WHERE r.kind='moment' GROUP BY m.slug"""))
    assert all(per_moment.get(s, 0) >= taxonomy.REFLECTIONS_PER_MOMENT for s in taxonomy.MOMENT_SLUGS)


@release
def test_release_no_es_muestra(meta):
    assert meta.get("is_sample") == "0"
