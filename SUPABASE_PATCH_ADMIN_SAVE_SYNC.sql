create extension if not exists pgcrypto;

create table if not exists public.app_assets (
  key text primary key,
  image_url text not null default '',
  updated_at timestamptz not null default now()
);

create table if not exists public.gold_catalog_entries (
  id uuid primary key default gen_random_uuid(),
  game text not null,
  server text not null,
  package_name text not null,
  price_usd numeric(12,2) not null default 0,
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

create unique index if not exists gold_catalog_entries_unique_key
on public.gold_catalog_entries (game, server, package_name);

alter table public.app_assets enable row level security;
alter table public.gold_catalog_entries enable row level security;

drop policy if exists app_assets_public_read on public.app_assets;
drop policy if exists app_assets_admin_write on public.app_assets;
drop policy if exists app_assets_authenticated_write on public.app_assets;

create policy app_assets_public_read
on public.app_assets
for select
using (true);

create policy app_assets_admin_write
on public.app_assets
for all
using (exists (select 1 from public.user_profiles p where p.id = auth.uid() and p.is_admin = true))
with check (exists (select 1 from public.user_profiles p where p.id = auth.uid() and p.is_admin = true));

create policy app_assets_authenticated_write
on public.app_assets
for all
to authenticated
using (true)
with check (true);

drop policy if exists gold_catalog_public_read on public.gold_catalog_entries;
drop policy if exists gold_catalog_admin_write on public.gold_catalog_entries;
drop policy if exists gold_catalog_authenticated_write on public.gold_catalog_entries;

create policy gold_catalog_public_read
on public.gold_catalog_entries
for select
using (true);

create policy gold_catalog_admin_write
on public.gold_catalog_entries
for all
using (exists (select 1 from public.user_profiles p where p.id = auth.uid() and p.is_admin = true))
with check (exists (select 1 from public.user_profiles p where p.id = auth.uid() and p.is_admin = true));

create policy gold_catalog_authenticated_write
on public.gold_catalog_entries
for all
to authenticated
using (true)
with check (true);

grant select on public.app_assets to anon;
grant select, insert, update, delete on public.app_assets to authenticated;

grant select on public.gold_catalog_entries to anon;
grant select, insert, update, delete on public.gold_catalog_entries to authenticated;

select 'ok_app_assets' as check_name, count(*)::int as total from public.app_assets
union all
select 'ok_gold_catalog_entries', count(*)::int from public.gold_catalog_entries;
