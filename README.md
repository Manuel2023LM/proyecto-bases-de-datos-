# Proyecto final: Censo habitacional y poblacional por afectación de terremotos

Proyecto académico de Base de Datos I para registrar municipios, eventos sísmicos y sus efectos en personas, hogares, viviendas, habitaciones e infraestructura. El modelo parte de los archivos compartidos por el equipo y contiene **36 entidades funcionales justificadas** y dos tablas técnicas de seguridad: 38 tablas en total.

Consulta [`INICIO_RAPIDO.md`](INICIO_RAPIDO.md) para instalarlo y ejecutar la aplicación.

## Entregables

- **MER y MER extendido:** [`docs/modelo_entidad_relacion.md`](docs/modelo_entidad_relacion.md), con relaciones, reglas, supuestos y justificación de las entidades.
- **Diagrama relacional de referencia:** [`docs/diagrama_relacional_base.pdf`](docs/diagrama_relacional_base.pdf).
- **Diccionario de datos:** [`docs/diccionario_datos.md`](docs/diccionario_datos.md), con tipos, nulabilidad, claves y descripciones.
- **Restricciones y seguridad:** [`docs/restricciones_seguridad.md`](docs/restricciones_seguridad.md).
- **Creación y población de ejemplo:** [`sql/00_proyecto_completo.sql`](sql/00_proyecto_completo.sql), junto con los scripts separados de esquema, datos y vistas.
- **Seis vistas de consulta:** [`sql/03_vistas_censo_terremoto.sql`](sql/03_vistas_censo_terremoto.sql); cada vista relaciona más de dos tablas.
- **Aplicación web:** [`app/app.py`](app/app.py), con inicio de sesión, registro de personas, tema claro/oscuro y permisos por rol para gestionar los registros. [`app/init_hosted_database.py`](app/init_hosted_database.py) inicializa la base alojada sin guardar su URL.
- **Guion de sustentación:** [`docs/guion_demostracion.md`](docs/guion_demostracion.md).
- **Análisis del caso:** [`analisis_requisitos.md`](analisis_requisitos.md).
- **Fuentes originales del equipo:** [`docs/material_equipo_fuente/`](docs/material_equipo_fuente/), conservadas sin reemplazar los scripts finales integrados.
- **Despliegue público gratuito:** [`docs/despliegue_publico.md`](docs/despliegue_publico.md) y [`render.yaml`](render.yaml).

## Correspondencia con la rúbrica

| Criterio | Entrega |
|---|---|
| MER y MER extendido (15 %) | [`docs/modelo_entidad_relacion.md`](docs/modelo_entidad_relacion.md) y diagrama relacional de referencia. |
| Diccionario de datos (5 %) | [`docs/diccionario_datos.md`](docs/diccionario_datos.md). |
| Restricciones y seguridad (10 %) | [`docs/restricciones_seguridad.md`](docs/restricciones_seguridad.md). |
| Creación y población SQL (5 %) | [`sql/00_proyecto_completo.sql`](sql/00_proyecto_completo.sql). |
| Seis vistas de más de dos tablas (10 %) | [`sql/03_vistas_censo_terremoto.sql`](sql/03_vistas_censo_terremoto.sql). |
| Programa para registrar información del terremoto | Carpeta [`app/`](app/) y guía de ejecución [`INICIO_RAPIDO.md`](INICIO_RAPIDO.md). |

## Roles de acceso

| Perfil | Permisos |
|---|---|
| Administrador | Gestiona los datos, elimina registros y administra las cuentas y los perfiles. |
| Encargado | Consulta, inserta y edita los registros; no elimina datos ni administra cuentas. |
| Persona | Consulta la información y edita solo su registro personal vinculado. |

La pantalla de acceso permite crear cuentas nuevas, siempre con perfil persona y sus datos personales vinculados. Solo un administrador puede asignar los perfiles de encargado o administrador. Los botones se adaptan al perfil y el servidor vuelve a verificar cada permiso antes de escribir. Las contraseñas de la aplicación se almacenan como hashes. Una cuenta administradora independiente puede crearse una sola vez mediante un código especial; ese código solo autoriza el alta y no sirve para iniciar sesión.

## Requisitos

- Windows 10 u 11.
- PostgreSQL 14 o superior, incluyendo las herramientas `psql.exe` y `createdb.exe`.
- Python 3.10 o superior.
- Internet durante la primera instalación de Flask y Psycopg.

## Instalación y ejecución

Desde PowerShell abierto en esta carpeta:

```powershell
.\setup.ps1
.\init-db.ps1
.\crear-administrador.ps1
.\run.ps1
```

Luego abre <http://127.0.0.1:5000> e inicia sesión con la cuenta de administrador. Desde la pantalla de acceso, las demás personas pueden crear su propia cuenta de perfil persona. Si PowerShell bloquea la ejecución, permite scripts solo en esa ventana con `Set-ExecutionPolicy -Scope Process Bypass`.

`init-db.ps1` solicita la contraseña del administrador de PostgreSQL si `.env` conserva el valor de ejemplo. En una base nueva carga esquema, población ficticia y vistas. Si encuentra el esquema del proyecto existente, conserva los registros, agrega las tablas técnicas de seguridad y corrige los textos que quedaron guardados con codificación incorrecta. También configura la cuenta técnica limitada que usa la aplicación.

## Privacidad de la instalación

`.env` contiene credenciales locales y está excluido del paquete de entrega. No lo compartas ni lo subas a GitHub. La app usa una base local al ejecutarla con `run.ps1`; para publicarla, sigue la guía de despliegue. Esta entrega está preparada para datos ficticios de demostración, no para exponer información personal real en Internet.

La población de ejemplo es ficticia. Incluye eventos, municipios, personas, viviendas, reportes, afectaciones, necesidades, albergues e intervenciones para mostrar el funcionamiento de las consultas.

## Entrega a otro computador

1. El archivo `.env` no se incluye en la entrega; nunca debe enviarse por correo o subirlo a Git.
2. En el computador del profesor, instalar PostgreSQL 14 o superior y Python 3.10 o superior.
3. Ejecutar `setup.ps1`, que crea el entorno privado de Python y genera `.env` desde la plantilla sin credenciales reales.
4. Ejecutar `init-db.ps1`; solicitará una sola vez la contraseña local del administrador de PostgreSQL y configurará una cuenta técnica limitada para la aplicación.
5. Ejecutar `crear-administrador.ps1` y crear la cuenta inicial con una contraseña propia.
6. Ejecutar `run.ps1` y abrir `http://127.0.0.1:5000`.

La carpeta no conserva contraseñas ni sesiones del equipo de desarrollo. Los datos de demostración se cargan nuevamente desde `sql/00_proyecto_completo.sql`.

## Publicación para acceso desde Internet

La app puede publicarse con el plan gratuito de Render y una base PostgreSQL gratuita de Neon siguiendo [`docs/despliegue_publico.md`](docs/despliegue_publico.md). Los planes gratuitos tienen suspensión por inactividad, límites mensuales y arranque en frío; no ofrecen disponibilidad continua garantizada. La base gratuita de Neon escala a cero y tiene límites de uso. Para disponibilidad permanente se requiere un plan de pago y una política de copias de seguridad.
