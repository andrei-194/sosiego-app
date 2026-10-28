# Web de enlaces de Sosiego

Páginas estáticas `/v/{libro}-{capitulo}-{versiculo}`, portada `/` y `/privacidad`, generadas desde `content.db` (spec secciones 9 y 11). Sin JavaScript, sin cookies, sin analítica.

## Comandos (desde `web/`)

```
C:\Python312\python.exe -m venv .venv
.venv\Scripts\python -m pip install -r requirements.txt

.venv\Scripts\python tests\fixtures\make_fixture.py build\content.db     # base de muestra
.venv\Scripts\python tests\fixtures\make_fixture.py build\big.db --synthetic 31100   # prueba de carga
.venv\Scripts\python build.py build\content.db                            # escribe dist/
.venv\Scripts\python build.py build\content.db --strict                   # falla si la política tiene [PENDIENTE]
.venv\Scripts\python serve.py dist 8000                                   # ver en local (URL sin .html)
.venv\Scripts\python -m pytest -q
.venv\Scripts\python scripts\subset_fonts.py    # regenera assets/fonts/*.woff2 (solo si cambian las fuentes)
.venv\Scripts\python scripts\make_og.py         # regenera assets/og.png
```

Opciones de `build.py`: `--out`, `--site-url` (o `SOSIEGO_SITE_URL`; dominio pendiente, por defecto `https://sosiego.app`), `--base-path` (o `SOSIEGO_BASE_PATH`, p. ej. `/sosiego` en un project site de GitHub Pages).

## Decisión de URL

Se escriben archivos `v/juan-3-16.html` y se enlaza **sin extensión** (`/v/juan-3-16`). GitHub Pages y Cloudflare Pages sirven la URL sin extensión sin redirección. Así coincide con el spec y con la ruta que recibe `go_router`, y se evitan 31.000 carpetas. `dist/.nojekyll` evita que Pages procese los archivos con Jekyll.

## Cómo se mide el peso (< 50 KB por página, Lora incluida)

`build.page_weight()` calcula el **peor caso de primera visita, sin caché y sin gzip**:

    peso = bytes del HTML (CSS en línea incluido)  +  bytes de cada .woff2 distinto de su @font-face

- El CSS va en línea: una sola petición y primer pintado rápido en el navegador de WhatsApp.
- Las fuentes son subsets latinos (español completo) en woff2, compartidos por todas las páginas: Lora 400 (17,5 KB), Atkinson Hyperlegible 400 (9,5 KB) y 700 (9,7 KB) = 36.664 bytes.
- No cuenta `og.png`: solo lo descargan los rastreadores de vista previa; la página no lo carga.
- El presupuesto se toma como 50.000 bytes (menos que 51.200). `test_presupuesto_de_peso_por_pagina` falla si una página lo supera; `test_peso_del_peor_caso_realista` prueba un versículo de 1.500 caracteres.

Resultado con la muestra: página más pesada 42.621 B (HTML 5.957 + fuentes 36.664). Con 31.100 versículos sintéticos: 42.750 B.

## Estado y pendientes

- `templates/privacy.html` es un **borrador, no asesoría legal**, con campos `[PENDIENTE: ...]` (responsable, correo, fecha, región de PostHog, proveedor de alojamiento).
- Dominio pendiente (spec sección 13): `SITE_URL`/`BASE_PATH` del workflow son provisionales.
- El workflow `.github/workflows/web.yml` usa la muestra mientras no exista el `content.db` real y no despliega salvo disparo manual con `deploy = true`.
