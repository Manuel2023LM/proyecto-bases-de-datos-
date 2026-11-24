from __future__ import annotations

import getpass
import os
import re
from pathlib import Path

import psycopg
from werkzeug.security import generate_password_hash


ROOT = Path(__file__).resolve().parent.parent


def load_env() -> None:
    path = ROOT / ".env"
    if path.exists():
        for raw in path.read_text(encoding="utf-8-sig").splitlines():
            line = raw.strip()
            if line and not line.startswith("#") and "=" in line:
                key, value = line.split("=", 1)
                os.environ.setdefault(key.strip(), value.strip().strip("\"'"))


def main() -> None:
    load_env()
    username = input("Nombre de usuario para el administrador: ").strip().lower()
    if not re.fullmatch(r"[a-z0-9._-]{3,50}", username):
        raise SystemExit("Usa entre 3 y 50 letras minúsculas, números, puntos, guiones o guiones bajos.")
    password = getpass.getpass("Contraseña (mínimo 10 caracteres; entrada oculta): ")
    confirmation = getpass.getpass("Confirma la contraseña (entrada oculta): ")
    if len(password) < 10:
        raise SystemExit("La contraseña debe tener al menos 10 caracteres.")
    if password != confirmation:
        raise SystemExit("Las contraseñas no coinciden. Vuelve a ejecutar el script y escríbelas de nuevo; no se muestran en pantalla.")
    with psycopg.connect(
        host=os.getenv("PGHOST", "localhost"),
        port=os.getenv("PGPORT", "5432"),
        dbname=os.getenv("PGDATABASE", "censo_terremoto"),
        user=os.getenv("PGAPPUSER", "censo_app"),
        password=os.getenv("PGAPPPASSWORD", ""),
        options="-c search_path=censo_terremoto,public",
    ) as conn:
        with conn.cursor() as cur:
            cur.execute(
                "INSERT INTO usuario_app(nombre_usuario,password_hash,rol,activo) VALUES (%s,%s,'administrador',true)",
                (username, generate_password_hash(password)),
            )
    print(f"Cuenta de administrador '{username}' creada. Inicia sesión desde la aplicación.")


if __name__ == "__main__":
    try:
        main()
    except psycopg.errors.UniqueViolation:
        raise SystemExit("Ese nombre de usuario ya existe.")
