"""Etapa 2: etiquetado con Ollama (spec §5.2).

Por versiculo: temas/emociones de una LISTA CERRADA con peso 0..1 y `card_score` (que tan bien se
entiende el versiculo solo). Salida JSON validada contra esquema, con reintento. Cada salida se
guarda en work.db con prompt, modelo, temperatura (0.2) y semilla.

Uso:
  python -I run.py tag --model qwen2.5:7b --sample 50          # muestra aleatoria (semilla fija)
  python -I run.py tag --model qwen2.5:7b --limit 500          # los primeros 500 sin etiquetar
  python -I run.py tag --model qwen2.5:7b --task chapters      # resumen de una linea por capitulo
"""
from __future__ import annotations

import argparse
import random
import sqlite3
import sys
from pathlib import Path

from . import books_data, taxonomy, workdb
from . import ollama_client as oc

SYSTEM = (
    "Eres un asistente editorial para una app cristiana de versiculos (Reina-Valera 1909). "
    "Clasificas versiculos con una lista cerrada de temas. Respondes SOLO con JSON valido."
)

THEME_HELP = {
    "ansiedad": "preocupacion, afan, inquietud", "tristeza": "dolor, llanto, duelo, desanimo",
    "gratitud": "dar gracias, alabanza por lo recibido", "miedo": "temor, peligro, necesidad de valor",
    "soledad": "abandono, aislamiento, compania de Dios", "perdon": "perdonar, ser perdonado, reconciliacion",
    "esperanza": "futuro, promesa de ayuda, animo", "cansancio": "agotamiento, descanso, fuerzas",
    "enojo": "ira, rencor, dominio propio", "duda": "incertidumbre, falta de fe, preguntas",
    "amor": "amor de Dios o al projimo", "paz": "calma, serenidad", "fe": "confianza en Dios",
    "sabiduria": "guia, consejo, decisiones", "proteccion": "refugio, cuidado, amparo",
}


def build_schema() -> dict:
    return {
        "type": "object",
        "properties": {
            "themes": {
                "type": "array", "maxItems": 6,
                "items": {
                    "type": "object",
                    "properties": {"slug": {"type": "string", "enum": taxonomy.THEME_SLUGS},
                                   "weight": {"type": "number", "minimum": 0, "maximum": 1}},
                    "required": ["slug", "weight"], "additionalProperties": False,
                },
            },
            "card_score": {"type": "number", "minimum": 0, "maximum": 1},
        },
        "required": ["themes", "card_score"], "additionalProperties": False,
    }


def build_user_prompt(ref: str, text: str) -> str:
    themes = "\n".join(f"- {s}: {THEME_HELP[s]}" for s in taxonomy.THEME_SLUGS)
    return f"""Versiculo ({ref}): "{text}"

Lista CERRADA de temas (usa solo estos slugs):
{themes}

Tarea:
1. Elige hasta 6 temas que de verdad toque el versiculo, cada uno con un peso entre 0 y 1
   (1 = tema central, 0.6 = claro, 0.3 = tangencial). Si ninguno aplica, devuelve la lista vacia.
2. card_score entre 0 y 1: que tan bien se entiende el versiculo SOLO, sin contexto, como tarjeta para
   compartir. 1 = se entiende y conforta por si mismo; 0 = necesita contexto (genealogias, listas,
   leyes, nombres, narracion suelta).

Responde solo con JSON: {{"themes":[{{"slug":"...","weight":0.0}}],"card_score":0.0}}"""


def tag_one(con: sqlite3.Connection, vid: int, text: str, model: str, seed: int, retries: int,
            transport=None) -> bool:
    kwargs = {"transport": transport} if transport else {}
    res = oc.chat_json(model, SYSTEM, build_user_prompt(books_data.reference(vid), text),
                       build_schema(), seed=seed, retries=retries, **kwargs)
    cur = con.execute(
        "INSERT INTO generations(stage,key,model,prompt,temperature,seed,response,valid,error,attempts,"
        "duration_s,created_at) VALUES ('tag',?,?,?,?,?,?,?,?,?,?,?)",
        (str(vid), model, res.prompt, res.temperature, res.seed, res.raw, int(res.valid), res.error,
         res.attempts, res.duration_s, workdb.now_iso()))
    gid = cur.lastrowid
    if res.valid:
        con.execute("DELETE FROM verse_tags WHERE verse_id=?", (vid,))
        best: dict[str, float] = {}
        for t in res.data["themes"]:
            best[t["slug"]] = max(best.get(t["slug"], 0.0), float(t["weight"]))
        con.executemany(
            "INSERT INTO verse_tags(verse_id,theme_slug,weight,generation_id) VALUES (?,?,?,?)",
            [(vid, s, round(w, 3), gid) for s, w in best.items() if w >= taxonomy.THEME_MIN_WEIGHT])
        con.execute("INSERT INTO verse_scores(verse_id,card_score,generation_id) VALUES (?,?,?) "
                    "ON CONFLICT(verse_id) DO UPDATE SET card_score=excluded.card_score, "
                    "generation_id=excluded.generation_id", (vid, round(float(res.data["card_score"]), 3), gid))
    con.commit()
    return res.valid


# ------------------------------------------------------------------ resumenes de capitulo
def summarize_chapters(con, model: str, seed: int, retries: int, limit: int | None) -> int:
    schema = {"type": "object", "properties": {"summary": {"type": "string", "minLength": 10, "maxLength": 160}},
              "required": ["summary"], "additionalProperties": False}
    todo = con.execute("""SELECT b, c FROM (SELECT DISTINCT book_id b, chapter c FROM verses_raw)
                          WHERE NOT EXISTS (SELECT 1 FROM chapter_summaries s WHERE s.book_id=b AND s.chapter=c)
                          ORDER BY b, c""").fetchall()
    n = 0
    for b, c in todo[:limit]:
        text = " ".join(r[0] for r in con.execute(
            "SELECT text FROM verses_raw WHERE book_id=? AND chapter=? ORDER BY verse LIMIT 40", (b, c)))
        name = books_data.BY_ID[b].name_es
        user = (f'Texto de {name} {c} (RV1909, puede estar recortado): "{text}"\n\n'
                'Escribe UNA linea (maximo 140 caracteres) en espanol actual que diga de que trata el capitulo. '
                'Tono cristiano general, sin posturas doctrinales. Responde {"summary":"..."}')
        res = oc.chat_json(model, SYSTEM, user, schema, seed=seed, retries=retries)
        gid = con.execute(
            "INSERT INTO generations(stage,key,model,prompt,temperature,seed,response,valid,error,attempts,"
            "duration_s,created_at) VALUES ('chapter',?,?,?,?,?,?,?,?,?,?,?)",
            (f"{b}:{c}", model, res.prompt, res.temperature, res.seed, res.raw, int(res.valid), res.error,
             res.attempts, res.duration_s, workdb.now_iso())).lastrowid
        if res.valid:
            con.execute("INSERT INTO chapter_summaries(book_id,chapter,summary_es,status,generation_id) "
                        "VALUES (?,?,?,'draft',?)", (b, c, res.data["summary"].strip(), gid))
            n += 1
        con.commit()
    return n


def pick_verses(con, args) -> list[tuple[int, str]]:
    if args.ids:
        q = ",".join("?" * len(args.ids))
        return con.execute(f"SELECT id, text FROM verses_raw WHERE id IN ({q}) ORDER BY id", args.ids).fetchall()
    rows = con.execute("SELECT id, text FROM verses_raw ORDER BY id").fetchall()
    if args.sample:
        return random.Random(args.sample_seed).sample(rows, args.sample)
    done = {r[0] for r in con.execute("SELECT verse_id FROM verse_scores")}
    rows = [r for r in rows if r[0] not in done]
    return rows[: args.limit] if args.limit else rows


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--work", type=Path, default=workdb.DEFAULT_PATH)
    ap.add_argument("--model", default="qwen2.5:7b")
    ap.add_argument("--task", choices=["verses", "chapters"], default="verses")
    ap.add_argument("--limit", type=int)
    ap.add_argument("--sample", type=int, help="N versiculos al azar (reproducible con --sample-seed)")
    ap.add_argument("--sample-seed", type=int, default=2026)
    ap.add_argument("--ids", type=int, nargs="*")
    ap.add_argument("--seed", type=int, default=oc.DEFAULT_SEED)
    ap.add_argument("--retries", type=int, default=2)
    a = ap.parse_args(argv)
    sys.stdout.reconfigure(encoding="utf-8")
    try:
        models = oc.list_models()
    except oc.OllamaUnavailable as e:
        sys.exit(str(e))
    if a.model not in models:
        sys.exit(f"El modelo {a.model} no esta en `ollama list` ({models}). El pipeline NO descarga modelos.")
    con = workdb.connect(a.work)
    if a.task == "chapters":
        print("resumenes generados:", summarize_chapters(con, a.model, a.seed, a.retries, a.limit))
        return 0
    todo = pick_verses(con, a)
    ok = 0
    for i, (vid, text) in enumerate(todo, start=1):
        ok += tag_one(con, vid, text, a.model, a.seed, a.retries)
        if i % 10 == 0 or i == len(todo):
            print(f"{i}/{len(todo)} validos={ok}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
