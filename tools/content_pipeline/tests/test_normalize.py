"""Normalizacion: usa la lista compartida tools/shared/normalize_cases.json.

La prueba Dart equivalente (test/ del proyecto Flutter) debe leer el MISMO archivo y comparar
normalize(input) == expected. PENDIENTE: la anadira el agente de la app (spec §10, prueba 9).
"""
import json
from pathlib import Path

import pytest

from pipeline.normalize import normalize

CASES_PATH = Path(__file__).resolve().parents[2] / "shared" / "normalize_cases.json"
CASES = json.loads(CASES_PATH.read_text("utf-8"))["cases"]


def test_lista_compartida_bien_formada():
    ids = [c["id"] for c in CASES]
    assert len(ids) == len(set(ids)) and len(CASES) >= 20
    assert all(set(c) == {"id", "input", "expected"} for c in CASES)
    # los resultados esperados ya estan normalizados: la funcion es idempotente
    assert all(normalize(c["expected"]) == c["expected"] for c in CASES)


@pytest.mark.parametrize("case", CASES, ids=[c["id"] for c in CASES])
def test_caso_compartido(case):
    assert normalize(case["input"]) == case["expected"]


def test_cubre_las_categorias_pedidas():
    joined = " ".join(c["id"] for c in CASES)
    for k in ("tilde", "enie", "mayuscula", "signos", "espacios"):
        assert k in joined, k


def test_idempotente():
    s = "¡Jehová es mi PASTOR; nada me faltará!"
    assert normalize(normalize(s)) == normalize(s)


def test_enie_coincide_con_fts5(schema_con):
    """FTS5 con remove_diacritics 2 tambien pliega la ñ: 'ano' encuentra 'año'."""
    from pipeline import books_data
    books_data.insert_books(schema_con)
    schema_con.execute("INSERT INTO verses VALUES (1001001, 1, 1, 1, 'año', ?, 0, 0)", (normalize("año"),))
    schema_con.execute("INSERT INTO verses_fts(verses_fts) VALUES('rebuild')")
    assert schema_con.execute("SELECT COUNT(*) FROM verses_fts WHERE verses_fts MATCH 'ano'").fetchone()[0] == 1
