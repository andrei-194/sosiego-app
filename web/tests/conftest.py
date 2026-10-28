import sqlite3
import sys
from pathlib import Path

import pytest

WEB = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(WEB))
sys.path.insert(0, str(WEB / "tests" / "fixtures"))

import build as site_build  # noqa: E402
import make_fixture  # noqa: E402


@pytest.fixture(scope="session")
def dist(tmp_path_factory) -> Path:
    base = tmp_path_factory.mktemp("web")
    db = make_fixture.make(base / "content.db")
    out = base / "dist"
    site_build.build(db, out, site_url="https://example.test")
    return out


@pytest.fixture(scope="session")
def verse_pages(dist) -> list[Path]:
    return sorted((dist / "v").glob("*.html"))


@pytest.fixture
def custom_dist(tmp_path):
    """Construye un dist con textos propios: custom_dist({(libro, cap, ver): texto})."""

    def _make(overrides: dict, **kw) -> Path:
        db = make_fixture.make(tmp_path / "c.db")
        con = sqlite3.connect(db)
        for (b, c, v), text in overrides.items():
            con.execute(
                "INSERT OR REPLACE INTO verses (id, book_id, chapter, verse, text, text_norm) "
                "VALUES (?,?,?,?,?,?)",
                (b * 1_000_000 + c * 1000 + v, b, c, v, text, make_fixture.norm(text)),
            )
        con.commit()
        con.close()
        out = tmp_path / "d"
        site_build.build(db, out, site_url="https://example.test", **kw)
        return out

    return _make
