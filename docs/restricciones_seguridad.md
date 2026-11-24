# Restricciones, permisos y seguridad

## Integridad de los datos

El modelo conserva las claves primarias y foráneas definidas en las 36 entidades funcionales. PostgreSQL valida relaciones, valores obligatorios, rangos, estados y fechas con restricciones `NOT NULL`, `UNIQUE`, `CHECK` y `FOREIGN KEY`. Las eliminaciones respetan las dependencias: si otra fila referencia el registro, PostgreSQL rechaza el borrado y la aplicación explica por qué.

Las relaciones con cambios en el tiempo incluyen fechas para distinguir hogares, ocupaciones, propiedad y estancias entre eventos. Un reporte, una afectación, una inspección y una evidencia representan hechos distintos y conservan su procedencia.

## Cuentas y perfiles

La tabla adicional `usuario_app` registra nombre de usuario, hash de contraseña, perfil, estado y vínculo opcional con `persona`. Una cuenta `persona` debe estar asociada a una persona del censo, y cada persona puede vincularse con una sola cuenta.

| Perfil | Consultar | Escritura y eliminación de datos | Administrar cuentas |
|---|---:|---:|---:|
| Administrador | Sí | Crear, editar y eliminar | Sí |
| Encargado | Sí | Crear y editar; no puede eliminar | No |
| Persona | Sí | Solo puede editar su propio registro | No |

El registro desde la pantalla de acceso siempre crea una cuenta `persona` y su fila personal relacionada; no permite escoger roles elevados. Solo un administrador puede convertir cuentas en encargados o administradores, desactivarlas, restablecer sus contraseñas o eliminarlas desde **Usuarios y roles**. El sistema impide desactivar o eliminar la última cuenta de administrador activa.

Los permisos se comprueban en el servidor para cada solicitud, no solo ocultando controles. El encargado no puede borrar ni administrar cuentas, incluso si intenta enviar una solicitud manual. La persona puede consultar la información y editar únicamente su fila personal vinculada; no puede crear ni eliminar registros.

Las contraseñas se guardan mediante hash seguro de Werkzeug y deben tener al menos 10 caracteres. Los formularios de escritura incluyen protección CSRF. La tabla de cuentas no aparece en el CRUD general para evitar exponer los hashes.

Una clave especial de alta, almacenada solo como variable de entorno `ADMIN_BOOTSTRAP_KEY`, permite crear una cuenta administradora independiente con usuario y contraseña propios. La clave se compara en tiempo constante y queda consumida de forma persistente en `admin_bootstrap_state`; no sirve para iniciar sesión, no se acepta en el registro público y no puede reutilizarse. Tras crear la cuenta, se debe retirar la variable del alojamiento. La cuenta creada inicia sesión por el formulario normal y es independiente de las demás cuentas.

## Cuenta de PostgreSQL de la aplicación

`init-db.ps1` usa las credenciales administrativas solo durante la inicialización. Luego configura `censo_app` como una cuenta técnica sin privilegios de superusuario, creación de bases ni administración de roles. Esa cuenta recibe permisos de lectura y escritura sobre las tablas y secuencias del esquema `censo_terremoto`; la aplicación aplica los perfiles anteriores antes de ejecutar operaciones.

En desarrollo local, las credenciales se guardan en `.env`, excluido del repositorio y del ZIP de entrega. En producción, se configuran como variables secretas del alojamiento y `DATABASE_URL` debe usar TLS. La cookie de sesión se marca `Secure` en producción y se requiere `FLASK_SECRET_KEY` estable para conservar sesiones entre reinicios. El proyecto es una demostración académica con datos ficticios: antes de manejar datos personales reales se necesitarían controles adicionales de auditoría, copias de seguridad, disponibilidad, despliegue y privacidad.

## Supuestos

- Las cuentas creadas desde la pantalla pública reciben el perfil persona y se vinculan a una fila personal nueva.
- El encargado puede consultar, insertar y editar datos, pero no eliminar registros ni administrar cuentas.
- Solo el administrador puede gestionar perfiles y otorgar los roles de encargado o administrador.
- El código de alta de una cuenta administradora independiente solo se usa una vez; no es una contraseña de inicio de sesión.
- Los datos incluidos en los scripts son simulados y no describen personas reales.
