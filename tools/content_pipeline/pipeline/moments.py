"""Etapa 4: momentos (spec §5.4). El modelo PROPONE candidatos; la persona elige 15-20 por momento.

1. `candidates`: por momento se preselecciona con las etiquetas (afinidad momento -> temas) y el
   modelo ordena/propone los mejores (JSON validado: solo ids de la lista).
2. `choose`: elegir a mano (interactivo) cuales entran y en que orden (rank).
   `auto-select` marca los N mejores sin preguntar (solo para ensayar; la eleccion real es humana).

Uso:
  python -I run.py moments candidates --model qwen2.5:7b [--moment antes-de-dormir]
  python -I run.py moments choose --moment antes-de-dormir
  python -I run.py moments auto-select --n 15        # ensayo
"""
from __future__ import annotations

import argparse
import sqlite3
import sys
from pathlib import Path

from . import books_data, taxonomy, workdb
from . import ollama_client as oc

AFFINITY = {   # momento -> temas cuyo peso suma en la preseleccion
    "al-despertar": ["gratitud", "esperanza", "paz", "fe"],
    "antes-de-dormir": ["cansancio", "ansiedad", "paz", "proteccion"],
    "antes-de-comer": ["gratitud", "amor"],
    "antes-de-un-viaje": ["proteccion", "miedo", "fe", "paz"],
    "antes-de-una-cita-medica": ["miedo", "ansiedad", "esperanza", "proteccion"],
    "familiar-enfermo": ["tristeza", "esperanza", "miedo", "amor", "soledad"],
    "entrevista-o-examen": ["ansiedad", "sabiduria", "fe", "miedo"],
    "problemas-de-dinero": ["ansiedad", "fe", "sabiduria", "esperanza"],
    "perdida-de-un-ser-querido": ["tristeza", "soledad", "esperanza", "paz"],
    "nacimiento-o-cumpleanos": ["gratitud", "amor", "esperanza"],
    "reconciliarse": ["perdon", "amor", "enojo", "paz"],
    "dar-gracias": ["gratitud", "amor", "fe"],
}
PRESELECT = 60       # candidatos que se muestran al modelo
PROPOSE = 25         # candidatos que el modelo propone por momento


def preselect(con: sqlite3.Connection, slug: str, n: int = PRESELECT) -> list[tuple[int, str, float]]:
    themes = AFFINITY[slug]
    q = ",".join("?" * len(themes))
    return con.execute(
        f"""SELECT v.id, v.text, SUM(t.weight) w FROM verse_tags t
            JOIN verses_raw v ON v.id=t.verse_id JOIN verse_scores s ON s.verse_id=v.id
            WHERE t.theme_slug IN ({q}) AND s.card_score >= ?
            GROUP BY v.id ORDER BY w DESC, s.card_score DESC, v.id LIMIT ?""",
        (*themes, taxonomy.CARD_SCORE_THRESHOLD, n)).fetchall()


def propose(con, slug: str, model: str, seed: int, retries: int, transport=None) -> int:
    pre = preselect(con, slug)
    if not pre:
        return 0
    allowed = {r[0] for r in pre}
    m = next(m for m in taxonomy.MOMENTS if m.slug == slug)
    listing = "\n".join(f'{vid}: ({books_data.reference(vid)}) "{text}"' for vid, text, _ in pre)
    user = (f"Momento: {m.name_es}. {m.description}\n\nVersiculos candidatos (id: texto):\n{listing}\n\n"
            f"Elige los {PROPOSE} que mejor acompanen ese momento, del mas al menos adecuado. Usa SOLO ids de la lista. "
            'Responde {"picks":[id,...]}')
    schema = {"type": "object", "properties": {"picks": {"type": "array", "items": {"type": "integer"},
              "minItems": 1, "maxItems": 40}}, "required": ["picks"], "additionalProperties": False}

    def extra(d):
        bad = [p for p in d["picks"] if p not in allowed]
        return [f"ids fuera de la lista: {bad[:5]}"] if bad else []

    kw = {"transport": transport} if transport else {}
    res = oc.chat_json(model, "Eres un asistente editorial de una app cristiana. Respondes SOLO JSON valido.",
                       user, schema, seed=seed, retries=retries, extra_validator=extra, num_predict=400, **kw)
    gid = con.execute(
        "INSERT INTO generations(stage,key,model,prompt,temperature,seed,response,valid,error,attempts,duration_s,created_at)"
        " VALUES ('moment',?,?,?,?,?,?,?,?,?,?,?)",
        (slug, model, res.prompt, res.temperature, res.seed, res.raw, int(res.valid), res.error,
         res.attempts, res.duration_s, workdb.now_iso())).lastrowid
    if not res.valid:
        con.commit()
        return 0
    con.execute("DELETE FROM moment_candidates WHERE moment_slug=? AND selected=0", (slug,))
    picks = list(dict.fromkeys(res.data["picks"]))
    for i, vid in enumerate(picks):
        con.execute("INSERT OR IGNORE INTO moment_candidates(moment_slug, verse_id, score, generation_id) VALUES (?,?,?,?)",
                    (slug, vid, round(1 - i / max(len(picks), 1), 3), gid))
    con.commit()
    return len(picks)


def auto_select(con, n: int) -> None:
    for m in taxonomy.MOMENTS:
        con.execute("UPDATE moment_candidates SET selected=0, rank=NULL WHERE moment_slug=?", (m.slug,))
        rows = con.execute("SELECT verse_id FROM moment_candidates WHERE moment_slug=? ORDER BY score DESC LIMIT ?",
                           (m.slug, n)).fetchall()
        for rank, (vid,) in enumerate(rows, start=1):
            con.execute("UPDATE moment_candidates SET selected=1, rank=? WHERE moment_slug=? AND verse_id=?",
                        (rank, m.slug, vid))
    con.commit()


def choose(con, slug: str) -> None:
    rows = con.execute(
        "SELECT c.verse_id, v.text FROM moment_candidates c JOIN verses_raw v ON v.id=c.verse_id "
        "WHERE c.moment_slug=? ORDER BY c.score DESC", (slug,)).fetchall()
    print(f"Momento {slug}: {len(rows)} candidatos")
    for i, (vid, text) in enumerate(rows, start=1):
        print(f"{i:3}. {books_data.reference(vid):<24} {text}")
    raw = input("Numeros elegidos en orden (15 a 20, separados por coma): ")
    nums = [int(x) for x in raw.replace(" ", "").split(",") if x]
    if not (15 <= len(nums) <= 20) or any(not 1 <= n <= len(rows) for n in nums) or len(set(nums)) != len(nums):
        sys.exit("Eleccion invalida: deben ser entre 15 y 20 numeros distintos de la lista.")
    con.execute("UPDATE moment_candidates SET selected=0, rank=NULL WHERE moment_slug=?", (slug,))
    for rank, n in enumerate(nums, start=1):
        con.execute("UPDATE moment_candidates SET selected=1, rank=? WHERE moment_slug=? AND verse_id=?",
                    (rank, slug, rows[n - 1][0]))
    con.commit()


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("cmd", choices=["candidates", "choose", "auto-select"])
    ap.add_argument("--work", type=Path, default=workdb.DEFAULT_PATH)
    ap.add_argument("--model", default="qwen2.5:7b")
    ap.add_argument("--moment", choices=taxonomy.MOMENT_SLUGS)
    ap.add_argument("--n", type=int, default=15)
    ap.add_argument("--seed", type=int, default=oc.DEFAULT_SEED)
    ap.add_argument("--retries", type=int, default=2)
    a = ap.parse_args(argv)
    sys.stdout.reconfigure(encoding="utf-8")
    con = workdb.connect(a.work)
    if a.cmd == "candidates":
        for m in ([a.moment] if a.moment else taxonomy.MOMENT_SLUGS):
            print(m, propose(con, m, a.model, a.seed, a.retries))
    elif a.cmd == "choose":
        if not a.moment:
            sys.exit("--moment es obligatorio")
        choose(con, a.moment)
    else:
        auto_select(con, a.n)
    return 0


if __name__ == "__main__":
    sys.exit(main())
