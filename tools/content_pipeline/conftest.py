"""Configuracion de pytest: ruta del content.db bajo prueba.

Orden de precedencia: --content-db RUTA  >  variable SOSIEGO_CONTENT_DB  >  la muestra v2
(se reconstruye en un directorio temporal con make_sample_db.build, asi la prueba nunca usa
un archivo viejo). Las pruebas de datos corren igual contra la muestra o contra el content.db
real que sale de `export`.
"""
import os
import sqlite3
import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT))


def pytest_addoption(parser):
    parser.addoption("--content-db", action="store", default=None,
                     help="ruta al content.db a verificar (por defecto, la muestra v2)")


@pytest.fixture(scope="session")
def content_db_path(request, tmp_path_factory) -> Path:
    arg = request.config.getoption("--content-db") or os.environ.get("SOSIEGO_CONTENT_DB")
    if arg:
        p = Path(arg)
        if not p.exists():
            pytest.exit(f"no existe el content.db indicado: {p}", returncode=2)
        return p
    import make_sample_db
    p = tmp_path_factory.mktemp("sample") / "content_v2.sample.db"
    make_sample_db.build(p)
    return p


@pytest.fixture()
def db(content_db_path):
    con = sqlite3.connect(f"file:{content_db_path.as_posix()}?mode=ro", uri=True)
    con.execute("PRAGMA foreign_keys = ON")
    yield con
    con.close()


@pytest.fixture()
def meta(db):
    return dict(db.execute("SELECT key, value FROM meta"))


@pytest.fixture()
def schema_con():
    """Base vacia creada solo con schema_content.sql (para las pruebas del esquema)."""
    from pipeline import contentdb
    con = sqlite3.connect(":memory:")
    con.executescript(contentdb.SCHEMA_PATH.read_text(encoding="utf-8"))
    con.execute("PRAGMA foreign_keys = ON")
    yield con
    con.close()
