# Plantillas de correo TradeHub para autenticación

Los correos reales de autenticación se cambian desde el panel del proveedor de auth. Para que Gmail muestre la marca TradeHub y no textos genéricos, configura lo siguiente en **Authentication → Email Templates** y en **Project Settings → Auth / SMTP**.

## Ajustes obligatorios
- En **Authentication → Providers → Email**, activa **Confirm email** para que se envíe confirmación al registrarse. Si está apagado, la cuenta se crea sin correo.
- En **Authentication → URL Configuration**, agrega la URL pública de TradeHub en **Site URL** y **Redirect URLs**.
- Para que Gmail muestre TradeHub como remitente y no el proveedor genérico, configura SMTP propio con un dominio/correo verificado.

## Remitente recomendado
- **Sender name:** TradeHub MMORPG
- **Sender email:** soporte@tradehubmmorpg.com (o el correo oficial verificado del dominio)

## Confirm signup / Confirmar cuenta
**Subject:** Confirma tu cuenta de TradeHub MMORPG

```html
<h2>Confirma tu cuenta de TradeHub MMORPG</h2>
<p>Hola, gracias por registrarte en TradeHub.</p>
<p>Presiona el botón para activar tu cuenta y volver al panel oficial:</p>
<p><a href="{{ .ConfirmationURL }}" style="background:#1a2229;color:#fff;padding:12px 18px;border-radius:10px;text-decoration:none;display:inline-block;">Confirmar cuenta TradeHub</a></p>
<p>Si no solicitaste esta cuenta, puedes ignorar este mensaje.</p>
<p>Equipo TradeHub MMORPG</p>
```

## Recuperar contraseña
**Plantilla:** Recuperación de contraseña

**Subject:** Restablece tu contraseña de TradeHub MMORPG

> Importante: cambia el asunto genérico del proveedor por el asunto anterior para que el usuario vea TradeHub en Gmail.

```html
<div style="font-family:Arial,sans-serif;background:#0d1217;color:#f7f7f7;padding:22px;border-radius:14px;">
  <h2 style="color:#f6ca63;margin-top:0;">Recupera tu acceso a TradeHub MMORPG</h2>
  <p>Recibimos una solicitud para crear una contraseña nueva en tu cuenta TradeHub.</p>
  <p>Presiona el botón para volver a la página oficial y confirmar tu nueva contraseña:</p>
  <p><a href="{{ .ConfirmationURL }}" style="background:#1a2229;color:#fff;padding:12px 18px;border-radius:10px;text-decoration:none;display:inline-block;border:1px solid #f6ca63;">Crear nueva contraseña TradeHub</a></p>
  <p>Si no solicitaste este cambio, ignora este mensaje. Tu cuenta seguirá protegida.</p>
  <p>Equipo TradeHub MMORPG</p>
</div>
```

> Nota: estas plantillas, asuntos y remitente no se pueden cambiar desde JavaScript del navegador; deben configurarse en el panel de autenticación/SMTP para que el correo real llegue y salga con marca TradeHub.
