from __future__ import annotations

import getpass
from pathlib import Path

import psycopg


ROOT = Path(__file__).resolve().parent.parent
SCHEMA = "censo_terremoto"


def initialize_database(connection_url: str) -> None:
    if not connection_url.strip():
        raise ValueError("La URL de conexión de Neon es obligatoria.")

    script = (ROOT / "sql" / "00_proyecto_completo.sql").read_text(encoding="utf-8-sig")
    with psycopg.connect(connection_url, autocommit=True) as conn:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT 1 FROM information_schema.schemata WHERE schema_name=%s",
                (SCHEMA,),
            )
            if cur.fetchone():
                raise ValueError(
                    f"El esquema {SCHEMA} ya existe; se cancela para no sobrescribir la base."
                )

        conn.execute(script, prepare=False)
        with conn.cursor() as cur:
            cur.execute(
                "SELECT count(*) FROM information_schema.tables "
                "WHERE table_schema=%s AND table_type='BASE TABLE'",
                (SCHEMA,),
            )
            table_count = cur.fetchone()[0]
            cur.execute(
                "SELECT count(*) FROM information_schema.views WHERE table_schema=%s",
                (SCHEMA,),
            )
            view_count = cur.fetchone()[0]
            if table_count != 38 or view_count != 6:
                raise RuntimeError(
                    f"Carga incompleta: se esperaban 38 tablas y 6 vistas; "
                    f"se encontraron {table_count} tablas y {view_count} vistas."
                )


def main() -> None:
    connection_url = getpass.getpass(
        "URL de PostgreSQL de Neon (entrada oculta; no se guardará): "
    )
    initialize_database(connection_url)
    print("Base alojada inicializada con esquema, datos ficticios y seis vistas.")


if __name__ == "__main__":
    main()
