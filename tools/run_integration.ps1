<#
Corre las pruebas de integracion y las mediciones en el emulador/dispositivo.
Uso:  powershell -File tools\run_integration.ps1 offline|performance|startup [-Device emulator-5554]
Requisitos: emulador `sosiego_pixel` ya encendido (ANDROID_AVD_HOME=D:\dev\caches\android-avd) y el
candado de dispositivo tomado (mkdir /d/tmp/sosiego_device.lock; rmdir al terminar).
#>
param(
  [Parameter(Mandatory = $true)][ValidateSet('offline', 'performance', 'startup')][string]$Modo,
  [string]$Device = 'emulator-5554'
)
$ErrorActionPreference = 'Stop'
$adb = 'C:\Users\andre\Android\Sdk\platform-tools\adb.exe'
$fvm = 'C:\Users\andre\AppData\Local\Pub\Cache\bin\fvm.bat'
Set-Location (Split-Path $PSScriptRoot -Parent)

function Set-Airplane([bool]$on) {
  $v = if ($on) { 'enable' } else { 'disable' }
  & $adb -s $Device shell cmd connectivity airplane-mode $v
  # Respaldo para imagenes sin el comando: svc wifi/data
  & $adb -s $Device shell svc wifi $(if ($on) { 'disable' } else { 'enable' })
  & $adb -s $Device shell svc data $(if ($on) { 'disable' } else { 'enable' })
  Start-Sleep -Seconds 3
}

switch ($Modo) {
  'offline' {
    Set-Airplane $true
    try {
      $ping = & $adb -s $Device shell 'ping -c 1 -W 2 8.8.8.8; echo rc=$?'
      if ($ping -match 'rc=0') { throw 'El dispositivo todavia tiene red: la prueba sin conexion no seria valida.' }
      & $fvm flutter test integration_test/offline_flow_test.dart -d $Device
    } finally { Set-Airplane $false }
  }
  'performance' {
    # --profile da cifras de cuadros representativas; en emulador solo son orientativas.
    & $fvm flutter drive --driver=integration_test/driver.dart --target=integration_test/performance_test.dart -d $Device --no-dds --profile
  }
  'startup' {
    # Arranque en frio: tiempo hasta el primer cuadro (TotalTime/WaitTime de am start -W). Objetivo < 2000 ms.
    & $adb -s $Device shell am force-stop app.sosiego.sosiego 2>$null
    & $adb -s $Device shell am start -W -n app.sosiego.sosiego/.MainActivity
  }
}
