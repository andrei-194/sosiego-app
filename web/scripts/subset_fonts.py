"""Genera los subsets woff2 (espanol completo) de Lora y Atkinson Hyperlegible.

Uso (desde web/):  .venv/Scripts/python scripts/subset_fonts.py
Lee assets/fonts/ de la app (OFL) y escribe web/assets/fonts/*.woff2.
Los .woff2 resultantes se versionan: el build no necesita las TTF.
"""
from __future__ import annotations

import sys
from pathlib import Path

from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

WEB = Path(__file__).resolve().parent.parent
SRC = WEB.parent / "assets" / "fonts"
OUT = WEB / "assets" / "fonts"

# Basic Latin + Latin-1 (n con tilde, vocales acentuadas, dieresis, signos
# invertidos, comillas angulares) + puntuacion tipografica usada en la RV1909.
UNICODES = (
    list(range(0x20, 0x7F))
    + list(range(0xA0, 0x100))
    + [0x2013, 0x2014, 0x2018, 0x2019, 0x201C, 0x201D, 0x2026, 0x2022, 0x20AC]
)

JOBS = [
    # (origen, destino, peso fijo para fuentes variables o None)
    ("Lora-Variable.ttf", "lora-400.woff2", 400),
    ("AtkinsonHyperlegible-Regular.ttf", "atkinson-400.woff2", None),
    ("AtkinsonHyperlegible-Bold.ttf", "atkinson-700.woff2", None),
]


def build(src_name: str, dst_name: str, wght: int | None) -> int:
    font = TTFont(SRC / src_name)
    if wght is not None and "fvar" in font:
        font = instancer.instantiateVariableFont(font, {"wght": wght})
    opts = subset.Options()
    opts.flavor = "woff2"
    opts.layout_features = ["kern", "liga"]
    opts.hinting = False
    opts.desubroutinize = True
    opts.name_IDs = [0, 1, 2, 4, 6, 13, 14]  # conserva copyright y licencia OFL
    opts.notdef_outline = True
    sub = subset.Subsetter(opts)
    sub.populate(unicodes=UNICODES)
    sub.subset(font)
    OUT.mkdir(parents=True, exist_ok=True)
    dst = OUT / dst_name
    font.flavor = "woff2"
    font.save(dst)
    return dst.stat().st_size


def main() -> int:
    total = 0
    for src, dst, w in JOBS:
        n = build(src, dst, w)
        total += n
        print(f"{dst:20s} {n:7d} bytes")
    print(f"{'total':20s} {total:7d} bytes")
    return 0


if __name__ == "__main__":
    sys.exit(main())
