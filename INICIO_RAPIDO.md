# Inicio rápido

## Antes de comenzar

Instala PostgreSQL para Windows con las herramientas de línea de comandos y Python 3.10 o superior. El proyecto se ha probado con PostgreSQL 18 y Python 3.14. `setup.ps1` usa primero el lanzador de Windows `py -3` y, si no está disponible, utiliza `python`. No necesitas descargar Flask ni Psycopg por separado: el script los instala en el entorno privado del proyecto.

## Pasos

Abre PowerShell en la carpeta del proyecto y ejecuta, en orden:

```powershell
.\setup.ps1
.\init-db.ps1
.\crear-administrador.ps1
.\run.ps1
```

Abre <http://127.0.0.1:5000> e inicia sesión con la cuenta de administrador que creaste. En la pantalla de acceso, cualquier persona puede crear su propia cuenta de perfil persona. Solo el administrador puede convertir cuentas en encargados o administradores desde **Usuarios y roles**.

## Archivo `.env`

El archivo `.env` guarda los datos de conexión local. La primera vez, `init-db.ps1` solicita la contraseña del usuario administrador de PostgreSQL sin mostrarla. El script genera y guarda una contraseña aleatoria para la cuenta técnica `censo_app`, que usa la aplicación con permisos limitados al esquema del proyecto. No compartas `.env`.

Para publicar la aplicación y permitir acceso desde Internet sin dejar tu computador encendido, sigue [`docs/despliegue_publico.md`](docs/despliegue_publico.md). La guía incluye el alojamiento gratuito y sus límites.

## Si algo falla

- Verifica en Servicios de Windows que el servicio `postgresql-x64-18` (o la versión instalada) esté en ejecución.
- Revisa `PGHOST`, `PGPORT`, `PGDATABASE` y `PGUSER` en `.env`.
- Si el proyecto ya tiene el esquema, vuelve a ejecutar `init-db.ps1`: la migración agrega seguridad y corrige la codificación sin borrar sus registros.
- Si PowerShell bloquea los scripts, ejecuta `Set-ExecutionPolicy -Scope Process Bypass` en esa misma ventana.
- La primera instalación de dependencias requiere Internet.

Para otro computador, descarga PostgreSQL y Python. Copia el proyecto sin `.env`, ejecuta `setup.ps1` y sigue los pasos anteriores.
