# Análisis de requisitos y alcance

## Planteamiento

Varias alcaldías necesitan reunir información de personas, hogares, viviendas e infraestructura afectada por terremotos ocurridos en fechas distintas. Sus archivos llegan en formatos heterogéneos y pueden ser incompletos o contradictorios. La solución debe conservar el evento y el municipio de cada registro para consultar qué cambió, quién necesita atención y qué acciones siguen pendientes.

Un hogar puede compartir vivienda con otros hogares, ocupar una habitación independiente o reubicarse después de un evento. La persona propietaria puede vivir en otro municipio. Los equipos de campo pueden no encontrar a alguien y recibir después nueva información. Para que el sistema represente esos casos, el modelo separa persona, hogar, edificación, vivienda, habitación, ocupación, propiedad, visita y registro censal.

El daño puede reportarse por habitantes o por personal de campo y más tarde confirmarse o corregirse. Las afectaciones también incluyen carreteras y otros activos que pueden extenderse por varios municipios o dividirse en tramos. La respuesta requiere registrar necesidades, solicitudes, organizaciones, intervenciones, albergues y estancias.

## Objetivo

Diseñar e implementar una base de datos relacional para registrar y consultar el censo habitacional y poblacional vinculado con terremotos. La solución debe distinguir municipios y eventos, conservar relaciones históricas, permitir registrar afectaciones de personas, viviendas e infraestructura, y demostrar el funcionamiento mediante seis vistas y una aplicación CRUD.

## Alcance funcional

1. Administrar departamentos, municipios y sectores.
2. Registrar terremotos y los municipios que afecta cada evento.
3. Crear censos y registrar visitas, resultados y personas encontradas.
4. Mantener personas, hogares, integrantes y relaciones temporales con viviendas y habitaciones.
5. Registrar edificaciones, viviendas, habitaciones y titularidad de vivienda.
6. Recibir reportes de daños y referencias a evidencias.
7. Registrar afectaciones de personas, viviendas e infraestructura, junto con inspecciones y consecuencias.
8. Administrar activos, tramos y vínculos territoriales de infraestructura.
9. Registrar alojamientos y estancias, necesidades, solicitudes e intervenciones con organizaciones participantes.
10. Crear, consultar, editar y eliminar registros desde una interfaz local, con permisos por perfil.
11. Consultar seis vistas de más de dos tablas para apoyar el seguimiento.

## Requisitos funcionales

| Código | Requisito |
|---|---|
| RF-01 | El sistema registra varios departamentos, municipios, sectores y terremotos. |
| RF-02 | Un terremoto se puede asociar con varios municipios; un municipio puede aparecer en diferentes terremotos. |
| RF-03 | Cada censo pertenece al par terremoto-municipio previamente asociado. |
| RF-04 | Se registran personas, hogares, integrantes y su relación temporal con viviendas y habitaciones. |
| RF-05 | Se registran visitas de censo y personas censadas, sin exigir que cada visita encuentre a alguien. |
| RF-06 | Se reciben reportes, se registra su fuente y estado de verificación, y se asocia evidencia documental. |
| RF-07 | Las afectaciones de vivienda e infraestructura se distinguen mediante un supertipo y subtipos relacionados. |
| RF-08 | La infraestructura puede relacionarse con varios municipios y dividirse en tramos. |
| RF-09 | Se administran inspecciones, consecuencias, necesidades, solicitudes, intervenciones y organizaciones participantes. |
| RF-10 | Se registran alojamientos y estancias asociadas exactamente a una persona o a un hogar. |
| RF-11 | La interfaz permite insertar, consultar, editar y eliminar filas, respetando las restricciones de integridad. |
| RF-12 | Las seis vistas presentan consultas relacionales útiles para el análisis del evento. |
| RF-13 | El registro público crea una cuenta de perfil persona y su ficha vinculada; solo el administrador puede asignar roles elevados. |
| RF-14 | El encargado puede consultar, insertar y editar registros, pero no eliminarlos ni administrar cuentas. |

## Requisitos no funcionales

- **Motor:** PostgreSQL 14 o superior.
- **Interfaz:** aplicación Flask en español, adaptable a pantallas de escritorio y móvil.
- **Integridad:** claves primarias, claves foráneas, restricciones `UNIQUE`, `CHECK` y disparadores.
- **Seguridad del prototipo:** conexión local, datos ficticios, parámetros SQL y credenciales en `.env` excluido de Git.
- **Control de acceso:** el administrador gestiona cuentas y perfiles; encargado y persona tienen permisos limitados que se verifican en el servidor.
- **Mantenibilidad:** nombres de tablas y columnas en español sin tildes, para facilitar consultas SQL; los textos visibles conservan la ortografía española.

## Supuestos del equipo

- La unidad territorial se modela con departamento, municipio y sector; el código DANE puede identificar departamento y municipio.
- Los datos de personas y viviendas entregados para demostración son ficticios.
- Una persona puede aparecer en censos diferentes y en afectaciones asociadas a terremotos distintos.
- Hogar y vivienda no son equivalentes. Un hogar puede cambiar de vivienda, y una vivienda puede albergar hogares diferentes a través del tiempo.
- Las afectaciones se separan de los reportes: el reporte conserva lo informado y la afectación representa el registro del daño.
- Un evento puede atenderse en varios municipios; la fecha del evento y la relación territorial permiten distinguir impactos históricos.
- El periodo de ocupación y propiedad se conserva mediante fechas de inicio y fin; las restricciones de solapamiento se dejan como regla pendiente para una segunda versión.
- La aplicación implementa inicio de sesión con roles; el prototipo no controla la capacidad acumulada de los albergues.
- El formulario de registro solo permite crear cuentas de perfil persona. Un administrador asigna los perfiles de encargado o administrador.
- El perfil encargado puede consultar, insertar y editar datos, pero no puede borrar ni administrar cuentas.

## Preguntas para el docente

El caso indica que el equipo debe validar algunas decisiones. Se proponen estas preguntas para registrar las respuestas antes de la sustentación:

1. ¿Toda persona necesita documento de identidad, o se permiten registros sin identificar?
2. ¿Las estancias de albergue deben asignarse a hogares completos, personas o ambos modelos según el caso?
3. ¿Qué catálogo de estados, niveles de daño y tipos de fuentes de reporte se debe utilizar?
4. ¿Se debe impedir que una vivienda o habitación tenga ocupaciones simultáneas incompatibles?
5. ¿Se debe bloquear el ingreso a un albergue cuando se alcance la capacidad registrada?
6. ¿Se requiere algún perfil adicional a administrador, encargado y persona para alcaldías, brigadas u organizaciones?

El modelo actual deja escritas las decisiones del equipo en [`docs/modelo_entidad_relacion.md`](docs/modelo_entidad_relacion.md) y las reglas que requieren validación en [`docs/restricciones_seguridad.md`](docs/restricciones_seguridad.md).
