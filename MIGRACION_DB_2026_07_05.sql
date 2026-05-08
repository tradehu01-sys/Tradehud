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
