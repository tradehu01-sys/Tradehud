# Plantillas de correo TradeHub para autenticación

Los correos reales de autenticación se cambian desde el panel del proveedor de auth. Para que Gmail no muestre textos genéricos ni asuntos como “Recovery Password”, configura lo siguiente en **Authentication → Email Templates** y en **Project Settings → Auth / SMTP**.

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
**Subject:** Restablece tu contraseña de TradeHub MMORPG

> Importante: reemplaza el asunto predeterminado “Recovery Password” por el asunto anterior.

```html
<h2>Restablece tu contraseña de TradeHub MMORPG</h2>
<p>Recibimos una solicitud para cambiar la contraseña de tu cuenta TradeHub.</p>
<p><a href="{{ .ConfirmationURL }}" style="background:#1a2229;color:#fff;padding:12px 18px;border-radius:10px;text-decoration:none;display:inline-block;">Crear nueva contraseña</a></p>
<p>Si no solicitaste este cambio, ignora este mensaje.</p>
<p>Equipo TradeHub MMORPG</p>
```

> Nota: estas plantillas y asuntos no se pueden cambiar desde JavaScript del navegador; deben configurarse en el panel de autenticación para que el correo real salga con marca TradeHub.
