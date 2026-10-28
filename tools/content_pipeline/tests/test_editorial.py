"""Validadores de reflexiones: palabras, referencias biblicas ajenas, terminos prohibidos."""
import pytest

from pipeline import editorial
from pipeline.books_data import verse_id

JN316 = verse_id(43, 3, 16)
SAL23 = verse_id(19, 23, 1)


def blocks(**over):
    base = {
        "context_text": "Este pasaje se escribió para animar a una comunidad que atravesaba días difíciles y necesitaba recordar su esperanza, y por eso sus palabras siguen siendo cercanas para quien las lee hoy con sencillez.",
        "reflection_text": "Podemos detenernos un momento y reconocer lo que sentimos sin reprocharnos, sabiendo que no caminamos solos en este día tan largo y cansado.",
        "application_text": "Hoy podemos escribir una frase del texto y compartirla con alguien cercano, a nuestro propio ritmo y sin exigirnos demasiado.",
        "prayer_text": "Dios nuestro, presentamos ante Ti esta necesidad. Acompáñanos con calma y enséñanos a cuidar de quienes están a nuestro lado. Amén.",
    }
    base.update(over)
    return base


def total(b):
    return editorial.word_count(*b.values())


def with_total(target):
    """Bloques cuyo total de palabras es exactamente `target` (ajusta la reflexion)."""
    b = blocks()
    words = b["reflection_text"].split()
    delta = target - total(b)
    words = words + ["palabra"] * delta if delta >= 0 else words[:delta]
    b["reflection_text"] = " ".join(words)
    assert total(b) == target
    return b


def test_bloque_base_esta_en_rango():
    assert 90 <= total(blocks()) <= 150
    assert editorial.validate_reflection(blocks(), JN316).ok


@pytest.mark.parametrize("n,ok", [(89, False), (90, True), (150, True), (151, False), (300, False)])
def test_limites_90_y_150(n, ok):
    assert editorial.validate_reflection(with_total(n), JN316).ok is ok


def test_mensaje_de_palabras_indica_cuantas_faltan():
    v = editorial.validate_reflection(with_total(80), JN316)
    assert "faltan al menos 10" in " ".join(v.errors)
    v = editorial.validate_reflection(with_total(160), JN316)
    assert "sobran al menos 10" in " ".join(v.errors)


@pytest.mark.parametrize("text", [
    "En Romanos 8:28 encontramos ánimo.",
    "véase 1 Corintios 13:4-7",
    "Salmo 23",                      # el ancla es Juan 3:16: otro libro
    "Sal 91:1",
    "Juan 3:17",                     # mismo capitulo, otro versiculo
    "Juan 4:1",                      # mismo libro, otro capitulo
    "Jn 1:1",
    "Mt 5:3-12",
    "1 Juan 4:8",                    # distinto de Juan
    "capítulo 5",
    "versículo 20",
])
def test_referencias_ajenas_se_detectan(text):
    assert editorial.foreign_references(text, JN316), text


@pytest.mark.parametrize("text", [
    "Juan 3:16",                     # la propia ancla, con distintas escrituras
    "juan 3 : 16",
    "Jn 3:16",
    "en Juan 3 vemos una conversación",
    "versículo 16",
    "capítulo 3",
    "Dios amó al mundo de tal manera.",
    "Pasaron 3 días y 16 noches.",   # numeros sueltos no son referencias
    "Pablo escribió a una comunidad.",
])
def test_referencias_validas_para_juan_3_16(text):
    assert editorial.foreign_references(text, JN316) == [], text


def test_ancla_con_libro_numerado():
    anchor = verse_id(46, 13, 4)
    assert editorial.foreign_references("1 Corintios 13:4", anchor) == []
    assert editorial.foreign_references("1 Cor 13:4-7", anchor) == []   # rango que incluye el ancla pero la excede
    assert editorial.foreign_references("2 Corintios 13:4", anchor)


def test_salmo_23_1_ancla():
    assert editorial.foreign_references("Salmo 23:1", SAL23) == []
    assert editorial.foreign_references("Salmos 23", SAL23) == []
    assert editorial.foreign_references("Salmo 23:4", SAL23)


@pytest.mark.parametrize("text", [
    "los santos intercederán", "la Virgen María", "el bautismo", "los sacramentos", "la liturgia",
    "Dios te dará prosperidad", "una promesa de sanidad", "el juicio final", "la condenación",
    "partido político", "el islam", "una predicción", "el fin del mundo", "SANTA", "Bautismo",
])
def test_terminos_prohibidos_detectados(text):
    assert editorial.forbidden_terms_in(text), text


@pytest.mark.parametrize("text", [
    "El Espíritu Santo nos acompaña", "podemos orar con fe y esperanza", "pidamos perdón",
    "Jesús nos enseñó a amar", "descanso y paz", "santificar",  # 'santificar' no es 'santos'
])
def test_terminos_permitidos(text):
    assert editorial.forbidden_terms_in(text) == []


def test_validate_reporta_todos_los_errores():
    b = blocks(prayer_text="Santa María, ruega por nosotros. Juan 4:1")
    v = editorial.validate_reflection(b, JN316)
    assert not v.ok
    joined = " ".join(v.errors)
    assert "terminos prohibidos" in joined and "referencias" in joined


def test_bloque_vacio_es_error():
    v = editorial.validate_reflection(blocks(prayer_text="  "), JN316)
    assert not v.ok and any("vacio" in e for e in v.errors)


def test_reading_seconds():
    assert editorial.reading_seconds(150) == 60
    assert editorial.reading_seconds(100) == 40


def test_la_guia_se_inyecta_en_el_prompt():
    from pipeline import reflections
    assert "GUIA EDITORIAL" in reflections.SYSTEM
    assert "ninguna referencia biblica distinta" in reflections.SYSTEM.replace("\n", " ") or \
        "referencia biblica" in reflections.SYSTEM
