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


SELECT *
FROM vista_censos_terremoto
ORDER BY id_terremoto, municipio;



-- VISTA 2: PERSONAS CENSADAS
-- Relaciona Persona, Registro_Censal_Persona,
-- Visita_Censo y Censo.

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


-- VISTA 3: VIVIENDAS POR MUNICIPIO
-- Relaciona Vivienda, Edificacion, Sector y Municipio.

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


-- VISTA 4: AFECTACIONES EN VIVIENDAS
-- Relaciona Afectacion_Vivienda, Afectacion,
-- Vivienda y Edificacion.

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


-- VISTA 5: NECESIDADES DE LOS HOGARES
-- Relaciona Necesidad, Hogar y Terremoto.

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


-- VISTA 6: INTERVENCIONES Y ORGANIZACIONES
-- Relaciona Intervencion_Organizacion,
-- Intervencion y Organizacion.

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



-- CONSULTA DE PRUEBA VISTAS 
SELECT table_name AS nombre_vista
FROM information_schema.views
WHERE table_schema = 'public'
ORDER BY table_name;

SELECT * FROM vista_personas_censadas LIMIT 5;
SELECT * FROM vista_viviendas_municipio LIMIT 5;
SELECT * FROM vista_afectaciones_vivienda LIMIT 5;
SELECT * FROM vista_necesidades_hogar LIMIT 5;
SELECT * FROM vista_intervenciones_organizacion LIMIT 5;
