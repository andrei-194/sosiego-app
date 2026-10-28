# Lista de publicación en Google Play

Basada en las secciones 11 y 12 del spec. Los requisitos y las medidas de Play cambian: lo que aquí se escribe es un punto de partida y **lo vigente es lo que muestra Play Console y su ayuda oficial**. Este documento no es asesoría legal.

Leyenda de responsable: **usuario** (tú, con tu cuenta o decisión), **agente** (lo puede producir un agente de código), **ambos**. Estado: Pendiente, En curso, Borrador listo, Hecho.

## 1. Cuenta y firma

| Ítem | Responsable | Estado | Notas |
| --- | --- | --- | --- |
| Crear la cuenta de desarrollador de Google Play (pago único; el spec estima unos USD 25, confirmar el vigente) | usuario | Pendiente | Elegir tipo de cuenta (personal u organización); condiciona los requisitos de prueba |
| Verificación de identidad de la cuenta | usuario | Pendiente | Puede pedir documentos; no los maneja ningún agente |
| Activar Play App Signing al crear la app | usuario | Pendiente | Spec sección 11 |
| Crear la clave de subida (upload key) y guardarla **fuera del repositorio**, con copia cifrada de respaldo en otro lugar | usuario | Pendiente | Las contraseñas del keystore no deben compartirse con ningún agente ni ponerse en CI como texto plano |
| Configurar la firma del AAB de release con la clave de subida (`key.properties` local, ignorado por git) | ambos | Pendiente | El agente prepara el `build.gradle`; el usuario guarda los secretos |
| Subir un AAB (no APK) firmado | ambos | Pendiente | `applicationId` actual: `app.sosiego.sosiego` |

## 2. Prueba cerrada

| Ítem | Responsable | Estado | Notas |
| --- | --- | --- | --- |
| **Confirmar en Play Console el requisito vigente de prueba cerrada** (número de testers y de días, si aplica a esta cuenta) | usuario | Pendiente | No se afirma ninguna cifra aquí: el spec (decisión pendiente 11) lo deja por confirmar al abrir la cuenta |
| Decidir si el piloto de 20 personas por 14 días puede servir también de prueba cerrada | usuario | Pendiente | Ruta acelerada, spec sección 12; solo si el requisito confirmado lo permite |
| Reclutar testers y agregarlos por lista de correo o grupo | usuario | Pendiente | Los correos de los testers son datos de otras personas: tratarlos con cuidado |
| Subir el AAB al canal de prueba cerrada y compartir el enlace de adhesión | usuario | Pendiente | |
| Recoger comentarios y corregir | ambos | Pendiente | |
| Solicitar acceso a producción cuando la consola lo permita | usuario | Pendiente | |

## 3. Assets gráficos

Medidas habituales de Play (verificar en la consola al subirlos):

| Asset | Medidas y formato | Quién lo produce | Estado | Notas |
| --- | --- | --- | --- | --- |
| Icono de la app | 512 × 512 px, PNG | usuario con apoyo de agente (diseño) | Pendiente | Coherente con la marca cálida (#8A4B08 sobre #FBF7F0). Sin fotografías |
| Gráfico de funciones (feature graphic) | 1024 × 500 px, PNG o JPEG | agente puede generarlo (como `web/assets/og.png`) | Pendiente | Texto breve, sin promesas médicas. Dejar márgenes seguros |
| Capturas de teléfono | Mínimo 2; relación y tamaño según los límites de la consola (suele aceptar 16:9 o 9:16) | agente prepara; usuario las toma del dispositivo real | Pendiente | Tomar con datos reales, en claro y oscuro; incluir Inicio, Versículo, Compartir, Buscar |
| Capturas de tablet de 7 y 10 pulgadas | Solo si se declara compatibilidad con tabletas y la consola las pide | usuario | Pendiente | Decidir si se limita a teléfonos |
| Vídeo promocional (opcional) | URL de YouTube | usuario | No requerido | Fuera del MVP |
| Ficha de texto (título, descripción corta y larga) | Texto | agente | Borrador listo | `docs/tienda/ficha-google-play.md`; elegir variante de descripción corta |

## 4. Política de privacidad y declaraciones

| Ítem | Responsable | Estado | Notas |
| --- | --- | --- | --- |
| Política de privacidad en una URL pública (`/privacidad`) | ambos | Borrador listo | `web/templates/privacy.html`. **Antes de publicar:** completar responsable del tratamiento, correo y fecha; revisión de un abogado (Ley 1581 de 2012); `python build.py --strict` debe pasar |
| Hospedar la web con el dominio definitivo (o la URL provisional de GitHub Pages) y poner esa URL en Play Console | usuario | Pendiente | Workflow `.github/workflows/web.yml`; el despliegue está desactivado hasta decidirlo |
| Formulario Seguridad de los datos | ambos | Borrador listo | `docs/tienda/seguridad-de-datos.md`, versión con o sin métricas según lo que lleve el APK |
| Declaración de anuncios: la app no contiene anuncios | usuario | Pendiente | |
| Declaración de acceso a la app: no requiere inicio de sesión | usuario | Pendiente | |
| Declaración de permisos sensibles (si se usan alarmas exactas para la notificación diaria) | ambos | Pendiente | Revisar el manifiesto final; spec: «permisos del manifiesto revisados» |
| Cumplimiento de los requisitos de la app para la versión de Android objetivo vigente | agente | Pendiente | Comprobar el `targetSdk` exigido por Play en la fecha de subida |

## 5. Clasificación y público objetivo

| Ítem | Responsable | Estado | Notas |
| --- | --- | --- | --- |
| Cuestionario de clasificación de contenido (IARC) | usuario | Pendiente | Responder con exactitud: contenido religioso, sin violencia propia ni compras. Lo hace el titular de la cuenta |
| Público objetivo: **adultos**; no declarar la app como dirigida a niños | usuario | Pendiente | Spec sección 11 |
| Categoría de la app | usuario | Pendiente | Ver propuesta en `ficha-google-play.md` |
| Datos de contacto de la ficha (correo y, opcional, web) | usuario | Pendiente | Mismo correo que la política de privacidad; **no inventar** |

## 6. Nombre, dominio y marca

| Ítem | Responsable | Estado | Notas |
| --- | --- | --- | --- |
| Buscar «Sosiego» a mano en Google Play (no se pudo consultar de forma automática) | usuario | Pendiente | Spec sección 13 |
| Comprobar a mano sosiego.app, sosiego.com y sosiego.co | usuario | Pendiente | El spec solo indica que sosiego.com está a la venta en GoDaddy y que sosiego.app no está verificado; sosiego.co tampoco |
| Registrar el dominio elegido | usuario | Pendiente | Costo del spec: unos USD 10 a 15 al año (confirmar) |
| Concepto de un abogado de propiedad industrial antes de registrar la marca en las clases 9, 41 y 45 | usuario | Pendiente | La búsqueda en la SIC del spec no lo sustituye |
| Fijar `SITE_URL` y `BASE_PATH` del workflow web y la URL de la ficha | agente | Pendiente | Depende del dominio |

## 7. Contenido sensible y línea de ayuda

| Ítem | Responsable | Estado | Notas |
| --- | --- | --- | --- |
| Verificar el número de la línea de ayuda de salud mental vigente en Colombia **con una fuente oficial** (entidad pública competente) y anotar la fuente y la fecha | usuario | Pendiente | Spec sección 12: es parte del criterio de salida de la fase 2 y de la lista previa a cada publicación. No se escribe ningún número en la app ni en la ficha sin esa verificación |
| Revisar la lista de términos de crisis con una persona con formación en salud mental (si es posible) | usuario | Pendiente | HU-13 |
| Confirmar que la licencia del modelo que redactó las reflexiones permite uso comercial de sus salidas | usuario | Pendiente | Spec sección 11 |
| Línea de transparencia sobre IA en cada reflexión y en Acerca de | agente | Pendiente | Spec sección 11 |

## 8. Revisión previa a cada publicación (spec sección 12)

- [ ] Puerta de calidad de CI en verde.
- [ ] Línea de ayuda verificada con una fuente oficial.
- [ ] Permisos del manifiesto revisados.
- [ ] Política de privacidad vigente y sin campos [PENDIENTE].
- [ ] `content_version` incrementado.
- [ ] Notas de versión escritas.
- [ ] Auditoría de licencias (código, fuentes, texto bíblico, modelo) en verde.
- [ ] Prueba de usabilidad: al menos el 80% completa las cuatro tareas sin ayuda y compartir tarda menos de 90 segundos.
- [ ] Declaración de Seguridad de los datos coincide con el tráfico observado.

## Decisiones que solo puede tomar el usuario

1. Dominio y nombre definitivos (y dónde se aloja la web).
2. Responsable del tratamiento de datos y correo de contacto (campos pendientes en la política).
3. Si la primera versión incluye métricas con PostHog o sale sin ellas (define la versión del formulario de datos).
4. Tipo de cuenta de Google Play y, con ello, el requisito real de prueba cerrada.
