# Qué correo configurar en Supabase para TradeHub

En **Supabase → Authentication → Email Templates** aparecen varias opciones. Para arreglar el correo que ahora llega como **Reset Password** / **reset password**, debes configurar la opción **Restablecer contraseña**.

## Datos exactos de esta página

Usa estos valores para TradeHub:

- **Dominio público de la página:** `https://tradehud.vercel.app`
- **Página de inicio visible:** `https://tradehud.vercel.app/#inicio`
- **Supabase Project Ref:** `lveocmzvfndvzjdqknnf`
- **Supabase URL:** `https://lveocmzvfndvzjdqknnf.supabase.co`

> Importante: en Supabase Auth usa `https://tradehud.vercel.app` y las URLs con `?auth=...`. No pongas `#inicio` como URL de redirección de Auth, porque el `#inicio` es solo una sección visual del navegador y el flujo de recuperación usa parámetros como `?auth=recovery`.

## Opciones y cuáles usa TradeHub

| Opción del panel | ¿Configurar para TradeHub? | Para qué sirve |
| --- | --- | --- |
| **Confirmar registro** | **Sí** | Correo que llega cuando un usuario crea cuenta y debe confirmar su email. |
| **Invitar usuario** | No es necesario ahora | Solo si desde Supabase invitas usuarios manualmente. |
| **Enlace mágico** | No es necesario ahora | Solo si activas login por magic link. |
| **Cambiar dirección de correo electrónico** | Opcional | Solo si permites que usuarios cambien su email. |
| **Restablecer contraseña** | **Sí, este es el de password recovery** | Correo que llega cuando el usuario toca “¿Olvidó su contraseña?”. Aquí debes quitar el texto genérico `Reset Password`. |
| **Reautenticación** | No es necesario ahora | Solo para acciones sensibles que pidan confirmar identidad otra vez. |

## 1. Configura “Restablecer contraseña”

Entra a **Authentication → Email Templates → Restablecer contraseña** y cambia estos dos campos:

### Sujeto

```text
Restablece tu contraseña de TradeHub MMORPG
```

### Cuerpo / Template HTML

Pega este contenido completo:

```html
<div style="font-family:Arial,sans-serif;background:#0d1217;color:#f7f7f7;padding:22px;border-radius:14px;line-height:1.55;">
  <h2 style="color:#f6ca63;margin-top:0;">Recupera tu acceso a TradeHub MMORPG</h2>
  <p>Hola, solicitaste restablecer la contraseña de tu cuenta TradeHub.</p>
  <p>Presiona el botón para volver a la página oficial y crear una nueva contraseña de forma segura:</p>
  <p>
    <a href="{{ .ConfirmationURL }}" style="background:#1a2229;color:#fff;padding:12px 18px;border-radius:10px;text-decoration:none;display:inline-block;border:1px solid #f6ca63;">
      Crear nueva contraseña TradeHub
    </a>
  </p>
  <p>Si no solicitaste este cambio, ignora este mensaje. Tu cuenta seguirá protegida.</p>
  <p style="margin-bottom:0;">Equipo TradeHub MMORPG</p>
</div>
```

> Importante: no borres `{{ .ConfirmationURL }}`. Supabase reemplaza eso por el enlace real para restablecer la contraseña.

## 2. Configura “Confirmar registro”

Entra a **Authentication → Email Templates → Confirmar registro** y cambia estos campos:

### Sujeto

```text
Confirma tu cuenta de TradeHub MMORPG
```

### Cuerpo / Template HTML

```html
<div style="font-family:Arial,sans-serif;background:#0d1217;color:#f7f7f7;padding:22px;border-radius:14px;line-height:1.55;">
  <h2 style="color:#f6ca63;margin-top:0;">Confirma tu cuenta de TradeHub MMORPG</h2>
  <p>Hola, gracias por registrarte en TradeHub.</p>
  <p>Presiona el botón para activar tu cuenta y volver al panel oficial:</p>
  <p>
    <a href="{{ .ConfirmationURL }}" style="background:#1a2229;color:#fff;padding:12px 18px;border-radius:10px;text-decoration:none;display:inline-block;border:1px solid #f6ca63;">
      Confirmar cuenta TradeHub
    </a>
  </p>
  <p>Si no solicitaste esta cuenta, puedes ignorar este mensaje.</p>
  <p style="margin-bottom:0;">Equipo TradeHub MMORPG</p>
</div>
```

## 3. Configura las URLs de redirección

En **Authentication → URL Configuration** configura exactamente esto para TradeHub:

### Site URL

```text
https://tradehud.vercel.app
```

### Redirect URLs / Additional Redirect URLs

Agrega estas URLs:

```text
https://tradehud.vercel.app
https://tradehud.vercel.app/
https://tradehud.vercel.app/?auth=signup
https://tradehud.vercel.app/?auth=recovery
```

No uses `https://tradehud.vercel.app/#inicio` aquí. La página puede abrir en `#inicio`, pero Supabase debe volver a las URLs anteriores para que el JavaScript detecte `?auth=signup` o `?auth=recovery`.

## 4. Si quieres aplicarlo automático

Este repo también trae un script para hacerlo por API sin pegar manualmente:

```bash
export SUPABASE_ACCESS_TOKEN="PEGA_AQUI_TU_ACCESS_TOKEN_DE_SUPABASE"
export PROJECT_REF="lveocmzvfndvzjdqknnf"
node scripts/apply-supabase-auth-email-templates.mjs
```

El `PROJECT_REF` ya queda listo para este proyecto. El `SUPABASE_ACCESS_TOKEN` es secreto y debes copiarlo desde **Supabase Dashboard → Account → Access Tokens**; no lo pegues en `index.html` ni lo subas público al repo.

Si solo quieres revisar lo que va a enviar:

```bash
node scripts/apply-supabase-auth-email-templates.mjs --dry-run
```

## Resumen rápido

Si el correo dice:

```html
<h2>Reset Password</h2>
<p>Follow this link to reset the password for your user:</p>
<p><a href="{{ .ConfirmationURL }}">Reset Password</a></p>
```

y el sujeto dice `reset password`, entonces la opción correcta que debes editar es:

```text
Authentication → Email Templates → Restablecer contraseña
```
