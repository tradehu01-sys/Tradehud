-- TradeHud patch: permitir cantidades alfanuméricas en paquetes de oro (ej: 10g, 1M)
-- Ejecutar en Supabase SQL Editor.

begin;

alter table if exists public.gold_catalog_entries
  alter column package_name type text using package_name::text;

alter table if exists public.gold_catalog_entries
  alter column package_name set not null;

commit;
