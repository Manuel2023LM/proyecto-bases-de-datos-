-- Seis vistas de consulta; cada una integra al menos tres tablas.
BEGIN;
SET LOCAL client_encoding TO 'UTF8';
SET LOCAL search_path TO censo_terremoto,public;
CREATE OR REPLACE VIEW vista_censos_terremoto AS
SELECT
    t.id_terremoto,
    t.fecha_hora,
    t.magnitud,
    m.nombre AS municipio,
    c.id_censo,
    c.estado AS estado_censo
FROM censo c
INNER JOIN terremoto_municipio tm
    ON c.id_municipio = tm.municipio_id_municipio
    AND c.id_terremoto = tm.terremoto_id_terremoto
INNER JOIN terremoto t
    ON tm.terremoto_id_terremoto = t.id_terremoto
INNER JOIN municipio m
    ON tm.municipio_id_municipio = m.id_municipio;

CREATE OR REPLACE VIEW vista_personas_censadas AS
SELECT
    p.id_persona,
    p.nombres,
    p.apellidos,
    p.numero_documento,
    rc.fecha_registro,
    v.id_visita,
    c.id_censo
FROM persona p
INNER JOIN registro_censal_persona rc
    ON p.id_persona = rc.persona_id_persona
INNER JOIN visita_censo v
    ON rc.visita_censo_id_visita = v.id_visita
INNER JOIN censo c
    ON v.censo_id_censo = c.id_censo;

CREATE OR REPLACE VIEW vista_viviendas_municipio AS
SELECT
    v.id_vivienda,
    v.tipo_vivienda,
    v.numero_unidad,
    e.direccion,
    s.nombre AS sector,
    m.nombre AS municipio
FROM vivienda v
INNER JOIN edificacion e
    ON v.edificacion_id_edificacion = e.id_edificacion
INNER JOIN sector s
    ON e.sector_id_sector = s.id_sector
INNER JOIN municipio m
    ON s.municipio_id_municipio = m.id_municipio;

CREATE OR REPLACE VIEW vista_afectaciones_vivienda AS
SELECT
    a.id_afectacion,
    a.fecha_registro,
    a.estado,
    v.id_vivienda,
    v.tipo_vivienda,
    e.direccion
FROM afectacion_vivienda av
INNER JOIN afectacion a
    ON av.id_afectacion = a.id_afectacion
INNER JOIN vivienda v
    ON av.vivienda_id_vivienda = v.id_vivienda
INNER JOIN edificacion e
    ON v.edificacion_id_edificacion = e.id_edificacion;

CREATE OR REPLACE VIEW vista_necesidades_hogar AS
SELECT
    n.id_necesidad,
    n.tipo_necesidad,
    n.prioridad,
    n.estado,
    h.id_hogar,
    t.id_terremoto,
    t.magnitud
FROM necesidad n
INNER JOIN hogar h
    ON n.hogar_id_hogar = h.id_hogar
INNER JOIN terremoto t
    ON n.terremoto_id_terremoto = t.id_terremoto;

CREATE OR REPLACE VIEW vista_intervenciones_organizacion AS
SELECT
    i.id_intervencion,
    i.tipo_intervencion,
    i.estado,
    o.nombre AS organizacion,
    o.tipo_organizacion,
    io.rol
FROM intervencion_organizacion io
INNER JOIN intervencion i
    ON io.intervencion_id_intervencion = i.id_intervencion
INNER JOIN organizacion o
    ON io.organizacion_id_organizacion = o.id_organizacion;
COMMIT;
