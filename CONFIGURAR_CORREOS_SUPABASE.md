# Qué correo configurar en Supabase para TradeHub

En **Supabase → Authentication → Email Templates** aparecen varias opciones. Para arreglar el correo que ahora llega como **Reset Password** / **reset password**, debes configurar la opción **Restablecer contraseña**.

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

En **Authentication → URL Configuration** configura:

- **Site URL:** la URL pública de tu página TradeHub.
- **Redirect URLs:** agrega la misma URL pública y, si Supabase te pide coincidencia exacta, también agrega:
  - `https://TU-DOMINIO.com/?auth=signup`
  - `https://TU-DOMINIO.com/?auth=recovery`

Cambia `https://TU-DOMINIO.com` por el dominio real donde publicaste `index.html`.

## 4. Si quieres aplicarlo automático

Este repo también trae un script para hacerlo por API sin pegar manualmente:

```bash
export SUPABASE_ACCESS_TOKEN="tu-access-token"
export PROJECT_REF="tu-project-ref"
node scripts/apply-supabase-auth-email-templates.mjs
```

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
