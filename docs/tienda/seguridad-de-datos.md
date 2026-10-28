# Seguridad de los datos (formulario Data Safety de Google Play)

Borrador técnico basado en la sección 11 del spec. **No es asesoría legal.** El formulario es una declaración que hace el desarrollador y debe coincidir con lo que la app hace de verdad; antes de enviarlo hay que contrastarlo con el manifiesto final, las dependencias reales (`pubspec.lock`) y el tráfico de red observado en un dispositivo. Los nombres de categorías y preguntas pueden haber cambiado: confirmarlos en Play Console, que es la fuente vigente.

Hay dos versiones porque la decisión de usar métricas (PostHog, opt-in) cambia la declaración. La versión «con métricas» es la que corresponde a la app tal como la describe el spec; la versión «sin métricas» aplica si se publica una primera versión sin el SDK.

## Qué hace la app (base común)

| Dato | Dónde vive | ¿Sale del teléfono? |
| --- | --- | --- |
| Favoritos, historial y racha | `user.db` | No, salvo respaldo de Android a la cuenta de Google de la persona |
| Ajustes | `shared_preferences` | No, salvo el mismo respaldo |
| Texto del buscador y dedicatoria | Solo memoria | No |
| Eventos de uso (solo si acepta) | PostHog Cloud | Sí, sin contenido personal |
| `install_id` (UUID aleatorio) | `app_state` | Solo si acepta las métricas |

No se piden correo, teléfono, ubicación, contactos ni micrófono. No hay cuentas, ni anuncios, ni compras.

## Versión A: sin métricas

| Pregunta del formulario | Respuesta | Justificación |
| --- | --- | --- |
| ¿La app recopila o comparte alguno de los tipos de datos requeridos? | **No** | Todo se guarda en el teléfono y no se envía a ningún servidor. Los datos procesados solo en el dispositivo no se consideran «recopilados» |
| ¿Datos cifrados en tránsito? | No aplica (no hay tránsito) | No se declara tráfico de datos de usuario |
| ¿Puede el usuario pedir que se borren sus datos? | No aplica | Se borran al desinstalar la app; no hay copia en un servidor del desarrollador |
| Política de privacidad | URL de `/privacidad` | Obligatoria igualmente |
| Respaldo automático de Android | Se explica en la política; **confirmar en la ayuda de Play si exige declaración** | La copia va a la cuenta de Google de la persona, gestionada por Google y no por el desarrollador. Verificar el criterio vigente en la ayuda de Play antes de enviar |

Condición: la app no debe incluir ningún SDK que envíe datos (ni analítica, ni publicidad, ni informes de fallos de terceros). Android vitals de Play Console no añade SDK a la app.

## Versión B: con métricas anónimas opt-in (PostHog)

Solo hay recopilación si la persona dice «Sí» al aviso propio (a partir del tercer día). Sin consentimiento no se inicia el SDK, no se crea `install_id` y no se envía nada.

| Pregunta del formulario | Respuesta | Justificación |
| --- | --- | --- |
| ¿Recopila datos? | **Sí** | Eventos de uso e identificador anónimo, solo con consentimiento |
| ¿Comparte datos con terceros? | **No**, si PostHog actúa solo como proveedor de servicios en nombre del desarrollador | Google excluye de «compartir» la transferencia a proveedores que procesan datos en nombre del desarrollador. Confirmar el texto vigente de la política y el contrato de PostHog |
| Tipo: **Actividad en la app → Interacciones con la app** | Recopilado, **opcional** | `app_open`, `feeling_selected`, `search_performed` (solo el tipo), `share_image`, `share_whatsapp`, `favorite_added`, `notification_enabled`, `daily_opened_from_notification`, `streak_milestone`, `tts_used` |
| Tipo: **Identificadores de dispositivo u otros → ID de dispositivo u otros ID** | Recopilado, **opcional** | `install_id`: UUID aleatorio generado por la app, no el ID de publicidad ni el ID de Android |
| Tipo: **Actividad en la app → Consultas de búsqueda** | **No** se declara como contenido | Solo se envía el tipo de búsqueda (referencia, tema o texto), nunca lo escrito. Si en el futuro se enviara el texto, cambia la respuesta |
| Tipo: **Ubicación aproximada** | **Pendiente de confirmar** | PostHog puede derivar ubicación de la IP. La decisión 7 del spec dice que falta crear el proyecto y desactivar el almacenamiento de IP. Si no se desactiva, hay que declarar ubicación aproximada |
| Información personal (nombre, correo, teléfono), ubicación precisa, contactos, mensajes, fotos, audio, salud | **No** | La app no los pide ni los lee. La dedicatoria vive solo en memoria y no se envía (en el evento solo viaja «lleva dedicatoria: sí/no») |
| Finalidad de los datos recopilados | **Analítica** | Retención al día 1 y 7 y número de compartidos |
| ¿Es obligatorio o opcional? | **Opcional** | El usuario puede decir «No» y cambiarlo en Ajustes |
| ¿Cifrado en tránsito? | **Sí** | PostHog Cloud se usa por HTTPS. Verificar con una captura de tráfico que no hay peticiones HTTP |
| ¿Puede el usuario pedir que se borren sus datos? | **Sí**, por correo | Requiere el correo de contacto (pendiente) y un procedimiento. Ojo: sin mostrar `install_id` en la app, no se puede localizar a una persona; decidir si Ajustes lo muestra |
| Política de privacidad | URL de `/privacidad` | Debe describir exactamente lo anterior |

### Coherencia con la política de privacidad

La política en `web/templates/privacy.html` ya refleja la tabla del spec. Cada vez que cambie el conjunto de eventos o el proveedor, actualizar a la vez: la lista de eventos de la política, esta declaración y el código.

### Lista de verificación antes de enviar el formulario

- [ ] Revisar `pubspec.lock`: ningún SDK de Firebase, publicidad ni rastreadores (regla de dependencias, spec sección 3).
- [ ] Revisar el manifiesto: permisos mínimos (notificaciones, y alarmas exactas solo si se usan).
- [ ] Capturar el tráfico de red con consentimiento denegado: debe ser cero peticiones a PostHog.
- [ ] Capturar el tráfico con consentimiento aceptado: solo los eventos permitidos, sin textos del usuario.
- [ ] Confirmar la configuración de PostHog (IP, región) y actualizar la fila de ubicación aproximada.
- [ ] Confirmar el criterio de Play sobre el respaldo automático de Android.
- [ ] Que el responsable legal y el correo estén completos en la política.
