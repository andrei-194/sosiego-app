#!/usr/bin/env python3
"""Trazabilidad HU <-> prueba (spec, seccion 10).

Lee `Spec SDD MVP App de Versiculos.md`, extrae todos los criterios de aceptacion
(HU-NN.M) y busca su identificador en los NOMBRES de las pruebas (cadenas entre
comillas de `test(`, `testWidgets(`, `group(`, etc. en test/ e integration_test/,
y `def test_...`/cadenas en tools/content_pipeline/tests).

Una cita solo en integration_test/ (necesita dispositivo) no cuenta como prueba
verificada: avisa (y falla con --strict). El registro manda sobre las pruebas.
Un criterio sin prueba hace fallar el script (codigo 1), salvo que este registrado
como "medicion" o "manual" en tools/trace_registry.json con su resultado. Un
registro con resultado "pendiente" solo avisa (con --strict tambien falla).
Tambien falla si una prueba cita un ID que no existe en el spec (errata).

Uso:
    python tools/trace.py              # informe + codigo de salida
    python tools/trace.py --strict     # los registros pendientes tambien fallan
    python tools/trace.py --json       # salida legible por maquina
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SPEC = ROOT / "Spec SDD MVP App de Versículos.md"
REGISTRY = Path(__file__).resolve().parent / "trace_registry.json"
TEST_DIRS = [ROOT / "test", ROOT / "integration_test", ROOT / "tools" / "content_pipeline" / "tests"]
TEST_EXTS = {".dart", ".py"}

ID_RE = re.compile(r"HU-(\d{2})\.(\d{1,2})")
STORY_RE = re.compile(r"^###\s+HU-(\d{2})\b\s*(.*)")
CRIT_RE = re.compile(r"^(\d{1,2})\.\s+(.*)")
STRING_RE = re.compile(r"""(?:'([^'\n]*)'|"([^"\n]*)")""")
VALID_KINDS = {"medicion", "manual"}
VALID_RESULTS = {"ok", "pendiente"}


def parse_spec(path: Path) -> dict[str, str]:
    """Devuelve {ID: texto del criterio} en orden de aparicion."""
    criteria: dict[str, str] = {}
    story: str | None = None
    for line in path.read_text(encoding="utf-8").splitlines():
        m = STORY_RE.match(line)
        if m:
            story = m.group(1)
            continue
        if line.startswith("## ") or (line.startswith("### ") and not STORY_RE.match(line)):
            story = None
            continue
        if story is None:
            continue
        m = CRIT_RE.match(line)
        if m:
            criteria[f"HU-{story}.{int(m.group(1))}"] = m.group(2).strip()
    return criteria


def normalize_id(story: str, num: str) -> str:
    return f"HU-{story}.{int(num)}"


def scan_tests() -> dict[str, list[str]]:
    """Devuelve {ID: [archivo:linea, ...]} segun los IDs citados en cadenas."""
    found: dict[str, list[str]] = {}
    for base in TEST_DIRS:
        if not base.exists():
            continue
        for f in sorted(base.rglob("*")):
            if f.suffix not in TEST_EXTS or not f.is_file():
                continue
            if "__pycache__" in f.parts or "golden" in f.parts and f.suffix == ".png":
                continue
            rel = f.relative_to(ROOT).as_posix()
            for n, line in enumerate(f.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
                for sm in STRING_RE.finditer(line):
                    literal = sm.group(1) if sm.group(1) is not None else sm.group(2)
                    for im in ID_RE.finditer(literal):
                        found.setdefault(normalize_id(*im.groups()), []).append(f"{rel}:{n}")
                # Pruebas Python: def test_HU_04_3_...
                for pm in re.finditer(r"def test_HU_(\d{2})_(\d{1,2})", line):
                    found.setdefault(normalize_id(*pm.groups()), []).append(f"{rel}:{n}")
    return found


def load_registry() -> dict[str, dict]:
    if not REGISTRY.exists():
        return {}
    data = json.loads(REGISTRY.read_text(encoding="utf-8"))
    return data.get("criterios", {})


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--strict", action="store_true", help="los registros pendientes tambien fallan")
    ap.add_argument("--json", action="store_true", help="salida JSON")
    args = ap.parse_args()

    criteria = parse_spec(SPEC)
    tests = scan_tests()
    registry = load_registry()

    covered, registered_ok, pending, missing, only_device = [], [], [], [], []
    for cid in criteria:
        refs = tests.get(cid, [])
        host_refs = [r for r in refs if not r.startswith("integration_test/")]
        if cid not in registry and host_refs:
            covered.append(cid)
        elif cid in registry:
            entry = registry[cid]
            kind, result = entry.get("tipo"), entry.get("resultado")
            if kind not in VALID_KINDS or result not in VALID_RESULTS:
                missing.append(cid)  # registro mal formado no cuenta
            elif result == "ok":
                registered_ok.append(cid)
            else:
                pending.append(cid)
        elif refs:
            # Solo la cita una prueba de integracion (necesita dispositivo): escrita, no verificada aqui.
            only_device.append(cid)
        else:
            missing.append(cid)

    unknown_ids = sorted(i for i in tests if i not in criteria)
    stale_registry = sorted(i for i in registry if i not in criteria)
    bad_registry = sorted(
        i for i, e in registry.items() if e.get("tipo") not in VALID_KINDS or e.get("resultado") not in VALID_RESULTS
    )
    also_tested = sorted(i for i in registry if any(not r.startswith('integration_test/') for r in tests.get(i, [])))

    failed = bool(missing or unknown_ids or stale_registry or bad_registry or (args.strict and (pending or only_device)))

    if args.json:
        print(json.dumps({
            "total": len(criteria), "con_prueba": covered, "registrados_ok": registered_ok,
            "registrados_pendientes": pending, "solo_integracion": only_device, "sin_prueba": missing,
            "ids_desconocidos_en_pruebas": unknown_ids, "registro_obsoleto": stale_registry,
            "registro_mal_formado": bad_registry, "falla": failed,
        }, ensure_ascii=False, indent=2))
        return 1 if failed else 0

    total = len(criteria)
    print(f"Trazabilidad HU-prueba: {total} criterios en el spec")
    print(f"  con prueba automatica : {len(covered)}")
    print(f"  medicion/manual (ok)  : {len(registered_ok)}")
    print(f"  medicion/manual (pend): {len(pending)}")
    print(f"  solo integracion (disp): {len(only_device)}")
    print(f"  SIN PRUEBA            : {len(missing)}")
    for cid in missing:
        print(f"    FALTA {cid}: {criteria[cid][:90]}")
    for cid in pending:
        e = registry[cid]
        print(f"    AVISO {cid} [{e['tipo']}] pendiente: {e.get('detalle', '')[:90]}")
    for cid in only_device:
        print(f"    AVISO {cid} solo tiene prueba de integracion (requiere dispositivo): {tests[cid][0]}")
    for cid in unknown_ids:
        print(f"    ERROR ID inexistente en el spec, citado en {', '.join(tests[cid][:3])}: {cid}")
    for cid in stale_registry:
        print(f"    ERROR el registro cita un criterio inexistente: {cid}")
    for cid in bad_registry:
        print(f"    ERROR registro mal formado (tipo medicion|manual, resultado ok|pendiente): {cid}")
    for cid in also_tested:
        print(f"    NOTA {cid} ya tiene prueba automatica; puede salir del registro")
    print("RESULTADO:", "FALLA" if failed else "OK (con avisos)" if (pending or only_device) else "OK")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
