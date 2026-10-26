-- Run this whole script in Supabase > SQL Editor > New query.
create extension if not exists pgcrypto;

create table if not exists public.exam_results (
  id uuid primary key default gen_random_uuid(),
  student_name text not null,
  student_class text not null,
  student_code text,
  student_email text,
  score integer not null check (score >= 0),
  total integer not null check (total > 0),
  percentage integer not null check (percentage between 0 and 100),
  passed boolean not null default false,
  answers jsonb not null default '[]'::jsonb,
  mistakes jsonb not null default '[]'::jsonb,
  email_sent_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.admin_users (
  email text primary key,
  created_at timestamptz not null default now()
);

alter table public.exam_results enable row level security;
alter table public.admin_users enable row level security;

drop policy if exists "Anyone can submit exam results" on public.exam_results;
create policy "Anyone can submit exam results" on public.exam_results
  for insert to anon, authenticated with check (
    length(trim(student_name)) between 2 and 100 and
    length(trim(student_class)) between 1 and 40 and
    score between 0 and total and total = 30
  );

drop policy if exists "Admins can view exam results" on public.exam_results;
create policy "Admins can view exam results" on public.exam_results
  for select to authenticated using (
    exists (select 1 from public.admin_users a where lower(a.email) = lower(auth.jwt() ->> 'email'))
  );

drop policy if exists "Admins can read own admin entry" on public.admin_users;
create policy "Admins can read own admin entry" on public.admin_users
  for select to authenticated using (lower(email) = lower(auth.jwt() ->> 'email'));

grant insert on public.exam_results to anon, authenticated;
grant select on public.exam_results to authenticated;
grant select on public.admin_users to authenticated;

-- After creating your admin user in Authentication > Users, add the same email here:
-- insert into public.admin_users(email) values ('your-email@example.com') on conflict do nothing;
