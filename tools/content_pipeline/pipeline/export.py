"""Etapa 7: exportacion a content.db v2 (spec §5.7 y §6).

Lee work.db y genera la base de la app: versiculos, temas, momentos, parecidos, calendario y SOLO
reflexiones 'approved'. Luego: indices, FTS5 'rebuild', PRAGMA integrity_check, foreign_key_check,
VACUUM, content_version, content_hash, y corre las pruebas de datos (tests/test_data_invariants.py)
contra el archivo generado. Si alguna falla, sale con codigo 1 y NO hay que empaquetar el archivo.

Uso:
  python -I run.py export --out out/content.db
  python -I run.py export --out out/content.db --release --help-line-number "<verificado>" --help-line-text "<texto>"

--release activa ademas las puertas de publicacion (linea de ayuda real, 685 reflexiones, no muestra).
Nunca escribe en assets/: copiar el resultado a mano (o con el script de la app) cuando se decida.
"""
from __future__ import annotations

import argparse
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

from . import contentdb, taxonomy, workdb

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_OUT = ROOT / "out" / "content.db"


def build_content(work: Path, out: Path, *, content_version: str, strict: bool,
                  help_text: str | None, help_number: str | None) -> dict:
    w = workdb.connect(work)
    n_verses = w.execute("SELECT COUNT(*) FROM verses_raw").fetchone()[0]
    if not n_verses:
        raise contentdb.ExportError("work.db no tiene versiculos: corre `ingest` primero")
    con = contentdb.create(out)
    tid, mid = contentdb.insert_taxonomy(con)

    scores = dict(w.execute("SELECT verse_id, card_score FROM verse_scores"))
    rows = []
    for vid, b, c, v, text, norm in w.execute(
            "SELECT id, book_id, chapter, verse, text, text_norm FROM verses_raw ORDER BY id"):
        s = float(scores.get(vid, 0.0))
        rows.append((vid, b, c, v, text, norm, s, 1 if s >= taxonomy.CARD_SCORE_THRESHOLD else 0))
    con.executemany("INSERT INTO verses VALUES (?,?,?,?,?,?,?,?)", rows)
    eligible = {r[0] for r in rows if r[7]}

    # capitulos: resumen aprobado; si falta, '' (NOT NULL) y aviso
    summ = {(b, c): s for b, c, s in w.execute(
        "SELECT book_id, chapter, summary_es FROM chapter_summaries WHERE status='approved'")}
    chapters = [(b, c) for b, c in w.execute("SELECT DISTINCT book_id, chapter FROM verses_raw ORDER BY 1, 2")]
    missing = [bc for bc in chapters if bc not in summ]
    if missing and strict:
        raise contentdb.ExportError(f"{len(missing)} capitulos sin resumen aprobado (--strict)")
    con.executemany("INSERT INTO chapters(book_id, chapter, summary_es) VALUES (?,?,?)",
                    [(b, c, summ.get((b, c), "")) for b, c in chapters])

    con.executemany(
        "INSERT INTO verse_themes(theme_id, verse_id, weight) VALUES (?,?,?)",
        [(tid[s], vid, wt) for vid, s, wt in w.execute("SELECT verse_id, theme_slug, weight FROM verse_tags")
         if s in tid and wt >= taxonomy.THEME_MIN_WEIGHT])
    con.executemany(
        "INSERT INTO moment_verses(moment_id, verse_id, rank) VALUES (?,?,?)",
        [(mid[m], vid, r) for m, vid, r in w.execute(
            "SELECT moment_slug, verse_id, rank FROM moment_candidates WHERE selected=1 ORDER BY moment_slug, rank")])
    con.executemany(
        "INSERT INTO verse_similar(verse_id, rank, similar_id, score) VALUES (?,?,?,?)",
        [(v, r, s, sc) for v, r, s, sc in w.execute("SELECT verse_id, rank, similar_id, score FROM similar")
         if v in eligible and s in eligible])

    # reflexiones: SOLO aprobadas
    new_id: dict[int, int] = {}
    refl = []
    for i, r in enumerate(w.execute(
            "SELECT id, verse_id, kind, theme_slug, moment_slug, context_text, reflection_text, application_text,"
            " prayer_text, word_count, sensitive FROM reflections WHERE status='approved' ORDER BY id"), start=1):
        (wid, vid, kind, th, mo, c, rf, a, p, wc, sens) = r
        new_id[wid] = i
        refl.append((i, vid, kind, tid.get(th) if th else None, mid.get(mo) if mo else None, c, rf, a, p, wc,
                     contentdb_reading(wc), sens, "approved"))
    con.executemany(
        "INSERT INTO reflections(id, verse_id, kind, theme_id, moment_id, context_text, reflection_text,"
        " application_text, prayer_text, word_count, reading_seconds, sensitive, status)"
        " VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)", refl)
    daily = {}
    for r in refl:
        if r[2] == "daily":
            daily.setdefault(r[1], r[0])
    plan = w.execute("SELECT month_day, verse_id FROM daily_plan ORDER BY month_day").fetchall()
    con.executemany("INSERT INTO daily_calendar(month_day, verse_id, reflection_id) VALUES (?,?,?)",
                    [(md, vid, daily.get(vid)) for md, vid in plan])

    if help_text:
        contentdb.set_meta(con, help_line_text=help_text)
    if help_number:
        contentdb.set_meta(con, help_line_number=help_number)
    con.commit()
    digest = contentdb.finalize(
        con, out, content_version=content_version,
        source_url=workdb.get_meta(w, "source_url", "") or "", verse_count_expected=len(rows), is_sample=False)
    return {"verses": len(rows), "eligible": len(eligible), "reflections": len(refl),
            "calendar": len(plan), "chapters_without_summary": len(missing), "hash": digest}


def contentdb_reading(words: int) -> int:
    from .editorial import reading_seconds
    return reading_seconds(words)


def run_data_tests(db_path: Path, release: bool) -> int:
    env = dict(os.environ, SOSIEGO_CONTENT_DB=str(db_path))
    env["SOSIEGO_RELEASE"] = "1" if release else "0"
    cmd = [sys.executable, "-m", "pytest", "-q", "-p", "no:cacheprovider",
           str(ROOT / "tests" / "test_data_invariants.py"), "--content-db", str(db_path)]
    return subprocess.call(cmd, cwd=ROOT, env=env)


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--work", type=Path, default=workdb.DEFAULT_PATH)
    ap.add_argument("--out", type=Path, default=DEFAULT_OUT)
    ap.add_argument("--content-version", default=datetime.now(timezone.utc).strftime("%Y%m%d%H%M"),
                    help="entero creciente (por defecto UTC AAAAMMDDHHMM); la app compara como numero")
    ap.add_argument("--strict", action="store_true", help="exigir resumen aprobado en los 1189 capitulos")
    ap.add_argument("--release", action="store_true")
    ap.add_argument("--help-line-text")
    ap.add_argument("--help-line-number")
    ap.add_argument("--skip-tests", action="store_true")
    a = ap.parse_args(argv)
    sys.stdout.reconfigure(encoding="utf-8")
    if "assets" in {p.lower() for p in a.out.resolve().parts}:
        sys.exit("Por seguridad el export no escribe dentro de assets/: usa --out out/content.db y copia a mano.")
    if a.release:
        if not (a.help_line_number and a.help_line_text) or "PLACEHOLDER" in (a.help_line_number + a.help_line_text):
            sys.exit("--release exige --help-line-text y --help-line-number reales (verificados con fuente oficial).")
        a.strict = True
    try:
        info = build_content(a.work, a.out, content_version=a.content_version, strict=a.strict,
                             help_text=a.help_line_text, help_number=a.help_line_number)
    except contentdb.ExportError as e:
        sys.exit(f"EXPORT FALLIDO: {e}")
    print("exportado", a.out, info)
    if info["chapters_without_summary"]:
        print(f"AVISO: {info['chapters_without_summary']} capitulos sin resumen aprobado (summary_es = '')")
    if a.skip_tests:
        return 0
    rc = run_data_tests(a.out, a.release)
    print("pruebas de datos:", "OK" if rc == 0 else "FALLARON (no empaquetar este archivo)")
    return rc


if __name__ == "__main__":
    sys.exit(main())
