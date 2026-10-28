"""Genera content_v2.sample.db: una muestra COMPLETA y coherente del esquema v2 (spec §6).

El texto de versiculos, reflexiones y resumenes de capitulo es FICTICIO y va marcado [MUESTRA]
(salvo con --real-text WORK_DB, que toma el texto real de la RV1909 ya ingerido en work.db para
los mismos versiculos; las reflexiones siguen siendo de muestra). Es determinista: dos corridas
dan el mismo content_hash.

Uso:
  python make_sample_db.py                                  # -> out/content_v2.sample.db
  python make_sample_db.py ruta/salida.db [--real-text work/work.db]
"""
from __future__ import annotations

import argparse
import datetime
import random
import sqlite3
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

from pipeline import books_data, contentdb, editorial, taxonomy  # noqa: E402
from pipeline.normalize import normalize  # noqa: E402
from pipeline.similar import cosine, select_neighbors  # noqa: E402

DEFAULT_OUT = HERE / "out" / "content_v2.sample.db"
SAMPLE_VERSION = "1"
SAMPLE_BUILT_AT = "2026-10-28T00:00:00Z"   # fijo: la muestra es reproducible

# Referencias reales (libro osis, capitulo, versiculo): 106 versiculos en ~38 libros.
_REFS = """
Ps 23:1 Ps 23:4 Ps 46:1 Ps 27:1 Ps 34:18 Ps 91:1 Ps 121:1 Ps 121:2 Ps 139:14 Ps 51:10 Ps 30:5 Ps 62:1
Prov 3:5 Prov 3:6 Prov 4:23 Prov 15:1 Prov 16:3 Prov 17:22 Prov 18:10
Isa 41:10 Isa 40:31 Isa 43:2 Isa 26:3 Jer 29:11 Jer 17:7 Lam 3:22 Lam 3:23
Matt 5:4 Matt 6:25 Matt 6:34 Matt 11:28 Matt 7:7 Matt 5:9 Matt 28:20
Mark 4:39 Mark 9:24 Mark 11:25 Luke 1:37 Luke 12:7 Luke 15:20
John 3:16 John 14:27 John 16:33 John 10:10 John 1:12 John 11:25 John 15:12 John 8:12
Acts 16:31 Acts 20:35
Rom 8:28 Rom 8:38 Rom 12:12 Rom 15:13 Rom 5:8 Rom 12:18
1Cor 13:4 1Cor 13:13 1Cor 10:13 1Cor 15:58 1Cor 16:14
2Cor 12:9 2Cor 4:16 2Cor 1:3 Gal 5:22 Gal 6:9
Eph 4:32 Eph 2:8 Eph 6:10 Eph 4:26 Phil 4:6 Phil 4:7 Phil 4:13 Phil 4:8
Col 3:13 Col 3:15 1Thess 5:16 1Thess 5:18 2Tim 1:7
Heb 11:1 Heb 13:5 Heb 13:8 Heb 4:16 Jas 1:5 Jas 1:19 Jas 5:16
1Pet 5:7 1Pet 4:8 1John 4:8 1John 4:18 1John 1:9 Rev 21:4
Gen 1:1 Gen 28:15 Exod 14:14 Exod 15:2 Deut 31:6 Deut 31:8 Josh 1:9 1Sam 16:7
Job 19:25 Eccl 3:1 Nah 1:7 Hab 3:19 Zeph 3:17 Mic 6:8
""".split()

_PHRASES = [
    "Dios es amor y su paz acompaña al cansado.",
    "El Señor es refugio en el día difícil.",
    "La esperanza renueva el ánimo de quien espera.",
    "Hay descanso para quien confía en Dios.",
    "El amor cubre lo que el miedo no puede.",
    "La paz llega despacio, como la luz del alba.",
    "El Señor escucha a quien lo llama con sencillez.",
    "Dios cuida de lo pequeño y de lo grande.",
]

def _sample_verses():
    by_osis = {b.osis: b for b in books_data.BOOKS}
    out = []
    for osis, cv in zip(_REFS[::2], _REFS[1::2]):
        c, v = (int(x) for x in cv.split(":"))
        out.append((by_osis[osis].id, c, v))
    assert len(set(out)) == len(out)
    return out


def _score(i: int, eligible: bool) -> float:
    if eligible:
        return round(0.97 - ((i * 7) % 33) / 100, 2)    # 0.65 .. 0.97
    return round(0.30 + ((i * 5) % 26) / 100, 2)        # 0.30 .. 0.55


def _real_texts(work_db: Path, ids):
    con = sqlite3.connect(work_db)
    rows = dict(con.execute("SELECT id, text FROM verses_raw"))
    con.close()
    return {i: rows[i] for i in ids}


# ---------------------------------------------------------------- reflexiones de muestra
_CONTEXT = [
    "[MUESTRA] Texto ficticio de contexto para {ref}. Aquí iría una breve explicación en lenguaje actual; solo se mencionan autor, destinatarios o fecha cuando son consenso.",
    "[MUESTRA] Este párrafo de ejemplo introduce el pasaje de {ref}. La versión final resumirá la situación que lo rodea, con palabras de hoy y sin afirmar datos dudosos.",
    "[MUESTRA] Contexto ficticio de {ref}. Una persona editora escribirá aquí una ayuda para entender el español de 1909, omitiendo lo que no sea seguro.",
]
_REFLECTION = [
    "{lead} el pasaje puede recordarnos que no caminamos solos. Podemos detenernos un momento, respirar despacio y reconocer lo que sentimos sin reprocharnos. Esta reflexión de muestra solo ilustra el tono: cercano, sereno y sin promesas concretas.",
    "{lead} podemos leer el versículo con calma, una sola vez más. A veces basta con quedarnos en una frase y dejar que nos acompañe. Este texto ficticio muestra el registro buscado: plural, sencillo y respetuoso con cada persona.",
    "{lead} el texto nos invita a mirar lo que tenemos delante sin prisa. No hace falta entenderlo todo hoy. Este ejemplo de muestra conserva el tono pastoral general, sin posturas propias de ninguna denominación.",
]
_SENSITIVE_EXTRA = (
    " Este dolor es real y merece tiempo; no hay una manera correcta de atravesarlo, "
    "y buscar la compañía de alguien de confianza también es un buen paso."
)
_APPLICATION = [
    "Hoy podemos elegir un gesto pequeño: leer despacio el versículo, compartirlo con alguien cercano o pasar unos minutos en silencio, a nuestro ritmo.",
    "Una idea sencilla para hoy: escribir la frase que más nos habló y llevarla con nosotros, sin exigirnos más de lo que podemos.",
    "Podemos terminar este momento agradeciendo algo concreto del día y dando un paso pequeño, al alcance de las manos.",
]
_PRAYER = [
    "Dios nuestro, presentamos ante Ti lo que sentimos hoy. Acompáñanos con calma y ayúdanos a descansar y a cuidar de quienes están a nuestro lado. Gracias por escucharnos. Amén.",
    "Señor, ponemos en tus manos esta necesidad. Danos serenidad para este día y gratitud por lo recibido. Pidamos juntos paz para nuestro corazón. Amén.",
    "Padre, gracias por este momento. Enséñanos a confiar y a ser amables con nosotros mismos y con los demás. Amén.",
]


def make_reflection(idx: int, ref: str, lead: str, sensitive: bool) -> dict:
    refl = _REFLECTION[idx % 3].format(lead=lead)
    if sensitive:
        refl += _SENSITIVE_EXTRA
    return {
        "context_text": _CONTEXT[idx % 3].format(ref=ref),
        "reflection_text": refl,
        "application_text": _APPLICATION[(idx // 3) % 3],
        "prayer_text": _PRAYER[(idx // 2) % 3],
    }


SENSITIVE_EMOTIONS = {"tristeza", "miedo", "soledad"}
SENSITIVE_MOMENTS = {"perdida-de-un-ser-querido", "familiar-enfermo", "antes-de-una-cita-medica"}


def build(path: Path, real_text: Path | None = None) -> str:
    refs = _sample_verses()
    con = contentdb.create(path)
    tid, mid = contentdb.insert_taxonomy(con)

    # ---- versiculos: 85 elegibles y 21 no elegibles, texto ficticio o real
    ids = [books_data.verse_id(*r) for r in refs]
    real = _real_texts(real_text, ids) if real_text else {}
    eligible: list[int] = []
    book_of: dict[int, int] = {}
    verse_rows = []
    for i, (b, c, v) in enumerate(refs):
        vid = ids[i]
        is_el = i % 5 != 4
        score = _score(i, is_el)
        text = real.get(vid) or f"[MUESTRA] Texto ficticio {i + 1:03d}. {_PHRASES[i % len(_PHRASES)]}"
        verse_rows.append((vid, b, c, v, text, normalize(text), score, 1 if is_el else 0))
        book_of[vid] = b
        if is_el:
            eligible.append(vid)
    con.executemany("INSERT INTO verses VALUES (?,?,?,?,?,?,?,?)", verse_rows)
    assert len(eligible) >= 60

    # ---- capitulos (los 1189, resumen ficticio)
    con.executemany(
        "INSERT INTO chapters(book_id, chapter, summary_es) VALUES (?,?,?)",
        [(b.id, c, f"[MUESTRA] Resumen ficticio de {b.name_es} {c}.")
         for b in books_data.BOOKS for c in range(1, b.chapters + 1)])

    # ---- verse_themes: ventana de 6 emociones fuertes (>=0.6) por versiculo elegible + 2 debiles
    em_slugs = taxonomy.EMOTION_SLUGS
    top_slugs = [t.slug for t in taxonomy.TOPICS]
    vt: dict[int, dict[str, float]] = {}
    for e, vid in enumerate(eligible):
        w: dict[str, float] = {}
        for j in range(6):
            w[em_slugs[(e + j) % 10]] = round(0.95 - 0.05 * j, 2)
        w[em_slugs[(e + 6) % 10]] = 0.45
        w[em_slugs[(e + 7) % 10]] = 0.35
        w[top_slugs[e % 5]] = 0.8
        w[top_slugs[(e + 2) % 5]] = 0.6
        vt[vid] = w
    for k, vid in enumerate(v for v in ids if v not in set(eligible)):
        vt[vid] = {em_slugs[k % 10]: 0.5, top_slugs[k % 5]: 0.4}
    con.executemany(
        "INSERT INTO verse_themes(theme_id, verse_id, weight) VALUES (?,?,?)",
        [(tid[s], vid, wt) for vid, d in vt.items() for s, wt in d.items() if wt >= taxonomy.THEME_MIN_WEIGHT])

    # ---- momentos: 18 versiculos elegibles por momento, con rank 1..18
    mv: dict[str, list[int]] = {}
    for m_i, m in enumerate(taxonomy.MOMENTS):
        picks = [eligible[(m_i * 6 + j) % len(eligible)] for j in range(18)]
        mv[m.slug] = picks
        con.executemany(
            "INSERT INTO moment_verses(moment_id, verse_id, rank) VALUES (?,?,?)",
            [(mid[m.slug], vid, r) for r, vid in enumerate(picks, start=1)])

    # ---- parecidos: 10 por versiculo elegible, max 2 del mismo libro, solo entre elegibles
    all_slugs = em_slugs + top_slugs
    vec = {}
    for vid in eligible:
        rnd = random.Random(vid)
        vec[vid] = [vt[vid].get(s, 0.0) for s in all_slugs] + [rnd.random() * 0.15 for _ in range(4)]
    sim_rows = []
    for vid in eligible:
        cands = [(o, cosine(vec[vid], vec[o])) for o in eligible if o != vid]
        for rank, (oid, sc) in enumerate(select_neighbors(cands, book_of), start=1):
            sim_rows.append((vid, rank, oid, round(sc, 4)))
    con.executemany("INSERT INTO verse_similar(verse_id, rank, similar_id, score) VALUES (?,?,?,?)", sim_rows)

    # ---- reflexiones aprobadas: 12 daily + 20 emotion (2 por emocion) + 12 moment
    refl_rows = []
    next_id = 1

    def ref_of(vid):
        return books_data.reference(vid)

    def add(vid, kind, theme=None, moment=None, lead="", sensitive=False, idx=0):
        nonlocal next_id
        blocks = make_reflection(idx, ref_of(vid), lead, sensitive)
        val = editorial.validate_reflection(blocks, vid)
        assert val.ok, (vid, kind, val.errors)
        n = val.word_count
        refl_rows.append((next_id, vid, kind, theme, moment, blocks["context_text"],
                          blocks["reflection_text"], blocks["application_text"],
                          blocks["prayer_text"], n, editorial.reading_seconds(n), int(sensitive), "approved"))
        next_id += 1
        return next_id - 1

    # calendario: 366 dias de un anio bisiesto, versiculos elegibles barajados con semilla fija
    start = datetime.date(2024, 1, 1)
    days = [(start + datetime.timedelta(days=d)).strftime("%m-%d") for d in range(366)]
    assert "02-29" in days and len(set(days)) == 366
    order = eligible[:]
    random.Random(7).shuffle(order)
    cal = {md: order[i % len(order)] for i, md in enumerate(days)}
    daily_rid: dict[str, int] = {}
    for i, md in enumerate(days[:12]):
        daily_rid[md] = add(cal[md], "daily", lead="Al comenzar este día,", idx=i)
    # emociones
    for e_i, slug in enumerate(em_slugs):
        name = taxonomy.EMOTIONS[e_i].name_es
        strong = [v for v in eligible if vt[v].get(slug, 0) >= taxonomy.EMOTION_STRONG_WEIGHT]
        for n_i, vid in enumerate((strong[0], strong[len(strong) // 2])):
            add(vid, "emotion", theme=tid[slug], lead=f"Pensando en el tema «{name}»,",
                sensitive=slug in SENSITIVE_EMOTIONS, idx=e_i * 2 + n_i)
    # momentos
    for m_i, m in enumerate(taxonomy.MOMENTS):
        add(mv[m.slug][0], "moment", moment=mid[m.slug], lead=f"Pensando en el momento «{m.name_es}»,",
            sensitive=m.slug in SENSITIVE_MOMENTS, idx=m_i)
    con.executemany(
        "INSERT INTO reflections(id, verse_id, kind, theme_id, moment_id, context_text, reflection_text,"
        " application_text, prayer_text, word_count, reading_seconds, sensitive, status)"
        " VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)", refl_rows)
    con.executemany(
        "INSERT INTO daily_calendar(month_day, verse_id, reflection_id) VALUES (?,?,?)",
        [(md, cal[md], daily_rid.get(md)) for md in days])

    con.commit()
    return contentdb.finalize(
        con, path, content_version=SAMPLE_VERSION, source_url="sample://sosiego/content_v2",
        verse_count_expected=len(verse_rows), is_sample=True, built_at=SAMPLE_BUILT_AT)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("out", nargs="?", type=Path, default=DEFAULT_OUT)
    ap.add_argument("--real-text", type=Path, default=None, help="work.db con la RV1909 ingerida")
    a = ap.parse_args(argv)
    digest = build(a.out, a.real_text)
    print(f"ok {a.out}  content_hash={digest[:16]}...")


if __name__ == "__main__":
    main()
