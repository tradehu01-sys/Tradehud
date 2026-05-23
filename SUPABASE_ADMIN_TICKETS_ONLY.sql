-- TradeHud: setup mínimo para administrador de tickets
-- Ejecuta este script en Supabase SQL Editor.
-- Objetivo: crear/asegurar un admin dedicado que solo gestione tickets.

-- 1) Asegurar tabla de perfiles básica
create table if not exists public.user_profiles (
  id uuid primary key,
  email text,
  name text,
  discord text default '',
  phone text default '',
  is_admin boolean not null default false,
  is_online boolean not null default false,
  last_seen timestamptz,
  updated_at timestamptz not null default now()
);

alter table public.user_profiles enable row level security;

-- 2) Asegurar columnas mínimas en tickets/ticket_messages
alter table if exists public.tickets
  add column if not exists status text default 'pendiente';

alter table if exists public.ticket_messages
  add column if not exists sender_role text default 'user';

-- 3) Función helper: ¿usuario actual es admin?
create or replace function public.is_ticket_admin()
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.user_profiles p
    where p.id = auth.uid()
      and p.is_admin = true
  );
$$;

-- 4) Policies de user_profiles (mínimas y seguras)
drop policy if exists user_profiles_self_select on public.user_profiles;
create policy user_profiles_self_select
on public.user_profiles
for select
to authenticated
using (id = auth.uid() or public.is_ticket_admin());

drop policy if exists user_profiles_self_insert on public.user_profiles;
create policy user_profiles_self_insert
on public.user_profiles
for insert
to authenticated
with check (id = auth.uid() or public.is_ticket_admin());

drop policy if exists user_profiles_self_update on public.user_profiles;
create policy user_profiles_self_update
on public.user_profiles
for update
to authenticated
using (id = auth.uid() or public.is_ticket_admin())
with check (id = auth.uid() or public.is_ticket_admin());

-- 5) Policies para tickets: usuario ve/crea los suyos, admin ve/gestiona todos
drop policy if exists tickets_user_select_or_admin on public.tickets;
create policy tickets_user_select_or_admin
on public.tickets
for select
to authenticated
using (user_id = auth.uid() or public.is_ticket_admin());

drop policy if exists tickets_user_insert_or_admin on public.tickets;
create policy tickets_user_insert_or_admin
on public.tickets
for insert
to authenticated
with check (user_id = auth.uid() or public.is_ticket_admin());

drop policy if exists tickets_user_update_or_admin on public.tickets;
create policy tickets_user_update_or_admin
on public.tickets
for update
to authenticated
using (user_id = auth.uid() or public.is_ticket_admin())
with check (user_id = auth.uid() or public.is_ticket_admin());

drop policy if exists tickets_admin_delete on public.tickets;
create policy tickets_admin_delete
on public.tickets
for delete
to authenticated
using (public.is_ticket_admin());

-- 6) Policies para ticket_messages: dueños del ticket y admin
drop policy if exists ticket_messages_select_owner_or_admin on public.ticket_messages;
create policy ticket_messages_select_owner_or_admin
on public.ticket_messages
for select
to authenticated
using (
  public.is_ticket_admin()
  or exists (
    select 1 from public.tickets t
    where t.id = ticket_messages.ticket_id
      and t.user_id = auth.uid()
  )
);

drop policy if exists ticket_messages_insert_owner_or_admin on public.ticket_messages;
create policy ticket_messages_insert_owner_or_admin
on public.ticket_messages
for insert
to authenticated
with check (
  public.is_ticket_admin()
  or exists (
    select 1 from public.tickets t
    where t.id = ticket_messages.ticket_id
      and t.user_id = auth.uid()
  )
);

drop policy if exists ticket_messages_update_owner_or_admin on public.ticket_messages;
create policy ticket_messages_update_owner_or_admin
on public.ticket_messages
for update
to authenticated
using (
  public.is_ticket_admin()
  or exists (
    select 1 from public.tickets t
    where t.id = ticket_messages.ticket_id
      and t.user_id = auth.uid()
  )
)
with check (
  public.is_ticket_admin()
  or exists (
    select 1 from public.tickets t
    where t.id = ticket_messages.ticket_id
      and t.user_id = auth.uid()
  )
);

drop policy if exists ticket_messages_admin_delete on public.ticket_messages;
create policy ticket_messages_admin_delete
on public.ticket_messages
for delete
to authenticated
using (public.is_ticket_admin());

-- 7) Grants base
grant usage on schema public to anon, authenticated;
grant select, insert, update on public.user_profiles to authenticated;
grant select, insert, update, delete on public.tickets to authenticated;
grant select, insert, update, delete on public.ticket_messages to authenticated;

-- 8) Crear/actualizar perfil admin de tickets (el user debe existir en auth.users)
insert into public.user_profiles (id, email, name, is_admin, is_online, last_seen, updated_at)
select u.id, u.email, coalesce(u.raw_user_meta_data->>'name', 'Admin Tickets TradeHud'), true, true, now(), now()
from auth.users u
where lower(u.email) = 'admin@tradehud.com'
on conflict (id) do update set
  email = excluded.email,
  name = excluded.name,
  is_admin = true,
  updated_at = now();

-- Si no existe en auth.users, créalo en Supabase Dashboard:
-- Authentication -> Users -> Add user
-- email: admin@tradehud.com
-- password: TradeHudAdmin2026!
