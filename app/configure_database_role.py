from __future__ import annotations

import os
import re
import secrets
from pathlib import Path

import psycopg
from psycopg import sql


ROOT = Path(__file__).resolve().parent.parent
SCHEMA = "censo_terremoto"


def read_project_env() -> None:
    path = ROOT / ".env"
    if not path.exists():
        return
    for raw in path.read_text(encoding="utf-8-sig").splitlines():
        line = raw.strip()
        if line and not line.startswith("#") and "=" in line:
            key, value = line.split("=", 1)
            os.environ.setdefault(key.strip(), value.strip().strip("\"'"))


def save_app_password(username: str, password: str) -> None:
    path = ROOT / ".env"
    lines = path.read_text(encoding="utf-8-sig").splitlines() if path.exists() else []
    updates = {"PGAPPUSER": username, "PGAPPPASSWORD": password}
    found = set()
    output = []
    for line in lines:
        key = line.split("=", 1)[0].strip() if "=" in line and not line.lstrip().startswith("#") else ""
        if key in updates:
            output.append(f"{key}={updates[key]}")
            found.add(key)
        else:
            output.append(line)
    for key, value in updates.items():
        if key not in found:
            output.append(f"{key}={value}")
    path.write_text("\n".join(output).rstrip() + "\n", encoding="utf-8")


def main() -> None:
    read_project_env()
    admin_user = os.getenv("PGUSER", "postgres")
    admin_password = os.getenv("PGPASSWORD", "")
    app_user = os.getenv("PGAPPUSER", "censo_app")
    app_password = os.getenv("PGAPPPASSWORD", "")
    if not re.fullmatch(r"[a-z_][a-z0-9_]*", app_user):
        raise SystemExit("PGAPPUSER debe contener solo letras minúsculas, números y guion bajo.")
    if not app_password or app_password.startswith("CAMBIA_") or app_password.startswith("GENERAR_"):
        app_password = secrets.token_urlsafe(36)
        save_app_password(app_user, app_password)

    connection = psycopg.connect(
        host=os.getenv("PGHOST", "localhost"),
        port=os.getenv("PGPORT", "5432"),
        dbname=os.getenv("PGDATABASE", "censo_terremoto"),
        user=admin_user,
        password=admin_password,
        connect_timeout=5,
    )
    with connection:
        with connection.cursor() as cur:
            cur.execute("SELECT 1 FROM pg_roles WHERE rolname=%s", (app_user,))
            role_exists = cur.fetchone() is not None
            role_sql = sql.SQL("ALTER ROLE {} WITH LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS NOINHERIT PASSWORD {}" if role_exists else "CREATE ROLE {} WITH LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS NOINHERIT PASSWORD {}").format(
                sql.Identifier(app_user), sql.Literal(app_password)
            )
            cur.execute(role_sql)
            cur.execute(
                sql.SQL("GRANT CONNECT ON DATABASE {} TO {}").format(
                    sql.Identifier(os.getenv("PGDATABASE", "censo_terremoto")), sql.Identifier(app_user)
                )
            )
            database = sql.Identifier(os.getenv("PGDATABASE", "censo_terremoto"))
            cur.execute(sql.SQL("REVOKE CONNECT ON DATABASE {} FROM PUBLIC").format(database))
            cur.execute(sql.SQL("GRANT CONNECT ON DATABASE {} TO {}").format(database, sql.Identifier(admin_user)))
            cur.execute(sql.SQL("GRANT USAGE ON SCHEMA {} TO {}").format(sql.Identifier(SCHEMA), sql.Identifier(app_user)))
            cur.execute(sql.SQL("REVOKE ALL ON SCHEMA {} FROM PUBLIC").format(sql.Identifier(SCHEMA)))
            cur.execute(
                sql.SQL("GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA {} TO {}").format(
                    sql.Identifier(SCHEMA), sql.Identifier(app_user)
                )
            )
            cur.execute(
                sql.SQL("GRANT USAGE,SELECT ON ALL SEQUENCES IN SCHEMA {} TO {}").format(
                    sql.Identifier(SCHEMA), sql.Identifier(app_user)
                )
            )
            owner = sql.Identifier(admin_user)
            schema = sql.Identifier(SCHEMA)
            target = sql.Identifier(app_user)
            cur.execute(sql.SQL("ALTER DEFAULT PRIVILEGES FOR ROLE {} IN SCHEMA {} GRANT SELECT,INSERT,UPDATE,DELETE ON TABLES TO {}").format(owner, schema, target))
            cur.execute(sql.SQL("ALTER DEFAULT PRIVILEGES FOR ROLE {} IN SCHEMA {} GRANT USAGE,SELECT ON SEQUENCES TO {}").format(owner, schema, target))
    connection.close()
    print(f"Cuenta técnica de aplicación '{app_user}' configurada con permisos limitados al esquema {SCHEMA}.")
    print("La contraseña se guardó en .env, archivo local excluido de la entrega.")


if __name__ == "__main__":
    main()
