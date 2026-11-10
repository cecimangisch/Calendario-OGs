# ¿Dónde estamos?

Calendario compartido para ver en qué ciudad está cada una entre noviembre y
febrero, y qué días coinciden.

Es una sola página estática. Los datos viven en Supabase; cualquiera con el link
puede abrirla y editarla, sin cuenta ni contraseña.

## Puesta en marcha

### 1. Supabase

1. Creá un proyecto en [supabase.com](https://supabase.com) (el plan gratis alcanza de sobra).
2. Entrá a **SQL Editor**, pegá todo el contenido de `schema.sql` y dale Run.
   Eso crea la tabla, las dos funciones de acceso y deja los datos actuales cargados.
3. Copiá dos valores:
   - **Project Settings → Data API → Project URL**
   - **Project Settings → API Keys → Publishable key** (`sb_publishable_...`)

   La publishable key reemplaza a la vieja `anon key` y tiene exactamente los mismos
   privilegios, así que el esquema de acá funciona igual. La **Secret key**
   (`sb_secret_...`) no se usa en este proyecto: se saltea RLS y nunca va en el navegador.

### 2. config.js

Pegá esos dos valores en `config.js`:

```js
var CONFIG = {
  url: "https://xxxxxxxx.supabase.co",
  key: "sb_publishable_..."
};
```

### 3. GitHub Pages

En el repo: **Settings → Pages → Source: Deploy from a branch → main / (root)**.
En un minuto queda publicado en `https://<usuario>.github.io/<repo>/`.

### 4. El link

```
https://cecimangisch.github.io/Calendario-OGs/
```

La URL pelada abre el calendario del grupo, porque su id está fijado en `config.js`.
Si se le agrega otro id al final (`.../#loquesea`), se abre un calendario distinto y vacío.

## Cómo se guarda

El calendario entero es un documento JSON con un número de versión. Al guardar se
manda la versión que se leyó: si alguien guardó en el medio, el cambio no se aplica,
la página avisa y carga la versión de la otra persona. La página además releé cada
8 segundos, así que los cambios de las demás aparecen solos.

## Sobre la seguridad

Esto es un calendario de viajes entre amigas, y está armado como tal: **cualquiera que
llegue a la página puede ver, editar y borrar.** No hay cuentas ni contraseñas, a propósito.

- La tabla está cerrada con RLS y sólo se entra por `cal_get` y `cal_put`, que piden el
  id del calendario. Pero el id está en este repo, que es público, así que no es un secreto.
- La publishable key es pública por diseño y no da acceso por sí sola a nada más: no hay
  otras tablas, y la Secret key no está acá.
- Si alguien rompe el calendario, se recupera desde Supabase: la tabla guarda una sola fila
  por calendario, y Supabase tiene backups diarios.
- Si alguna vez querés cerrarlo de verdad, el camino es Supabase Auth con magic link y
  policies por email. Es otro trabajo, no un ajuste.
