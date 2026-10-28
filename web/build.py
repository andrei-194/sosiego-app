"""Generador de la web de enlaces de Sosiego (spec seccion 9).

Lee un content.db (esquema de la seccion 6), aplica plantillas Jinja2 y escribe dist/:

  dist/index.html                      portada            -> /
  dist/privacidad.html                 politica           -> /privacidad
  dist/v/{slug}-{capitulo}-{versiculo}.html                -> /v/juan-3-16
  dist/404.html, dist/.nojekyll, dist/assets/...

DECISION DE URL: se escriben archivos `.html` y se enlaza SIN extension.
GitHub Pages (y Cloudflare Pages) sirven `/v/juan-3-16` desde `juan-3-16.html`,
sin redireccion ni barra final. Ventajas frente a `juan-3-16/index.html`:
una URL identica a la del spec y de la app (go_router recibe `/v/juan-3-16`),
31.000 archivos en vez de 31.000 carpetas + 31.000 archivos, y sin el 301
de "anadir barra final". Para verlo en local use `python serve.py`.

Uso:
  python build.py RUTA/content.db [--out dist] [--site-url https://...] [--base-path /sub] [--strict]

Eficiencia: UNA sola consulta (verses JOIN books ORDER BY id) recorrida una vez;
el "siguiente" se resuelve con una fila de anticipacion, sin consultas por pagina.
"""
from __future__ import annotations

import argparse
import os
import re
import shutil
import sqlite3
import sys
import time
from pathlib import Path
from urllib.parse import quote

from jinja2 import Environment, FileSystemLoader, StrictUndefined, select_autoescape

from tokens import DARK, LIGHT

WEB = Path(__file__).resolve().parent
TEMPLATES = WEB / "templates"
ASSETS = WEB / "assets"

APPLICATION_ID = "app.sosiego.sosiego"
# Dominio PENDIENTE (spec seccion 13, decision 1): valor provisional hasta decidir.
DEFAULT_SITE_URL = "https://sosiego.app"
SLUG_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
OG_DESC_MAX = 300
BUDGET_BYTES = 50_000  # "50 KB" tomado de forma conservadora como 50.000 bytes (< 51.200)


def play_url() -> str:
    """Ficha de Google Play con referrer (spec seccion 9, 'De la pagina a la instalacion').

    El valor de `referrer` va codificado (utm_source%3Dshare%26...), como exige Play.
    """
    referrer = quote("utm_source=share&utm_medium=link&utm_campaign=verse", safe="")
    return f"https://play.google.com/store/apps/details?id={APPLICATION_ID}&referrer={referrer}"


def minify_css(css: str) -> str:
    css = re.sub(r"/\*.*?\*/", "", css, flags=re.S)
    css = re.sub(r"\s+", " ", css)
    css = re.sub(r"\s*([{};,>])\s*", r"\1", css)
    css = re.sub(r":\s+", ":", css)
    return css.replace(";}", "}").strip()


def verse_path(slug: str, chapter: int, verse: int) -> str:
    return f"/v/{slug}-{chapter}-{verse}"


def truncate(text: str, limit: int = OG_DESC_MAX) -> str:
    return text if len(text) <= limit else text[: limit - 1].rstrip() + "…"


def make_env() -> Environment:
    return Environment(
        loader=FileSystemLoader(str(TEMPLATES)),
        autoescape=select_autoescape(["html", "xml"], default=True),
        undefined=StrictUndefined,
        trim_blocks=True,
        lstrip_blocks=True,
    )


def write(path: Path, content: str) -> int:
    data = content.encode("utf-8")
    path.write_bytes(data)
    return len(data)


def prepare_out(out: Path) -> None:
    if out.exists():
        entries = list(out.iterdir())
        if entries and not (out / ".nojekyll").exists():
            raise SystemExit(f"{out} no esta vacio y no parece un dist/ generado; no lo borro.")
        shutil.rmtree(out)
    (out / "v").mkdir(parents=True)
    (out / ".nojekyll").write_text("", encoding="utf-8")


def build(db_path: Path, out: Path, site_url: str = DEFAULT_SITE_URL, base_path: str = "",
          strict: bool = False) -> dict:
    t0 = time.perf_counter()
    site_url = site_url.rstrip("/")
    base = base_path.rstrip("/")
    if base and not base.startswith("/"):
        base = "/" + base

    if not (ASSETS / "og.png").exists():
        raise SystemExit("Falta web/assets/og.png: ejecute scripts/make_og.py")
    for f in ("lora-400.woff2", "atkinson-400.woff2", "atkinson-700.woff2"):
        if not (ASSETS / "fonts" / f).exists():
            raise SystemExit(f"Falta web/assets/fonts/{f}: ejecute scripts/subset_fonts.py")

    env = make_env()
    css = minify_css(env.from_string((TEMPLATES / "style.css").read_text(encoding="utf-8"))
                     .render(base=base, L=LIGHT, D=DARK))
    common = dict(L=LIGHT, D=DARK, css=css, base=base, site_url=site_url,
                  play_url=play_url(), preload_font="lora-400.woff2", noindex=False)

    prepare_out(out)
    shutil.copytree(ASSETS, out / "assets")

    verse_tpl = env.get_template("verse.html")

    con = sqlite3.connect(Path(db_path).resolve().as_uri() + "?mode=ro", uri=True)
    try:
        have = {r[1] for r in con.execute("PRAGMA table_info(books)")}
        missing = {"id", "name_es", "slug"} - have
        if missing:
            raise SystemExit(
                f"{db_path}: la tabla books no sigue el esquema de la seccion 6 del spec "
                f"(faltan columnas {sorted(missing)}; tiene {sorted(have)})")
        cur = con.execute(
            "SELECT b.slug, b.name_es, v.chapter, v.verse, v.text "
            "FROM verses v JOIN books b ON b.id = v.book_id ORDER BY v.id"
        )
        seen: set[str] = set()
        count = 0
        first_path: str | None = None
        max_html = 0

        def emit(row, next_row):
            nonlocal count, first_path, max_html
            slug, book, chapter, verse, text = row
            if not SLUG_RE.match(slug):
                raise SystemExit(f"slug de libro invalido: {slug!r}")
            if not text or not text.strip():
                raise SystemExit(f"versiculo vacio: {book} {chapter}:{verse}")
            path = verse_path(slug, chapter, verse)
            if path in seen:
                raise SystemExit(f"URL duplicada: {path}")
            seen.add(path)
            if first_path is None:
                first_path = path
            if next_row is None:
                next_url, next_label = f"{base}/", "Volver al inicio"
            else:
                next_url = base + verse_path(next_row[0], next_row[2], next_row[3])
                next_label = "Ver el siguiente versículo"
            ref = f"{book} {chapter}:{verse}"
            html = verse_tpl.render(
                **common, title=f"{ref} · Sosiego", og_title=ref,
                description=truncate(text), url=f"{site_url}{base}{path}",
                text=text, ref=ref, next_url=next_url, next_label=next_label,
            )
            size = write(out / "v" / f"{slug}-{chapter}-{verse}.html", html)
            max_html = max(max_html, size)
            count += 1

        prev = cur.fetchone()
        if prev is None:
            raise SystemExit("content.db no tiene versiculos")
        for row in cur:
            emit(prev, row)
            prev = row
        emit(prev, None)
    finally:
        con.close()

    # Paginas fijas
    first_url = f"{base}{first_path}"
    write(out / "index.html", env.get_template("home.html").render(
        **common, title="Sosiego · Una palabra para hoy", og_title="Sosiego",
        description="Abre la app, toca cómo te sientes y recibe una palabra para hoy. Sin cuentas y sin internet.",
        url=f"{site_url}{base}/", first_url=first_url))
    write(out / "privacidad.html", env.get_template("privacy.html").render(
        **common, title="Política de privacidad · Sosiego", og_title="Política de privacidad",
        description="Qué datos guarda Sosiego, cuáles salen de tu teléfono y cómo decides sobre las métricas.",
        url=f"{site_url}{base}/privacidad"))
    write(out / "404.html", env.get_template("404.html").render(
        **{**common, "noindex": True}, title="Página no encontrada · Sosiego", og_title="Sosiego",
        description="Esta página no existe.", url=f"{site_url}{base}/"))

    pending = 0
    if strict:
        priv = (out / "privacidad.html").read_text(encoding="utf-8")
        pending = priv.count("[PENDIENTE")
        if pending:
            raise SystemExit(f"--strict: privacidad.html aun tiene {pending} campos [PENDIENTE: ...]")

    return {"pages": count, "max_html_bytes": max_html, "seconds": round(time.perf_counter() - t0, 2),
            "out": str(out)}


FONT_URL_RE = re.compile(r"url\(([^)]+?\.woff2)\)")


def page_weight(html_file: Path, out_dir: Path) -> dict:
    """Peso de una pagina en el PEOR CASO (primera visita, sin cache ni gzip).

    peso = bytes del HTML (CSS en linea incluido, sin comprimir)
         + bytes de cada .woff2 distinto referenciado en su @font-face (ya vienen comprimidos).
    No cuenta og.png (solo lo descargan los rastreadores de vista previa, la pagina
    no lo carga) ni el icono (data: URI, ya dentro del HTML). Sin JavaScript ni otros recursos.
    """
    html = html_file.read_bytes()
    fonts = {}
    for m in FONT_URL_RE.finditer(html.decode("utf-8")):
        rel = m.group(1).strip("\"'")
        fonts[rel] = None
    total_fonts = 0
    for rel in fonts:
        # quita el prefijo base-path: la ruta real en dist empieza en /assets/
        idx = rel.find("/assets/")
        total_fonts += (out_dir / rel[idx + 1:]).stat().st_size
    return {"html": len(html), "fonts": total_fonts, "total": len(html) + total_fonts}


def main() -> int:
    ap = argparse.ArgumentParser(description="Genera web/dist a partir de content.db")
    ap.add_argument("db", type=Path, help="ruta a content.db")
    ap.add_argument("--out", type=Path, default=WEB / "dist")
    ap.add_argument("--site-url", default=os.environ.get("SOSIEGO_SITE_URL", DEFAULT_SITE_URL),
                    help="URL absoluta del sitio (para og:url y og:image). Dominio pendiente.")
    ap.add_argument("--base-path", default=os.environ.get("SOSIEGO_BASE_PATH", ""),
                    help="prefijo si se sirve en un subdirectorio (p. ej. /sosiego en un project site)")
    ap.add_argument("--strict", action="store_true", help="falla si la politica aun tiene [PENDIENTE]")
    a = ap.parse_args()
    if not a.db.exists():
        print(f"No existe {a.db}", file=sys.stderr)
        return 2
    r = build(a.db, a.out, a.site_url, a.base_path, a.strict)
    # peso maximo real (HTML mas grande + fuentes compartidas)
    biggest = max((a.out / "v").glob("*.html"), key=lambda p: p.stat().st_size)
    w = page_weight(biggest, a.out)
    print(f"{r['pages']} versiculos en {r['seconds']} s -> {r['out']}")
    print(f"Pagina mas pesada: {biggest.name} = {w['total']} B (HTML {w['html']} + fuentes {w['fonts']}); "
          f"presupuesto {BUDGET_BYTES} B")
    if w["total"] > BUDGET_BYTES:
        print("FUERA DE PRESUPUESTO", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
