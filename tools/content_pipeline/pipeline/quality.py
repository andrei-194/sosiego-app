"""Prueba de calidad del modelo antes de la generacion masiva (spec §5, "Calidad y reproducibilidad").

50 versiculos con el modelo elegido. Pasa si (a) >= 90% de las salidas es JSON valido, (b) ninguna
cita un versiculo inventado y (c) >= 80% de las reflexiones se acepta sin reescritura mayor.

El criterio (c) es HUMANO. Aqui se mide un sustituto automatico: porcentaje de reflexiones que
pasan TODOS los validadores (90-150 palabras, sin referencias ajenas, sin terminos prohibidos) en el
PRIMER intento. Hay que leer la muestra generada (work/quality_*.db, `review reflections`) para dar
el veredicto final de (c).

Trabaja en su propia base work/quality_<modelo>.db (copia de los 50 versiculos); no ensucia work.db.

Uso:
  python -I run.py quality --model qwen2.5:7b [--n 50] [--time-budget-min 90]
"""
from __future__ import annotations

import argparse
import json
import random
import re
import sys
import time
from pathlib import Path

from . import editorial, reflections, tag, workdb
from . import ollama_client as oc


def run(model: str, n: int, work_src: Path, seed: int, retries: int, time_budget_s: float | None) -> dict:
    src = workdb.connect(work_src)
    rows = src.execute("SELECT id, book_id, chapter, verse, text, text_norm, source_id FROM verses_raw ORDER BY id").fetchall()
    sample = random.Random(2026).sample(rows, n)
    qpath = workdb.ROOT / "work" / f"quality_{re.sub(r'[^A-Za-z0-9]+', '_', model)}.db"
    if qpath.exists():
        qpath.unlink()
    q = workdb.connect(qpath)
    q.execute("INSERT INTO sources(id,name,url,license_declared,license_evidence,downloaded_at,sha256,local_file,"
              "verse_count,chapter_count) VALUES (1,'quality-copy','','','','','','',0,0)")
    q.executemany("INSERT INTO verses_raw VALUES (?,?,?,?,?,?,1)", [r[:6] for r in sample])
    q.commit()

    t0 = time.time()
    tag_first_try = tag_valid = 0
    done_tags = 0
    for r in sample:
        vid, text = r[0], r[4]
        if time_budget_s and time.time() - t0 > time_budget_s / 2:
            break
        ok = tag.tag_one(q, vid, text, model, seed, retries)
        done_tags += 1
        tag_valid += ok
        g = q.execute("SELECT attempts FROM generations WHERE stage='tag' AND key=? ORDER BY id DESC", (str(vid),)).fetchone()
        tag_first_try += bool(ok and g[0] == 1)
        print(f"tag {done_tags}/{n} valido={ok}", flush=True)

    # reflexiones: sobre los versiculos ELEGIBLES de la muestra (card_score >= umbral), que son los que se usan
    # como ancla en la practica; si hay menos de 20, se completa con los de mayor card_score.
    scored = q.execute("SELECT verse_id, card_score FROM verse_scores ORDER BY card_score DESC, verse_id").fetchall()
    elig = [v for v, s in scored if s >= 0.6]
    anchors = elig if len(elig) >= 20 else [v for v, _ in scored[:20]]
    for vid in anchors:
        reflections._slot(q, vid, "daily")
    q.commit()
    ids = [r[0] for r in q.execute("SELECT id FROM reflections ORDER BY id")]
    refl_valid_json = auto_pass_first = auto_pass_final = invented = forbidden = out_of_range = 0
    done_r = 0
    for rid in ids:
        if time_budget_s and time.time() - t0 > time_budget_s:
            break
        passed = reflections.generate_one(q, rid, model, seed, retries)
        done_r += 1
        g = q.execute("SELECT attempts, valid, response FROM generations WHERE stage='reflection' ORDER BY id DESC LIMIT 1").fetchone()
        row = q.execute("SELECT verse_id, context_text, reflection_text, application_text, prayer_text, word_count "
                        "FROM reflections WHERE id=?", (rid,)).fetchone()
        has_blocks = row[5] > 0
        refl_valid_json += has_blocks
        auto_pass_final += passed
        auto_pass_first += bool(passed and g[0] == 1)
        if has_blocks:
            blocks = dict(zip(editorial.BLOCKS, row[1:5]))
            full = " ".join(blocks.values())
            invented += bool(editorial.foreign_references(full, row[0]))
            forbidden += bool(editorial.forbidden_terms_in(full))
            out_of_range += not (editorial.MIN_WORDS <= row[5] <= editorial.MAX_WORDS)
        print(f"refl {done_r}/{len(ids)} auto_ok={passed} intentos={g[0]}", flush=True)

    secs = time.time() - t0
    gens = q.execute("SELECT stage, COUNT(*), AVG(duration_s), AVG(attempts) FROM generations GROUP BY stage").fetchall()
    per = {s: {"n": c, "avg_s": round(a, 1), "avg_attempts": round(at, 2)} for s, c, a, at in gens}
    rep = {
        "model": model, "n_requested": n, "reflection_anchors": len(anchors), "eligible_in_sample": len(elig), "tag_done": done_tags, "reflections_done": done_r,
        "a_json_valid_tags_pct": round(100 * tag_valid / max(done_tags, 1), 1),
        "a_json_valid_tags_first_try_pct": round(100 * tag_first_try / max(done_tags, 1), 1),
        "a_json_valid_reflections_pct": round(100 * refl_valid_json / max(done_r, 1), 1),
        "b_reflections_with_foreign_reference": invented,
        "c_proxy_auto_pass_first_try_pct": round(100 * auto_pass_first / max(done_r, 1), 1),
        "c_proxy_auto_pass_after_retries_pct": round(100 * auto_pass_final / max(done_r, 1), 1),
        "forbidden_terms_in_drafts": forbidden, "word_count_out_of_range_drafts": out_of_range,
        "timing": per, "total_minutes": round(secs / 60, 1),
        "eta_all_verses_tag_hours": round(31084 * per.get("tag", {}).get("avg_s", 0) / 3600, 1),
        "eta_685_reflections_hours": round(685 * per.get("reflection", {}).get("avg_s", 0) / 3600, 1),
        "temperature": oc.DEFAULT_TEMPERATURE, "seed": seed,
        "note": "(c) real requiere lectura humana de work/" + qpath.name,
    }
    out = workdb.ROOT / "work" / f"quality_report_{re.sub(r'[^A-Za-z0-9]+', '_', model)}.json"
    out.write_text(json.dumps(rep, indent=1, ensure_ascii=False), encoding="utf-8")
    return rep


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--work", type=Path, default=workdb.DEFAULT_PATH)
    ap.add_argument("--model", default="qwen2.5:7b")
    ap.add_argument("--n", type=int, default=50)
    ap.add_argument("--seed", type=int, default=oc.DEFAULT_SEED)
    ap.add_argument("--retries", type=int, default=2)
    ap.add_argument("--time-budget-min", type=float, default=None, help="tope total; recorta la muestra si se pasa")
    a = ap.parse_args(argv)
    sys.stdout.reconfigure(encoding="utf-8")
    try:
        if a.model not in oc.list_models():
            sys.exit(f"{a.model} no esta en `ollama list`; el pipeline no descarga modelos.")
    except oc.OllamaUnavailable as e:
        sys.exit(str(e))
    rep = run(a.model, a.n, a.work, a.seed, a.retries, a.time_budget_min * 60 if a.time_budget_min else None)
    print(json.dumps(rep, indent=1, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
