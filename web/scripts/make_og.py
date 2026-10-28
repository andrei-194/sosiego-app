"""Genera web/assets/og.png (1200x630, < 300 KB): degradado calido, marca y promesa.

Uso (desde web/):  .venv/Scripts/python scripts/make_og.py
Usa Lora (OFL) de ../assets/fonts y los tokens de color de tokens.py.
"""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

WEB = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(WEB))
from tokens import LIGHT  # noqa: E402

FONTS = WEB.parent / "assets" / "fonts"
W, H = 1200, 630
MAX_BYTES = 300 * 1024


def hexrgb(h: str) -> tuple[int, int, int]:
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))  # type: ignore[return-value]


def lerp(a, b, t):
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))


def font(name: str, size: int, wght: int | None = None) -> ImageFont.FreeTypeFont:
    f = ImageFont.truetype(str(FONTS / name), size)
    if wght is not None:
        f.set_variation_by_axes([wght])
    return f


def main() -> int:
    top, bottom = hexrgb("#FBF7F0"), hexrgb("#EFD9B4")  # amanecer calido
    img = Image.new("RGB", (W, H))
    px = img.load()
    for y in range(H):
        for x in range(W):
            t = (x * 0.35 + y) / (W * 0.35 + H)  # diagonal suave
            px[x, y] = lerp(top, bottom, t)
    d = ImageDraw.Draw(img)

    ink, accent = hexrgb(LIGHT["text"]), hexrgb(LIGHT["accent"])
    # sol suave detras de la marca (circulos concentricos muy discretos)
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    for r, a in ((330, 26), (250, 30), (170, 36)):
        gd.ellipse((W - 250 - r, 120 - r, W - 250 + r, 120 + r), fill=(226, 183, 126, a))
    img.paste(glow, (0, 0), glow)
    d = ImageDraw.Draw(img)

    brand = font("Lora-Variable.ttf", 190, 600)
    tag = font("Lora-Variable.ttf", 54, 400)
    small = font("AtkinsonHyperlegible-Bold.ttf", 36)

    d.text((90, 150), "Sosiego", font=brand, fill=accent)
    d.rounded_rectangle((96, 400, 216, 408), radius=4, fill=accent)
    d.text((90, 440), "Toca cómo te sientes.", font=tag, fill=ink)
    d.text((90, 510), "Recibe una palabra para hoy.", font=tag, fill=ink)
    d.text((96, 40), "Versículos y calma, sin cuentas", font=small, fill=hexrgb(LIGHT["muted"]))

    out = WEB / "assets" / "og.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out, optimize=True)
    size = out.stat().st_size
    if size > MAX_BYTES:
        # Cuantiza a paleta de 256 colores con tramado: mantiene el degradado y baja el peso.
        img.quantize(colors=256, dither=Image.Dither.FLOYDSTEINBERG).save(out, optimize=True)
        size = out.stat().st_size
    print(f"{out} {W}x{H} {size} bytes ({size / 1024:.0f} KB)")
    return 0 if size <= MAX_BYTES else 1


if __name__ == "__main__":
    sys.exit(main())
