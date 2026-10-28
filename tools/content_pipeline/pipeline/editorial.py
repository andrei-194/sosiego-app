"""Guia editorial (spec §5) y validadores automaticos de reflexiones.

Un solo lugar para: terminos prohibidos, el texto de la guia que se inyecta en el prompt, y los
validadores (90-150 palabras, ninguna referencia biblica distinta de la ancla, sin terminos
prohibidos, cuatro bloques). Los usa el generador, la revision, la exportacion y las pruebas.
"""
from __future__ import annotations

import re
from dataclasses import dataclass, field

from . import books_data
from .normalize import normalize, strip_accents_lower

MIN_WORDS = 90
MAX_WORDS = 150
BLOCKS = ("context_text", "reflection_text", "application_text", "prayer_text")

GUIDE_TEXT = """\
GUIA EDITORIAL (obligatoria):
- Tono cristiano general. Se puede hablar de Dios, Jesus, el Espiritu Santo, la oracion, la fe, la esperanza y el perdon.
- Se evita: santos y mediacion de Maria, bautismo, sacramentos y liturgia, promesas de prosperidad o sanidad, juicio y condenacion, politica, otras religiones y predicciones.
- Sin promesas concretas. Nunca "Dios te dara el trabajo"; si "podemos presentarle esta necesidad".
- Registro: primera persona del plural o forma impersonal ("podemos", "pidamos"). Nunca tu ni usted.
- Usa SOLO el texto del versiculo dado. No cites ningun otro versiculo ni escribas ninguna referencia biblica (libro, capitulo, versiculo) distinta de la del versiculo ancla.
- Contexto: menciona autor, destinatarios o fecha solo si son consenso; si no, omitelos.
- Temas delicados (duelo, depresion, miedo a morir): sin minimizar el dolor, y marca sensitive=true. Las reflexiones no sustituyen atencion medica ni psicologica.
- Explica el pasaje en lenguaje actual (el texto es de 1909).
- Entre 90 y 150 palabras en total sumando los cuatro bloques.
"""

# Terminos prohibidos (normalizados: minusculas, sin tildes). Se busca como palabra completa
# o frase completa. "Espiritu Santo" esta permitido, por eso no se prohibe "santo" suelto,
# pero si "santos", "santa(s)" y "san <nombre>" via la frase "san".
_FORBIDDEN_RAW = [
    # santos y mediacion de Maria
    "santos", "santa", "santas", "san", "virgen", "maria", "intercesion de", "mediadora",
    "rosario", "purgatorio", "papa",
    # bautismo, sacramentos, liturgia
    "bautismo", "bautizo", "bautizar", "bautizado", "bautizada", "sacramento", "sacramentos",
    "eucaristia", "comunion", "misa", "liturgia", "liturgico", "confesion", "penitencia",
    # prosperidad y sanidad
    "prosperidad", "prospero", "prosperos", "prosperaras", "diezmo", "diezmos", "riquezas aseguradas",
    "sanidad", "sanacion", "sanara", "sanare", "milagro de sanidad",
    # juicio y condenacion
    "juicio", "juicios", "condenacion", "condenar", "condenado", "condenados", "infierno",
    "perdicion", "castigo", "castigara",
    # politica
    "politica", "politico", "politicos", "politicas", "elecciones", "gobierno", "presidente",
    # otras religiones
    "budismo", "budista", "islam", "islamico", "musulman", "musulmanes", "hinduismo", "hindu",
    "mormon", "mormones", "testigos de jehova", "new age",
    # predicciones
    "prediccion", "predicciones", "predecir", "profecia", "profecias", "fin del mundo",
    "fin de los tiempos", "segunda venida",
]
FORBIDDEN_TERMS = sorted({normalize(t) for t in _FORBIDDEN_RAW})
_FORBIDDEN_RE = re.compile(
    r"(?<![a-z0-9])(" + "|".join(re.escape(t) for t in sorted(FORBIDDEN_TERMS, key=len, reverse=True)) + r")(?![a-z0-9])"
)


def forbidden_terms_in(text: str) -> list[str]:
    return sorted(set(_FORBIDDEN_RE.findall(normalize(text))))


def word_count(*blocks: str) -> int:
    return sum(len(b.split()) for b in blocks)


# ---------------------------------------------------------------- referencias biblicas
# Alias -> libro, del mas largo al mas corto. Se aplican sobre texto sin tildes y en minusculas
# pero CON signos, para ver "3:16" y "13:4-7".
def _build_ref_regex():
    pairs = sorted(
        ((a, b.id) for b in books_data.BOOKS for a in b.aliases),
        key=lambda p: len(p[0]),
        reverse=True,
    )
    alt = "|".join(r"\s+".join(re.escape(w) for w in a.split(" ")) for a, _ in pairs)
    # (?<![a-z0-9]) evita dentro de palabras ("dios 3" no es libro; "mar 3" si lo seria: es una referencia valida
    # a Marcos y se marca, que es lo conservador).
    return re.compile(
        r"(?<![a-z0-9])(?P<book>" + alt + r")\.?\s*(?P<chap>\d{1,3})"
        r"(?:\s*[:.,]\s*(?P<v1>\d{1,3})(?:\s*[-–—]\s*(?P<v2>\d{1,3}))?)?(?![a-z])"
    ), dict(pairs)


_REF_RE, _ALIAS_TO_BOOK = _build_ref_regex()
_SPOKEN_RE = re.compile(r"(?<![a-z0-9])(capitulo|versiculo|versiculos|cap|vers|vv?)\.?\s*(\d{1,3})(?![a-z0-9])")


@dataclass
class Ref:
    book_id: int
    chapter: int
    verse: int | None
    raw: str


def find_references(text: str) -> list[Ref]:
    t = strip_accents_lower(text)
    t = re.sub(r"\s+", " ", t)
    refs = []
    for m in _REF_RE.finditer(t):
        alias = re.sub(r"\s+", " ", m.group("book"))
        refs.append(Ref(
            _ALIAS_TO_BOOK[alias], int(m.group("chap")),
            int(m.group("v1")) if m.group("v1") else None, m.group(0)))
    return refs


def foreign_references(text: str, anchor_verse_id: int) -> list[str]:
    """Referencias del texto distintas de la del versiculo ancla (lista vacia = valido)."""
    b, c, v = books_data.split_verse_id(anchor_verse_id)
    bad = []
    for r in find_references(text):
        same = r.book_id == b and r.chapter == c and (r.verse is None or r.verse == v)
        if not same:
            bad.append(r.raw)
    t = strip_accents_lower(text)
    for m in _SPOKEN_RE.finditer(t):
        n = int(m.group(2))
        kind = m.group(1)
        is_chapter = kind.startswith("cap")
        ok = (n == c) if is_chapter else (n == v)
        if not ok:
            bad.append(m.group(0))
    return bad


# ---------------------------------------------------------------- validacion completa
@dataclass
class Validation:
    ok: bool
    errors: list[str] = field(default_factory=list)
    word_count: int = 0
    warnings: list[str] = field(default_factory=list)


def validate_reflection(blocks: dict[str, str], anchor_verse_id: int) -> Validation:
    errs: list[str] = []
    for k in BLOCKS:
        if not blocks.get(k, "").strip():
            errs.append(f"bloque vacio: {k}")
    full = " ".join(blocks.get(k, "") for k in BLOCKS)
    n = word_count(*(blocks.get(k, "") for k in BLOCKS))
    if not (MIN_WORDS <= n <= MAX_WORDS):
        hint = (f"faltan al menos {MIN_WORDS - n} palabras: amplia la reflexion y la aplicacion" if n < MIN_WORDS
                else f"sobran al menos {n - MAX_WORDS} palabras: resume")
        errs.append(f"palabras fuera de rango: {n} (esperado {MIN_WORDS}-{MAX_WORDS}); {hint}")
    fr = foreign_references(full, anchor_verse_id)
    if fr:
        errs.append(f"referencias biblicas distintas de la ancla: {fr}")
    ft = forbidden_terms_in(full)
    if ft:
        errs.append(f"terminos prohibidos: {ft}")
    warns: list[str] = []
    if re.search(r"\b(tu|tus|usted|ustedes)\b", normalize(full)):
        # solo advertencia: el versiculo citado puede traer "tu" legitimamente
        warns.append("registro: aparece tu/usted (deberia ser 'podemos', 'pidamos' o impersonal)")
    return Validation(not errs, errs, n, warns)


def reading_seconds(words: int) -> int:
    return round(words / 150 * 60)
