import importlib
import os
import re
import unittest
from unittest.mock import patch


app_module = importlib.import_module("app.app")


class BootstrapDatabase:
    def __init__(self, state):
        self.state = state

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        return False

    def cursor(self):
        return BootstrapCursor(self.state)


class BootstrapCursor:
    def __init__(self, state):
        self.state = state
        self.result = None

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        return False

    def execute(self, query, params=None):
        if "SELECT 1 FROM admin_bootstrap_state" in query:
            self.result = {"used": True} if self.state["used"] else None
        elif "INSERT INTO usuario_app" in query:
            self.result = {"id_usuario": 42}
        elif "INSERT INTO admin_bootstrap_state" in query:
            self.state["used"] = True
            self.result = None
        else:
            self.result = None

    def fetchone(self):
        return self.result


class AdminBootstrapTests(unittest.TestCase):
    def setUp(self):
        self.state = {"used": False}
        app_module.app.config.update(TESTING=True, SECRET_KEY="test-session-secret")
        self.client = app_module.app.test_client()
        self.environment = patch.dict(os.environ, {"ADMIN_BOOTSTRAP_KEY": "test-one-use-key"})
        self.environment.start()
        self.bootstrap_key = patch.object(app_module, "configured_bootstrap_key", "test-one-use-key")
        self.bootstrap_key.start()
        self.database = patch.object(
            app_module,
            "connect_db",
            side_effect=lambda: BootstrapDatabase(self.state),
        )
        self.database.start()

    def tearDown(self):
        self.database.stop()
        self.bootstrap_key.stop()
        self.environment.stop()

    def csrf_token(self):
        response = self.client.get("/admin/bootstrap")
        self.assertEqual(response.status_code, 200)
        match = re.search(rb'name="csrf_token" value="([^"]+)"', response.data)
        self.assertIsNotNone(match)
        return match.group(1).decode("ascii")

    def test_invalid_key_does_not_consume_bootstrap(self):
        token = self.csrf_token()
        response = self.client.post(
            "/admin/bootstrap",
            data={
                "csrf_token": token,
                "clave_alta": "incorrect",
                "nombre_usuario": "admin_nuevo",
                "contrasena": "una-clave-segura-123",
                "confirmacion": "una-clave-segura-123",
            },
        )
        self.assertEqual(response.status_code, 200)
        self.assertIn("La clave especial no es válida.".encode(), response.data)
        self.assertFalse(self.state["used"])

    def test_valid_key_creates_an_independent_admin_once(self):
        token = self.csrf_token()
        response = self.client.post(
            "/admin/bootstrap",
            data={
                "csrf_token": token,
                "clave_alta": "test-one-use-key",
                "nombre_usuario": "admin_nuevo",
                "contrasena": "una-clave-segura-123",
                "confirmacion": "una-clave-segura-123",
            },
        )
        self.assertEqual(response.status_code, 302)
        self.assertTrue(self.state["used"])
        self.assertEqual(self.client.get("/admin/bootstrap").status_code, 410)


if __name__ == "__main__":
    unittest.main()
