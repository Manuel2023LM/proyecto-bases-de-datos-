$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ProjectRoot

if (Get-Command py -ErrorAction SilentlyContinue) {
    $PythonCommand = (Get-Command py).Source
    $PythonArgs = @('-3')
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
    $PythonCommand = (Get-Command python).Source
    $PythonArgs = @()
} else {
    throw 'No encuentro Python. Instala Python 3.10 o superior y vuelve a ejecutar setup.ps1.'
}

& $PythonCommand @PythonArgs -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)"
if ($LASTEXITCODE -ne 0) { throw 'Se requiere Python 3.10 o superior. Instala una versión compatible y vuelve a ejecutar setup.ps1.' }

if (-not (Test-Path '.venv\Scripts\python.exe')) {
    & $PythonCommand @PythonArgs -m venv .venv
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo crear el entorno virtual de Python.' }
}

& '.venv\Scripts\python.exe' -m pip install -r requirements.txt
if ($LASTEXITCODE -ne 0) { throw 'Falló la instalación de dependencias. Revisa Internet o vuelve a ejecutar setup.ps1.' }

if (-not (Test-Path '.env')) {
    Copy-Item '.env.example' '.env'
    Write-Host 'Se creó .env desde .env.example. Los scripts pedirán la clave de PostgreSQL si sigue el valor de ejemplo.' -ForegroundColor Yellow
}

Write-Host 'Dependencias instaladas. Ejecuta .\init-db.ps1 y luego .\run.ps1.' -ForegroundColor Green
