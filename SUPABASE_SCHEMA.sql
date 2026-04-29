-- TradeHud schema (sin localhost, todo en base de datos)

create extension if not exists "pgcrypto";

create table if not exists public.user_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null default 'Usuario',
  email text not null,
  discord text default '',
  phone text default '',
  is_admin boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.tickets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  game text not null default '',
  server text not null default '',
  product text not null default '',
  faction text not null default '',
  character text not null default '',
  delivery text not null default '',
  status text not null default 'pendiente',
  created_at timestamptz not null default now()
);

create table if not exists public.market_catalog_entries (
  id uuid primary key default gen_random_uuid(),
  service_type text not null check (service_type in ('p2p','streaming','giftcards')),
  entry_type text not null check (entry_type in ('category','price')),
  name text not null default '',
  image text not null default '',
  value text not null default '',
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

-- RLS
alter table public.user_profiles enable row level security;
alter table public.tickets enable row level security;
alter table public.market_catalog_entries enable row level security;

-- perfiles
create policy if not exists "user_profiles_select_own"
on public.user_profiles for select
using (auth.uid() = id);

create policy if not exists "user_profiles_upsert_own"
on public.user_profiles for all
using (auth.uid() = id)
with check (auth.uid() = id);

-- tickets (usuario dueño)
create policy if not exists "tickets_select_own"
on public.tickets for select
using (auth.uid() = user_id);

create policy if not exists "tickets_insert_own"
on public.tickets for insert
with check (auth.uid() = user_id);

-- admin básico por profile
create policy if not exists "tickets_select_admin"
on public.tickets for select
using (
  exists (
    select 1 from public.user_profiles p
    where p.id = auth.uid() and p.is_admin = true
  )
);

create policy if not exists "market_catalog_public_read"
on public.market_catalog_entries for select
using (true);

create policy if not exists "market_catalog_admin_write"
on public.market_catalog_entries for all
using (
  exists (
    select 1 from public.user_profiles p
    where p.id = auth.uid() and p.is_admin = true
  )
)
with check (
  exists (
    select 1 from public.user_profiles p
    where p.id = auth.uid() and p.is_admin = true
  )
);
