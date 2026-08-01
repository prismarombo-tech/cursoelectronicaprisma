# ElectroQuest Global - listo para GitHub Pages

Esta carpeta ya contiene la URL y la clave publica de Supabase suministradas para el proyecto.

## Archivos que debes subir a GitHub

- `index.html`
- `config.js`

Puedes subir tambien:

- `supabase_setup.sql`
- `README.md`

## Paso obligatorio en Supabase

1. Abre tu proyecto de Supabase.
2. Entra en **SQL Editor**.
3. Crea una consulta nueva.
4. Copia todo el contenido de `supabase_setup.sql`.
5. Ejecuta la consulta con **Run**.

Sin este paso, la pagina abrira, pero el inicio de sesion, el progreso compartido y el ranking global no funcionaran.

## Publicar en GitHub Pages

1. Sube los archivos a la raiz del repositorio.
2. Abre **Settings > Pages**.
3. Selecciona **Deploy from a branch**.
4. Elige la rama `main` y la carpeta `/root`.
5. Guarda los cambios.

## Contenido

- 19 misiones de electricidad.
- 6 preguntas por tema.
- 114 preguntas en total.
- Explicaciones ampliadas.
- Repeticion inteligente de errores.
- Repasos posteriores.
- Gran Reto Final con todas las preguntas mezcladas.
- Progreso local y sincronizacion global.
- Ranking compartido entre estudiantes.

## Seguridad

La clave incluida es una clave publica `publishable`, apropiada para una aplicacion web. No reemplaces esta clave por una clave secreta ni por `service_role`.
