"""Tokens de color de la web (spec seccion 8, revision 2). Unica fuente de verdad:
build.py los inyecta en el CSS y los tests calculan el contraste WCAG sobre ellos.
"""

LIGHT = {
    "bg": "#FBF7F0",       # fondo (inicio del degradado)
    "bg2": "#F7EEDF",      # fin del degradado (punto mas desfavorable)
    "text": "#1F1B16",
    "muted": "#5C5247",    # texto secundario
    "accent": "#8A4B08",
    "on_accent": "#FBF7F0",  # texto sobre el boton de acento
    "line": "#E6D9C3",     # solo decorativo (bordes)
}
DARK = {
    "bg": "#14110D",
    "bg2": "#1F1810",
    "text": "#F3EBDD",
    "muted": "#BFB3A0",
    "accent": "#E2B77E",
    "on_accent": "#14110D",
    "line": "#3A3228",
}
