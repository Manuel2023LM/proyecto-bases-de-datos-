# Diccionario de datos

**Motor:** PostgreSQL 14 o superior. **Esquema:** `censo_terremoto`. **Entidades funcionales:** 36. **Tablas técnicas:** `usuario_app` y `admin_bootstrap_state`. **Total de tablas:** 38. **Identificadores:** `BIGINT`; 32 claves se generan con `IDENTITY`, y las restantes son claves compuestas o compartidas con su entidad principal.

Las columnas conservan nombres sin tildes para que sean sencillas de escribir en SQL. La aplicación muestra etiquetas en español con tildes. `PK` identifica la clave primaria; `FK` identifica una clave foránea; `NN` significa `NOT NULL`; `UQ` significa unicidad. Los valores vacíos se representan como `NULL` cuando la columna lo permite.

## Resumen de relaciones

Las 54 claves foráneas conectan territorio, eventos, población, vivienda, reportes, infraestructura y respuesta. Las tablas asociativas guardan datos propios de relaciones muchos-a-muchos, como `terremoto_municipio`, `infraestructura_municipio` e `intervencion_organizacion`.

## Geografía

### `departamento` — Departamentos

División administrativa que agrupa los municipios incluidos en el censo.

| Columna | Tipo | Reglas | Descripción |
|---|---|---|---|
| `id_departamento` | `BIGINT` | PK; NN; IDENTITY | Identificador del departamento. |
| `nombre` | `VARCHAR(60)` | Admite NULL | Nombre. |
| `codigo_dane` | `VARCHAR(2)` | NN; UQ `Departamento_CodigoDane_UK` | Código DANE. |

### `municipio` — Municipios

Territorio municipal que participa en uno o varios eventos.

| Columna | Tipo | Reglas | Descripción |
|---|---|---|---|
| `id_municipio` | `BIGINT` | PK; NN; IDENTITY | Identificador del municipio. |
| `nombre` | `VARCHAR(60)` | NN | Nombre. |
| `codigo_dane` | `VARCHAR(5)` | NN; UQ `Municipio_CodigoDane_UK` | Código DANE. |
| `departamento_id_departamento` | `BIGINT` | FK → `departamento.id_departamento`; NN | Departamento. |

### `sector` — Sectores

Barrio, vereda u otro sector geográfico de un municipio.

| Columna | Tipo | Reglas | Descripción |
|---|---|---|---|
| `id_sector` | `BIGINT` | PK; NN; IDENTITY | Identificador del sector. |
| `nombre` | `VARCHAR(80)` | NN | Nombre. |
| `tipo_sector` | `VARCHAR(20)` | NN | Tipo de sector. |
| `municipio_id_municipio` | `BIGINT` | FK → `municipio.id_municipio`; NN | Municipio. |

## Eventos y censos

### `terremoto` — Terremotos

Evento sísmico con fecha, magnitud, profundidad y descripción.

| Columna | Tipo | Reglas | Descripción |
|---|---|---|---|
| `id_terremoto` | `BIGINT` | PK; NN; IDENTITY | Identificador del terremoto. |
| `fecha_hora` | `TIMESTAMP` | NN | Fecha y hora. |
| `magnitud` | `NUMERIC` | Admite NULL | Magnitud. |
| `profundidad_km` | `NUMERIC` | Admite NULL | Profundidad (km). |
| `descripcion` | `VARCHAR(500)` | Admite NULL | Descripción. |

### `terremoto_municipio` — Terremotos por municipio

Relación que registra los municipios alcanzados por cada terremoto.

| Columna | Tipo | Reglas | Descripción |
|---|---|---|---|
| `fecha_registro` | `DATE` | NN | Fecha de registro. |
| `observaciones` | `VARCHAR(300)` | Admite NULL | Observaciones. |
| `municipio_id_municipio` | `BIGINT` | PK; FK → `municipio.id_municipio`; NN | Municipio. |
| `terremoto_id_terremoto` | `BIGINT` | PK; FK → `terremoto.id_terremoto`; NN | Terremoto. |

### `censo` — Censos

Operativo de recolección asociado a un terremoto y a un municipio.

| Columna | Tipo | Reglas | Descripción |
|---|---|---|---|
| `id_censo` | `BIGINT` | PK; NN; IDENTITY | Identificador del censo. |
| `fecha_inicio` | `DATE` | NN | Fecha de inicio. |
| `fecha_fin` | `DATE` | Admite NULL | Fecha de finalización. |
| `estado` | `VARCHAR(20)` | NN | Estado. |
| `id_municipio` | `BIGINT` | FK → `terremoto_municipio.municipio_id_municipio`; NN | Identificador del municipio. |
| `id_terremoto` | `BIGINT` | FK → `terremoto_municipio.terremoto_id_terremoto`; NN | Identificador del terremoto. |

### `visita_censo` — Visitas de censo

Visita de campo realizada como parte de un censo.

| Columna | Tipo | Reglas | Descripción |
|---|---|---|---|
| `id_visita` | `BIGINT` | PK; NN; IDENTITY | Identificador de la visita. |
| `fecha_visita` | `TIMESTAMP` | NN | Fecha de visita. |
| `resultado` | `VARCHAR(30)` | NN | Resultado. |
| `observaciones` | `VARCHAR(500)` | Admite NULL | Observaciones. |
| `ubicacion_referencia` | `VARCHAR(150)` | Admite NULL | Ubicación de referencia. |
| `censo_id_censo` | `BIGINT` | FK → `censo.id_censo`; NN | Censo. |
| `vivienda_id_vivienda` | `BIGINT` | FK → `vivienda.id_vivienda`; Admite NULL | Vivienda. |

### `registro_censal_persona` — Personas censadas

Persona encontrada y registrada durante una visita.

| Columna | Tipo | Reglas | Descripción |
|---|---|---|---|
| `id_registro` | `BIGINT` | PK; NN; IDENTITY | Identificador interno. |
| `fecha_registro` | `TIMESTAMP` | NN | Fecha de registro. |
| `observaciones` | `VARCHAR(500)` | Admite NULL | Observaciones. |
| `visita_censo_id_visita` | `BIGINT` | FK → `visita_censo.id_visita`; NN; UQ `Registro_Censal_UK` | Visita de censo. |
| `persona_id_persona` | `BIGINT` | FK → `persona.id_persona`; NN; UQ `Registro_Censal_UK` | Persona. |

## Personas, hogares y viviendas

### `persona` — Personas

Persona censada o afectada. La identificación es opcional en el modelo.

| Columna | Tipo | Reglas | Descripción |
|---|---|---|---|
| `id_persona` | `BIGINT` | PK; NN; IDENTITY | Identificador de la persona. |
| `tipo_documento` | `VARCHAR(10)` | Admite NULL; UQ `Persona_Documento_UK` | Tipo de documento. |
| `numero_documento` | `VARCHAR(20)` | Admite NULL; UQ `Persona_Documento_UK` | Número de documento. |
| `nombres` | `VARCHAR(80)` | NN | Nombres. |
| `apellidos` | `VARCHAR(80)` | Admite NULL | Apellidos. |
| `fecha_nacimiento` | `DATE` | Admite NULL | Fecha de nacimiento. |
| `telefono` | `VARCHAR(20)` | Admite NULL | Teléfono. |

### `hogar` — Hogares

Unidad de convivencia que puede cambiar de vivienda con el tiempo.

| Columna | Tipo | Reglas | Descripción |
|---|---|---|---|
| `id_hogar` | `BIGINT` | PK; NN; IDENTITY | Identificador del hogar. |
| `fecha_registro` | `DATE` | NN | Fecha de registro. |
| `observaciones` | `VARCHAR(300)` | Admite NULL | Observaciones. |

### `integrante_hogar` — Integrantes de hogar

Membresía temporal de una persona en un hogar.

| Columna | Tipo | Reglas | Descripción |
|---|---|---|---|
| `id_integrante_hogar` | `BIGINT` | PK; NN; IDENTITY | Identificador interno. |
| `fecha_inicio` | `DATE` | NN | Fecha de inicio. |
| `fecha_fin` | `DATE` | Admite NULL | Fecha de finalización. |
| `parentesco` | `VARCHAR(30)` | Admite NULL | Parentesco. |
| `persona_id_persona` | `BIGINT` | FK → `persona.id_persona`; NN | Persona. |
| `hogar_id_hogar` | `BIGINT` | FK → `hogar.id_hogar`; NN | Hogar. |

### `edificacion` — Edificaciones

Construcción ubicada en un sector, que puede contener varias viviendas.

| Columna | Tipo | Reglas | Descripción |
|---|---|---|---|
| `id_edificacion` | `BIGINT` | PK; NN; IDENTITY | Identificador de la edificación. |
| `direccion` | `VARCHAR(150)` | Admite NULL | Dirección. |
| `numero_pisos` | `NUMERIC` | Admite NULL | Número de pisos. |
| `observaciones` | `VARCHAR(300)` | Admite NULL | Observaciones. |
| `sector_id_sector` | `BIGINT` | FK → `sector.id_sector`; NN | Sector. |

### `vivienda` — Viviendas

Unidad habitacional asociada a una edificación.

| Columna | Tipo | Reglas | Descripción |
|---|---|---|---|
| `id_vivienda` | `BIGINT` | PK; NN; IDENTITY | Identificador de la vivienda. |
| `numero_unidad` | `VARCHAR(20)` | Admite NULL | Número de unidad. |
| `tipo_vivienda` | `VARCHAR(30)` | NN | Tipo de vivienda. |
| `observaciones` | `VARCHAR(300)` | Admite NULL | Observaciones. |
| `edificacion_id_edificacion` | `BIGINT` | FK → `edificacion.id_edificacion`; NN | Edificación. |

### `habitacion` — Habitaciones

Espacio interno de una vivienda, con ocupación y uso propios.

| Columna | Tipo | Reglas | Descripción |
|---|---|---|---|
| `id_habitacion` | `BIGINT` | PK; NN; IDENTITY | Identificador de la habitación. |
| `numero_habitacion` | `VARCHAR(20)` | NN | Número de habitación. |
| `uso` | `VARCHAR(30)` | Admite NULL | Uso. |
| `arrendable_independiente` | `NUMERIC` | NN | Arrendable de forma independiente. |
| `vivienda_id_vivienda` | `BIGINT` | FK → `vivienda.id_vivienda`; NN | Vivienda. |

### `ocupacion_vivienda` — Ocupaciones de vivienda

Periodo durante el que un hogar ocupa una vivienda.

| Columna | Tipo | Reglas | Descripción |
|---|---|---|---|
| `id_ocupacion` | `BIGINT` | PK; NN; IDENTITY | Identificador interno. |
| `fecha_inicio` | `DATE` | NN | Fecha de inicio. |
| `fecha_fin` | `DATE` | Admite NULL | Fecha de finalización. |
| `tipo_ocupacion` | `VARCHAR(30)` | NN | Tipo de ocupación. |
| `hogar_id_hogar` | `BIGINT` | FK → `hogar.id_hogar`; NN | Hogar. |
| `vivienda_id_vivienda` | `BIGINT` | FK → `vivienda.id_vivienda`; NN | Vivienda. |

### `ocupacion_habitacion` — Ocupaciones de habitación

Periodo durante el que un hogar ocupa una habitación.

| Columna | Tipo | Reglas | Descripción |
|---|---|---|---|
| `id_ocupacion_habitacion` | `BIGINT` | PK; NN; IDENTITY | Identificador interno. |
| `fecha_inicio` | `DATE` | NN | Fecha de inicio. |
| `fecha_fin` | `DATE` | Admite NULL | Fecha de finalización. |
| `hogar_id_hogar` | `BIGINT` | FK → `hogar.id_hogar`; NN | Hogar. |
| `habitacion_id_habitacion` | `BIGINT` | FK → `habitacion.id_habitacion`; NN | Habitación. |

### `propiedad_vivienda` — Propiedad de vivienda

Relación temporal entre una persona propietaria y una vivienda.

| Columna | Tipo | Reglas | Descripción |
|---|---|---|---|
| `id_propiedad` | `BIGINT` | PK; NN; IDENTITY | Identificador interno. |
| `fecha_inicio` | `DATE` | Admite NULL | Fecha de inicio. |
| `fecha_fin` | `DATE` | Admite NULL | Fecha de finalización. |
| `porcentaje_propiedad` | `NUMERIC` | Admite NULL | Porcentaje de propiedad. |
| `persona_id_persona` | `BIGINT` | FK → `persona.id_persona`; NN | Persona. |
| `vivienda_id_vivienda` | `BIGINT` | FK → `vivienda.id_vivienda`; NN | Vivienda. |

## Reportes y afectaciones

### `reporte_dano` — Reportes de daño

Información recibida sobre daños relacionados con un terremoto.

| Columna | Tipo | Reglas | Descripción |
|---|---|---|---|
| `id_reporte` | `BIGINT` | PK; NN; IDENTITY | Identificador del reporte. |
| `fecha_reporte` | `TIMESTAMP` | NN | Fecha del reporte. |
| `tipo_fuente` | `VARCHAR(30)` | NN | Fuente del reporte. |
| `descripcion` | `VARCHAR(500)` | NN | Descripción. |
| `estado_verificacion` | `VARCHAR(20)` | NN | Estado de verificación. |
| `terremoto_id_terremoto` | `BIGINT` | FK → `terremoto.id_terremoto`; NN | Terremoto. |

### `evidencia` — Evidencias

Referencia a una fotografía, documento u otra evidencia de un reporte o inspección.

| Columna | Tipo | Reglas | Descripción |
|---|---|---|---|
| `id_evidencia` | `BIGINT` | PK; NN; IDENTITY | Identificador interno. |
| `tipo_evidencia` | `VARCHAR(30)` | NN | Tipo de evidencia. |
| `ruta_archivo` | `VARCHAR(300)` | NN | Ruta de archivo. |
| `fecha_registro` | `DATE` | NN | Fecha de registro. |
| `descripcion` | `VARCHAR(300)` | Admite NULL | Descripción. |
| `reporte_dano_id_reporte` | `BIGINT` | FK → `reporte_dano.id_reporte`; Admite NULL | Reporte de daño. |
| `inspeccion_id_inspeccion` | `BIGINT` | FK → `inspeccion.id_inspeccion`; Admite NULL | Inspección. |

### `afectacion` — Afectaciones

Registro general de un daño, clasificado por tipo y vinculado al evento.

| Columna | Tipo | Reglas | Descripción |
|---|---|---|---|
| `id_afectacion` | `BIGINT` | PK; NN; IDENTITY | Identificador de la afectación. |
| `fecha_registro` | `DATE` | NN | Fecha de registro. |
| `descripcion_general` | `VARCHAR(500)` | NN | Descripción general. |
| `estado` | `VARCHAR(30)` | NN | Estado. |
| `terremoto_id_terremoto` | `BIGINT` | FK → `terremoto.id_terremoto`; NN | Terremoto. |
| `reporte_dano_id_reporte` | `BIGINT` | FK → `reporte_dano.id_reporte`; Admite NULL | Reporte de daño. |
| `tipo_afectacion` | `VARCHAR(26)` | NN | Tipo de afectación. |

### `afectacion_persona` — Afectaciones a personas

Situación de una persona afectada por un terremoto.

| Columna | Tipo | Reglas | Descripción |
|---|---|---|---|
| `id_afectacion_persona` | `BIGINT` | PK; NN; IDENTITY | Identificador interno. |
| `situacion` | `VARCHAR(30)` | Admite NULL | Situación. |
| `condicion_presencia` | `VARCHAR(20)` | Admite NULL | Condición de presencia. |
| `desplazado` | `NUMERIC` | Admite NULL | Desplazamiento (0 o 1). |
| `fecha_registro` | `DATE` | NN | Fecha de registro. |
| `observaciones` | `VARCHAR(500)` | Admite NULL | Observaciones. |
| `persona_id_persona` | `BIGINT` | FK → `persona.id_persona`; NN | Persona. |
| `terremoto_id_terremoto` | `BIGINT` | FK → `terremoto.id_terremoto`; NN | Terremoto. |
| `municipio_id_municipio` | `BIGINT` | FK → `municipio.id_municipio`; Admite NULL | Municipio. |

### `afectacion_vivienda` — Afectaciones a viviendas

Detalle de una afectación que corresponde a una vivienda.

| Columna | Tipo | Reglas | Descripción |
|---|---|---|---|
| `id_afectacion` | `BIGINT` | PK; FK → `afectacion.id_afectacion`; NN | Identificador de la afectación. |
| `observaciones` | `VARCHAR(300)` | Admite NULL | Observaciones. |
| `vivienda_id_vivienda` | `BIGINT` | FK → `vivienda.id_vivienda`; NN | Vivienda. |

### `afectacion_infraestructura` — Afectaciones a infraestructura

Detalle de una afectación que corresponde a infraestructura y tramo.

| Columna | Tipo | Reglas | Descripción |
|---|---|---|---|
| `id_afectacion` | `BIGINT` | PK; FK → `afectacion.id_afectacion`; NN | Identificador de la afectación. |
| `observaciones` | `VARCHAR(300)` | Admite NULL | Observaciones. |
| `id_infraestructura` | `BIGINT` | FK → `infraestructura.id_infraestructura`; NN | Identificador de la infraestructura. |
| `tramo_infraestructura_id_tramo` | `BIGINT` | FK → `tramo_infraestructura.id_tramo`; NN | Tramo de infraestructura. |

### `inspeccion` — Inspecciones

Evaluación técnica realizada por personal de campo sobre una afectación.

| Columna | Tipo | Reglas | Descripción |
|---|---|---|---|
| `id_inspeccion` | `BIGINT` | PK; NN; IDENTITY | Identificador de la inspección. |
| `fecha_inspeccion` | `TIMESTAMP` | NN | Fecha de inspección. |
| `nivel_dano` | `VARCHAR(20)` | Admite NULL | Nivel de daño. |
| `resultado` | `VARCHAR(300)` | NN | Resultado. |
| `observaciones` | `VARCHAR(500)` | Admite NULL | Observaciones. |
| `afectacion_id_afectacion` | `BIGINT` | FK → `afectacion.id_afectacion`; NN | Afectación. |
| `personal_campo_id_personal` | `BIGINT` | FK → `personal_campo.id_personal`; NN | Personal de campo. |

### `consecuencia_afectacion` — Consecuencias de afectación

Efecto derivado de una afectación y su estado de seguimiento.

| Columna | Tipo | Reglas | Descripción |
|---|---|---|---|
| `id_consecuencia` | `BIGINT` | PK; NN; IDENTITY | Identificador interno. |
| `tipo_consecuencia` | `VARCHAR(40)` | NN | Tipo de consecuencia. |
| `descripcion` | `VARCHAR(500)` | NN | Descripción. |
| `fecha_inicio` | `DATE` | NN | Fecha de inicio. |
| `fecha_fin` | `DATE` | Admite NULL | Fecha de finalización. |
| `estado` | `VARCHAR(20)` | NN | Estado. |
| `afectacion_id_afectacion` | `BIGINT` | FK → `afectacion.id_afectacion`; NN | Afectación. |

## Infraestructura

### `infraestructura` — Infraestructuras

Activo o servicio de infraestructura que puede atender varios municipios.

| Columna | Tipo | Reglas | Descripción |
|---|---|---|---|
| `id_infraestructura` | `BIGINT` | PK; NN; IDENTITY | Identificador de la infraestructura. |
| `nombre` | `VARCHAR(100)` | NN | Nombre. |
| `tipo_infraestructura` | `VARCHAR(40)` | NN | Tipo de infraestructura. |
| `descripcion` | `VARCHAR(500)` | Admite NULL | Descripción. |
| `estado_operativo` | `VARCHAR(30)` | Admite NULL | Estado operativo. |

### `infraestructura_municipio` — Infraestructura por municipio

Relación territorial de una infraestructura con un municipio.

| Columna | Tipo | Reglas | Descripción |
|---|---|---|---|
| `tipo_vinculo` | `VARCHAR(30)` | NN | Tipo de vínculo. |
| `observaciones` | `VARCHAR(300)` | Admite NULL | Observaciones. |
| `id_infraestructura` | `BIGINT` | PK; FK → `infraestructura.id_infraestructura`; NN | Identificador de la infraestructura. |
| `municipio_id_municipio` | `BIGINT` | PK; FK → `municipio.id_municipio`; NN | Municipio. |

### `tramo_infraestructura` — Tramos de infraestructura

Segmento identificable de una infraestructura lineal.

| Columna | Tipo | Reglas | Descripción |
|---|---|---|---|
| `id_tramo` | `BIGINT` | PK; NN; IDENTITY | Identificador del tramo. |
| `codigo_tramo` | `VARCHAR(30)` | NN | Codigo tramo. |
| `km_inicio` | `NUMERIC` | Admite NULL | Kilómetro inicial. |
| `km_fin` | `NUMERIC` | Admite NULL | Kilómetro final. |
| `descripcion` | `VARCHAR(300)` | Admite NULL | Descripción. |
| `id_infraestructura` | `BIGINT` | FK → `infraestructura.id_infraestructura`; NN | Identificador de la infraestructura. |

## Atención y respuesta

### `organizacion` — Organizaciones

Entidad que participa en labores de atención o recuperación.

| Columna | Tipo | Reglas | Descripción |
|---|---|---|---|
| `id_organizacion` | `BIGINT` | PK; NN; IDENTITY | Identificador de la organización. |
| `nombre` | `VARCHAR(100)` | NN | Nombre. |
| `tipo_organizacion` | `VARCHAR(40)` | NN | Tipo de organización. |
| `telefono` | `VARCHAR(20)` | Admite NULL | Teléfono. |
| `correo` | `VARCHAR(100)` | Admite NULL | Correo electrónico. |

### `personal_campo` — Personal de campo

Integrante de una organización que participa en las visitas o inspecciones.

| Columna | Tipo | Reglas | Descripción |
|---|---|---|---|
| `id_personal` | `BIGINT` | PK; NN; IDENTITY | Identificador del personal. |
| `nombres` | `VARCHAR(20)` | NN | Nombres. |
| `apellidos` | `VARCHAR(80)` | NN | Apellidos. |
| `cargo` | `VARCHAR(60)` | Admite NULL | Cargo. |
| `telefono` | `VARCHAR(20)` | Admite NULL | Teléfono. |
| `organizacion_id_organizacion` | `BIGINT` | FK → `organizacion.id_organizacion`; NN | Organización. |

### `alojamiento_temporal` — Alojamientos temporales

Lugar habilitado para alojar personas u hogares después de un evento.

| Columna | Tipo | Reglas | Descripción |
|---|---|---|---|
| `id_alojamiento` | `BIGINT` | PK; NN; IDENTITY | Alojamiento temporal. |
| `nombre` | `VARCHAR(100)` | NN | Nombre. |
| `direccion` | `VARCHAR(150)` | NN | Dirección. |
| `capacidad_personas` | `NUMERIC` | NN | Capacidad de personas. |
| `estado` | `VARCHAR(30)` | NN | Estado. |
| `municipio_id_municipio` | `BIGINT` | FK → `municipio.id_municipio`; NN | Municipio. |

### `estancia_alojamiento` — Estancias en alojamiento

Periodo de alojamiento de una persona o de un hogar.

| Columna | Tipo | Reglas | Descripción |
|---|---|---|---|
| `id_estancia` | `BIGINT` | PK; NN; IDENTITY | Identificador interno. |
| `fecha_ingreso` | `DATE` | NN | Fecha de ingreso. |
| `fecha_salida` | `DATE` | Admite NULL | Fecha de salida. |
| `observaciones` | `VARCHAR(300)` | Admite NULL | Observaciones. |
| `id_alojamiento` | `BIGINT` | FK → `alojamiento_temporal.id_alojamiento`; NN | Alojamiento temporal. |
| `terremoto_id_terremoto` | `BIGINT` | FK → `terremoto.id_terremoto`; NN | Terremoto. |
| `hogar_id_hogar` | `BIGINT` | FK → `hogar.id_hogar`; Admite NULL | Hogar. |
| `persona_id_persona` | `BIGINT` | FK → `persona.id_persona`; Admite NULL | Persona. |

### `necesidad` — Necesidades

Necesidad identificada para un hogar a causa de un terremoto.

| Columna | Tipo | Reglas | Descripción |
|---|---|---|---|
| `id_necesidad` | `BIGINT` | PK; NN; IDENTITY | Identificador de la necesidad. |
| `tipo_necesidad` | `VARCHAR(40)` | NN | Tipo de necesidad. |
| `descripcion` | `VARCHAR(500)` | Admite NULL | Descripción. |
| `prioridad` | `VARCHAR(20)` | NN | Prioridad. |
| `fecha_identificacion` | `DATE` | NN | Fecha de identificación. |
| `estado` | `VARCHAR(20)` | NN | Estado. |
| `hogar_id_hogar` | `BIGINT` | FK → `hogar.id_hogar`; NN | Hogar. |
| `terremoto_id_terremoto` | `BIGINT` | FK → `terremoto.id_terremoto`; NN | Terremoto. |

### `solicitud_atencion` — Solicitudes de atención

Solicitud de atención derivada de una necesidad.

| Columna | Tipo | Reglas | Descripción |
|---|---|---|---|
| `id_solicitud` | `BIGINT` | PK; NN; IDENTITY | Solicitud de atención. |
| `fecha_solicitud` | `DATE` | NN | Fecha de solicitud. |
| `estado` | `VARCHAR(25)` | NN | Estado. |
| `observaciones` | `VARCHAR(500)` | Admite NULL | Observaciones. |
| `necesidad_id_necesidad` | `BIGINT` | FK → `necesidad.id_necesidad`; NN | Necesidad. |

### `intervencion` — Intervenciones

Acción de respuesta vinculada a una afectación y una solicitud.

| Columna | Tipo | Reglas | Descripción |
|---|---|---|---|
| `id_intervencion` | `BIGINT` | PK; NN; IDENTITY | Identificador de la intervención. |
| `fecha_inicio` | `DATE` | NN | Fecha de inicio. |
| `fecha_fin` | `DATE` | Admite NULL | Fecha de finalización. |
| `tipo_intervencion` | `VARCHAR(40)` | NN | Tipo de intervención. |
| `descripcion` | `VARCHAR(500)` | NN | Descripción. |
| `estado` | `VARCHAR(25)` | NN | Estado. |
| `terremoto_id_terremoto` | `BIGINT` | FK → `terremoto.id_terremoto`; NN | Terremoto. |
| `id_solicitud` | `BIGINT` | FK → `solicitud_atencion.id_solicitud`; NN | Solicitud de atención. |
| `afectacion_id_afectacion` | `BIGINT` | FK → `afectacion.id_afectacion`; NN | Afectación. |

### `intervencion_organizacion` — Organizaciones por intervención

Participación de una organización en una intervención, con su rol.

| Columna | Tipo | Reglas | Descripción |
|---|---|---|---|
| `rol` | `VARCHAR(30)` | NN | Rol. |
| `intervencion_id_intervencion` | `BIGINT` | PK; FK → `intervencion.id_intervencion`; NN | Intervención. |
| `organizacion_id_organizacion` | `BIGINT` | PK; FK → `organizacion.id_organizacion`; NN | Organización. |

## Restricciones de dominio relevantes

| Entidad | Regla |
|---|---|
| `afectacion` | El discriminador solo admite `Afectacion_Vivienda` o `Afectacion_Infraestructura`; los disparadores comprueban que el subtipo coincida. |
| `alojamiento_temporal` | La capacidad debe ser mayor que cero. |
| `estancia_alojamiento` | La fecha de salida no puede ser anterior a la fecha de ingreso y debe indicarse exactamente un destinatario: hogar o persona. |
| `habitacion` | `arrendable_independiente` solo admite `0` o `1`. |
| `integrante_hogar`, `ocupacion_habitacion`, `ocupacion_vivienda` | La fecha final, si se registra, no puede ser anterior a la inicial. |
| `propiedad_vivienda` | El porcentaje de propiedad debe ser mayor que cero y menor o igual a 100. |
| `terremoto` | La magnitud puede ser nula o estar entre 0 y 10. |
| `tramo_infraestructura` | Si se informan ambos kilómetros, el final debe ser igual o mayor que el inicial. |

La definición completa y ejecutable de claves, disparadores y restricciones está en [`sql/00_proyecto_completo.sql`](../sql/00_proyecto_completo.sql).

### `usuario_app` — Cuentas de acceso

Tabla adicional de seguridad. No aparece en el CRUD general; las cuentas se administran desde la sección **Usuarios y roles**.

| Columna | Tipo | Reglas | Descripción |
|---|---|---|---|
| `id_usuario` | `BIGINT` | PK; NN; IDENTITY | Identificador de la cuenta. |
| `nombre_usuario` | `VARCHAR(50)` | NN; UQ | Nombre de inicio de sesión, normalizado a minúsculas. |
| `password_hash` | `VARCHAR(255)` | NN | Hash de contraseña generado por Werkzeug; nunca se muestra en la interfaz. |
| `rol` | `VARCHAR(20)` | NN; CK | Perfil `administrador`, `encargado` o `persona`. |
| `persona_id_persona` | `BIGINT` | FK → `persona.id_persona`; UQ; admite NULL | Persona propietaria de una cuenta; obligatoria para el perfil `persona`. |
| `activo` | `BOOLEAN` | NN; predeterminado `TRUE` | Permite deshabilitar temporalmente una cuenta. |
| `creado_en` | `TIMESTAMPTZ` | NN; predeterminado `CURRENT_TIMESTAMP` | Momento en que se creó la cuenta. |

### `admin_bootstrap_state` — Uso de la clave especial

Tabla técnica que registra el único uso permitido de la clave de alta para crear una cuenta administradora independiente. No forma parte de las entidades funcionales del MER ni aparece en el CRUD general.

| Columna | Tipo | Reglas | Descripción |
|---|---|---|---|
| `singleton` | `BOOLEAN` | PK; predeterminado `TRUE`; CK | Permite como máximo un registro de alta completada. |
| `admin_id` | `BIGINT` | FK → `usuario_app.id_usuario`; UQ; NN | Cuenta administradora independiente creada mediante la clave de un solo uso. |
| `used_at` | `TIMESTAMPTZ` | NN; predeterminado `CURRENT_TIMESTAMP` | Momento en que se consumió la clave especial. |

