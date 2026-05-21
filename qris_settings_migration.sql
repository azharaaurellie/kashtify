create table if not exists public.app_settings (
  key text primary key,
  value text,
  updated_by uuid references auth.users (id),
  updated_at timestamptz default now()
);

alter table public.app_settings enable row level security;

drop policy if exists "authenticated users can read app settings"
on public.app_settings;

create policy "authenticated users can read app settings"
on public.app_settings
for select
to authenticated
using (true);

drop policy if exists "bendahara can manage qris setting"
on public.app_settings;

create policy "bendahara can manage qris setting"
on public.app_settings
for all
to authenticated
using (
  exists (
    select 1
    from public.profiles
    where profiles.id = auth.uid()
      and profiles.role in ('bendahara', 'admin')
  )
)
with check (
  exists (
    select 1
    from public.profiles
    where profiles.id = auth.uid()
      and profiles.role in ('bendahara', 'admin')
  )
);

insert into public.app_settings (key, value)
values ('qris', null)
on conflict (key) do nothing;
