# Guion de demostración y sustentación

## Recorrido

1. **Inicio de sesión:** entrar con la cuenta administradora configurada; explicar que no existe una contraseña predeterminada.
2. **Resumen:** mostrar los indicadores y los terremotos cargados como población ficticia.
3. **Registro y roles:** desde la pantalla de acceso, crear una cuenta nueva y mostrar que queda como perfil persona. Desde **Usuarios y roles**, el administrador puede asignar los perfiles de encargado o administrador.
4. **Gestión de datos:** recorrer las seis categorías y sus 36 entidades funcionales. Abrir un registro, editarlo, crear uno nuevo y consultar el resultado.
5. **Permisos e integridad:** comprobar que el encargado puede crear y editar, pero no borrar ni administrar cuentas. Como administrador, probar borrar un registro de prueba sin dependencias; explicar que PostgreSQL bloquea borrar filas relacionadas.
6. **Evento y territorio:** crear un terremoto de demostración, vincularlo con un municipio y crear un censo para ese par.
7. **Población y vivienda:** mostrar Persona, Hogar, Edificación, Vivienda, Habitación y Ocupación. Explicar por qué hogar y vivienda son entidades distintas.
8. **Daños y respuesta:** mostrar Reportes, Afectaciones, Inspecciones, Necesidades, Solicitudes, Organizaciones e Intervenciones.
9. **Consultas:** abrir las seis vistas y explicar qué relaciones reúne cada una.
10. **Perfil persona:** cerrar sesión, entrar con la cuenta creada y comprobar que puede consultar, editar solo sus propios datos y no administrar otras cuentas.

## Vistas incluidas

| Vista | Relaciones que demuestra |
|---|---|
| `vista_censos_terremoto` | Censo, terremoto, municipio y evento territorial. |
| `vista_personas_censadas` | Persona, registro censal, visita y censo. |
| `vista_viviendas_municipio` | Vivienda, edificación, sector y municipio. |
| `vista_afectaciones_vivienda` | Afectación, vivienda y edificación. |
| `vista_necesidades_hogar` | Necesidad, hogar y terremoto. |
| `vista_intervenciones_organizacion` | Intervención, organización y participación. |

## Ideas para defender el modelo

- El hogar describe convivencia y la vivienda describe un espacio físico; sus relaciones guardan periodos para preservar el historial.
- `terremoto_municipio` representa que un evento alcanza varios municipios sin repetir la descripción del terremoto.
- Reporte, afectación, inspección y evidencia separan la fuente, el daño y su verificación.
- La infraestructura puede relacionarse con varios municipios y dividirse en tramos para localizar daños.
- Las 36 entidades funcionales responden a necesidades del caso; `usuario_app` y `admin_bootstrap_state` son tablas técnicas de control de acceso y alta inicial.
- La clave especial crea una cuenta administradora separada una sola vez; la clave no reemplaza el usuario y la contraseña de esa cuenta.
- Los datos de ejemplo son ficticios; los supuestos pendientes se consultan en [`modelo_entidad_relacion.md`](modelo_entidad_relacion.md).

Antes de exponer, completen los nombres de los integrantes si la entrega lo requiere y comprueben que PostgreSQL esté activo.
