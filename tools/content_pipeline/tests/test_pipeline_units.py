"""Pruebas unitarias de las etapas del pipeline SIN red ni Ollama (transporte simulado)."""
import json
import sqlite3
import zipfile

import pytest

from pipeline import books_data, contentdb, editorial, export, ingest, moments, reflections, review, similar, tag, workdb
from pipeline import ollama_client as oc


# ---------------------------------------------------------------- ingesta
@pytest.mark.parametrize("raw,expected", [
    ('\\w EN el principio|strong="H7225"\\w* \\w crió|strong="H1254"\\w* \\w Dios|strong="H0430"\\w*.',
     "EN el principio crió Dios."),
    ('\\w sáca|strong="H3318"\\w*\\add lo\\add* \\w de|strong="H4480"\\w*', "sácalo de"),
    ('\\w Dios|strong="H0430"\\w* (\\add dijo ella\\add*) \\w me|strong="H1"\\w*', "Dios (dijo ella) me"),
    ('\\add \\+w son las medidas|strong="H4055"\\+w* \\+w de que|strong="H0834"\\+w*\\add* \\w Salomón|strong="H8010"\\w*',
     "son las medidas de que Salomón"),
    ("Texto simple sin marcas", "Texto simple sin marcas"),
])
def test_limpieza_usfm(raw, expected):
    assert ingest.clean_usfm_text(raw) == expected


def _zip(tmp_path, members):
    p = tmp_path / "x.zip"
    with zipfile.ZipFile(p, "w") as z:
        for n, t in members.items():
            z.writestr(n, t)
    return p


def test_parse_usfm_zip_minimo(tmp_path):
    z = _zip(tmp_path, {
        "44-JHNspaRV1909.usfm": "\\id JHN\n\\c 3\n\\p\n\\v 16 \\w Porque|strong=\"G1\"\\w* de tal manera\n continua aqui\n\\v 17 Dos\n",
        "malicioso../../evil.py": "import os",
    })
    out = ingest.parse_usfm_zip(z)
    assert out == [(43, 3, 16, "Porque de tal manera continua aqui"), (43, 3, 17, "Dos")]


def test_parse_rechaza_rangos_y_codigos_raros(tmp_path):
    with pytest.raises(ingest.IngestError):
        ingest.parse_usfm_zip(_zip(tmp_path, {"44-JHNspaRV1909.usfm": "\\c 1\n\\v 1-2 x\n"}))
    with pytest.raises(ingest.IngestError):
        ingest.parse_usfm_zip(_zip(tmp_path, {"99-ZZZspaRV1909.usfm": "\\c 1\n\\v 1 x\n"}))


def test_licencia_se_exige(tmp_path):
    ok = _zip(tmp_path, {"copr.htm": "<p>Public Domain</p>"})
    assert "Public Domain" in ingest.verify_license(ok, tmp_path / "no.html")["declared"]
    with pytest.raises(ingest.IngestError):
        ingest.verify_license(_zip(tmp_path, {"copr.htm": "<p>Copyright (c) todos los derechos</p>"}), tmp_path / "no.html")


def test_check_lossless_detecta_huecos_y_marcas():
    ok = [(43, 3, 1, "a"), (43, 3, 2, "b")]
    rep = ingest.check_lossless(ok)
    assert any("libros" in e for e in rep["errors"])             # solo hay 1 libro de 66
    bad = ingest.check_lossless([(1, 1, 1, "x \\add"), (1, 1, 3, "y")])
    assert any("marcas USFM" in e for e in bad["errors"]) and any("no contiguos" in e for e in bad["errors"])


def test_conteo_fijado_en_la_ingesta_real():
    data = json.loads(ingest.EXPECTED_JSON.read_text("utf-8"))
    assert data["total_verses"] == 31084 and data["total_chapters"] == 1189
    assert data["source_verse_slots"] == 31102 and len(data["empty_in_source"]) == 18
    assert sum(data["per_book_verses"].values()) == data["total_verses"]
    assert set(data["per_book_verses"]) == {b.osis for b in books_data.BOOKS}


def test_work_db_real_coincide_con_el_conteo_fijado():
    if not workdb.DEFAULT_PATH.exists():
        pytest.skip("work.db no existe (corre la ingesta)")
    con = sqlite3.connect(workdb.DEFAULT_PATH)
    n = con.execute("SELECT COUNT(*) FROM verses_raw").fetchone()[0]
    if n == 0:
        pytest.skip("work.db sin ingesta")
    assert n == json.loads(ingest.EXPECTED_JSON.read_text("utf-8"))["total_verses"]
    src = con.execute("SELECT license_declared, url, sha256 FROM sources").fetchone()
    assert "Public Domain" in src[0] and src[1].startswith("https://ebible.org/") and len(src[2]) == 64
    assert con.execute("SELECT COUNT(*) FROM verses_raw WHERE text = '' OR text LIKE '%\\%'").fetchone()[0] == 0


# ---------------------------------------------------------------- parecidos
def test_select_neighbors_maximo_2_por_libro():
    book_of = {i: (1 if i < 10 else 2 if i < 20 else 3 + i) for i in range(1, 60)}
    cands = [(i, 1.0 - i / 100) for i in range(1, 60)]
    chosen = similar.select_neighbors(cands, book_of)
    assert len(chosen) == 10
    from collections import Counter
    assert max(Counter(book_of[v] for v, _ in chosen).values()) <= 2
    scores = [s for _, s in chosen]
    assert scores == sorted(scores, reverse=True)
    assert [v for v, _ in chosen][:2] == [1, 2]       # los dos mejores del libro 1; el 3ro se salta


def test_select_neighbors_devuelve_menos_si_no_hay_variedad():
    book_of = {i: 1 for i in range(1, 30)}
    assert len(similar.select_neighbors([(i, 1 / i) for i in range(1, 30)], book_of)) == 2


def test_similar_run_con_backend_hash_cumple_las_reglas(tmp_path):
    from collections import Counter
    con = workdb.connect(tmp_path / "w.db")
    con.execute("INSERT INTO sources(id,name,url,license_declared,license_evidence,downloaded_at,sha256,local_file,"
                "verse_count,chapter_count) VALUES (1,'s','u','PD','e','d','x','f',0,0)")
    for i in range(60):
        b = 1 + i % 6
        vid = books_data.verse_id(b, 1 + i // 6, 1)
        text = f"palabra{i % 7} comun{i % 3} texto {i}"
        con.execute("INSERT INTO verses_raw VALUES (?,?,?,?,?,?,1)", (vid, b, 1 + i // 6, 1, text, text))
        con.execute("INSERT INTO verse_scores VALUES (?,?,NULL)", (vid, 0.9 if i < 50 else 0.2))
    con.commit()
    con.close()
    assert similar.run(tmp_path / "w.db", "hash", "x", 0.6) == 50
    con = workdb.connect(tmp_path / "w.db")
    per = Counter(r[0] for r in con.execute("SELECT verse_id FROM similar"))
    assert set(per.values()) == {10} and len(per) == 50
    elig = {r[0] for r in con.execute("SELECT verse_id FROM verse_scores WHERE card_score >= 0.6")}
    assert all(s in elig and v != s for v, s in con.execute("SELECT verse_id, similar_id FROM similar"))
    rows = con.execute("SELECT s.verse_id, v.book_id, COUNT(*) FROM similar s JOIN verses_raw v ON v.id=s.similar_id "
                       "GROUP BY s.verse_id, v.book_id").fetchall()
    assert max(r[2] for r in rows) <= 2


# ---------------------------------------------------------------- cliente Ollama
def fake_transport(responses):
    calls = []

    def t(host, payload, timeout):
        calls.append(payload)
        return responses[min(len(calls) - 1, len(responses) - 1)]
    t.calls = calls
    return t


def test_chat_json_valido_a_la_primera():
    t = fake_transport([json.dumps({"themes": [{"slug": "paz", "weight": 0.9}], "card_score": 0.8})])
    r = oc.chat_json("m", "s", "u", tag.build_schema(), transport=t, seed=7)
    assert r.valid and r.attempts == 1 and r.seed == 7 and r.temperature == 0.2
    assert t.calls[0]["options"] == {"temperature": 0.2, "seed": 7, "num_predict": 900}
    assert t.calls[0]["format"] == tag.build_schema()


def test_chat_json_reintenta_y_pasa_el_error_al_modelo():
    bad_slug = json.dumps({"themes": [{"slug": "inventado", "weight": 0.9}], "card_score": 0.8})
    good = json.dumps({"themes": [], "card_score": 0.5})
    t = fake_transport(["no es json", bad_slug, good])
    r = oc.chat_json("m", "s", "u", tag.build_schema(), transport=t, retries=3)
    assert r.valid and r.attempts == 3 and len(r.errors_history) == 2
    last_user = t.calls[2]["messages"][-1]["content"]
    assert "no cumple el esquema" in last_user
    assert [p["options"]["seed"] for p in t.calls] == [42, 43, 44]       # semilla distinta por reintento


def test_chat_json_agota_reintentos():
    t = fake_transport(["{}"])
    r = oc.chat_json("m", "s", "u", tag.build_schema(), transport=t, retries=1)
    assert not r.valid and r.attempts == 2 and r.error


def test_esquema_de_etiquetas_es_lista_cerrada():
    enum = tag.build_schema()["properties"]["themes"]["items"]["properties"]["slug"]["enum"]
    assert enum == __import__("pipeline.taxonomy", fromlist=["x"]).THEME_SLUGS
    assert len(enum) == 15


# ---------------------------------------------------------------- work.db + etiquetado + reflexiones
@pytest.fixture()
def wdb(tmp_path):
    con = workdb.connect(tmp_path / "work.db")
    con.execute("INSERT INTO sources(id,name,url,license_declared,license_evidence,downloaded_at,sha256,local_file,"
                "verse_count,chapter_count) VALUES (1,'s','u','PD','e','2026-01-01','x','f',0,0)")
    con.execute("INSERT INTO verses_raw VALUES (43003016,43,3,16,'Porque de tal manera amó Dios al mundo',"
                "'porque de tal manera amo dios al mundo',1)")
    con.execute("INSERT INTO verses_raw VALUES (19023001,19,23,1,'Jehová es mi pastor; nada me faltará','jehova es mi pastor nada me faltara',1)")
    con.commit()
    return con


def test_tag_one_guarda_prompt_modelo_temperatura_y_semilla(wdb):
    t = fake_transport([json.dumps({"themes": [{"slug": "amor", "weight": 0.9}, {"slug": "paz", "weight": 0.1},
                                               {"slug": "amor", "weight": 0.5}], "card_score": 0.93})])
    assert tag.tag_one(wdb, 43003016, "texto", "qwen2.5:7b", 42, 1, transport=t)
    g = wdb.execute("SELECT stage, model, temperature, seed, valid, prompt FROM generations").fetchone()
    assert g[:5] == ("tag", "qwen2.5:7b", 0.2, 42, 1) and "Juan 3:16" in g[5]
    assert wdb.execute("SELECT theme_slug, weight FROM verse_tags").fetchall() == [("amor", 0.9)]   # <0.3 descartado
    assert wdb.execute("SELECT card_score FROM verse_scores").fetchone()[0] == 0.93


def test_tag_one_invalido_no_guarda_etiquetas(wdb):
    t = fake_transport(["basura"])
    assert not tag.tag_one(wdb, 43003016, "texto", "m", 42, 1, transport=t)
    assert wdb.execute("SELECT COUNT(*) FROM verse_tags").fetchone()[0] == 0
    assert wdb.execute("SELECT valid, attempts FROM generations").fetchone() == (0, 2)


GOOD = {
    "context": "Este pasaje de Juan 3:16 recoge palabras sobre el amor de Dios dichas en una conversación nocturna con un maestro de la ley.",
    "reflection": "Podemos detenernos a pensar cuánto significa sentirse amados sin condiciones. Esta idea invita a descansar en un cariño que no depende de lo que logremos hoy ni de nuestros errores pasados, y nos recuerda que recibir sin merecer también es una forma de confianza que se aprende despacio.",
    "application": "Hoy podemos agradecer a alguien cercano y decirle una palabra amable, empezando por quien menos lo espera de nosotros.",
    "prayer": "Dios nuestro, gracias por tu amor sin medida. Enséñanos a recibirlo con calma y a compartirlo con quienes están a nuestro lado. Amén.",
    "sensitive": False,
}


def test_generate_one_valida_y_guarda_borrador(wdb):
    reflections._slot(wdb, 43003016, "daily")
    assert editorial.validate_reflection(reflections.to_blocks(GOOD), 43003016).ok
    t = fake_transport([json.dumps(GOOD)])
    assert reflections.generate_one(wdb, 1, "m", 42, 1, transport=t)
    r = wdb.execute("SELECT status, word_count, validation_errors FROM reflections").fetchone()
    assert r[0] == "draft" and 90 <= r[1] <= 150 and r[2] is None
    assert "ninguna referencia biblica" in t.calls[0]["messages"][0]["content"].replace("\n", " ")


def test_generate_one_reintenta_si_cita_otro_versiculo(wdb):
    reflections._slot(wdb, 43003016, "daily")
    bad = dict(GOOD, reflection=GOOD["reflection"] + " Como dice Romanos 8:28 todo ayuda a bien.")
    t = fake_transport([json.dumps(bad), json.dumps(GOOD)])
    assert reflections.generate_one(wdb, 1, "m", 42, 2, transport=t)
    assert wdb.execute("SELECT attempts FROM generations").fetchone()[0] == 2
    assert "referencias biblicas" in t.calls[1]["messages"][-1]["content"]


def test_generate_one_invalida_queda_con_errores_para_revision(wdb):
    reflections._slot(wdb, 43003016, "daily")
    bad = dict(GOOD, prayer="Santa María, ruega por nosotros, amén y gracias por escucharnos siempre.")
    t = fake_transport([json.dumps(bad)])
    assert not reflections.generate_one(wdb, 1, "m", 42, 0, transport=t)
    status, errs = wdb.execute("SELECT status, validation_errors FROM reflections").fetchone()
    assert status == "draft" and "terminos prohibidos" in errs


# ---------------------------------------------------------------- revision
def _draft(wdb, blocks=None):
    reflections._slot(wdb, 43003016, "daily")
    b = blocks or reflections.to_blocks(GOOD)
    wdb.execute("UPDATE reflections SET context_text=?, reflection_text=?, application_text=?, prayer_text=?, word_count=?"
                " WHERE id=1", (*b.values(), editorial.word_count(*b.values())))
    wdb.commit()
    return b


def test_aprobar_registra_tiempo_y_estado(wdb):
    _draft(wdb)
    review.apply_review(wdb, 1, "approve", 75)
    assert wdb.execute("SELECT status, review_seconds, edited FROM reflections").fetchone() == ("approved", 75, 0)
    assert wdb.execute("SELECT action, seconds FROM review_log").fetchone() == ("approved", 75)


def test_no_se_aprueba_lo_que_no_pasa_validadores(wdb):
    b = _draft(wdb)
    b["prayer_text"] = "Virgen santa, ruega por nosotros. " + b["prayer_text"]
    wdb.execute("UPDATE reflections SET prayer_text=? WHERE id=1", (b["prayer_text"],))
    with pytest.raises(review.ReviewError):
        review.apply_review(wdb, 1, "approve", 10)
    assert wdb.execute("SELECT status FROM reflections").fetchone()[0] == "draft"


def test_editar_y_aprobar_corrige_y_marca_editada(wdb):
    b = _draft(wdb)
    b["prayer_text"] = "Dios nuestro, gracias por escucharnos hoy y siempre. Acompáñanos con calma, ayúdanos a descansar en tu cuidado y a compartir con otros lo que hemos recibido sin merecerlo. Amén."
    review.apply_review(wdb, 1, "edit_approve", 120, blocks=b, sensitive=True)
    row = wdb.execute("SELECT status, edited, sensitive, prayer_text, review_seconds FROM reflections").fetchone()
    assert row[:3] == ("approved", 1, 1) and row[3].startswith("Dios nuestro, gracias") and row[4] == 120


def test_rechazar(wdb):
    _draft(wdb)
    review.apply_review(wdb, 1, "reject", 20)
    assert wdb.execute("SELECT status FROM reflections").fetchone()[0] == "rejected"


# ---------------------------------------------------------------- exportacion
def test_export_solo_aprobadas_y_similares_entre_elegibles(wdb, tmp_path):
    wdb.execute("INSERT INTO verse_scores VALUES (43003016, 0.9, NULL)")
    wdb.execute("INSERT INTO verse_scores VALUES (19023001, 0.3, NULL)")
    wdb.execute("INSERT INTO verse_tags VALUES (43003016,'amor',0.9,NULL)")
    wdb.execute("INSERT INTO similar VALUES (43003016,1,19023001,0.5,'m')")    # a no elegible: se descarta
    wdb.execute("INSERT INTO similar VALUES (19023001,1,43003016,0.5,'m')")    # desde no elegible: se descarta
    _draft(wdb)
    reflections._slot(wdb, 19023001, "daily")                                  # sin texto, 'draft'
    review.apply_review(wdb, 1, "approve", 5)
    wdb.execute("INSERT INTO daily_plan VALUES ('01-01', 43003016)")
    wdb.commit()
    out = tmp_path / "content.db"
    info = export.build_content(tmp_path / "work.db", out, content_version="2026102801", strict=False,
                                help_text=None, help_number=None)
    assert info["verses"] == 2 and info["eligible"] == 1 and info["reflections"] == 1
    c = sqlite3.connect(out)
    assert c.execute("SELECT COUNT(*) FROM reflections").fetchone()[0] == 1
    assert c.execute("SELECT COUNT(*) FROM verse_similar").fetchone()[0] == 0
    assert c.execute("SELECT reflection_id FROM daily_calendar").fetchone()[0] == 1
    meta = dict(c.execute("SELECT key, value FROM meta"))
    assert meta["content_version"] == "2026102801" and len(meta["content_hash"]) == 64
    assert meta["is_sample"] == "0" and "PLACEHOLDER" in meta["help_line_number"]
    assert c.execute("PRAGMA integrity_check").fetchone() == ("ok",)
    assert c.execute("PRAGMA foreign_key_check").fetchall() == []
    assert c.execute("SELECT COUNT(*) FROM verses_fts WHERE verses_fts MATCH 'amo'").fetchone()[0] == 1


def test_export_se_niega_a_escribir_en_assets(tmp_path):
    with pytest.raises(SystemExit):
        export.main(["--out", str(tmp_path / "assets" / "db" / "content.db"), "--work", str(tmp_path / "w.db")])


def test_release_exige_linea_de_ayuda_real(tmp_path):
    with pytest.raises(SystemExit):
        export.main(["--out", str(tmp_path / "c.db"), "--work", str(tmp_path / "w.db"), "--release"])
    with pytest.raises(SystemExit):
        export.main(["--out", str(tmp_path / "c.db"), "--work", str(tmp_path / "w.db"), "--release",
                     "--help-line-text", "PLACEHOLDER", "--help-line-number", "PLACEHOLDER"])


# ---------------------------------------------------------------- momentos
def test_momentos_afinidad_cubre_taxonomia():
    from pipeline import taxonomy
    assert set(moments.AFFINITY) == set(taxonomy.MOMENT_SLUGS)
    assert all(t in taxonomy.THEME_SLUGS for ts in moments.AFFINITY.values() for t in ts)
