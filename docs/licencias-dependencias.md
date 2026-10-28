# Licencias de dependencias (app Flutter)

Fecha: 28 de octubre de 2026. Regla del spec (§3): licencia permisiva (MIT, BSD o Apache-2.0), mantenimiento activo y ningún SDK de Firebase ni rastreadores. La licencia se leyó del archivo `LICENSE` de cada paquete en la caché de pub (no de la ficha de pub.dev).

## Dependencias directas

| Paquete | Versión | Licencia | Notas |
| --- | --- | --- | --- |
| flutter, flutter_localizations | SDK 3.47.8 | BSD-3 | |
| flutter_riverpod | 2.6.1 | MIT | Se queda en 2.x: 3.x cambia `StateNotifier` |
| go_router | 18.1.1 | BSD-3 | |
| sqlite3 | 2.9.4 | MIT | SQLite propio con FTS5; el SQLite es de dominio público |
| sqlite3_flutter_libs | 0.5.42 | MIT | La 0.6 está marcada «eol»; se queda en 0.5.x |
| path | 1.9.1 | BSD-3 | |
| path_provider | 2.1.5 | BSD-3 | |
| shared_preferences | 2.5.3 | BSD-3 | |
| intl | 0.20.x | BSD-3 | Lo fija `flutter_localizations` |
| **share_plus** | 13.3.1 | BSD-3 | Hoja de compartir del sistema |
| **url_launcher** | 6.3.3 | BSD-3 | `wa.me`, `tel:`, `mailto:` |
| **flutter_tts** | 4.2.5 | MIT | Usa el motor de voz del sistema |
| **flutter_local_notifications** | 22.3.3 | BSD-3 | Exige desugaring de Java (ver abajo) |
| **timezone** | 0.11.2 | BSD-2 | Base de zonas horarias incluida en el paquete |
| flutter_lints (dev) | 6.0.0 | BSD-3 | |
| mocktail (dev) | 1.0.5 | MIT | |
| flutter_test, integration_test (dev) | SDK | BSD-3 | |

## Dependencias transitivas nuevas (por los cinco paquetes)

`flutter_local_notifications_platform_interface`, `_linux`, `_windows`, `_web` (BSD-3), `share_plus_platform_interface` (BSD-3), `url_launcher_*` (BSD-3), `http`, `http_parser`, `mime`, `fixnum` (BSD-3), `uuid` (MIT), `xml`, `petitparser` (MIT), `win32`, `ffi_leak_tracker` (BSD-3). Todas permisivas. Las plataformas de escritorio y web no entran en el APK de Android.

## Verificación de rastreadores

- `pubspec.lock` no contiene Firebase, Google Analytics, Crashlytics, Sentry, PostHog ni ningún paquete de analítica.
- Ninguno de los cinco paquetes declara el permiso INTERNET. `http` llega como dependencia de `share_plus` (para compartir archivos desde URL) y la app no la usa.
- `share_plus` añade en su manifiesto un `FileProvider` (`dev.fluttercommunity.plus.share`) y un receptor interno, no exportados. No son permisos.

## Permisos y requisitos de Android que traen

| Paquete | Qué exige | Decisión |
| --- | --- | --- |
| flutter_local_notifications | Permisos `POST_NOTIFICATIONS` y `VIBRATE` (ya en el spec); receptores `ScheduledNotificationReceiver` y `ScheduledNotificationBootReceiver` en el manifiesto; `compileSdk` 35 o más; **desugaring** (`coreLibraryDesugaring` con `desugar_jdk_libs` 2.1.4) | Se declaran los receptores y se activa el desugaring en `android/app/build.gradle.kts`. No se usan alarmas exactas: no se pide `SCHEDULE_EXACT_ALARM` (spec HU-07.5) |
| flutter_tts | Ninguno | Sin cambios |
| share_plus | Ninguno (FileProvider propio) | Sin cambios |
| url_launcher | Declarar `<queries>` para `https`, `tel` y `mailto` (visibilidad de paquetes, no es un permiso) | Añadido al manifiesto |
| timezone | Ninguno | Sin cambios |

`minSdk` queda en 26 (spec §7); ninguno de los plugins exige más (flutter_local_notifications pide 24).

## Auditoría automática

`scripts/check_manifest.py` falla en CI si el manifiesto principal o el fusionado de release declara un permiso fuera de la lista del spec. El manifiesto de debug lleva INTERNET que añade Flutter para depurar; no se empaqueta en release.
