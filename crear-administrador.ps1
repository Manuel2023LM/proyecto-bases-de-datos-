$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ProjectRoot

if (-not (Test-Path '.venv\Scripts\python.exe')) {
    throw 'Faltan dependencias. Ejecuta primero .\setup.ps1.'
}
if (-not (Test-Path '.env')) {
    throw 'No existe .env. Ejecuta primero .\setup.ps1 y .\init-db.ps1.'
}

Write-Host 'Aviso: la contraseña no se muestra mientras escribes; introdúcela y pulsa Enter en ambos avisos.' -ForegroundColor Cyan
& '.venv\Scripts\python.exe' 'app\crear_administrador.py'
if ($LASTEXITCODE -ne 0) { throw 'No se pudo crear la cuenta. Revisa el mensaje anterior para corregir la entrada o diagnosticar el error de base de datos.' }
