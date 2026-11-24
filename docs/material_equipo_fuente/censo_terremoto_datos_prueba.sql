-- DATOS DE PRUEBA FICTICIOS PARA censo_terremoto (PostgreSQL)
-- Basado en las 36 tablas del DDL convertido.
-- REQUISITO: base con las 36 tablas creadas, y UNICAMENTE los dos registros
-- ya insertados por el usuario: departamento (1, Risaralda, 66)
-- y municipio (1, Pereira, 66001).
-- IMPORTANTE: toda la informacion de sismos, personas, danos y direcciones es SIMULADA.
-- Ejecutar como SCRIPT COMPLETO en DBeaver, sobre la base censo_terremoto.
-- Se realiza una comprobacion previa y se utiliza una transaccion.
BEGIN;
DO $verificar$
DECLARE t RECORD; n BIGINT;
BEGIN
 IF (SELECT COUNT(*) FROM departamento) <> 1
    OR NOT EXISTS (SELECT 1 FROM departamento WHERE id_departamento=1 AND nombre='Risaralda' AND codigo_dane='66')
    OR (SELECT COUNT(*) FROM municipio) <> 1
    OR NOT EXISTS (SELECT 1 FROM municipio WHERE id_municipio=1 AND nombre='Pereira' AND codigo_dane='66001' AND departamento_id_departamento=1)
 THEN
    RAISE EXCEPTION 'Estado inesperado en departamento/municipio: se cancela la carga';
 END IF;
 FOR t IN SELECT tablename FROM pg_tables WHERE schemaname='public' AND tablename NOT IN ('departamento','municipio') LOOP
    EXECUTE format('SELECT COUNT(*) FROM public.%I',t.tablename) INTO n;
    IF n <> 0 THEN
       RAISE EXCEPTION 'La tabla % contiene % registros. Se cancela la carga para evitar duplicados',t.tablename,n;
    END IF;
 END LOOP;
END;
$verificar$;

-- departamento: 1 registros nuevos
INSERT INTO departamento (id_departamento, nombre, codigo_dane) VALUES
  (2, 'Quindío', '63');

-- municipio: 5 registros nuevos
INSERT INTO municipio (id_municipio, nombre, codigo_dane, departamento_id_departamento) VALUES
  (2, 'Dosquebradas', '66170', 1),
  (3, 'Santa Rosa de Cabal', '66682', 1),
  (4, 'La Virginia', '66400', 1),
  (5, 'Armenia', '63001', 2),
  (6, 'Marsella', '66440', 1);

-- terremoto: 2 registros nuevos
INSERT INTO terremoto (id_terremoto, fecha_hora, magnitud, profundidad_km, descripcion) VALUES
  (1, '2026-08-15 09:14:00', 5.8, 13, 'SIMULACION: sismo hipotetico zona cafetera'),
  (2, '2026-09-03 16:28:00', 4.9, 9, 'SIMULACION: replica hipotetica');

-- terremoto_municipio: 8 registros nuevos
INSERT INTO terremoto_municipio (fecha_registro, observaciones, municipio_id_municipio, terremoto_id_terremoto) VALUES
  ('2026-08-16', 'Registro territorial de simulacion', 1, 1),
  ('2026-08-16', 'Registro territorial de simulacion', 2, 1),
  ('2026-08-16', 'Registro territorial de simulacion', 3, 1),
  ('2026-08-16', 'Registro territorial de simulacion', 4, 1),
  ('2026-08-16', 'Registro territorial de simulacion', 5, 1),
  ('2026-08-16', 'Registro territorial de simulacion', 6, 1),
  ('2026-09-04', 'Registro territorial de simulacion', 1, 2),
  ('2026-09-04', 'Registro territorial de simulacion', 2, 2);

-- sector: 9 registros nuevos
INSERT INTO sector (id_sector, nombre, tipo_sector, municipio_id_municipio) VALUES
  (1, 'Centro', 'urbano', 1),
  (2, 'Cuba', 'urbano', 1),
  (3, 'La Pradera', 'urbano', 2),
  (4, 'Frailes', 'urbano', 2),
  (5, 'Centro', 'urbano', 3),
  (6, 'El Lembo', 'rural', 3),
  (7, 'Centro', 'urbano', 4),
  (8, 'Centro', 'urbano', 5),
  (9, 'Cabecera', 'urbano', 6);

-- edificacion: 18 registros nuevos
INSERT INTO edificacion (id_edificacion, direccion, numero_pisos, observaciones, sector_id_sector) VALUES
  (1, 'Calle 11 No. 4-20 (ficticia)', 2, 'Direccion de ejemplo no verificable', 1),
  (2, 'Calle 12 No. 5-20 (ficticia)', 3, 'Direccion de ejemplo no verificable', 2),
  (3, 'Calle 13 No. 6-20 (ficticia)', 4, 'Direccion de ejemplo no verificable', 3),
  (4, 'Calle 14 No. 7-20 (ficticia)', 5, 'Direccion de ejemplo no verificable', 4),
  (5, 'Calle 15 No. 8-20 (ficticia)', 1, 'Direccion de ejemplo no verificable', 5),
  (6, 'Calle 16 No. 9-20 (ficticia)', 2, 'Direccion de ejemplo no verificable', 6),
  (7, 'Calle 17 No. 10-20 (ficticia)', 3, 'Direccion de ejemplo no verificable', 7),
  (8, 'Calle 18 No. 11-20 (ficticia)', 4, 'Direccion de ejemplo no verificable', 8),
  (9, 'Calle 19 No. 12-20 (ficticia)', 5, 'Direccion de ejemplo no verificable', 9),
  (10, 'Calle 20 No. 13-20 (ficticia)', 1, 'Direccion de ejemplo no verificable', 1),
  (11, 'Calle 21 No. 14-20 (ficticia)', 2, 'Direccion de ejemplo no verificable', 2),
  (12, 'Calle 22 No. 15-20 (ficticia)', 3, 'Direccion de ejemplo no verificable', 3),
  (13, 'Calle 23 No. 16-20 (ficticia)', 4, 'Direccion de ejemplo no verificable', 4),
  (14, 'Calle 24 No. 17-20 (ficticia)', 5, 'Direccion de ejemplo no verificable', 5),
  (15, 'Calle 25 No. 18-20 (ficticia)', 1, 'Direccion de ejemplo no verificable', 6),
  (16, 'Calle 26 No. 19-20 (ficticia)', 2, 'Direccion de ejemplo no verificable', 7),
  (17, 'Calle 27 No. 20-20 (ficticia)', 3, 'Direccion de ejemplo no verificable', 8),
  (18, 'Calle 28 No. 21-20 (ficticia)', 4, 'Direccion de ejemplo no verificable', 9);

-- vivienda: 26 registros nuevos
INSERT INTO vivienda (id_vivienda, numero_unidad, tipo_vivienda, observaciones, edificacion_id_edificacion) VALUES
  (1, 'U-001', 'apartamento', 'Unidad habitacional ficticia', 1),
  (2, 'U-002', 'apartamento', 'Unidad habitacional ficticia', 2),
  (3, 'U-003', 'casa', 'Unidad habitacional ficticia', 3),
  (4, 'U-004', 'apartamento', 'Unidad habitacional ficticia', 4),
  (5, 'U-005', 'apartamento', 'Unidad habitacional ficticia', 5),
  (6, 'U-006', 'casa', 'Unidad habitacional ficticia', 6),
  (7, 'U-007', 'apartamento', 'Unidad habitacional ficticia', 7),
  (8, 'U-008', 'apartamento', 'Unidad habitacional ficticia', 8),
  (9, 'U-009', 'casa', 'Unidad habitacional ficticia', 9),
  (10, 'U-010', 'apartamento', 'Unidad habitacional ficticia', 10),
  (11, 'U-011', 'apartamento', 'Unidad habitacional ficticia', 11),
  (12, 'U-012', 'casa', 'Unidad habitacional ficticia', 12),
  (13, 'U-013', 'apartamento', 'Unidad habitacional ficticia', 13),
  (14, 'U-014', 'apartamento', 'Unidad habitacional ficticia', 14),
  (15, 'U-015', 'casa', 'Unidad habitacional ficticia', 15),
  (16, 'U-016', 'apartamento', 'Unidad habitacional ficticia', 16),
  (17, 'U-017', 'apartamento', 'Unidad habitacional ficticia', 17),
  (18, 'U-018', 'casa', 'Unidad habitacional ficticia', 18),
  (19, 'U-019', 'apartamento', 'Unidad habitacional ficticia', 1),
  (20, 'U-020', 'apartamento', 'Unidad habitacional ficticia', 2),
  (21, 'U-021', 'casa', 'Unidad habitacional ficticia', 3),
  (22, 'U-022', 'apartamento', 'Unidad habitacional ficticia', 4),
  (23, 'U-023', 'apartamento', 'Unidad habitacional ficticia', 5),
  (24, 'U-024', 'casa', 'Unidad habitacional ficticia', 6),
  (25, 'U-025', 'apartamento', 'Unidad habitacional ficticia', 7),
  (26, 'U-026', 'apartamento', 'Unidad habitacional ficticia', 8);

-- habitacion: 28 registros nuevos
INSERT INTO habitacion (id_habitacion, numero_habitacion, uso, arrendable_independiente, vivienda_id_vivienda) VALUES
  (1, '1', 'dormitorio', 0, 1),
  (2, '2', 'dormitorio', 0, 2),
  (3, '3', 'dormitorio', 0, 3),
  (4, '4', 'estudio', 0, 4),
  (5, '1', 'dormitorio', 0, 5),
  (6, '2', 'dormitorio', 0, 6),
  (7, '3', 'dormitorio', 1, 7),
  (8, '4', 'estudio', 0, 8),
  (9, '1', 'dormitorio', 0, 9),
  (10, '2', 'dormitorio', 0, 10),
  (11, '3', 'dormitorio', 0, 11),
  (12, '4', 'estudio', 0, 12),
  (13, '1', 'dormitorio', 0, 13),
  (14, '2', 'dormitorio', 1, 14),
  (15, '3', 'dormitorio', 0, 15),
  (16, '4', 'estudio', 0, 16),
  (17, '1', 'dormitorio', 0, 17),
  (18, '2', 'dormitorio', 0, 18),
  (19, '3', 'dormitorio', 0, 19),
  (20, '4', 'estudio', 0, 20),
  (21, '1', 'dormitorio', 1, 21),
  (22, '2', 'dormitorio', 0, 22),
  (23, '3', 'dormitorio', 0, 23),
  (24, '4', 'estudio', 0, 24),
  (25, '1', 'dormitorio', 0, 25),
  (26, '2', 'dormitorio', 0, 26),
  (27, '3', 'dormitorio', 0, 1),
  (28, '4', 'estudio', 1, 2);

-- hogar: 21 registros nuevos
INSERT INTO hogar (id_hogar, fecha_registro, observaciones) VALUES
  (1, '2026-08-17', 'Hogar simulado 1'),
  (2, '2026-08-17', 'Hogar simulado 2'),
  (3, '2026-08-17', 'Hogar simulado 3'),
  (4, '2026-08-17', 'Hogar simulado 4'),
  (5, '2026-08-17', 'Hogar simulado 5'),
  (6, '2026-08-17', 'Hogar simulado 6'),
  (7, '2026-08-17', 'Hogar simulado 7'),
  (8, '2026-08-17', 'Hogar simulado 8'),
  (9, '2026-08-17', 'Hogar simulado 9'),
  (10, '2026-08-17', 'Hogar simulado 10'),
  (11, '2026-08-17', 'Hogar simulado 11'),
  (12, '2026-08-17', 'Hogar simulado 12'),
  (13, '2026-08-17', 'Hogar simulado 13'),
  (14, '2026-08-17', 'Hogar simulado 14'),
  (15, '2026-08-17', 'Hogar simulado 15'),
  (16, '2026-08-17', 'Hogar simulado 16'),
  (17, '2026-08-17', 'Hogar simulado 17'),
  (18, '2026-08-17', 'Hogar simulado 18'),
  (19, '2026-08-17', 'Hogar simulado 19'),
  (20, '2026-08-17', 'Hogar simulado 20'),
  (21, '2026-08-17', 'Hogar simulado 21');

-- persona: 56 registros nuevos
INSERT INTO persona (id_persona, tipo_documento, numero_documento, nombres, apellidos, fecha_nacimiento, telefono) VALUES
  (1, 'CC', '1000000001', 'Ana', 'Gómez', '1963-02-02', NULL),
  (2, 'CC', '1000000002', 'Luis', 'Ramírez', '1966-03-03', NULL),
  (3, 'CC', '1000000003', 'María', 'Torres', '1969-04-04', NULL),
  (4, 'CC', '1000000004', 'Carlos', 'López', '1972-05-05', NULL),
  (5, 'TI', '1000000005', 'Diana', 'García', '1975-06-06', NULL),
  (6, 'CC', '1000000006', 'Jorge', 'Ríos', '1978-07-07', NULL),
  (7, 'CC', '1000000007', 'Sofía', 'Restrepo', '1981-08-08', NULL),
  (8, 'CC', '1000000008', 'Miguel', 'Castaño', '1984-09-09', NULL),
  (9, 'CC', '1000000009', 'Laura', 'Morales', '1987-10-10', NULL),
  (10, 'TI', '1000000010', 'Camila', 'Giraldo', '1990-11-11', NULL),
  (11, 'CC', '1000000011', 'Andrés', 'Gómez', '1993-12-12', NULL),
  (12, 'CC', '1000000012', 'Valentina', 'Ramírez', '1996-01-13', NULL),
  (13, 'CC', '1000000013', 'Mateo', 'Torres', '1999-02-14', NULL),
  (14, 'CC', '1000000014', 'Daniela', 'López', '2002-03-15', NULL),
  (15, 'TI', '1000000015', 'Felipe', 'García', '2005-04-16', NULL),
  (16, 'CC', '1000000016', 'Paula', 'Ríos', '1962-05-17', NULL),
  (17, 'CC', '1000000017', 'Alejandro', 'Restrepo', '1965-06-18', NULL),
  (18, 'CC', '1000000018', 'Natalia', 'Castaño', '1968-07-19', NULL),
  (19, 'CC', '1000000019', 'Sebastián', 'Morales', '1971-08-20', NULL),
  (20, 'TI', '1000000020', 'Juliana', 'Giraldo', '1974-09-21', NULL),
  (21, 'CC', '1000000021', 'Ana', 'Gómez', '1977-10-22', NULL),
  (22, 'CC', '1000000022', 'Luis', 'Ramírez', '1980-11-23', NULL),
  (23, 'CC', '1000000023', 'María', 'Torres', '1983-12-24', NULL),
  (24, 'CC', '1000000024', 'Carlos', 'López', '1986-01-25', NULL),
  (25, 'TI', '1000000025', 'Diana', 'García', '1989-02-26', NULL),
  (26, 'CC', '1000000026', 'Jorge', 'Ríos', '1992-03-27', NULL),
  (27, 'CC', '1000000027', 'Sofía', 'Restrepo', '1995-04-01', NULL),
  (28, 'CC', '1000000028', 'Miguel', 'Castaño', '1998-05-02', NULL),
  (29, 'CC', '1000000029', 'Laura', 'Morales', '2001-06-03', NULL),
  (30, 'TI', '1000000030', 'Camila', 'Giraldo', '2004-07-04', NULL),
  (31, 'CC', '1000000031', 'Andrés', 'Gómez', '1961-08-05', NULL),
  (32, 'CC', '1000000032', 'Valentina', 'Ramírez', '1964-09-06', NULL),
  (33, 'CC', '1000000033', 'Mateo', 'Torres', '1967-10-07', NULL),
  (34, 'CC', '1000000034', 'Daniela', 'López', '1970-11-08', NULL),
  (35, 'TI', '1000000035', 'Felipe', 'García', '1973-12-09', NULL),
  (36, 'CC', '1000000036', 'Paula', 'Ríos', '1976-01-10', NULL),
  (37, 'CC', '1000000037', 'Alejandro', 'Restrepo', '1979-02-11', NULL),
  (38, 'CC', '1000000038', 'Natalia', 'Castaño', '1982-03-12', NULL),
  (39, 'CC', '1000000039', 'Sebastián', 'Morales', '1985-04-13', NULL),
  (40, 'TI', '1000000040', 'Juliana', 'Giraldo', '1988-05-14', NULL),
  (41, 'CC', '1000000041', 'Ana', 'Gómez', '1991-06-15', NULL),
  (42, 'CC', '1000000042', 'Luis', 'Ramírez', '1994-07-16', NULL),
  (43, 'CC', '1000000043', 'María', 'Torres', '1997-08-17', NULL),
  (44, 'CC', '1000000044', 'Carlos', 'López', '2000-09-18', NULL),
  (45, 'TI', '1000000045', 'Diana', 'García', '2003-10-19', NULL),
  (46, 'CC', '1000000046', 'Jorge', 'Ríos', '1960-11-20', NULL),
  (47, 'CC', '1000000047', 'Sofía', 'Restrepo', '1963-12-21', NULL),
  (48, 'CC', '1000000048', 'Miguel', 'Castaño', '1966-01-22', NULL),
  (49, 'CC', '1000000049', 'Laura', 'Morales', '1969-02-23', NULL),
  (50, 'TI', '1000000050', 'Camila', 'Giraldo', '1972-03-24', NULL),
  (51, 'CC', '1000000051', 'Andrés', 'Gómez', '1975-04-25', NULL),
  (52, 'CC', '1000000052', 'Valentina', 'Ramírez', '1978-05-26', NULL),
  (53, 'CC', '1000000053', 'Mateo', 'Torres', '1981-06-27', NULL),
  (54, 'CC', '1000000054', 'Daniela', 'López', '1984-07-01', NULL),
  (55, 'TI', '1000000055', 'Felipe', 'García', '1987-08-02', NULL),
  (56, 'CC', '1000000056', 'Paula', 'Ríos', '1990-09-03', NULL);

-- integrante_hogar: 56 registros nuevos
INSERT INTO integrante_hogar (id_integrante_hogar, fecha_inicio, fecha_fin, parentesco, persona_id_persona, hogar_id_hogar) VALUES
  (1, '2025-01-01', NULL, 'jefe', 1, 1),
  (2, '2025-01-01', NULL, 'jefe', 2, 2),
  (3, '2025-01-01', NULL, 'jefe', 3, 3),
  (4, '2025-01-01', NULL, 'jefe', 4, 4),
  (5, '2025-01-01', NULL, 'jefe', 5, 5),
  (6, '2025-01-01', NULL, 'jefe', 6, 6),
  (7, '2025-01-01', NULL, 'jefe', 7, 7),
  (8, '2025-01-01', NULL, 'jefe', 8, 8),
  (9, '2025-01-01', NULL, 'jefe', 9, 9),
  (10, '2025-01-01', NULL, 'jefe', 10, 10),
  (11, '2025-01-01', NULL, 'jefe', 11, 11),
  (12, '2025-01-01', NULL, 'jefe', 12, 12),
  (13, '2025-01-01', NULL, 'jefe', 13, 13),
  (14, '2025-01-01', NULL, 'jefe', 14, 14),
  (15, '2025-01-01', NULL, 'jefe', 15, 15),
  (16, '2025-01-01', NULL, 'jefe', 16, 16),
  (17, '2025-01-01', NULL, 'jefe', 17, 17),
  (18, '2025-01-01', NULL, 'jefe', 18, 18),
  (19, '2025-01-01', NULL, 'jefe', 19, 19),
  (20, '2025-01-01', NULL, 'jefe', 20, 20),
  (21, '2025-01-01', NULL, 'jefe', 21, 21),
  (22, '2025-01-01', NULL, 'pareja', 22, 1),
  (23, '2025-01-01', NULL, 'hijo/a', 23, 2),
  (24, '2025-01-01', NULL, 'pareja', 24, 3),
  (25, '2025-01-01', NULL, 'hijo/a', 25, 4),
  (26, '2025-01-01', NULL, 'pareja', 26, 5),
  (27, '2025-01-01', NULL, 'hijo/a', 27, 6),
  (28, '2025-01-01', NULL, 'pareja', 28, 7),
  (29, '2025-01-01', NULL, 'hijo/a', 29, 8),
  (30, '2025-01-01', NULL, 'pareja', 30, 9),
  (31, '2025-01-01', NULL, 'hijo/a', 31, 10),
  (32, '2025-01-01', NULL, 'pareja', 32, 11),
  (33, '2025-01-01', NULL, 'hijo/a', 33, 12),
  (34, '2025-01-01', NULL, 'pareja', 34, 13),
  (35, '2025-01-01', NULL, 'hijo/a', 35, 14),
  (36, '2025-01-01', NULL, 'pareja', 36, 15),
  (37, '2025-01-01', NULL, 'hijo/a', 37, 16),
  (38, '2025-01-01', NULL, 'pareja', 38, 17),
  (39, '2025-01-01', NULL, 'hijo/a', 39, 18),
  (40, '2025-01-01', NULL, 'pareja', 40, 19),
  (41, '2025-01-01', NULL, 'hijo/a', 41, 20),
  (42, '2025-01-01', NULL, 'pareja', 42, 21),
  (43, '2025-01-01', NULL, 'hijo/a', 43, 1),
  (44, '2025-01-01', NULL, 'pareja', 44, 2),
  (45, '2025-01-01', NULL, 'hijo/a', 45, 3),
  (46, '2025-01-01', NULL, 'pareja', 46, 4),
  (47, '2025-01-01', NULL, 'hijo/a', 47, 5),
  (48, '2025-01-01', NULL, 'pareja', 48, 6),
  (49, '2025-01-01', NULL, 'hijo/a', 49, 7),
  (50, '2025-01-01', NULL, 'pareja', 50, 8),
  (51, '2025-01-01', NULL, 'hijo/a', 51, 9),
  (52, '2025-01-01', NULL, 'pareja', 52, 10),
  (53, '2025-01-01', NULL, 'hijo/a', 53, 11),
  (54, '2025-01-01', NULL, 'pareja', 54, 12),
  (55, '2025-01-01', NULL, 'hijo/a', 55, 13),
  (56, '2025-01-01', NULL, 'pareja', 56, 14);

-- ocupacion_vivienda: 21 registros nuevos
INSERT INTO ocupacion_vivienda (id_ocupacion, fecha_inicio, fecha_fin, tipo_ocupacion, hogar_id_hogar, vivienda_id_vivienda) VALUES
  (1, '2025-01-01', NULL, 'propietario', 1, 1),
  (2, '2025-01-01', NULL, 'propietario', 2, 2),
  (3, '2025-01-01', NULL, 'arriendo', 3, 3),
  (4, '2025-01-01', NULL, 'propietario', 4, 4),
  (5, '2025-01-01', NULL, 'propietario', 5, 5),
  (6, '2025-01-01', NULL, 'arriendo', 6, 6),
  (7, '2025-01-01', NULL, 'propietario', 7, 7),
  (8, '2025-01-01', NULL, 'propietario', 8, 8),
  (9, '2025-01-01', NULL, 'arriendo', 9, 9),
  (10, '2025-01-01', NULL, 'propietario', 10, 10),
  (11, '2025-01-01', NULL, 'propietario', 11, 11),
  (12, '2025-01-01', NULL, 'arriendo', 12, 12),
  (13, '2025-01-01', NULL, 'propietario', 13, 13),
  (14, '2025-01-01', NULL, 'propietario', 14, 14),
  (15, '2025-01-01', NULL, 'arriendo', 15, 15),
  (16, '2025-01-01', NULL, 'propietario', 16, 16),
  (17, '2025-01-01', NULL, 'propietario', 17, 17),
  (18, '2025-01-01', NULL, 'arriendo', 18, 18),
  (19, '2025-01-01', NULL, 'propietario', 19, 19),
  (20, '2025-01-01', NULL, 'propietario', 20, 20),
  (21, '2025-01-01', NULL, 'arriendo', 21, 21);

-- ocupacion_habitacion: 18 registros nuevos
INSERT INTO ocupacion_habitacion (id_ocupacion_habitacion, fecha_inicio, fecha_fin, hogar_id_hogar, habitacion_id_habitacion) VALUES
  (1, '2025-01-01', NULL, 1, 1),
  (2, '2025-01-01', NULL, 2, 2),
  (3, '2025-01-01', NULL, 3, 3),
  (4, '2025-01-01', NULL, 4, 4),
  (5, '2025-01-01', NULL, 5, 5),
  (6, '2025-01-01', NULL, 6, 6),
  (7, '2025-01-01', NULL, 7, 7),
  (8, '2025-01-01', NULL, 8, 8),
  (9, '2025-01-01', NULL, 9, 9),
  (10, '2025-01-01', NULL, 10, 10),
  (11, '2025-01-01', NULL, 11, 11),
  (12, '2025-01-01', NULL, 12, 12),
  (13, '2025-01-01', NULL, 13, 13),
  (14, '2025-01-01', NULL, 14, 14),
  (15, '2025-01-01', NULL, 15, 15),
  (16, '2025-01-01', NULL, 16, 16),
  (17, '2025-01-01', NULL, 17, 17),
  (18, '2025-01-01', NULL, 18, 18);

-- propiedad_vivienda: 15 registros nuevos
INSERT INTO propiedad_vivienda (id_propiedad, fecha_inicio, fecha_fin, porcentaje_propiedad, persona_id_persona, vivienda_id_vivienda) VALUES
  (1, '2024-01-01', NULL, 100, 1, 1),
  (2, '2024-01-01', NULL, 100, 2, 2),
  (3, '2024-01-01', NULL, 100, 3, 3),
  (4, '2024-01-01', NULL, 100, 4, 4),
  (5, '2024-01-01', NULL, 100, 5, 5),
  (6, '2024-01-01', NULL, 100, 6, 6),
  (7, '2024-01-01', NULL, 100, 7, 7),
  (8, '2024-01-01', NULL, 100, 8, 8),
  (9, '2024-01-01', NULL, 100, 9, 9),
  (10, '2024-01-01', NULL, 100, 10, 10),
  (11, '2024-01-01', NULL, 100, 11, 11),
  (12, '2024-01-01', NULL, 100, 12, 12),
  (13, '2024-01-01', NULL, 100, 13, 13),
  (14, '2024-01-01', NULL, 100, 14, 14),
  (15, '2024-01-01', NULL, 100, 15, 15);

-- censo: 8 registros nuevos
INSERT INTO censo (id_censo, fecha_inicio, fecha_fin, estado, id_municipio, id_terremoto) VALUES
  (1, '2026-08-17', NULL, 'en_proceso', 1, 1),
  (2, '2026-08-17', NULL, 'en_proceso', 2, 1),
  (3, '2026-08-17', NULL, 'en_proceso', 3, 1),
  (4, '2026-08-17', NULL, 'en_proceso', 4, 1),
  (5, '2026-08-17', NULL, 'en_proceso', 5, 1),
  (6, '2026-08-17', NULL, 'en_proceso', 6, 1),
  (7, '2026-09-05', NULL, 'en_proceso', 1, 2),
  (8, '2026-09-05', NULL, 'en_proceso', 2, 2);

-- visita_censo: 24 registros nuevos
INSERT INTO visita_censo (id_visita, fecha_visita, resultado, observaciones, ubicacion_referencia, censo_id_censo, vivienda_id_vivienda) VALUES
  (1, '2026-08-18 10:00:00', 'completada', 'Visita de simulacion', 'Sector ficticio 2', 1, 1),
  (2, '2026-08-19 10:00:00', 'completada', 'Visita de simulacion', 'Sector ficticio 3', 2, 2),
  (3, '2026-08-20 10:00:00', 'completada', 'Visita de simulacion', 'Sector ficticio 4', 3, 3),
  (4, '2026-08-21 10:00:00', 'completada', 'Visita de simulacion', 'Sector ficticio 5', 4, 4),
  (5, '2026-08-22 10:00:00', 'pendiente', 'Visita de simulacion', 'Sector ficticio 6', 5, 5),
  (6, '2026-08-23 10:00:00', 'completada', 'Visita de simulacion', 'Sector ficticio 7', 6, 6),
  (7, '2026-09-12 10:00:00', 'completada', 'Visita de simulacion', 'Sector ficticio 8', 7, 7),
  (8, '2026-09-05 10:00:00', 'completada', 'Visita de simulacion', 'Sector ficticio 9', 8, 8),
  (9, '2026-08-26 10:00:00', 'completada', 'Visita de simulacion', 'Sector ficticio 1', 1, 9),
  (10, '2026-08-17 10:00:00', 'pendiente', 'Visita de simulacion', 'Sector ficticio 2', 2, 10),
  (11, '2026-08-18 10:00:00', 'completada', 'Visita de simulacion', 'Sector ficticio 3', 3, 11),
  (12, '2026-08-19 10:00:00', 'completada', 'Visita de simulacion', 'Sector ficticio 4', 4, 12),
  (13, '2026-08-20 10:00:00', 'completada', 'Visita de simulacion', 'Sector ficticio 5', 5, 13),
  (14, '2026-08-21 10:00:00', 'completada', 'Visita de simulacion', 'Sector ficticio 6', 6, 14),
  (15, '2026-09-12 10:00:00', 'pendiente', 'Visita de simulacion', 'Sector ficticio 7', 7, 15),
  (16, '2026-09-05 10:00:00', 'completada', 'Visita de simulacion', 'Sector ficticio 8', 8, 16),
  (17, '2026-08-24 10:00:00', 'completada', 'Visita de simulacion', 'Sector ficticio 9', 1, 17),
  (18, '2026-08-25 10:00:00', 'completada', 'Visita de simulacion', 'Sector ficticio 1', 2, 18),
  (19, '2026-08-26 10:00:00', 'completada', 'Visita de simulacion', 'Sector ficticio 2', 3, 19),
  (20, '2026-08-17 10:00:00', 'pendiente', 'Visita de simulacion', 'Sector ficticio 3', 4, 20),
  (21, '2026-08-18 10:00:00', 'completada', 'Visita de simulacion', 'Sector ficticio 4', 5, 21),
  (22, '2026-08-19 10:00:00', 'completada', 'Visita de simulacion', 'Sector ficticio 5', 6, 22),
  (23, '2026-09-12 10:00:00', 'completada', 'Visita de simulacion', 'Sector ficticio 6', 7, 23),
  (24, '2026-09-05 10:00:00', 'completada', 'Visita de simulacion', 'Sector ficticio 7', 8, 24);

-- registro_censal_persona: 44 registros nuevos
INSERT INTO registro_censal_persona (id_registro, fecha_registro, observaciones, visita_censo_id_visita, persona_id_persona) VALUES
  (1, '2026-08-18 11:15:00', 'Registro censal ficticio', 1, 1),
  (2, '2026-08-19 11:15:00', 'Registro censal ficticio', 2, 2),
  (3, '2026-08-20 11:15:00', 'Registro censal ficticio', 3, 3),
  (4, '2026-08-21 11:15:00', 'Registro censal ficticio', 4, 4),
  (5, '2026-08-22 11:15:00', 'Registro censal ficticio', 5, 5),
  (6, '2026-08-23 11:15:00', 'Registro censal ficticio', 6, 6),
  (7, '2026-09-11 11:15:00', 'Registro censal ficticio', 7, 7),
  (8, '2026-09-12 11:15:00', 'Registro censal ficticio', 8, 8),
  (9, '2026-08-26 11:15:00', 'Registro censal ficticio', 9, 9),
  (10, '2026-08-17 11:15:00', 'Registro censal ficticio', 10, 10),
  (11, '2026-08-18 11:15:00', 'Registro censal ficticio', 11, 11),
  (12, '2026-08-19 11:15:00', 'Registro censal ficticio', 12, 12),
  (13, '2026-08-20 11:15:00', 'Registro censal ficticio', 13, 13),
  (14, '2026-08-21 11:15:00', 'Registro censal ficticio', 14, 14),
  (15, '2026-09-11 11:15:00', 'Registro censal ficticio', 15, 15),
  (16, '2026-09-12 11:15:00', 'Registro censal ficticio', 16, 16),
  (17, '2026-08-24 11:15:00', 'Registro censal ficticio', 17, 17),
  (18, '2026-08-25 11:15:00', 'Registro censal ficticio', 18, 18),
  (19, '2026-08-26 11:15:00', 'Registro censal ficticio', 19, 19),
  (20, '2026-08-17 11:15:00', 'Registro censal ficticio', 20, 20),
  (21, '2026-08-18 11:15:00', 'Registro censal ficticio', 21, 21),
  (22, '2026-08-19 11:15:00', 'Registro censal ficticio', 22, 22),
  (23, '2026-09-11 11:15:00', 'Registro censal ficticio', 23, 23),
  (24, '2026-09-12 11:15:00', 'Registro censal ficticio', 24, 24),
  (25, '2026-08-22 11:15:00', 'Registro censal ficticio', 1, 25),
  (26, '2026-08-23 11:15:00', 'Registro censal ficticio', 2, 26),
  (27, '2026-08-24 11:15:00', 'Registro censal ficticio', 3, 27),
  (28, '2026-08-25 11:15:00', 'Registro censal ficticio', 4, 28),
  (29, '2026-08-26 11:15:00', 'Registro censal ficticio', 5, 29),
  (30, '2026-08-17 11:15:00', 'Registro censal ficticio', 6, 30),
  (31, '2026-09-11 11:15:00', 'Registro censal ficticio', 7, 31),
  (32, '2026-09-12 11:15:00', 'Registro censal ficticio', 8, 32),
  (33, '2026-08-20 11:15:00', 'Registro censal ficticio', 9, 33),
  (34, '2026-08-21 11:15:00', 'Registro censal ficticio', 10, 34),
  (35, '2026-08-22 11:15:00', 'Registro censal ficticio', 11, 35),
  (36, '2026-08-23 11:15:00', 'Registro censal ficticio', 12, 36),
  (37, '2026-08-24 11:15:00', 'Registro censal ficticio', 13, 37),
  (38, '2026-08-25 11:15:00', 'Registro censal ficticio', 14, 38),
  (39, '2026-09-11 11:15:00', 'Registro censal ficticio', 15, 39),
  (40, '2026-09-12 11:15:00', 'Registro censal ficticio', 16, 40),
  (41, '2026-08-18 11:15:00', 'Registro censal ficticio', 17, 41),
  (42, '2026-08-19 11:15:00', 'Registro censal ficticio', 18, 42),
  (43, '2026-08-20 11:15:00', 'Registro censal ficticio', 19, 43),
  (44, '2026-08-21 11:15:00', 'Registro censal ficticio', 20, 44);

-- afectacion_persona: 28 registros nuevos
INSERT INTO afectacion_persona (id_afectacion_persona, situacion, condicion_presencia, desplazado, fecha_registro, observaciones, persona_id_persona, terremoto_id_terremoto, municipio_id_municipio) VALUES
  (1, 'sin_lesiones', 'presente', 0, '2026-08-18', 'Evaluacion ficticia', 1, 1, 1),
  (2, 'sin_lesiones', 'presente', 0, '2026-08-18', 'Evaluacion ficticia', 2, 1, 2),
  (3, 'sin_lesiones', 'presente', 0, '2026-08-18', 'Evaluacion ficticia', 3, 1, 3),
  (4, 'sin_lesiones', 'presente', 1, '2026-08-18', 'Evaluacion ficticia', 4, 1, 4),
  (5, 'sin_lesiones', 'presente', 0, '2026-08-18', 'Evaluacion ficticia', 5, 1, 5),
  (6, 'sin_lesiones', 'presente', 0, '2026-08-18', 'Evaluacion ficticia', 6, 1, 6),
  (7, 'lesionado', 'presente', 0, '2026-08-18', 'Evaluacion ficticia', 7, 1, 1),
  (8, 'sin_lesiones', 'presente', 1, '2026-08-18', 'Evaluacion ficticia', 8, 1, 2),
  (9, 'sin_lesiones', 'presente', 0, '2026-08-18', 'Evaluacion ficticia', 9, 1, 3),
  (10, 'sin_lesiones', 'presente', 0, '2026-08-18', 'Evaluacion ficticia', 10, 1, 4),
  (11, 'sin_lesiones', 'presente', 0, '2026-08-18', 'Evaluacion ficticia', 11, 1, 5),
  (12, 'sin_lesiones', 'presente', 1, '2026-08-18', 'Evaluacion ficticia', 12, 1, 6),
  (13, 'sin_lesiones', 'presente', 0, '2026-08-18', 'Evaluacion ficticia', 13, 1, 1),
  (14, 'lesionado', 'presente', 0, '2026-08-18', 'Evaluacion ficticia', 14, 1, 2),
  (15, 'sin_lesiones', 'presente', 0, '2026-08-18', 'Evaluacion ficticia', 15, 1, 3),
  (16, 'sin_lesiones', 'presente', 1, '2026-08-18', 'Evaluacion ficticia', 16, 1, 4),
  (17, 'sin_lesiones', 'presente', 0, '2026-08-18', 'Evaluacion ficticia', 17, 1, 5),
  (18, 'sin_lesiones', 'presente', 0, '2026-08-18', 'Evaluacion ficticia', 18, 1, 6),
  (19, 'sin_lesiones', 'presente', 0, '2026-08-18', 'Evaluacion ficticia', 19, 1, 1),
  (20, 'sin_lesiones', 'presente', 1, '2026-08-18', 'Evaluacion ficticia', 20, 1, 2),
  (21, 'lesionado', 'presente', 0, '2026-08-18', 'Evaluacion ficticia', 21, 1, 3),
  (22, 'sin_lesiones', 'presente', 0, '2026-08-18', 'Evaluacion ficticia', 22, 1, 4),
  (23, 'sin_lesiones', 'presente', 0, '2026-08-18', 'Evaluacion ficticia', 23, 1, 5),
  (24, 'sin_lesiones', 'presente', 1, '2026-08-18', 'Evaluacion ficticia', 24, 1, 6),
  (25, 'sin_lesiones', 'presente', 0, '2026-08-18', 'Evaluacion ficticia', 25, 1, 1),
  (26, 'sin_lesiones', 'presente', 0, '2026-08-18', 'Evaluacion ficticia', 26, 1, 2),
  (27, 'sin_lesiones', 'presente', 0, '2026-08-18', 'Evaluacion ficticia', 27, 1, 3),
  (28, 'lesionado', 'presente', 1, '2026-08-18', 'Evaluacion ficticia', 28, 1, 4);

-- infraestructura: 8 registros nuevos
INSERT INTO infraestructura (id_infraestructura, nombre, tipo_infraestructura, descripcion, estado_operativo) VALUES
  (1, 'Puente principal', 'puente', 'Infraestructura ficticia para pruebas', 'parcial'),
  (2, 'Via de acceso', 'carretera', 'Infraestructura ficticia para pruebas', 'parcial'),
  (3, 'Centro de salud', 'salud', 'Infraestructura ficticia para pruebas', 'fuera_servicio'),
  (4, 'Escuela central', 'educativa', 'Infraestructura ficticia para pruebas', 'parcial'),
  (5, 'Acueducto local', 'acueducto', 'Infraestructura ficticia para pruebas', 'parcial'),
  (6, 'Subestacion', 'energia', 'Infraestructura ficticia para pruebas', 'fuera_servicio'),
  (7, 'Hospital municipal', 'salud', 'Infraestructura ficticia para pruebas', 'parcial'),
  (8, 'Via secundaria', 'carretera', 'Infraestructura ficticia para pruebas', 'parcial');

-- tramo_infraestructura: 12 registros nuevos
INSERT INTO tramo_infraestructura (id_tramo, codigo_tramo, km_inicio, km_fin, descripcion, id_infraestructura) VALUES
  (1, 'TR-001', 0, 2, 'Tramo ficticio', 1),
  (2, 'TR-002', 2, 4, 'Tramo ficticio', 2),
  (3, 'TR-003', 4, 6, 'Tramo ficticio', 3),
  (4, 'TR-004', 6, 8, 'Tramo ficticio', 4),
  (5, 'TR-005', 8, 10, 'Tramo ficticio', 5),
  (6, 'TR-006', 10, 12, 'Tramo ficticio', 6),
  (7, 'TR-007', 12, 14, 'Tramo ficticio', 7),
  (8, 'TR-008', 14, 16, 'Tramo ficticio', 8),
  (9, 'TR-009', 16, 18, 'Tramo ficticio', 1),
  (10, 'TR-010', 18, 20, 'Tramo ficticio', 2),
  (11, 'TR-011', 20, 22, 'Tramo ficticio', 3),
  (12, 'TR-012', 22, 24, 'Tramo ficticio', 4);

-- infraestructura_municipio: 12 registros nuevos
INSERT INTO infraestructura_municipio (tipo_vinculo, observaciones, id_infraestructura, municipio_id_municipio) VALUES
  ('ubicada', 'Relacion territorial simulada', 1, 1),
  ('ubicada', 'Relacion territorial simulada', 2, 2),
  ('ubicada', 'Relacion territorial simulada', 3, 3),
  ('ubicada', 'Relacion territorial simulada', 4, 4),
  ('ubicada', 'Relacion territorial simulada', 5, 5),
  ('ubicada', 'Relacion territorial simulada', 6, 6),
  ('ubicada', 'Relacion territorial simulada', 7, 1),
  ('ubicada', 'Relacion territorial simulada', 8, 2),
  ('servicio', 'Relacion territorial simulada', 1, 3),
  ('servicio', 'Relacion territorial simulada', 2, 4),
  ('servicio', 'Relacion territorial simulada', 3, 5),
  ('servicio', 'Relacion territorial simulada', 4, 6);

-- reporte_dano: 16 registros nuevos
INSERT INTO reporte_dano (id_reporte, fecha_reporte, tipo_fuente, descripcion, estado_verificacion, terremoto_id_terremoto) VALUES
  (1, '2026-08-17 14:00:00', 'ciudadano', 'Reporte ficticio de danos 1', 'verificado', 1),
  (2, '2026-08-17 14:00:00', 'inspector', 'Reporte ficticio de danos 2', 'verificado', 1),
  (3, '2026-08-17 14:00:00', 'ciudadano', 'Reporte ficticio de danos 3', 'pendiente', 1),
  (4, '2026-08-17 14:00:00', 'inspector', 'Reporte ficticio de danos 4', 'verificado', 1),
  (5, '2026-08-17 14:00:00', 'ciudadano', 'Reporte ficticio de danos 5', 'verificado', 1),
  (6, '2026-08-17 14:00:00', 'inspector', 'Reporte ficticio de danos 6', 'pendiente', 1),
  (7, '2026-08-17 14:00:00', 'ciudadano', 'Reporte ficticio de danos 7', 'verificado', 1),
  (8, '2026-08-17 14:00:00', 'inspector', 'Reporte ficticio de danos 8', 'verificado', 1),
  (9, '2026-08-17 14:00:00', 'ciudadano', 'Reporte ficticio de danos 9', 'pendiente', 1),
  (10, '2026-08-17 14:00:00', 'inspector', 'Reporte ficticio de danos 10', 'verificado', 1),
  (11, '2026-08-17 14:00:00', 'ciudadano', 'Reporte ficticio de danos 11', 'verificado', 1),
  (12, '2026-08-17 14:00:00', 'inspector', 'Reporte ficticio de danos 12', 'pendiente', 1),
  (13, '2026-08-17 14:00:00', 'ciudadano', 'Reporte ficticio de danos 13', 'verificado', 1),
  (14, '2026-08-17 14:00:00', 'inspector', 'Reporte ficticio de danos 14', 'verificado', 1),
  (15, '2026-08-17 14:00:00', 'ciudadano', 'Reporte ficticio de danos 15', 'pendiente', 1),
  (16, '2026-08-17 14:00:00', 'inspector', 'Reporte ficticio de danos 16', 'verificado', 1);

-- afectacion: 24 registros nuevos
INSERT INTO afectacion (id_afectacion, fecha_registro, descripcion_general, estado, terremoto_id_terremoto, reporte_dano_id_reporte, tipo_afectacion) VALUES
  (1, '2026-08-18', 'Afectacion simulada 1', 'evaluacion', 1, 1, 'Afectacion_Vivienda'),
  (2, '2026-08-18', 'Afectacion simulada 2', 'evaluacion', 1, 2, 'Afectacion_Vivienda'),
  (3, '2026-08-18', 'Afectacion simulada 3', 'atendida', 1, 3, 'Afectacion_Vivienda'),
  (4, '2026-08-18', 'Afectacion simulada 4', 'evaluacion', 1, 4, 'Afectacion_Vivienda'),
  (5, '2026-08-18', 'Afectacion simulada 5', 'evaluacion', 1, 5, 'Afectacion_Vivienda'),
  (6, '2026-08-18', 'Afectacion simulada 6', 'atendida', 1, 6, 'Afectacion_Vivienda'),
  (7, '2026-08-18', 'Afectacion simulada 7', 'evaluacion', 1, 7, 'Afectacion_Vivienda'),
  (8, '2026-08-18', 'Afectacion simulada 8', 'evaluacion', 1, 8, 'Afectacion_Vivienda'),
  (9, '2026-08-18', 'Afectacion simulada 9', 'atendida', 1, 9, 'Afectacion_Vivienda'),
  (10, '2026-08-18', 'Afectacion simulada 10', 'evaluacion', 1, 10, 'Afectacion_Vivienda'),
  (11, '2026-08-18', 'Afectacion simulada 11', 'evaluacion', 1, 11, 'Afectacion_Vivienda'),
  (12, '2026-08-18', 'Afectacion simulada 12', 'atendida', 1, 12, 'Afectacion_Vivienda'),
  (13, '2026-08-18', 'Afectacion simulada 13', 'evaluacion', 1, 13, 'Afectacion_Vivienda'),
  (14, '2026-08-18', 'Afectacion simulada 14', 'evaluacion', 1, 14, 'Afectacion_Vivienda'),
  (15, '2026-08-18', 'Afectacion simulada 15', 'atendida', 1, 15, 'Afectacion_Vivienda'),
  (16, '2026-08-18', 'Afectacion simulada 16', 'evaluacion', 1, 16, 'Afectacion_Vivienda'),
  (17, '2026-08-18', 'Afectacion simulada 17', 'evaluacion', 1, 1, 'Afectacion_Infraestructura'),
  (18, '2026-08-18', 'Afectacion simulada 18', 'atendida', 1, 2, 'Afectacion_Infraestructura'),
  (19, '2026-08-18', 'Afectacion simulada 19', 'evaluacion', 1, 3, 'Afectacion_Infraestructura'),
  (20, '2026-08-18', 'Afectacion simulada 20', 'evaluacion', 1, 4, 'Afectacion_Infraestructura'),
  (21, '2026-08-18', 'Afectacion simulada 21', 'atendida', 1, 5, 'Afectacion_Infraestructura'),
  (22, '2026-08-18', 'Afectacion simulada 22', 'evaluacion', 1, 6, 'Afectacion_Infraestructura'),
  (23, '2026-08-18', 'Afectacion simulada 23', 'evaluacion', 1, 7, 'Afectacion_Infraestructura'),
  (24, '2026-08-18', 'Afectacion simulada 24', 'atendida', 1, 8, 'Afectacion_Infraestructura');

-- afectacion_vivienda: 16 registros nuevos
INSERT INTO afectacion_vivienda (id_afectacion, observaciones, vivienda_id_vivienda) VALUES
  (1, 'Danio estructural simulado', 1),
  (2, 'Danio estructural simulado', 2),
  (3, 'Danio estructural simulado', 3),
  (4, 'Danio estructural simulado', 4),
  (5, 'Danio estructural simulado', 5),
  (6, 'Danio estructural simulado', 6),
  (7, 'Danio estructural simulado', 7),
  (8, 'Danio estructural simulado', 8),
  (9, 'Danio estructural simulado', 9),
  (10, 'Danio estructural simulado', 10),
  (11, 'Danio estructural simulado', 11),
  (12, 'Danio estructural simulado', 12),
  (13, 'Danio estructural simulado', 13),
  (14, 'Danio estructural simulado', 14),
  (15, 'Danio estructural simulado', 15),
  (16, 'Danio estructural simulado', 16);

-- afectacion_infraestructura: 8 registros nuevos
INSERT INTO afectacion_infraestructura (id_afectacion, observaciones, id_infraestructura, tramo_infraestructura_id_tramo) VALUES
  (17, 'Danio de infraestructura simulado', 1, 1),
  (18, 'Danio de infraestructura simulado', 2, 2),
  (19, 'Danio de infraestructura simulado', 3, 3),
  (20, 'Danio de infraestructura simulado', 4, 4),
  (21, 'Danio de infraestructura simulado', 5, 5),
  (22, 'Danio de infraestructura simulado', 6, 6),
  (23, 'Danio de infraestructura simulado', 7, 7),
  (24, 'Danio de infraestructura simulado', 8, 8);

-- organizacion: 4 registros nuevos
INSERT INTO organizacion (id_organizacion, nombre, tipo_organizacion, telefono, correo) VALUES
  (1, 'Cruz Roja - equipo simulado', 'humanitaria', NULL, NULL),
  (2, 'Defensa Civil - equipo simulado', 'emergencia', NULL, NULL),
  (3, 'Alcaldia - equipo simulado', 'publica', NULL, NULL),
  (4, 'ONG Apoyo Local - ficticia', 'social', NULL, NULL);

-- personal_campo: 10 registros nuevos
INSERT INTO personal_campo (id_personal, nombres, apellidos, cargo, telefono, organizacion_id_organizacion) VALUES
  (1, 'Diana', 'Ramírez', 'inspector', NULL, 1),
  (2, 'Jorge', 'Torres', 'coordinador', NULL, 2),
  (3, 'Sofía', 'López', 'inspector', NULL, 3),
  (4, 'Miguel', 'García', 'coordinador', NULL, 4),
  (5, 'Laura', 'Ríos', 'inspector', NULL, 1),
  (6, 'Camila', 'Restrepo', 'coordinador', NULL, 2),
  (7, 'Andrés', 'Castaño', 'inspector', NULL, 3),
  (8, 'Valentina', 'Morales', 'coordinador', NULL, 4),
  (9, 'Mateo', 'Giraldo', 'inspector', NULL, 1),
  (10, 'Daniela', 'Gómez', 'coordinador', NULL, 2);

-- inspeccion: 16 registros nuevos
INSERT INTO inspeccion (id_inspeccion, fecha_inspeccion, nivel_dano, resultado, observaciones, afectacion_id_afectacion, personal_campo_id_personal) VALUES
  (1, '2026-08-19 08:00:00', 'moderado', 'Revision tecnica ficticia 1', 'Inspeccion de simulacion', 1, 1),
  (2, '2026-08-19 08:00:00', 'grave', 'Revision tecnica ficticia 2', 'Inspeccion de simulacion', 2, 2),
  (3, '2026-08-19 08:00:00', 'leve', 'Revision tecnica ficticia 3', 'Inspeccion de simulacion', 3, 3),
  (4, '2026-08-19 08:00:00', 'moderado', 'Revision tecnica ficticia 4', 'Inspeccion de simulacion', 4, 4),
  (5, '2026-08-19 08:00:00', 'grave', 'Revision tecnica ficticia 5', 'Inspeccion de simulacion', 5, 5),
  (6, '2026-08-19 08:00:00', 'leve', 'Revision tecnica ficticia 6', 'Inspeccion de simulacion', 6, 6),
  (7, '2026-08-19 08:00:00', 'moderado', 'Revision tecnica ficticia 7', 'Inspeccion de simulacion', 7, 7),
  (8, '2026-08-19 08:00:00', 'grave', 'Revision tecnica ficticia 8', 'Inspeccion de simulacion', 8, 8),
  (9, '2026-08-19 08:00:00', 'leve', 'Revision tecnica ficticia 9', 'Inspeccion de simulacion', 9, 9),
  (10, '2026-08-19 08:00:00', 'moderado', 'Revision tecnica ficticia 10', 'Inspeccion de simulacion', 10, 10),
  (11, '2026-08-19 08:00:00', 'grave', 'Revision tecnica ficticia 11', 'Inspeccion de simulacion', 11, 1),
  (12, '2026-08-19 08:00:00', 'leve', 'Revision tecnica ficticia 12', 'Inspeccion de simulacion', 12, 2),
  (13, '2026-08-19 08:00:00', 'moderado', 'Revision tecnica ficticia 13', 'Inspeccion de simulacion', 13, 3),
  (14, '2026-08-19 08:00:00', 'grave', 'Revision tecnica ficticia 14', 'Inspeccion de simulacion', 14, 4),
  (15, '2026-08-19 08:00:00', 'leve', 'Revision tecnica ficticia 15', 'Inspeccion de simulacion', 15, 5),
  (16, '2026-08-19 08:00:00', 'moderado', 'Revision tecnica ficticia 16', 'Inspeccion de simulacion', 16, 6);

-- evidencia: 16 registros nuevos
INSERT INTO evidencia (id_evidencia, tipo_evidencia, ruta_archivo, fecha_registro, descripcion, reporte_dano_id_reporte, inspeccion_id_inspeccion) VALUES
  (1, 'fotografia', '/evidencias/simulacion_001.jpg', '2026-08-19', 'Ruta de ejemplo; archivo no incluido', 1, 1),
  (2, 'fotografia', '/evidencias/simulacion_002.jpg', '2026-08-19', 'Ruta de ejemplo; archivo no incluido', 2, 2),
  (3, 'fotografia', '/evidencias/simulacion_003.jpg', '2026-08-19', 'Ruta de ejemplo; archivo no incluido', 3, 3),
  (4, 'fotografia', '/evidencias/simulacion_004.jpg', '2026-08-19', 'Ruta de ejemplo; archivo no incluido', 4, 4),
  (5, 'fotografia', '/evidencias/simulacion_005.jpg', '2026-08-19', 'Ruta de ejemplo; archivo no incluido', 5, 5),
  (6, 'fotografia', '/evidencias/simulacion_006.jpg', '2026-08-19', 'Ruta de ejemplo; archivo no incluido', 6, 6),
  (7, 'fotografia', '/evidencias/simulacion_007.jpg', '2026-08-19', 'Ruta de ejemplo; archivo no incluido', 7, 7),
  (8, 'fotografia', '/evidencias/simulacion_008.jpg', '2026-08-19', 'Ruta de ejemplo; archivo no incluido', 8, 8),
  (9, 'fotografia', '/evidencias/simulacion_009.jpg', '2026-08-19', 'Ruta de ejemplo; archivo no incluido', 9, 9),
  (10, 'fotografia', '/evidencias/simulacion_010.jpg', '2026-08-19', 'Ruta de ejemplo; archivo no incluido', 10, 10),
  (11, 'fotografia', '/evidencias/simulacion_011.jpg', '2026-08-19', 'Ruta de ejemplo; archivo no incluido', 11, 11),
  (12, 'fotografia', '/evidencias/simulacion_012.jpg', '2026-08-19', 'Ruta de ejemplo; archivo no incluido', 12, 12),
  (13, 'fotografia', '/evidencias/simulacion_013.jpg', '2026-08-19', 'Ruta de ejemplo; archivo no incluido', 13, 13),
  (14, 'fotografia', '/evidencias/simulacion_014.jpg', '2026-08-19', 'Ruta de ejemplo; archivo no incluido', 14, 14),
  (15, 'fotografia', '/evidencias/simulacion_015.jpg', '2026-08-19', 'Ruta de ejemplo; archivo no incluido', 15, 15),
  (16, 'fotografia', '/evidencias/simulacion_016.jpg', '2026-08-19', 'Ruta de ejemplo; archivo no incluido', 16, 16);

-- consecuencia_afectacion: 15 registros nuevos
INSERT INTO consecuencia_afectacion (id_consecuencia, tipo_consecuencia, descripcion, fecha_inicio, fecha_fin, estado, afectacion_id_afectacion) VALUES
  (1, 'corte_servicio', 'Consecuencia simulada 1', '2026-08-18', NULL, 'activa', 1),
  (2, 'riesgo', 'Consecuencia simulada 2', '2026-08-18', NULL, 'activa', 2),
  (3, 'inhabitabilidad', 'Consecuencia simulada 3', '2026-08-18', NULL, 'activa', 3),
  (4, 'corte_servicio', 'Consecuencia simulada 4', '2026-08-18', NULL, 'controlada', 4),
  (5, 'riesgo', 'Consecuencia simulada 5', '2026-08-18', NULL, 'activa', 5),
  (6, 'inhabitabilidad', 'Consecuencia simulada 6', '2026-08-18', NULL, 'activa', 6),
  (7, 'corte_servicio', 'Consecuencia simulada 7', '2026-08-18', NULL, 'activa', 7),
  (8, 'riesgo', 'Consecuencia simulada 8', '2026-08-18', NULL, 'controlada', 8),
  (9, 'inhabitabilidad', 'Consecuencia simulada 9', '2026-08-18', NULL, 'activa', 9),
  (10, 'corte_servicio', 'Consecuencia simulada 10', '2026-08-18', NULL, 'activa', 10),
  (11, 'riesgo', 'Consecuencia simulada 11', '2026-08-18', NULL, 'activa', 11),
  (12, 'inhabitabilidad', 'Consecuencia simulada 12', '2026-08-18', NULL, 'controlada', 12),
  (13, 'corte_servicio', 'Consecuencia simulada 13', '2026-08-18', NULL, 'activa', 13),
  (14, 'riesgo', 'Consecuencia simulada 14', '2026-08-18', NULL, 'activa', 14),
  (15, 'inhabitabilidad', 'Consecuencia simulada 15', '2026-08-18', NULL, 'activa', 15);

-- alojamiento_temporal: 6 registros nuevos
INSERT INTO alojamiento_temporal (id_alojamiento, nombre, direccion, capacidad_personas, estado, municipio_id_municipio) VALUES
  (1, 'Albergue ficticio 1', 'Carrera 11 No. 5-20 (ficticia)', 30, 'activo', 1),
  (2, 'Albergue ficticio 2', 'Carrera 12 No. 5-20 (ficticia)', 40, 'activo', 2),
  (3, 'Albergue ficticio 3', 'Carrera 13 No. 5-20 (ficticia)', 50, 'activo', 3),
  (4, 'Albergue ficticio 4', 'Carrera 14 No. 5-20 (ficticia)', 60, 'activo', 4),
  (5, 'Albergue ficticio 5', 'Carrera 15 No. 5-20 (ficticia)', 70, 'activo', 5),
  (6, 'Albergue ficticio 6', 'Carrera 16 No. 5-20 (ficticia)', 80, 'activo', 6);

-- estancia_alojamiento: 14 registros nuevos
INSERT INTO estancia_alojamiento (id_estancia, fecha_ingreso, fecha_salida, observaciones, id_alojamiento, terremoto_id_terremoto, hogar_id_hogar, persona_id_persona) VALUES
  (1, '2026-08-20', NULL, 'Estancia ficticia', 1, 1, 1, NULL),
  (2, '2026-08-20', NULL, 'Estancia ficticia', 2, 1, 2, NULL),
  (3, '2026-08-20', NULL, 'Estancia ficticia', 3, 1, 3, NULL),
  (4, '2026-08-20', '2026-08-26', 'Estancia ficticia', 4, 1, 4, NULL),
  (5, '2026-08-20', NULL, 'Estancia ficticia', 5, 1, 5, NULL),
  (6, '2026-08-20', NULL, 'Estancia ficticia', 6, 1, 6, NULL),
  (7, '2026-08-20', NULL, 'Estancia ficticia', 1, 1, 7, NULL),
  (8, '2026-08-20', '2026-08-26', 'Estancia ficticia', 2, 1, 8, NULL),
  (9, '2026-08-20', NULL, 'Estancia ficticia', 3, 1, 9, NULL),
  (10, '2026-08-20', NULL, 'Estancia ficticia', 4, 1, 10, NULL),
  (11, '2026-08-20', NULL, 'Estancia ficticia', 5, 1, NULL, 21),
  (12, '2026-08-20', '2026-08-26', 'Estancia ficticia', 6, 1, NULL, 22),
  (13, '2026-08-20', NULL, 'Estancia ficticia', 1, 1, NULL, 23),
  (14, '2026-08-20', NULL, 'Estancia ficticia', 2, 1, NULL, 24);

-- necesidad: 18 registros nuevos
INSERT INTO necesidad (id_necesidad, tipo_necesidad, descripcion, prioridad, fecha_identificacion, estado, hogar_id_hogar, terremoto_id_terremoto) VALUES
  (1, 'alojamiento', 'Necesidad simulada de apoyo', 'media', '2026-08-20', 'pendiente', 1, 1),
  (2, 'salud', 'Necesidad simulada de apoyo', 'baja', '2026-08-20', 'en_atencion', 2, 1),
  (3, 'agua', 'Necesidad simulada de apoyo', 'alta', '2026-08-20', 'pendiente', 3, 1),
  (4, 'alimentos', 'Necesidad simulada de apoyo', 'media', '2026-08-20', 'en_atencion', 4, 1),
  (5, 'alojamiento', 'Necesidad simulada de apoyo', 'baja', '2026-08-20', 'pendiente', 5, 1),
  (6, 'salud', 'Necesidad simulada de apoyo', 'alta', '2026-08-20', 'en_atencion', 6, 1),
  (7, 'agua', 'Necesidad simulada de apoyo', 'media', '2026-08-20', 'pendiente', 7, 1),
  (8, 'alimentos', 'Necesidad simulada de apoyo', 'baja', '2026-08-20', 'en_atencion', 8, 1),
  (9, 'alojamiento', 'Necesidad simulada de apoyo', 'alta', '2026-08-20', 'pendiente', 9, 1),
  (10, 'salud', 'Necesidad simulada de apoyo', 'media', '2026-08-20', 'en_atencion', 10, 1),
  (11, 'agua', 'Necesidad simulada de apoyo', 'baja', '2026-08-20', 'pendiente', 11, 1),
  (12, 'alimentos', 'Necesidad simulada de apoyo', 'alta', '2026-08-20', 'en_atencion', 12, 1),
  (13, 'alojamiento', 'Necesidad simulada de apoyo', 'media', '2026-08-20', 'pendiente', 13, 1),
  (14, 'salud', 'Necesidad simulada de apoyo', 'baja', '2026-08-20', 'en_atencion', 14, 1),
  (15, 'agua', 'Necesidad simulada de apoyo', 'alta', '2026-08-20', 'pendiente', 15, 1),
  (16, 'alimentos', 'Necesidad simulada de apoyo', 'media', '2026-08-20', 'en_atencion', 16, 1),
  (17, 'alojamiento', 'Necesidad simulada de apoyo', 'baja', '2026-08-20', 'pendiente', 17, 1),
  (18, 'salud', 'Necesidad simulada de apoyo', 'alta', '2026-08-20', 'en_atencion', 18, 1);

-- solicitud_atencion: 16 registros nuevos
INSERT INTO solicitud_atencion (id_solicitud, fecha_solicitud, estado, observaciones, necesidad_id_necesidad) VALUES
  (1, '2026-08-21', 'radicada', 'Solicitud ficticia', 1),
  (2, '2026-08-21', 'radicada', 'Solicitud ficticia', 2),
  (3, '2026-08-21', 'atendida', 'Solicitud ficticia', 3),
  (4, '2026-08-21', 'radicada', 'Solicitud ficticia', 4),
  (5, '2026-08-21', 'radicada', 'Solicitud ficticia', 5),
  (6, '2026-08-21', 'atendida', 'Solicitud ficticia', 6),
  (7, '2026-08-21', 'radicada', 'Solicitud ficticia', 7),
  (8, '2026-08-21', 'radicada', 'Solicitud ficticia', 8),
  (9, '2026-08-21', 'atendida', 'Solicitud ficticia', 9),
  (10, '2026-08-21', 'radicada', 'Solicitud ficticia', 10),
  (11, '2026-08-21', 'radicada', 'Solicitud ficticia', 11),
  (12, '2026-08-21', 'atendida', 'Solicitud ficticia', 12),
  (13, '2026-08-21', 'radicada', 'Solicitud ficticia', 13),
  (14, '2026-08-21', 'radicada', 'Solicitud ficticia', 14),
  (15, '2026-08-21', 'atendida', 'Solicitud ficticia', 15),
  (16, '2026-08-21', 'radicada', 'Solicitud ficticia', 16);

-- intervencion: 12 registros nuevos
INSERT INTO intervencion (id_intervencion, fecha_inicio, fecha_fin, tipo_intervencion, descripcion, estado, terremoto_id_terremoto, id_solicitud, afectacion_id_afectacion) VALUES
  (1, '2026-08-22', NULL, 'reparacion', 'Intervencion simulada de respuesta', 'en_proceso', 1, 1, 1),
  (2, '2026-08-22', NULL, 'evaluacion', 'Intervencion simulada de respuesta', 'en_proceso', 1, 2, 2),
  (3, '2026-08-22', '2026-08-29', 'asistencia', 'Intervencion simulada de respuesta', 'finalizada', 1, 3, 3),
  (4, '2026-08-22', NULL, 'reparacion', 'Intervencion simulada de respuesta', 'en_proceso', 1, 4, 4),
  (5, '2026-08-22', NULL, 'evaluacion', 'Intervencion simulada de respuesta', 'en_proceso', 1, 5, 5),
  (6, '2026-08-22', '2026-08-29', 'asistencia', 'Intervencion simulada de respuesta', 'finalizada', 1, 6, 6),
  (7, '2026-08-22', NULL, 'reparacion', 'Intervencion simulada de respuesta', 'en_proceso', 1, 7, 7),
  (8, '2026-08-22', NULL, 'evaluacion', 'Intervencion simulada de respuesta', 'en_proceso', 1, 8, 8),
  (9, '2026-08-22', '2026-08-29', 'asistencia', 'Intervencion simulada de respuesta', 'finalizada', 1, 9, 9),
  (10, '2026-08-22', NULL, 'reparacion', 'Intervencion simulada de respuesta', 'en_proceso', 1, 10, 10),
  (11, '2026-08-22', NULL, 'evaluacion', 'Intervencion simulada de respuesta', 'en_proceso', 1, 11, 11),
  (12, '2026-08-22', '2026-08-29', 'asistencia', 'Intervencion simulada de respuesta', 'finalizada', 1, 12, 12);

-- intervencion_organizacion: 18 registros nuevos
INSERT INTO intervencion_organizacion (rol, intervencion_id_intervencion, organizacion_id_organizacion) VALUES
  ('ejecutor', 1, 1),
  ('apoyo', 2, 2),
  ('ejecutor', 3, 3),
  ('apoyo', 4, 4),
  ('ejecutor', 5, 1),
  ('apoyo', 6, 2),
  ('ejecutor', 7, 3),
  ('apoyo', 8, 4),
  ('ejecutor', 9, 1),
  ('apoyo', 10, 2),
  ('ejecutor', 11, 3),
  ('apoyo', 12, 4),
  ('ejecutor', 1, 2),
  ('apoyo', 2, 3),
  ('ejecutor', 3, 4),
  ('apoyo', 4, 1),
  ('ejecutor', 5, 2),
  ('apoyo', 6, 3);

COMMIT;

-- VERIFICACION: conteos de algunas tablas representativas.
SELECT (SELECT COUNT(*) FROM departamento) AS departamentos, (SELECT COUNT(*) FROM municipio) AS municipios, (SELECT COUNT(*) FROM persona) AS personas, (SELECT COUNT(*) FROM afectacion) AS afectaciones;
-- Para comprobar filas de ejemplo:
SELECT * FROM departamento ORDER BY id_departamento;
SELECT * FROM municipio ORDER BY id_municipio;
SELECT * FROM terremoto ORDER BY id_terremoto;
