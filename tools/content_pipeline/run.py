"""Lanzador de etapas: `python -I run.py <etapa> [args]`.

Se usa con `-I` (modo aislado) para que Python no cargue modulos del directorio actual ni de
variables de entorno al leer archivos descargados. Este script agrega SU carpeta a sys.path de
forma explicita (en modo -I no se agrega sola).

Etapas: ingest, tag, similar, moments, reflections, review, export, quality
"""
import runpy
import sys
from pathlib import Path

STAGES = ["ingest", "tag", "similar", "moments", "reflections", "review", "export", "quality"]

if __name__ == "__main__":
    if len(sys.argv) < 2 or sys.argv[1] not in STAGES:
        sys.exit(__doc__)
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    stage = sys.argv.pop(1)
    runpy.run_module(f"pipeline.{stage}", run_name="__main__", alter_sys=True)
