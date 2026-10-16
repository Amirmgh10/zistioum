-- زیستیوم: ذخیره آزمون‌ها و سؤال‌ها در Supabase
-- این فایل را یک بار در Supabase > SQL Editor اجرا کن.
create table if not exists public.zistium_exams (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  exam_date date,
  duration integer not null default 15,
  description text,
  status text not null default 'آماده',
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
create table if not exists public.zistium_questions (
  id uuid primary key default gen_random_uuid(),
  exam_id uuid not null references public.zistium_exams(id) on delete cascade,
  question_text text not null,
  options jsonb not null default '[]'::jsonb,
  position integer not null default 0
);
create table if not exists public.zistium_answer_keys (
  question_id uuid primary key references public.zistium_questions(id) on delete cascade,
  correct_answer integer not null check (correct_answer between 0 and 3)
);
alter table public.zistium_exams enable row level security;
alter table public.zistium_questions enable row level security;
alter table public.zistium_answer_keys enable row level security;
drop policy if exists "signed in can read zistium exams" on public.zistium_exams;
create policy "signed in can read zistium exams" on public.zistium_exams for select to authenticated using (true);
drop policy if exists "teachers create zistium exams" on public.zistium_exams;
create policy "teachers create zistium exams" on public.zistium_exams for insert to authenticated with check (
  created_by = auth.uid() and exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'teacher')
);
drop policy if exists "teachers delete own zistium exams" on public.zistium_exams;
create policy "teachers delete own zistium exams" on public.zistium_exams for delete to authenticated using (
  created_by = auth.uid() and exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'teacher')
);
drop policy if exists "signed in can read zistium questions" on public.zistium_questions;
create policy "signed in can read zistium questions" on public.zistium_questions for select to authenticated using (true);
drop policy if exists "teachers add zistium questions" on public.zistium_questions;
create policy "teachers add zistium questions" on public.zistium_questions for insert to authenticated with check (
  exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'teacher')
  and exists (select 1 from public.zistium_exams e where e.id = exam_id and e.created_by = auth.uid())
);
drop policy if exists "teachers read zistium answer keys" on public.zistium_answer_keys;
create policy "teachers read zistium answer keys" on public.zistium_answer_keys for select to authenticated using (
  exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'teacher')
);
drop policy if exists "teachers add zistium answer keys" on public.zistium_answer_keys;
create policy "teachers add zistium answer keys" on public.zistium_answer_keys for insert to authenticated with check (
  exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'teacher')
  and exists (
    select 1 from public.zistium_questions q join public.zistium_exams e on e.id = q.exam_id
    where q.id = question_id and e.created_by = auth.uid()
  )
);
grant select, insert, delete on public.zistium_exams to authenticated;
grant select, insert on public.zistium_questions to authenticated;
grant select, insert on public.zistium_answer_keys to authenticated;
