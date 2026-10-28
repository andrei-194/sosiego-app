"""Etapa 5: borradores de reflexiones con estructura fija (spec §5.5).

Cuatro bloques (contexto, reflexion, aplicacion, oracion), 90-150 palabras en total. El prompt se
basa en la guia editorial (editorial.GUIDE_TEXT). Validadores automaticos (editorial.py): palabras,
ninguna referencia biblica distinta de la ancla, terminos prohibidos. Un borrador que no pasa se
reintenta con los errores como retroalimentacion; si aun asi falla queda como borrador con
`validation_errors` para que la revision lo corrija a mano.

Subcomandos:
  plan       crea el calendario (366 dias) y las 685 plazas de reflexiones pendientes
  generate   genera borradores para las plazas pendientes
  status     cuenta por estado

Uso:
  python -I run.py reflections plan
  python -I run.py reflections generate --model qwen2.5:7b --limit 20
"""
from __future__ import annotations

import argparse
import datetime
import sqlite3
import sys
from collections import defaultdict
from pathlib import Path

from . import books_data, editorial, taxonomy, workdb
from . import ollama_client as oc

SYSTEM = (
    "Eres redactor de una app cristiana de versiculos en espanol. Escribes reflexiones breves, serenas y "
    "respetuosas para personas de cualquier iglesia. Respondes SOLO con JSON valido.\n\n" + editorial.GUIDE_TEXT
)

SCHEMA = {
    "type": "object",
    "properties": {
        "context": {"type": "string", "minLength": 20},
        "reflection": {"type": "string", "minLength": 20},
        "application": {"type": "string", "minLength": 20},
        "prayer": {"type": "string", "minLength": 20},
        "sensitive": {"type": "boolean"},
    },
    "required": ["context", "reflection", "application", "prayer", "sensitive"],
    "additionalProperties": False,
}


def to_blocks(d: dict) -> dict:
    return {"context_text": d["context"].strip(), "reflection_text": d["reflection"].strip(),
            "application_text": d["application"].strip(), "prayer_text": d["prayer"].strip()}


def build_user_prompt(vid: int, text: str, kind: str, theme_slug=None, moment_slug=None) -> str:
    ref = books_data.reference(vid)
    if kind == "emotion":
        t = next(t for t in taxonomy.THEMES if t.slug == theme_slug)
        focus = f"Para una persona que hoy siente: {t.name_es.lower()}."
    elif kind == "moment":
        m = next(m for m in taxonomy.MOMENTS if m.slug == moment_slug)
        focus = f"Para el momento: {m.name_es.lower()} ({m.description})"
    else:
        focus = "Para el versiculo del dia, sin un tema en particular."
    return f"""Versiculo ancla ({ref}), Reina-Valera 1909: "{text}"
{focus}

Escribe una reflexion con EXACTAMENTE estos cuatro bloques, en espanol actual:
- context (30 a 40 palabras): explica el pasaje en lenguaje de hoy; autor/fecha solo si son consenso.
- reflection (45 a 60 palabras): que nos dice el versiculo ahora.
- application (25 a 35 palabras): un gesto pequeno y concreto para hoy, sin promesas.
- prayer (25 a 35 palabras): oracion en primera persona del plural.
Total aproximado: 130 palabras (limite duro: 90 a 150; los modelos suelen quedarse cortos, no lo hagas).
Puedes citar o parafrasear solo ESTE versiculo.
Si el tema es delicado (duelo, depresion, miedo a morir) marca sensitive=true; si no, false.

Responde solo con JSON: {{"context":"","reflection":"","application":"","prayer":"","sensitive":false}}"""


def generate_one(con: sqlite3.Connection, rid: int, model: str, seed: int, retries: int,
                 transport=None) -> bool:
    row = con.execute(
        "SELECT r.verse_id, r.kind, r.theme_slug, r.moment_slug, v.text FROM reflections r "
        "JOIN verses_raw v ON v.id=r.verse_id WHERE r.id=?", (rid,)).fetchone()
    vid, kind, th, mo, text = row

    def extra(d: dict) -> list[str]:
        return editorial.validate_reflection(to_blocks(d), vid).errors

    kwargs = {"transport": transport} if transport else {}
    res = oc.chat_json(model, SYSTEM, build_user_prompt(vid, text, kind, th, mo), SCHEMA, seed=seed,
                       retries=retries, extra_validator=extra, num_predict=700, **kwargs)
    gid = con.execute(
        "INSERT INTO generations(stage,key,model,prompt,temperature,seed,response,valid,error,attempts,"
        "duration_s,created_at) VALUES ('reflection',?,?,?,?,?,?,?,?,?,?,?)",
        (f"{vid}|{kind}|{th or mo or ''}", model, res.prompt, res.temperature, res.seed, res.raw,
         int(res.valid), res.error, res.attempts, res.duration_s, workdb.now_iso())).lastrowid
    data = res.data
    if data is None:                       # JSON invalido: intentar rescatar el ultimo texto para revisarlo
        try:
            import json
            data = json.loads(res.raw)
            to_blocks(data)
        except Exception:
            data = None
    if data is None:
        con.execute("UPDATE reflections SET validation_errors=?, generation_id=? WHERE id=?",
                    (res.error, gid, rid))
        con.commit()
        return False
    blocks = to_blocks(data)
    v = editorial.validate_reflection(blocks, vid)
    con.execute(
        "UPDATE reflections SET context_text=?, reflection_text=?, application_text=?, prayer_text=?, "
        "word_count=?, sensitive=?, status='draft', validation_errors=?, generation_id=? WHERE id=?",
        (*blocks.values(), v.word_count, int(bool(data.get("sensitive"))),
         "; ".join(v.errors) or None, gid, rid))
    con.commit()
    return v.ok


# ------------------------------------------------------------------ plan
def plan_calendar(con: sqlite3.Connection) -> int:
    """366 versiculos elegibles repartidos entre libros (round-robin por libro, mejor card_score primero)."""
    rows = con.execute(
        "SELECT v.id, v.book_id, s.card_score FROM verses_raw v JOIN verse_scores s ON s.verse_id=v.id "
        "WHERE s.card_score >= ? ORDER BY s.card_score DESC, v.id", (taxonomy.CARD_SCORE_THRESHOLD,)).fetchall()
    by_book: dict[int, list[int]] = defaultdict(list)
    for vid, b, _ in rows:
        by_book[b].append(vid)
    order: list[int] = []
    queues = [by_book[b] for b in sorted(by_book)]
    i = 0
    while len(order) < 366 and any(queues):
        for q in queues:
            if i < len(q) and len(order) < 366:
                order.append(q[i])
        i += 1
    if len(order) < 366:
        raise SystemExit(f"Solo hay {len(order)} versiculos elegibles; se necesitan 366 para el calendario")
    start = datetime.date(2024, 1, 1)
    days = [(start + datetime.timedelta(days=d)).strftime("%m-%d") for d in range(366)]
    con.execute("DELETE FROM daily_plan")
    con.executemany("INSERT INTO daily_plan(month_day, verse_id) VALUES (?,?)", list(zip(days, order)))
    con.commit()
    return 366


def _slot(con, vid, kind, theme=None, moment=None) -> None:
    con.execute("INSERT OR IGNORE INTO reflections(verse_id, kind, theme_slug, moment_slug) VALUES (?,?,?,?)",
                (vid, kind, theme, moment))


def plan_reflections(con: sqlite3.Connection) -> dict:
    if con.execute("SELECT COUNT(*) FROM daily_plan").fetchone()[0] != 366:
        plan_calendar(con)
    n = {"daily": 0, "emotion": 0, "moment": 0}
    for md, vid in con.execute("SELECT month_day, verse_id FROM daily_plan ORDER BY month_day"):
        if md != "02-29":                       # 365 reflexiones del dia; el 02-29 reutiliza el texto sin reflexion
            _slot(con, vid, "daily")
            n["daily"] += 1
    for slug in taxonomy.EMOTION_SLUGS:
        rows = con.execute(
            "SELECT t.verse_id FROM verse_tags t JOIN verse_scores s ON s.verse_id=t.verse_id "
            "WHERE t.theme_slug=? AND s.card_score >= ? ORDER BY t.weight DESC, s.card_score DESC, t.verse_id "
            "LIMIT ?", (slug, taxonomy.CARD_SCORE_THRESHOLD, taxonomy.REFLECTIONS_PER_EMOTION)).fetchall()
        for (vid,) in rows:
            _slot(con, vid, "emotion", theme=slug)
            n["emotion"] += 1
    for m in taxonomy.MOMENTS:
        rows = con.execute(
            "SELECT verse_id FROM moment_candidates WHERE moment_slug=? AND selected=1 ORDER BY rank LIMIT ?",
            (m.slug, taxonomy.REFLECTIONS_PER_MOMENT)).fetchall()
        for (vid,) in rows:
            _slot(con, vid, "moment", moment=m.slug)
            n["moment"] += 1
    con.commit()
    return n


def status(con) -> list[tuple]:
    return con.execute("SELECT kind, status, COUNT(*), SUM(word_count=0) FROM reflections GROUP BY kind, status").fetchall()


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("cmd", choices=["plan", "generate", "status"])
    ap.add_argument("--work", type=Path, default=workdb.DEFAULT_PATH)
    ap.add_argument("--model", default="qwen2.5:7b")
    ap.add_argument("--limit", type=int)
    ap.add_argument("--kind", choices=["daily", "emotion", "moment"])
    ap.add_argument("--redo-invalid", action="store_true", help="regenerar borradores con errores de validacion")
    ap.add_argument("--seed", type=int, default=oc.DEFAULT_SEED)
    ap.add_argument("--retries", type=int, default=2)
    a = ap.parse_args(argv)
    sys.stdout.reconfigure(encoding="utf-8")
    con = workdb.connect(a.work)
    if a.cmd == "plan":
        print("plazas creadas:", plan_reflections(con))
    elif a.cmd == "status":
        for r in status(con):
            print(r)
    else:
        try:
            models = oc.list_models()
        except oc.OllamaUnavailable as e:
            sys.exit(str(e))
        if a.model not in models:
            sys.exit(f"El modelo {a.model} no esta instalado (ollama list: {models}). No se descargan modelos.")
        cond = "word_count=0" + (" OR (status='draft' AND validation_errors IS NOT NULL)" if a.redo_invalid else "")
        sql = f"SELECT id FROM reflections WHERE ({cond})" + (" AND kind=?" if a.kind else "") + " ORDER BY id"
        ids = [r[0] for r in con.execute(sql, (a.kind,) if a.kind else ())][: a.limit]
        ok = 0
        for i, rid in enumerate(ids, start=1):
            ok += generate_one(con, rid, a.model, a.seed, a.retries)
            print(f"{i}/{len(ids)} validas_automaticas={ok}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
