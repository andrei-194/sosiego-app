# Entorno de desarrollo: dónde vive cada cosa

Regla: **todo el trabajo y todas las cachés pesadas viven en el disco D:**. C: queda para el sistema.

## Ubicación final declarada

| Qué | Ubicación final | Variable (usuario) | Estado |
| --- | --- | --- | --- |
| Proyecto | `D:\projects\apps android\sosiego-fase0\sosiego` | | En D: |
| Salidas de compilación | `…\sosiego\build` | | En D: |
| Caché de Gradle (12,5 GB) | `D:\dev\caches\gradle` | `GRADLE_USER_HOME` | **Movida** (28 oct 2026). La carpeta vieja `C:\Users\andre\.gradle` quedó casi vacía (2 archivos en uso) |
| Emulador (AVD `sosiego_pixel`, 6 GB) | `D:\dev\caches\android-avd` | `ANDROID_AVD_HOME` | **Movida**; `C:\Users\andre\.android\avd` es una junction a D: |
| Caché de pub (0,3 GB) | queda en `C:\Users\andre\AppData\Local\Pub\Cache` | | No se mueve: pesa poco y VS Code la tiene en uso; `package_config.json` guarda rutas absolutas |
| Caché de FVM (1,5 GB) | queda en `C:\Users\andre\fvm` | | No se mueve: pesa poco, la usa el servidor de Dart de VS Code y `.fvm\flutter_sdk` apunta ahí |
| Capturas y temporales de trabajo | `D:\tmp` | | En D: |

Pendiente de decidir aparte: el Android SDK (`C:\Users\andre\Android\Sdk`) y el Flutter global 3.24 (`C:\Users\andre\flutter`). No se mueven con este script porque cambian `ANDROID_HOME` y el PATH de otros proyectos.

## Cómo se mueve

`scripts/mover-caches-a-d.ps1` (simulacro por defecto; `-Ejecutar` para mover). Copia con robocopy, verifica el conteo de archivos, borra el origen, deja una junction en la ruta vieja y fija la variable de usuario. Las rutas absolutas existentes siguen funcionando por la junction.

Se ejecuta cuando no haya compilaciones en curso (agentes terminados) o si C: baja de unos 1,5 GB libres.

**Qué pasó al ejecutarlo:** el avd se movió con la junction. En `.gradle` el renombrado de la carpeta raíz fue denegado por Windows (sin proceso identificable), así que se aplicó la alternativa: copia verificada (114.628 archivos y 12,53 GB idénticos), variable `GRADLE_USER_HOME` apuntando a D: y borrado del contenido viejo. Lo mismo vale si hay que repetirlo.
Verificado después: `fvm flutter build apk --debug` compila y C: no vuelve a consumir espacio. C: pasó de 12,5 a 30,7 GB libres.
Las variables de usuario aplican a sesiones nuevas: cierra y reabre terminales e IDE.

## Verificación posterior

1. `fvm flutter doctor` y `fvm flutter pub get` en el proyecto.
2. `fvm flutter build apk --debug` y arrancar el emulador `sosiego_pixel`.
3. Confirmar que C: recuperó espacio.
