from __future__ import annotations

import json
import os
import re
import secrets
from datetime import date, datetime
from decimal import Decimal, InvalidOperation
from pathlib import Path
from base64 import urlsafe_b64decode, urlsafe_b64encode

import psycopg
from flask import Flask, abort, flash, g, redirect, render_template, request, session, url_for
from psycopg.rows import dict_row
from werkzeug.exceptions import HTTPException
from werkzeug.security import check_password_hash, generate_password_hash


ROOT = Path(__file__).resolve().parent.parent
SCHEMA = "censo_terremoto"
IDENTIFIER_RE = re.compile(r"^[a-z_][a-z0-9_]*$")


def load_env_file() -> None:
    """Carga .env sin dependencia adicional; no sobrescribe variables del sistema."""
    path = ROOT / ".env"
    if not path.exists():
        return
    for raw in path.read_text(encoding="utf-8-sig").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        os.environ.setdefault(key.strip(), value.strip().strip("\"'"))


load_env_file()

app = Flask(
    __name__,
    template_folder=str(ROOT / "app" / "templates"),
    static_folder=str(ROOT / "app" / "static"),
)
is_production = os.getenv("APP_ENV", "development").lower() == "production"
configured_secret = os.getenv("FLASK_SECRET_KEY", "")
if is_production and (not configured_secret or configured_secret.startswith("CAMBIA_")):
    raise RuntimeError("FLASK_SECRET_KEY debe configurarse en el entorno de producción.")
configured_bootstrap_key = os.getenv("ADMIN_BOOTSTRAP_KEY", "")
if is_production and configured_bootstrap_key and len(configured_bootstrap_key) < 32:
    raise RuntimeError("ADMIN_BOOTSTRAP_KEY debe contener al menos 32 caracteres en producción.")
app.secret_key = configured_secret if configured_secret and not configured_secret.startswith("CAMBIA_") else secrets.token_urlsafe(32)
app.config.update(
    SESSION_COOKIE_HTTPONLY=True,
    SESSION_COOKIE_SAMESITE="Lax",
    SESSION_COOKIE_SECURE=is_production,
)


def connect_db():
    database_url = os.getenv("DATABASE_URL", "").strip()
    if is_production and not database_url:
        raise psycopg.OperationalError("DATABASE_URL no est? configurada en el entorno de producci?n.")

    if database_url:
        if is_production:
            conn = psycopg.connect(
                database_url,
                row_factory=dict_row,
                connect_timeout=10,
                sslmode="require",
            )
        else:
            conn = psycopg.connect(
                database_url,
                row_factory=dict_row,
                connect_timeout=10,
            )
    else:
        conn = psycopg.connect(
            host=os.getenv("PGHOST", "localhost"),
            port=os.getenv("PGPORT", "5432"),
            dbname=os.getenv("PGDATABASE", "censo_terremoto"),
            user=os.getenv("PGAPPUSER") or os.getenv("PGUSER", "postgres"),
            password=os.getenv("PGAPPPASSWORD") or os.getenv("PGPASSWORD", ""),
            row_factory=dict_row,
            connect_timeout=5,
        )

    try:
        # Neon pooled endpoints reject search_path in startup options. SET LOCAL is scoped
        # to this transaction and is supported by PgBouncer transaction pooling.
        conn.execute("SET LOCAL search_path TO censo_terremoto, public")
    except Exception:
        conn.close()
        raise
    return conn


ENTITY_GROUPS = {
    "Geografía": ["departamento", "municipio", "sector"],
    "Eventos y censos": ["terremoto", "terremoto_municipio", "censo", "visita_censo", "registro_censal_persona"],
    "Personas, hogares y viviendas": ["persona", "hogar", "integrante_hogar", "edificacion", "vivienda", "habitacion", "ocupacion_vivienda", "ocupacion_habitacion", "propiedad_vivienda"],
    "Reportes y afectaciones": ["reporte_dano", "evidencia", "afectacion", "afectacion_persona", "afectacion_vivienda", "afectacion_infraestructura", "inspeccion", "consecuencia_afectacion"],
    "Infraestructura": ["infraestructura", "infraestructura_municipio", "tramo_infraestructura"],
    "Atención y respuesta": ["organizacion", "personal_campo", "alojamiento_temporal", "estancia_alojamiento", "necesidad", "solicitud_atencion", "intervencion", "intervencion_organizacion"],
}

ENTITY_LABELS = {
    "departamento": "Departamentos", "municipio": "Municipios", "sector": "Sectores",
    "terremoto": "Terremotos", "terremoto_municipio": "Terremotos por municipio", "censo": "Censos",
    "visita_censo": "Visitas de censo", "registro_censal_persona": "Personas censadas",
    "persona": "Personas", "hogar": "Hogares", "integrante_hogar": "Integrantes de hogar",
    "edificacion": "Edificaciones", "vivienda": "Viviendas", "habitacion": "Habitaciones",
    "ocupacion_vivienda": "Ocupaciones de vivienda", "ocupacion_habitacion": "Ocupaciones de habitación",
    "propiedad_vivienda": "Propiedad de vivienda", "reporte_dano": "Reportes de daño", "evidencia": "Evidencias",
    "afectacion": "Afectaciones", "afectacion_persona": "Afectaciones a personas",
    "afectacion_vivienda": "Afectaciones a viviendas", "afectacion_infraestructura": "Afectaciones a infraestructura",
    "inspeccion": "Inspecciones", "consecuencia_afectacion": "Consecuencias de afectación",
    "infraestructura": "Infraestructuras", "infraestructura_municipio": "Infraestructura por municipio",
    "tramo_infraestructura": "Tramos de infraestructura", "organizacion": "Organizaciones",
    "personal_campo": "Personal de campo", "alojamiento_temporal": "Alojamientos temporales",
    "estancia_alojamiento": "Estancias en alojamiento", "necesidad": "Necesidades",
    "solicitud_atencion": "Solicitudes de atención", "intervencion": "Intervenciones",
    "intervencion_organizacion": "Organizaciones por intervención",
}

ENTITY_DESCRIPTIONS = {
    "departamento": "División administrativa que agrupa los municipios incluidos en el censo.",
    "municipio": "Territorio municipal que participa en uno o varios eventos.",
    "sector": "Barrio, vereda u otro sector geográfico de un municipio.",
    "terremoto": "Evento sísmico con fecha, magnitud, profundidad y descripción.",
    "terremoto_municipio": "Relación que registra los municipios alcanzados por cada terremoto.",
    "censo": "Operativo de recolección asociado a un terremoto y a un municipio.",
    "visita_censo": "Visita de campo realizada como parte de un censo.",
    "registro_censal_persona": "Persona encontrada y registrada durante una visita.",
    "persona": "Persona censada o afectada. La identificación es opcional en el modelo.",
    "hogar": "Unidad de convivencia que puede cambiar de vivienda con el tiempo.",
    "integrante_hogar": "Membresía temporal de una persona en un hogar.",
    "edificacion": "Construcción ubicada en un sector, que puede contener varias viviendas.",
    "vivienda": "Unidad habitacional asociada a una edificación.",
    "habitacion": "Espacio interno de una vivienda, con ocupación y uso propios.",
    "ocupacion_vivienda": "Periodo durante el que un hogar ocupa una vivienda.",
    "ocupacion_habitacion": "Periodo durante el que un hogar ocupa una habitación.",
    "propiedad_vivienda": "Relación temporal entre una persona propietaria y una vivienda.",
    "reporte_dano": "Información recibida sobre daños relacionados con un terremoto.",
    "evidencia": "Referencia a una fotografía, documento u otra evidencia de un reporte o inspección.",
    "afectacion": "Registro general de un daño, clasificado por tipo y vinculado al evento.",
    "afectacion_persona": "Situación de una persona afectada por un terremoto.",
    "afectacion_vivienda": "Detalle de una afectación que corresponde a una vivienda.",
    "afectacion_infraestructura": "Detalle de una afectación que corresponde a infraestructura y tramo.",
    "inspeccion": "Evaluación técnica realizada por personal de campo sobre una afectación.",
    "consecuencia_afectacion": "Efecto derivado de una afectación y su estado de seguimiento.",
    "infraestructura": "Activo o servicio de infraestructura que puede atender varios municipios.",
    "infraestructura_municipio": "Relación territorial de una infraestructura con un municipio.",
    "tramo_infraestructura": "Segmento identificable de una infraestructura lineal.",
    "organizacion": "Entidad que participa en labores de atención o recuperación.",
    "personal_campo": "Integrante de una organización que participa en las visitas o inspecciones.",
    "alojamiento_temporal": "Lugar habilitado para alojar personas u hogares después de un evento.",
    "estancia_alojamiento": "Periodo de alojamiento de una persona o de un hogar.",
    "necesidad": "Necesidad identificada para un hogar a causa de un terremoto.",
    "solicitud_atencion": "Solicitud de atención derivada de una necesidad.",
    "intervencion": "Acción de respuesta vinculada a una afectación y una solicitud.",
    "intervencion_organizacion": "Participación de una organización en una intervención, con su rol.",
}

FIELD_LABELS = {
    "id_departamento": "Identificador del departamento", "id_municipio": "Identificador del municipio",
    "id_sector": "Identificador del sector", "id_terremoto": "Identificador del terremoto",
    "id_censo": "Identificador del censo", "id_visita": "Identificador de la visita",
    "id_persona": "Identificador de la persona", "id_hogar": "Identificador del hogar",
    "id_edificacion": "Identificador de la edificación", "id_vivienda": "Identificador de la vivienda",
    "id_habitacion": "Identificador de la habitación", "id_reporte": "Identificador del reporte",
    "id_afectacion": "Identificador de la afectación", "id_inspeccion": "Identificador de la inspección",
    "id_infraestructura": "Identificador de la infraestructura", "id_tramo": "Identificador del tramo",
    "id_organizacion": "Identificador de la organización", "id_personal": "Identificador del personal",
    "id_alojamiento": "Identificador del alojamiento", "id_necesidad": "Identificador de la necesidad",
    "id_solicitud": "Identificador de la solicitud", "id_intervencion": "Identificador de la intervención",
    "fecha_hora": "Fecha y hora", "fecha_registro": "Fecha de registro", "fecha_reporte": "Fecha del reporte",
    "fecha_inicio": "Fecha de inicio", "fecha_fin": "Fecha de finalización", "fecha_visita": "Fecha de visita",
    "fecha_nacimiento": "Fecha de nacimiento", "fecha_ingreso": "Fecha de ingreso", "fecha_salida": "Fecha de salida",
    "fecha_inspeccion": "Fecha de inspección", "fecha_solicitud": "Fecha de solicitud",
    "fecha_identificacion": "Fecha de identificación", "fecha_registro": "Fecha de registro",
    "fecha_inicio": "Fecha de inicio", "fecha_fin": "Fecha de finalización", "fecha_hora": "Fecha y hora",
    "nombre": "Nombre", "nombres": "Nombres", "apellidos": "Apellidos", "direccion": "Dirección",
    "descripcion": "Descripción", "descripcion_general": "Descripción general", "observaciones": "Observaciones",
    "tipo_documento": "Tipo de documento", "numero_documento": "Número de documento", "telefono": "Teléfono",
    "codigo_dane": "Código DANE", "tipo_sector": "Tipo de sector", "tipo_vivienda": "Tipo de vivienda",
    "numero_unidad": "Número de unidad", "numero_habitacion": "Número de habitación", "numero_pisos": "Número de pisos",
    "tipo_ocupacion": "Tipo de ocupación", "porcentaje_propiedad": "Porcentaje de propiedad",
    "parentesco": "Parentesco", "uso": "Uso", "arrendable_independiente": "¿Se arrienda de forma independiente?",
    "tipo_fuente": "Fuente del reporte", "estado_verificacion": "Estado de verificación", "estado_operativo": "Estado operativo",
    "estado": "Estado", "nivel_dano": "Nivel de daño", "tipo_afectacion": "Tipo de afectación",
    "tipo_infraestructura": "Tipo de infraestructura", "tipo_vinculo": "Tipo de vínculo",
    "tipo_organizacion": "Tipo de organización", "correo": "Correo electrónico", "cargo": "Cargo",
    "capacidad_personas": "Capacidad de personas", "condicion_presencia": "Condición de presencia",
    "situacion": "Situación", "desplazado": "Desplazamiento (0 o 1)", "magnitud": "Magnitud",
    "profundidad_km": "Profundidad (km)", "km_inicio": "Kilómetro inicial", "km_fin": "Kilómetro final",
    "tipo_necesidad": "Tipo de necesidad", "prioridad": "Prioridad", "tipo_intervencion": "Tipo de intervención",
    "tipo_consecuencia": "Tipo de consecuencia", "tipo_evidencia": "Tipo de evidencia", "ruta_archivo": "Ruta de archivo",
    "resultado": "Resultado", "ubicacion_referencia": "Ubicación de referencia", "rol": "Rol",
    "porcentaje_propiedad": "Porcentaje de propiedad", "fecha_registro": "Fecha de registro",
    "hogar_id_hogar": "Hogar", "persona_id_persona": "Persona", "terremoto_id_terremoto": "Terremoto",
    "municipio_id_municipio": "Municipio", "departamento_id_departamento": "Departamento",
    "sector_id_sector": "Sector", "edificacion_id_edificacion": "Edificación", "vivienda_id_vivienda": "Vivienda",
    "habitacion_id_habitacion": "Habitación", "censo_id_censo": "Censo", "visita_censo_id_visita": "Visita de censo",
    "reporte_dano_id_reporte": "Reporte de daño", "afectacion_id_afectacion": "Afectación",
    "personal_campo_id_personal": "Personal de campo", "organizacion_id_organizacion": "Organización",
    "necesidad_id_necesidad": "Necesidad", "solicitud_id": "Solicitud de atención",
    "id_solicitud": "Solicitud de atención", "id_alojamiento": "Alojamiento temporal",
    "tramo_infraestructura_id_tramo": "Tramo de infraestructura", "intervencion_id_intervencion": "Intervención",
}

FIELD_LABELS.update({
    "id_afectacion_persona": "Identificador de afectación a persona", "id_consecuencia": "Identificador de consecuencia",
    "id_estancia": "Identificador de estancia", "id_evidencia": "Identificador de evidencia",
    "id_integrante_hogar": "Identificador de integrante del hogar", "id_ocupacion": "Identificador de ocupación",
    "id_ocupacion_habitacion": "Identificador de ocupación de habitación", "id_propiedad": "Identificador de propiedad",
    "id_registro": "Identificador de registro", "codigo_tramo": "Código del tramo",
    "estado_censo": "Estado del censo", "inspeccion_id_inspeccion": "Inspección",
    "municipio": "Municipio", "sector": "Sector", "organizacion": "Organización",
    "tipo_organizacion": "Tipo de organización", "tipo_consecuencia": "Tipo de consecuencia",
    "tipo_afectacion": "Tipo de afectación", "tipo_infraestructura": "Tipo de infraestructura",
    "tipo_intervencion": "Tipo de intervención", "tipo_necesidad": "Tipo de necesidad",
    "tipo_ocupacion": "Tipo de ocupación", "tipo_vinculo": "Tipo de vínculo",
    "estado_verificacion": "Estado de verificación", "estado_operativo": "Estado operativo",
    "nivel_dano": "Nivel de daño", "codigo_dane": "Código DANE", "fecha_hora": "Fecha y hora",
    "descripcion": "Descripción", "profundidad_km": "Profundidad (km)", "numero_pisos": "Número de pisos",
    "numero_habitacion": "Número de habitación", "numero_unidad": "Número de unidad",
    "numero_documento": "Número de documento", "fecha_nacimiento": "Fecha de nacimiento",
    "fecha_visita": "Fecha de visita", "fecha_inspeccion": "Fecha de inspección",
    "fecha_ingreso": "Fecha de ingreso", "fecha_salida": "Fecha de salida",
    "fecha_solicitud": "Fecha de solicitud", "fecha_identificacion": "Fecha de identificación",
    "fecha_fin": "Fecha de finalización", "fecha_inicio": "Fecha de inicio",
})


VIEW_DEFINITIONS = [
    ("vista_censos_terremoto", "Censos por terremoto", "Municipio, evento sísmico y estado de cada operativo."),
    ("vista_personas_censadas", "Personas censadas", "Personas vinculadas con visitas y censos."),
    ("vista_viviendas_municipio", "Viviendas por municipio", "Viviendas, edificaciones, sectores y municipios."),
    ("vista_afectaciones_vivienda", "Afectaciones a viviendas", "Daños registrados junto con la vivienda y su dirección."),
    ("vista_necesidades_hogar", "Necesidades por hogar", "Necesidades identificadas y terremoto relacionado."),
    ("vista_intervenciones_organizacion", "Intervenciones por organización", "Acciones de respuesta y organizaciones participantes."),
]


def quote_ident(value: str) -> str:
    if not IDENTIFIER_RE.fullmatch(value):
        raise ValueError("Identificador de base de datos no permitido")
    return f'"{value}"'


def b64_json(values) -> str:
    raw = json.dumps(values, ensure_ascii=False, default=str, separators=(",", ":")).encode("utf-8")
    return urlsafe_b64encode(raw).decode("ascii").rstrip("=")


def decode_b64_json(value: str):
    padding = "=" * (-len(value) % 4)
    return json.loads(urlsafe_b64decode(value + padding).decode("utf-8"))


def schema_metadata(conn):
    with conn.cursor() as cur:
        cur.execute("""
            SELECT c.table_name, c.column_name, c.ordinal_position, c.data_type, c.udt_name,
                   c.is_nullable, c.column_default, c.is_identity, c.character_maximum_length
            FROM information_schema.columns c
            JOIN information_schema.tables t
              ON t.table_schema=c.table_schema AND t.table_name=c.table_name
            WHERE c.table_schema=%s AND t.table_type='BASE TABLE'
            ORDER BY c.table_name,c.ordinal_position
        """, (SCHEMA,))
        columns = cur.fetchall()
        cur.execute("""
            SELECT tc.table_name,kcu.column_name,kcu.ordinal_position
            FROM information_schema.table_constraints tc
            JOIN information_schema.key_column_usage kcu
              ON tc.constraint_schema=kcu.constraint_schema AND tc.constraint_name=kcu.constraint_name
             AND tc.table_name=kcu.table_name
            WHERE tc.constraint_schema=%s AND tc.constraint_type='PRIMARY KEY'
            ORDER BY tc.table_name,kcu.ordinal_position
        """, (SCHEMA,))
        pks = cur.fetchall()
        cur.execute("""
            SELECT src.relname AS table_name, con.conname AS constraint_name,
                   ref.relname AS ref_table,
                   array_agg(src_a.attname ORDER BY src_k.ord) AS columns,
                   array_agg(ref_a.attname ORDER BY src_k.ord) AS ref_columns
            FROM pg_constraint con
            JOIN pg_class src ON src.oid=con.conrelid
            JOIN pg_namespace ns ON ns.oid=src.relnamespace
            JOIN pg_class ref ON ref.oid=con.confrelid
            JOIN LATERAL unnest(con.conkey) WITH ORDINALITY src_k(attnum,ord) ON true
            JOIN LATERAL unnest(con.confkey) WITH ORDINALITY ref_k(attnum,ord) ON ref_k.ord=src_k.ord
            JOIN pg_attribute src_a ON src_a.attrelid=src.oid AND src_a.attnum=src_k.attnum
            JOIN pg_attribute ref_a ON ref_a.attrelid=ref.oid AND ref_a.attnum=ref_k.attnum
            WHERE ns.nspname=%s AND con.contype='f'
            GROUP BY src.relname,con.conname,ref.relname
            ORDER BY src.relname,con.conname
        """, (SCHEMA,))
        fks = cur.fetchall()
    by_table = {}
    for col in columns:
        by_table.setdefault(col["table_name"], {"columns": [], "fks": [], "pk": []})["columns"].append(col)
    for row in pks:
        by_table.setdefault(row["table_name"], {"columns": [], "fks": [], "pk": []})["pk"].append(row["column_name"])
    for row in fks:
        by_table.setdefault(row["table_name"], {"columns": [], "fks": [], "pk": []})["fks"].append(row)
    return by_table


def field_label(name: str) -> str:
    if name in FIELD_LABELS:
        return FIELD_LABELS[name]
    text = name.replace("_", " ").strip()
    text = re.sub(r"\bid\b", "identificador", text)
    return text[:1].upper() + text[1:]


def type_value(raw: str, column: dict):
    if raw == "":
        return None
    data_type = column["data_type"]
    try:
        if data_type in ("smallint", "integer", "bigint"):
            return int(raw)
        if data_type in ("numeric", "decimal", "real", "double precision"):
            return Decimal(raw)
        if data_type == "date":
            return date.fromisoformat(raw)
        if data_type in ("timestamp without time zone", "timestamp with time zone"):
            return datetime.fromisoformat(raw)
        if data_type == "boolean":
            return raw.lower() in ("1", "true", "on", "sí", "si")
        return raw.strip()
    except (ValueError, InvalidOperation) as exc:
        raise ValueError(f"El valor de «{field_label(column['column_name'])}» no tiene el formato correcto.") from exc


def cell_value(value):
    if value is None:
        return "—"
    if isinstance(value, (datetime, date)):
        return value.strftime("%d/%m/%Y %H:%M" if isinstance(value, datetime) else "%d/%m/%Y")
    return str(value)


def fk_choices(conn, fk, metadata):
    target = metadata.get(fk["ref_table"])
    if not target:
        return []
    ref_cols = fk["ref_columns"]
    key_names = target["pk"]
    text_columns = [c["column_name"] for c in target["columns"]
                    if c["data_type"] in ("character varying", "character", "text") and c["column_name"] not in key_names]
    display_cols = text_columns[:2]
    select_names = list(dict.fromkeys(ref_cols + display_cols))
    sql = "SELECT " + ",".join(quote_ident(c) for c in select_names) + " FROM " + quote_ident(SCHEMA) + "." + quote_ident(fk["ref_table"])
    sql += " ORDER BY " + ",".join(quote_ident(c) for c in display_cols or key_names) + " LIMIT 500"
    with conn.cursor() as cur:
        cur.execute(sql)
        rows = cur.fetchall()
    choices = []
    for row in rows:
        key_values = [row[c] for c in ref_cols]
        parts = [str(row[c]) for c in display_cols if row[c] not in (None, "")]
        label = " · ".join(parts) if parts else " / ".join(map(str, key_values))
        if len(ref_cols) > 1:
            label += " (" + ", ".join(map(str, key_values)) + ")"
        choices.append({"value": b64_json(key_values), "label": label})
    return choices


def describe_table(conn, table, metadata, existing=None, editing=False):
    info = metadata[table]
    columns = info["columns"]
    by_name = {c["column_name"]: c for c in columns}
    fks = info["fks"]
    covered = set()
    fields = []
    fk_values = {}
    for fk in fks:
        choices = fk_choices(conn, fk, metadata)
        current = None
        if existing:
            vals = [existing.get(c) for c in fk["columns"]]
            current = b64_json(vals) if all(v is not None for v in vals) else ""
        fk_values.update({c: existing.get(c) for c in fk["columns"]} if existing else {})
        name = fk["columns"][0]
        covered.update(fk["columns"])
        # Las claves foráneas del modelo tienen grupos sin columnas compartidas.
        fields.append({"name": "fk__" + fk["constraint_name"], "label": field_label(name) if len(fk["columns"]) == 1 else field_label(fk["ref_table"]),
                       "kind": "select", "required": any(by_name[c]["is_nullable"] == "NO" for c in fk["columns"]),
                       "options": choices, "value": current or "", "columns": fk["columns"], "constraint": fk["constraint_name"],
                       "locked": bool(existing and any(c in info["pk"] for c in fk["columns"])),
                       "hint": "Selecciona un registro relacionado."})

    for column in columns:
        name = column["column_name"]
        if name in covered:
            continue
        if editing and name in info["pk"]:
            continue
        if column["is_identity"] == "YES":
            continue
        raw = existing.get(name) if existing else None
        data_type = column["data_type"]
        kind = "text"
        if data_type == "date":
            kind = "date"
        elif data_type.startswith("timestamp"):
            kind = "datetime-local"
        elif data_type in ("smallint", "integer", "bigint", "numeric", "decimal", "real", "double precision"):
            kind = "number"
        elif data_type == "boolean":
            kind = "checkbox"
        elif name in ("descripcion", "descripcion_general", "observaciones", "resultado", "ruta_archivo"):
            kind = "textarea"
        fields.append({"name": name, "label": field_label(name), "kind": kind,
                       "required": column["is_nullable"] == "NO" and not column["column_default"],
                       "value": "" if raw is None else (raw.strftime("%Y-%m-%dT%H:%M") if isinstance(raw, datetime) else raw.isoformat() if isinstance(raw, date) else str(raw)),
                       "hint": f"Máximo {column['character_maximum_length']} caracteres." if column["character_maximum_length"] else ""})
    if editing:
        fields.insert(0, {"name": "_key_info", "label": "Clave primaria", "kind": "readonly",
                          "value": " · ".join(f"{field_label(k)}: {cell_value(existing.get(k))}" for k in info["pk"]), "required": False})
    return fields


def fetch_table_rows(conn, table, info, limit=100, only_person_id=None):
    order = info["pk"] or [info["columns"][0]["column_name"]]
    sql = "SELECT * FROM " + quote_ident(SCHEMA) + "." + quote_ident(table)
    params = []
    if table == "persona" and only_person_id is not None:
        sql += " WHERE id_persona=%s"
        params.append(only_person_id)
    sql += " ORDER BY " + ",".join(quote_ident(c) for c in order) + " LIMIT %s"
    params.append(limit)
    with conn.cursor() as cur:
        cur.execute(sql, params)
        rows = cur.fetchall()
    for row in rows:
        row["_key"] = b64_json([row[k] for k in info["pk"]])
    return rows


def find_row(conn, table, info, token):
    try:
        values = decode_b64_json(token)
    except Exception:
        abort(404)
    if len(values) != len(info["pk"]):
        abort(404)
    by_name = {c["column_name"]: c for c in info["columns"]}
    converted = [type_value(str(v), by_name[k]) if v is not None else None for k, v in zip(info["pk"], values)]
    predicate = " AND ".join(f"{quote_ident(k)} IS NOT DISTINCT FROM %s" for k in info["pk"])
    with conn.cursor() as cur:
        cur.execute(f"SELECT * FROM {quote_ident(SCHEMA)}.{quote_ident(table)} WHERE {predicate}", converted)
        row = cur.fetchone()
    if not row:
        abort(404)
    return row


def apply_post(conn, table, info, metadata, existing=None):
    by_name = {c["column_name"]: c for c in info["columns"]}
    values = {}
    for fk in info["fks"]:
        form_value = request.form.get("fk__" + fk["constraint_name"], "")
        if form_value:
            try:
                selected = decode_b64_json(form_value)
            except Exception as exc:
                raise ValueError("La relación seleccionada no es válida; vuelve a elegirla.") from exc
            if len(selected) != len(fk["columns"]):
                raise ValueError("La relación seleccionada no es válida.")
            for col, raw in zip(fk["columns"], selected):
                values[col] = type_value(str(raw), by_name[col]) if raw is not None else None
        elif existing is not None:
            values.update({col: existing.get(col) for col in fk["columns"]})
        elif any(by_name[c]["is_nullable"] == "NO" for c in fk["columns"]):
            raise ValueError(f"Debes seleccionar {field_label(fk['columns'][0])}.")
        else:
            values.update({col: None for col in fk["columns"]})

    covered = {c for fk in info["fks"] for c in fk["columns"]}
    for column in info["columns"]:
        name = column["column_name"]
        if name in covered or name in info["pk"] or column["is_identity"] == "YES":
            continue
        if column["data_type"] == "boolean":
            values[name] = request.form.get(name) in {"true", "on", "1"}
            continue
        if name not in request.form:
            continue
        raw = request.form.get(name, "").strip()
        if not raw and column["is_nullable"] == "NO" and not column["column_default"]:
            raise ValueError(f"El campo «{field_label(name)}» es obligatorio.")
        values[name] = type_value(raw, column)

    if existing is None:
        insert_values = {}
        for column in info["columns"]:
            name = column["column_name"]
            if column["is_identity"] == "YES":
                continue
            if name in values:
                insert_values[name] = values[name]
            elif name in request.form:
                insert_values[name] = type_value(request.form.get(name, "").strip(), column)
        if not insert_values:
            raise ValueError("No hay campos para guardar en esta entidad.")
        names = list(insert_values)
        sql = f"INSERT INTO {quote_ident(SCHEMA)}.{quote_ident(table)} (" + ",".join(quote_ident(n) for n in names) + ") VALUES (" + ",".join(["%s"] * len(names)) + ")"
        with conn.cursor() as cur:
            cur.execute(sql, [insert_values[n] for n in names])
    else:
        updates = {name: value for name, value in values.items() if name not in info["pk"]}
        # Columnas ordinarias que no pertenecen a una FK.
        for column in info["columns"]:
            name = column["column_name"]
            if name in covered or name in info["pk"] or column["is_identity"] == "YES":
                continue
            if column["data_type"] == "boolean":
                updates[name] = request.form.get(name) in {"true", "on", "1"}
                continue
            if name not in request.form:
                continue
            updates[name] = type_value(request.form.get(name, "").strip(), column)
        if updates:
            set_sql = ",".join(f"{quote_ident(n)}=%s" for n in updates)
            predicate = " AND ".join(f"{quote_ident(k)} IS NOT DISTINCT FROM %s" for k in info["pk"])
            key_values = [existing[k] for k in info["pk"]]
            with conn.cursor() as cur:
                cur.execute(f"UPDATE {quote_ident(SCHEMA)}.{quote_ident(table)} SET {set_sql} WHERE {predicate}", list(updates.values()) + key_values)


def csrf_token():
    token = session.get("csrf_token")
    if not token:
        token = secrets.token_urlsafe(24)
        session["csrf_token"] = token
    return token


@app.context_processor
def inject_globals():
    user = getattr(g, "current_user", None)
    return {
        "current_year": date.today().year,
        "csrf_token": csrf_token(),
        "entity_labels": ENTITY_LABELS,
        "label_for": field_label,
        "current_user": user,
        "can_manage": bool(user and user["rol"] == "administrador"),
        "admin_bootstrap_enabled": bool(configured_bootstrap_key),
        "is_production": is_production,
    }


@app.before_request
def load_user_and_protect_forms():
    if request.method == "POST":
        supplied = request.form.get("csrf_token", "")
        expected = session.get("csrf_token", "")
        if not supplied or not secrets.compare_digest(supplied, expected):
            abort(400, "La sesión del formulario expiró. Recarga la página e inténtalo de nuevo.")
    if request.endpoint in {"login", "register", "admin_bootstrap", "health", "health_database", "static"}:
        g.current_user = None
        return
    user_id = session.get("user_id")
    if not user_id:
        return redirect(url_for("login", next=request.path))
    with connect_db() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT id_usuario,nombre_usuario,rol,persona_id_persona,activo "
                "FROM usuario_app WHERE id_usuario=%s",
                (user_id,),
            )
            user = cur.fetchone()
    if not user or not user["activo"]:
        session.clear()
        return redirect(url_for("login"))
    if user["rol"] == "persona" and not user["persona_id_persona"]:
        abort(403, "Esta cuenta todavía no está vinculada con una persona censada. Solicita ayuda al administrador.")
    g.current_user = user


@app.route("/login", methods=["GET", "POST"])
def login():
    if session.get("user_id"):
        return redirect(url_for("dashboard"))
    if request.method == "POST":
        username = request.form.get("nombre_usuario", "").strip()
        password = request.form.get("contrasena", "")
        with connect_db() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "SELECT id_usuario,nombre_usuario,password_hash,rol,persona_id_persona,activo "
                    "FROM usuario_app WHERE lower(nombre_usuario)=lower(%s)",
                    (username,),
                )
                user = cur.fetchone()
        if not user or not user["activo"] or not check_password_hash(user["password_hash"], password):
            flash("Usuario o contraseña incorrectos.", "error")
            return render_template("login.html")
        session.clear()
        session["user_id"] = user["id_usuario"]
        session["csrf_token"] = secrets.token_urlsafe(24)
        destination = request.args.get("next", "")
        if not destination.startswith("/") or destination.startswith("//"):
            destination = url_for("dashboard")
        return redirect(destination)
    return render_template("login.html")


@app.route("/registro", methods=["GET", "POST"])
def register():
    if session.get("user_id"):
        return redirect(url_for("dashboard"))
    form_values = {"nombre_usuario": "", "nombres": "", "apellidos": ""}
    if request.method == "POST":
        username = request.form.get("nombre_usuario", "").strip().lower()
        names = request.form.get("nombres", "").strip()
        surnames = request.form.get("apellidos", "").strip()
        password = request.form.get("contrasena", "")
        confirmation = request.form.get("confirmacion", "")
        form_values = {"nombre_usuario": username, "nombres": names, "apellidos": surnames}

        if not re.fullmatch(r"[a-z0-9._-]{3,50}", username):
            flash("El usuario debe tener entre 3 y 50 letras, números, puntos, guiones o guiones bajos.", "error")
        elif not names or len(names) > 80 or len(surnames) > 80:
            flash("Escribe tu nombre y un apellido de hasta 80 caracteres.", "error")
        elif len(password) < 10:
            flash("La contraseña debe tener al menos 10 caracteres.", "error")
        elif password != confirmation:
            flash("Las contraseñas no coinciden.", "error")
        else:
            try:
                with connect_db() as conn:
                    with conn.cursor() as cur:
                        cur.execute(
                            "INSERT INTO persona(nombres,apellidos) VALUES (%s,%s) RETURNING id_persona",
                            (names, surnames or None),
                        )
                        person_id = cur.fetchone()["id_persona"]
                        cur.execute(
                            "INSERT INTO usuario_app(nombre_usuario,password_hash,rol,persona_id_persona,activo) "
                            "VALUES (%s,%s,'persona',%s,true)",
                            (username, generate_password_hash(password), person_id),
                        )
                flash("Cuenta creada. Ya puedes iniciar sesión.", "success")
                return redirect(url_for("login"))
            except psycopg.errors.UniqueViolation:
                flash("Ese nombre de usuario ya está registrado. Elige otro.", "error")
    return render_template("register.html", form=form_values)


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/health/database")
def health_database():
    try:
        with connect_db() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT 1")
                cur.fetchone()
    except psycopg.Error as error:
        app.logger.error("PostgreSQL health check failed [%s]: %s", type(error).__name__, error)
        return {"status": "database_unavailable", "error": type(error).__name__}, 503
    return {"status": "ok", "database": "connected"}


@app.route("/admin/bootstrap", methods=["GET", "POST"])
def admin_bootstrap():
    if not configured_bootstrap_key:
        abort(404)

    with connect_db() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT 1 FROM admin_bootstrap_state LIMIT 1")
            if cur.fetchone():
                abort(410, "El registro especial de administrador ya fue utilizado.")

    form_values = {"nombre_usuario": ""}
    if request.method == "POST":
        supplied_key = request.form.get("clave_alta", "")
        username = request.form.get("nombre_usuario", "").strip().lower()
        password = request.form.get("contrasena", "")
        confirmation = request.form.get("confirmacion", "")
        form_values["nombre_usuario"] = username

        if not secrets.compare_digest(configured_bootstrap_key, supplied_key):
            flash("La clave especial no es válida.", "error")
        elif not re.fullmatch(r"[a-z0-9._-]{3,50}", username):
            flash("El usuario debe tener entre 3 y 50 letras, números, puntos, guiones o guiones bajos.", "error")
        elif len(password) < 10:
            flash("La contraseña debe tener al menos 10 caracteres.", "error")
        elif password != confirmation:
            flash("Las contraseñas no coinciden.", "error")
        else:
            try:
                with connect_db() as conn:
                    with conn.cursor() as cur:
                        cur.execute("SELECT pg_advisory_xact_lock(724103, 2)")
                        cur.execute("SELECT 1 FROM admin_bootstrap_state LIMIT 1")
                        if cur.fetchone():
                            abort(410, "El registro especial de administrador ya fue utilizado.")
                        cur.execute(
                            "INSERT INTO usuario_app(nombre_usuario,password_hash,rol,activo) "
                            "VALUES (%s,%s,'administrador',true) RETURNING id_usuario",
                            (username, generate_password_hash(password)),
                        )
                        admin_id = cur.fetchone()["id_usuario"]
                        cur.execute(
                            "INSERT INTO admin_bootstrap_state(singleton,admin_id) VALUES (true,%s)",
                            (admin_id,),
                        )
                flash("Cuenta de administrador creada. Inicia sesión con tu usuario y contraseña propios.", "success")
                return redirect(url_for("login"))
            except psycopg.errors.UniqueViolation:
                flash("Ese nombre de usuario ya existe. Elige otro.", "error")
    return render_template("admin_bootstrap.html", form=form_values)


@app.post("/salir")
def logout():
    session.clear()
    flash("Sesión cerrada.", "success")
    return redirect(url_for("login"))


@app.get("/")
def dashboard():
    counts = {"terremotos": 0, "municipios": 0, "personas": 0, "viviendas": 0, "hogares": 0, "reportes": 0}
    latest = []
    with connect_db() as conn:
        metadata = schema_metadata(conn)
        expected_tables = set(metadata)
        for label, table in (("terremotos", "terremoto"), ("municipios", "municipio"), ("personas", "persona"), ("viviendas", "vivienda"), ("hogares", "hogar"), ("reportes", "reporte_dano")):
            if table in expected_tables:
                with conn.cursor() as cur:
                    cur.execute(f"SELECT count(*) AS total FROM {quote_ident(SCHEMA)}.{quote_ident(table)}")
                    counts[label] = cur.fetchone()["total"]
        if "terremoto" in expected_tables:
            with conn.cursor() as cur:
                cur.execute(f"SELECT id_terremoto,fecha_hora,magnitud,descripcion FROM {quote_ident(SCHEMA)}.terremoto ORDER BY fecha_hora DESC LIMIT 5")
                latest = cur.fetchall()
    if not metadata:
        return render_template("error.html", code="Esquema pendiente", message="La base de datos está disponible, pero no se encuentra el esquema censo_terremoto. Ejecuta .\\init-db.ps1 para crear las tablas y cargar los datos ficticios."), 503
    return render_template("dashboard.html", active="inicio", counts=counts, latest=latest, views=VIEW_DEFINITIONS)


@app.get("/entidades")
def entities_page():
    with connect_db() as conn:
        metadata = schema_metadata(conn)
    groups = []
    for group, tables in ENTITY_GROUPS.items():
        group_items = [{"table": table, "label": ENTITY_LABELS[table], "description": ENTITY_DESCRIPTIONS[table]}
                       for table in tables if table in metadata]
        if group_items:
            groups.append({"name": group, "items": group_items})
    return render_template("entities.html", active="datos", groups=groups, total=len([table for table in metadata if table in ENTITY_LABELS]))


@app.route("/entidades/<table>", methods=["GET", "POST"])
def entity_page(table):
    if not IDENTIFIER_RE.fullmatch(table) or table not in ENTITY_LABELS:
        abort(404)
    user = g.current_user
    can_manage_records = user["rol"] in {"administrador", "encargado"}
    can_delete_records = user["rol"] == "administrador"
    editing = request.args.get("editar", "")
    try:
        with connect_db() as conn:
            metadata = schema_metadata(conn)
            if table not in metadata:
                abort(404)
            info = metadata[table]
            existing = find_row(conn, table, info, editing) if editing else None

            if not can_manage_records and user["rol"] == "persona":
                if table != "persona" or not editing or not existing:
                    if request.method == "POST":
                        abort(403)
                elif existing["id_persona"] != user["persona_id_persona"]:
                    abort(403)

            if request.method == "POST":
                action = request.form.get("action", "save")
                if action == "delete":
                    if not can_delete_records:
                        abort(403)
                    try:
                        key = decode_b64_json(request.form.get("key", ""))
                        if len(key) != len(info["pk"]):
                            raise ValueError
                        by_name = {c["column_name"]: c for c in info["columns"]}
                        key = [type_value(str(v), by_name[k]) if v is not None else None for k, v in zip(info["pk"], key)]
                    except Exception:
                        raise ValueError("La clave del registro no es v\u00e1lida.")
                    predicate = " AND ".join(f"{quote_ident(k)} IS NOT DISTINCT FROM %s" for k in info["pk"])
                    with conn.cursor() as cur:
                        cur.execute(f"DELETE FROM {quote_ident(SCHEMA)}.{quote_ident(table)} WHERE {predicate}", key)
                    flash("Registro eliminado.", "success")
                    return redirect(url_for("entity_page", table=table))

                if not can_manage_records and (table != "persona" or not existing or existing["id_persona"] != user["persona_id_persona"]):
                    abort(403)
                apply_post(conn, table, info, metadata, existing)
                flash("Cambios guardados correctamente.", "success")
                return redirect(url_for("entity_page", table=table))

            fields = describe_table(conn, table, metadata, existing=existing, editing=bool(existing))
            only_person_id = user["persona_id_persona"] if user["rol"] == "persona" and table == "persona" else None
            rows = fetch_table_rows(conn, table, info, only_person_id=only_person_id)
            columns = [c["column_name"] for c in info["columns"]]
            for row in rows:
                row["_display"] = {c: cell_value(row[c]) for c in columns}
    except psycopg.OperationalError:
        return render_template("error.html", code="Conexi\u00f3n con PostgreSQL", message="No se pudo conectar con la cuenta de aplicaci\u00f3n. Ejecuta .\\init-db.ps1 para preparar los permisos y vuelve a iniciar Terra."), 503
    except psycopg.errors.UndefinedTable:
        return render_template("error.html", code="Esquema pendiente", message="Faltan tablas del proyecto. Ejecuta .\\init-db.ps1 para crear o actualizar el esquema."), 503
    except psycopg.Error as exc:
        if isinstance(exc, psycopg.errors.ForeignKeyViolation):
            message = "No se puede borrar este registro porque hay datos relacionados. Reasigna o elimina primero esos registros."
        elif isinstance(exc, psycopg.errors.UniqueViolation):
            message = "Ya existe un registro con esos datos\u00fanicos. Revisa los valores e int\u00e9ntalo de nuevo."
        elif isinstance(exc, psycopg.errors.CheckViolation):
            message = "Uno de los valores incumple una regla del modelo, como un rango o una fecha. Revisa el formulario."
        elif isinstance(exc, psycopg.errors.NotNullViolation):
            message = "Falta un dato obligatorio. Completa los campos marcados y vuelve a guardar."
        else:
            message = "No fue posible guardar el registro. Revisa las relaciones y los datos del formulario."
        flash(message, "error")
        return redirect(url_for("entity_page", table=table, editar=editing) if editing else url_for("entity_page", table=table))
    except ValueError as exc:
        flash(str(exc), "error")
        return redirect(url_for("entity_page", table=table, editar=editing) if editing else url_for("entity_page", table=table))
    return render_template(
        "entity.html", active="datos", table=table, label=ENTITY_LABELS[table],
        description=ENTITY_DESCRIPTIONS[table], group=next((group for group, tables in ENTITY_GROUPS.items() if table in tables), "Datos"),
        fields=fields, rows=rows, columns=columns, editing=bool(existing), edit_token=editing,
        primary_keys=info["pk"], truncated=len(rows) == 100,
        can_manage_records=can_manage_records, can_delete_records=can_delete_records,
        current_persona_id=user["persona_id_persona"],
    )


def require_admin():
    if g.current_user["rol"] != "administrador":
        abort(403)


@app.route("/usuarios", methods=["GET", "POST"])
def users_page():
    require_admin()
    roles = ("administrador", "encargado", "persona")
    try:
        with connect_db() as conn:
            if request.method == "POST":
                action = request.form.get("action", "")
                if action in {"actualizar", "eliminar"}:
                    # Serializa cambios de perfiles para que no se elimine por concurrencia el ?ltimo administrador.
                    with conn.cursor() as cur:
                        cur.execute("SELECT pg_advisory_xact_lock(724103, 1)")
                if action == "crear":
                    username = request.form.get("nombre_usuario", "").strip().lower()
                    password = request.form.get("contrasena", "")
                    role = request.form.get("rol", "")
                    persona_raw = request.form.get("persona_id_persona", "").strip()
                    persona_id = int(persona_raw) if persona_raw else None
                    if not re.fullmatch(r"[a-z0-9._-]{3,50}", username):
                        raise ValueError("El usuario debe tener entre 3 y 50 letras, n\u00fameros, puntos, guiones o guiones bajos.")
                    if len(password) < 10:
                        raise ValueError("La contrase\u00f1a debe tener al menos 10 caracteres.")
                    if role not in roles:
                        raise ValueError("Selecciona un perfil v\u00e1lido.")
                    if role == "persona" and persona_id is None:
                        raise ValueError("El perfil persona debe estar vinculado a una persona del censo.")
                    with conn.cursor() as cur:
                        cur.execute(
                            "INSERT INTO usuario_app(nombre_usuario,password_hash,rol,persona_id_persona,activo) "
                            "VALUES (%s,%s,%s,%s,true)",
                            (username, generate_password_hash(password), role, persona_id),
                        )
                    flash("Cuenta creada correctamente.", "success")
                elif action == "actualizar":
                    account_id = int(request.form.get("id_usuario", "0"))
                    role = request.form.get("rol", "")
                    persona_raw = request.form.get("persona_id_persona", "").strip()
                    persona_id = int(persona_raw) if persona_raw else None
                    active = request.form.get("activo") == "on"
                    password = request.form.get("contrasena", "")
                    if role not in roles:
                        raise ValueError("Selecciona un perfil v\u00e1lido.")
                    if role == "persona" and persona_id is None:
                        raise ValueError("El perfil persona debe estar vinculado a una persona del censo.")
                    if password and len(password) < 10:
                        raise ValueError("La contrase\u00f1a nueva debe tener al menos 10 caracteres.")
                    with conn.cursor() as cur:
                        cur.execute("SELECT id_usuario,rol,activo FROM usuario_app WHERE id_usuario=%s FOR UPDATE", (account_id,))
                        account = cur.fetchone()
                        if not account:
                            abort(404)
                        would_remove_admin = account["rol"] == "administrador" and account["activo"] and (role != "administrador" or not active)
                        if would_remove_admin:
                            cur.execute("SELECT count(*) AS total FROM usuario_app WHERE rol='administrador' AND activo=true")
                            if cur.fetchone()["total"] <= 1:
                                raise ValueError("Debe quedar al menos una cuenta de administrador activa.")
                        if account_id == g.current_user["id_usuario"] and not active:
                            raise ValueError("No puedes desactivar la cuenta con la que iniciaste sesi\u00f3n.")
                        if password:
                            cur.execute(
                                "UPDATE usuario_app SET rol=%s,persona_id_persona=%s,activo=%s,password_hash=%s WHERE id_usuario=%s",
                                (role, persona_id, active, generate_password_hash(password), account_id),
                            )
                        else:
                            cur.execute(
                                "UPDATE usuario_app SET rol=%s,persona_id_persona=%s,activo=%s WHERE id_usuario=%s",
                                (role, persona_id, active, account_id),
                            )
                    flash("Cuenta actualizada.", "success")
                elif action == "eliminar":
                    account_id = int(request.form.get("id_usuario", "0"))
                    if account_id == g.current_user["id_usuario"]:
                        raise ValueError("No puedes eliminar la cuenta con la que iniciaste sesi\u00f3n.")
                    with conn.cursor() as cur:
                        cur.execute("SELECT rol,activo FROM usuario_app WHERE id_usuario=%s FOR UPDATE", (account_id,))
                        account = cur.fetchone()
                        if not account:
                            abort(404)
                        if account["rol"] == "administrador" and account["activo"]:
                            cur.execute("SELECT count(*) AS total FROM usuario_app WHERE rol='administrador' AND activo=true")
                            if cur.fetchone()["total"] <= 1:
                                raise ValueError("Debe quedar al menos una cuenta de administrador activa.")
                        cur.execute("DELETE FROM usuario_app WHERE id_usuario=%s", (account_id,))
                    flash("Cuenta eliminada.", "success")
                else:
                    raise ValueError("La operaci\u00f3n solicitada no es v\u00e1lida.")
                return redirect(url_for("users_page"))

            with conn.cursor() as cur:
                cur.execute("""
                    SELECT u.id_usuario,u.nombre_usuario,u.rol,u.persona_id_persona,u.activo,
                           p.nombres,p.apellidos
                    FROM usuario_app u
                    LEFT JOIN persona p ON p.id_persona=u.persona_id_persona
                    ORDER BY u.nombre_usuario
                """)
                users = cur.fetchall()
                cur.execute("""
                    SELECT p.id_persona,p.nombres,p.apellidos,p.numero_documento
                    FROM persona p
                    WHERE NOT EXISTS (
                        SELECT 1 FROM usuario_app u WHERE u.persona_id_persona=p.id_persona
                    )
                    ORDER BY p.apellidos,p.nombres
                    LIMIT 500
                """)
                available_people = cur.fetchall()
    except psycopg.errors.UniqueViolation:
        flash("El nombre de usuario ya existe o esa persona ya tiene una cuenta.", "error")
        return redirect(url_for("users_page"))
    except psycopg.errors.ForeignKeyViolation:
        flash("La persona relacionada ya no existe. Actualiza la selecci\u00f3n e int\u00e9ntalo otra vez.", "error")
        return redirect(url_for("users_page"))
    except (ValueError, TypeError) as exc:
        flash(str(exc), "error")
        return redirect(url_for("users_page"))
    return render_template("users.html", active="usuarios", users=users, roles=roles, people=available_people)


@app.get("/consultas")
def queries_page():
    return render_template("queries.html", active="consultas", views=VIEW_DEFINITIONS)


@app.get("/consultas/<view_name>")
def query_view(view_name):
    allowed = {row[0] for row in VIEW_DEFINITIONS}
    if view_name not in allowed:
        abort(404)
    with connect_db() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT * FROM " + quote_ident(SCHEMA) + "." + quote_ident(view_name) + " LIMIT 500")
            rows = cur.fetchall()
        columns = list(rows[0].keys()) if rows else []
        if not columns:
            with conn.cursor() as cur:
                cur.execute("SELECT column_name FROM information_schema.columns WHERE table_schema=%s AND table_name=%s ORDER BY ordinal_position", (SCHEMA, view_name))
                columns = [r["column_name"] for r in cur.fetchall()]
    label, description = next((name, text) for table, name, text in VIEW_DEFINITIONS if table == view_name)
    display_rows = [{col: cell_value(row.get(col)) for col in columns} for row in rows]
    return render_template("query_result.html", active="consultas", view_name=view_name, label=label,
                           description=description, columns=columns, rows=display_rows, truncated=len(rows) == 500)


@app.get("/documentacion")
def documentation_page():
    return render_template("documentation.html", active="documentacion")


@app.errorhandler(400)
@app.errorhandler(403)
@app.errorhandler(404)
def request_error(error):
    return render_template("error.html", code=error.code, message=getattr(error, "description", "La solicitud no se pudo procesar.")), error.code


@app.errorhandler(psycopg.errors.UndefinedTable)
def missing_table_error(error):
    return render_template("error.html", code="Actualización pendiente", message="La base todavía no tiene las tablas de acceso de esta versión. Ejecuta .\\init-db.ps1 para actualizarla sin borrar los datos."), 503


@app.errorhandler(psycopg.OperationalError)
def database_error(error):
    app.logger.error("PostgreSQL connection failed [%s]: %s", type(error).__name__, error)
    return render_template("error.html", code="Conexión con PostgreSQL", message="Terra no pudo conectar con la base en la nube. Revisa DATABASE_URL y la disponibilidad de Neon."), 503


@app.errorhandler(psycopg.Error)
def query_database_error(error):
    app.logger.exception("Fall? una operaci?n de base de datos")
    return render_template(
        "error.html",
        code="Error de base de datos",
        message="No se pudo completar la operaci?n. Revisa que init-db.ps1 haya terminado correctamente y vuelve a intentarlo.",
    ), 503


@app.errorhandler(Exception)
def unexpected_error(error):
    if isinstance(error, HTTPException):
        return error
    app.logger.exception("Error inesperado en la aplicación", exc_info=error)
    return render_template("error.html", code="Error interno", message="Ocurrió un error inesperado. Vuelve a la página anterior; si continúa, revisa la consola de PowerShell donde se inició Terra."), 500


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=int(os.getenv("PORT", "5000")), debug=False)
