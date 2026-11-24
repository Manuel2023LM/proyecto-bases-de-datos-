-- CENSO HABITACIONAL Y POBLACIONAL POR AFECTACION DE UN TERREMOTO
-- PostgreSQL - Conversion del DDL Oracle 21c exportado el 2026-11-24.
-- Mantiene 36 tablas, columnas, PK, FK, UNIQUE y CHECK del archivo fuente.
-- Las tablas/columnas originales quedan sin comillas; PostgreSQL normaliza
-- los identificadores sin comillas a minusculas.
--
-- INSTRUCCIONES:
-- 1. Abrir DBeaver y conectarse a una base de datos PostgreSQL VACIA.
-- 2. Ejecutar el ARCHIVO COMPLETO como script SQL en la base elegida.
-- 3. Este archivo NO crea la base de datos, usuarios, vistas ni datos de prueba.
-- 4. Los identificadores NUMERIC se insertan manualmente: el modelo original
--    no definia secuencias ni columnas IDENTITY/autoincrementales.
-- 5. No usar sobre una base con estas tablas ya creadas sin respaldo.
--
-- Cambios de compatibilidad: VARCHAR2(n) -> VARCHAR(n); NUMBER -> NUMERIC.
-- Se conservan DATE y TIMESTAMP. Los triggers Oracle se reescribieron
-- como funciones y triggers PL/pgSQL en PostgreSQL.

BEGIN;

-- ===== TABLAS Y RESTRICCIONES ORIGINALES =====

CREATE TABLE Afectacion 
    ( 
     id_afectacion           NUMERIC  NOT NULL , 
     fecha_registro          DATE  NOT NULL , 
     descripcion_general     VARCHAR(500)  NOT NULL , 
     estado                  VARCHAR(30)  NOT NULL , 
     Terremoto_id_terremoto  NUMERIC  NOT NULL , 
     Reporte_Dano_id_reporte NUMERIC , 
     tipo_afectacion         VARCHAR(26)  NOT NULL 
    ) 
;

ALTER TABLE Afectacion 
    ADD CONSTRAINT CH_INH_Afectacion 
    CHECK (tipo_afectacion IN ('Afectacion_Infraestructura', 'Afectacion_Vivienda')) 
;

ALTER TABLE Afectacion 
    ADD CONSTRAINT Afectacion_PK PRIMARY KEY ( id_afectacion ) ;

CREATE TABLE Afectacion_Infraestructura 
    ( 
     id_afectacion                  NUMERIC  NOT NULL , 
     observaciones                  VARCHAR(300) , 
     id_infraestructura             NUMERIC  NOT NULL , 
     Tramo_Infraestructura_id_tramo NUMERIC  NOT NULL 
    ) 
;

ALTER TABLE Afectacion_Infraestructura 
    ADD CONSTRAINT Afectacion_Infraestructura_PK PRIMARY KEY ( id_afectacion ) ;

CREATE TABLE Afectacion_Persona 
    ( 
     id_afectacion_persona  NUMERIC  NOT NULL , 
     situacion              VARCHAR(30) , 
     condicion_presencia    VARCHAR(20) , 
     desplazado             NUMERIC , 
     fecha_registro         DATE  NOT NULL , 
     observaciones          VARCHAR(500) , 
     Persona_id_persona     NUMERIC  NOT NULL , 
     Terremoto_id_terremoto NUMERIC  NOT NULL , 
     Municipio_id_municipio NUMERIC 
    ) 
;

ALTER TABLE Afectacion_Persona 
    ADD CONSTRAINT Afectacion_Persona_PK PRIMARY KEY ( id_afectacion_persona ) ;

CREATE TABLE Afectacion_Vivienda 
    ( 
     id_afectacion        NUMERIC  NOT NULL , 
     observaciones        VARCHAR(300) , 
     Vivienda_id_vivienda NUMERIC  NOT NULL 
    ) 
;

ALTER TABLE Afectacion_Vivienda 
    ADD CONSTRAINT Afectacion_Vivienda_PK PRIMARY KEY ( id_afectacion ) ;

CREATE TABLE Alojamiento_Temporal 
    ( 
     id_alojamiento         NUMERIC  NOT NULL , 
     nombre                 VARCHAR(100)  NOT NULL , 
     direccion              VARCHAR(150)  NOT NULL , 
     capacidad_personas     NUMERIC  NOT NULL , 
     estado                 VARCHAR(30)  NOT NULL , 
     Municipio_id_municipio NUMERIC  NOT NULL 
    ) 
;

ALTER TABLE Alojamiento_Temporal 
    ADD CONSTRAINT Alojamiento_Temporal_CK_1 
    CHECK (capacidad_personas > 0)
;
ALTER TABLE Alojamiento_Temporal 
    ADD CONSTRAINT Alojamiento_Temporal_PK PRIMARY KEY ( id_alojamiento ) ;

CREATE TABLE Censo 
    ( 
     id_censo     NUMERIC  NOT NULL , 
     fecha_inicio DATE  NOT NULL , 
     fecha_fin    DATE , 
     estado       VARCHAR(20)  NOT NULL , 
     id_municipio NUMERIC  NOT NULL , 
     id_terremoto NUMERIC  NOT NULL 
    ) 
;

ALTER TABLE Censo 
    ADD CONSTRAINT Censo_PK PRIMARY KEY ( id_censo ) ;

CREATE TABLE Consecuencia_Afectacion 
    ( 
     id_consecuencia          NUMERIC  NOT NULL , 
     tipo_consecuencia        VARCHAR(40)  NOT NULL , 
     descripcion              VARCHAR(500)  NOT NULL , 
     fecha_inicio             DATE  NOT NULL , 
     fecha_fin                DATE , 
     estado                   VARCHAR(20)  NOT NULL , 
     Afectacion_id_afectacion NUMERIC  NOT NULL 
    ) 
;

ALTER TABLE Consecuencia_Afectacion 
    ADD CONSTRAINT Consecuencia_Afectacion_PK PRIMARY KEY ( id_consecuencia ) ;

CREATE TABLE Departamento 
    ( 
     id_departamento NUMERIC  NOT NULL , 
     nombre          VARCHAR(60) , 
     codigo_dane     VARCHAR(2)  NOT NULL 
    ) 
;

ALTER TABLE Departamento 
    ADD CONSTRAINT Departamento_PK PRIMARY KEY ( id_departamento ) ;

ALTER TABLE Departamento 
    ADD CONSTRAINT Departamento_CodigoDane_UK UNIQUE ( codigo_dane ) ;

CREATE TABLE Edificacion 
    ( 
     id_edificacion   NUMERIC  NOT NULL , 
     direccion        VARCHAR(150) , 
     numero_pisos     NUMERIC , 
     observaciones    VARCHAR(300) , 
     Sector_id_sector NUMERIC  NOT NULL 
    ) 
;

ALTER TABLE Edificacion 
    ADD CONSTRAINT Edificacion_PK PRIMARY KEY ( id_edificacion ) ;

CREATE TABLE Estancia_Alojamiento 
    ( 
     id_estancia            NUMERIC  NOT NULL , 
     fecha_ingreso          DATE  NOT NULL , 
     fecha_salida           DATE , 
     observaciones          VARCHAR(300) , 
     id_alojamiento         NUMERIC  NOT NULL , 
     Terremoto_id_terremoto NUMERIC  NOT NULL , 
     Hogar_id_hogar         NUMERIC , 
     Persona_id_persona     NUMERIC 
    ) 
;

ALTER TABLE Estancia_Alojamiento 
    ADD CONSTRAINT Estancia_Alojamiento_CK_1 
    CHECK (fecha_salida IS NULL OR fecha_salida >= fecha_ingreso)
;
ALTER TABLE Estancia_Alojamiento 
    ADD CONSTRAINT Estancia_Alojamiento_PK PRIMARY KEY ( id_estancia ) ;

CREATE TABLE Evidencia 
    ( 
     id_evidencia             NUMERIC  NOT NULL , 
     tipo_evidencia           VARCHAR(30)  NOT NULL , 
     ruta_archivo             VARCHAR(300)  NOT NULL , 
     fecha_registro           DATE  NOT NULL , 
     descripcion              VARCHAR(300) , 
     Reporte_Dano_id_reporte  NUMERIC , 
     Inspeccion_id_inspeccion NUMERIC 
    ) 
;

ALTER TABLE Evidencia 
    ADD CONSTRAINT Evidencia_PK PRIMARY KEY ( id_evidencia ) ;

CREATE TABLE Habitacion 
    ( 
     id_habitacion            NUMERIC  NOT NULL , 
     numero_habitacion        VARCHAR(20)  NOT NULL , 
     uso                      VARCHAR(30) , 
     arrendable_independiente NUMERIC  NOT NULL , 
     Vivienda_id_vivienda     NUMERIC  NOT NULL 
    ) 
;

ALTER TABLE Habitacion 
    ADD CONSTRAINT Habitacion_CK_1 
    CHECK (arrendable_independiente IN (0, 1))
;
ALTER TABLE Habitacion 
    ADD CONSTRAINT Habitacion_PK PRIMARY KEY ( id_habitacion ) ;

CREATE TABLE Hogar 
    ( 
     id_hogar       NUMERIC  NOT NULL , 
     fecha_registro DATE  NOT NULL , 
     observaciones  VARCHAR(300) 
    ) 
;

ALTER TABLE Hogar 
    ADD CONSTRAINT Hogar_PK PRIMARY KEY ( id_hogar ) ;

CREATE TABLE Infraestructura 
    ( 
     id_infraestructura   NUMERIC  NOT NULL , 
     nombre               VARCHAR(100)  NOT NULL , 
     tipo_infraestructura VARCHAR(40)  NOT NULL , 
     descripcion          VARCHAR(500) , 
     estado_operativo     VARCHAR(30) 
    ) 
;

ALTER TABLE Infraestructura 
    ADD CONSTRAINT Infraestructura_PK PRIMARY KEY ( id_infraestructura ) ;

CREATE TABLE Infraestructura_Municipio 
    ( 
     tipo_vinculo           VARCHAR(30)  NOT NULL , 
     observaciones          VARCHAR(300) , 
     id_infraestructura     NUMERIC  NOT NULL , 
     Municipio_id_municipio NUMERIC  NOT NULL 
    ) 
;

ALTER TABLE Infraestructura_Municipio 
    ADD CONSTRAINT Infraestructura_Municipio_PK PRIMARY KEY ( id_infraestructura, Municipio_id_municipio ) ;

CREATE TABLE Inspeccion 
    ( 
     id_inspeccion              NUMERIC  NOT NULL , 
     fecha_inspeccion           TIMESTAMP  NOT NULL , 
     nivel_dano                 VARCHAR(20) , 
     resultado                  VARCHAR(300)  NOT NULL , 
     observaciones              VARCHAR(500) , 
     Afectacion_id_afectacion   NUMERIC  NOT NULL , 
     Personal_Campo_id_personal NUMERIC  NOT NULL 
    ) 
;

ALTER TABLE Inspeccion 
    ADD CONSTRAINT Inspeccion_PK PRIMARY KEY ( id_inspeccion ) ;

CREATE TABLE Integrante_Hogar 
    ( 
     id_integrante_hogar NUMERIC  NOT NULL , 
     fecha_inicio        DATE  NOT NULL , 
     fecha_fin           DATE , 
     parentesco          VARCHAR(30) , 
     Persona_id_persona  NUMERIC  NOT NULL , 
     Hogar_id_hogar      NUMERIC  NOT NULL 
    ) 
;

ALTER TABLE Integrante_Hogar 
    ADD CONSTRAINT Integrante_Hogar_CK_1 
    CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
;
ALTER TABLE Integrante_Hogar 
    ADD CONSTRAINT Integrante_Hogar_PK PRIMARY KEY ( id_integrante_hogar ) ;

CREATE TABLE Intervencion 
    ( 
     id_intervencion          NUMERIC  NOT NULL , 
     fecha_inicio             DATE  NOT NULL , 
     fecha_fin                DATE , 
     tipo_intervencion        VARCHAR(40)  NOT NULL , 
     descripcion              VARCHAR(500)  NOT NULL , 
     estado                   VARCHAR(25)  NOT NULL , 
     Terremoto_id_terremoto   NUMERIC  NOT NULL , 
     id_solicitud             NUMERIC  NOT NULL , 
     Afectacion_id_afectacion NUMERIC  NOT NULL 
    ) 
;

ALTER TABLE Intervencion 
    ADD CONSTRAINT Intervencion_PK PRIMARY KEY ( id_intervencion ) ;

CREATE TABLE Intervencion_Organizacion 
    ( 
     rol                          VARCHAR(30)  NOT NULL , 
     Intervencion_id_intervencion NUMERIC  NOT NULL , 
     Organizacion_id_organizacion NUMERIC  NOT NULL 
    ) 
;

ALTER TABLE Intervencion_Organizacion 
    ADD CONSTRAINT Intervencion_Organizacion_PK PRIMARY KEY ( Intervencion_id_intervencion, Organizacion_id_organizacion ) ;

CREATE TABLE Municipio 
    ( 
     id_municipio                 NUMERIC  NOT NULL , 
     nombre                       VARCHAR(60)  NOT NULL , 
     codigo_dane                  VARCHAR(5)  NOT NULL , 
     Departamento_id_departamento NUMERIC  NOT NULL 
    ) 
;

ALTER TABLE Municipio 
    ADD CONSTRAINT Municipio_PK PRIMARY KEY ( id_municipio ) ;

ALTER TABLE Municipio 
    ADD CONSTRAINT Municipio_CodigoDane_UK UNIQUE ( codigo_dane ) ;

CREATE TABLE Necesidad 
    ( 
     id_necesidad           NUMERIC  NOT NULL , 
     tipo_necesidad         VARCHAR(40)  NOT NULL , 
     descripcion            VARCHAR(500) , 
     prioridad              VARCHAR(20)  NOT NULL , 
     fecha_identificacion   DATE  NOT NULL , 
     estado                 VARCHAR(20)  NOT NULL , 
     Hogar_id_hogar         NUMERIC  NOT NULL , 
     Terremoto_id_terremoto NUMERIC  NOT NULL 
    ) 
;

ALTER TABLE Necesidad 
    ADD CONSTRAINT Necesidad_PK PRIMARY KEY ( id_necesidad ) ;

CREATE TABLE Ocupacion_Habitacion 
    ( 
     id_ocupacion_habitacion  NUMERIC  NOT NULL , 
     fecha_inicio             DATE  NOT NULL , 
     fecha_fin                DATE , 
     Hogar_id_hogar           NUMERIC  NOT NULL , 
     Habitacion_id_habitacion NUMERIC  NOT NULL 
    ) 
;

ALTER TABLE Ocupacion_Habitacion 
    ADD CONSTRAINT Ocupacion_Habitacion_CK_1 
    CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
;
ALTER TABLE Ocupacion_Habitacion 
    ADD CONSTRAINT Ocupacion_Habitacion_PK PRIMARY KEY ( id_ocupacion_habitacion ) ;

CREATE TABLE Ocupacion_Vivienda 
    ( 
     id_ocupacion         NUMERIC  NOT NULL , 
     fecha_inicio         DATE  NOT NULL , 
     fecha_fin            DATE , 
     tipo_ocupacion       VARCHAR(30)  NOT NULL , 
     Hogar_id_hogar       NUMERIC  NOT NULL , 
     Vivienda_id_vivienda NUMERIC  NOT NULL 
    ) 
;

ALTER TABLE Ocupacion_Vivienda 
    ADD CONSTRAINT Ocupacion_Vivienda_CK_1 
    CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
;
ALTER TABLE Ocupacion_Vivienda 
    ADD CONSTRAINT Ocupacion_Vivienda_PK PRIMARY KEY ( id_ocupacion ) ;

CREATE TABLE Organizacion 
    ( 
     id_organizacion   NUMERIC  NOT NULL , 
     nombre            VARCHAR(100)  NOT NULL , 
     tipo_organizacion VARCHAR(40)  NOT NULL , 
     telefono          VARCHAR(20) , 
     correo            VARCHAR(100) 
    ) 
;

ALTER TABLE Organizacion 
    ADD CONSTRAINT Organizacion_PK PRIMARY KEY ( id_organizacion ) ;

CREATE TABLE Persona 
    ( 
     id_persona       NUMERIC  NOT NULL , 
     tipo_documento   VARCHAR(10) , 
     numero_documento VARCHAR(20) , 
     nombres          VARCHAR(80)  NOT NULL , 
     apellidos        VARCHAR(80) , 
     fecha_nacimiento DATE , 
     telefono         VARCHAR(20) 
    ) 
;

ALTER TABLE Persona 
    ADD CONSTRAINT Persona_PK PRIMARY KEY ( id_persona ) ;

ALTER TABLE Persona 
    ADD CONSTRAINT Persona_Documento_UK UNIQUE ( tipo_documento , numero_documento ) ;

CREATE TABLE Personal_Campo 
    ( 
     id_personal                  NUMERIC  NOT NULL , 
     nombres                      VARCHAR(20)  NOT NULL , 
     apellidos                    VARCHAR(80)  NOT NULL , 
     cargo                        VARCHAR(60) , 
     telefono                     VARCHAR(20) , 
     Organizacion_id_organizacion NUMERIC  NOT NULL 
    ) 
;

ALTER TABLE Personal_Campo 
    ADD CONSTRAINT Personal_Campo_PK PRIMARY KEY ( id_personal ) ;

CREATE TABLE Propiedad_Vivienda 
    ( 
     id_propiedad         NUMERIC  NOT NULL , 
     fecha_inicio         DATE , 
     fecha_fin            DATE , 
     porcentaje_propiedad NUMERIC , 
     Persona_id_persona   NUMERIC  NOT NULL , 
     Vivienda_id_vivienda NUMERIC  NOT NULL 
    ) 
;

ALTER TABLE Propiedad_Vivienda 
    ADD CONSTRAINT Propiedad_Porcentaje_CK 
    CHECK (porcentaje_propiedad > 0 AND porcentaje_propiedad <= 100)
;
ALTER TABLE Propiedad_Vivienda 
    ADD CONSTRAINT Propiedad_Vivienda_PK PRIMARY KEY ( id_propiedad ) ;

CREATE TABLE Registro_Censal_Persona 
    ( 
     id_registro            NUMERIC  NOT NULL , 
     fecha_registro         TIMESTAMP  NOT NULL , 
     observaciones          VARCHAR(500) , 
     Visita_Censo_id_visita NUMERIC  NOT NULL , 
     Persona_id_persona     NUMERIC  NOT NULL 
    ) 
;

ALTER TABLE Registro_Censal_Persona 
    ADD CONSTRAINT Registro_Censal_Persona_PK PRIMARY KEY ( id_registro ) ;

ALTER TABLE Registro_Censal_Persona 
    ADD CONSTRAINT Registro_Censal_UK UNIQUE ( Persona_id_persona , Visita_Censo_id_visita ) ;

CREATE TABLE Reporte_Dano 
    ( 
     id_reporte             NUMERIC  NOT NULL , 
     fecha_reporte          TIMESTAMP  NOT NULL , 
     tipo_fuente            VARCHAR(30)  NOT NULL , 
     descripcion            VARCHAR(500)  NOT NULL , 
     estado_verificacion    VARCHAR(20)  NOT NULL , 
     Terremoto_id_terremoto NUMERIC  NOT NULL 
    ) 
;

ALTER TABLE Reporte_Dano 
    ADD CONSTRAINT Reporte_Dano_PK PRIMARY KEY ( id_reporte ) ;

CREATE TABLE Sector 
    ( 
     id_sector              NUMERIC  NOT NULL , 
     nombre                 VARCHAR(80)  NOT NULL , 
     tipo_sector            VARCHAR(20)  NOT NULL , 
     Municipio_id_municipio NUMERIC  NOT NULL 
    ) 
;

ALTER TABLE Sector 
    ADD CONSTRAINT Sector_PK PRIMARY KEY ( id_sector ) ;

CREATE TABLE Solicitud_Atencion 
    ( 
     id_solicitud           NUMERIC  NOT NULL , 
     fecha_solicitud        DATE  NOT NULL , 
     estado                 VARCHAR(25)  NOT NULL , 
     observaciones          VARCHAR(500) , 
     Necesidad_id_necesidad NUMERIC  NOT NULL 
    ) 
;

ALTER TABLE Solicitud_Atencion 
    ADD CONSTRAINT Solicitud_Atencion_PK PRIMARY KEY ( id_solicitud ) ;

CREATE TABLE Terremoto 
    ( 
     id_terremoto   NUMERIC  NOT NULL , 
     fecha_hora     TIMESTAMP  NOT NULL , 
     magnitud       NUMERIC , 
     profundidad_km NUMERIC , 
     descripcion    VARCHAR(500) 
    ) 
;

ALTER TABLE Terremoto 
    ADD CONSTRAINT Terremoto_PK PRIMARY KEY ( id_terremoto ) ;

CREATE TABLE Terremoto_Municipio 
    ( 
     fecha_registro         DATE  NOT NULL , 
     observaciones          VARCHAR(300) , 
     Municipio_id_municipio NUMERIC  NOT NULL , 
     Terremoto_id_terremoto NUMERIC  NOT NULL 
    ) 
;

ALTER TABLE Terremoto_Municipio 
    ADD CONSTRAINT Terremoto_Municipio_PK PRIMARY KEY ( Municipio_id_municipio, Terremoto_id_terremoto ) ;

CREATE TABLE Tramo_Infraestructura 
    ( 
     id_tramo           NUMERIC  NOT NULL , 
     codigo_tramo       VARCHAR(30)  NOT NULL , 
     km_inicio          NUMERIC , 
     km_fin             NUMERIC , 
     descripcion        VARCHAR(300) , 
     id_infraestructura NUMERIC  NOT NULL 
    ) 
;

ALTER TABLE Tramo_Infraestructura 
    ADD CONSTRAINT Tramo_Infraestructura_PK PRIMARY KEY ( id_tramo ) ;

CREATE TABLE Visita_Censo 
    ( 
     id_visita            NUMERIC  NOT NULL , 
     fecha_visita         TIMESTAMP  NOT NULL , 
     resultado            VARCHAR(30)  NOT NULL , 
     observaciones        VARCHAR(500) , 
     ubicacion_referencia VARCHAR(150) , 
     Censo_id_censo       NUMERIC  NOT NULL , 
     Vivienda_id_vivienda NUMERIC 
    ) 
;

ALTER TABLE Visita_Censo 
    ADD CONSTRAINT Visita_Censo_PK PRIMARY KEY ( id_visita ) ;

CREATE TABLE Vivienda 
    ( 
     id_vivienda                NUMERIC  NOT NULL , 
     numero_unidad              VARCHAR(20) , 
     tipo_vivienda              VARCHAR(30)  NOT NULL , 
     observaciones              VARCHAR(300) , 
     Edificacion_id_edificacion NUMERIC  NOT NULL 
    ) 
;

ALTER TABLE Vivienda 
    ADD CONSTRAINT Vivienda_PK PRIMARY KEY ( id_vivienda ) ;

ALTER TABLE Afectacion_Persona 
    ADD CONSTRAINT Afectacion_Persona_Persona_FK FOREIGN KEY 
    ( 
     Persona_id_persona
    ) 
    REFERENCES Persona 
    ( 
     id_persona
    ) 
;

ALTER TABLE Afectacion 
    ADD CONSTRAINT Afectacion_Reporte_Dano_FK FOREIGN KEY 
    ( 
     Reporte_Dano_id_reporte
    ) 
    REFERENCES Reporte_Dano 
    ( 
     id_reporte
    ) 
;

ALTER TABLE Afectacion 
    ADD CONSTRAINT Afectacion_Terremoto_FK FOREIGN KEY 
    ( 
     Terremoto_id_terremoto
    ) 
    REFERENCES Terremoto 
    ( 
     id_terremoto
    ) 
;

ALTER TABLE Censo 
    ADD CONSTRAINT Censo_Terremoto_Municipio_FK FOREIGN KEY 
    ( 
     id_municipio,
     id_terremoto
    ) 
    REFERENCES Terremoto_Municipio 
    ( 
     Municipio_id_municipio,
     Terremoto_id_terremoto
    ) 
;

ALTER TABLE Edificacion 
    ADD CONSTRAINT Edificacion_Sector_FK FOREIGN KEY 
    ( 
     Sector_id_sector
    ) 
    REFERENCES Sector 
    ( 
     id_sector
    ) 
;

ALTER TABLE Estancia_Alojamiento 
    ADD CONSTRAINT Estancia_Alojamiento_Hogar_FK FOREIGN KEY 
    ( 
     Hogar_id_hogar
    ) 
    REFERENCES Hogar 
    ( 
     id_hogar
    ) 
;

ALTER TABLE Evidencia 
    ADD CONSTRAINT Evidencia_Inspeccion_FK FOREIGN KEY 
    ( 
     Inspeccion_id_inspeccion
    ) 
    REFERENCES Inspeccion 
    ( 
     id_inspeccion
    ) 
;

ALTER TABLE Evidencia 
    ADD CONSTRAINT Evidencia_Reporte_Dano_FK FOREIGN KEY 
    ( 
     Reporte_Dano_id_reporte
    ) 
    REFERENCES Reporte_Dano 
    ( 
     id_reporte
    ) 
;

ALTER TABLE Afectacion_Infraestructura 
    ADD CONSTRAINT FK_AfectInfra_Afect FOREIGN KEY 
    ( 
     id_afectacion
    ) 
    REFERENCES Afectacion 
    ( 
     id_afectacion
    ) 
;

ALTER TABLE Afectacion_Infraestructura 
    ADD CONSTRAINT FK_AfectInfra_Infra FOREIGN KEY 
    ( 
     id_infraestructura
    ) 
    REFERENCES Infraestructura 
    ( 
     id_infraestructura
    ) 
;

ALTER TABLE Afectacion_Infraestructura 
    ADD CONSTRAINT FK_AfectInfra_Tramo FOREIGN KEY 
    ( 
     Tramo_Infraestructura_id_tramo
    ) 
    REFERENCES Tramo_Infraestructura 
    ( 
     id_tramo
    ) 
;

ALTER TABLE Afectacion_Persona 
    ADD CONSTRAINT FK_AfectPersona_Municipio FOREIGN KEY 
    ( 
     Municipio_id_municipio
    ) 
    REFERENCES Municipio 
    ( 
     id_municipio
    ) 
;

ALTER TABLE Afectacion_Persona 
    ADD CONSTRAINT FK_AfectPersona_Terremoto FOREIGN KEY 
    ( 
     Terremoto_id_terremoto
    ) 
    REFERENCES Terremoto 
    ( 
     id_terremoto
    ) 
;

ALTER TABLE Afectacion_Vivienda 
    ADD CONSTRAINT FK_AfectViv_Afect FOREIGN KEY 
    ( 
     id_afectacion
    ) 
    REFERENCES Afectacion 
    ( 
     id_afectacion
    ) 
;

ALTER TABLE Afectacion_Vivienda 
    ADD CONSTRAINT FK_AfectViv_Vivienda FOREIGN KEY 
    ( 
     Vivienda_id_vivienda
    ) 
    REFERENCES Vivienda 
    ( 
     id_vivienda
    ) 
;

ALTER TABLE Alojamiento_Temporal 
    ADD CONSTRAINT FK_AlojTemp_Municipio FOREIGN KEY 
    ( 
     Municipio_id_municipio
    ) 
    REFERENCES Municipio 
    ( 
     id_municipio
    ) 
;

ALTER TABLE Consecuencia_Afectacion 
    ADD CONSTRAINT FK_Consecuencia_Afect FOREIGN KEY 
    ( 
     Afectacion_id_afectacion
    ) 
    REFERENCES Afectacion 
    ( 
     id_afectacion
    ) 
;

ALTER TABLE Estancia_Alojamiento 
    ADD CONSTRAINT FK_Estancia_AlojTemp FOREIGN KEY 
    ( 
     id_alojamiento
    ) 
    REFERENCES Alojamiento_Temporal 
    ( 
     id_alojamiento
    ) 
;

ALTER TABLE Estancia_Alojamiento 
    ADD CONSTRAINT FK_Estancia_Persona FOREIGN KEY 
    ( 
     Persona_id_persona
    ) 
    REFERENCES Persona 
    ( 
     id_persona
    ) 
;

ALTER TABLE Estancia_Alojamiento 
    ADD CONSTRAINT FK_Estancia_Terremoto FOREIGN KEY 
    ( 
     Terremoto_id_terremoto
    ) 
    REFERENCES Terremoto 
    ( 
     id_terremoto
    ) 
;

ALTER TABLE Infraestructura_Municipio 
    ADD CONSTRAINT FK_InfraMun_Infra FOREIGN KEY 
    ( 
     id_infraestructura
    ) 
    REFERENCES Infraestructura 
    ( 
     id_infraestructura
    ) 
;

ALTER TABLE Infraestructura_Municipio 
    ADD CONSTRAINT FK_InfraMun_Municipio FOREIGN KEY 
    ( 
     Municipio_id_municipio
    ) 
    REFERENCES Municipio 
    ( 
     id_municipio
    ) 
;

ALTER TABLE Intervencion 
    ADD CONSTRAINT FK_Interv_Solicitud FOREIGN KEY 
    ( 
     id_solicitud
    ) 
    REFERENCES Solicitud_Atencion 
    ( 
     id_solicitud
    ) 
;

ALTER TABLE Intervencion_Organizacion 
    ADD CONSTRAINT FK_IntervOrg_Interv FOREIGN KEY 
    ( 
     Intervencion_id_intervencion
    ) 
    REFERENCES Intervencion 
    ( 
     id_intervencion
    ) 
;

ALTER TABLE Intervencion_Organizacion 
    ADD CONSTRAINT FK_IntervOrg_Organiz FOREIGN KEY 
    ( 
     Organizacion_id_organizacion
    ) 
    REFERENCES Organizacion 
    ( 
     id_organizacion
    ) 
;

ALTER TABLE Ocupacion_Habitacion 
    ADD CONSTRAINT FK_OcupHab_Habitacion FOREIGN KEY 
    ( 
     Habitacion_id_habitacion
    ) 
    REFERENCES Habitacion 
    ( 
     id_habitacion
    ) 
;

ALTER TABLE Registro_Censal_Persona 
    ADD CONSTRAINT FK_RegCensal_Persona FOREIGN KEY 
    ( 
     Persona_id_persona
    ) 
    REFERENCES Persona 
    ( 
     id_persona
    ) 
;

ALTER TABLE Registro_Censal_Persona 
    ADD CONSTRAINT FK_RegCensal_Visita FOREIGN KEY 
    ( 
     Visita_Censo_id_visita
    ) 
    REFERENCES Visita_Censo 
    ( 
     id_visita
    ) 
;

ALTER TABLE Solicitud_Atencion 
    ADD CONSTRAINT FK_Solicitud_Necesidad FOREIGN KEY 
    ( 
     Necesidad_id_necesidad
    ) 
    REFERENCES Necesidad 
    ( 
     id_necesidad
    ) 
;

ALTER TABLE Terremoto_Municipio 
    ADD CONSTRAINT FK_TerrMun_Municipio FOREIGN KEY 
    ( 
     Municipio_id_municipio
    ) 
    REFERENCES Municipio 
    ( 
     id_municipio
    ) 
;

ALTER TABLE Terremoto_Municipio 
    ADD CONSTRAINT FK_TerrMun_Terremoto FOREIGN KEY 
    ( 
     Terremoto_id_terremoto
    ) 
    REFERENCES Terremoto 
    ( 
     id_terremoto
    ) 
;

ALTER TABLE Tramo_Infraestructura 
    ADD CONSTRAINT FK_Tramo_Infraestructura FOREIGN KEY 
    ( 
     id_infraestructura
    ) 
    REFERENCES Infraestructura 
    ( 
     id_infraestructura
    ) 
;

ALTER TABLE Habitacion 
    ADD CONSTRAINT Habitacion_Vivienda_FK FOREIGN KEY 
    ( 
     Vivienda_id_vivienda
    ) 
    REFERENCES Vivienda 
    ( 
     id_vivienda
    ) 
;

ALTER TABLE Inspeccion 
    ADD CONSTRAINT Inspeccion_Afectacion_FK FOREIGN KEY 
    ( 
     Afectacion_id_afectacion
    ) 
    REFERENCES Afectacion 
    ( 
     id_afectacion
    ) 
;

ALTER TABLE Inspeccion 
    ADD CONSTRAINT Inspeccion_Personal_Campo_FK FOREIGN KEY 
    ( 
     Personal_Campo_id_personal
    ) 
    REFERENCES Personal_Campo 
    ( 
     id_personal
    ) 
;

ALTER TABLE Integrante_Hogar 
    ADD CONSTRAINT Integrante_Hogar_Hogar_FK FOREIGN KEY 
    ( 
     Hogar_id_hogar
    ) 
    REFERENCES Hogar 
    ( 
     id_hogar
    ) 
;

ALTER TABLE Integrante_Hogar 
    ADD CONSTRAINT Integrante_Hogar_Persona_FK FOREIGN KEY 
    ( 
     Persona_id_persona
    ) 
    REFERENCES Persona 
    ( 
     id_persona
    ) 
;

ALTER TABLE Intervencion 
    ADD CONSTRAINT Intervencion_Afectacion_FK FOREIGN KEY 
    ( 
     Afectacion_id_afectacion
    ) 
    REFERENCES Afectacion 
    ( 
     id_afectacion
    ) 
;

ALTER TABLE Intervencion 
    ADD CONSTRAINT Intervencion_Terremoto_FK FOREIGN KEY 
    ( 
     Terremoto_id_terremoto
    ) 
    REFERENCES Terremoto 
    ( 
     id_terremoto
    ) 
;

ALTER TABLE Municipio 
    ADD CONSTRAINT Municipio_Departamento_FK FOREIGN KEY 
    ( 
     Departamento_id_departamento
    ) 
    REFERENCES Departamento 
    ( 
     id_departamento
    ) 
;

ALTER TABLE Necesidad 
    ADD CONSTRAINT Necesidad_Hogar_FK FOREIGN KEY 
    ( 
     Hogar_id_hogar
    ) 
    REFERENCES Hogar 
    ( 
     id_hogar
    ) 
;

ALTER TABLE Necesidad 
    ADD CONSTRAINT Necesidad_Terremoto_FK FOREIGN KEY 
    ( 
     Terremoto_id_terremoto
    ) 
    REFERENCES Terremoto 
    ( 
     id_terremoto
    ) 
;

ALTER TABLE Ocupacion_Habitacion 
    ADD CONSTRAINT Ocupacion_Habitacion_Hogar_FK FOREIGN KEY 
    ( 
     Hogar_id_hogar
    ) 
    REFERENCES Hogar 
    ( 
     id_hogar
    ) 
;

ALTER TABLE Ocupacion_Vivienda 
    ADD CONSTRAINT Ocupacion_Vivienda_Hogar_FK FOREIGN KEY 
    ( 
     Hogar_id_hogar
    ) 
    REFERENCES Hogar 
    ( 
     id_hogar
    ) 
;

ALTER TABLE Ocupacion_Vivienda 
    ADD CONSTRAINT Ocupacion_Vivienda_Vivienda_FK FOREIGN KEY 
    ( 
     Vivienda_id_vivienda
    ) 
    REFERENCES Vivienda 
    ( 
     id_vivienda
    ) 
;

ALTER TABLE Personal_Campo 
    ADD CONSTRAINT Personal_Campo_Organizacion_FK FOREIGN KEY 
    ( 
     Organizacion_id_organizacion
    ) 
    REFERENCES Organizacion 
    ( 
     id_organizacion
    ) 
;

ALTER TABLE Propiedad_Vivienda 
    ADD CONSTRAINT Propiedad_Vivienda_Persona_FK FOREIGN KEY 
    ( 
     Persona_id_persona
    ) 
    REFERENCES Persona 
    ( 
     id_persona
    ) 
;

ALTER TABLE Propiedad_Vivienda 
    ADD CONSTRAINT Propiedad_Vivienda_Vivienda_FK FOREIGN KEY 
    ( 
     Vivienda_id_vivienda
    ) 
    REFERENCES Vivienda 
    ( 
     id_vivienda
    ) 
;

ALTER TABLE Reporte_Dano 
    ADD CONSTRAINT Reporte_Dano_Terremoto_FK FOREIGN KEY 
    ( 
     Terremoto_id_terremoto
    ) 
    REFERENCES Terremoto 
    ( 
     id_terremoto
    ) 
;

ALTER TABLE Sector 
    ADD CONSTRAINT Sector_Municipio_FK FOREIGN KEY 
    ( 
     Municipio_id_municipio
    ) 
    REFERENCES Municipio 
    ( 
     id_municipio
    ) 
;

ALTER TABLE Visita_Censo 
    ADD CONSTRAINT Visita_Censo_Censo_FK FOREIGN KEY 
    ( 
     Censo_id_censo
    ) 
    REFERENCES Censo 
    ( 
     id_censo
    ) 
;

ALTER TABLE Visita_Censo 
    ADD CONSTRAINT Visita_Censo_Vivienda_FK FOREIGN KEY 
    ( 
     Vivienda_id_vivienda
    ) 
    REFERENCES Vivienda 
    ( 
     id_vivienda
    ) 
;

ALTER TABLE Vivienda 
    ADD CONSTRAINT Vivienda_Edificacion_FK FOREIGN KEY 
    ( 
     Edificacion_id_edificacion
    ) 
    REFERENCES Edificacion 
    ( 
     id_edificacion
    ) 
;

-- ===== VALIDACION DE LOS SUBTIPOS DE AFECTACION =====
-- En el modelo Oracle, dos triggers verificaban el valor del discriminador
-- "tipo_afectacion" al registrar una fila en una tabla hija.
-- PostgreSQL puede reutilizar una sola funcion para ambas tablas.
-- Si el padre no existe, la clave foranea correspondiente dara el error.

CREATE OR REPLACE FUNCTION fn_validar_subtipo_afectacion()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_tipo VARCHAR(26);
BEGIN
    SELECT a.tipo_afectacion
      INTO v_tipo
      FROM afectacion AS a
     WHERE a.id_afectacion = NEW.id_afectacion;

    IF FOUND AND v_tipo IS DISTINCT FROM TG_ARGV[0] THEN
        RAISE EXCEPTION
            'Tipo de afectacion incorrecto: se esperaba %, se encontro %',
            TG_ARGV[0], v_tipo
            USING ERRCODE = '23514';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_afectacion_vivienda_tipo
BEFORE INSERT OR UPDATE OF id_afectacion
ON afectacion_vivienda
FOR EACH ROW
EXECUTE FUNCTION fn_validar_subtipo_afectacion('Afectacion_Vivienda');

CREATE TRIGGER trg_afectacion_infra_tipo
BEFORE INSERT OR UPDATE OF id_afectacion
ON afectacion_infraestructura
FOR EACH ROW
EXECUTE FUNCTION fn_validar_subtipo_afectacion('Afectacion_Infraestructura');

COMMIT;
