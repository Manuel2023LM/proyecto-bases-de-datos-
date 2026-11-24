$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ProjectRoot

if (-not (Test-Path '.venv\Scripts\python.exe')) {
    throw 'Faltan dependencias. Ejecuta primero .\setup.ps1.'
}
if (-not (Test-Path '.env')) {
    Copy-Item '.env.example' '.env'
    Write-Host 'Se creó .env con valores de ejemplo.' -ForegroundColor Yellow
}

Get-Content '.env' | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith('#') -and $line.Contains('=')) {
        $parts = $line -split '=', 2
        [Environment]::SetEnvironmentVariable($parts[0].Trim(), $parts[1].Trim().Trim('"').Trim("'"), 'Process')
    }
}
if (-not $env:PGAPPUSER) { $env:PGAPPUSER = 'censo_app' }
if (-not $env:PGAPPPASSWORD -or $env:PGAPPPASSWORD.StartsWith('GENERAR_') -or $env:PGAPPPASSWORD.StartsWith('CAMBIA_')) {
    $securePassword = Read-Host "Ingresa la contraseña de $env:PGAPPUSER (no se guardará en .env)" -AsSecureString
    $passwordPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
    try { $env:PGAPPPASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($passwordPointer) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($passwordPointer) }
}

& '.venv\Scripts\python.exe' 'app\app.py'
