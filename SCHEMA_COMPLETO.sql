-- TradeHud schema completo (auth + tickets + catálogos + categorías + precios)
-- Actualizado: 2026-05-01 (incluye storage bucket tradehud-assets + políticas)
-- Compatible con PostgreSQL/Supabase (sin "create policy if not exists")

create extension if not exists "pgcrypto";

-- =========================
-- 1) PERFILES
-- =========================
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

-- =========================
-- 2) TICKETS
-- =========================
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

-- =========================
-- 3) CATÁLOGO MARKETPLACE
-- =========================
create table if not exists public.market_catalog_entries (
  id uuid primary key default gen_random_uuid(),
  service_type text not null check (service_type in ('p2p','streaming','giftcards','gold')),
  entry_type text not null check (entry_type in ('category','price')),
  category_name text not null default '',
  item_name text not null default '',
  image text not null default '',
  value text not null default '',
  currency text not null default 'USD',
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

-- =========================
-- 4) ORO POR JUEGO/SERVIDOR
-- =========================
create table if not exists public.gold_catalog_entries (
  id uuid primary key default gen_random_uuid(),
  game text not null,
  server text not null,
  package_name text not null,
  price_usd numeric(12,2) not null default 0,
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

-- =========================
-- RLS
-- =========================
alter table public.user_profiles enable row level security;
alter table public.tickets enable row level security;
alter table public.market_catalog_entries enable row level security;
alter table public.gold_catalog_entries enable row level security;

-- Limpiar políticas previas si existen
drop policy if exists "user_profiles_select_own" on public.user_profiles;
drop policy if exists "user_profiles_upsert_own" on public.user_profiles;
drop policy if exists "tickets_select_own" on public.tickets;
drop policy if exists "tickets_insert_own" on public.tickets;
drop policy if exists "tickets_select_admin" on public.tickets;
drop policy if exists "market_catalog_public_read" on public.market_catalog_entries;
drop policy if exists "market_catalog_admin_write" on public.market_catalog_entries;
drop policy if exists "gold_catalog_public_read" on public.gold_catalog_entries;
drop policy if exists "gold_catalog_admin_write" on public.gold_catalog_entries;

-- perfiles
create policy "user_profiles_select_own"
on public.user_profiles
for select
using (auth.uid() = id);

create policy "user_profiles_upsert_own"
on public.user_profiles
for all
using (auth.uid() = id)
with check (auth.uid() = id);

-- tickets usuario dueño
create policy "tickets_select_own"
on public.tickets
for select
using (auth.uid() = user_id);

create policy "tickets_insert_own"
on public.tickets
for insert
with check (auth.uid() = user_id);

-- tickets admin
create policy "tickets_select_admin"
on public.tickets
for select
using (
  exists (
    select 1
    from public.user_profiles p
    where p.id = auth.uid() and p.is_admin = true
  )
);

-- catálogo lectura pública
create policy "market_catalog_public_read"
on public.market_catalog_entries
for select
using (true);

create policy "gold_catalog_public_read"
on public.gold_catalog_entries
for select
using (true);

-- catálogo escritura admin
create policy "market_catalog_admin_write"
on public.market_catalog_entries
for all
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

create policy "gold_catalog_admin_write"
on public.gold_catalog_entries
for all
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

-- =========================
-- 5) SEED CATÁLOGO MARKETPLACE (P2P, STREAMING, GIFTCARDS)
-- =========================
insert into public.market_catalog_entries (service_type, entry_type, category_name, item_name, image, value, sort_order)
values
('p2p','category','ZINLI','ZINLI','https://cdn.discordapp.com/attachments/1495867730752966788/1496252825313738893/ChatGPT_Image_20_abr_2026_06_02_01_p.m..png','',1),
('p2p','category','PAYPAL','PAYPAL','https://cdn.discordapp.com/attachments/1495867730752966788/1496252825313738893/ChatGPT_Image_20_abr_2026_06_02_01_p.m..png','',2),
('streaming','category','Streaming Apps','Streaming Apps','https://cdn.discordapp.com/attachments/1495867730752966788/1496280085509050398/ChatGPT_Image_21_abr_2026_06_42_28_p.m..png','',1),
('giftcards','category','GiftCards Gaming','GiftCards Gaming','https://cdn.discordapp.com/attachments/1495867730752966788/1496255540295368915/ChatGPT_Image_20_abr_2026_04_27_24_p.m..png','',1)
on conflict do nothing;

insert into public.market_catalog_entries (service_type, entry_type, category_name, item_name, image, value, sort_order)
values
('p2p','price','ZINLI','Zinli 10$','','12$',1),
('p2p','price','ZINLI','Zinli 20$','','23$',2),
('p2p','price','PAYPAL','Paypal 50$','','60$',3),
('p2p','price','PAYPAL','Paypal 100$','','120$',4),
('streaming','price','Netflix','1 perfil (mes)','','4.50$',1),
('streaming','price','Disney','1 perfil (mes)','','3$',2),
('streaming','price','Prime Video','1 perfil (mes)','','3$',3),
('streaming','price','HBO','1 perfil (mes)','','3$',4),
('giftcards','price','GiftCards','10$','','13$',1),
('giftcards','price','GiftCards','20$','','26$',2),
('giftcards','price','GiftCards','50$','','65$',3),
('giftcards','price','GiftCards','100$','','130$',4)
on conflict do nothing;

-- =========================
-- 6) SEED ORO (JUEGOS/CATEGORÍAS/PRECIOS PRINCIPALES)
-- =========================
insert into public.gold_catalog_entries (game, server, package_name, price_usd, sort_order) values
('World of Warcraft 20th Anniversary TBC','(US) NIGHTSLAYER','300G',4.20,1),
('World of Warcraft 20th Anniversary TBC','(US) NIGHTSLAYER','500G',7,2),
('World of Warcraft 20th Anniversary TBC','(US) NIGHTSLAYER','1000G',14,3),
('World of Warcraft Retail','(US) WOW RETAIL','100K',4.50,1),
('World of Warcraft Retail','(US) WOW RETAIL','200K',9,2),
('World of Warcraft Project Epoch','KEZAN','100G',7,1),
('World of Warcraft Ascension','BRONZEBEARD','100G',0.90,1),
('WARMANE','Onyxia','1K',14,1),
('Albion Online','SILVER','100M',24,1),
('AION','EUROAION','100M',2.20,1),
('RuneScape','Old School RuneScape','100M',24,1),
('Diablo 2 Resurrected Runes','(PC) Ladder Season 13 Normal','100M',7.10,1),
('Dofus','Retro - Fallanster','100M',5,1),
('Flyff Universe','MUSHPOIE','100M',1.90,1),
('ODIN: Valhalla Rising Diamonds','(EU+USD) Asgard 01','1K',4.50,1),
('Mir4','(ASIA)','1000G',4,1),
('Path of Exile 1','MIRAGE SEASON NUEVA','300DV',4.50,1),
('Path of Exile 2','Divine Orbs','100,000U',3,1),
('Throne and Liberty','Region Global Americas','2K',9.60,1),
('Torchlight Infinite','(USD) Season Lunaria','1000U',1.10,1),
('The Quinfall','Region (USD)','500M',10.20,1),
('Lineage 2 (Reborn)','ORIGIN X1','50M',6.28,1),
('Warbone Above Ashes','America','2K',10.52,1)
on conflict do nothing;

-- =========================
-- 7) TABLAS FALTANTES PARA PANEL ADMIN (games / gold_categories)
-- =========================
create table if not exists public.games (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  icon text not null default '',
  description text not null default '',
  services text[] not null default array['gold','boosting','accounts'],
  custom_service_enabled boolean not null default false,
  custom_service_name text not null default '',
  custom_service_image text not null default '',
  custom_service_hide_name boolean not null default false,
  replace_gold_with_custom boolean not null default false,
  created_at timestamptz not null default now(),
  unique(name)
);

-- Compatibilidad para instalaciones previas (si la tabla ya existía sin estas columnas)
alter table public.games add column if not exists services text[] not null default array['gold','boosting','accounts'];
alter table public.games add column if not exists custom_service_enabled boolean not null default false;
alter table public.games add column if not exists custom_service_name text not null default '';
alter table public.games add column if not exists custom_service_image text not null default '';
alter table public.games add column if not exists custom_service_hide_name boolean not null default false;
alter table public.games add column if not exists replace_gold_with_custom boolean not null default false;

create table if not exists public.gold_categories (
  id uuid primary key default gen_random_uuid(),
  game text not null default 'General',
  name text not null,
  description text not null default 'Sin descripción.',
  created_at timestamptz not null default now(),
  unique(game, name)
);

create unique index if not exists games_name_key on public.games (name);
create unique index if not exists gold_categories_game_name_key on public.gold_categories (game, name);

alter table public.games enable row level security;
alter table public.gold_categories enable row level security;

drop policy if exists "games_public_read" on public.games;
drop policy if exists "games_admin_write" on public.games;
drop policy if exists "gold_categories_public_read" on public.gold_categories;
drop policy if exists "gold_categories_admin_write" on public.gold_categories;

create policy "games_public_read"
on public.games
for select
using (true);

create policy "games_admin_write"
on public.games
for all
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

create policy "gold_categories_public_read"
on public.gold_categories
for select
using (true);

create policy "gold_categories_admin_write"
on public.gold_categories
for all
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

insert into public.games (name, icon, description, services) values
('World of Warcraft 20th Anniversary TBC','', 'Catálogo TBC anniversary.', array['gold','boosting','accounts']),
('World of Warcraft Retail','', 'Catálogo Retail US/EU.', array['gold','boosting','accounts']),
('World of Warcraft Project Epoch','', 'Project Epoch gold.', array['gold','boosting','accounts']),
('World of Warcraft Ascension','', 'Ascension gold.', array['gold','boosting','accounts']),
('WARMANE','', 'Onyxia/Lordaeron/Icecrown.', array['gold','boosting','accounts']),
('Albion Online','', 'Compra/venta de plata y servicios por encargo.', array['gold']),
('AION','', 'Kinah EUROAION.', array['gold']),
('Aion 2','', 'TW Triniel/Vaziel.', array['gold']),
('RuneScape','', 'Old School RuneScape.', array['gold']),
('Diablo 2 Resurrected Runes','', 'Ladder Season 13.', array['gold']),
('LAWL','', 'Lawl Global.', array['gold']),
('Dofus','', 'Retro servers.', array['gold']),
('Flyff Universe','', 'MUSHPOIE / TOTENMANIA / BURUDENG / FWC-2026.', array['gold']),
('ODIN: Valhalla Rising Diamonds','', 'Asgard 01-09.', array['gold']),
('Mir4','', 'ASIA / EU / NA / SA.', array['gold']),
('Rubinot','', 'Rubinicoin.', array['gold']),
('Tibia','', 'Tibicoin.', array['gold']),
('Path of Exile 1','', 'Mirage Season.', array['gold']),
('Path of Exile 2','', 'Divine Orbs.', array['gold']),
('Throne and Liberty','', 'Global Americas.', array['gold']),
('Torchlight Infinite','', 'Season Lunaria USD/EU.', array['gold']),
('The Quinfall','', 'Region USD/EU.', array['gold']),
('Warbone Above Ashes','', 'America / Europa.', array['gold'])
on conflict do nothing;

-- =========================
-- 8) SEED COMERCIAL (VENDemos) Y TARJETAS P2P
-- =========================
insert into public.market_catalog_entries (service_type, entry_type, category_name, item_name, image, value, currency, sort_order)
values
('p2p','category','Tarjetas P2P','Zinli / PayPal / GiftCards','https://cdn.discordapp.com/attachments/1495867730752966788/1496252825313738893/ChatGPT_Image_20_abr_2026_06_02_01_p.m..png','','USD',10),
('p2p','price','Tarjetas P2P','Vendemos Zinli 10$','https://cdn.discordapp.com/attachments/1495867730752966788/1496252825313738893/ChatGPT_Image_20_abr_2026_06_02_01_p.m..png','12$','USD',11),
('p2p','price','Tarjetas P2P','Vendemos Zinli 20$','https://cdn.discordapp.com/attachments/1495867730752966788/1496252825313738893/ChatGPT_Image_20_abr_2026_06_02_01_p.m..png','23$','USD',12),
('p2p','price','Tarjetas P2P','Vendemos PayPal 50$','https://cdn.discordapp.com/attachments/1495867730752966788/1496252825313738893/ChatGPT_Image_20_abr_2026_06_02_01_p.m..png','60$','USD',13),
('p2p','price','Tarjetas P2P','Vendemos PayPal 100$','https://cdn.discordapp.com/attachments/1495867730752966788/1496252825313738893/ChatGPT_Image_20_abr_2026_06_02_01_p.m..png','120$','USD',14)
on conflict do nothing;

-- Escala de paquetes para WoW TBC Anniversary (100G a 1000G)
insert into public.gold_catalog_entries (game, server, package_name, price_usd, sort_order) values
('World of Warcraft 20th Anniversary TBC','(US) NIGHTSLAYER','100G',1.40,101),
('World of Warcraft 20th Anniversary TBC','(US) NIGHTSLAYER','200G',2.80,102),
('World of Warcraft 20th Anniversary TBC','(US) NIGHTSLAYER','300G',4.20,103),
('World of Warcraft 20th Anniversary TBC','(US) NIGHTSLAYER','400G',5.60,104),
('World of Warcraft 20th Anniversary TBC','(US) NIGHTSLAYER','500G',7.00,105),
('World of Warcraft 20th Anniversary TBC','(US) NIGHTSLAYER','600G',8.40,106),
('World of Warcraft 20th Anniversary TBC','(US) NIGHTSLAYER','700G',9.80,107),
('World of Warcraft 20th Anniversary TBC','(US) NIGHTSLAYER','800G',11.20,108),
('World of Warcraft 20th Anniversary TBC','(US) NIGHTSLAYER','900G',12.60,109),
('World of Warcraft 20th Anniversary TBC','(US) NIGHTSLAYER','1000G',14.00,110)
on conflict do nothing;

-- =========================
-- 9) ASSETS (LOGO + ICONOS DE SECCIONES)
-- =========================
create table if not exists public.app_assets (
  key text primary key,
  image_url text not null,
  created_at timestamptz not null default now()
);

alter table public.app_assets enable row level security;

drop policy if exists "app_assets_public_read" on public.app_assets;
drop policy if exists "app_assets_admin_write" on public.app_assets;

create policy "app_assets_public_read"
on public.app_assets
for select
using (true);

create policy "app_assets_admin_write"
on public.app_assets
for all
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

insert into public.app_assets (key, image_url) values
('logo_main','https://i.imgur.com/BzQZCIH.png'),
('service_gold','https://i.imgur.com/c5ktaxz.png'),
('service_boosting','https://i.imgur.com/9QHS0xN.png'),
('service_accounts','https://i.imgur.com/MfZK9dg.png'),
('service_sell_gold','https://i.imgur.com/ODy7Rqb.png')
on conflict (key) do update set image_url = excluded.image_url;
-- Nota: usamos DO NOTHING para no sobreescribir logos/imágenes personalizados al re-ejecutar el schema.

-- =========================
-- 10) STORAGE PARA IMÁGENES DESDE PC
-- =========================
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'tradehud-assets',
  'tradehud-assets',
  true,
  5242880,
  array['image/png','image/jpeg','image/webp','image/gif']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "tradehud_assets_public_read" on storage.objects;
drop policy if exists "tradehud_assets_admin_write" on storage.objects;

create policy "tradehud_assets_public_read"
on storage.objects
for select
using (bucket_id = 'tradehud-assets');

create policy "tradehud_assets_admin_write"
on storage.objects
for all
using (
  bucket_id = 'tradehud-assets'
  and exists (
    select 1 from public.user_profiles p
    where p.id = auth.uid() and p.is_admin = true
  )
)
with check (
  bucket_id = 'tradehud-assets'
  and exists (
    select 1 from public.user_profiles p
    where p.id = auth.uid() and p.is_admin = true
  )
);
