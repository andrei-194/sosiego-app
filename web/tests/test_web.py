"""Pruebas de la web de enlaces (spec secciones 8, 9 y 11)."""
import html
import re
import subprocess
import sys
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import parse_qs, urlparse

import pytest

import build as site_build
from tokens import DARK, LIGHT

WEB = Path(__file__).resolve().parent.parent
VOID = {"meta", "link", "br", "img", "hr", "input", "area", "base", "col", "embed", "source", "track", "wbr"}


# ---------- utilidades ----------
class Collector(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.stack, self.errors, self.tags = [], [], []
        self.metas, self.links, self.anchors, self.lang = [], [], [], None
        self.title, self._in_title = "", False

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        self.tags.append(tag)
        if tag == "html":
            self.lang = a.get("lang")
        if tag == "meta":
            self.metas.append(a)
        if tag == "link":
            self.links.append(a)
        if tag == "a":
            self.anchors.append(a)
        if tag == "title":
            self._in_title = True
        if tag not in VOID:
            self.stack.append(tag)

    def handle_endtag(self, tag):
        if tag in VOID:
            return
        if not self.stack or self.stack[-1] != tag:
            self.errors.append(f"cierre inesperado </{tag}> con pila {self.stack[-3:]}")
            if tag in self.stack:
                while self.stack and self.stack.pop() != tag:
                    pass
            return
        self.stack.pop()
        if tag == "title":
            self._in_title = False

    def handle_data(self, data):
        if self._in_title:
            self.title += data

    def meta(self, key, val):
        for m in self.metas:
            if m.get(key) == val:
                return m.get("content")
        return None


def parse(path: Path) -> Collector:
    p = Collector()
    p.feed(path.read_text(encoding="utf-8"))
    p.close()
    return p


def luminance(hexcolor: str) -> float:
    h = hexcolor.lstrip("#")
    chan = []
    for i in (0, 2, 4):
        c = int(h[i:i + 2], 16) / 255
        chan.append(c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4)
    return 0.2126 * chan[0] + 0.7152 * chan[1] + 0.0722 * chan[2]


def contrast(a: str, b: str) -> float:
    hi, lo = sorted((luminance(a), luminance(b)), reverse=True)
    return (hi + 0.05) / (lo + 0.05)


def all_pages(dist):
    return sorted(dist.rglob("*.html"))


def parse_text(path: Path) -> str:
    body = re.sub(r"<style>.*?</style>|<head>.*?</head>|<[^>]+>", " ", path.read_text(encoding="utf-8"), flags=re.S)
    return html.unescape(body)


# ---------- estructura ----------
def test_estructura_generada(dist):
    for rel in ("index.html", "privacidad.html", "404.html", ".nojekyll", "assets/og.png",
                "assets/fonts/lora-400.woff2", "v/juan-3-16.html", "v/salmos-23-1.html"):
        assert (dist / rel).exists(), rel


def test_una_pagina_por_versiculo(verse_pages):
    import make_fixture
    assert len(verse_pages) == len(make_fixture.SAMPLE)


# ---------- HTML valido basico ----------
@pytest.mark.parametrize("name", ["index.html", "privacidad.html", "404.html", "v/juan-3-16.html"])
def test_html_basico(dist, name):
    raw = (dist / name).read_text(encoding="utf-8")
    assert raw.lstrip().lower().startswith("<!doctype html>")
    p = parse(dist / name)
    assert p.errors == []
    assert p.stack == []
    assert p.lang == "es"
    assert p.meta("name", "viewport")
    assert any(m.get("charset") == "utf-8" for m in p.metas)
    assert p.title.strip()
    assert p.tags.count("h1") == 1, "cada pagina debe tener un unico h1"
    assert p.tags.count("main") == 1


def test_todas_las_paginas_html_bien_formadas(dist):
    for f in all_pages(dist):
        p = parse(f)
        assert p.errors == [] and p.stack == [], f.name


# ---------- sin JavaScript, cookies ni rastreo ----------
def test_sin_javascript_ni_recursos_externos(dist):
    for f in all_pages(dist):
        raw = f.read_text(encoding="utf-8").lower()
        assert "<script" not in raw, f.name
        assert not re.search(r"\son[a-z]+\s*=", raw), f"manejador de evento en {f.name}"
        assert "javascript:" not in raw
        assert "<iframe" not in raw and "<form" not in raw
        assert "document.cookie" not in raw
        p = parse(f)
        assert not [x for x in p.links if x.get("rel") == "stylesheet"], "CSS debe ir en linea"
        hosts = {urlparse(a["href"]).netloc for a in p.anchors if a.get("href", "").startswith("http")}
        assert hosts <= {"play.google.com"}, (f.name, hosts)
        css_urls = re.findall(r"url\(([^)]+)\)", raw)
        assert all(not u.startswith(("http", "//")) for u in css_urls), f.name


# ---------- Open Graph ----------
def test_open_graph_en_cada_pagina_de_versiculo(verse_pages):
    for f in verse_pages:
        p = parse(f)
        assert re.fullmatch(r".+ \d+:\d+", p.meta("property", "og:title")), f.name
        assert p.meta("property", "og:description")
        assert p.meta("property", "og:url").startswith("https://example.test/v/")
        assert p.meta("property", "og:url").endswith(f.stem)
        assert p.meta("property", "og:image") == "https://example.test/assets/og.png"
        assert p.meta("name", "twitter:card") == "summary"
        assert any(x.get("rel") == "canonical" and x["href"] == p.meta("property", "og:url") for x in p.links)


def test_og_juan_3_16(dist):
    p = parse(dist / "v/juan-3-16.html")
    assert p.meta("property", "og:title") == "Juan 3:16"
    assert p.meta("property", "og:description").startswith("Porque de tal manera amó Dios")
    assert p.meta("property", "og:image:width") == "1200"


def test_og_description_se_trunca(custom_dist):
    d = custom_dist({(43, 3, 17): "palabra " * 100})
    desc = parse(d / "v/juan-3-17.html").meta("property", "og:description")
    assert len(desc) <= site_build.OG_DESC_MAX and desc.endswith("…")


def test_escapado_de_html_en_texto(custom_dist):
    d = custom_dist({(43, 3, 17): 'a <script>alert(1)</script> & "b"'})
    raw = (d / "v/juan-3-17.html").read_text(encoding="utf-8")
    assert "<script" not in raw
    assert "&lt;script&gt;" in raw
    assert parse(d / "v/juan-3-17.html").meta("property", "og:description") == 'a <script>alert(1)</script> & "b"'


def test_og_png_dimensiones_y_peso():
    from PIL import Image
    png = WEB / "assets" / "og.png"
    assert png.stat().st_size < 300 * 1024
    with Image.open(png) as im:
        assert im.size == (1200, 630)
        assert im.format == "PNG"


# ---------- siguiente versiculo ----------
def href_next(dist, name):
    p = parse(dist / "v" / name)
    nxt = [a for a in p.anchors if a.get("rel") == "next"]
    assert len(nxt) == 1
    return nxt[0]["href"], p


def test_siguiente_dentro_del_libro(dist):
    assert href_next(dist, "salmos-23-1.html")[0] == "/v/salmos-23-2"


def test_siguiente_en_frontera_de_libro(dist):
    # ultimo de Genesis -> primero de Exodo
    assert href_next(dist, "genesis-50-26.html")[0] == "/v/exodo-1-1"
    # ultimo de Exodo (en la muestra) -> primer versiculo del libro siguiente con datos
    assert href_next(dist, "exodo-1-2.html")[0] == "/v/salmos-23-1"


def test_ultimo_de_la_biblia_apunta_a_portada(dist):
    assert href_next(dist, "apocalipsis-22-21.html")[0] == "/"


def test_texto_del_enlace_siguiente(dist):
    raw = (dist / "v/salmos-23-1.html").read_text(encoding="utf-8")
    assert "Ver el siguiente versículo" in raw
    assert "Descargar en Google Play" in raw


def test_enlaces_internos_resuelven(dist):
    """Todo enlace interno apunta a un archivo que existe (sin extension -> .html)."""
    for f in all_pages(dist):
        for a in parse(f).anchors:
            h = a.get("href", "")
            if not h.startswith("/"):
                continue
            target = "index.html" if h == "/" else h.lstrip("/") + ".html"
            assert (dist / target).exists(), (f.name, h)


def test_base_path(custom_dist):
    d = custom_dist({}, base_path="/sosiego")
    href, _ = href_next(d, "genesis-50-26.html")
    assert href == "/sosiego/v/exodo-1-1"
    raw = (d / "v/juan-3-16.html").read_text(encoding="utf-8")
    assert "url(/sosiego/assets/fonts/lora-400.woff2)" in raw
    assert "https://example.test/sosiego/assets/og.png" in raw


# ---------- Google Play y la dedicatoria ----------
def test_enlace_play_con_referrer(verse_pages):
    for f in verse_pages:
        p = parse(f)
        play = [a["href"] for a in p.anchors if "play.google.com" in a.get("href", "")]
        assert len(play) == 1
        u = urlparse(html.unescape(play[0]))
        assert u.scheme == "https" and u.netloc == "play.google.com" and u.path == "/store/apps/details"
        q = parse_qs(u.query)
        assert q["id"] == ["app.sosiego.sosiego"]
        assert parse_qs(q["referrer"][0]) == {
            "utm_source": ["share"], "utm_medium": ["link"], "utm_campaign": ["verse"]}
        # el valor de referrer va codificado, como exige Google Play
        assert "referrer=utm_source%3Dshare%26utm_medium%3Dlink%26utm_campaign%3Dverse" in play[0]


def test_la_dedicatoria_nunca_va_en_el_enlace(dist):
    """El enlace es el mismo para todos (spec seccion 9): ninguna URL interna ni canonica
    lleva parametros ni consulta, asi que no hay donde viajar una dedicatoria."""
    for f in all_pages(dist):
        p = parse(f)
        for a in p.anchors:
            h = a.get("href", "")
            if h.startswith("/"):
                assert "?" not in h, (f.name, h)
                assert "#" not in h.replace("#contenido", ""), (f.name, h)
        for x in p.links:
            if x.get("rel") == "canonical":
                assert "?" not in x["href"] and "#" not in x["href"]
        assert "para=" not in f.read_text(encoding="utf-8").lower()
    # los nombres de archivo (las URL) solo tienen slug-capitulo-versiculo
    for f in (dist / "v").glob("*.html"):
        assert re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*-\d+-\d+", f.stem), f.name
    # y la pagina no muestra ningun "Para {nombre}"
    assert not re.search(r"\bPara \w+", parse_text(dist / "v/juan-3-16.html"))


# ---------- peso (< 50 KB por pagina, fuente Lora incluida) ----------
def test_presupuesto_de_peso_por_pagina(dist):
    for f in all_pages(dist):
        w = site_build.page_weight(f, dist)
        assert w["total"] < site_build.BUDGET_BYTES, (f.name, w)


def test_peso_del_peor_caso_realista(custom_dist):
    """Versiculo de 1.500 caracteres (el mas largo de la Biblia ronda los 600)."""
    d = custom_dist({(43, 3, 17): ("Y dijo Dios que sea la luz; " * 55)})
    w = site_build.page_weight(d / "v/juan-3-17.html", d)
    assert w["total"] < site_build.BUDGET_BYTES, w


def test_el_presupuesto_detecta_excesos(custom_dist):
    """La prueba de peso falla de verdad: un versiculo de 20 KB debe pasar el presupuesto."""
    d = custom_dist({(43, 3, 17): "x" * 20_000})
    w = site_build.page_weight(d / "v/juan-3-17.html", d)
    assert w["total"] > site_build.BUDGET_BYTES


def test_peso_incluye_la_fuente_lora(dist):
    w = site_build.page_weight(dist / "v/juan-3-16.html", dist)
    lora = (dist / "assets/fonts/lora-400.woff2").stat().st_size
    assert w["fonts"] >= lora and w["total"] == w["html"] + w["fonts"]


def test_fuentes_woff2_validas(dist):
    for f in (dist / "assets/fonts").glob("*.woff2"):
        assert f.read_bytes()[:4] == b"wOF2"


def test_lora_cubre_el_espanol():
    from fontTools.ttLib import TTFont
    cmap = TTFont(WEB / "assets/fonts/lora-400.woff2").getBestCmap()
    for ch in "áéíóúüñÁÉÍÓÚÜÑ¿¡«»“”‘’—–…":
        assert ord(ch) in cmap, ch


# ---------- contraste (WCAG) ----------
def test_formula_de_contraste():
    assert contrast("#000000", "#FFFFFF") == pytest.approx(21.0, abs=0.01)
    assert contrast("#1F1B16", "#FBF7F0") == pytest.approx(16.0, abs=0.1)  # spec rev. 2


@pytest.mark.parametrize("name,tok", [("claro", LIGHT), ("oscuro", DARK)])
def test_contraste_de_los_tokens(name, tok):
    # el degradado va de bg a bg2: se mide en ambos extremos (peor caso)
    for bg in (tok["bg"], tok["bg2"]):
        assert contrast(tok["text"], bg) >= 7.0, (name, "versiculo 7:1")
        assert contrast(tok["muted"], bg) >= 4.5, (name, "secundario 4.5:1")
        assert contrast(tok["accent"], bg) >= 4.5, (name, "referencia y enlaces 4.5:1")
    # texto del boton principal sobre el acento
    assert contrast(tok["on_accent"], tok["accent"]) >= 4.5, name


def test_tokens_coinciden_con_el_spec():
    assert (LIGHT["bg"], LIGHT["text"], LIGHT["accent"]) == ("#FBF7F0", "#1F1B16", "#8A4B08")
    assert (DARK["bg"], DARK["text"], DARK["accent"]) == ("#14110D", "#F3EBDD", "#E2B77E")


def test_css_usa_tokens_y_modo_oscuro(dist):
    raw = (dist / "v/juan-3-16.html").read_text(encoding="utf-8")
    assert "prefers-color-scheme:dark" in raw
    for t in (LIGHT["bg"], LIGHT["text"], LIGHT["accent"], DARK["bg"], DARK["text"], DARK["accent"]):
        assert t in raw
    assert "font-display:swap" in raw
    # ningun texto por debajo de 14 px (0.875rem) y botones de >= 56 px (3.5rem)
    sizes = [float(x) for x in re.findall(r"font-size:([\d.]+)rem", raw)]
    assert min(sizes) >= 0.875
    assert "min-height:3.5rem" in raw


# ---------- politica de privacidad ----------
def test_privacidad_es_borrador_con_campos_pendientes(dist):
    src = (WEB / "templates/privacy.html").read_text(encoding="utf-8")
    head = src.split("#}")[0]
    assert "BORRADOR" in head and "NO ES ASESORIA LEGAL" in head
    out = (dist / "privacidad.html").read_text(encoding="utf-8")
    assert "[PENDIENTE: nombre y datos del responsable del tratamiento]" in out
    assert "[PENDIENTE: correo de contacto]" in out
    for needle in ("Ley 1581 de 2012", "PostHog", "respaldo", "cuentas"):
        assert needle.lower() in out.lower(), needle


def test_strict_falla_con_pendientes(tmp_path):
    import make_fixture
    db = make_fixture.make(tmp_path / "c.db")
    with pytest.raises(SystemExit, match="PENDIENTE"):
        site_build.build(db, tmp_path / "d", strict=True)


# ---------- CLI ----------
def test_cli_build(tmp_path):
    import make_fixture
    db = make_fixture.make(tmp_path / "c.db")
    r = subprocess.run([sys.executable, str(WEB / "build.py"), str(db), "--out", str(tmp_path / "o")],
                       capture_output=True, text=True, cwd=tmp_path)
    assert r.returncode == 0, r.stderr
    assert "Pagina mas pesada" in r.stdout


def test_css_en_linea_no_esta_escapado(dist):
    """Regresion: el autoescape de Jinja convertia las comillas del CSS en &#34; y rompia las fuentes."""
    for f in all_pages(dist):
        css = re.search(r"<style>(.*?)</style>", f.read_text(encoding="utf-8"), re.S).group(1)
        assert "&#" not in css and "&quot;" not in css and "&amp;" not in css, f.name
        assert '"Atkinson Hyperlegible"' in css
