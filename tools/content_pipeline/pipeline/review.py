"""Etapa 6: revision humana (spec §5.6). CLI para leer y aprobar / editar / rechazar cada reflexion.

Solo las reflexiones en estado 'approved' se exportan. Aprobar exige pasar los validadores
automaticos; si no pasan hay que editar primero. Se registra el tiempo de cada revision.

Teclas:  a aprobar | e editar (abre el editor) | s marcar/quitar sensible | r rechazar | k saltar | q salir

Uso:
  python -I run.py review reflections [--kind emotion] [--only-valid]
  python -I run.py review stats
  python -I run.py review tags --sample 300      # coincidencia humano vs modelo en etiquetas
  python -I run.py review tags-report
"""
from __future__ import annotations

import argparse
import os
import subprocess
import sys
import tempfile
import time
from pathlib import Path

from . import books_data, editorial, taxonomy, workdb

HEADERS = [("context_text", "CONTEXTO"), ("reflection_text", "REFLEXION"),
           ("application_text", "APLICACION"), ("prayer_text", "ORACION")]


class ReviewError(ValueError):
    pass


def _blocks(con, rid) -> tuple[int, dict]:
    row = con.execute("SELECT verse_id, context_text, reflection_text, application_text, prayer_text "
                      "FROM reflections WHERE id=?", (rid,)).fetchone()
    return row[0], dict(zip([k for k, _ in HEADERS], row[1:]))


def apply_review(con, rid: int, action: str, seconds: int, blocks: dict | None = None,
                 sensitive: bool | None = None) -> editorial.Validation | None:
    """Nucleo testeable de la revision. action: approve | edit_approve | reject | skip."""
    if action not in ("approve", "edit_approve", "reject", "skip"):
        raise ReviewError(f"accion desconocida: {action}")
    vid, cur = _blocks(con, rid)
    val = None
    if action in ("approve", "edit_approve"):
        new = blocks or cur
        val = editorial.validate_reflection(new, vid)
        if not val.ok:
            raise ReviewError("no pasa los validadores: " + "; ".join(val.errors))
        sets = ["status='approved'", "word_count=?", "validation_errors=NULL", "edited=?"]
        params: list = [val.word_count, 1 if action == "edit_approve" else 0]
        for k, v in new.items():
            sets.append(f"{k}=?")
            params.append(v.strip())
        if sensitive is not None:
            sets.append("sensitive=?")
            params.append(int(sensitive))
        con.execute(f"UPDATE reflections SET {', '.join(sets)}, review_seconds=review_seconds+?, reviewed_at=? WHERE id=?",
                    (*params, seconds, workdb.now_iso(), rid))
        log = "edited_approved" if action == "edit_approve" else "approved"
    elif action == "reject":
        con.execute("UPDATE reflections SET status='rejected', review_seconds=review_seconds+?, reviewed_at=? WHERE id=?",
                    (seconds, workdb.now_iso(), rid))
        log = "rejected"
    else:
        log = "skipped"
    con.execute("INSERT INTO review_log(reflection_id, action, seconds, at) VALUES (?,?,?,?)",
                (rid, log, seconds, workdb.now_iso()))
    con.commit()
    return val


def render(con, rid: int) -> str:
    vid, blocks = _blocks(con, rid)
    row = con.execute("SELECT r.kind, r.theme_slug, r.moment_slug, r.sensitive, r.validation_errors, v.text "
                      "FROM reflections r JOIN verses_raw v ON v.id=r.verse_id WHERE r.id=?", (rid,)).fetchone()
    kind, th, mo, sens, errs, text = row
    out = [f"\n=== #{rid}  {books_data.reference(vid)}  [{kind}{' / ' + (th or mo) if (th or mo) else ''}]"
           f"{'  SENSIBLE' if sens else ''} ===", f'"{text}"', ""]
    for k, h in HEADERS:
        out += [f"[{h}]", blocks[k], ""]
    v = editorial.validate_reflection(blocks, vid)
    out.append(f"palabras: {v.word_count}   validadores: {'OK' if v.ok else 'FALLAN: ' + '; '.join(v.errors)}")
    for w in v.warnings:
        out.append("aviso: " + w)
    return "\n".join(out)


def edit_in_editor(blocks: dict) -> dict:
    body = "".join(f"### {h}\n{blocks[k]}\n\n" for k, h in HEADERS)
    editor = os.environ.get("EDITOR") or ("notepad" if os.name == "nt" else "nano")
    with tempfile.NamedTemporaryFile("w+", suffix=".md", delete=False, encoding="utf-8") as f:
        f.write(body)
        path = f.name
    try:
        subprocess.call([editor, path])
        text = Path(path).read_text(encoding="utf-8")
    finally:
        os.unlink(path)
    out, cur = {}, None
    for line in text.splitlines():
        if line.startswith("### "):
            cur = next((k for k, h in HEADERS if h == line[4:].strip()), None)
            out[cur] = [] if cur else None
        elif cur:
            out[cur].append(line)
    return {k: "\n".join(v).strip() for k, v in out.items() if k}


def review_loop(con, kind=None, only_valid=False) -> None:
    sql = "SELECT id FROM reflections WHERE status='draft' AND word_count>0"
    params: tuple = ()
    if kind:
        sql += " AND kind=?"
        params = (kind,)
    if only_valid:
        sql += " AND validation_errors IS NULL"
    ids = [r[0] for r in con.execute(sql + " ORDER BY id", params)]
    print(f"{len(ids)} borradores por revisar")
    for rid in ids:
        print(render(con, rid))
        t0 = time.time()
        while True:
            key = input("[a]probar [e]ditar [s]ensible [r]echazar s[k]ip [q]uit > ").strip().lower()
            secs = int(time.time() - t0)
            try:
                if key == "a":
                    apply_review(con, rid, "approve", secs)
                elif key == "e":
                    _, cur = _blocks(con, rid)
                    apply_review(con, rid, "edit_approve", secs, blocks=edit_in_editor(cur))
                elif key == "s":
                    con.execute("UPDATE reflections SET sensitive = 1 - sensitive WHERE id=?", (rid,))
                    con.commit()
                    print("sensible =", con.execute("SELECT sensitive FROM reflections WHERE id=?", (rid,)).fetchone()[0])
                    continue
                elif key == "r":
                    apply_review(con, rid, "reject", secs)
                elif key == "k":
                    apply_review(con, rid, "skip", secs)
                elif key == "q":
                    return
                else:
                    continue
                break
            except ReviewError as e:
                print("NO APROBADA:", e, "-> usa [e]ditar")


def stats(con) -> str:
    st = dict(con.execute("SELECT status, COUNT(*) FROM reflections GROUP BY status").fetchall())
    secs = con.execute("SELECT COUNT(*), COALESCE(AVG(review_seconds),0) FROM reflections WHERE review_seconds>0").fetchone()
    edited = con.execute("SELECT COUNT(*) FROM reflections WHERE edited=1").fetchone()[0]
    return f"estados={st}  revisadas_con_tiempo={secs[0]}  promedio_s={secs[1]:.0f}  editadas={edited}"


# ------------------------------------------------------------------ etiquetas (muestra)
def tags_session(con, n: int) -> None:
    rows = con.execute(
        "SELECT v.id, v.text FROM verses_raw v WHERE EXISTS (SELECT 1 FROM verse_tags t WHERE t.verse_id=v.id) "
        "AND v.id NOT IN (SELECT verse_id FROM tag_review) ORDER BY (v.id * 2654435761) % 1000003 LIMIT ?", (n,)).fetchall()
    print("Escribe los slugs correctos separados por coma (enter = de acuerdo con el modelo, q = salir).")
    print("Temas:", ", ".join(taxonomy.THEME_SLUGS))
    for vid, text in rows:
        model = [r[0] for r in con.execute(
            "SELECT theme_slug FROM verse_tags WHERE verse_id=? AND weight>=? ORDER BY weight DESC",
            (vid, taxonomy.EMOTION_STRONG_WEIGHT))]
        print(f"\n{books_data.reference(vid)}: {text}\n modelo: {', '.join(model) or '(ninguno)'}")
        ans = input("> ").strip().lower()
        if ans == "q":
            return
        human = model if ans == "" else [x for x in ans.replace(" ", "").split(",") if x in taxonomy.THEME_SLUGS]
        con.execute("INSERT OR REPLACE INTO tag_review VALUES (?,?,?,?,?)",
                    (vid, ",".join(sorted(model)), ",".join(sorted(human)), int(set(model) == set(human)), workdb.now_iso()))
        con.commit()


def tags_report(con) -> str:
    n, agree = con.execute("SELECT COUNT(*), COALESCE(SUM(agree),0) FROM tag_review").fetchone()
    return f"etiquetas revisadas={n} coincidencia exacta={agree}/{n} ({(100 * agree / n) if n else 0:.0f}%)"


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("cmd", choices=["reflections", "stats", "tags", "tags-report"])
    ap.add_argument("--work", type=Path, default=workdb.DEFAULT_PATH)
    ap.add_argument("--kind", choices=["daily", "emotion", "moment"])
    ap.add_argument("--only-valid", action="store_true")
    ap.add_argument("--sample", type=int, default=300)
    a = ap.parse_args(argv)
    sys.stdout.reconfigure(encoding="utf-8")
    con = workdb.connect(a.work)
    if a.cmd == "reflections":
        review_loop(con, a.kind, a.only_valid)
    elif a.cmd == "stats":
        print(stats(con))
    elif a.cmd == "tags":
        tags_session(con, a.sample)
    else:
        print(tags_report(con))
    return 0


if __name__ == "__main__":
    sys.exit(main())
