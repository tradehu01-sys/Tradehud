-- Ejecuta este script DIRECTAMENTE en Supabase SQL Editor.
-- Fecha: 2026-07-05

begin;

-- 1) Asegurar columna image en categorías de oro
alter table if exists public.gold_categories
  add column if not exists image text not null default '';

-- 2) Asegurar columna image en catálogo de servicios (por si faltara en algún entorno)
alter table if exists public.service_catalog_entries
  add column if not exists image text not null default '';

-- 3) Seed de categorías GiftCards (mismo flujo que streaming)
insert into public.service_catalog_entries (service_type, entry_type, category_name, item_name, image, value, sort_order)
values
  ('giftcards', 'category', 'Battle Net Gift Card', 'Battle Net Gift Card', '', '', 1),
  ('giftcards', 'category', 'Amazon Gift Card', 'Amazon Gift Card', '', '', 2),
  ('giftcards', 'category', 'Roblox Gift Cards', 'Roblox Gift Cards', '', '', 3),
  ('giftcards', 'category', 'PlayStation Gift Card', 'PlayStation Gift Card', '', '', 4),
  ('giftcards', 'category', 'Apple Gift Cards', 'Apple Gift Cards', '', '', 5),
  ('giftcards', 'category', 'Steam Gift Cards', 'Steam Gift Cards', '', '', 6),
  ('giftcards', 'category', 'Xbox Gift Cards', 'Xbox Gift Cards', '', '', 7),
  ('giftcards', 'category', 'Valorant Gift Cards', 'Valorant Gift Cards', '', '', 8),
  ('giftcards', 'category', 'Garena Free Fire Gift Cards', 'Garena Free Fire Gift Cards', '', '', 9),
  ('giftcards', 'category', 'Google Play Gift Cards', 'Google Play Gift Cards', '', '', 10)
on conflict do nothing;

-- p2p_categories_seed
insert into public.service_catalog_entries (service_type, entry_type, category_name, item_name, image, value, sort_order)
values
  ('p2p', 'category', 'ZINLI', 'ZINLI', '', '', 101),
  ('p2p', 'category', 'PAYPAL', 'PAYPAL', '', '', 102)
on conflict do nothing;

-- p2p_prices_seed
insert into public.service_catalog_entries (service_type, entry_type, category_name, item_name, image, value, sort_order)
values
  ('p2p','price','ZINLI','Zinli 1$','','ZINLI - Zinli 1$ - 1.30$',201),
  ('p2p','price','ZINLI','Zinli 2$','','ZINLI - Zinli 2$ - 2.60$',202),
  ('p2p','price','ZINLI','Zinli 5$','','ZINLI - Zinli 5$ - 6.50$',203),
  ('p2p','price','ZINLI','Zinli 10$','','ZINLI - Zinli 10$ - 12$',204),
  ('p2p','price','ZINLI','Zinli 15$','','ZINLI - Zinli 15$ - 17.25$',205),
  ('p2p','price','ZINLI','Zinli 20$','','ZINLI - Zinli 20$ - 23$',206),
  ('p2p','price','ZINLI','Zinli 25$','','ZINLI - Zinli 25$ - 28.75$',207),
  ('p2p','price','ZINLI','Zinli 30$','','ZINLI - Zinli 30$ - 34.50$',208),
  ('p2p','price','ZINLI','Zinli 40$','','ZINLI - Zinli 40$ - 46$',209),
  ('p2p','price','ZINLI','Zinli 50$','','ZINLI - Zinli 50$ - 57.50$',210),
  ('p2p','price','ZINLI','Zinli 100$','','ZINLI - Zinli 100$ - 115$',211),
  ('p2p','price','PAYPAL','Paypal 10$','','PAYPAL - Paypal 10$ - 12.50$',221),
  ('p2p','price','PAYPAL','Paypal 20$','','PAYPAL - Paypal 20$ - 24$',222),
  ('p2p','price','PAYPAL','Paypal 50$','','PAYPAL - Paypal 50$ - 60$',223),
  ('p2p','price','PAYPAL','Paypal 100$','','PAYPAL - Paypal 100$ - 120$',224),
  ('p2p','price','PAYPAL','Paypal 200$','','PAYPAL - Paypal 200$ - 240$',225),
  ('p2p','price','PAYPAL','Paypal 300$','','PAYPAL - Paypal 300$ - 360$',226)
on conflict do nothing;



-- giftcards_prices_seed
insert into public.service_catalog_entries (service_type, entry_type, category_name, item_name, image, value, sort_order)
select 'giftcards','price', c.category_name, 'PRECIO', '', v.price_text, v.sort_order
from (values
  ('10$ en 13$', 101),
  ('20$ en 26$', 102),
  ('30$ en 39$', 103),
  ('40$ en 52$', 104),
  ('50$ en 65$', 105),
  ('100$ en 130$', 106)
) as v(price_text, sort_order)
cross join (
  values
    ('Battle Net Gift Card'),
    ('Amazon Gift Card'),
    ('Roblox Gift Cards'),
    ('PlayStation Gift Card'),
    ('Apple Gift Cards'),
    ('Steam Gift Cards'),
    ('Xbox Gift Cards'),
    ('Valorant Gift Cards'),
    ('Garena Free Fire Gift Cards'),
    ('Google Play Gift Cards')
) as c(category_name)
on conflict do nothing;

commit;
