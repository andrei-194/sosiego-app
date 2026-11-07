#!/usr/bin/env python3
"""Cobertura de lib/domain/ a partir de coverage/lcov.info (spec 10, puerta 3: >= 90%).

Uso: flutter test --coverage && python tools/coverage_domain.py [--min 90] [--verbose]
Sale con 1 si la cobertura total de lib/domain/ queda bajo el minimo.
Nota: lcov solo lista archivos que alguna prueba importa; los no importados se
reportan aparte con 0% (el script los cuenta contando lineas ejecutables aprox.).
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--min", type=float, default=90.0)
    ap.add_argument("--lcov", default=str(ROOT / "coverage" / "lcov.info"))
    ap.add_argument("--verbose", action="store_true", help="lista las lineas sin cubrir")
    args = ap.parse_args()

    lcov = Path(args.lcov)
    if not lcov.exists():
        print("No existe coverage/lcov.info: ejecuta `flutter test --coverage`.")
        return 2

    files: dict[str, dict[int, int]] = {}
    cur: str | None = None
    for line in lcov.read_text(encoding="utf-8").splitlines():
        if line.startswith("SF:"):
            path = line[3:].replace("\\", "/")
            cur = path if "lib/domain/" in path else None
            if cur:
                files.setdefault(cur, {})
        elif cur and line.startswith("DA:"):
            n, hits = line[3:].split(",")[:2]
            files[cur][int(n)] = max(files[cur].get(int(n), 0), int(hits))

    listed = {Path(p).name for p in files}
    total = hit = 0
    print(f"{'archivo':34} {'cubiertas':>10} {'lineas':>7} {'%':>7}")
    for p in sorted(files):
        lines = files[p]
        h = sum(1 for v in lines.values() if v > 0)
        t = len(lines)
        total += t
        hit += h
        pct = 100.0 * h / t if t else 100.0
        print(f"{Path(p).name:34} {h:>10} {t:>7} {pct:>6.1f}%")
        if args.verbose:
            miss = [n for n, v in sorted(lines.items()) if v == 0]
            if miss:
                print("    sin cubrir:", ", ".join(map(str, miss)))
    for f in sorted((ROOT / "lib" / "domain").glob("*.dart")):
        if f.name not in listed:
            print(f"{f.name:34} NO aparece en lcov (ninguna prueba lo importa; cuenta como 0%)")
    pct = 100.0 * hit / total if total else 0.0
    print(f"{'TOTAL lib/domain/':34} {hit:>10} {total:>7} {pct:>6.1f}%  (minimo {args.min:.0f}%)")
    return 0 if pct >= args.min else 1


if __name__ == "__main__":
    sys.exit(main())
