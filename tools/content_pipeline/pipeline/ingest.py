"""Etapa 1: ingesta de la Reina-Valera 1909 (spec §5.1).

Fuente: eBible.org (spaRV1909, USFM). La pagina de la traduccion y el archivo copr.htm del zip
declaran "Public Domain / Dominio Publico"; la ingesta ABORTA si no encuentra esa declaracion.
Se registran fuente, URL, fecha de descarga, SHA-256 y evidencia de licencia en work.db.

Seguridad: el zip NO se extrae a disco (se lee en memoria, solo nombres `NN-XXXspaRV1909.usfm`),
y cada descarga va a su propio directorio nuevo y vacio.

Uso:
  python -m pipeline.ingest --raw-dir work/raw/2026-10-28 [--cross-check work/raw/2026-10-28-vpl/spaRV1909_vpl.zip]
  python -m pipeline.ingest --raw-dir work/raw/2026-10-28 --zip-only   # ya descargado: no vuelve a bajar
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
import urllib.request
import zipfile
from datetime import datetime, timezone
from pathlib import Path

from . import books_data, workdb
from .normalize import normalize

SOURCE_NAME = "Santa Biblia - Reina Valera 1909 (eBible.org, spaRV1909)"
ZIP_URL = "https://ebible.org/Scriptures/spaRV1909_usfm.zip"
DETAILS_URL = "https://ebible.org/find/details.php?id=spaRV1909"
ZIP_NAME = "spaRV1909_usfm.zip"
DETAILS_NAME = "details.html"
EXPECTED_JSON = Path(__file__).resolve().parent.parent / "data" / "rv1909_expected.json"
_MEMBER_RE = re.compile(r"^\d{2}-([0-9A-Z]{3})spaRV1909\.usfm$")


class IngestError(RuntimeError):
    pass


# ------------------------------------------------------------------ descarga
def download(raw_dir: Path) -> None:
    if raw_dir.exists() and any(raw_dir.iterdir()):
        raise IngestError(f"{raw_dir} no esta vacio: cada descarga va en un directorio nuevo y vacio")
    raw_dir.mkdir(parents=True, exist_ok=True)
    for url, name in ((ZIP_URL, ZIP_NAME), (DETAILS_URL, DETAILS_NAME)):
        req = urllib.request.Request(url, headers={"User-Agent": "sosiego-pipeline/2"})
        with urllib.request.urlopen(req, timeout=120) as r:
            (raw_dir / name).write_bytes(r.read())


# ------------------------------------------------------------------ licencia
def verify_license(zip_path: Path, details_path: Path) -> dict:
    """Devuelve la evidencia; lanza IngestError si la fuente no declara dominio publico."""
    evidence = []
    with zipfile.ZipFile(zip_path) as z:
        if "copr.htm" in z.namelist():
            txt = re.sub(r"<[^>]+>", " ", z.read("copr.htm").decode("utf-8-sig", "replace"))
            if re.search(r"public domain|dominio p[uú]blico", txt, re.I):
                evidence.append("copr.htm dentro del zip: 'Public Domain' / 'Dominio Publico'")
    if details_path.exists():
        txt = re.sub(r"<[^>]+>", " ", details_path.read_text("utf-8", "replace"))
        if re.search(r"public domain", txt, re.I):
            evidence.append(f"{DETAILS_URL}: 'public domain'")
    if not evidence:
        raise IngestError("La fuente NO declara dominio publico: no se ingiere. Revisar alternativas.")
    return {"declared": "Public Domain / Dominio Publico", "evidence": "; ".join(evidence)}


# ------------------------------------------------------------------ parseo USFM
_W_RE = re.compile(r"\\\+?w\s+([^|\\]*?)(?:\|[^\\]*)?\\\+?w\*")   # tambien la forma anidada \+w
_CLOSE_RE = re.compile(r"\\\+?[A-Za-z0-9]+\*")
_OPEN_RE = re.compile(r"\\\+?[A-Za-z0-9]+ ?")


def clean_usfm_text(s: str) -> str:
    s = _W_RE.sub(r"\1", s)            # \w palabra|strong="H1"\w*  ->  palabra
    s = _CLOSE_RE.sub("", s)           # \add*  (cierre; el espacio que sigue SI es texto)
    s = _OPEN_RE.sub("", s)            # \add   (apertura; su UN espacio separador no es texto)
    return " ".join(s.split())


def parse_usfm_zip(zip_path: Path) -> list[tuple[int, int, int, str]]:
    """-> [(book_id, chapter, verse, text)] en orden. Sin extraer a disco."""
    out: list[tuple[int, int, int, str]] = []
    with zipfile.ZipFile(zip_path) as z:
        members = sorted(n for n in z.namelist() if _MEMBER_RE.match(n))
        for name in members:
            code = _MEMBER_RE.match(name).group(1)
            if code not in books_data.BY_USFM:
                raise IngestError(f"codigo USFM desconocido: {code}")
            book = books_data.BY_USFM[code]
            chapter = 0
            cur: list | None = None
            for line in z.read(name).decode("utf-8-sig").splitlines():
                m = re.match(r"\\c\s+(\d+)", line)
                if m:
                    chapter = int(m.group(1))
                    cur = None
                    continue
                m = re.match(r"\\v\s+(\d+)(?:-(\d+))?\s*(.*)$", line)
                if m:
                    if m.group(2):
                        raise IngestError(f"{code} {chapter}:{m.group(1)}-{m.group(2)}: rango de versiculos no soportado")
                    cur = [book.id, chapter, int(m.group(1)), m.group(3)]
                    out.append(cur)  # type: ignore[arg-type]
                    continue
                if cur is not None and line and not line.startswith("\\"):
                    cur[3] += " " + line      # continuacion de linea
    return [(b, c, v, clean_usfm_text(t)) for b, c, v, t in out]  # type: ignore[misc]


# ------------------------------------------------------------------ verificaciones (sin perdidas)
def check_lossless(verses: list[tuple[int, int, int, str]]) -> dict:
    errors: list[str] = []
    per_book: dict[int, dict[int, list[int]]] = {}
    for b, c, v, t in verses:
        per_book.setdefault(b, {}).setdefault(c, []).append(v)
        if re.search(r"[\\|]|strong=|\\\*", t):
            errors.append(f"marcas USFM sin limpiar en {b}:{c}:{v}: {t[:60]}")
    if sorted(per_book) != list(range(1, 67)):
        errors.append(f"libros presentes: {len(per_book)} (esperado 66)")
    n_chapters = 0
    for b, chs in per_book.items():
        exp = books_data.BY_ID[b].chapters
        if sorted(chs) != list(range(1, exp + 1)):
            errors.append(f"{books_data.BY_ID[b].name_es}: capitulos {len(chs)} != {exp}")
        n_chapters += len(chs)
        for c, vs in chs.items():
            if vs != list(range(1, len(vs) + 1)):
                errors.append(f"{books_data.BY_ID[b].name_es} {c}: versiculos no contiguos")
    return {"verses": len(verses), "chapters": n_chapters, "errors": errors}


def cross_check_vpl(verses, vpl_zip: Path) -> list[str]:
    """Compara cada versiculo con el formato VPL de la misma fuente (texto plano independiente)."""
    with zipfile.ZipFile(vpl_zip) as z:
        name = next(n for n in z.namelist() if n.endswith("_vpl.txt"))
        lines = z.read(name).decode("utf-8-sig").splitlines()
    mine = {(b, c, v): t for b, c, v, t in verses}
    errs: list[str] = []
    seen = 0
    order: dict[str, int] = {}     # VPL usa sus propios codigos (p. ej. SOL): se mapean por orden canonico
    for ln in lines:
        m = re.match(r"([0-9A-Z]{3}) (\d+):(\d+) (.*)$", ln)
        if not m:
            errs.append(f"linea VPL no reconocida: {ln[:50]}")
            continue
        order.setdefault(m.group(1), len(order) + 1)
        key = (order[m.group(1)], int(m.group(2)), int(m.group(3)))
        seen += 1
        # VPL marca con [corchetes] las palabras anadidas por los traductores (\add en USFM)
        vpl_text = " ".join(m.group(4).replace("[", "").replace("]", "").split())
        if vpl_text != mine.get(key):
            errs.append(f"difiere {m.group(1)} {m.group(2)}:{m.group(3)}")
    if seen != len(verses):
        errs.append(f"VPL tiene {seen} versiculos y el USFM {len(verses)}")
    return errs


# ------------------------------------------------------------------ carga
def load_into_work(work: Path, raw_dir: Path, verses, lic: dict, cross: str | None) -> int:
    zip_path = raw_dir / ZIP_NAME
    con = workdb.connect(work)
    sha = hashlib.sha256(zip_path.read_bytes()).hexdigest()
    mtime = datetime.fromtimestamp(zip_path.stat().st_mtime, timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    con.execute("DELETE FROM verses_raw")
    con.execute("DELETE FROM sources")
    cur = con.execute(
        "INSERT INTO sources(name,url,license_declared,license_evidence,downloaded_at,sha256,local_file,"
        "verse_count,chapter_count) VALUES (?,?,?,?,?,?,?,?,?)",
        (SOURCE_NAME, ZIP_URL, lic["declared"], lic["evidence"], mtime, sha,
         str(zip_path.relative_to(workdb.ROOT)) if zip_path.is_relative_to(workdb.ROOT) else str(zip_path),
         len(verses), len({(b, c) for b, c, _, _ in verses})))
    sid = cur.lastrowid
    con.executemany(
        "INSERT INTO verses_raw(id,book_id,chapter,verse,text,text_norm,source_id) VALUES (?,?,?,?,?,?,?)",
        [(books_data.verse_id(b, c, v), b, c, v, t, normalize(t), sid) for b, c, v, t in verses])
    workdb.set_meta(con, "expected_verse_count", len(verses))
    workdb.set_meta(con, "source_url", ZIP_URL)
    if cross:
        workdb.set_meta(con, "cross_check", cross)
    con.commit()
    con.close()
    return sid


def pin_expected(verses, empties=()) -> dict:
    """Escribe data/rv1909_expected.json (el conteo fijado; lo lee la prueba de datos 1)."""
    per_book = {books_data.BY_ID[b].osis: 0 for b in range(1, 67)}
    for b, *_ in verses:
        per_book[books_data.BY_ID[b].osis] += 1
    data = {
        "source": ZIP_URL, "translation": "RV1909",
        "total_verses": len(verses),                       # cargados (con texto)
        "source_verse_slots": len(verses) + len(empties),  # entradas \\v de la fuente
        "empty_in_source": [f"{books_data.BY_ID[b].osis} {c}:{v}" for b, c, v, _ in empties],
        "total_chapters": len({(b, c) for b, c, _, _ in verses}),
        "per_book_verses": per_book,
    }
    EXPECTED_JSON.parent.mkdir(parents=True, exist_ok=True)
    EXPECTED_JSON.write_text(json.dumps(data, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    return data


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--raw-dir", type=Path, required=True, help="directorio NUEVO y vacio para la descarga")
    ap.add_argument("--work", type=Path, default=workdb.DEFAULT_PATH)
    ap.add_argument("--zip-only", action="store_true", help="no descargar: usar el zip ya presente en --raw-dir")
    ap.add_argument("--cross-check", type=Path, help="zip VPL (spaRV1909_vpl.zip) para comparar verso a verso")
    ap.add_argument("--pin", action="store_true", help="(re)escribir data/rv1909_expected.json con el conteo obtenido")
    a = ap.parse_args(argv)
    sys.stdout.reconfigure(encoding="utf-8")

    if not a.zip_only:
        download(a.raw_dir)
    zip_path = a.raw_dir / ZIP_NAME
    lic = verify_license(zip_path, a.raw_dir / DETAILS_NAME)
    print("(a) licencia:", lic["declared"], "|", lic["evidence"])
    verses = parse_usfm_zip(zip_path)
    rep = check_lossless(verses)
    print(f"(b) versiculos: {rep['verses']}  capitulos: {rep['chapters']}")
    cross = None
    if a.cross_check:
        diffs = cross_check_vpl(verses, a.cross_check)
        rep["errors"] += diffs
        cross = f"VPL: {len(diffs)} diferencias"
        print("    cross-check VPL:", cross)
    if rep["errors"]:
        print("(c) ERRORES de integridad:")
        for e in rep["errors"][:30]:
            print("   -", e)
        return 1
    print("(c) parseo sin perdidas: OK (66 libros, capitulos y versiculos contiguos, sin marcas USFM residuales)")
    # Versiculos que la fuente publica SIN texto (cambios de versificacion en la RV1909; el VPL
    # tambien los trae vacios). No se cargan: content.db no admite texto vacio.
    empties = [x for x in verses if not x[3]]
    verses = [x for x in verses if x[3]]
    print(f"    versiculos sin texto en la fuente (omitidos): {len(empties)} -> {len(verses)} cargados")
    if a.pin or not EXPECTED_JSON.exists():
        pin_expected(verses, empties)
        print("    conteo fijado en", EXPECTED_JSON)
    else:
        exp = json.loads(EXPECTED_JSON.read_text("utf-8"))["total_verses"]
        if exp != len(verses):
            print(f"ERROR: conteo {len(verses)} != fijado {exp}")
            return 1
    load_into_work(a.work, a.raw_dir, verses, lic, cross)
    print("cargado en", a.work)
    return 0


if __name__ == "__main__":
    sys.exit(main())
