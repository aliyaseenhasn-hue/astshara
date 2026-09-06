-- Native FCM device token persistence.
-- user_id references the application's public profile, not auth.users directly,
-- matching the existing client-side notification ownership model.

create table if not exists public.device_push_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  token text not null,
  platform text not null check (platform in ('android', 'ios')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint device_push_tokens_token_key unique (token)
);

create index if not exists idx_device_push_tokens_user_id
  on public.device_push_tokens(user_id);

create index if not exists idx_device_push_tokens_platform
  on public.device_push_tokens(platform);

alter table public.device_push_tokens enable row level security;

revoke all on table public.device_push_tokens from anon;
revoke all on table public.device_push_tokens from authenticated;

drop policy if exists device_push_tokens_select_own on public.device_push_tokens;
drop policy if exists device_push_tokens_insert_own on public.device_push_tokens;
drop policy if exists device_push_tokens_update_own on public.device_push_tokens;
drop policy if exists device_push_tokens_delete_own on public.device_push_tokens;

create policy device_push_tokens_select_own
  on public.device_push_tokens
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.profiles p
      where p.id = device_push_tokens.user_id
        and p.auth_id = (select auth.uid())
    )
  );

create policy device_push_tokens_insert_own
  on public.device_push_tokens
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.profiles p
      where p.id = device_push_tokens.user_id
        and p.auth_id = (select auth.uid())
    )
  );

create policy device_push_tokens_update_own
  on public.device_push_tokens
  for update
  to authenticated
  using (
    exists (
      select 1
      from public.profiles p
      where p.id = device_push_tokens.user_id
        and p.auth_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1
      from public.profiles p
      where p.id = device_push_tokens.user_id
        and p.auth_id = (select auth.uid())
    )
  );

create policy device_push_tokens_delete_own
  on public.device_push_tokens
  for delete
  to authenticated
  using (
    exists (
      select 1
      from public.profiles p
      where p.id = device_push_tokens.user_id
        and p.auth_id = (select auth.uid())
    )
  );

comment on table public.device_push_tokens is
  'FCM device tokens for native Android/iOS push delivery; service-role/server-side code may target tokens without exposing them to other users.';
