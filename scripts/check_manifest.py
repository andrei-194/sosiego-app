#!/usr/bin/env python3
"""Falla si el manifiesto declara un permiso fuera de la lista del spec (§7).

Uso: python scripts/check_manifest.py [manifiesto ...]
Sin argumentos revisa el manifiesto principal y, si existe, el manifiesto
fusionado de la versión release (build/app/intermediates/**/release/**).
El manifiesto de debug queda fuera: Flutter le añade INTERNET para depurar.
"""
import glob
import re
import sys
import xml.etree.ElementTree as ET

PERMITIDOS = {
    "android.permission.POST_NOTIFICATIONS",
    "android.permission.RECEIVE_BOOT_COMPLETED",
    "android.permission.VIBRATE",
    # Solo la usará el SDK de métricas opt-in (spec §7); hoy no se declara.
    "android.permission.INTERNET",
}
ANDROID = "{http://schemas.android.com/apk/res/android}"


def permisos(ruta):
    arbol = ET.parse(ruta).getroot()
    nombres = set()
    for tag in ("uses-permission", "uses-permission-sdk-23"):
        for el in arbol.iter(tag):
            nombres.add(el.get(ANDROID + "name", ""))
    return nombres


def main(argv):
    rutas = argv[1:] or ["android/app/src/main/AndroidManifest.xml"]
    if not argv[1:]:
        rutas += [
            r
            for r in glob.glob(
                "build/app/intermediates/merged_manifest*/**/AndroidManifest.xml",
                recursive=True,
            )
            if re.search(r"[\/]release", r, re.I)
        ]
    fallos = 0
    for ruta in rutas:
        extra = sorted(permisos(ruta) - PERMITIDOS)
        estado = "OK" if not extra else "PERMISOS NO PERMITIDOS: " + ", ".join(extra)
        print(f"{ruta}: {estado}")
        fallos += bool(extra)
    return 1 if fallos else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
