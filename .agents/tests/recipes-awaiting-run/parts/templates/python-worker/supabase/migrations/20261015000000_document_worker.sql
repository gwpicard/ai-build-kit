create extension if not exists pgmq with schema pgmq;
select pgmq.create('document_jobs');

create table public.document_results (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  job_id bigint not null,
  text_content text not null,
  created_at timestamptz not null default now()
);

alter table public.document_results enable row level security;
create policy "People read their own document results"
  on public.document_results for select to authenticated
  using ((select auth.uid()) = owner_id);
create policy "People add their own document results"
  on public.document_results for insert to authenticated
  with check ((select auth.uid()) = owner_id);
