create table public.roles (
  user_id uuid primary key references auth.users (id) on delete cascade,
  role text not null default 'member' check (role in ('admin', 'member')),
  created_at timestamptz not null default now()
);

alter table public.roles enable row level security;

create policy "People can read their own role"
  on public.roles for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "Administrators can read all roles"
  on public.roles for select to authenticated
  using ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

create or replace function public.access_token_hook(event jsonb)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  claims jsonb;
  user_role text;
begin
  select role into user_role from public.roles where user_id = (event ->> 'user_id')::uuid;
  claims := event -> 'claims';
  if user_role is not null then
    claims := jsonb_set(claims, '{app_metadata,role}', to_jsonb(user_role), true);
  end if;
  return jsonb_set(event, '{claims}', claims);
end;
$$;

revoke execute on function public.access_token_hook(jsonb) from public, anon, authenticated;
grant execute on function public.access_token_hook(jsonb) to supabase_auth_admin;

grant usage on schema public to supabase_auth_admin;
grant select on table public.roles to supabase_auth_admin;
revoke all on table public.roles from anon;
grant select on table public.roles to anon, authenticated;
