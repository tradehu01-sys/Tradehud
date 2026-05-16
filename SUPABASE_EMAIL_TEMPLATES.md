# Plantillas de correo TradeHub para autenticación

Los correos reales de autenticación se cambian desde el panel del proveedor de auth. Para que Gmail muestre la marca TradeHub y no textos genéricos, configura lo siguiente en **Authentication → Email Templates** y en **Project Settings → Auth / SMTP**.

## Ajustes obligatorios
- En **Authentication → Providers → Email**, activa **Confirm email** para que se envíe confirmación al registrarse. Si está apagado, la cuenta se crea sin correo.
- En **Authentication → URL Configuration**, agrega la URL pública de TradeHub en **Site URL** y **Redirect URLs**. Incluye también las URLs con `?auth=signup` y `?auth=recovery` si tu panel exige coincidencias exactas.
- Para que Gmail muestre TradeHub como remitente y no el proveedor genérico, configura SMTP propio con un dominio/correo verificado.
- Revisa límites/rate limits del proveedor: si se excede el límite de correos, el navegador puede solicitar el email pero el proveedor no lo entregará.
- Si un correo ya está registrado, normalmente no se envía otro email de registro; usa recuperación de contraseña para ese correo.

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
**Plantilla del panel:** Recovery / Recovery password

**Subject:** Restablece tu contraseña de TradeHub MMORPG

> Importante: si el correo llega con el asunto **Recovery password**, falta cambiar el **Subject** de esta plantilla en el panel. Copia el asunto anterior exactamente para que Gmail muestre TradeHub desde el título del mensaje.

```html
<div style="font-family:Arial,sans-serif;background:#0d1217;color:#f7f7f7;padding:22px;border-radius:14px;">
  <h2 style="color:#f6ca63;margin-top:0;">Recupera tu acceso a TradeHub MMORPG</h2>
  <p>Hola, solicitaste restablecer la contraseña de tu cuenta TradeHub.</p>
  <p>Presiona el botón para volver a la página oficial y crear una nueva contraseña de forma segura:</p>
  <p><a href="{{ .ConfirmationURL }}" style="background:#1a2229;color:#fff;padding:12px 18px;border-radius:10px;text-decoration:none;display:inline-block;border:1px solid #f6ca63;">Crear nueva contraseña TradeHub</a></p>
  <p>Si no solicitaste este cambio, ignora este mensaje. Tu cuenta seguirá protegida.</p>
  <p>Equipo TradeHub MMORPG</p>
</div>
```

## Si no llega ningún correo
1. Verifica que **Confirm email** esté activado para registros.
2. Configura **SMTP propio** y valida el remitente/dominio.
3. Confirma que **Site URL** y **Redirect URLs** coincidan con el dominio publicado de TradeHub.
4. Revisa spam/promociones y los límites de envío del proveedor.
5. Prueba con un correo nuevo; si el correo ya existe, usa recuperación de contraseña.

> Nota: estas plantillas, asuntos y remitente no se pueden cambiar desde JavaScript del navegador; deben configurarse en el panel de autenticación/SMTP para que el correo real llegue y salga con marca TradeHub.
