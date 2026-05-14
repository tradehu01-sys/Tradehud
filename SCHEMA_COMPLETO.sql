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
-- 3) CATÁLOGO DE SERVICIOS
-- =========================
create table if not exists public.service_catalog_entries (
  id uuid primary key default gen_random_uuid(),
  service_type text not null check (service_type in ('p2p','streaming','giftcards','gold')),
  entry_type text not null check (entry_type in ('category','price')),
  category_name text not null default '',
  item_name text not null default '',
  account_type text not null default '',
  billing_period text not null default '',
  amount_label text not null default '',
  image text not null default '',
  value text not null default '',
  currency text not null default 'USD',
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);
alter table public.service_catalog_entries add column if not exists account_type text not null default '';
alter table public.service_catalog_entries add column if not exists billing_period text not null default '';
alter table public.service_catalog_entries add column if not exists amount_label text not null default '';
-- Limpia duplicados históricos antes de crear índice único
delete from public.service_catalog_entries a
using public.service_catalog_entries b
where a.ctid < b.ctid
  and a.service_type = b.service_type
  and a.entry_type = b.entry_type
  and coalesce(a.category_name, '') = coalesce(b.category_name, '')
  and coalesce(a.item_name, '') = coalesce(b.item_name, '')
  and coalesce(a.value, '') = coalesce(b.value, '');
create unique index if not exists service_catalog_entries_unique_key
on public.service_catalog_entries (service_type, entry_type, category_name, item_name, value);

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
alter table public.service_catalog_entries enable row level security;
alter table public.gold_catalog_entries enable row level security;

-- Limpiar políticas previas si existen
drop policy if exists "user_profiles_select_own" on public.user_profiles;
drop policy if exists "user_profiles_upsert_own" on public.user_profiles;
drop policy if exists "tickets_select_own" on public.tickets;
drop policy if exists "tickets_insert_own" on public.tickets;
drop policy if exists "tickets_select_admin" on public.tickets;
drop policy if exists "service_catalog_public_read" on public.service_catalog_entries;
drop policy if exists "service_catalog_admin_write" on public.service_catalog_entries;
drop policy if exists "service_catalog_authenticated_write" on public.service_catalog_entries;
drop policy if exists "service_catalog_anon_write" on public.service_catalog_entries;
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
create policy "service_catalog_public_read"
on public.service_catalog_entries
for select
using (true);

create policy "gold_catalog_public_read"
on public.gold_catalog_entries
for select
using (true);

-- catálogo escritura admin
create policy "service_catalog_admin_write"
on public.service_catalog_entries
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

create policy "service_catalog_authenticated_write"
on public.service_catalog_entries
for all
to authenticated
using (auth.uid() is not null)
with check (auth.uid() is not null);

create policy "service_catalog_anon_write"
on public.service_catalog_entries
for all
to anon
using (true)
with check (true);

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
-- 5) SEED CATÁLOGO DE SERVICIOS (P2P, STREAMING, GIFTCARDS)
-- =========================
-- Normaliza P2P/Streaming para evitar precios antiguos al re-ejecutar el schema.
delete from public.service_catalog_entries where service_type in ('p2p','streaming') and entry_type = 'price';
delete from public.service_catalog_entries where service_type = 'streaming' and entry_type = 'category' and category_name in ('Discord Nitro','Gemini');
delete from public.service_catalog_entries where service_type = 'giftcards' and entry_type = 'price' and category_name in ('Discord Nitro','Gemini');
insert into public.service_catalog_entries (service_type, entry_type, category_name, item_name, image, value, sort_order)
values
('p2p','category','ZINLI','ZINLI','https://cdn.discordapp.com/attachments/1495867730752966788/1496252825313738893/ChatGPT_Image_20_abr_2026_06_02_01_p.m..png','',1),
('p2p','category','PAYPAL','PAYPAL','https://cdn.discordapp.com/attachments/1495867730752966788/1496252825313738893/ChatGPT_Image_20_abr_2026_06_02_01_p.m..png','',2),
('p2p','category','Cambio BS / USDT','Cambio BS / USDT','','',3),
('streaming','category','Netflix','Netflix','https://upload.wikimedia.org/wikipedia/commons/0/08/Netflix_2015_logo.svg','',1),
('streaming','category','Disney','Disney','https://upload.wikimedia.org/wikipedia/commons/3/3e/Disney%2B_logo.svg','',2),
('streaming','category','Prime Video','Prime Video','https://upload.wikimedia.org/wikipedia/commons/f/f1/Prime_Video.png','',3),
('streaming','category','HBO','HBO','https://upload.wikimedia.org/wikipedia/commons/1/17/HBO_Max_Logo.svg','',4),
('streaming','category','Crunchyroll','Crunchyroll','https://upload.wikimedia.org/wikipedia/commons/0/08/Crunchyroll_Logo.png','',5),
('streaming','category','YouTube','YouTube','https://upload.wikimedia.org/wikipedia/commons/b/b8/YouTube_Logo_2017.svg','',6),
('streaming','category','Chat GPT','Chat GPT','https://upload.wikimedia.org/wikipedia/commons/0/04/ChatGPT_logo.svg','',7),
('streaming','category','CapCut Pro','CapCut Pro','https://upload.wikimedia.org/wikipedia/commons/a/a9/CapCut_logo.svg','',8),
('streaming','category','Paramount','Paramount','https://upload.wikimedia.org/wikipedia/commons/9/94/Paramount%2B_logo.svg','',9),
('streaming','category','Apple TV','Apple TV','https://upload.wikimedia.org/wikipedia/commons/f/fa/Apple_logo_black.svg','',10),
('streaming','category','CAMVA EDU PRO','CAMVA EDU PRO','https://upload.wikimedia.org/wikipedia/commons/0/08/Canva_icon_2021.svg','',11),
('giftcards','category','Battle Net Gift Card','Battle Net Gift Card','https://cdn.discordapp.com/attachments/1495867730752966788/1496255540295368915/ChatGPT_Image_20_abr_2026_04_27_24_p.m..png','',1),
('giftcards','category','Amazon Gift Card','Amazon Gift Card','https://cdn.discordapp.com/attachments/1495867730752966788/1496255540295368915/ChatGPT_Image_20_abr_2026_04_27_24_p.m..png','',2),
('giftcards','category','Roblox Gift Cards','Roblox Gift Cards','https://cdn.discordapp.com/attachments/1495867730752966788/1496255540295368915/ChatGPT_Image_20_abr_2026_04_27_24_p.m..png','',3),
('giftcards','category','PlayStation Gift Card','PlayStation Gift Card','https://cdn.discordapp.com/attachments/1495867730752966788/1496255540295368915/ChatGPT_Image_20_abr_2026_04_27_24_p.m..png','',4),
('giftcards','category','Apple Gift Cards','Apple Gift Cards','https://cdn.discordapp.com/attachments/1495867730752966788/1496255540295368915/ChatGPT_Image_20_abr_2026_04_27_24_p.m..png','',5),
('giftcards','category','Steam Gift Cards','Steam Gift Cards','https://cdn.discordapp.com/attachments/1495867730752966788/1496255540295368915/ChatGPT_Image_20_abr_2026_04_27_24_p.m..png','',6),
('giftcards','category','Xbox Gift Cards','Xbox Gift Cards','https://cdn.discordapp.com/attachments/1495867730752966788/1496255540295368915/ChatGPT_Image_20_abr_2026_04_27_24_p.m..png','',7),
('giftcards','category','Valorant Gift Cards','Valorant Gift Cards','https://cdn.discordapp.com/attachments/1495867730752966788/1496255540295368915/ChatGPT_Image_20_abr_2026_04_27_24_p.m..png','',8),
('giftcards','category','Garena Free Fire Gift Cards','Garena Free Fire Gift Cards','https://cdn.discordapp.com/attachments/1495867730752966788/1496255540295368915/ChatGPT_Image_20_abr_2026_04_27_24_p.m..png','',9),
('giftcards','category','Google Play Gift Cards','Google Play Gift Cards','https://cdn.discordapp.com/attachments/1495867730752966788/1496255540295368915/ChatGPT_Image_20_abr_2026_04_27_24_p.m..png','',10),
('giftcards','category','Discord Nitro','Discord Nitro','https://cdn.simpleicons.org/discord/5865F2','',11),
('giftcards','category','Gemini','Gemini','https://upload.wikimedia.org/wikipedia/commons/8/8f/Google-gemini-icon.svg','',12)
on conflict do nothing;

insert into public.service_catalog_entries (service_type, entry_type, category_name, item_name, image, value, sort_order)
values
('p2p','price','ZINLI','Zinli 1$','','ZINLI - Zinli 1$ - 1.30$',1),
('p2p','price','ZINLI','Zinli 2$','','ZINLI - Zinli 2$ - 2.60$',2),
('p2p','price','ZINLI','Zinli 5$','','ZINLI - Zinli 5$ - 6.50$',3),
('p2p','price','ZINLI','Zinli 10$','','ZINLI - Zinli 10$ - 12$',4),
('p2p','price','ZINLI','Zinli 15$','','ZINLI - Zinli 15$ - 17.25$',5),
('p2p','price','ZINLI','Zinli 20$','','ZINLI - Zinli 20$ - 23$',6),
('p2p','price','ZINLI','Zinli 25$','','ZINLI - Zinli 25$ - 28.75$',7),
('p2p','price','ZINLI','Zinli 30$','','ZINLI - Zinli 30$ - 34.50$',8),
('p2p','price','ZINLI','Zinli 40$','','ZINLI - Zinli 40$ - 46$',9),
('p2p','price','ZINLI','Zinli 50$','','ZINLI - Zinli 50$ - 57.50$',10),
('p2p','price','ZINLI','Zinli 100$','','ZINLI - Zinli 100$ - 115$',11),
('p2p','price','PAYPAL','Paypal 10$','','PAYPAL - Paypal 10$ - 12.50$',12),
('p2p','price','PAYPAL','Paypal 20$','','PAYPAL - Paypal 20$ - 24$',13),
('p2p','price','PAYPAL','Paypal 50$','','PAYPAL - Paypal 50$ - 60$',14),
('p2p','price','PAYPAL','Paypal 100$','','PAYPAL - Paypal 100$ - 120$',15),
('p2p','price','PAYPAL','Paypal 200$','','PAYPAL - Paypal 200$ - 240$',16),
('p2p','price','PAYPAL','Paypal 300$','','PAYPAL - Paypal 300$ - 360$',17),
('p2p','price','Cambio BS / USDT','BS x USDT','','Cambio BS / USDT - BS x USDT - Tasa del día -30 BS',18),
('p2p','price','Cambio BS / USDT','USDT x BS','','Cambio BS / USDT - USDT x BS - Tasa del día +30 BS',19),
('streaming','price','Netflix','1 PERFIL 4.50$ (MES)','','1 PERFIL 4.50$ (MES)',1),
('streaming','price','Netflix','CUENTA COMPLETA 17$ (MES)','','CUENTA COMPLETA 17$ (MES)',2),
('streaming','price','Disney','1 PERFIL 3$ (MES)','','1 PERFIL 3$ (MES)',3),
('streaming','price','Disney','CUENTA COMPLETA 15$ (MES)','','CUENTA COMPLETA 15$ (MES)',4),
('streaming','price','Prime Video','1 PERFIL 3$ (MES)','','1 PERFIL 3$ (MES)',5),
('streaming','price','HBO','1 PERFIL 3$ (MES)','','1 PERFIL 3$ (MES)',6),
('streaming','price','HBO','CUENTA COMPLETA 10$ (MES)','','CUENTA COMPLETA 10$ (MES)',7),
('streaming','price','Crunchyroll','1 PERFIL 2$ (MES)','','1 PERFIL 2$ (MES)',8),
('streaming','price','YouTube','1 PERFIL 3$ (MES)','','1 PERFIL 3$ (MES)',9),
('streaming','price','Chat GPT','1 PERFIL 4$ (MES)','','1 PERFIL 4$ (MES)',10),
('streaming','price','CapCut Pro','1 PERFIL 3$ (MES)','','1 PERFIL 3$ (MES)',11),
('streaming','price','Paramount','1 PERFIL 2.50$ (MES)','','1 PERFIL 2.50$ (MES)',12),
('streaming','price','Apple TV','1 PERFIL 3$ (MES)','','1 PERFIL 3$ (MES)',13),
('streaming','price','CAMVA EDU PRO','1 AÑO 3$','','1 AÑO 3$',14),
('giftcards','price','Discord Nitro','BASIC MES 4.49$','','Discord Nitro - BASIC MES 4.49$',101),
('giftcards','price','Discord Nitro','BASIC AÑO 44.99$','','Discord Nitro - BASIC AÑO 44.99$',102),
('giftcards','price','Discord Nitro','NITRO MES 11.99$','','Discord Nitro - NITRO MES 11.99$',103),
('giftcards','price','Discord Nitro','NITRO AÑO 119.99$','','Discord Nitro - NITRO AÑO 119.99$',104),
('giftcards','price','Gemini','1 MES 2.50$','','Gemini - 1 MES 2.50$',105),
('giftcards','price','Gemini','1 AÑO 7$','','Gemini - 1 AÑO 7$',106),
('giftcards','price','GiftCards','10$','','13$',1),
('giftcards','price','GiftCards','20$','','26$',2),
('giftcards','price','GiftCards','50$','','65$',3),
('giftcards','price','GiftCards','100$','','130$',4)
on conflict do nothing;

-- =========================
-- 6) SEED ORO COMPLETO (precios y servidores enviados 27/04/2026)
-- =========================
-- Normaliza duplicados antes de aplicar llave única por juego/servidor/paquete.
delete from public.gold_catalog_entries a
using public.gold_catalog_entries b
where a.ctid < b.ctid
  and a.game = b.game
  and a.server = b.server
  and a.package_name = b.package_name;
create unique index if not exists gold_catalog_entries_unique_key
on public.gold_catalog_entries (game, server, package_name);

-- El seed de oro es autoritativo: mantiene la base alineada con la lista comercial enviada.
delete from public.gold_catalog_entries;
insert into public.gold_catalog_entries (game, server, package_name, price_usd, sort_order) values
('World of Warcraft 20th Anniversary TBC','(US) NIGHTLASYER','300G',4.20,1),
('World of Warcraft 20th Anniversary TBC','(US) NIGHTLASYER','500G',7.00,2),
('World of Warcraft 20th Anniversary TBC','(US) NIGHTLASYER','1000G',14.00,3),
('World of Warcraft 20th Anniversary TBC','(US) NIGHTLASYER','2000G',28.00,4),
('World of Warcraft 20th Anniversary TBC','(US) NIGHTLASYER','5000G',70.00,5),
('World of Warcraft 20th Anniversary TBC','(US) NIGHTLASYER','10000G',140.00,6),
('World of Warcraft 20th Anniversary TBC','(US) DREAMSCYTHE','300G',4.20,1),
('World of Warcraft 20th Anniversary TBC','(US) DREAMSCYTHE','500G',7.00,2),
('World of Warcraft 20th Anniversary TBC','(US) DREAMSCYTHE','1000G',14.00,3),
('World of Warcraft 20th Anniversary TBC','(US) DREAMSCYTHE','2000G',28.00,4),
('World of Warcraft 20th Anniversary TBC','(US) DREAMSCYTHE','5000G',70.00,5),
('World of Warcraft 20th Anniversary TBC','(US) DREAMSCYTHE','10000G',140.00,6),
('World of Warcraft 20th Anniversary TBC','(EU) SPINESHATTER','300G',4.20,1),
('World of Warcraft 20th Anniversary TBC','(EU) SPINESHATTER','500G',7.00,2),
('World of Warcraft 20th Anniversary TBC','(EU) SPINESHATTER','1000G',14.00,3),
('World of Warcraft 20th Anniversary TBC','(EU) SPINESHATTER','2000G',28.00,4),
('World of Warcraft 20th Anniversary TBC','(EU) SPINESHATTER','5000G',70.00,5),
('World of Warcraft 20th Anniversary TBC','(EU) SPINESHATTER','10000G',140.00,6),
('World of Warcraft 20th Anniversary TBC','(EU) THUNDERSTRIKE','300G',4.20,1),
('World of Warcraft 20th Anniversary TBC','(EU) THUNDERSTRIKE','500G',7.00,2),
('World of Warcraft 20th Anniversary TBC','(EU) THUNDERSTRIKE','1000G',14.00,3),
('World of Warcraft 20th Anniversary TBC','(EU) THUNDERSTRIKE','2000G',28.00,4),
('World of Warcraft 20th Anniversary TBC','(EU) THUNDERSTRIKE','5000G',70.00,5),
('World of Warcraft 20th Anniversary TBC','(EU) THUNDERSTRIKE','10000G',140.00,6),
('World of Warcraft 20th Anniversary TBC','(EU) SOULSEEKER','300G',4.20,1),
('World of Warcraft 20th Anniversary TBC','(EU) SOULSEEKER','500G',7.00,2),
('World of Warcraft 20th Anniversary TBC','(EU) SOULSEEKER','1000G',14.00,3),
('World of Warcraft 20th Anniversary TBC','(EU) SOULSEEKER','2000G',28.00,4),
('World of Warcraft 20th Anniversary TBC','(EU) SOULSEEKER','5000G',70.00,5),
('World of Warcraft 20th Anniversary TBC','(EU) SOULSEEKER','10000G',140.00,6),
('World of Warcraft Retail','(US) WOW RETAIL','100K',4.50,1),
('World of Warcraft Retail','(US) WOW RETAIL','200K',9.00,2),
('World of Warcraft Retail','(US) WOW RETAIL','300K',13.50,3),
('World of Warcraft Retail','(US) WOW RETAIL','500K',36.00,4),
('World of Warcraft Retail','(US) WOW RETAIL','1M',45.00,5),
('World of Warcraft Retail','(US) WOW RETAIL','2M',90.00,6),
('World of Warcraft Retail','(US) WOW RETAIL','5M',225.00,7),
('World of Warcraft Retail','(US) WOW RETAIL','10M',450.00,8),
('World of Warcraft Retail','(EU) WOW RETAIL','100K',4.50,1),
('World of Warcraft Retail','(EU) WOW RETAIL','200K',9.00,2),
('World of Warcraft Retail','(EU) WOW RETAIL','300K',13.50,3),
('World of Warcraft Retail','(EU) WOW RETAIL','500K',36.00,4),
('World of Warcraft Retail','(EU) WOW RETAIL','1M',45.00,5),
('World of Warcraft Retail','(EU) WOW RETAIL','2M',90.00,6),
('World of Warcraft Retail','(EU) WOW RETAIL','5M',225.00,7),
('World of Warcraft Retail','(EU) WOW RETAIL','10M',450.00,8),
('World of Warcraft Project Epoch','KEZAN','100G',7.00,1),
('World of Warcraft Project Epoch','KEZAN','200G',14.00,2),
('World of Warcraft Project Epoch','KEZAN','300G',21.00,3),
('World of Warcraft Project Epoch','KEZAN','500G',35.00,4),
('World of Warcraft Project Epoch','KEZAN','1000G',70.00,5),
('World of Warcraft Project Epoch','KEZAN','2000G',140.00,6),
('World of Warcraft Project Epoch','KEZAN','5000G',350.00,7),
('World of Warcraft Project Epoch','KEZAN','10000G',700.00,8),
('World of Warcraft Project Epoch','GURUBASHI','100G',7.00,1),
('World of Warcraft Project Epoch','GURUBASHI','200G',14.00,2),
('World of Warcraft Project Epoch','GURUBASHI','300G',21.00,3),
('World of Warcraft Project Epoch','GURUBASHI','500G',35.00,4),
('World of Warcraft Project Epoch','GURUBASHI','1000G',70.00,5),
('World of Warcraft Project Epoch','GURUBASHI','2000G',140.00,6),
('World of Warcraft Project Epoch','GURUBASHI','5000G',350.00,7),
('World of Warcraft Project Epoch','GURUBASHI','10000G',700.00,8),
('World of Warcraft Ascension','BRONZEBEARD','100G',0.90,1),
('World of Warcraft Ascension','BRONZEBEARD','200G',1.80,2),
('World of Warcraft Ascension','BRONZEBEARD','300G',2.70,3),
('World of Warcraft Ascension','BRONZEBEARD','500G',4.50,4),
('World of Warcraft Ascension','BRONZEBEARD','1000G',9.00,5),
('World of Warcraft Ascension','BRONZEBEARD','2000G',18.00,6),
('World of Warcraft Ascension','BRONZEBEARD','5000G',45.00,7),
('World of Warcraft Ascension','BRONZEBEARD','10000G',90.00,8),
('WARMANE','Onyxia','1K',14.00,1),
('WARMANE','Onyxia','2K',28.00,2),
('WARMANE','Onyxia','3K',42.00,3),
('WARMANE','Onyxia','5K',70.00,4),
('WARMANE','Onyxia','10K',140.00,5),
('WARMANE','Onyxia','20K',280.00,6),
('WARMANE','Onyxia','50K',700.00,7),
('WARMANE','Onyxia','100K',1400.00,8),
('WARMANE','Lordaeron','1K',14.00,1),
('WARMANE','Lordaeron','2K',28.00,2),
('WARMANE','Lordaeron','3K',42.00,3),
('WARMANE','Lordaeron','5K',70.00,4),
('WARMANE','Lordaeron','10K',140.00,5),
('WARMANE','Lordaeron','20K',280.00,6),
('WARMANE','Lordaeron','50K',700.00,7),
('WARMANE','Lordaeron','100K',1400.00,8),
('WARMANE','Icecrown','1K',14.00,1),
('WARMANE','Icecrown','2K',28.00,2),
('WARMANE','Icecrown','3K',42.00,3),
('WARMANE','Icecrown','5K',70.00,4),
('WARMANE','Icecrown','10K',140.00,5),
('WARMANE','Icecrown','20K',280.00,6),
('WARMANE','Icecrown','50K',700.00,7),
('WARMANE','Icecrown','100K',1400.00,8),
('Albion Online','SILVER','100M',24.00,1),
('Albion Online','SILVER','200M',48.00,2),
('Albion Online','SILVER','300M',72.00,3),
('Albion Online','SILVER','500M',120.00,4),
('Albion Online','SILVER','1000M',240.00,5),
('Albion Online','SILVER','2000M',480.00,6),
('Albion Online','SILVER','5000M',1200.00,7),
('Albion Online','SILVER','10000M',2400.00,8),
('AION','EUROAION','100M',2.20,1),
('AION','EUROAION','200M',4.40,2),
('AION','EUROAION','300M',6.60,3),
('AION','EUROAION','500M',11.00,4),
('AION','EUROAION','1000M',22.00,5),
('AION','EUROAION','2000M',44.00,6),
('AION','EUROAION','5000M',110.00,7),
('AION','EUROAION','10000M',220.00,8),
('Aion 2','(TW) Triniel','100M',3.50,1),
('Aion 2','(TW) Triniel','200M',7.00,2),
('Aion 2','(TW) Triniel','300M',10.50,3),
('Aion 2','(TW) Triniel','500M',17.50,4),
('Aion 2','(TW) Triniel','1000M',35.00,5),
('Aion 2','(TW) Triniel','2000M',70.00,6),
('Aion 2','(TW) Triniel','5000M',175.00,7),
('Aion 2','(TW) Triniel','10000M',350.00,8),
('Aion 2','(TW) Vaziel','100M',3.50,1),
('Aion 2','(TW) Vaziel','200M',7.00,2),
('Aion 2','(TW) Vaziel','300M',10.50,3),
('Aion 2','(TW) Vaziel','500M',17.50,4),
('Aion 2','(TW) Vaziel','1000M',35.00,5),
('Aion 2','(TW) Vaziel','2000M',70.00,6),
('Aion 2','(TW) Vaziel','5000M',175.00,7),
('Aion 2','(TW) Vaziel','10000M',350.00,8),
('RuneScape','Old School RuneScape','100M',24.00,1),
('RuneScape','Old School RuneScape','200M',48.00,2),
('RuneScape','Old School RuneScape','300M',72.00,3),
('RuneScape','Old School RuneScape','500M',120.00,4),
('RuneScape','Old School RuneScape','1000M',240.00,5),
('RuneScape','Old School RuneScape','2000M',480.00,6),
('RuneScape','Old School RuneScape','5000M',1200.00,7),
('RuneScape','Old School RuneScape','10000M',2400.00,8),
('Diablo 2 Resurrected Runes','(PC) Ladder Season 13 Normal','100M',7.10,1),
('Diablo 2 Resurrected Runes','(PC) Ladder Season 13 Normal','200M',14.20,2),
('Diablo 2 Resurrected Runes','(PC) Ladder Season 13 Normal','300M',21.13,3),
('Diablo 2 Resurrected Runes','(PC) Ladder Season 13 Normal','500M',35.50,4),
('Diablo 2 Resurrected Runes','(PC) Ladder Season 13 Normal','1000M',71.00,5),
('Diablo 2 Resurrected Runes','(PC) Ladder Season 13 Normal','2000M',142.00,6),
('Diablo 2 Resurrected Runes','(PC) Ladder Season 13 Normal','5000M',355.00,7),
('Diablo 2 Resurrected Runes','(PC) Ladder Season 13 Normal','10000M',710.00,8),
('LAWL','Lawl Global','50KK',16.50,1),
('LAWL','Lawl Global','100KK',33.00,2),
('LAWL','Lawl Global','200KK',66.00,3),
('LAWL','Lawl Global','300KK',99.00,4),
('LAWL','Lawl Global','500KK',165.00,5),
('LAWL','Lawl Global','1000KK',330.00,6),
('LAWL','Lawl Global','2000KK',660.00,7),
('LAWL','Lawl Global','5000KK',1650.00,8),
('LAWL','Lawl Global','10000KK',3300.00,9),
('Dofus','Retro - Fallanster','100M',5.00,1),
('Dofus','Retro - Fallanster','200M',10.00,2),
('Dofus','Retro - Fallanster','300M',15.00,3),
('Dofus','Retro - Fallanster','500M',25.00,4),
('Dofus','Retro - Fallanster','1000M',50.00,5),
('Dofus','Retro - Fallanster','2000M',100.00,6),
('Dofus','Retro - Fallanster','5000M',250.00,7),
('Dofus','Retro - Fallanster','10000M',500.00,8),
('Dofus','Retro - Boune','100M',30.00,1),
('Dofus','Retro - Boune','200M',60.00,2),
('Dofus','Retro - Boune','300M',90.00,3),
('Dofus','Retro - Boune','500M',150.00,4),
('Dofus','Retro - Boune','1000M',300.00,5),
('Dofus','Retro - Boune','2000M',600.00,6),
('Dofus','Retro - Boune','5000M',1500.00,7),
('Dofus','Retro - Boune','10000M',3000.00,8),
('Dofus','Retro - Allisteria','100M',10.00,1),
('Dofus','Retro - Allisteria','200M',20.00,2),
('Dofus','Retro - Allisteria','300M',30.00,3),
('Dofus','Retro - Allisteria','500M',50.00,4),
('Dofus','Retro - Allisteria','1000M',100.00,5),
('Dofus','Retro - Allisteria','2000M',200.00,6),
('Dofus','Retro - Allisteria','5000M',500.00,7),
('Dofus','Retro - Allisteria','10000M',1000.00,8),
('Flyff Universe','MUSHPOIE','100M',1.90,1),
('Flyff Universe','MUSHPOIE','200M',3.80,2),
('Flyff Universe','MUSHPOIE','300M',5.70,3),
('Flyff Universe','MUSHPOIE','500M',9.50,4),
('Flyff Universe','MUSHPOIE','1000M',19.00,5),
('Flyff Universe','MUSHPOIE','2000M',38.00,6),
('Flyff Universe','MUSHPOIE','5000M',95.00,7),
('Flyff Universe','MUSHPOIE','10000M',190.00,8),
('Flyff Universe','TOTENMANIA','100M',3.45,1),
('Flyff Universe','TOTENMANIA','200M',6.90,2),
('Flyff Universe','TOTENMANIA','300M',10.35,3),
('Flyff Universe','TOTENMANIA','500M',17.25,4),
('Flyff Universe','TOTENMANIA','1000M',34.50,5),
('Flyff Universe','TOTENMANIA','2000M',69.00,6),
('Flyff Universe','TOTENMANIA','5000M',172.25,7),
('Flyff Universe','TOTENMANIA','10000M',345.00,8),
('Flyff Universe','BURUDENG','100M',2.10,1),
('Flyff Universe','BURUDENG','200M',4.20,2),
('Flyff Universe','BURUDENG','300M',6.30,3),
('Flyff Universe','BURUDENG','500M',10.50,4),
('Flyff Universe','BURUDENG','1000M',21.00,5),
('Flyff Universe','BURUDENG','2000M',42.00,6),
('Flyff Universe','BURUDENG','5000M',105.00,7),
('Flyff Universe','BURUDENG','10000M',210.00,8),
('Flyff Universe','FWC-2026','100M',9.00,1),
('Flyff Universe','FWC-2026','200M',18.00,2),
('Flyff Universe','FWC-2026','300M',27.00,3),
('Flyff Universe','FWC-2026','500M',45.00,4),
('Flyff Universe','FWC-2026','1000M',90.00,5),
('Flyff Universe','FWC-2026','2000M',180.00,6),
('Flyff Universe','FWC-2026','5000M',450.00,7),
('Flyff Universe','FWC-2026','10000M',900.00,8),
('ODIN: Valhalla Rising Diamonds','(EU+USD) Asgard 01','1K',4.50,1),
('ODIN: Valhalla Rising Diamonds','(EU+USD) Asgard 01','2K',9.00,2),
('ODIN: Valhalla Rising Diamonds','(EU+USD) Asgard 01','3K',13.50,3),
('ODIN: Valhalla Rising Diamonds','(EU+USD) Asgard 01','5K',22.50,4),
('ODIN: Valhalla Rising Diamonds','(EU+USD) Asgard 01','10K',45.00,5),
('ODIN: Valhalla Rising Diamonds','(EU+USD) Asgard 02','1K',4.50,1),
('ODIN: Valhalla Rising Diamonds','(EU+USD) Asgard 02','2K',9.00,2),
('ODIN: Valhalla Rising Diamonds','(EU+USD) Asgard 02','3K',13.50,3),
('ODIN: Valhalla Rising Diamonds','(EU+USD) Asgard 02','5K',22.50,4),
('ODIN: Valhalla Rising Diamonds','(EU+USD) Asgard 02','10K',45.00,5),
('ODIN: Valhalla Rising Diamonds','(EU+USD) Asgard 03','1K',4.50,1),
('ODIN: Valhalla Rising Diamonds','(EU+USD) Asgard 03','2K',9.00,2),
('ODIN: Valhalla Rising Diamonds','(EU+USD) Asgard 03','3K',13.50,3),
('ODIN: Valhalla Rising Diamonds','(EU+USD) Asgard 03','5K',22.50,4),
('ODIN: Valhalla Rising Diamonds','(EU+USD) Asgard 03','10K',45.00,5),
('ODIN: Valhalla Rising Diamonds','(EU+USD) Asgard 04','1K',4.50,1),
('ODIN: Valhalla Rising Diamonds','(EU+USD) Asgard 04','2K',9.00,2),
('ODIN: Valhalla Rising Diamonds','(EU+USD) Asgard 04','3K',13.50,3),
('ODIN: Valhalla Rising Diamonds','(EU+USD) Asgard 04','5K',22.50,4),
('ODIN: Valhalla Rising Diamonds','(EU+USD) Asgard 04','10K',45.00,5),
('ODIN: Valhalla Rising Diamonds','(EU+USD) Asgard 05','1K',4.50,1),
('ODIN: Valhalla Rising Diamonds','(EU+USD) Asgard 05','2K',9.00,2),
('ODIN: Valhalla Rising Diamonds','(EU+USD) Asgard 05','3K',13.50,3),
('ODIN: Valhalla Rising Diamonds','(EU+USD) Asgard 05','5K',22.50,4),
('ODIN: Valhalla Rising Diamonds','(EU+USD) Asgard 05','10K',45.00,5),
('ODIN: Valhalla Rising Diamonds','(EU+USD) Asgard 06','1K',4.50,1),
('ODIN: Valhalla Rising Diamonds','(EU+USD) Asgard 06','2K',9.00,2),
('ODIN: Valhalla Rising Diamonds','(EU+USD) Asgard 06','3K',13.50,3),
('ODIN: Valhalla Rising Diamonds','(EU+USD) Asgard 06','5K',22.50,4),
('ODIN: Valhalla Rising Diamonds','(EU+USD) Asgard 06','10K',45.00,5),
('ODIN: Valhalla Rising Diamonds','(EU+USD) Asgard 07','1K',4.50,1),
('ODIN: Valhalla Rising Diamonds','(EU+USD) Asgard 07','2K',9.00,2),
('ODIN: Valhalla Rising Diamonds','(EU+USD) Asgard 07','3K',13.50,3),
('ODIN: Valhalla Rising Diamonds','(EU+USD) Asgard 07','5K',22.50,4),
('ODIN: Valhalla Rising Diamonds','(EU+USD) Asgard 07','10K',45.00,5),
('ODIN: Valhalla Rising Diamonds','(EU+USD) Asgard 08','1K',4.50,1),
('ODIN: Valhalla Rising Diamonds','(EU+USD) Asgard 08','2K',9.00,2),
('ODIN: Valhalla Rising Diamonds','(EU+USD) Asgard 08','3K',13.50,3),
('ODIN: Valhalla Rising Diamonds','(EU+USD) Asgard 08','5K',22.50,4),
('ODIN: Valhalla Rising Diamonds','(EU+USD) Asgard 08','10K',45.00,5),
('ODIN: Valhalla Rising Diamonds','(EU+USD) Asgard 09','1K',4.50,1),
('ODIN: Valhalla Rising Diamonds','(EU+USD) Asgard 09','2K',9.00,2),
('ODIN: Valhalla Rising Diamonds','(EU+USD) Asgard 09','3K',13.50,3),
('ODIN: Valhalla Rising Diamonds','(EU+USD) Asgard 09','5K',22.50,4),
('ODIN: Valhalla Rising Diamonds','(EU+USD) Asgard 09','10K',45.00,5),
('Mir4','(ASIA)','1000G',4.00,1),
('Mir4','(ASIA)','2000G',8.00,2),
('Mir4','(ASIA)','5000G',20.00,3),
('Mir4','(ASIA)','10000G',40.00,4),
('Mir4','(EU)','1000G',4.00,1),
('Mir4','(EU)','2000G',8.00,2),
('Mir4','(EU)','5000G',20.00,3),
('Mir4','(EU)','10000G',40.00,4),
('Mir4','(NA)','1000G',4.00,1),
('Mir4','(NA)','2000G',8.00,2),
('Mir4','(NA)','5000G',20.00,3),
('Mir4','(NA)','10000G',40.00,4),
('Mir4','(SA)','1000G',4.00,1),
('Mir4','(SA)','2000G',8.00,2),
('Mir4','(SA)','5000G',20.00,3),
('Mir4','(SA)','10000G',40.00,4),
('Rubinot','Rubinicoin','1K',18.00,1),
('Tibia','Tibicoin','250TC',12.00,1),
('Path of Exile 1','MIRAGE SEASON NUEVA','300DV',4.50,1),
('Path of Exile 1','MIRAGE SEASON NUEVA','500DV',7.50,2),
('Path of Exile 1','MIRAGE SEASON NUEVA','1000DV',14.70,3),
('Path of Exile 2','Divine Orbs','100,000U',3.00,1),
('Path of Exile 2','Divine Orbs','200,000U',6.00,2),
('Path of Exile 2','Divine Orbs','300,000U',9.00,3),
('Throne and Liberty','Region Global Americas','2K',9.60,1),
('Throne and Liberty','Region Global Americas','5K',24.00,2),
('Throne and Liberty','Region Global Americas','10K',48.00,3),
('Throne and Liberty','Region Global Americas','20K',96.00,4),
('Torchlight Infinite','(USD) Season Lunaria','1000U',1.10,1),
('Torchlight Infinite','(USD) Season Lunaria','2000U',2.20,2),
('Torchlight Infinite','(USD) Season Lunaria','3000U',3.30,3),
('Torchlight Infinite','(USD) Season Lunaria','5000U',5.50,4),
('Torchlight Infinite','(USD) Season Lunaria','10000U',11.00,5),
('Torchlight Infinite','(EU) Season Lunaria','1000U',1.25,1),
('Torchlight Infinite','(EU) Season Lunaria','2000U',2.50,2),
('Torchlight Infinite','(EU) Season Lunaria','3000U',3.75,3),
('Torchlight Infinite','(EU) Season Lunaria','5000U',6.25,4),
('Torchlight Infinite','(EU) Season Lunaria','10000U',12.50,5),
('The Quinfall','Region (USD)','500M',10.20,1),
('The Quinfall','Region (USD)','1000M',20.40,2),
('The Quinfall','Region (USD)','2000M',40.80,3),
('The Quinfall','Region (USD)','5000M',102.00,4),
('The Quinfall','Region (USD)','10000M',204.00,5),
('The Quinfall','Region (EU)','500M',11.20,1),
('The Quinfall','Region (EU)','1000M',22.40,2),
('The Quinfall','Region (EU)','2000M',44.80,3),
('The Quinfall','Region (EU)','5000M',112.00,4),
('The Quinfall','Region (EU)','10000M',224.00,5),
('Lineage 2 (Reborn)','ORIGIN X1','50M',6.28,1),
('Lineage 2 (Reborn)','ORIGIN X1','100M',12.57,2),
('Lineage 2 (Reborn)','ORIGIN X1','300M',37.70,3),
('Lineage 2 (Reborn)','ORIGIN X1','500M',61.57,4),
('Lineage 2 (Reborn)','ORIGIN X1','1000M',123.14,5),
('Lineage 2 (Reborn)','ETERNAL X10 MAIN','500M',4.52,1),
('Lineage 2 (Reborn)','ETERNAL X10 MAIN','1000M',8.86,2),
('Lineage 2 (Reborn)','ETERNAL X10 MAIN','2000M',17.72,3),
('Lineage 2 (Reborn)','ETERNAL X10 MAIN','3000M',26.58,4),
('Lineage 2 (Reborn)','ETERNAL X10 MAIN','5000M',44.30,5),
('Lineage 2 (Reborn)','ETERNAL X10 NEW SEASON','500M',4.34,1),
('Lineage 2 (Reborn)','ETERNAL X10 NEW SEASON','1000M',8.52,2),
('Lineage 2 (Reborn)','ETERNAL X10 NEW SEASON','2000M',17.04,3),
('Lineage 2 (Reborn)','ETERNAL X10 NEW SEASON','3000M',25.56,4),
('Lineage 2 (Reborn)','ETERNAL X10 NEW SEASON','5000M',42.60,5),
('Lineage 2 (Reborn)','ORIGIN X5 NEW SEASON','30M',8.81,1),
('Lineage 2 (Reborn)','ORIGIN X5 NEW SEASON','50M',14.68,2),
('Lineage 2 (Reborn)','ORIGIN X5 NEW SEASON','100M',28.77,3),
('Lineage 2 (Reborn)','ORIGIN X5 NEW SEASON','200M',57.54,4),
('Lineage 2 (Reborn)','ORIGIN X5 NEW SEASON','300M',86.31,5),
('Lineage 2 (Reborn)','ORIGIN X5 NEW SEASON','500M',143.85,6),
('Warbone Above Ashes','America','2K',10.52,1),
('Warbone Above Ashes','America','3K',15.78,2),
('Warbone Above Ashes','America','5K',26.30,3),
('Warbone Above Ashes','America','10K',51.55,4),
('Warbone Above Ashes','Europa','2K',10.52,1),
('Warbone Above Ashes','Europa','3K',15.78,2),
('Warbone Above Ashes','Europa','5K',26.30,3),
('Warbone Above Ashes','Europa','10K',51.55,4)
on conflict (game, server, package_name) do update set
  price_usd = excluded.price_usd,
  sort_order = excluded.sort_order;

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
  image text not null default '',
  created_at timestamptz not null default now(),
  unique(game, name)
);


-- Compatibilidad para instalaciones previas (si la tabla ya existía sin columna image)
alter table public.gold_categories add column if not exists image text not null default '';

create unique index if not exists games_name_key on public.games (name);
create unique index if not exists gold_categories_game_name_key on public.gold_categories (game, name);

alter table public.games enable row level security;
alter table public.gold_categories enable row level security;

drop policy if exists "games_public_read" on public.games;
drop policy if exists "games_admin_write" on public.games;
drop policy if exists "games_authenticated_write" on public.games;
drop policy if exists "gold_categories_public_read" on public.gold_categories;
drop policy if exists "gold_categories_admin_write" on public.gold_categories;
drop policy if exists "gold_categories_authenticated_write" on public.gold_categories;

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

create policy "games_authenticated_write"
on public.games
for all
to authenticated
using (auth.uid() is not null)
with check (auth.uid() is not null);

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

create policy "gold_categories_authenticated_write"
on public.gold_categories
for all
to authenticated
using (auth.uid() is not null)
with check (auth.uid() is not null);

-- permisos explícitos para evitar bloqueos por grants faltantes
grant select on public.service_catalog_entries to anon;
grant select, insert, update, delete on public.service_catalog_entries to authenticated;

grant select on public.games to anon;
grant select, insert, update, delete on public.games to authenticated;

grant select on public.gold_categories to anon;
grant select, insert, update, delete on public.gold_categories to authenticated;
do $$
begin
  if to_regclass('public.service_catalog_entries_id_seq') is not null then
    execute 'grant usage, select on sequence public.service_catalog_entries_id_seq to authenticated';
  end if;
  if to_regclass('public.games_id_seq') is not null then
    execute 'grant usage, select on sequence public.games_id_seq to authenticated';
  end if;
  if to_regclass('public.gold_categories_id_seq') is not null then
    execute 'grant usage, select on sequence public.gold_categories_id_seq to authenticated';
  end if;
end $$;

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
('Lineage 2 (Reborn)','', 'ORIGIN / ETERNAL servers.', array['gold']),
('Warbone Above Ashes','', 'America / Europa.', array['gold'])
on conflict do nothing;

insert into public.gold_categories (game, name, description) values
('WARMANE', 'Warmane Gold', 'Onyxia / Lordaeron / Icecrown.'),
('Albion Online', 'Albion Silver', 'Compra/venta de plata en Albion Online.')
on conflict (game, name) do update
set description = excluded.description;

-- =========================
-- 8) SEED COMERCIAL
-- =========================
-- Catálogos P2P y Streaming ya quedan normalizados en la sección 5.

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
