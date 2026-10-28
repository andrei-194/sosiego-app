# Entorno de desarrollo: dónde vive cada cosa

Regla: **todo el trabajo y todas las cachés pesadas viven en el disco D:**. C: queda para el sistema.

## Ubicación final declarada

| Qué | Ubicación final | Variable (usuario) | Estado |
| --- | --- | --- | --- |
| Proyecto | `D:\projects\apps android\sosiego-fase0\sosiego` | | En D: |
| Salidas de compilación | `…\sosiego\build` | | En D: |
| Caché de pub | `D:\dev\caches\pub` | `PUB_CACHE` | Pendiente de mover |
| Caché de Gradle | `D:\dev\caches\gradle` | `GRADLE_USER_HOME` | Pendiente de mover |
| Caché de FVM (Flutter 3.47.8) | `D:\dev\caches\fvm` | `FVM_CACHE_PATH` | Pendiente de mover |
| Emulador (AVD `sosiego_pixel`) | `D:\dev\caches\android-avd` | `ANDROID_AVD_HOME` | Pendiente de mover |
| Capturas y temporales de trabajo | `D:\tmp` | | En D: |

Pendiente de decidir aparte: el Android SDK (`C:\Users\andre\Android\Sdk`) y el Flutter global 3.24 (`C:\Users\andre\flutter`). No se mueven con este script porque cambian `ANDROID_HOME` y el PATH de otros proyectos.

## Cómo se mueve

`scripts/mover-caches-a-d.ps1` (simulacro por defecto; `-Ejecutar` para mover). Copia con robocopy, verifica el conteo de archivos, borra el origen, deja una junction en la ruta vieja y fija la variable de usuario. Las rutas absolutas existentes siguen funcionando por la junction.

Se ejecuta cuando no haya compilaciones en curso (agentes terminados) o si C: baja de unos 1,5 GB libres.

## Verificación posterior

1. `fvm flutter doctor` y `fvm flutter pub get` en el proyecto.
2. `fvm flutter build apk --debug` y arrancar el emulador `sosiego_pixel`.
3. Confirmar que C: recuperó espacio.
