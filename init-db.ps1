$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ProjectRoot

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
$env:PGCLIENTENCODING = 'UTF8'

$PgParent = Join-Path $env:ProgramFiles 'PostgreSQL'
$PgBins = @()
if (Test-Path $PgParent) {
    $PgBins = @(Get-ChildItem $PgParent -Directory | Where-Object { $_.Name -match '^\d+$' } |
        Sort-Object { [int]$_.Name } -Descending |
        ForEach-Object { Join-Path $_.FullName 'bin' } |
        Where-Object { Test-Path (Join-Path $_ 'psql.exe') })
}
if (-not $PgBins) {
    throw "No encuentro psql en $PgParent. Instala PostgreSQL con sus herramientas de línea de comandos."
}
$PgBin = $PgBins[0]
$Psql = Join-Path $PgBin 'psql.exe'
$Createdb = Join-Path $PgBin 'createdb.exe'
$PgVersion = Split-Path (Split-Path $PgBin -Parent) -Leaf

$ServiceName = "postgresql-x64-$PgVersion"
$Service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($Service -and $Service.Status -ne 'Running') {
    throw "El servicio $ServiceName está detenido. Inícialo desde Servicios de Windows y vuelve a ejecutar este archivo."
}
if ([string]::IsNullOrWhiteSpace($env:PGPASSWORD) -or $env:PGPASSWORD -match '^(CAMBIA_|REEMPLAZA_|PON_AQUI|CHANGE_ME|YOUR_PASSWORD)') {
    $securePassword = Read-Host 'Ingresa la contraseña del administrador de PostgreSQL (no se guardará en .env)' -AsSecureString
    $passwordPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
    try { $env:PGPASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($passwordPointer) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($passwordPointer) }
}

$HostName = if ($env:PGHOST) { $env:PGHOST } else { 'localhost' }
$Port = if ($env:PGPORT) { $env:PGPORT } else { '5432' }
$DbName = if ($env:PGDATABASE) { $env:PGDATABASE } else { 'censo_terremoto' }
$DbUser = if ($env:PGUSER) { $env:PGUSER } else { 'postgres' }

$Existing = & $Psql -h $HostName -p $Port -U $DbUser -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$DbName'"
if ($LASTEXITCODE -ne 0) { throw 'No se pudo conectar al servidor PostgreSQL. Revisa el servicio y los datos de conexión en .env.' }
if (-not $Existing) {
    & $Createdb -h $HostName -p $Port -U $DbUser $DbName
    if ($LASTEXITCODE -ne 0) { throw "No se pudo crear la base $DbName." }
    Write-Host "Base $DbName creada." -ForegroundColor Green
} else {
    Write-Host "Se usará la base existente $DbName. No se eliminarán otros esquemas." -ForegroundColor Yellow
}

$ExistingSchema = & $Psql -h $HostName -p $Port -U $DbUser -d $DbName -tAc "SELECT 1 FROM information_schema.schemata WHERE schema_name='censo_terremoto'"
if ($LASTEXITCODE -ne 0) { throw 'No se pudo consultar el estado de la base de datos.' }
if ($ExistingSchema) {
    Write-Host 'Esquema encontrado. Se actualizarán seguridad y codificación, conservando los datos existentes.' -ForegroundColor Yellow
    & $Psql -v ON_ERROR_STOP=1 -h $HostName -p $Port -U $DbUser -d $DbName -f 'sql\04_actualizacion_seguridad.sql'
    if ($LASTEXITCODE -ne 0) { throw 'Falló la actualización de seguridad o de acentos.' }
} else {
    & $Psql -v ON_ERROR_STOP=1 -h $HostName -p $Port -U $DbUser -d $DbName -f 'sql\00_proyecto_completo.sql'
    if ($LASTEXITCODE -ne 0) { throw 'Falló la carga SQL. Revisa el error de PostgreSQL mostrado arriba.' }
    Write-Host 'Esquema, datos ficticios y seis vistas cargados correctamente.' -ForegroundColor Green
}

if (-not (Test-Path '.venv\Scripts\python.exe')) { throw 'Falta el entorno Python. Ejecuta primero .\setup.ps1.' }
& '.venv\Scripts\python.exe' 'app\configure_database_role.py'
if ($LASTEXITCODE -ne 0) { throw 'No se pudo configurar la cuenta técnica censo_app. Revisa los permisos del administrador de PostgreSQL.' }
Write-Host 'Cuenta técnica censo_app configurada. Ejecuta .\crear-administrador.ps1 para registrar el primer administrador.' -ForegroundColor Green
