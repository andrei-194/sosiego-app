"""Tabla unica de los 66 libros: unicidad de alias y slugs, conteos canonicos y resolucion."""
import re
from collections import Counter

import pytest

from pipeline import books_data
from pipeline.books_data import BOOKS
from pipeline.normalize import normalize


def test_66_libros_ids_consecutivos():
    assert [b.id for b in BOOKS] == list(range(1, 67))


def test_testamentos_39_at_27_nt():
    c = Counter(b.testament for b in BOOKS)
    assert c == {"AT": 39, "NT": 27}
    assert BOOKS[38].osis == "Mal" and BOOKS[39].osis == "Matt"


def test_1189_capitulos_929_at_260_nt():
    assert sum(b.chapters for b in BOOKS) == 1189
    assert sum(b.chapters for b in BOOKS if b.testament == "AT") == 929
    assert sum(b.chapters for b in BOOKS if b.testament == "NT") == 260


def test_osis_y_usfm_unicos():
    assert len({b.osis for b in BOOKS}) == 66
    assert len({b.usfm for b in BOOKS}) == 66


def test_slugs_unicos_y_url_seguros():
    slugs = [b.slug for b in BOOKS]
    assert len(set(slugs)) == 66
    assert all(re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*", s) for s in slugs)
    assert books_data.BY_SLUG["juan"].id == 43


def test_slug_se_deriva_del_nombre():
    for b in BOOKS:
        assert b.slug == normalize(b.name_es).replace(" ", "-"), b.name_es


def test_aliases_unicos_entre_libros():
    seen: dict[str, str] = {}
    dup = []
    for b in BOOKS:
        for a in b.aliases:
            if a in seen and seen[a] != b.osis:
                dup.append((a, seen[a], b.osis))
            seen[a] = b.osis
    assert dup == []


def test_aliases_sin_repetir_dentro_del_libro_y_normalizados():
    for b in BOOKS:
        assert len(set(b.aliases)) == len(b.aliases), b.name_es
        assert b.aliases, b.name_es
        for a in b.aliases:
            assert a == normalize(a), (b.name_es, a)
            assert "|" not in a


def test_cada_libro_se_busca_por_su_nombre_y_su_slug():
    for b in BOOKS:
        assert normalize(b.name_es) in b.aliases
        assert books_data.resolve_alias(b.name_es) is b
        assert books_data.resolve_alias(b.slug.replace("-", " ")) is b


@pytest.mark.parametrize("text,osis", [
    ("jn", "John"), ("jua", "John"), ("Juan", "John"), ("JUAN", "John"),
    ("1co", "1Cor"), ("1 cor", "1Cor"), ("1 Corintios", "1Cor"), ("1corintios", "1Cor"),
    ("2co", "2Cor"), ("sal", "Ps"), ("salmo", "Ps"), ("Salmos", "Ps"),
    ("gn", "Gen"), ("éxodo", "Exod"), ("1 jn", "1John"), ("3 Juan", "3John"),
    ("mt", "Matt"), ("hch", "Acts"), ("ap", "Rev"), ("stg", "Jas"), ("fil", "Phil"), ("flm", "Phlm"),
    ("jud", "Jude"), ("jue", "Judg"), ("jon", "Jonah"), ("cantar de los cantares", "Song"),
    ("1 re", "1Kgs"), ("2 cr", "2Chr"), ("1 ts", "1Thess"), ("2 tim", "2Tim"), ("1 p", "1Pet"),
])
def test_resolucion_de_alias_conocidos(text, osis):
    assert books_data.resolve_alias(text).osis == osis


def test_alias_inexistente():
    assert books_data.resolve_alias("libro inventado") is None
    assert books_data.resolve_alias("") is None


def test_aliases_de_numerados_con_y_sin_espacio():
    b = books_data.BY_USFM["1CO"]
    assert {"1co", "1 co", "1cor", "1 cor", "1 corintios", "1corintios"} <= set(b.aliases)
    assert "co" not in b.aliases and "corintios" not in b.aliases    # sin numero seria ambiguo


def test_ejemplos_del_spec():
    assert books_data.BY_USFM["JHN"].aliases_str.startswith("jn|jua|juan")
    assert {"1co", "1 cor", "1 corintios"} <= set(books_data.BY_USFM["1CO"].aliases)
    assert {"sal", "salmo", "salmos"} <= set(books_data.BY_USFM["PSA"].aliases)


def test_verse_id_roundtrip_y_referencia():
    assert books_data.verse_id(43, 3, 16) == 43003016
    assert books_data.split_verse_id(46013004) == (46, 13, 4)
    assert books_data.reference(43003016) == "Juan 3:16"
