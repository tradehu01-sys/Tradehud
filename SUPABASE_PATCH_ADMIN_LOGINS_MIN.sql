create extension if not exists pgcrypto;

create table if not exists public.user_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text unique,
  name text,
  discord text,
  phone text,
  is_admin boolean not null default false,
  is_online boolean not null default false,
  last_seen timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.user_profiles enable row level security;

create or replace function public.is_ticket_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.user_profiles p
    where p.id = auth.uid()
      and p.is_admin = true
  );
$$;

insert into public.user_profiles (id, email, name, is_admin, is_online, last_seen)
select u.id, lower(u.email), 'Administrador TradeHud', true, false, now()
from auth.users u
where lower(u.email) in ('admin@tradehud.com', 'ajustes@tradehud.com')
on conflict (id) do update
set email = excluded.email,
    name = excluded.name,
    is_admin = true,
    updated_at = now();

update public.user_profiles
set email = lower(email)
where email is not null;

select id, email, is_admin
from public.user_profiles
where lower(email) in ('admin@tradehud.com', 'ajustes@tradehud.com')
order by email;
