"""Los 66 libros: UNICA fuente de verdad (osis, nombre, slug, testamento, capitulos, aliases).

Orden canonico protestante (el de la RV1909). `id` = posicion 1..66; los ids de versiculo son
libro*1_000_000 + capitulo*1000 + versiculo.

Los alias van normalizados (minusculas, sin tildes ni signos, espacios simples) con la misma
funcion de `pipeline.normalize`. Para los libros numerados se generan las variantes con y sin
espacio ("1co", "1 cor", "1 corintios", "1corintios"). Ningun alias puede repetirse entre
libros: lo garantiza tests/test_books.py.
"""
from __future__ import annotations

from dataclasses import dataclass

from .normalize import normalize


@dataclass(frozen=True)
class Book:
    id: int
    osis: str
    usfm: str          # codigo USFM de 3 letras (el de eBible.org en `\id`)
    name_es: str
    slug: str
    testament: str     # 'AT' | 'NT'
    chapters: int
    aliases: tuple[str, ...]

    @property
    def aliases_str(self) -> str:
        return "|".join(self.aliases)


# (osis, usfm, nombre, slug, capitulos, numero-de-serie o 0, alias base)
# Para libros numerados el nombre ya lleva el numero ("1 Samuel") y los alias base no.
_RAW = [
    ("Gen", "GEN", "Génesis", "genesis", 50, 0, "gn gen genesis"),
    ("Exod", "EXO", "Éxodo", "exodo", 40, 0, "ex exo exod exodo"),
    ("Lev", "LEV", "Levítico", "levitico", 27, 0, "lv lev levitico"),
    ("Num", "NUM", "Números", "numeros", 36, 0, "nm num numeros"),
    ("Deut", "DEU", "Deuteronomio", "deuteronomio", 34, 0, "dt deu deut deuteronomio"),
    ("Josh", "JOS", "Josué", "josue", 24, 0, "jos josue"),
    ("Judg", "JDG", "Jueces", "jueces", 21, 0, "jc jue juec jueces"),
    ("Ruth", "RUT", "Rut", "rut", 4, 0, "rt rut"),
    ("1Sam", "1SA", "1 Samuel", "1-samuel", 31, 1, "sm sam samuel"),
    ("2Sam", "2SA", "2 Samuel", "2-samuel", 24, 2, "sm sam samuel"),
    ("1Kgs", "1KI", "1 Reyes", "1-reyes", 22, 1, "re rey reyes"),
    ("2Kgs", "2KI", "2 Reyes", "2-reyes", 25, 2, "re rey reyes"),
    ("1Chr", "1CH", "1 Crónicas", "1-cronicas", 29, 1, "cr cro cron cronicas"),
    ("2Chr", "2CH", "2 Crónicas", "2-cronicas", 36, 2, "cr cro cron cronicas"),
    ("Ezra", "EZR", "Esdras", "esdras", 10, 0, "esd esdras"),
    ("Neh", "NEH", "Nehemías", "nehemias", 13, 0, "neh nehemias"),
    ("Esth", "EST", "Ester", "ester", 10, 0, "est ester"),
    ("Job", "JOB", "Job", "job", 42, 0, "jb job"),
    ("Ps", "PSA", "Salmos", "salmos", 150, 0, "sal salmo salmos slm"),
    ("Prov", "PRO", "Proverbios", "proverbios", 31, 0, "pr prov proverbios"),
    ("Eccl", "ECC", "Eclesiastés", "eclesiastes", 12, 0, "ec ecl eclesiastes"),
    ("Song", "SNG", "Cantares", "cantares", 8, 0, "cnt cant cantares cantar de los cantares"),
    ("Isa", "ISA", "Isaías", "isaias", 66, 0, "is isa isaias"),
    ("Jer", "JER", "Jeremías", "jeremias", 52, 0, "jer jeremias"),
    ("Lam", "LAM", "Lamentaciones", "lamentaciones", 5, 0, "lm lam lamentaciones"),
    ("Ezek", "EZK", "Ezequiel", "ezequiel", 48, 0, "ez eze ezeq ezequiel"),
    ("Dan", "DAN", "Daniel", "daniel", 12, 0, "dn dan daniel"),
    ("Hos", "HOS", "Oseas", "oseas", 14, 0, "os ose oseas"),
    ("Joel", "JOL", "Joel", "joel", 3, 0, "jl joel"),
    ("Amos", "AMO", "Amós", "amos", 9, 0, "am amos"),
    ("Obad", "OBA", "Abdías", "abdias", 1, 0, "abd abdias"),
    ("Jonah", "JON", "Jonás", "jonas", 4, 0, "jon jonas jnh"),
    ("Mic", "MIC", "Miqueas", "miqueas", 7, 0, "miq miqueas"),
    ("Nah", "NAM", "Nahúm", "nahum", 3, 0, "na nah nahum"),
    ("Hab", "HAB", "Habacuc", "habacuc", 3, 0, "hab habacuc"),
    ("Zeph", "ZEP", "Sofonías", "sofonias", 3, 0, "sof sofonias"),
    ("Hag", "HAG", "Hageo", "hageo", 2, 0, "hag hageo"),
    ("Zech", "ZEC", "Zacarías", "zacarias", 14, 0, "zac zacarias"),
    ("Mal", "MAL", "Malaquías", "malaquias", 4, 0, "mal malaquias"),
    ("Matt", "MAT", "Mateo", "mateo", 28, 0, "mt mat mateo"),
    ("Mark", "MRK", "Marcos", "marcos", 16, 0, "mr mc mar marcos"),
    ("Luke", "LUK", "Lucas", "lucas", 24, 0, "lc luc lucas"),
    ("John", "JHN", "Juan", "juan", 21, 0, "jn jua juan"),
    ("Acts", "ACT", "Hechos", "hechos", 28, 0, "hch hec hech hechos"),
    ("Rom", "ROM", "Romanos", "romanos", 16, 0, "ro rom romanos"),
    ("1Cor", "1CO", "1 Corintios", "1-corintios", 16, 1, "co cor corintios"),
    ("2Cor", "2CO", "2 Corintios", "2-corintios", 13, 2, "co cor corintios"),
    ("Gal", "GAL", "Gálatas", "galatas", 6, 0, "ga gal galatas"),
    ("Eph", "EPH", "Efesios", "efesios", 6, 0, "ef efe efesios"),
    ("Phil", "PHP", "Filipenses", "filipenses", 4, 0, "fil flp filip filipenses"),
    ("Col", "COL", "Colosenses", "colosenses", 4, 0, "col colosenses"),
    ("1Thess", "1TH", "1 Tesalonicenses", "1-tesalonicenses", 5, 1, "ts tes tesalonicenses"),
    ("2Thess", "2TH", "2 Tesalonicenses", "2-tesalonicenses", 3, 2, "ts tes tesalonicenses"),
    ("1Tim", "1TI", "1 Timoteo", "1-timoteo", 6, 1, "ti tim timoteo"),
    ("2Tim", "2TI", "2 Timoteo", "2-timoteo", 4, 2, "ti tim timoteo"),
    ("Titus", "TIT", "Tito", "tito", 3, 0, "tit tito"),
    ("Phlm", "PHM", "Filemón", "filemon", 1, 0, "flm filem filemon"),
    ("Heb", "HEB", "Hebreos", "hebreos", 13, 0, "heb hebreos"),
    ("Jas", "JAS", "Santiago", "santiago", 5, 0, "stg sant santiago"),
    ("1Pet", "1PE", "1 Pedro", "1-pedro", 5, 1, "p pe ped pedro"),
    ("2Pet", "2PE", "2 Pedro", "2-pedro", 3, 2, "p pe ped pedro"),
    ("1John", "1JN", "1 Juan", "1-juan", 5, 1, "jn jua juan"),
    ("2John", "2JN", "2 Juan", "2-juan", 1, 2, "jn jua juan"),
    ("3John", "3JN", "3 Juan", "3-juan", 1, 3, "jn jua juan"),
    ("Jude", "JUD", "Judas", "judas", 1, 0, "jud judas"),
    ("Rev", "REV", "Apocalipsis", "apocalipsis", 22, 0, "ap apoc apocalipsis"),
]


def _aliases(name_es: str, serial: int, base: str) -> tuple[str, ...]:
    out: list[str] = []
    if serial == 0:
        # los alias con espacios internos ("cantar de los cantares") van enteros
        parts = base.split()
        if "cantar" in parts:
            out += ["cnt", "cant", "cantares", "cantar de los cantares"]
        else:
            out += parts
        out.append(normalize(name_es))
    else:
        for b in base.split():
            out += [f"{serial}{b}", f"{serial} {b}"]
        out.append(normalize(name_es))
        out.append(normalize(name_es).replace(" ", ""))
    seen: dict[str, None] = {}
    for a in out:
        seen.setdefault(a, None)
    return tuple(seen)


BOOKS: list[Book] = [
    Book(
        id=i,
        osis=osis,
        usfm=usfm,
        name_es=name,
        slug=slug,
        testament="AT" if i <= 39 else "NT",
        chapters=chapters,
        aliases=_aliases(name, serial, base),
    )
    for i, (osis, usfm, name, slug, chapters, serial, base) in enumerate(_RAW, start=1)
]

BY_ID = {b.id: b for b in BOOKS}
BY_USFM = {b.usfm: b for b in BOOKS}
BY_SLUG = {b.slug: b for b in BOOKS}


def verse_id(book_id: int, chapter: int, verse: int) -> int:
    return book_id * 1_000_000 + chapter * 1000 + verse


def split_verse_id(vid: int) -> tuple[int, int, int]:
    return vid // 1_000_000, (vid // 1000) % 1000, vid % 1000


def reference(vid: int) -> str:
    b, c, v = split_verse_id(vid)
    return f"{BY_ID[b].name_es} {c}:{v}"


def resolve_alias(text: str) -> Book | None:
    """Devuelve el libro cuyo alias (normalizado) coincide exactamente con `text`."""
    key = normalize(text)
    for b in BOOKS:
        if key in b.aliases:
            return b
    return None


def insert_books(con) -> None:
    con.executemany(
        "INSERT INTO books(id, osis, name_es, slug, testament, chapters, aliases) VALUES (?,?,?,?,?,?,?)",
        [(b.id, b.osis, b.name_es, b.slug, b.testament, b.chapters, b.aliases_str) for b in BOOKS],
    )
