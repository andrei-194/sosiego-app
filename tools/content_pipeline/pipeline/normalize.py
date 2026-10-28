"""Normalizacion de texto para `verses.text_norm` y la busqueda (spec §6).

Regla (debe dar el MISMO resultado en Dart; casos en tools/shared/normalize_cases.json):
  1. descomponer en NFD y pasar a minusculas;
  2. quitar las marcas combinantes (categoria Mn): tildes, dieresis y la tilde de la n
     (la ene pasa a 'n', igual que hace FTS5 con remove_diacritics 2);
  3. cada caracter que no sea letra (L*) ni numero (N*) pasa a espacio;
  4. colapsar espacios y recortar.
"""
from __future__ import annotations

import unicodedata


def normalize(text: str) -> str:
    decomposed = unicodedata.normalize("NFD", text.lower())
    out: list[str] = []
    for ch in decomposed:
        cat = unicodedata.category(ch)
        if cat == "Mn":
            continue
        out.append(ch if cat[0] in ("L", "N") else " ")
    return " ".join("".join(out).split())


def strip_accents_lower(text: str) -> str:
    """Minusculas y sin tildes, CONSERVANDO signos (para detectar referencias tipo 'Juan 3:16')."""
    decomposed = unicodedata.normalize("NFD", text.lower())
    return "".join(c for c in decomposed if unicodedata.category(c) != "Mn")
