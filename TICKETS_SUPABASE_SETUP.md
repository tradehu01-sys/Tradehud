# Activar tickets y chat en Supabase

Para que **Crear orden**, **Perfil → Órdenes**, el **chat del ticket** y el **panel admin → Tickets** funcionen de forma persistente, ejecuta la migración incluida en este repo.

## Pasos

1. Abre tu proyecto en Supabase.
2. Ve a **SQL Editor**.
3. Copia y ejecuta el archivo:

```sql
MIGRACION_DB_2026_07_05.sql
```

Si estás configurando la base desde cero, también puedes ejecutar primero:

```sql
SCHEMA_COMPLETO.sql
```

## Qué debe existir después

Verifica en Supabase que existan estas tablas:

- `public.tickets`
- `public.ticket_messages`
- `public.user_profiles`

Y que `ticket_messages` tenga estas columnas:

- `ticket_id`
- `sender_id`
- `sender_role`
- `message`
- `created_at`

## Verificación rápida en la web

1. Inicia sesión como usuario normal.
2. Crea una orden desde oro, streaming, giftcards, P2P, cuentas o boosting.
3. Abre **Perfil → Órdenes** y escribe un mensaje en el chat del ticket.
4. Abre el panel admin, entra a **Tickets** y responde desde el chat del mismo ticket.

> Si ves mensajes temporales, significa que el navegador está guardando respaldo local, pero falta ejecutar o refrescar la migración en Supabase para sincronización global entre dispositivos.
