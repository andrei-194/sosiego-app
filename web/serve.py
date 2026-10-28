"""Servidor local para ver dist/ como lo sirve GitHub Pages (URL sin extension).

Uso:  python serve.py [carpeta=dist] [puerto=8000]
"""
import http.server
import sys
from functools import partial
from pathlib import Path


class Handler(http.server.SimpleHTTPRequestHandler):
    def translate_path(self, path):
        p = super().translate_path(path)
        pp = Path(p)
        if not pp.exists() and pp.with_suffix(".html").exists():
            return str(pp.with_suffix(".html"))
        return p


if __name__ == "__main__":
    root = sys.argv[1] if len(sys.argv) > 1 else "dist"
    port = int(sys.argv[2]) if len(sys.argv) > 2 else 8000
    http.server.ThreadingHTTPServer(("127.0.0.1", port), partial(Handler, directory=root)).serve_forever()
