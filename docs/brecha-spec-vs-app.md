# Brecha entre el spec (rev. 2) y la app construida

Fecha: 28 de octubre de 2026. Estado medido: `flutter analyze --fatal-infos` limpio, `dart format` sin cambios, 55 pruebas en verde.
Veredicto por fila: **Mantener** (lo construido es mejor o igual), **Adoptar spec** (la app debe cambiar) o **Falta** (no existe aún).

## 1. Mantener (decisiones de diseño que se quedan)

| Qué | Por qué se queda |
| --- | --- |
| Degradado cálido, comilla decorativa, referencia en cursiva con raya | Cumple «solo gradientes y texturas, sin fotos» y da identidad |
| Fundido con ascenso suave entre versículos | Fluido; ajustar la duración a 260 ms (spec: 250 a 300) |
| Barra inferior fundida con el fondo, 4 pestañas con texto | Cumple la regla de navegación |
| Reflexión: Lora 20 con interlineado 1.75, ancho máximo 600, oración en bloque aparte | Lectura cómoda; se amplía a 4 bloques |
| Racha con icono de hoja y tono sin presión | Coincide con HU-11; solo cambian los textos |
| Ajustes en filas verticales con vista previa «Aa» | No desborda al 200% y el spec no lo prohíbe |
| Deshacer en aviso flotante | Coincide con HU-10.3 |
| Tokens `Gap` y `AppRadius`, respeto de reducir animaciones, prueba de 12 rutas al 200% | Base de D9 |

## 2. Adoptar spec (la app diverge)

| # | Spec | Hoy | Acción |
| --- | --- | --- | --- |
| 1 | Pestañas Inicio, Versículos, Buscar, Guardados; Inicio = emociones, momentos, versículo de hoy (D10) | Inicio = feed; «Explorar» hace de Inicio del spec | Renombrar Explorar a Inicio, ponerlo primero y mover el feed a Versículos |
| 2 | Primer arranque: una pantalla «¿Cómo prefieres leer?» con 3 tamaños y muestra real; preselección según el sistema (HU-01) | 3 pantallas de promesas | Reemplazar; es el único ajuste del arranque |
| 3 | Feed con botones Anterior y Siguiente de 56 dp; Guardar, Compartir, Escuchar y Más como este con texto bajo el icono (HU-04, D12) | Solo íconos con tooltip; sin Anterior/Siguiente; pista «Desliza» solo en la primera tarjeta y se oculta con letra de 1.6 o más | Añadir barra de acciones con texto; ayuda en las 3 primeras páginas, adaptada a la escala |
| 4 | Fondos: 8 a 10 estilos según `verse_id`, 7:1 (HU-04.5, D8) | 1 degradado | Crear `CardStyle` con variante clara y oscura y prueba de contraste |
| 5 | Reflexión: Contexto, Reflexión, Aplicación y Oración con encabezado; sin título; HU-13 al final | Título propio, cuerpo y oración; aviso previo que oculta el cuerpo | Reestructurar a 4 bloques; quitar el aviso previo; bloque de ayuda con `tel:` |
| 6 | Más como este: feed con 10 similares, etiqueta «Parecidos a … · Salir» y tarjeta final (HU-05) | Lista en el detalle | Feed en modo tema |
| 7 | Tocar emoción o momento abre el feed en modo tema con «Tema: … · Salir» (HU-02, sección 4) | Pantalla de lista aparte | Reutilizar el feed en modo tema |
| 8 | 10 emociones y 12 momentos; chips de 56 dp; «¿Cómo te sientes hoy?» | 8 temas de muestra en tarjetas; momentos de muestra | Cambiar la muestra a la taxonomía del spec y a chips |
| 9 | Buscador: referencia, luego tema o momento, luego texto; 250 ms de espera; 30 resultados; palabra resaltada; `bm25` (HU-06) | Referencia y texto, sin espera, hasta 50, sin resaltado, sin atajo a tema | Completar el orden de resolución y el resaltado |
| 10 | Guardados con vistas «Guardados» y «Vistos» (últimos 100), «Enviarme mis guardados», aviso «viven solo en este teléfono», botón «Ir a versículos», aviso de 5 s (HU-10) | Solo lista de favoritos; sin historial; aviso sin botón de acción visible equivalente al deslizar | Completar; el deslizar queda como atajo, no como única vía |
| 11 | Racha: «Llevas N días contigo» (N de 2 o más); «Hoy es un buen día para empezar»; tarjetas en 7, 30 y 100 (HU-11) | «Primer día» o «N días»; sin tarjetas | Cambiar textos; reutilizar la hoja de compartir |
| 12 | Ajustes completos: letra, tema (Automático), versículo diario, velocidad de voz, ayuda de notificaciones, enviar guardados, privacidad, acerca de, comentarios (HU-12) | Letra, tema («Como el teléfono») y acerca de | Completar a medida que existan las funciones |
| 13 | `user.db` para favoritos, historial y racha (D11) | `shared_preferences` | Crear `user.db` con migraciones y migrar |
| 14 | Acento claro `#8A4B08`: 6.4:1 sobre el fondo | `#8A5A2B`: 5.5:1, 4.8:1 sobre el extremo oscuro del degradado | Cambiar el token |
| 15 | Radios de 16 dp (sección 8) | 20 y 28 dp | Decidir: el radio mayor se ve más amable; si se conserva, actualizar el spec a 20/28 |
| 16 | Esquema de `content.db` de la sección 6 | `schema_content.sql` es el de la fase 0: `themes.id` de texto, `moments` solo con `label`, `books` sin `osis`, `slug` ni `aliases`, `reflections` con `title` y `body`, `chapters` con `verse_count` | Actualizar el esquema, el generador de muestra y `ContentRepository` |
| 17 | Tamaño base del versículo 22 sp (sección 8) | 26 sp fijo, multiplicado además por la escala | Alinear con la tabla del spec o actualizar la tabla; decidir en la prueba de usabilidad |

## 3. Falta (no existe)

| Funcionalidad | Dependencias del spec |
| --- | --- |
| Compartir tarjeta 9:16, hoja con estilos, «Para:», WhatsApp (HU-09) | `share_plus`, `url_launcher`, `RepaintBoundary` |
| Escuchar (HU-08) | `flutter_tts` |
| Versículo del día con notificación y tarjeta de permiso (HU-07) | `flutter_local_notifications`, `timezone` |
| Historial con registro a los 2 s | `user.db` |
| Aviso y envío de métricas con consentimiento | `posthog_flutter` |
| Privacidad, licencias, comentarios por correo | `showLicensePage`, `mailto:` |
| Textos en ARB y prueba que falla con textos fijos | `flutter gen-l10n` |
| Reglas de respaldo de Android (`allowBackup` con `user.db`) y permisos del manifiesto | Manifiesto y `backup_rules.xml` |
| Pruebas de guías de accesibilidad y golden; `tools/trace.py` y nombres de prueba con el ID de la historia | `flutter_test` |
| FVM y versión de Flutter vigente (`.fvmrc`) | Hoy 3.24.0 y Gradle fijado en 8.7 |
| Pipeline de contenido real y `content.db` completo; web `/v/` | Python, Ollama, Jinja2 |

## 4. Orden recomendado de construcción

1. Base: subir y fijar Flutter, ARB, `user.db`, `CardStyle` y tokens (todo lo que se encarece con cada pantalla nueva).
2. Reestructura de navegación (puntos 1, 2, 3, 6 y 7 de la sección 2).
3. Compartir (HU-09) y versículo del día con notificación (HU-07).
4. Escuchar, Guardados completo, racha y Ajustes.
5. Esquema de datos y reflexión de 4 bloques cuando exista el primer lote del pipeline.
