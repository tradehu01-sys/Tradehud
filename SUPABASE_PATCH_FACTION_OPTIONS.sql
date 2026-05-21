-- Patch pequeño: habilitar guardado de facciones/opciones por juego desde panel admin web (modo anon).
-- Fecha: 2026-05-21
-- Ejecutar en Supabase SQL Editor.

begin;

create table if not exists public.gold_game_options (
  game text primary key,
  faction_disabled boolean not null default false,
  faction_options text[] not null default array['Alianza','Horda','Neutral'],
  updated_at timestamptz not null default now()
);

alter table public.gold_game_options enable row level security;

-- Lectura pública para render en frontend.
drop policy if exists "gold_game_options_public_read" on public.gold_game_options;
create policy "gold_game_options_public_read"
  on public.gold_game_options
  for select
  to anon, authenticated
  using (true);

-- Escritura para usuarios autenticados admin (flujo recomendado).
drop policy if exists "gold_game_options_admin_write" on public.gold_game_options;
create policy "gold_game_options_admin_write"
  on public.gold_game_options
  for all
  to authenticated
  using (exists (
    select 1 from public.user_profiles p
    where p.id = auth.uid() and p.is_admin = true
  ))
  with check (exists (
    select 1 from public.user_profiles p
    where p.id = auth.uid() and p.is_admin = true
  ));

-- Compatibilidad con panel admin local (sin auth.uid, usando rol anon).
-- Importante: esto abre escritura anon en esta tabla; úsalo solo si dependes del admin local.
drop policy if exists "gold_game_options_admin_panel_write" on public.gold_game_options;
create policy "gold_game_options_admin_panel_write"
  on public.gold_game_options
  for all
  to anon
  using (true)
  with check (
    game is not null
    and length(trim(game)) > 0
    and cardinality(faction_options) >= 0
  );

grant select on public.gold_game_options to anon;
grant select, insert, update, delete on public.gold_game_options to authenticated;
grant insert, update, delete on public.gold_game_options to anon;

commit;
