# Publicar Terra en Internet

Esta configuración usa Render Free para servir Flask y Neon Free para PostgreSQL. Render permite abrir la aplicación sin ejecutar nada en el computador del equipo, pero suspende el servicio después de 15 minutos sin tráfico y el siguiente acceso puede tardar cerca de un minuto. Neon Free escala la base a cero después de cinco minutos sin actividad, tiene hasta 1 GB por proyecto y un límite de cómputo mensual. Estos planes sirven para la sustentación y pruebas, no ofrecen disponibilidad continua garantizada ni son adecuados para datos personales reales.

Referencias vigentes:

- [Limitaciones de Render Free](https://render.com/docs/free)
- [Planes y límites de Neon](https://neon.com/pricing)
- [Formato `render.yaml`](https://render.com/docs/blueprint-spec)

## 1. Crear la base de datos de demostración

1. Crea un proyecto gratuito en Neon y selecciona una región cercana a Oregon, donde se configura el servicio de Render.
2. Ejecuta `.\setup.ps1` en Windows para instalar Psycopg en el entorno privado del proyecto.
3. En Neon, crea una base vacía y copia la URL de PostgreSQL con SSL. Usa la URL del pooler cuando esté disponible. No la publiques ni la agregues a archivos versionados.
4. Desde PowerShell en la carpeta del proyecto, ejecuta `.\.venv\Scripts\python.exe app\init_hosted_database.py` e introduce la URL cuando la solicite; la entrada se oculta y no se guarda. El script carga [`../sql/00_proyecto_completo.sql`](../sql/00_proyecto_completo.sql), verifica las 38 tablas y las seis vistas, y se detiene si ya existe el esquema `censo_terremoto`.

La base nueva contiene los datos ficticios del proyecto y todavía no tiene las cuentas locales del computador. Se creará un administrador independiente durante el paso de alta especial.

## 2. Subir el código a GitHub

El despliegue de Render se conecta a un repositorio GitHub. Desde PowerShell en la carpeta del proyecto, inicializa el repositorio y confirma que `.env` no aparezca antes de subirlo:

```powershell
git init
git add .
git status --short
```

Si `.env` aparece en la lista, no continúes: elimínalo del área de preparación con `git rm --cached .env` y confirma que `.gitignore` lo excluya. Nunca subas `.env`, `.venv`, contraseñas ni URLs de conexión. Crea un repositorio privado vacío en GitHub (recomendado) y luego conecta la URL que GitHub te muestre:

```powershell
git commit -m "Preparar despliegue de Terra"
git branch -M main
git remote add origin https://github.com/USUARIO/REPOSITORIO.git
git push -u origin main
```

## 3. Crear el servicio web

1. Crea una cuenta en Render y conecta el repositorio GitHub.
2. Elige **New > Blueprint** y selecciona el repositorio. Render detecta [`../render.yaml`](../render.yaml), instala Gunicorn y publica la app con HTTPS.
3. Cuando solicite las variables marcadas como secretas, asigna:
   - `DATABASE_URL`: URL TLS de Neon copiada en el paso 1.
   - `ADMIN_BOOTSTRAP_KEY`: genera una clave aleatoria de alta, por ejemplo `python -c "import secrets; print(secrets.token_urlsafe(48))"`. Guárdala temporalmente en un gestor de contraseñas; no la escribas en el código ni la envíes por chat.
   - `FLASK_SECRET_KEY`: Render la genera al crear el servicio mediante `generateValue`.
4. Espera a que termine el despliegue y verifica que `/health` responda `{"status":"ok"}`. El dominio HTTPS se muestra en el panel de Render.

## 4. Crear el administrador nuevo

1. Abre el dominio HTTPS de Render y elige **Usar clave especial de un solo uso**.
2. Introduce `ADMIN_BOOTSTRAP_KEY`, el nuevo nombre de usuario y una contraseña nueva de al menos 10 caracteres.
3. Inicia sesión desde el formulario normal con las credenciales de esa cuenta. La clave especial no se usa para iniciar sesión y no cambia la cuenta administradora que ya existe en el computador.
4. Después de crear la cuenta, elimina `ADMIN_BOOTSTRAP_KEY` de las variables del servicio en Render y vuelve a desplegar. La base también guarda que la clave ya fue consumida, por lo que no se puede volver a usar.

Las cuentas públicas normales solo pueden crear perfiles persona. El nuevo administrador puede asignar roles desde **Usuarios y roles**.

## 5. Mantenimiento y límites

- En el plan gratuito, la app puede tardar cerca de un minuto en responder después de estar inactiva; eso no requiere encender el computador del equipo.
- Render Free ofrece horas y tráfico limitados; si se agotan, el servicio puede quedar suspendido.
- Neon Free escala a cero y tiene límites de cómputo y almacenamiento. Revisa el uso en ambos paneles.
- Conserva una copia de la base. No uses esta configuración para información real de personas afectadas ni para operaciones de emergencia.
- Para servicio siempre activo, copias automatizadas y uso real, migra a planes de pago y establece controles de privacidad, auditoría y recuperación.
