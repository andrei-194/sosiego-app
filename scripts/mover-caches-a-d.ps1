<#
Mueve las cachés de herramientas de C: a D: y las declara de forma permanente.

Uso:
  .\scripts\mover-caches-a-d.ps1             simulacro: no cambia nada, solo informa
  .\scripts\mover-caches-a-d.ps1 -Ejecutar   mueve, deja una junction en la ruta vieja y fija variables de usuario

Cómo funciona: copia con robocopy, verifica que el número de archivos coincida, borra
el origen y crea una junction (C:\ruta\vieja -> D:\dev\caches\...). Así las rutas
absolutas ya escritas (fvm.bat, .fvm\flutter_sdk, los .ini del emulador) siguen valiendo.
Además fija la variable de entorno oficial de cada herramienta para que los procesos
nuevos escriban directamente en D:.

Hay que ejecutarlo sin flutter, dart, java, adb ni el emulador corriendo (-Forzar lo omite).
Las variables de usuario aplican a sesiones nuevas: cierra y vuelve a abrir terminales e IDE.
#>
param(
    [switch]$Ejecutar,
    [switch]$Forzar,
    [string]$Destino = 'D:\dev\caches'
)

$ErrorActionPreference = 'Stop'
$perfil = $env:USERPROFILE

$items = @(
    @{ Nombre = 'pub';         Origen = "$env:LOCALAPPDATA\Pub\Cache"; Dest = "$Destino\pub";         Var = 'PUB_CACHE' },
    @{ Nombre = 'gradle';      Origen = "$perfil\.gradle";             Dest = "$Destino\gradle";      Var = 'GRADLE_USER_HOME' },
    @{ Nombre = 'fvm';         Origen = "$perfil\fvm";                 Dest = "$Destino\fvm";         Var = 'FVM_CACHE_PATH' },
    @{ Nombre = 'android-avd'; Origen = "$perfil\.android\avd";        Dest = "$Destino\android-avd"; Var = 'ANDROID_AVD_HOME' }
)

function Escribir($m) { Write-Host "[mover-caches] $m" }

$libreC = [math]::Round((Get-PSDrive C).Free / 1GB, 1)
$libreD = [math]::Round((Get-PSDrive D).Free / 1GB, 1)
Escribir "Libre en C: $libreC GB | libre en D: $libreD GB | destino: $Destino"
if (-not $Ejecutar) { Escribir 'SIMULACRO: no se cambia nada (usa -Ejecutar para mover).' }

if ($Ejecutar -and -not $Forzar) {
    $busy = Get-Process -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '^(flutter|dart|java|adb|emulator|qemu-system.*|gradle.*)$' }
    if ($busy) {
        $lista = ($busy | Select-Object -ExpandProperty Name -Unique) -join ', '
        throw "Hay procesos en uso ($lista). Ciérralos o usa -Forzar."
    }
}

foreach ($it in $items) {
    $o = $it.Origen; $d = $it.Dest
    if (-not (Test-Path $o)) { Escribir "$($it.Nombre): no existe $o, se omite"; continue }
    if ((Get-Item $o -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) {
        Escribir "$($it.Nombre): $o ya es una junction, se omite"; continue
    }
    Escribir "$($it.Nombre): $o -> $d (variable $($it.Var))"
    if (-not $Ejecutar) { continue }

    New-Item -ItemType Directory -Force -Path $d | Out-Null
    robocopy $o $d /E /COPY:DAT /R:2 /W:2 /NFL /NDL /NP /NJH /NJS | Out-Null
    if ($LASTEXITCODE -ge 8) { throw "robocopy falló en $($it.Nombre) (código $LASTEXITCODE); el origen sigue intacto" }

    $nOrigen = (Get-ChildItem $o -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object).Count
    $nDest   = (Get-ChildItem $d -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object).Count
    if ($nDest -lt $nOrigen) { throw "$($it.Nombre): copia incompleta ($nDest de $nOrigen archivos); el origen sigue intacto" }

    Remove-Item $o -Recurse -Force
    New-Item -ItemType Junction -Path $o -Target $d | Out-Null
    [Environment]::SetEnvironmentVariable($it.Var, $d, 'User')
    Escribir "$($it.Nombre): listo ($nDest archivos) y $($it.Var) fijada"
}

if ($Ejecutar) {
    $libreC2 = [math]::Round((Get-PSDrive C).Free / 1GB, 1)
    Escribir "Terminado. Libre en C: $libreC2 GB. Cierra y reabre terminales e IDE para tomar las variables."
}
