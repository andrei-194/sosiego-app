# Spec SDD MVP: App de Versículos

Oct 27, 2026 · @andrei rodriguez · Revisión 2: Oct 28, 2026 (cambios marcados «rev. 2»; resumen en la sección 14)

## 1. Visión y alcance

El MVP es un feed vertical de versículos, sin registro y sin internet, que una persona de 70 años y una de 20 puedan usar igual de fácil desde el primer minuto.

**Promesa al usuario:** abre la app, toca cómo se siente, recibe una palabra para hoy y se la envía a alguien.

**Público.** Primario: adultos mayores (60+) con Android de gama media o baja que ya usan WhatsApp a diario. Secundario: jóvenes de 18 a 30 años que llegan por una tarjeta que alguien les compartió.

**Principios de producto**

1. Cero fricción: sin cuenta, sin formularios, un solo ajuste en el arranque (tamaño de letra).
2. Nada oculto: cada gesto tiene un botón visible equivalente.
3. Todo funciona sin conexión; el contenido viaja dentro de la app.
4. Tono cristiano general, sin posturas sobre doctrinas en las que las iglesias difieren.
5. Ningún texto de reflexión u oración se publica sin revisión humana.

**Dentro del MVP**

- Inicio "¿Cómo te sientes hoy?" y "Momentos" (antes de dormir, familiar enfermo, entrevista de trabajo).
- Feed vertical con botones Anterior y Siguiente, y "Más como este".
- Buscador único por referencia, palabra o tema.
- Versículo y reflexión del día, con notificación local.
- Compartir tarjeta 9:16 y enlace por WhatsApp, con dedicatoria opcional.
- Favoritos, historial y racha suave.
- Escuchar con la voz del sistema.
- Tamaño de letra ajustable y modo oscuro.

**Fuera del MVP:** modelo de lenguaje en el teléfono, cuentas y sincronización, comunidad o comentarios, planes de lectura, audio profesional, varias traducciones y monetización.

## 2. Decisiones cerradas

Siete decisiones fijan el diseño y el resto del spec depende de ellas.

| ID | Decisión | Por qué |
| --- | --- | --- |
| D1 | Tono cristiano general: sin santos, sin posturas sobre bautismo, sacramentos o liturgia, sin lenguaje propio de una denominación | La app debe servir a católicos, evangélicos y no afiliados sin que nadie se sienta excluido |
| D2 | Una sola traducción: Reina-Valera 1909 (dominio público) | Se publica sin pedir permisos; su español es antiguo, así que cada reflexión explica el pasaje en lenguaje actual |
| D3 | Todo el contenido (etiquetas, relaciones, reflexiones) se genera en el computador del desarrollador y viaja dentro de la app como una base SQLite ya revisada | La app es rápida, funciona sin internet y no depende de la potencia del teléfono |
| D4 | Flutter para la app | Un solo código para el diseño y las animaciones; la velocidad de una app nativa no es crítica porque solo lee una base local |
| D5 | Solo tecnologías gratuitas y de código abierto, en la app, el pipeline de contenido y la web | Cero licencias y sin dependencia de un proveedor |
| D6 | Sin cuentas ni registro: los datos del usuario viven solo en su teléfono | Quita fricción y simplifica la privacidad |
| D7 | Android primero; iOS queda para una fase posterior (confirmado) | Se desarrolla en Windows y compilar para iOS exige macOS; Android domina el mercado colombiano |

**Costos que no se pueden evitar** (valores aproximados, confirma los vigentes): la cuenta de Google Play (pago único de unos USD 25), la de Apple cuando llegue iOS (unos USD 99 al año) y un dominio propio, que es opcional (unos USD 10 a 15 al año).

## 3. Stack tecnológico

Todo el stack es gratuito y de código abierto; las licencias son las que declara cada proyecto a la fecha de redacción y se confirman con una auditoría de licencias en CI antes de publicar.

### App móvil (Flutter)

| Pieza | Tecnología | Licencia | Para qué |
| --- | --- | --- | --- |
| Framework | Flutter y Dart, última versión estable fijada con FVM | BSD-3 / MIT | Interfaz, animaciones y compilación a Android |
| Estado | flutter\_riverpod | MIT | Estado e inyección de dependencias, fácil de probar |
| Navegación | go\_router | BSD-3 | Rutas declarativas y enlaces profundos |
| Base de datos | paquete sqlite3 + sqlite3\_flutter\_libs, sin ORM | MIT | SQLite propio con FTS5 incluido, sin depender del SQLite del sistema |
| Rutas de archivos | path\_provider | BSD-3 | Copiar la base empaquetada al almacenamiento de la app |
| Ajustes | shared\_preferences | BSD-3 | Tamaño de letra, tema, hora de notificación |
| Notificaciones | flutter\_local\_notifications + timezone | BSD-3 / BSD-2 | Versículo del día programado en el teléfono |
| Voz | flutter\_tts | MIT | Leer en voz alta con el motor del sistema |
| Compartir | share\_plus y url\_launcher | BSD-3 | Hoja de compartir del sistema y enlace wa.me |
| Tarjeta como imagen | RepaintBoundary del SDK de Flutter | BSD-3 | Convertir un widget en PNG sin paquetes extra |
| Fuentes | Lora (versículos) y Atkinson Hyperlegible (interfaz), empaquetadas | OFL | Legibilidad alta; nunca se descargan en ejecución |
| Pruebas | flutter\_test, integration\_test, mocktail | BSD-3 / MIT | Ver sección 10 |

### Pipeline de contenido (en tu computador)

| Pieza | Tecnología | Licencia | Para qué |
| --- | --- | --- | --- |
| Lenguaje | Python 3 y pytest | PSF / MIT | Scripts del pipeline y sus pruebas |
| Modelo de lenguaje | Ollama con Qwen2.5 7B Instruct como punto de partida | MIT / Apache-2.0 | Etiquetar y redactar borradores; se cambia por un modelo mayor si la prueba de calidad (sección 5) no pasa |
| Embeddings | sentence-transformers con un modelo multilingüe de licencia MIT (por ejemplo BGE-M3) | Apache-2.0 / MIT | Calcular versículos parecidos |
| Exportación | SQLite y el módulo sqlite3 de Python | Dominio público | Generar content.db |

### Web de enlaces y operación

| Pieza | Tecnología | Licencia | Para qué |
| --- | --- | --- | --- |
| Páginas /v/ | HTML estático generado con Jinja2 | BSD-3 | Una página por versículo compartible |
| Alojamiento | GitHub Pages o Cloudflare Pages, plan gratuito | Servicio gratuito | Servir la web sin servidor propio |
| Integración continua | GitHub Actions | Servicio gratuito | Pruebas, análisis y compilación del APK en cada cambio |
| Fallos y rendimiento | Android vitals de Google Play Console | Servicio gratuito | Cierres y bloqueos sin añadir ningún SDK |
| Métricas de uso | PostHog Cloud con el SDK oficial posthog\_flutter | MIT (núcleo y SDK, a confirmar) | Retención y compartidos, con consentimiento (sección 11) |

**Regla de dependencias:** cada paquete nuevo debe tener licencia permisiva (MIT, BSD o Apache-2.0), mantenimiento activo y ningún SDK de Firebase ni rastreadores publicitarios.

## 4. Arquitectura de la app

La app tiene tres capas (presentación, dominio y datos) y la presentación nunca toca SQLite directamente: todo el contenido llega por repositorios.

- **Presentación:** pantallas y widgets de Flutter, con controladores Riverpod.
- **Dominio:** entidades (Verse, Reflection, Theme, Moment) y casos de uso (GetNextVerse, SearchVerses, GetDailyContent, BuildShareCard, ScheduleDailyNotifications). Dart puro, sin importar Flutter.
- **Datos:** repositorios con dos bases SQLite separadas, más los servicios del sistema (notificaciones, voz, compartir).

&#91;embedded content: arquitectura por capas · 3 capas y 4 fuentes de datos\]

La presentación pide a los casos de uso, el dominio solo conoce interfaces y la capa de datos las implementa sobre las dos bases SQLite, los ajustes y los servicios del sistema.

**Dos bases de datos, dos ciclos de vida.** `content.db` viaja como asset, es de solo lectura y se reemplaza en cada versión de la app. `user.db` se crea en el teléfono, guarda favoritos, historial y racha, y se migra con `PRAGMA user_version`. Al abrir la app, si `meta.content_version` del asset es mayor que el de la copia instalada, se copia de nuevo `content.db` y `user.db` no se toca.

### Estructura del proyecto

```text
lib/
  core/          tema, tipografía, constantes de accesibilidad, errores
  domain/        entidades, interfaces de repositorio, casos de uso (Dart puro)
  data/
    content/     content_db.dart, repositorios de versículos, temas y reflexiones
    user/        user_db.dart (migraciones), favoritos, historial, racha
    services/    notification_service, tts_service, share_service
  features/
    onboarding/  home/  feed/  search/  daily/  share/  favorites/  settings/
  app.dart       rutas y arranque
assets/
  db/content.db
  fonts/
test/            unitarias y de widgets
integration_test/
tools/content_pipeline/   pipeline en Python (sección 5)
web/             generador de las páginas /v/ (sección 9)
```

### Reglas de arquitectura

1. `domain/` no importa Flutter ni sqlite3; se prueba sin emulador.
2. Los repositorios son interfaces en `domain/`; las pruebas usan implementaciones en memoria.
3. Una consulta a SQLite que tarde más de 16 ms en el dispositivo de referencia (Android de gama baja con 3 GB de RAM, por definir) se mueve a un isolate.
4. Navegación inferior con cuatro pestañas, siempre con texto bajo el icono: Inicio, Versículos, Buscar, Guardados. Ajustes se abre desde el icono de la esquina superior.
5. Objetivo a validar en pruebas: el primer versículo visible en menos de 2 segundos con la app en frío.

### Lógica del feed

1. **Elegibles:** versículos con `is_card_eligible = 1`, es decir `card_score` mayor o igual a un umbral inicial de 0.6 que se calibra con la muestra revisada a mano.
2. **Cola:** la app mantiene 20 identificadores por delante; cuando quedan 5 rellena con 20 más.
3. **Sorteo:** sin reposición entre los elegibles, excluyendo los últimos 500 vistos en `history`.
4. **Modo tema:** si el usuario llega desde un chip de emoción, un momento o "Más como este", la cola sale de `verse_themes` (peso de 0.6 o más), `moment_verses` o `verse_similar`, y se muestra una etiqueta "Tema: nombre · Salir".
5. **Anterior:** pila de historial de la sesión de hasta 100 versículos.
6. **Registro:** un versículo visible 2 segundos o más se guarda en `history`.

## 5. Pipeline de contenido offline

El pipeline convierte el texto de la Reina-Valera 1909 en `content.db` en siete etapas, y ninguna reflexión llega a la app sin que tú la hayas leído.

1. **Ingesta.** Cargar la RV1909 desde una fuente que declare dominio público (por ejemplo eBible.org) y guardar en el repositorio la fuente, la URL y la fecha de descarga. El conteo de versículos (cerca de 31.100) se fija con la fuente elegida y se convierte en una prueba.
2. **Etiquetado.** Para cada versículo el modelo asigna temas y emociones de una lista cerrada, con un peso de 0 a 1, y un `card_score` que mide qué tan bien se entiende el versículo solo. La salida es JSON validado contra un esquema, con reintento si no cumple.
3. **Parecidos.** Calcular embeddings y guardar los 10 vecinos más cercanos de cada versículo, con máximo 2 del mismo libro para dar variedad.
4. **Momentos.** El modelo propone candidatos a partir de las etiquetas y tú eliges de 15 a 20 versículos por momento.
5. **Reflexiones.** Generar borradores con estructura fija (contexto, reflexión, aplicación, oración) para 365 versículos del día, 10 emociones por 20 y 12 momentos por 10: unas 685 en total. Entre 90 y 150 palabras cada una, lo que equivale a cerca de un minuto de lectura o de audio.
6. **Revisión humana.** Una reflexión pasa a `approved` solo después de que la lees y, si hace falta, la corriges. Las etiquetas se revisan por muestra (300 versículos) y se mide cuánto coincides con el modelo.
7. **Exportación.** Generar `content.db` con índices y FTS5, correr `PRAGMA integrity_check` y `VACUUM`, calcular `content_version` y `content_hash`, y ejecutar las pruebas de datos de la sección 10.

&#91;embedded content: pipeline de contenido · 7 etapas, 1 revisión obligatoria\]

Las etapas 1 a 4 preparan los datos; las reflexiones solo avanzan a la exportación cuando la revisión las aprueba, y si no, vuelven a corregirse.

**Por qué revisar el 100% de las reflexiones y solo una muestra de las etiquetas.** Las reflexiones y oraciones son texto que miles de personas leerán como propio de la app, y un error doctrinal es difícil de retirar. Una etiqueta equivocada solo afecta qué versículo aparece bajo un chip. El esfuerzo estimado es de 1 a 2 minutos por reflexión, entre 11 y 23 horas en total.

### Guía editorial para el prompt

- **Cristiano general.** Se puede hablar de Dios, Jesús, el Espíritu Santo, la oración, la fe, la esperanza y el perdón. Se evita: santos y mediación de María, bautismo, sacramentos y liturgia, promesas de prosperidad o sanidad, juicio y condenación, política, otras religiones y predicciones.
- **Sin promesas concretas.** Nunca "Dios te dará el trabajo"; sí "podemos presentarle esta necesidad".
- **Registro.** Primera persona del plural o forma impersonal ("podemos", "pidamos"), para no tener que elegir entre tú y usted.
- **Solo el texto dado.** La reflexión no cita ningún otro versículo; una validación automática rechaza cualquier referencia bíblica distinta de la del versículo ancla.
- **Contexto con certeza.** Autor, destinatarios y fecha solo se mencionan cuando son consenso; si no, se omiten.
- **Temas delicados** (duelo, depresión, miedo a morir): sin minimizar el dolor y con `sensitive = 1`, que activa el aviso de ayuda de la sección 11. Las reflexiones no sustituyen atención médica ni psicológica.

### Taxonomía inicial (se ajusta en la revisión)

- **10 emociones:** ansiedad, tristeza, gratitud, miedo, soledad, perdón, esperanza, cansancio, enojo y duda.
- **12 momentos:** al despertar, antes de dormir, antes de comer, antes de un viaje, antes de una cita médica, familiar enfermo, entrevista o examen, problemas de dinero, pérdida de un ser querido, nacimiento o cumpleaños, reconciliarse y dar gracias.

### Calidad y reproducibilidad

- **Prueba de calidad del modelo antes de la generación masiva:** 50 versículos con el modelo elegido. Pasa si al menos el 90% de las salidas es JSON válido, ninguna cita un versículo inventado y al menos el 80% de las reflexiones se acepta sin reescritura mayor. Si no pasa, se cambia a un modelo más grande que tu equipo pueda correr.
- **Cada salida se guarda en un `work.db` de trabajo** con el prompt, la versión del modelo, la temperatura (0.2 como punto de partida) y la semilla, para rehacer solo lo que cambie y poder explicar de dónde salió cada texto.
- **El tiempo total de generación depende de tu equipo** y se mide con la prueba de 50 versículos antes de planear la fase.

## 6. Esquema de base de datos

Hay dos bases: `content.db` (solo lectura, la genera el pipeline) y `user.db` (se crea en el teléfono); `content.db` pesaría entre 12 y 25 MB, un estimado que se confirma con la primera exportación.

### content.db

```sql
CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT NOT NULL);
-- claves: translation='RV1909', content_version, built_at, content_hash, source_url

CREATE TABLE books (
  id        INTEGER PRIMARY KEY,                 -- 1..66
  osis      TEXT NOT NULL UNIQUE,                -- 'John'
  name_es   TEXT NOT NULL,                       -- 'Juan'
  slug      TEXT NOT NULL UNIQUE,                -- 'juan' (para /v/juan-3-16)
  testament TEXT NOT NULL CHECK (testament IN ('AT','NT')),
  chapters  INTEGER NOT NULL,
  aliases   TEXT NOT NULL                        -- 'jn|jua|juan' para buscar por referencia
);

CREATE TABLE verses (
  id               INTEGER PRIMARY KEY,          -- libro*1000000 + capitulo*1000 + versiculo
  book_id          INTEGER NOT NULL REFERENCES books(id),
  chapter          INTEGER NOT NULL,
  verse            INTEGER NOT NULL,
  text             TEXT NOT NULL,
  text_norm        TEXT NOT NULL,                -- minusculas, sin tildes ni signos
  card_score       REAL NOT NULL DEFAULT 0,      -- 0..1: se entiende solo
  is_card_eligible INTEGER NOT NULL DEFAULT 0,
  UNIQUE (book_id, chapter, verse)
);
CREATE INDEX idx_verses_eligible ON verses(id) WHERE is_card_eligible = 1;

CREATE VIRTUAL TABLE verses_fts USING fts5(
  text_norm, content='verses', content_rowid='id',
  tokenize='unicode61 remove_diacritics 2'
);

CREATE TABLE chapters (
  book_id    INTEGER NOT NULL REFERENCES books(id),
  chapter    INTEGER NOT NULL,
  summary_es TEXT NOT NULL,                      -- una linea, revisada
  PRIMARY KEY (book_id, chapter)
);

CREATE TABLE themes (
  id      INTEGER PRIMARY KEY,
  slug    TEXT NOT NULL UNIQUE,                  -- 'ansiedad'
  name_es TEXT NOT NULL,
  kind    TEXT NOT NULL CHECK (kind IN ('emotion','topic')),
  icon    TEXT NOT NULL,
  sort    INTEGER NOT NULL
);
CREATE TABLE verse_themes (                      -- solo pesos >= 0.3
  theme_id INTEGER NOT NULL REFERENCES themes(id),
  verse_id INTEGER NOT NULL REFERENCES verses(id),
  weight   REAL NOT NULL CHECK (weight BETWEEN 0 AND 1),
  PRIMARY KEY (theme_id, verse_id)
) WITHOUT ROWID;
CREATE INDEX idx_verse_themes_weight ON verse_themes(theme_id, weight DESC);

CREATE TABLE moments (
  id INTEGER PRIMARY KEY, slug TEXT NOT NULL UNIQUE, name_es TEXT NOT NULL,
  description TEXT NOT NULL, icon TEXT NOT NULL, sort INTEGER NOT NULL
);
CREATE TABLE moment_verses (
  moment_id INTEGER NOT NULL REFERENCES moments(id),
  verse_id  INTEGER NOT NULL REFERENCES verses(id),
  rank      INTEGER NOT NULL,
  PRIMARY KEY (moment_id, verse_id)
) WITHOUT ROWID;

CREATE TABLE verse_similar (                     -- solo entre versiculos elegibles
  verse_id   INTEGER NOT NULL REFERENCES verses(id),
  rank       INTEGER NOT NULL,                   -- 1..10
  similar_id INTEGER NOT NULL REFERENCES verses(id),
  score      REAL NOT NULL,
  PRIMARY KEY (verse_id, rank)
) WITHOUT ROWID;

CREATE TABLE reflections (
  id               INTEGER PRIMARY KEY,
  verse_id         INTEGER NOT NULL REFERENCES verses(id),
  kind             TEXT NOT NULL CHECK (kind IN ('daily','emotion','moment')),
  theme_id         INTEGER REFERENCES themes(id),   -- si kind = 'emotion'
  moment_id        INTEGER REFERENCES moments(id),  -- si kind = 'moment'
  context_text     TEXT NOT NULL,
  reflection_text  TEXT NOT NULL,
  application_text TEXT NOT NULL,
  prayer_text      TEXT NOT NULL,
  word_count       INTEGER NOT NULL,
  reading_seconds  INTEGER NOT NULL,                -- word_count / 150 * 60
  sensitive        INTEGER NOT NULL DEFAULT 0,
  status           TEXT NOT NULL CHECK (status = 'approved')  -- solo se exportan aprobadas
);
CREATE INDEX idx_reflections_theme  ON reflections(kind, theme_id);
CREATE INDEX idx_reflections_moment ON reflections(kind, moment_id);
CREATE INDEX idx_reflections_verse  ON reflections(verse_id);

CREATE TABLE daily_calendar (                    -- 366 filas, incluye 02-29
  month_day     TEXT PRIMARY KEY,                 -- 'MM-DD'
  verse_id INTEGER NOT NULL REFERENCES verses(id), reflection_id INTEGER REFERENCES reflections(id)
) WITHOUT ROWID;
```

Después de cargar los versículos se llena el índice con `INSERT INTO verses_fts(verses_fts) VALUES('rebuild')`. La normalización de texto (minúsculas, sin tildes ni signos) debe dar el mismo resultado en Python y en Dart: se comprueba con una lista compartida de casos de prueba.

### user.db

```sql
CREATE TABLE favorites (
  verse_id   INTEGER PRIMARY KEY,
  created_at INTEGER NOT NULL                    -- epoch en milisegundos
);
CREATE TABLE history (
  id       INTEGER PRIMARY KEY AUTOINCREMENT,
  verse_id INTEGER NOT NULL,
  seen_at  INTEGER NOT NULL
);
CREATE INDEX idx_history_seen ON history(seen_at DESC);   -- se conservan las ultimas 2000

CREATE TABLE activity_days (day TEXT PRIMARY KEY);         -- 'YYYY-MM-DD' local, para la racha
CREATE TABLE app_state (key TEXT PRIMARY KEY, value TEXT NOT NULL);
-- claves: install_id (UUID aleatorio, solo si hay consentimiento), first_run_at, content_version_installed
```

**Ajustes en shared\_preferences:** `font_scale` (normal, grande, muy\_grande), `theme_mode`, `notif_enabled`, `notif_time` (HH:mm), `analytics_opt_in`, `onboarding_done`, `tts_rate`.

**Invariantes que garantiza el diseño:** `content.db` no puede contener reflexiones sin aprobar (restricción CHECK), cada versículo de `verse_similar`, `moment_verses` y `daily_calendar` existe en `verses`, y el calendario tiene exactamente 366 filas.

## 7. Historias de usuario y criterios de aceptación

El MVP tiene 13 historias; cada criterio se verifica con una prueba automática o una medición, y las cifras marcadas como objetivo se calibran en el dispositivo de referencia. Un criterio se cita como HU-04.3 (historia 4, criterio 3).

| ID | Historia | Hook | Fase |
| --- | --- | --- | --- |
| HU-01 | Primer arranque y tamaño de letra | Accesibilidad | 1 |
| HU-02 | Inicio con emociones y momentos | Emocional | 1 |
| HU-03 | Acompañamiento: versículo, reflexión y oración | Emocional | 2 |
| HU-04 | Feed vertical de versículos | Descubrimiento | 1 |
| HU-05 | Más como este | Descubrimiento | 1 |
| HU-06 | Buscador único | Descubrimiento | 1 |
| HU-07 | Versículo del día con notificación; reflexión del día en la fase 2 | Hábito | 1 y 2 |
| HU-08 | Escuchar | Accesibilidad | 1 |
| HU-09 | Compartir tarjeta, WhatsApp y dedicatoria | Viral | 1 |
| HU-10 | Favoritos e historial | Hábito | 1 |
| HU-11 | Racha suave | Hábito | 2 |
| HU-12 | Ajustes | Accesibilidad | 1 |
| HU-13 | Aviso de ayuda en temas delicados | Seguridad | 2 |

### HU-01 Primer arranque y tamaño de letra

Como persona que abre la app por primera vez, quiero elegir cómo prefiero leer, para ver el texto cómodo sin buscar ajustes.

1. Se muestra una sola pantalla con la pregunta "¿Cómo prefieres leer?" y tres opciones, Normal, Grande y Muy grande, cada una con una muestra de versículo real a su tamaño.
2. Al tocar una opción, la vista previa cambia al instante; un botón "Continuar" confirma.
3. La opción preseleccionada sale del tamaño de fuente del sistema: factor 1.3 o más → Grande; 1.6 o más → Muy grande; si no, Normal.
4. Tras confirmar se entra a Inicio sin pedir permisos, cuenta ni datos. La pantalla no vuelve a aparecer; el tamaño se cambia en Ajustes.
5. Sin conexión funciona igual.

### HU-02 Inicio con emociones y momentos

Como persona que no sabe qué buscar, quiero tocar cómo me siento o qué estoy viviendo, para recibir algo que me hable a mí.

1. Inicio muestra, en este orden: tarjeta "Versículo de hoy" (HU-07), el título "¿Cómo te sientes hoy?" con 10 chips de emoción y la sección "Momentos" con 12 chips.
2. Los chips se leen de `themes` (kind = 'emotion') y de `moments`, en orden `sort`. Cada chip lleva icono y texto, y mide al menos 56 dp de alto.
3. En la fase 1 un toque abre el feed en modo tema; desde la fase 2 abre el acompañamiento (HU-03).
4. La respuesta al toque tarda menos de 300 ms en el dispositivo de referencia (objetivo).
5. La pantalla solo se desplaza en vertical.

### HU-03 Acompañamiento: versículo, reflexión y oración

Como persona con una emoción, quiero recibir con un solo toque un versículo, una reflexión corta y una oración, para sentirme acompañada.

1. Se elige una reflexión con `kind = 'emotion'` y el tema tocado, evitando las cuyo `verse_id` esté en los últimos 500 de `history`; si no queda ninguna, se elige cualquiera del tema.
2. Se muestra la referencia, el versículo y cuatro bloques con encabezado visible: Contexto, Reflexión, Aplicación y Oración. No hay título propio de la reflexión: el encabezado de la pantalla es la referencia (rev. 2).
3. Se muestra el tiempo de lectura (por ejemplo "1 min") calculado de `reading_seconds`.
4. Botones con texto: Escuchar, Compartir, Guardar, "Otra palabra" (otra reflexión del mismo tema) y "Más versículos de este tema" (feed en modo tema).
5. Si `sensitive = 1`, se muestra el aviso de ayuda de HU-13.

### HU-04 Feed vertical de versículos

Como persona que quiere explorar, quiero pasar de un versículo a otro con un deslizamiento o con un botón, para descubrir sin esfuerzo.

1. Cada página ocupa toda la pantalla con un versículo, su referencia y un fondo; el desplazamiento es vertical y se ajusta a la página (PageView).
2. Hay botones "Anterior" y "Siguiente" visibles, de al menos 56 dp. En las primeras tres páginas de la primera sesión se muestra la ayuda "Desliza o toca Siguiente"; la ayuda se adapta al tamaño de letra y nunca se oculta por agrandarla (rev. 2).
3. La selección sigue la lógica de la sección 4 y, además, nunca muestra más de dos versículos seguidos del mismo libro.
4. Cada página ofrece Guardar, Compartir, Escuchar y "Más como este", con texto bajo cada icono.
5. El fondo se elige entre 8 y 10 estilos de gradiente o color según `verse_id` (siempre el mismo para el mismo versículo), con contraste texto-fondo de al menos 7:1. Son los mismos estilos de la tarjeta compartida (HU-09); en modo oscuro el feed usa la variante oscura del estilo, y la tarjeta compartida usa siempre la variante fija que la persona elige (rev. 2).
6. Objetivo a validar: durante el deslizamiento, menos del 5% de los cuadros superan 16 ms en el dispositivo de referencia.

### HU-05 Más como este

Como persona a la que le gustó un versículo, quiero ver otros parecidos, para seguir en el mismo ánimo.

1. "Más como este" abre el feed con los 10 versículos de `verse_similar`, en orden de `rank`, y una etiqueta fija "Parecidos a Juan 3:16 · Salir".
2. Al terminar los 10, aparece una tarjeta final con dos botones: "Volver al feed" y "Ver más parecidos" (los parecidos del último versículo).
3. El botón se muestra solo si el versículo tiene filas en `verse_similar`; una prueba de datos garantiza que todo versículo elegible las tiene.

### HU-06 Buscador único

Como persona que busca algo concreto, quiero escribir en un solo campo una referencia, una palabra o un tema, para encontrarlo sin entender filtros.

1. Un campo con lupa y la sugerencia "Busca una palabra, un tema o Juan 3:16".
2. La entrada se resuelve en este orden: (a) referencia, (b) tema o momento, (c) texto.
3. **Referencia:** acepta libro, capítulo, versículo o rango, con abreviaturas y sin tildes ("jn 3 16", "Juan 3:16", "1 corintios 13:4-7"). Un capítulo o un rango devuelve la lista de esos versículos en orden; esa lista es la única vista de capítulo del MVP, cada versículo con las mismas acciones que en el feed, y "capítulo anterior/siguiente" queda para la fase 4 (rev. 2). El libro se resuelve con `books.aliases`.
4. **Tema o momento:** si la entrada normalizada coincide con el nombre de un tema o momento, aparece arriba un botón "Ver versículos sobre ansiedad" que abre el feed en modo tema.
5. **Texto:** consulta FTS5 con prefijo en la última palabra, ordenada por `bm25`, con 30 resultados como máximo y la palabra resaltada.
6. Cada resultado muestra la referencia en negrita y hasta dos líneas de texto; un toque abre el versículo con sus acciones.
7. Sin resultados: el mensaje "No encontramos eso. Prueba con una palabra más corta o elige un tema" y los chips de emoción.
8. La búsqueda se lanza 250 ms después de dejar de escribir y devuelve resultados en menos de 200 ms (objetivo). La normalización es la misma que usa el pipeline.
9. La búsqueda por voz queda fuera del MVP (ver sección 13).
10. No hay búsquedas recientes ni sugerencias aprendidas: lo escrito vive solo en memoria (coherente con HU-13.5). Las sugerencias del campo vacío son fijas: los chips de emoción (rev. 2).

### HU-07 Versículo del día con notificación

Como persona que quiere un momento diario, quiero recibir cada día un versículo a la hora que elija, para que sea un hábito sin esfuerzo.

1. El versículo del día sale de `daily_calendar` según la fecha local (MM-DD), de modo que todas las personas ven el mismo cada día. Si `reflection_id` no es nulo, el día incluye reflexión (fase 2).
2. Inicio muestra la tarjeta "Versículo de hoy" con Leer, Escuchar y Compartir.
3. El permiso de notificaciones no se pide al arrancar. Una tarjeta propia en Inicio pregunta "¿Quieres recibir el versículo cada día?" con tres horas (mañana 6:30, tarde 13:00, noche 20:00) y "Ahora no". Aparece en la segunda apertura o tras ver 5 versículos, lo que ocurra primero. Solo al tocar una hora se lanza el permiso del sistema (POST\_NOTIFICATIONS en Android 13 o superior).
4. Si responde "Ahora no", la tarjeta vuelve una sola vez a los 7 días; después solo se activa desde Ajustes.
5. Al abrir la app y al cambiar la hora se programan las próximas 30 notificaciones, una por día, cada una con el texto de ese día. En Android se usa el modo inexacto (`inexactAllowWhileIdle`) para no pedir el permiso de alarmas exactas, así que pueden llegar con unos minutos de retraso. Se reprograman tras reiniciar el teléfono (RECEIVE\_BOOT\_COMPLETED).
6. El texto de la notificación usa el estilo de texto largo de Android; si el versículo supera 180 caracteres se corta con "…" y el toque abre el versículo completo.
7. Tocar la notificación abre el versículo de ese día en Inicio, con la app abierta o cerrada.
8. Limitaciones conocidas: si la persona no abre la app en 30 días, las notificaciones terminan; y algunos fabricantes bloquean las alarmas con su ahorro de batería. Ajustes incluye "Ayuda con las notificaciones" con los pasos para quitar ese ahorro de batería para la app.

### HU-08 Escuchar

Como persona que lee con dificultad o prefiere oír, quiero que la app me lea el texto en voz alta, para disfrutarlo sin esfuerzo.

1. El botón "Escuchar" está en el feed, el acompañamiento, el versículo del día y los guardados.
2. Usa `flutter_tts` con el idioma es-CO si el teléfono lo tiene y, si no, otro español (es-US, es-MX, es-ES).
3. La referencia se dice en forma hablada: "Juan, capítulo 3, versículo 16". En el acompañamiento se leen en orden versículo, contexto, reflexión, aplicación y oración, con una pausa de medio segundo entre bloques.
4. El botón cambia a "Pausar" y "Detener" mientras se reproduce.
5. La lectura se detiene al salir de la pantalla, al pasar a otro versículo y al perder el foco de audio (por ejemplo, una llamada).
6. La velocidad se elige en Ajustes entre Lenta, Normal y Rápida (valores iniciales de `speechRate` 0.4, 0.5 y 0.6, a calibrar).
7. Si el teléfono no tiene voz en español, se muestra el mensaje "Tu teléfono no tiene voz en español. Puedes instalarla en Ajustes del teléfono, en Idioma y Salida de texto a voz".

### HU-09 Compartir tarjeta, WhatsApp y dedicatoria

Como persona que quiere animar a alguien, quiero enviarle un versículo en una tarjeta bonita con su nombre, para que sepa que pensé en él o ella.

1. "Compartir" abre una hoja con la vista previa de la tarjeta en formato 9:16, un selector de 8 a 10 estilos con nombre, el campo opcional "Para:" (máximo 30 caracteres) y dos botones: **Compartir imagen** (principal) y **Enviar texto por WhatsApp** (secundario).
2. La tarjeta lleva el versículo, la referencia, la dedicatoria si existe (por ejemplo "Para mamá") y, en una esquina, el nombre de la app y el enlace corto con letra legible, nunca menor a 28 px sobre el ancho de 1080 px.
3. La imagen es un PNG de 1080 × 1920 px generado en el teléfono con `RepaintBoundary`, sin conexión y en menos de 1 segundo (objetivo).
4. **Compartir imagen** abre la hoja de compartir del sistema con la imagen y un texto con el versículo y el enlace; WhatsApp suele usar ese texto como pie de la imagen. **Enviar texto por WhatsApp** abre `https://wa.me/?text=` con el versículo, la referencia, la dedicatoria y el enlace, sin imagen. Enviar la imagen directamente a WhatsApp sin pasar por la hoja del sistema exige código nativo y queda fuera del MVP.
5. El enlace tiene la forma `https://{dominio}/v/{slug-del-libro}-{capitulo}-{versiculo}`, por ejemplo `/v/juan-3-16`. El dominio es una decisión pendiente (sección 13).
6. Si el versículo es largo, la letra de la tarjeta baja hasta un mínimo de 36 px; si aun así no cabe, se corta con "…" y el enlace lleva al texto completo.
7. Todos los estilos cumplen contraste de al menos 7:1, comprobado con una prueba automática.
8. La imagen y la dedicatoria nunca se suben a ningún servidor.

### HU-10 Favoritos e historial

Como persona que encuentra un versículo que le habla, quiero guardarlo y volver a él, para tenerlo siempre a mano.

1. El botón "Guardar" (corazón con texto) alterna entre guardado y no guardado, con una animación breve y la etiqueta "Guardado".
2. La pestaña Guardados tiene dos vistas, "Guardados" y "Vistos" (los últimos 100 de `history`), con el más reciente primero. Cada elemento permite Compartir, Escuchar y Quitar.
3. "Quitar" no abre un diálogo: elimina y muestra durante 5 segundos un aviso con "Deshacer", que restituye el favorito con su fecha original y en su posición (rev. 2).
4. Sin guardados, se muestra un estado vacío con una frase amable y el botón "Ir a versículos".
5. Ajustes y Guardados avisan: "Tus guardados viven solo en este teléfono".
6. "Enviarme mis guardados" comparte la lista como texto (referencia y versículo) por la hoja del sistema, como respaldo si cambia de teléfono.

### HU-11 Racha suave

Como persona que quiere constancia sin presión, quiero ver cuántos días llevo con la Palabra, para animarme a seguir.

1. Un día cuenta como activo si se vio al menos un versículo durante 2 segundos o más ese día (fecha local), y se registra en `activity_days`.
2. Inicio muestra "Llevas N días contigo" cuando N es 2 o más. N son los días consecutivos que terminan hoy o ayer.
3. Si la racha se interrumpe, no se muestra ninguna pérdida: el texto pasa a "Hoy es un buen día para empezar". No se usa rojo ni alertas.
4. En los días 7, 30 y 100 aparece una tarjeta compartible "7 días con la Palabra", que reutiliza la hoja de HU-09.
5. Con N = 1 no se muestra contador. "Hoy es un buen día para empezar" solo aparece si hubo una racha de 2 o más que se interrumpió; a quien nunca la tuvo no se le muestra nada negativo (rev. 2).
6. El indicador lleva texto además del icono y su detalle se abre con un botón visible, no con un gesto (rev. 2).

### HU-12 Ajustes

Como persona que quiere adaptar la app, quiero cambiar lo básico en un solo lugar, para sentirla mía.

1. Las opciones son: Tamaño de letra (con vista previa), Tema (Claro, Oscuro o Automático), Versículo diario (activar y hora), Velocidad de voz, Ayuda con las notificaciones, Enviarme mis guardados, Privacidad, Acerca de y Enviar comentarios.
2. Los cambios se aplican al instante y se conservan al cerrar la app.
3. Privacidad incluye el enlace a la política y el interruptor "Ayudar a mejorar la app (anónimo)", que refleja la decisión tomada en el aviso de la sección 11.
4. Acerca de muestra la versión de la app, `content_version`, la traducción (Reina-Valera 1909, dominio público) y la fuente del texto.
5. Enviar comentarios abre el correo con un destinatario predefinido.

### HU-13 Aviso de ayuda en temas delicados

Como persona que atraviesa un momento muy difícil, quiero encontrar una orientación clara de a quién acudir, para no quedarme solo con un versículo.

1. Cuando se muestra una reflexión con `sensitive = 1`, o la búsqueda coincide con una lista corta de términos de crisis (curada y revisada por ti y, si es posible, por una persona con formación en salud mental), se agrega al final un bloque discreto: "Si sientes que no puedes más o piensas en hacerte daño, habla hoy con alguien" y el botón "Llamar a una línea de ayuda".
2. El texto y el número vienen de `meta` (`help_line_text` y `help_line_number`) para poder actualizarlos con cada versión. El número se verifica con una fuente oficial en la lista de comprobación previa a cada publicación.
3. El botón abre el marcador del teléfono con el número (`tel:`); la app no llama sola.
4. El aviso no bloquea ni reemplaza el versículo.
5. Lo que la persona escribe en el buscador nunca se guarda ni se envía.
6. El cuerpo de la reflexión nunca se oculta tras un aviso previo: el bloque de ayuda va al final y no condiciona la lectura (rev. 2).

### Requisitos transversales

| Requisito | Valor | Cómo se verifica |
| --- | --- | --- |
| Funciona sin internet | Todos los flujos, salvo abrir enlaces externos | Prueba de integración en modo avión |
| Tamaño de descarga | Menos de 60 MB (objetivo) | Tamaño del paquete AAB en CI |
| Versión mínima de Android | Android 8.0 (API 26), a confirmar contra el mínimo de la versión de Flutter elegida | Configuración del proyecto y prueba en un equipo real |
| Texto ampliado | Sin desbordes con `textScaler` hasta 2.0 | Pruebas de widgets con factor 2.0 |
| Zonas táctiles | 48 × 48 dp mínimo; 56 dp en acciones principales | `androidTapTargetGuideline` de flutter\_test |
| Etiquetas de accesibilidad | Todo icono con texto visible y etiqueta para TalkBack | `labeledTapTargetGuideline` y revisión manual con TalkBack |
| Contraste | 7:1 en versículos; 4.5:1 en el resto de la interfaz | `textContrastGuideline` y prueba de contraste de los estilos |
| Animaciones | Se reducen o eliminan si el sistema lo pide | Prueba con `disableAnimations` |
| Permisos de Android | Solo POST\_NOTIFICATIONS, RECEIVE\_BOOT\_COMPLETED, VIBRATE e INTERNET (solo la usa el SDK de métricas, que no envía nada sin consentimiento) | Revisión del manifiesto de la versión final en CI |
| Idioma | Español de Colombia; todos los textos en archivos ARB desde el inicio | Prueba que falla si hay textos fijos en widgets |
| Arranque | Primer versículo visible en menos de 2 s en frío (objetivo) | Medición con DevTools en el dispositivo de referencia |

## 8. UX y accesibilidad

La misma interfaz sirve a mayores y jóvenes: el diseño se calcula para la persona que más lo necesita (letra grande, un objetivo por pantalla, ningún gesto sin botón) y se viste con detalles que atraen a los jóvenes (modo oscuro, tarjetas con estilo, animaciones suaves).

### Tamaños de letra

El factor elegido en HU-01 multiplica los tamaños base. El factor final es el mayor entre el elegido y el del sistema, con un tope de 2.0, para respetar al sistema sin que ambos se sumen. Los valores son iniciales y se calibran en la prueba de usabilidad.

| Elemento | Base (sp) | Normal ×1.0 | Grande ×1.3 | Muy grande ×1.6 |
| --- | --- | --- | --- | --- |
| Versículo (Lora, regular) | 22 | 22 | 29 | 35 |
| Reflexión y oración (Atkinson Hyperlegible, regular) | 18 | 18 | 23 | 29 |
| Botones y chips (Atkinson Hyperlegible, seminegrita) | 18 | 18 | 23 | 29 |
| Referencia, por ejemplo Juan 3:16 (negrita) | 16 | 16 | 21 | 26 |
| Texto secundario | 14 | 14 | 18 | 22 |

Ningún texto de la interfaz baja de 14 sp en el tamaño Normal.

### Color, forma y movimiento

| Token | Claro | Oscuro |
| --- | --- | --- |
| Fondo | #FBF7F0 | #14110D (rev. 2; antes #12161C) |
| Texto principal | #1F1B16 | #F3EBDD (rev. 2; antes #F2EEE6) |
| Acento | #8A4B08 | #E2B77E (rev. 2; antes #E8B769) |

Estos colores son una propuesta inicial; los valores finales se fijan como tokens y se validan con la prueba de contraste (7:1 para versículos, 4.5:1 para el resto).

**Rev. 2, contrastes medidos (WCAG):** texto sobre fondo claro 16.0:1 y oscuro 15.9:1; acento claro #8A4B08 sobre el fondo 6.4:1 (con #8A5A2B baja a 5.5:1 y a 4.8:1 sobre el extremo más oscuro del degradado, demasiado cerca del mínimo); acento oscuro 10.1:1. El fondo oscuro pasa de azul-negro a marrón-negro para mantener una sola familia cálida con el papel y el ámbar; el contraste no empeora.

- **Fondos de tarjeta y de feed:** solo gradientes y texturas suaves, sin fotografías. Así no hay licencias de imágenes y la app pesa menos. El contraste se mide en el punto más desfavorable de cada degradado.
- **Forma:** esquinas de 20 dp en tarjetas y 28 dp en bloques grandes (rev. 2; antes 16 dp, se amplió porque se ve más amable y no afecta al contraste), botones de 56 dp de alto en acciones principales, espacios de 16 y 24 dp.
- **Movimiento:** transiciones de 250 a 300 ms, sin destellos y sin reproducción automática; todo se reduce si el sistema lo pide.
- **Textos de la interfaz:** cercanos y respetuosos, sin jerga ni anglicismos. Se dice "Guardar" y "Siguiente", no "Like" ni "Streak".

### Pantallas

| Pantalla | Qué muestra | Acción principal |
| --- | --- | --- |
| Bienvenida (una vez) | Pregunta "¿Cómo prefieres leer?" con tres muestras | Continuar |
| Inicio | Versículo de hoy, "¿Cómo te sientes hoy?", Momentos, racha y tarjeta de notificación | Tocar una emoción |
| Versículos | Feed vertical a pantalla completa | Siguiente |
| Acompañamiento (fase 2) | Versículo, contexto, reflexión, aplicación y oración | Escuchar |
| Buscar | Campo único y resultados | Escribir |
| Guardados | Guardados y Vistos | Abrir un versículo |
| Ajustes | Opciones de HU-12 | Cambiar tamaño de letra |
| Hoja de compartir | Vista previa, estilos, campo "Para:" | Compartir imagen |

La navegación inferior tiene cuatro pestañas con texto bajo el icono: Inicio, Versículos, Buscar y Guardados.

### Reglas de diseño

**Para mayores**

- Un objetivo por pantalla y dos acciones principales visibles como máximo.
- Todo gesto tiene un botón equivalente; no hay pulsaciones largas, ni pellizcos, ni gestos escondidos.
- Sin límites de tiempo ni avance automático.
- Los errores se dicen en lenguaje sencillo, sin códigos.
- Los interruptores dicen "Activado" o "Desactivado" con texto.

**Para jóvenes**

- Feed fluido, modo oscuro automático y tarjetas con 8 a 10 estilos con nombre (por ejemplo Amanecer, Noche, Papel y Mar).
- Compartir en dos toques: "Compartir" y "Compartir imagen".
- Micro animación del corazón al guardar.

### Prueba de usabilidad (antes de publicar)

Cinco adultos mayores y cinco jóvenes, sin explicación previa, hacen cuatro tareas: encontrar un versículo sobre la tristeza, guardarlo, enviárselo a un familiar con su nombre, y activar el versículo diario a las 6:30. Objetivo: al menos el 80% completa cada tarea sin ayuda, y la tarea de compartir tarda menos de 90 segundos.

## 9. Compartir: tarjeta, texto y página web

Compartir es el motor de crecimiento: cada tarjeta enviada debe verse bien en WhatsApp, y quien la recibe sin la app debe poder llegar a una página que muestre el versículo y lo lleve a la tienda.

### La tarjeta (imagen 1080 × 1920 px)

| Zona | Especificación |
| --- | --- |
| Márgenes | 96 px a los lados y 200 px arriba y abajo, para que las interfaces de estados e historias no tapen el texto |
| Dedicatoria (opcional) | "Para mamá", Atkinson Hyperlegible seminegrita, 56 px, arriba del versículo |
| Versículo | Lora regular, centrado, ajuste automático entre 72 y 36 px dentro de un cuadro de 888 × 1100 px; si no cabe a 36 px se corta con "…" |
| Referencia | Atkinson Hyperlegible negrita, 44 px, debajo del versículo |
| Pie | Nombre de la app a 32 px y enlace a 28 px como mínimo, en la esquina inferior |

- **Ajuste de tamaño:** búsqueda binaria del tamaño de letra más grande que cabe en el cuadro.
- **Generación:** `RepaintBoundary.toImage` con `pixelRatio = 1080 / ancho lógico`, codificado a PNG y guardado en la carpeta temporal como `share_{verse_id}_{style_id}.png`. Los archivos temporales se borran al iniciar la app.
- **Estilos:** una clase `CardStyle` con id, nombre, degradado, color de texto y color de acento, definida en código. Una prueba recorre todos los estilos y falla si alguno baja de 7:1 de contraste.
- **Fuentes empaquetadas:** la tarjeta se ve igual en todos los teléfonos y sin internet.

### El texto que acompaña

Tanto la imagen como el envío por WhatsApp usan este formato, y la dedicatoria solo aparece si la persona la escribió:

```text
«{texto del versículo}»
{referencia}
Para {nombre}
{enlace}
```

La dedicatoria nunca va dentro del enlace: el enlace es el mismo para todos.

### La página del enlace

Una página estática por cada versículo, en `/v/{slug-del-libro}-{capitulo}-{versiculo}`, generada desde `content.db`.

- **Generación:** `web/build.py` lee `content.db`, aplica una plantilla Jinja2 y escribe `dist/`. Incluye también la portada `/` y la política de privacidad `/privacidad`.
- **Alojamiento:** GitHub Pages, desplegado con GitHub Actions para no guardar en el repositorio los cerca de 31.000 archivos generados. Se confirman los límites vigentes del servicio antes de publicar.
- **Contenido:** el versículo en grande, la referencia, el botón "Descargar en Google Play" y un enlace "Ver el siguiente versículo" que lleva a la página del versículo siguiente.
- **Vista previa en WhatsApp:** etiquetas Open Graph (`og:title` con la referencia, `og:description` con el texto del versículo, `og:url` y `og:image`) y `twitter:card = summary`. La imagen es una sola, de la marca, de 1200 × 630 px y ligera (idealmente menos de 300 KB); en el MVP no se genera una imagen por versículo.
- **Ligera y sin rastreo:** HTML y CSS sin JavaScript, sin cookies y sin analítica, con la fuente Lora alojada en la propia web y un peso total menor de 50 KB por página.
- **Idioma y accesibilidad:** `lang="es"`, los mismos tamaños y contrastes de la sección 8.

### De la página a la instalación

- El botón de la página usa el enlace de la ficha de Google Play con el parámetro `referrer` (`utm_source=share`, `utm_medium=link`, `utm_campaign=verse`). Google Play Console agrupa las instalaciones por esos parámetros en sus informes de adquisición, sin añadir ningún SDK a la app (se confirma que el informe esté disponible para la cuenta).
- Mejora para la fase 3: enlaces de aplicación verificados (`/.well-known/assetlinks.json` y un filtro de intención con `autoVerify`) para que el enlace abra directamente el versículo si la app ya está instalada. `go_router` ya recibe la ruta `/v/...` y la convierte en un `verse_id`.

## 10. Estrategia de pruebas (TDD)

Cada criterio de aceptación se convierte primero en una prueba que falla y el código se escribe hasta que pase, empezando por los datos y el dominio, que no necesitan emulador.

**Trazabilidad.** El identificador del criterio va en el nombre de la prueba, por ejemplo `test('HU-04.3 no muestra más de dos versículos seguidos del mismo libro')`. Un script (`tools/trace.py`) lee este spec y los archivos de prueba y hace fallar la integración continua si un criterio no tiene prueba, salvo los marcados como "medición" o "manual", que se registran con su resultado.

### Niveles de prueba

| Nivel | Herramienta | Qué cubre |
| --- | --- | --- |
| Datos | pytest sobre `content.db` | Invariantes del contenido (lista abajo) |
| Unitarias de dominio | flutter\_test, mocktail | Parser de referencias, normalización, selección del feed, racha, factor de letra, texto compartido, versículo del día, fechas |
| Widgets | flutter\_test | Pantallas con repositorios en memoria, texto ampliado a 2.0, guías de accesibilidad, estados vacíos |
| Golden | flutter\_test (`matchesGoldenFile`) | Cada estilo de tarjeta con tres largos de versículo; pantallas clave en claro y oscuro y en los tres tamaños de letra |
| Integración | integration\_test en emulador, modo avión | Flujos completos de la sección 7 |
| Rendimiento | DevTools en el dispositivo físico de referencia | Arranque, deslizamiento y búsqueda frente a los objetivos |
| Manual | TalkBack, voz es-CO, notificaciones en varios teléfonos, usabilidad | Lo que no se automatiza |

### Pruebas de datos (pipeline y `content.db`)

1. El total de versículos es exactamente el conteo fijado en la ingesta.
2. `PRAGMA integrity_check` devuelve `ok` y `PRAGMA foreign_key_check` no devuelve filas.
3. Todo versículo elegible tiene 10 filas en `verse_similar` y ninguna apunta a un versículo no elegible.
4. Cada emoción tiene al menos 40 versículos con peso de 0.6 o más, y cada momento al menos 15 (los mínimos se ajustan con la taxonomía final).
5. `daily_calendar` tiene 366 filas, incluido el 02-29, y todas sus referencias existen.
6. Cada reflexión tiene entre 90 y 150 palabras, estado `approved` y no contiene ninguna referencia bíblica distinta de la de su versículo ancla.
7. Ninguna reflexión contiene términos de la lista de términos prohibidos de la guía editorial.
8. La búsqueda de texto en `verses_fts` devuelve resultados para una lista de palabras de control.
9. La función de normalización de Python y la de Dart dan el mismo resultado sobre una lista compartida de casos.
10. Al arrancar la app, `sqlite_compileoption_used('ENABLE_FTS5')` devuelve 1.

### Casos que el dominio debe cubrir sí o sí

- **Referencias:** "jn 3 16", "Juan 3:16", "  JUAN  3 : 16 ", "1 corintios 13:4-7", "salmo 23", "1co 13", un libro inexistente y un capítulo fuera de rango.
- **Feed:** con semilla fija, no repite los últimos 500, no pone más de dos del mismo libro seguidos y rellena la cola al llegar a 5.
- **Fechas:** versículo del día para el 29 de febrero, cambio de zona horaria (America/Bogota) y programación de 30 notificaciones desde cualquier hora.
- **Racha:** días consecutivos, un día saltado, cambio de mes y de año.
- **Letra:** factor final = máximo entre el elegido y el del sistema, con tope en 2.0.

### Puertas de calidad en CI (GitHub Actions)

1. `dart format` sin cambios y `flutter analyze` sin advertencias, con reglas estrictas.
2. Pruebas unitarias, de widgets y golden. Los golden se generan siempre en el mismo sistema (Linux) para evitar diferencias de renderizado entre equipos.
3. Cobertura de `domain/` de al menos el 90%.
4. Pruebas de datos con pytest sobre el `content.db` que se va a empaquetar.
5. Auditoría de licencias de las dependencias y revisión de los permisos del manifiesto.
6. Tamaño del AAB bajo el objetivo y verificación de trazabilidad.

### Definición de terminado de una historia

- Todos sus criterios tienen prueba en verde, o resultado de medición o revisión manual registrado.
- Pasa las guías de accesibilidad de flutter\_test.
- Los golden afectados se revisaron a ojo antes de actualizarlos.
- Si el comportamiento cambió, este spec cambió primero.

## 11. Privacidad, seguridad y tiendas

La app no tiene cuentas ni servidor, así que casi nada sale del teléfono; lo único que puede salir son métricas anónimas, y solo si la persona las acepta. Esta sección no es asesoría legal: confírmala con un abogado antes de publicar.

### Qué se guarda y qué sale del teléfono

| Dato | Dónde vive | ¿Sale del teléfono? |
| --- | --- | --- |
| Favoritos, historial y racha | `user.db` | No, salvo el respaldo automático de Android a la cuenta de Google de la persona, si lo tiene activo |
| Ajustes | `shared_preferences` | No, salvo el mismo respaldo |
| Texto del buscador y dedicatoria | Solo memoria | No |
| Eventos de uso (si acepta) | PostHog Cloud | Sí, sin contenido personal |
| `install_id` (UUID aleatorio) | `app_state` | Solo si acepta las métricas |

La app no pide correo, teléfono, ubicación, contactos ni micrófono.

### Métricas anónimas (opt-in)

- **Aviso propio**, una sola vez, a partir del tercer día de uso: "¿Nos ayudas a mejorar? Solo contamos cuántas veces se usa cada función. Nunca guardamos lo que lees, lo que escribes ni quién eres." con "Sí" y "No". El interruptor de Ajustes permite cambiar la decisión.
- **Sin consentimiento no se envía nada** y no se inicia el SDK de PostHog ni se crea `install_id`.
- **Eventos permitidos:** `app_open`, `feeling_selected` (slug del tema), `search_performed` (solo el tipo: referencia, tema o texto), `share_image` y `share_whatsapp` (con `verse_id`, `style_id` y si lleva dedicatoria, nunca su texto), `favorite_added` (con `verse_id`), `notification_enabled` (franja horaria), `daily_opened_from_notification`, `streak_milestone` y `tts_used`.
- **Retención** al día 1 y al día 7 se calcula con `app_open` y `install_id`. Quien no acepta solo aparece en los informes agregados de Google Play Console.
- **Marco legal de referencia:** la Ley 1581 de 2012 de protección de datos personales de Colombia. Aun con datos anónimos, la política de privacidad debe publicarse en `/privacidad` y declararse en las tiendas.

### Google Play

- **Política de privacidad:** URL pública obligatoria, la de `/privacidad`.
- **Seguridad de los datos:** declarar con exactitud lo anterior (sin datos si no hay métricas; datos anónimos de uso si las hay).
- **Público objetivo:** adultos; no se declara dirigida a niños.
- **Cuenta personal nueva:** Google puede exigir una prueba cerrada con un mínimo de personas durante un número de días antes de publicar; se confirma el requisito vigente al abrir la cuenta y se planifica en la fase 3.
- **Firma:** activar Play App Signing; la clave de subida se guarda fuera del repositorio, con una copia cifrada de respaldo.
- **Respaldo de datos:** `allowBackup` activo con reglas que incluyen `user.db` y los ajustes y excluyen `content.db`, que se reinstala con la app. Así, al cambiar de teléfono con la misma cuenta de Google, los guardados vuelven sin código adicional.

### Licencias y transparencia del contenido

- **Texto bíblico:** Reina-Valera 1909, dominio público; la fuente y la fecha de descarga quedan registradas y se muestran en Acerca de.
- **Licencias de código y fuentes:** la pantalla de licencias usa `showLicensePage`, con las licencias de las fuentes (OFL) registradas en `LicenseRegistry`.
- **Reflexiones y oraciones:** son obra propia, redactadas con un modelo de licencia abierta y revisadas una a una. Antes de publicar se confirma que la licencia del modelo permite uso comercial de sus salidas.
- **Transparencia:** cada reflexión lleva al pie una línea discreta, "Redactada con ayuda de inteligencia artificial y revisada por una persona", y Acerca de lo explica. No sustituye la guía pastoral ni la atención médica o psicológica.

## 12. Plan de entrega por fases

El MVP se construye en cuatro fases que suman entre 10 y 12 semanas de dedicación completa más 2 semanas de calendario de piloto (estimado inicial, sin fechas; con medio tiempo se duplica la dedicación), con una puerta de validación entre la fase 1 y la fase 2.

&#91;embedded content: hoja de ruta · 5 fases y 1 puerta de validación\]

Las fases 0 a 3 forman el MVP; la fase 4 no está comprometida y se define con los datos del piloto y de las métricas.

| Fase | Objetivo | Entregables | Criterio de salida | Estimado |
| --- | --- | --- | --- | --- |
| 0. Fundamentos | Probar lo técnico más riesgoso | Esqueleto Flutter, CI, copia de `content.db` al primer arranque, FTS5 funcionando, ingesta de la RV1909 y etiquetado de una muestra de 500 versículos | Pruebas de datos 1, 2, 9 y 10 en verde y APK de depuración corriendo en el dispositivo de referencia | 1.5 semanas |
| 1. Núcleo | Lo que se comparte | HU-01, 02, 04, 05, 06, 07 (solo versículo), 08, 09, 10 y 12; `content.db` completo con etiquetas, parecidos, momentos y calendario; web de enlaces publicada | Todos los criterios de esas historias con prueba en verde y mediciones dentro del objetivo | 4 semanas |
| Puerta de validación | Decidir si se invierte en reflexiones | Piloto con 20 personas durante 14 días | Umbrales propuestos: al menos el 30% comparte una tarjeta y al menos el 25% vuelve al día 7 | 2 semanas |
| 2. Reflexiones y hábito | El diferenciador | Pipeline de reflexiones, revisión del 100%, HU-03, HU-07 con reflexión, HU-11 y HU-13 | 685 reflexiones aprobadas, pruebas de datos 6 y 7 en verde y línea de ayuda verificada | 3 semanas |
| 3. Publicación | Salir a la tienda | Prueba de usabilidad, rendimiento, prueba cerrada, ficha de tienda, política de privacidad y lista final de comprobación | Al menos el 80% completa las cuatro tareas de la sección 8 sin ayuda y la versión firmada queda publicada | 2 a 3 semanas |
| 4. Después del MVP | Crecer | iOS, búsqueda por voz, enlaces de aplicación verificados, planes de lectura, otras traducciones con licencia, modelo local opcional | Se define con los datos de las métricas | Sin estimar |

La fase 2 puede arrancar en paralelo con el final de la fase 1 si el pipeline se prueba primero con el lote de 50 versículos de la sección 5, porque la generación y la revisión de las reflexiones dependen de tu tiempo y no del de la app.

### Ruta acelerada (propuesta, rev. 2)

Es una hipótesis para salir antes sin recortar el alcance; las semanas dependen de tu dedicación y se validan al cierre de cada fase.

1. **Cuatro frentes en paralelo desde ya:** (A) app, (B) pipeline de contenido, (C) web de enlaces `/v/` y (D) tienda y legal. Hoy solo avanza A.
2. **Camino crítico = contenido y tiempo humano, no la app:** ingesta de la RV1909, la prueba de calidad de 50 versículos y la revisión del 100% de las reflexiones (11 a 23 horas). Se arrancan ya, por lotes, mientras se construye la app.
3. **Unir el piloto y la prueba cerrada de Google Play:** la distribución a los 20 testers del piloto se hace como prueba cerrada en Play Console, de modo que los mismos 14 días sirvan de puerta de validación y de requisito de la tienda (si la cuenta lo exige). Ahorra de 2 a 3 semanas de la fase 3.
4. **La fase 2 corre durante esos 14 días:** el pipeline de reflexiones y su revisión no esperan al resultado de la puerta; si la puerta falla, lo ya revisado sigue siendo contenido válido para la web.
5. **Orden de construcción dentro de la fase 1 (por valor):** Compartir (HU-09, el motor de crecimiento) y Versículo del día con notificación (HU-07) antes que el pulido de Buscar y Ajustes.
6. **Hacer ahora lo que se encarece con el tiempo:** textos en archivos ARB (cada pantalla nueva añade textos fijos), `user.db` (favoritos, historial y racha hoy están en `shared_preferences`), tokens de diseño únicos y la versión de Flutter fijada con FVM.
7. **Estimado con ruta acelerada:** de 6 a 8 semanas hasta la publicación en lugar de 10 a 12, solo si los frentes A y B avanzan a la vez.

**Lista de comprobación previa a cada publicación:** puerta de calidad de CI en verde, línea de ayuda verificada con una fuente oficial, permisos del manifiesto revisados, política de privacidad vigente, `content_version` incrementado y notas de versión escritas.

## 13. Riesgos, métricas y decisiones pendientes

El mayor riesgo es la calidad de las reflexiones, y el más difícil de medir es si la gente comparte; por eso el plan incluye una revisión del 100% de las reflexiones y una puerta de validación antes de la fase 2.

### Métricas de éxito

| Métrica | Cómo se mide | Meta |
| --- | --- | --- |
| Personas que comparten | Quienes disparan `share_image` o `share_whatsapp` al menos una vez, entre las activas | Piloto: al menos el 30% |
| Retención al día 7 | Personas con `app_open` el día 7 entre las que aceptaron métricas | Piloto: al menos el 25% |
| Activación del versículo diario | `notification_enabled` entre las personas activas | Se fija tras el piloto |
| Instalaciones desde enlaces | Informe de adquisición de Google Play por `utm_source=share` | Se fija tras el piloto |
| Facilidad de uso | Prueba de usabilidad de la sección 8 | 80% sin ayuda y compartir en menos de 90 s |

Los umbrales del piloto son hipótesis para tomar la decisión de la puerta, no promesas de mercado.

### Riesgos

| Riesgo | Consecuencia | Mitigación |
| --- | --- | --- |
| Un modelo de 7B escribe reflexiones torpes o doctrinalmente dudosas | Texto que hay que reescribir o que se publica con errores | Prueba de calidad de 50 versículos, revisión del 100%, validaciones automáticas y paso a un modelo mayor si hace falta |
| El español de 1909 aleja a los jóvenes | Menor retención joven | La reflexión explica en lenguaje actual; una traducción moderna con licencia entra en la fase 4 |
| Ahorro de batería de algunos fabricantes bloquea las notificaciones | Hábito débil | Modo inexacto, ayuda en Ajustes y pruebas en varios teléfonos |
| Sin cuentas no se puede recuperar a quien deja de abrir la app | Retención baja | Versículo diario, racha suave y compartir como motor |
| La cuenta personal de Google Play exige una prueba cerrada | Retraso en publicar | Reclutar testers desde el piloto y planificarlo en la fase 3 |
| WhatsApp no recibe la imagen sin pasar por la hoja del sistema | Un toque más al compartir | Hoja del sistema con texto y enlace; evaluar código nativo después del MVP |
| Licencias de modelo, fuentes o texto | Problema legal | Auditoría de licencias en CI y registro de fuentes |
| Competencia de apps establecidas | Poca diferenciación | Diferenciarse por emociones, reflexión corta, tarjetas con dedicatoria y facilidad para mayores |
| Una persona en crisis usa la app | Daño a una persona | HU-13, lista de términos de crisis revisada, línea de ayuda verificada y ningún consejo médico |
| Rendimiento en teléfonos de gama baja | Mala experiencia | Dispositivo de referencia, mediciones en cada fase y consultas pesadas en un isolate |
| Tiempo de revisión de 11 a 23 horas | Retraso de la fase 2 | Revisar por lotes y en paralelo con el final de la fase 1 |
| Flutter 3.24 (julio de 2024) está desfasado y los plugins de la sección 3 piden versiones más nuevas; Gradle 9 ya rompió la compilación (rev. 2) | Plugins que no resuelven o bloquean la compilación | Subir a la estable vigente y fijarla con FVM (`.fvmrc`) antes de añadir share_plus, flutter_tts y flutter_local_notifications; mientras tanto, Gradle fijado en 8.7 |
| Textos fijos en los widgets en lugar de ARB (rev. 2) | Retrabajo creciente y la prueba de la sección 7 fallaría | Migrar a ARB ahora, con `flutter gen-l10n`, antes de seguir con pantallas |
| Sin pruebas de guías de accesibilidad ni golden (rev. 2) | Regresiones de contraste y de zonas táctiles | Añadir `androidTapTargetGuideline`, `labeledTapTargetGuideline`, `textContrastGuideline` y los golden de la sección 10 a cada pantalla nueva |

**Búsqueda por voz.** Queda fuera del MVP porque el reconocimiento de voz estándar de Android suele depender de servicios de Google y de conexión, lo que choca con el principio de funcionar sin internet y con código abierto. Una opción a evaluar en la fase 4 es Vosk, de licencia Apache-2.0 y con modelos en español que corren sin conexión.

### Nombre de la app: cinco propuestas

Se consultó el registro de marcas de la SIC (copia de Croma al 27 de octubre de 2026) por palabras del signo en las clases 9 (software), 41 (educación y entretenimiento) y 45 (servicios religiosos), y se probó si los dominios ya están en uso. Google Play no se pudo consultar de forma automática, así que falta buscar cada nombre allí a mano.

| Nombre | Qué evoca | Marcas SIC | Dominio | Riesgo |
| --- | --- | --- | --- | --- |
| Sosiego | Calma y paz del ánimo | Sin registros | sosiego.com está a la venta en GoDaddy; sosiego.app sin verificar | Bajo |
| Cobijo | Refugio y abrigo | Sin registros | cobijo.app ya lo usa un software hotelero para sitios de sus clientes | Medio, por el dominio |
| Lumbre | Fuego del hogar y calidez | Solo una solicitud en trámite, "Piedra Lumbre Films" (clases 35 y 41) | lumbre.co y lumbre.app sin verificar | Bajo a medio |
| Lámpara | El Salmo 119:105, "lámpara es a mis pies tu palabra" | Sin registros útiles; una solicitud de 1989 en clase 9, "OVNI - LAMPARA" | lampara.app ya existe | Medio |
| Pan de cada día | Lo cotidiano y el Padre Nuestro | Sin registros | Sin verificar; se parece a "Nuestro Pan Diario", un devocional conocido | Medio |

**Descartados:** Aliento (aliento.app es una app de meditaciones con IA para el mismo público), Candil (candil.app es una plataforma de acceso a edificios), Manantial (manantial.app es un sistema de gestión comercial y hay marcas "Manantial de Vida" en clase 41), Semilla (marca SEMILLA registrada en clase 41 hasta 2027 y muchas parecidas) y Rocío (rocio.app está registrado y existe la marca ROCÍO CORSON en clase 41).

La búsqueda en la SIC no sustituye el concepto de un abogado de propiedad industrial antes de registrar la marca.

### Nombre de la app: segunda ronda

El favorito actual es Sosiego. Esta ronda usa las mismas comprobaciones que la primera (SIC en clases 9, 41 y 45, y dominios .app).

| Nombre | Qué evoca | Marcas SIC | Dominio | Riesgo |
| --- | --- | --- | --- | --- |
| Reposo | El Salmo 23, "aguas de reposo" | Sin registros | reposo.app sin verificar | Bajo |
| Alivio | Descanso de una carga o un dolor | Sin registros del signo | alivio.app sin verificar | Bajo |
| Abrigo | Protección y calidez | Una marca registrada, "Un abrigo para ti" (clases 38 y 45) | abrigo.app sin verificar | Bajo a medio |
| Alborada | El amanecer, empezar el día con una palabra | Sin registros vigentes; solo dos caducados en clase 41 | alborada.app es una plataforma de administración de propiedades | Medio, por el dominio |
| Regazo | Ternura, el regazo de una madre | Sin registros | regazo.app redirige a una app para bebés | Medio, por el dominio |

**Descartados en esta ronda:** Remanso (remanso.app es una app de finanzas personales "en calma", en español y con el mismo tono) y Sereno (varias marcas registradas en clase 41).

### Decisiones pendientes

1. **Nombre de la app y dominio.** Afectan los enlaces `/v/`, la ficha de la tienda y la política de privacidad. Nombre elegido: Sosiego. Falta buscarlo a mano en Google Play, comprobar sosiego.app, sosiego.com y sosiego.co, y pedir el concepto de un abogado antes de registrar la marca en las clases 9, 41 y 45.
2. **Dispositivo de referencia.** Un Android de gama baja con 3 GB de RAM sobre el cual se miden todos los objetivos.
3. **Equipo y modelo del pipeline.** La memoria de tu GPU decide si Qwen2.5 7B alcanza o se pasa a uno mayor; se resuelve con la prueba de 50 versículos.
4. **Umbrales de la puerta de validación** (30% y 25%).
5. **Transparencia sobre la IA** en cada reflexión, como se propone en la sección 11.
6. **Android primero** confirmado (D7); iOS queda fuera hasta la fase 4.
7. **Herramienta de métricas:** decidida, PostHog Cloud (sección 3); falta crear el proyecto y desactivar el almacenamiento de IP.
8. **Fuente exacta de la RV1909** y su conteo de versículos.
9. **Línea de ayuda:** número nacional vigente, verificado con una fuente oficial.
10. **Versión de Flutter (rev. 2):** hoy el proyecto usa 3.24.0; decidir la estable vigente y fijarla con FVM antes de añadir plugins.
11. **Requisito de prueba cerrada de Google Play (rev. 2):** confirmar el número de testers y de días que exige la cuenta nueva, porque define si el piloto puede servir también como prueba cerrada (ruta acelerada, sección 12).

## 14. Revisión 2 (Oct 28, 2026)

Esta revisión contrasta el spec con la app construida (esqueleto de la fase 0 más las maquetas del feed, Explorar, Buscar, Guardados, reflexión, ajustes y primer arranque). El detalle pantalla por pantalla está en `docs/brecha-spec-vs-app.md`.

### Qué cambió en el spec

- Ambigüedades cerradas en HU-03, HU-04, HU-06, HU-10, HU-11 y HU-13 (marcadas «rev. 2»).
- Colores oscuros ajustados a la familia cálida y contrastes medidos (sección 8).
- Ruta acelerada (sección 12), tres riesgos nuevos (sección 13) y dos decisiones pendientes nuevas (10 y 11).
- No se tocó ninguna de las decisiones D1 a D7 ni el alcance del MVP.

### Decisiones de diseño propuestas (a confirmar)

| ID | Decisión | Por qué |
| --- | --- | --- |
| D8 | Un solo sistema de estilos (`CardStyle`, de 8 a 10) para el fondo del feed y la tarjeta compartida; el feed usa la variante clara u oscura según el tema y la tarjeta compartida usa la variante fija elegida | Coherencia visual, una sola prueba de contraste y menos código |
| D9 | Tokens únicos de diseño (espaciado de 4 dp, radios, duraciones, colores) en `core/theme`; ningún valor suelto en las pantallas | Cambiar el aspecto en un solo lugar y validar el contraste una vez |
| D10 | Inicio (emociones, momentos y versículo de hoy) es la pantalla de entrada; el feed vive en la pestaña Versículos | La promesa es «toca cómo te sientes»; el feed es para explorar |
| D11 | Favoritos, historial y racha viven en `user.db`, no en `shared_preferences` | Historial de 2000 entradas, migraciones y respaldo de Android con reglas |
| D12 | Toda acción visible lleva texto bajo el icono, también en el feed | Principio 2 y público de 60 años o más |

### Cierre de las dudas que dejó el diseño

1. Los momentos ya tienen `description` en el esquema; no se añade ninguna marca «delicado»: lo sensible se decide por reflexión con `sensitive`.
2. `sensitive` no oculta la reflexión; agrega el bloque de ayuda al final (HU-13.1 y 13.6).
3. Texto de la racha: ver HU-11.2, 11.3 y 11.5.
4. No hay búsquedas recientes (HU-06.10).
5. Deshacer restituye el favorito con su fecha y posición originales (HU-10.3).
6. El versículo del día usa la fecha local y `America/Bogota` como caso de prueba (HU-07.1, sección 10).
7. «Capítulo anterior/siguiente» queda para la fase 4 (HU-06.3).
