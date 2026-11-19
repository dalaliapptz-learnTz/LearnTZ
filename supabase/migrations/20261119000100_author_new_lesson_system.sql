-- ============================================================================
-- LearnTZ — Production-Ready Curriculum-Driven Lesson Authoring System
-- Migration: 20261119000100_author_new_lesson_system.sql
--
-- Extends existing LearnTZ schema (no duplicate lesson/question/media tables):
--   1. RBAC roles & backend permission helpers (Author, Reviewer, Admin, Super Admin)
--   2. Normalized Main Competence & Specific Competence tables backed by official DB records
--   3. Extended public.lessons with full curriculum linkage, outcomes, activities & DB trigger validation
--   4. Controlled draft -> in_review -> revision_requested/approved -> published workflow & audit trail
--   5. Extended public.question_bank (8 question types, marks, outcome linkage)
--   6. Extended public.content_media_assets & private Supabase Storage bucket 'lesson-media'
--   7. Cascading dropdown RPCs, save/review/publish RPCs, and strict RLS enforcement
-- ============================================================================

begin;

-- ============================================================================
-- 1. RBAC Extensions & Permission Helpers
-- ============================================================================

alter table public.user_roles
  drop constraint if exists user_roles_role_check,
  add constraint user_roles_role_check check (role in (
    'super_admin', 'country_admin', 'content_admin',
    'finance_admin', 'support_admin', 'parent', 'learner',
    'curriculum_editor', 'curriculum_reviewer',
    'curriculum_approver', 'curriculum_admin',
    'content_author', 'academic_reviewer'
  ));

alter table public.user_roles
  drop constraint if exists user_roles_country_scope_check,
  add constraint user_roles_country_scope_check check (
    (role in (
      'country_admin', 'curriculum_editor', 'curriculum_reviewer',
      'curriculum_approver', 'curriculum_admin',
      'content_author', 'academic_reviewer'
    ) and country_code is not null)
    or (role not in (
      'country_admin', 'curriculum_editor', 'curriculum_reviewer',
      'curriculum_approver', 'curriculum_admin',
      'content_author', 'academic_reviewer'
    ))
  );

create or replace function public.can_author_lesson(p_country_code text default null)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    auth.uid() is not null
    and (
      public.has_role('super_admin')
      or public.has_role('content_admin', p_country_code)
      or public.has_role('curriculum_admin', p_country_code)
      or public.has_role('curriculum_editor', p_country_code)
      or public.has_role('content_author', p_country_code)
      or exists (
        select 1
        from public.admin_profiles ap
        join public.admin_user_roles aur on aur.admin_id = ap.id
        join public.admin_roles ar on ar.id = aur.role_id
        where ap.auth_user_id = auth.uid()
          and ap.account_status = 'ACTIVE'
          and aur.approval_status = 'APPROVED'
          and ar.role_name in ('SUPER_ADMIN', 'CONTENT_ADMIN', 'COUNTRY_ADMIN')
          and (
            ar.role_name = 'SUPER_ADMIN'
            or p_country_code is null
            or aur.country_code is null
            or upper(aur.country_code) = upper(p_country_code)
          )
      )
    );
$$;

create or replace function public.can_review_lesson(p_country_code text default null)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    auth.uid() is not null
    and (
      public.has_role('super_admin')
      or public.has_role('curriculum_admin', p_country_code)
      or public.has_role('curriculum_reviewer', p_country_code)
      or public.has_role('curriculum_approver', p_country_code)
      or public.has_role('academic_reviewer', p_country_code)
      or exists (
        select 1
        from public.admin_profiles ap
        join public.admin_user_roles aur on aur.admin_id = ap.id
        join public.admin_roles ar on ar.id = aur.role_id
        where ap.auth_user_id = auth.uid()
          and ap.account_status = 'ACTIVE'
          and aur.approval_status = 'APPROVED'
          and ar.role_name in ('SUPER_ADMIN', 'COUNTRY_ADMIN')
          and (
            ar.role_name = 'SUPER_ADMIN'
            or p_country_code is null
            or aur.country_code is null
            or upper(aur.country_code) = upper(p_country_code)
          )
      )
    );
$$;

create or replace function public.can_approve_lesson(p_country_code text default null)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    auth.uid() is not null
    and (
      public.has_role('super_admin')
      or public.has_role('curriculum_admin', p_country_code)
      or public.has_role('curriculum_approver', p_country_code)
      or public.has_role('academic_reviewer', p_country_code)
      or exists (
        select 1
        from public.admin_profiles ap
        join public.admin_user_roles aur on aur.admin_id = ap.id
        join public.admin_roles ar on ar.id = aur.role_id
        where ap.auth_user_id = auth.uid()
          and ap.account_status = 'ACTIVE'
          and aur.approval_status = 'APPROVED'
          and ar.role_name in ('SUPER_ADMIN', 'COUNTRY_ADMIN')
          and (
            ar.role_name = 'SUPER_ADMIN'
            or p_country_code is null
            or aur.country_code is null
            or upper(aur.country_code) = upper(p_country_code)
          )
      )
    );
$$;

create or replace function public.can_publish_lesson(p_country_code text default null)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    auth.uid() is not null
    and (
      public.has_role('super_admin')
      or public.has_role('curriculum_admin', p_country_code)
      or public.has_role('curriculum_approver', p_country_code)
      or exists (
        select 1
        from public.admin_profiles ap
        join public.admin_user_roles aur on aur.admin_id = ap.id
        join public.admin_roles ar on ar.id = aur.role_id
        where ap.auth_user_id = auth.uid()
          and ap.account_status = 'ACTIVE'
          and aur.approval_status = 'APPROVED'
          and ar.role_name in ('SUPER_ADMIN', 'COUNTRY_ADMIN')
          and (
            ar.role_name = 'SUPER_ADMIN'
            or p_country_code is null
            or aur.country_code is null
            or upper(aur.country_code) = upper(p_country_code)
          )
      )
    );
$$;

revoke all on function public.can_author_lesson(text) from public, anon;
revoke all on function public.can_review_lesson(text) from public, anon;
revoke all on function public.can_approve_lesson(text) from public, anon;
revoke all on function public.can_publish_lesson(text) from public, anon;
grant execute on function public.can_author_lesson(text) to authenticated, service_role;
grant execute on function public.can_review_lesson(text) to authenticated, service_role;
grant execute on function public.can_approve_lesson(text) to authenticated, service_role;
grant execute on function public.can_publish_lesson(text) to authenticated, service_role;

create or replace function public.get_lesson_authoring_capabilities(
  p_country_code text default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_country text := nullif(upper(btrim(coalesce(p_country_code, ''))), '');
begin
  if v_uid is null then
    return jsonb_build_object(
      'authenticated', false,
      'can_author', false,
      'can_review', false,
      'can_approve', false,
      'can_publish', false,
      'is_super_admin', false,
      'roles', '[]'::jsonb
    );
  end if;

  return jsonb_build_object(
    'authenticated', true,
    'can_author', public.can_author_lesson(v_country),
    'can_review', public.can_review_lesson(v_country),
    'can_approve', public.can_approve_lesson(v_country),
    'can_publish', public.can_publish_lesson(v_country),
    'is_super_admin', public.has_role('super_admin'),
    'roles', coalesce(
      (
        select jsonb_agg(distinct ur.role)
        from public.user_roles ur
        where ur.user_id = v_uid
          and (v_country is null or ur.country_code is null or upper(ur.country_code) = v_country)
      ),
      '[]'::jsonb
    )
  );
end;
$$;

revoke all on function public.get_lesson_authoring_capabilities(text) from public;
grant execute on function public.get_lesson_authoring_capabilities(text) to anon, authenticated, service_role;

-- ============================================================================
-- 2. Normalized Main Competence & Specific Competence Tables
--    Populated strictly from official existing DB records (never invented).
-- ============================================================================

create table if not exists public.curriculum_main_competences (
  id uuid primary key default gen_random_uuid(),
  subject_id uuid not null references public.subjects (id) on delete cascade,
  curriculum_version_id uuid references public.curriculum_versions (id) on delete set null,
  code text not null check (char_length(btrim(code)) between 1 and 40),
  title text not null check (char_length(btrim(title)) between 1 and 400),
  description text not null default '',
  display_order integer not null default 1 check (display_order > 0),
  is_published boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint curriculum_main_competences_subject_code_unique unique (subject_id, code),
  constraint curriculum_main_competences_id_subject_unique unique (id, subject_id)
);

create index if not exists curriculum_main_competences_subject_order_idx
  on public.curriculum_main_competences (subject_id, is_published, display_order);

drop trigger if exists curriculum_main_competences_set_updated_at on public.curriculum_main_competences;
create trigger curriculum_main_competences_set_updated_at
  before update on public.curriculum_main_competences
  for each row execute function public.set_updated_at();

create table if not exists public.curriculum_specific_competences (
  id uuid primary key default gen_random_uuid(),
  main_competence_id uuid not null,
  subject_id uuid not null,
  topic_id uuid unique references public.topics (id) on delete set null,
  code text not null check (char_length(btrim(code)) between 1 and 40),
  title text not null check (char_length(btrim(title)) between 1 and 500),
  description text not null default '',
  period_allocation integer check (period_allocation is null or period_allocation >= 0),
  assessment_criteria text,
  source_page integer check (source_page is null or source_page > 0),
  display_order integer not null default 1 check (display_order > 0),
  is_published boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint curriculum_specific_competences_main_fk
    foreign key (main_competence_id, subject_id)
    references public.curriculum_main_competences (id, subject_id)
    on delete cascade,
  constraint curriculum_specific_competences_main_code_unique unique (main_competence_id, code),
  constraint curriculum_specific_competences_scope_unique unique (id, main_competence_id, subject_id)
);

create index if not exists curriculum_specific_competences_main_order_idx
  on public.curriculum_specific_competences (main_competence_id, is_published, display_order);
create index if not exists curriculum_specific_competences_subject_idx
  on public.curriculum_specific_competences (subject_id, topic_id);

drop trigger if exists curriculum_specific_competences_set_updated_at on public.curriculum_specific_competences;
create trigger curriculum_specific_competences_set_updated_at
  before update on public.curriculum_specific_competences
  for each row execute function public.set_updated_at();

alter table public.curriculum_main_competences enable row level security;
alter table public.curriculum_specific_competences enable row level security;

revoke all on public.curriculum_main_competences, public.curriculum_specific_competences
  from public, anon, authenticated;
grant select on public.curriculum_main_competences, public.curriculum_specific_competences
  to anon, authenticated;
grant insert, update, delete on public.curriculum_main_competences, public.curriculum_specific_competences
  to authenticated;

drop policy if exists "Anyone reads published main competences" on public.curriculum_main_competences;
create policy "Anyone reads published main competences"
  on public.curriculum_main_competences for select to anon, authenticated
  using (
    is_published
    or exists (
      select 1 from public.subjects s
      where s.id = curriculum_main_competences.subject_id
        and (public.can_author_lesson(s.country_code) or public.can_review_lesson(s.country_code))
    )
  );

drop policy if exists "Curriculum admins manage main competences" on public.curriculum_main_competences;
create policy "Curriculum admins manage main competences"
  on public.curriculum_main_competences for all to authenticated
  using (
    exists (
      select 1 from public.subjects s
      where s.id = curriculum_main_competences.subject_id
        and public.can_publish_lesson(s.country_code)
    )
  )
  with check (
    exists (
      select 1 from public.subjects s
      where s.id = curriculum_main_competences.subject_id
        and public.can_publish_lesson(s.country_code)
    )
  );

drop policy if exists "Anyone reads published specific competences" on public.curriculum_specific_competences;
create policy "Anyone reads published specific competences"
  on public.curriculum_specific_competences for select to anon, authenticated
  using (
    is_published
    or exists (
      select 1 from public.subjects s
      where s.id = curriculum_specific_competences.subject_id
        and (public.can_author_lesson(s.country_code) or public.can_review_lesson(s.country_code))
    )
  );

drop policy if exists "Curriculum admins manage specific competences" on public.curriculum_specific_competences;
create policy "Curriculum admins manage specific competences"
  on public.curriculum_specific_competences for all to authenticated
  using (
    exists (
      select 1 from public.subjects s
      where s.id = curriculum_specific_competences.subject_id
        and public.can_publish_lesson(s.country_code)
    )
  )
  with check (
    exists (
      select 1 from public.subjects s
      where s.id = curriculum_specific_competences.subject_id
        and public.can_publish_lesson(s.country_code)
    )
  );

-- Backfill official Main & Specific Competences directly from existing verified public.topics
-- Strictly preserves exact official wording from TIE syllabus topics; never invents competences.
do $$
declare
  v_topic record;
  v_match text[];
  v_main_code text;
  v_main_title text;
  v_main_order integer;
  v_main_id uuid;
  v_version_id uuid;
begin
  for v_topic in
    select
      t.id as topic_id,
      t.subject_id,
      t.title,
      t.summary,
      t.competency_code,
      t.period_allocation,
      t.assessment_criteria,
      t.source_page,
      t.display_order,
      t.is_published,
      s.curriculum_id
    from public.topics t
    join public.subjects s on s.id = t.subject_id
    where t.competency_code is not null
      and btrim(t.competency_code) <> ''
    order by t.subject_id, t.display_order, t.created_at
  loop
    select cv.id into v_version_id
    from public.curriculum_versions cv
    where cv.curriculum_id = v_topic.curriculum_id
    order by
      case cv.status when 'published' then 1 when 'approved' then 2 else 3 end,
      cv.created_at desc
    limit 1;

    -- Extract official "Main Competence X.0: <Official Title>." pattern when present
    v_match := regexp_match(
      coalesce(v_topic.summary, ''),
      'Main Competence\s+([0-9]+(?:\.[0-9]+)?)\s*:\s*([^\.]+)'
    );

    if v_match is not null then
      v_main_code := btrim(v_match[1]);
      v_main_title := btrim(v_match[2]);
      v_main_order := greatest(1, coalesce(nullif(split_part(v_main_code, '.', 1), '')::integer, v_topic.display_order));
    else
      -- Topic itself carries a primary competency_code (e.g., Foundational Std I-II 1.0, 2.0, etc.)
      v_main_code := btrim(v_topic.competency_code);
      if exists (
        select 1 from public.curriculum_main_competences cmc
        where cmc.subject_id = v_topic.subject_id
          and cmc.code = v_main_code
          and cmc.title <> btrim(v_topic.title)
      ) then
        v_main_code := btrim(v_topic.competency_code) || '.' || v_topic.display_order::text;
      end if;
      v_main_title := btrim(v_topic.title);
      v_main_order := greatest(1, v_topic.display_order);
    end if;

    insert into public.curriculum_main_competences (
      subject_id,
      curriculum_version_id,
      code,
      title,
      description,
      display_order,
      is_published
    ) values (
      v_topic.subject_id,
      v_version_id,
      v_main_code,
      v_main_title,
      coalesce(v_topic.summary, ''),
      v_main_order,
      v_topic.is_published
    )
    on conflict (subject_id, code) do update
      set title = excluded.title,
          curriculum_version_id = coalesce(curriculum_main_competences.curriculum_version_id, excluded.curriculum_version_id),
          is_published = excluded.is_published
    returning id into v_main_id;

    insert into public.curriculum_specific_competences (
      main_competence_id,
      subject_id,
      topic_id,
      code,
      title,
      description,
      period_allocation,
      assessment_criteria,
      source_page,
      display_order,
      is_published
    ) values (
      v_main_id,
      v_topic.subject_id,
      v_topic.topic_id,
      btrim(v_topic.competency_code),
      btrim(v_topic.title),
      coalesce(v_topic.summary, ''),
      v_topic.period_allocation,
      v_topic.assessment_criteria,
      v_topic.source_page,
      greatest(1, v_topic.display_order),
      v_topic.is_published
    )
    on conflict (topic_id) do update
      set main_competence_id = excluded.main_competence_id,
          code = excluded.code,
          title = excluded.title,
          description = excluded.description,
          period_allocation = excluded.period_allocation,
          assessment_criteria = excluded.assessment_criteria,
          source_page = excluded.source_page,
          display_order = excluded.display_order,
          is_published = excluded.is_published;
  end loop;
end $$;

-- ============================================================================
-- 3. Extend public.lessons with Full Curriculum Linkage & Authoring Structure
-- ============================================================================

alter table public.lessons
  add column if not exists country_code text references public.countries (country_code) on delete restrict,
  add column if not exists curriculum_id uuid references public.curricula (id) on delete restrict,
  add column if not exists curriculum_version_id uuid references public.curriculum_versions (id) on delete restrict,
  add column if not exists education_level_id uuid references public.education_levels (id) on delete restrict,
  add column if not exists grade_id uuid references public.education_grades (id) on delete restrict,
  add column if not exists subject_id uuid references public.subjects (id) on delete restrict,
  add column if not exists main_competence_id uuid references public.curriculum_main_competences (id) on delete restrict,
  add column if not exists specific_competence_id uuid references public.curriculum_specific_competences (id) on delete restrict,
  add column if not exists subtopic_id uuid references public.subtopics (id) on delete set null,
  add column if not exists language_code text not null default 'en'
    check (language_code ~ '^[a-z]{2,3}(-[A-Za-z0-9]{2,8})*$'),
  add column if not exists difficulty_level text not null default 'standard'
    check (difficulty_level in ('foundational', 'standard', 'intermediate', 'advanced')),
  add column if not exists lesson_type text not null default 'core_instruction'
    check (lesson_type in ('core_instruction', 'guided_practice', 'revision', 'practical', 'assessment_prep', 'enrichment')),
  add column if not exists learning_objectives jsonb not null default '[]'::jsonb
    check (jsonb_typeof(learning_objectives) = 'array'),
  add column if not exists learning_outcomes jsonb not null default '[]'::jsonb
    check (jsonb_typeof(learning_outcomes) = 'array'),
  add column if not exists teaching_activities jsonb not null default '[]'::jsonb
    check (jsonb_typeof(teaching_activities) = 'array'),
  add column if not exists assessment_criteria text,
  add column if not exists submitted_at timestamptz,
  add column if not exists approved_by uuid references auth.users (id) on delete set null,
  add column if not exists approved_at timestamptz,
  add column if not exists published_by uuid references auth.users (id) on delete set null;

-- Update status check to include 'revision_requested'
do $$
declare
  v_conname text;
begin
  for v_conname in
    select conname
    from pg_constraint
    where conrelid = 'public.lessons'::regclass
      and contype = 'c'
      and pg_get_constraintdef(oid) ilike '%status%'
      and conname <> 'lessons_publish_state_check'
  loop
    execute format('alter table public.lessons drop constraint if exists %I', v_conname);
  end loop;
end $$;

alter table public.lessons
  add constraint lessons_status_check
    check (status in ('draft', 'in_review', 'revision_requested', 'approved', 'published', 'archived'));

-- Synchronize any pre-existing rows before adding publish guard
update public.lessons
set status = 'published',
    published_at = coalesce(published_at, updated_at)
where is_published = true and status <> 'published';

update public.lessons
set is_published = false
where status <> 'published' and is_published = true;

alter table public.lessons
  drop constraint if exists lessons_publish_state_check,
  add constraint lessons_publish_state_check
    check (
      (status = 'published' and is_published = true)
      or (status <> 'published' and is_published = false)
    );

-- Backfill curriculum hierarchy columns on existing lessons from topic -> subject
update public.lessons l
set
  country_code = coalesce(l.country_code, s.country_code),
  curriculum_id = coalesce(l.curriculum_id, s.curriculum_id),
  education_level_id = coalesce(l.education_level_id, s.education_level_id),
  grade_id = coalesce(l.grade_id, s.grade_id),
  subject_id = coalesce(l.subject_id, s.id),
  specific_competence_id = coalesce(l.specific_competence_id, sc.id),
  main_competence_id = coalesce(l.main_competence_id, sc.main_competence_id)
from public.topics t
join public.subjects s on s.id = t.subject_id
left join public.curriculum_specific_competences sc on sc.topic_id = t.id
where l.topic_id = t.id;

create index if not exists lessons_curriculum_scope_idx
  on public.lessons (country_code, curriculum_id, grade_id, subject_id, status);
create index if not exists lessons_competence_idx
  on public.lessons (main_competence_id, specific_competence_id)
  where specific_competence_id is not null;
create index if not exists lessons_author_status_idx
  on public.lessons (author_id, status, updated_at desc)
  where author_id is not null;

-- Backend Curriculum Alignment Validation Trigger (cannot be bypassed)
create or replace function public.validate_lesson_curriculum_alignment()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_topic record;
  v_subject record;
  v_grade record;
  v_version record;
  v_main record;
  v_spec record;
  v_subtopic record;
begin
  -- Enforce publish flag invariant
  if new.status = 'published' and not new.is_published then
    raise exception 'Published lessons must have is_published = true' using errcode = '23514';
  end if;
  if new.status <> 'published' and new.is_published then
    raise exception 'Draft, in-review, revision-requested, approved, or archived lessons cannot have is_published = true'
      using errcode = '23514';
  end if;

  -- Resolve topic & derive subject if omitted
  select id, subject_id into v_topic
  from public.topics
  where id = new.topic_id;

  if not found then
    raise exception 'Curriculum alignment error: topic % does not exist', new.topic_id
      using errcode = '23503';
  end if;

  if new.subject_id is null then
    new.subject_id := v_topic.subject_id;
  elsif new.subject_id <> v_topic.subject_id then
    raise exception 'Curriculum alignment error: topic % does not belong to subject %', new.topic_id, new.subject_id
      using errcode = '23514';
  end if;

  -- Resolve subject & validate country/curriculum/level/grade
  select id, country_code, curriculum_id, education_level_id, grade_id
  into v_subject
  from public.subjects
  where id = new.subject_id;

  if not found then
    raise exception 'Curriculum alignment error: subject % does not exist', new.subject_id
      using errcode = '23503';
  end if;

  if new.country_code is null then
    new.country_code := v_subject.country_code;
  elsif upper(new.country_code) <> upper(v_subject.country_code) then
    raise exception 'Curriculum alignment error: subject % belongs to country %, not %',
      new.subject_id, v_subject.country_code, new.country_code
      using errcode = '23514';
  end if;

  if new.curriculum_id is null then
    new.curriculum_id := v_subject.curriculum_id;
  elsif new.curriculum_id <> v_subject.curriculum_id then
    raise exception 'Curriculum alignment error: subject % belongs to curriculum %, not %',
      new.subject_id, v_subject.curriculum_id, new.curriculum_id
      using errcode = '23514';
  end if;

  if new.education_level_id is null then
    new.education_level_id := v_subject.education_level_id;
  elsif new.education_level_id <> v_subject.education_level_id then
    raise exception 'Curriculum alignment error: subject % belongs to education level %, not %',
      new.subject_id, v_subject.education_level_id, new.education_level_id
      using errcode = '23514';
  end if;

  -- Validate grade belongs to curriculum & education level and matches grade-scoped subject
  if new.grade_id is null then
    new.grade_id := v_subject.grade_id;
  end if;

  if new.grade_id is not null then
    select id, curriculum_id, education_level_id into v_grade
    from public.education_grades
    where id = new.grade_id;

    if not found then
      raise exception 'Curriculum alignment error: grade % does not exist', new.grade_id
        using errcode = '23503';
    end if;

    if v_grade.curriculum_id <> new.curriculum_id or v_grade.education_level_id <> new.education_level_id then
      raise exception 'Curriculum alignment error: grade % does not belong to curriculum % and education level %',
        new.grade_id, new.curriculum_id, new.education_level_id
        using errcode = '23514';
    end if;

    if v_subject.grade_id is not null and v_subject.grade_id <> new.grade_id then
      raise exception 'Curriculum alignment error: subject % is scoped to grade %, not grade %',
        new.subject_id, v_subject.grade_id, new.grade_id
        using errcode = '23514';
    end if;
  end if;

  -- Validate curriculum version belongs to curriculum
  if new.curriculum_version_id is not null then
    select id, curriculum_id into v_version
    from public.curriculum_versions
    where id = new.curriculum_version_id;

    if not found then
      raise exception 'Curriculum alignment error: curriculum version % does not exist', new.curriculum_version_id
        using errcode = '23503';
    end if;

    if v_version.curriculum_id <> new.curriculum_id then
      raise exception 'Curriculum alignment error: curriculum version % does not belong to curriculum %',
        new.curriculum_version_id, new.curriculum_id
        using errcode = '23514';
    end if;
  end if;

  -- Validate main competence belongs to subject
  if new.main_competence_id is not null then
    select id, subject_id into v_main
    from public.curriculum_main_competences
    where id = new.main_competence_id;

    if not found then
      raise exception 'Curriculum alignment error: main competence % does not exist', new.main_competence_id
        using errcode = '23503';
    end if;

    if v_main.subject_id <> new.subject_id then
      raise exception 'Curriculum alignment error: main competence % does not belong to subject %',
        new.main_competence_id, new.subject_id
        using errcode = '23514';
    end if;
  end if;

  -- Validate specific competence belongs to main competence, subject, and topic
  if new.specific_competence_id is not null then
    select id, main_competence_id, subject_id, topic_id into v_spec
    from public.curriculum_specific_competences
    where id = new.specific_competence_id;

    if not found then
      raise exception 'Curriculum alignment error: specific competence % does not exist', new.specific_competence_id
        using errcode = '23503';
    end if;

    if v_spec.subject_id <> new.subject_id then
      raise exception 'Curriculum alignment error: specific competence % does not belong to subject %',
        new.specific_competence_id, new.subject_id
        using errcode = '23514';
    end if;

    if new.main_competence_id is null then
      new.main_competence_id := v_spec.main_competence_id;
    elsif v_spec.main_competence_id <> new.main_competence_id then
      raise exception 'Curriculum alignment error: specific competence % does not belong to main competence %',
        new.specific_competence_id, new.main_competence_id
        using errcode = '23514';
    end if;

    if v_spec.topic_id is not null and v_spec.topic_id <> new.topic_id then
      raise exception 'Curriculum alignment error: specific competence % is linked to topic %, not topic %',
        new.specific_competence_id, v_spec.topic_id, new.topic_id
        using errcode = '23514';
    end if;
  end if;

  -- Validate subtopic belongs to topic if specified
  if new.subtopic_id is not null then
    select id, topic_id into v_subtopic
    from public.subtopics
    where id = new.subtopic_id;

    if not found then
      raise exception 'Curriculum alignment error: subtopic % does not exist', new.subtopic_id
        using errcode = '23503';
    end if;

    if v_subtopic.topic_id <> new.topic_id then
      raise exception 'Curriculum alignment error: subtopic % does not belong to topic %',
        new.subtopic_id, new.topic_id
        using errcode = '23514';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists lessons_validate_curriculum_alignment on public.lessons;
create trigger lessons_validate_curriculum_alignment
  before insert or update on public.lessons
  for each row execute function public.validate_lesson_curriculum_alignment();

-- ============================================================================
-- 4. Extend lesson_revisions & Create lesson_review_events (Version & Audit History)
-- ============================================================================

alter table public.lesson_revisions
  add column if not exists status text not null default 'draft',
  add column if not exists difficulty_level text default 'standard',
  add column if not exists lesson_type text default 'core_instruction',
  add column if not exists language_code text default 'en',
  add column if not exists estimated_minutes integer default 10,
  add column if not exists learning_objectives jsonb not null default '[]'::jsonb,
  add column if not exists learning_outcomes jsonb not null default '[]'::jsonb,
  add column if not exists teaching_activities jsonb not null default '[]'::jsonb,
  add column if not exists curriculum_snapshot jsonb not null default '{}'::jsonb;

create table if not exists public.lesson_review_events (
  id uuid primary key default gen_random_uuid(),
  lesson_id uuid not null references public.lessons (id) on delete cascade,
  actor_user_id uuid references auth.users (id) on delete set null,
  action text not null check (action in (
    'draft_saved', 'submitted_for_review', 'revision_requested',
    'approved', 'published', 'archived', 'reopened_draft'
  )),
  from_status text,
  to_status text not null,
  version_number integer not null default 1 check (version_number > 0),
  comments text,
  created_at timestamptz not null default now()
);

create index if not exists lesson_review_events_lesson_idx
  on public.lesson_review_events (lesson_id, created_at desc);

alter table public.lesson_review_events enable row level security;
revoke all on public.lesson_review_events from public, anon, authenticated;
grant select, insert on public.lesson_review_events to authenticated;

drop policy if exists "Staff can view lesson review events" on public.lesson_review_events;
create policy "Staff can view lesson review events"
  on public.lesson_review_events for select to authenticated
  using (
    exists (
      select 1
      from public.lessons l
      join public.topics t on t.id = l.topic_id
      join public.subjects s on s.id = t.subject_id
      where l.id = lesson_review_events.lesson_id
        and (
          l.author_id = auth.uid()
          or public.can_author_lesson(s.country_code)
          or public.can_review_lesson(s.country_code)
          or public.can_publish_lesson(s.country_code)
        )
    )
  );

drop policy if exists "Staff can record lesson review events" on public.lesson_review_events;
create policy "Staff can record lesson review events"
  on public.lesson_review_events for insert to authenticated
  with check (
    exists (
      select 1
      from public.lessons l
      join public.topics t on t.id = l.topic_id
      join public.subjects s on s.id = t.subject_id
      where l.id = lesson_review_events.lesson_id
        and (
          public.can_author_lesson(s.country_code)
          or public.can_review_lesson(s.country_code)
          or public.can_publish_lesson(s.country_code)
        )
    )
  );

-- Update lesson_revisions RLS so authors and reviewers can view history in scope
drop policy if exists "Staff can view lesson revisions" on public.lesson_revisions;
create policy "Staff can view lesson revisions"
  on public.lesson_revisions for select to authenticated
  using (
    exists (
      select 1 from public.lessons l
      join public.topics t on l.topic_id = t.id
      join public.subjects s on t.subject_id = s.id
      where l.id = lesson_id
        and (
          l.author_id = auth.uid()
          or public.can_author_lesson(s.country_code)
          or public.can_review_lesson(s.country_code)
          or public.can_publish_lesson(s.country_code)
        )
    )
  );

drop policy if exists "Staff can record lesson revisions" on public.lesson_revisions;
create policy "Staff can record lesson revisions"
  on public.lesson_revisions for insert to authenticated
  with check (
    exists (
      select 1 from public.lessons l
      join public.topics t on l.topic_id = t.id
      join public.subjects s on t.subject_id = s.id
      where l.id = lesson_id
        and (
          public.can_author_lesson(s.country_code)
          or public.can_publish_lesson(s.country_code)
        )
    )
  );

-- Harden lessons RLS & learner visibility: unpublished drafts are NEVER visible to learners
create or replace function public.can_access_learning_lesson(p_lesson_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.lessons l
    join public.topics t on t.id = l.topic_id
    join public.subjects s on s.id = t.subject_id
    where l.id = p_lesson_id
      and (
        (
          l.is_published = true
          and l.status = 'published'
          and t.is_published = true
          and s.is_published = true
          and (l.is_free_preview or public.has_active_parent_subscription(auth.uid()))
        )
        or (l.author_id = auth.uid() and public.can_author_lesson(s.country_code))
        or public.can_review_lesson(s.country_code)
        or public.can_publish_lesson(s.country_code)
        or public.has_role('content_admin', s.country_code)
      )
  );
$$;

drop policy if exists "Content admins manage lessons" on public.lessons;
drop policy if exists "Authors manage own unpublished lessons" on public.lessons;
drop policy if exists "Publishers manage lessons" on public.lessons;

create policy "Authors manage own unpublished lessons"
  on public.lessons for all to authenticated
  using (
    status in ('draft', 'revision_requested')
    and is_published = false
    and (author_id = auth.uid() or author_id is null)
    and exists (
      select 1
      from public.topics t
      join public.subjects s on s.id = t.subject_id
      where t.id = lessons.topic_id
        and public.can_author_lesson(s.country_code)
    )
  )
  with check (
    status in ('draft', 'in_review')
    and is_published = false
    and (author_id = auth.uid() or author_id is null)
    and exists (
      select 1
      from public.topics t
      join public.subjects s on s.id = t.subject_id
      where t.id = lessons.topic_id
        and public.can_author_lesson(s.country_code)
    )
  );

create policy "Publishers manage lessons"
  on public.lessons for all to authenticated
  using (
    exists (
      select 1
      from public.topics t
      join public.subjects s on s.id = t.subject_id
      where t.id = lessons.topic_id
        and public.can_publish_lesson(s.country_code)
    )
  )
  with check (
    exists (
      select 1
      from public.topics t
      join public.subjects s on s.id = t.subject_id
      where t.id = lessons.topic_id
        and public.can_publish_lesson(s.country_code)
    )
  );

-- ============================================================================
-- 5. Extend public.question_bank (All 8 Required Assessment Types + Outcomes)
-- ============================================================================

do $$
declare
  v_conname text;
begin
  for v_conname in
    select conname
    from pg_constraint
    where conrelid = 'public.question_bank'::regclass
      and contype = 'c'
      and pg_get_constraintdef(oid) ilike '%question_type%'
  loop
    execute format('alter table public.question_bank drop constraint if exists %I', v_conname);
  end loop;
end $$;

alter table public.question_bank
  add constraint question_bank_question_type_check check (
    question_type in (
      'multiple_choice',
      'true_false',
      'short_answer',
      'matching',
      'fill_in_the_blank',
      'listening',
      'oral_response',
      'practical_task'
    )
  ),
  add column if not exists marks numeric(5, 2) not null default 1.00
    check (marks > 0 and marks <= 100),
  add column if not exists learning_outcome_ref text,
  add column if not exists assessment_criteria text,
  add column if not exists media_asset_id uuid references public.content_media_assets (id) on delete set null,
  add column if not exists author_id uuid references auth.users (id) on delete set null;

drop policy if exists "Content admins manage question bank" on public.question_bank;
create policy "Authorized content staff manage question bank"
  on public.question_bank for all to authenticated
  using (
    public.can_author_lesson(question_bank.country_code)
    or public.can_review_lesson(question_bank.country_code)
    or public.can_publish_lesson(question_bank.country_code)
  )
  with check (
    public.can_author_lesson(question_bank.country_code)
    or public.can_publish_lesson(question_bank.country_code)
  );

-- ============================================================================
-- 6. Extend public.content_media_assets & Configure 'lesson-media' Bucket
-- ============================================================================

do $$
declare
  v_conname text;
begin
  for v_conname in
    select conname
    from pg_constraint
    where conrelid = 'public.content_media_assets'::regclass
      and contype = 'c'
      and pg_get_constraintdef(oid) ilike '%media_type%'
  loop
    execute format('alter table public.content_media_assets drop constraint if exists %I', v_conname);
  end loop;
end $$;

alter table public.content_media_assets
  add constraint content_media_assets_media_type_check
    check (media_type in ('image', 'audio', 'video', 'document', 'diagram', 'illustration')),
  add column if not exists description text,
  add column if not exists storage_bucket text,
  add column if not exists storage_object_path text,
  add column if not exists mime_type text,
  add column if not exists source_reference text,
  add column if not exists license_type text not null default 'unverified'
    check (license_type in (
      'unverified', 'original_learntz', 'creative_commons',
      'public_domain', 'licensed_third_party', 'restricted'
    )),
  add column if not exists copyright_cleared boolean not null default false,
  add column if not exists attribution text,
  add column if not exists transcript text,
  add column if not exists review_status text not null default 'pending_review'
    check (review_status in ('pending_review', 'approved', 'rejected')),
  add column if not exists reviewed_by uuid references auth.users (id) on delete set null,
  add column if not exists reviewed_at timestamptz;

drop policy if exists "Staff can upload media assets" on public.content_media_assets;
create policy "Staff can upload media assets"
  on public.content_media_assets for insert to authenticated
  with check (
    public.can_author_lesson(country_code)
    or public.can_publish_lesson(country_code)
  );

drop policy if exists "Reviewers can update media assets" on public.content_media_assets;
create policy "Reviewers can update media assets"
  on public.content_media_assets for update to authenticated
  using (
    public.can_review_lesson(country_code)
    or public.can_publish_lesson(country_code)
    or (uploaded_by_user_id = auth.uid() and review_status = 'pending_review')
  )
  with check (
    public.can_review_lesson(country_code)
    or public.can_publish_lesson(country_code)
    or (uploaded_by_user_id = auth.uid() and review_status = 'pending_review' and copyright_cleared = false)
  );

grant update on public.content_media_assets to authenticated;

-- Private storage bucket for lesson multimedia (25 MB limit, mobile/low-bandwidth friendly MIME types)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'lesson-media',
  'lesson-media',
  false,
  26214400,
  array[
    'image/png',
    'image/jpeg',
    'image/webp',
    'image/svg+xml',
    'audio/mpeg',
    'audio/mp4',
    'audio/ogg',
    'audio/wav',
    'audio/webm',
    'video/mp4',
    'video/webm',
    'application/pdf'
  ]
)
on conflict (id) do update
set public = false,
    file_size_limit = 26214400,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Authenticated users read lesson-media objects" on storage.objects;
create policy "Authenticated users read lesson-media objects"
  on storage.objects for select to authenticated
  using (bucket_id = 'lesson-media');

drop policy if exists "Authorized authors upload lesson-media objects" on storage.objects;
create policy "Authorized authors upload lesson-media objects"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'lesson-media'
    and (
      public.can_author_lesson(null)
      or public.can_publish_lesson(null)
    )
  );

drop policy if exists "Authorized authors manage own lesson-media objects" on storage.objects;
create policy "Authorized authors manage own lesson-media objects"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'lesson-media'
    and (
      public.can_publish_lesson(null)
      or (owner = auth.uid() and public.can_author_lesson(null))
    )
  );

-- ============================================================================
-- 7. Cascading Dropdown & Context RPCs (100% Real DB Records)
-- ============================================================================

create or replace function public.get_lesson_authoring_context(
  p_country_code text default null,
  p_curriculum_id uuid default null,
  p_education_level_id uuid default null,
  p_grade_id uuid default null,
  p_subject_id uuid default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_country text := nullif(upper(btrim(coalesce(p_country_code, ''))), '');
  v_curriculum record;
  v_version record;
  v_level record;
  v_grade record;
  v_subject record;
  v_country_row record;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  -- If subject_id is given, derive parent hierarchy from subject
  if p_subject_id is not null then
    select s.id, s.country_code, s.curriculum_id, s.education_level_id, s.grade_id, s.name, s.code, s.official_name, s.language
    into v_subject
    from public.subjects s
    where s.id = p_subject_id;

    if found then
      v_country := v_subject.country_code;
      p_curriculum_id := coalesce(p_curriculum_id, v_subject.curriculum_id);
      p_education_level_id := coalesce(p_education_level_id, v_subject.education_level_id);
      p_grade_id := coalesce(p_grade_id, v_subject.grade_id);
    end if;
  end if;

  -- If grade_id is given, derive level & curriculum
  if p_grade_id is not null then
    select eg.id, eg.education_level_id, eg.curriculum_id, eg.name, eg.code, eg.sequence
    into v_grade
    from public.education_grades eg
    where eg.id = p_grade_id;

    if found then
      p_education_level_id := coalesce(p_education_level_id, v_grade.education_level_id);
      p_curriculum_id := coalesce(p_curriculum_id, v_grade.curriculum_id);
    end if;
  end if;

  -- If education_level_id is given, derive curriculum
  if p_education_level_id is not null then
    select el.id, el.curriculum_id, el.name, el.code, el.sequence
    into v_level
    from public.education_levels el
    where el.id = p_education_level_id;

    if found then
      p_curriculum_id := coalesce(p_curriculum_id, v_level.curriculum_id);
    end if;
  end if;

  -- Resolve curriculum
  if p_curriculum_id is not null then
    select c.id, c.country_code, c.name, c.code, ca.name as authority_name, ca.code as authority_code
    into v_curriculum
    from public.curricula c
    left join public.curriculum_authorities ca on ca.id = c.authority_id
    where c.id = p_curriculum_id;
    if found then
      v_country := coalesce(v_country, v_curriculum.country_code);
    end if;
  else
    select c.id, c.country_code, c.name, c.code, ca.name as authority_name, ca.code as authority_code
    into v_curriculum
    from public.curricula c
    left join public.curriculum_authorities ca on ca.id = c.authority_id
    where (v_country is null or c.country_code = v_country)
      and c.is_enabled = true
    order by (case when c.country_code = 'TZ' then 0 else 1 end), c.created_at asc
    limit 1;
    if found then
      v_country := v_curriculum.country_code;
      p_curriculum_id := v_curriculum.id;
    end if;
  end if;

  if v_country is null then
    v_country := 'TZ';
  end if;

  if not (public.can_author_lesson(v_country) or public.can_review_lesson(v_country) or public.can_publish_lesson(v_country)) then
    raise exception 'Permission denied: lesson authoring requires authorized staff role' using errcode = '42501';
  end if;

  select country_code, display_name, product_name
  into v_country_row
  from public.countries
  where country_code = v_country;

  -- Resolve latest curriculum version for the active curriculum
  if p_curriculum_id is not null then
    select cv.id, cv.version_code, cv.display_name, cv.official_document_version, cv.status
    into v_version
    from public.curriculum_versions cv
    where cv.curriculum_id = p_curriculum_id
    order by
      case cv.status when 'published' then 1 when 'approved' then 2 else 3 end,
      cv.created_at desc
    limit 1;
  end if;

  -- Resolve default level if not selected yet
  if v_level.id is null and p_curriculum_id is not null then
    select el.id, el.curriculum_id, el.name, el.code, el.sequence
    into v_level
    from public.education_levels el
    where el.curriculum_id = p_curriculum_id
      and el.is_enabled = true
    order by el.sequence asc
    limit 1;
  end if;

  return jsonb_build_object(
    'country_code', coalesce(v_country_row.country_code, v_country),
    'country_name', coalesce(v_country_row.display_name, v_country),
    'curriculum_id', v_curriculum.id,
    'curriculum_name', v_curriculum.name,
    'curriculum_code', v_curriculum.code,
    'authority_name', v_curriculum.authority_name,
    'authority_code', v_curriculum.authority_code,
    'curriculum_version_id', v_version.id,
    'curriculum_version_code', v_version.version_code,
    'curriculum_version_name', coalesce(v_version.display_name, v_version.official_document_version),
    'education_level_id', v_level.id,
    'education_level_name', v_level.name,
    'grade_id', v_grade.id,
    'grade_name', v_grade.name,
    'subject_id', v_subject.id,
    'subject_name', v_subject.name,
    'capabilities', public.get_lesson_authoring_capabilities(v_country),
    'available_curricula', coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'id', c.id,
            'country_code', c.country_code,
            'country_name', co.display_name,
            'name', c.name,
            'code', c.code,
            'authority_code', ca.code
          ) order by (case when c.country_code = 'TZ' then 0 else 1 end), c.country_code, c.name
        )
        from public.curricula c
        join public.countries co on co.country_code = c.country_code
        left join public.curriculum_authorities ca on ca.id = c.authority_id
        where c.is_enabled = true
      ),
      '[]'::jsonb
    ),
    'available_levels', coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'id', el.id,
            'curriculum_id', el.curriculum_id,
            'name', el.name,
            'code', el.code,
            'sequence', el.sequence
          ) order by el.sequence asc
        )
        from public.education_levels el
        where el.curriculum_id = v_curriculum.id
          and el.is_enabled = true
      ),
      '[]'::jsonb
    )
  );
end;
$$;

-- Dropdown 1: Grades/Classes from actual DB records for active curriculum & level
create or replace function public.get_authoring_grades(
  p_curriculum_id uuid,
  p_education_level_id uuid default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_country text;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select country_code into v_country from public.curricula where id = p_curriculum_id;
  if v_country is null then
    raise exception 'Curriculum % not found', p_curriculum_id using errcode = '22023';
  end if;

  if not (public.can_author_lesson(v_country) or public.can_review_lesson(v_country) or public.can_publish_lesson(v_country)) then
    raise exception 'Permission denied' using errcode = '42501';
  end if;

  return coalesce(
    (
      select jsonb_agg(
        jsonb_build_object(
          'id', eg.id,
          'curriculum_id', eg.curriculum_id,
          'education_level_id', eg.education_level_id,
          'education_level_name', el.name,
          'name', eg.name,
          'code', eg.code,
          'sequence', eg.sequence,
          'subject_count', (
            select count(*)::int
            from public.subjects s
            where s.curriculum_id = eg.curriculum_id
              and s.grade_id = eg.id
              and s.is_published = true
          )
        ) order by el.sequence asc, eg.sequence asc
      )
      from public.education_grades eg
      join public.education_levels el on el.id = eg.education_level_id
      where eg.curriculum_id = p_curriculum_id
        and eg.is_enabled = true
        and (p_education_level_id is null or eg.education_level_id = p_education_level_id)
    ),
    '[]'::jsonb
  );
end;
$$;

-- Dropdown 2: Subjects strictly associated with selected grade & curriculum
create or replace function public.get_authoring_subjects(
  p_curriculum_id uuid,
  p_grade_id uuid,
  p_education_level_id uuid default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_country text;
  v_grade record;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select eg.id, eg.curriculum_id, eg.education_level_id, c.country_code
  into v_grade
  from public.education_grades eg
  join public.curricula c on c.id = eg.curriculum_id
  where eg.id = p_grade_id;

  if not found then
    raise exception 'Grade % not found', p_grade_id using errcode = '22023';
  end if;

  if v_grade.curriculum_id <> p_curriculum_id then
    raise exception 'Grade % does not belong to curriculum %', p_grade_id, p_curriculum_id using errcode = '23514';
  end if;

  if p_education_level_id is not null and v_grade.education_level_id <> p_education_level_id then
    raise exception 'Grade % does not belong to education level %', p_grade_id, p_education_level_id using errcode = '23514';
  end if;

  v_country := v_grade.country_code;
  if not (public.can_author_lesson(v_country) or public.can_review_lesson(v_country) or public.can_publish_lesson(v_country)) then
    raise exception 'Permission denied' using errcode = '42501';
  end if;

  return coalesce(
    (
      select jsonb_agg(
        jsonb_build_object(
          'id', s.id,
          'country_code', s.country_code,
          'curriculum_id', s.curriculum_id,
          'education_level_id', s.education_level_id,
          'grade_id', s.grade_id,
          'code', s.code,
          'name', s.name,
          'official_name', coalesce(s.official_name, s.name),
          'classification', coalesce(s.classification, 'compulsory'),
          'language', coalesce(s.language, 'en'),
          'main_competence_count', (
            select count(*)::int
            from public.curriculum_main_competences mc
            where mc.subject_id = s.id and mc.is_published = true
          )
        ) order by s.display_order asc, s.name asc
      )
      from public.subjects s
      where s.curriculum_id = p_curriculum_id
        and s.education_level_id = v_grade.education_level_id
        and s.grade_id = p_grade_id
        and s.is_published = true
    ),
    '[]'::jsonb
  );
end;
$$;

-- Dropdown 3: Main Competences for selected subject
create or replace function public.get_authoring_main_competences(
  p_subject_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_country text;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select country_code into v_country from public.subjects where id = p_subject_id;
  if v_country is null then
    raise exception 'Subject % not found', p_subject_id using errcode = '22023';
  end if;

  if not (public.can_author_lesson(v_country) or public.can_review_lesson(v_country) or public.can_publish_lesson(v_country)) then
    raise exception 'Permission denied' using errcode = '42501';
  end if;

  return coalesce(
    (
      select jsonb_agg(
        jsonb_build_object(
          'id', mc.id,
          'subject_id', mc.subject_id,
          'curriculum_version_id', mc.curriculum_version_id,
          'code', mc.code,
          'title', mc.title,
          'description', mc.description,
          'display_order', mc.display_order,
          'specific_competence_count', (
            select count(*)::int
            from public.curriculum_specific_competences sc
            where sc.main_competence_id = mc.id and sc.is_published = true
          )
        ) order by mc.display_order asc, mc.code asc
      )
      from public.curriculum_main_competences mc
      where mc.subject_id = p_subject_id
        and mc.is_published = true
    ),
    '[]'::jsonb
  );
end;
$$;

-- Dropdown 4: Specific Competences for selected main competence (with linked real topic & subtopics)
create or replace function public.get_authoring_specific_competences(
  p_main_competence_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_country text;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select s.country_code into v_country
  from public.curriculum_main_competences mc
  join public.subjects s on s.id = mc.subject_id
  where mc.id = p_main_competence_id;

  if v_country is null then
    raise exception 'Main competence % not found', p_main_competence_id using errcode = '22023';
  end if;

  if not (public.can_author_lesson(v_country) or public.can_review_lesson(v_country) or public.can_publish_lesson(v_country)) then
    raise exception 'Permission denied' using errcode = '42501';
  end if;

  return coalesce(
    (
      select jsonb_agg(
        jsonb_build_object(
          'id', sc.id,
          'main_competence_id', sc.main_competence_id,
          'subject_id', sc.subject_id,
          'topic_id', sc.topic_id,
          'topic_title', t.title,
          'code', sc.code,
          'title', sc.title,
          'description', sc.description,
          'period_allocation', sc.period_allocation,
          'assessment_criteria', sc.assessment_criteria,
          'source_page', sc.source_page,
          'display_order', sc.display_order,
          'subtopics', coalesce(
            (
              select jsonb_agg(
                jsonb_build_object(
                  'id', st.id,
                  'topic_id', st.topic_id,
                  'title', st.title,
                  'description', st.description,
                  'learning_outcome', st.learning_outcome,
                  'assessment_criteria', st.assessment_criteria,
                  'period_allocation', st.period_allocation,
                  'source_page', st.source_page,
                  'display_order', st.display_order
                ) order by st.display_order asc
              )
              from public.subtopics st
              where st.topic_id = sc.topic_id
                and st.is_published = true
            ),
            '[]'::jsonb
          )
        ) order by sc.display_order asc, sc.code asc
      )
      from public.curriculum_specific_competences sc
      left join public.topics t on t.id = sc.topic_id
      where sc.main_competence_id = p_main_competence_id
        and sc.is_published = true
    ),
    '[]'::jsonb
  );
end;
$$;

-- ============================================================================
-- 8. Backend-Validated Lesson Save, Workflow Transition & Bundle RPCs
-- ============================================================================

create or replace function public.save_authored_lesson(
  p_country_code text,
  p_curriculum_id uuid,
  p_curriculum_version_id uuid,
  p_education_level_id uuid,
  p_grade_id uuid,
  p_subject_id uuid,
  p_main_competence_id uuid,
  p_specific_competence_id uuid,
  p_topic_id uuid,
  p_title text,
  p_body_markdown text,
  p_subtopic_id uuid default null,
  p_summary text default null,
  p_estimated_minutes integer default 20,
  p_language_code text default 'en',
  p_difficulty_level text default 'standard',
  p_lesson_type text default 'core_instruction',
  p_is_free_preview boolean default false,
  p_learning_objectives jsonb default '[]'::jsonb,
  p_learning_outcomes jsonb default '[]'::jsonb,
  p_content_blocks jsonb default '[]'::jsonb,
  p_teaching_activities jsonb default '[]'::jsonb,
  p_assessment_criteria text default null,
  p_change_summary text default null,
  p_lesson_id uuid default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_country text := upper(btrim(coalesce(p_country_code, '')));
  v_existing record;
  v_prev_status text := null;
  v_target_id uuid;
  v_new_version integer := 1;
  v_next_order integer := 1;
  v_effective_body text;
  v_spec_topic_id uuid;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  if not public.can_author_lesson(v_country) then
    raise exception 'Permission denied: user is not authorized to author lessons for %', v_country
      using errcode = '42501';
  end if;

  if nullif(btrim(coalesce(p_title, '')), '') is null then
    raise exception 'Validation error: lesson title is required' using errcode = '22023';
  end if;

  if p_curriculum_id is null or p_education_level_id is null or p_grade_id is null
     or p_subject_id is null or p_main_competence_id is null or p_specific_competence_id is null then
    raise exception 'Validation error: curriculum, education level, grade, subject, main competence, and specific competence are required'
      using errcode = '22023';
  end if;

  -- Resolve canonical topic_id from specific competence if omitted
  select topic_id into v_spec_topic_id
  from public.curriculum_specific_competences
  where id = p_specific_competence_id;

  if p_topic_id is null then
    p_topic_id := v_spec_topic_id;
  end if;

  if p_topic_id is null then
    raise exception 'Curriculum alignment error: specific competence % is not linked to a curriculum topic', p_specific_competence_id
      using errcode = '23514';
  end if;

  v_effective_body := nullif(btrim(coalesce(p_body_markdown, '')), '');
  if v_effective_body is null then
    v_effective_body := '# ' || btrim(p_title);
  end if;

  if p_lesson_id is not null then
    select * into v_existing
    from public.lessons
    where id = p_lesson_id;

    if not found then
      raise exception 'Lesson % not found', p_lesson_id using errcode = '22023';
    end if;

    -- Controlled revision process: published or approved lessons cannot be silently overwritten by non-publishers
    if v_existing.status = 'published' then
      if not public.can_publish_lesson(v_country) then
        raise exception 'Published lessons require a controlled revision workflow before editing'
          using errcode = '42501';
      end if;
    elsif v_existing.status = 'in_review' then
      raise exception 'Lessons currently under academic review cannot be edited until revision is requested'
        using errcode = '42501';
    elsif v_existing.author_id is not null
          and v_existing.author_id <> v_uid
          and not public.can_publish_lesson(v_country)
          and not public.has_role('content_admin', v_country) then
      raise exception 'Permission denied: authors can only edit their own drafts'
        using errcode = '42501';
    end if;

    v_prev_status := v_existing.status;
    v_new_version := v_existing.version_number + 1;

    -- Draft save NEVER auto-publishes; editing a published lesson moves it back to draft for controlled re-review
    update public.lessons
    set
      country_code = v_country,
      curriculum_id = p_curriculum_id,
      curriculum_version_id = p_curriculum_version_id,
      education_level_id = p_education_level_id,
      grade_id = p_grade_id,
      subject_id = p_subject_id,
      main_competence_id = p_main_competence_id,
      specific_competence_id = p_specific_competence_id,
      topic_id = p_topic_id,
      subtopic_id = p_subtopic_id,
      title = btrim(p_title),
      summary = nullif(btrim(coalesce(p_summary, '')), ''),
      body_markdown = v_effective_body,
      estimated_minutes = coalesce(p_estimated_minutes, 20),
      language_code = coalesce(nullif(btrim(p_language_code), ''), 'en'),
      difficulty_level = coalesce(nullif(btrim(p_difficulty_level), ''), 'standard'),
      lesson_type = coalesce(nullif(btrim(p_lesson_type), ''), 'core_instruction'),
      is_free_preview = coalesce(p_is_free_preview, false),
      learning_objectives = coalesce(p_learning_objectives, '[]'::jsonb),
      learning_outcomes = coalesce(p_learning_outcomes, '[]'::jsonb),
      content_blocks = coalesce(p_content_blocks, '[]'::jsonb),
      teaching_activities = coalesce(p_teaching_activities, '[]'::jsonb),
      assessment_criteria = nullif(btrim(coalesce(p_assessment_criteria, '')), ''),
      status = 'draft',
      is_published = false,
      version_number = v_new_version,
      updated_at = now()
    where id = p_lesson_id
    returning id into v_target_id;
  else
    select coalesce(max(display_order), 0) + 1 into v_next_order
    from public.lessons
    where topic_id = p_topic_id;

    insert into public.lessons (
      country_code,
      curriculum_id,
      curriculum_version_id,
      education_level_id,
      grade_id,
      subject_id,
      main_competence_id,
      specific_competence_id,
      topic_id,
      subtopic_id,
      title,
      summary,
      body_markdown,
      estimated_minutes,
      language_code,
      difficulty_level,
      lesson_type,
      is_free_preview,
      display_order,
      learning_objectives,
      learning_outcomes,
      content_blocks,
      teaching_activities,
      assessment_criteria,
      status,
      is_published,
      version_number,
      author_id
    ) values (
      v_country,
      p_curriculum_id,
      p_curriculum_version_id,
      p_education_level_id,
      p_grade_id,
      p_subject_id,
      p_main_competence_id,
      p_specific_competence_id,
      p_topic_id,
      p_subtopic_id,
      btrim(p_title),
      nullif(btrim(coalesce(p_summary, '')), ''),
      v_effective_body,
      coalesce(p_estimated_minutes, 20),
      coalesce(nullif(btrim(p_language_code), ''), 'en'),
      coalesce(nullif(btrim(p_difficulty_level), ''), 'standard'),
      coalesce(nullif(btrim(p_lesson_type), ''), 'core_instruction'),
      coalesce(p_is_free_preview, false),
      v_next_order,
      coalesce(p_learning_objectives, '[]'::jsonb),
      coalesce(p_learning_outcomes, '[]'::jsonb),
      coalesce(p_content_blocks, '[]'::jsonb),
      coalesce(p_teaching_activities, '[]'::jsonb),
      nullif(btrim(coalesce(p_assessment_criteria, '')), ''),
      'draft',
      false,
      1,
      v_uid
    )
    returning id into v_target_id;
  end if;

  -- Record immutable version snapshot
  insert into public.lesson_revisions (
    lesson_id,
    version_number,
    title,
    summary,
    body_markdown,
    content_blocks,
    status,
    difficulty_level,
    lesson_type,
    language_code,
    estimated_minutes,
    learning_objectives,
    learning_outcomes,
    teaching_activities,
    curriculum_snapshot,
    changed_by_user_id,
    change_summary
  ) values (
    v_target_id,
    v_new_version,
    btrim(p_title),
    nullif(btrim(coalesce(p_summary, '')), ''),
    v_effective_body,
    coalesce(p_content_blocks, '[]'::jsonb),
    'draft',
    coalesce(nullif(btrim(p_difficulty_level), ''), 'standard'),
    coalesce(nullif(btrim(p_lesson_type), ''), 'core_instruction'),
    coalesce(nullif(btrim(p_language_code), ''), 'en'),
    coalesce(p_estimated_minutes, 20),
    coalesce(p_learning_objectives, '[]'::jsonb),
    coalesce(p_learning_outcomes, '[]'::jsonb),
    coalesce(p_teaching_activities, '[]'::jsonb),
    jsonb_build_object(
      'country_code', v_country,
      'curriculum_id', p_curriculum_id,
      'curriculum_version_id', p_curriculum_version_id,
      'education_level_id', p_education_level_id,
      'grade_id', p_grade_id,
      'subject_id', p_subject_id,
      'main_competence_id', p_main_competence_id,
      'specific_competence_id', p_specific_competence_id,
      'topic_id', p_topic_id,
      'subtopic_id', p_subtopic_id
    ),
    v_uid,
    coalesce(nullif(btrim(coalesce(p_change_summary, '')), ''), 'Saved draft in Lesson Studio')
  );

  insert into public.lesson_review_events (
    lesson_id,
    actor_user_id,
    action,
    from_status,
    to_status,
    version_number,
    comments
  ) values (
    v_target_id,
    v_uid,
    'draft_saved',
    v_prev_status,
    'draft',
    v_new_version,
    coalesce(nullif(btrim(coalesce(p_change_summary, '')), ''), 'Draft saved')
  );

  return jsonb_build_object(
    'id', v_target_id,
    'title', btrim(p_title),
    'status', 'draft',
    'is_published', false,
    'version_number', v_new_version,
    'updated_at', now()
  );
end;
$$;

-- Controlled Editorial Lifecycle Transition RPC
create or replace function public.transition_lesson_workflow(
  p_lesson_id uuid,
  p_action text,
  p_comments text default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_lesson record;
  v_country text;
  v_new_status text;
  v_event_action text;
  v_is_pub boolean := false;
  v_obj_count integer := 0;
  v_out_count integer := 0;
  v_block_count integer := 0;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select l.*, s.country_code as resolved_country
  into v_lesson
  from public.lessons l
  join public.topics t on t.id = l.topic_id
  join public.subjects s on s.id = t.subject_id
  where l.id = p_lesson_id;

  if not found then
    raise exception 'Lesson % not found', p_lesson_id using errcode = '22023';
  end if;

  v_country := coalesce(v_lesson.country_code, v_lesson.resolved_country);

  case p_action
    when 'submit_for_review' then
      if not public.can_author_lesson(v_country) then
        raise exception 'Permission denied: only authorized authors can submit lessons for review'
          using errcode = '42501';
      end if;
      if v_lesson.status not in ('draft', 'revision_requested') then
        raise exception 'Invalid transition: only draft or revision_requested lessons can be submitted for review (current: %)', v_lesson.status
          using errcode = '22023';
      end if;

      -- Validate objectives, outcomes, and instructional content before submission
      v_obj_count := coalesce(jsonb_array_length(v_lesson.learning_objectives), 0);
      v_out_count := coalesce(jsonb_array_length(v_lesson.learning_outcomes), 0);
      v_block_count := coalesce(jsonb_array_length(v_lesson.content_blocks), 0);

      if v_obj_count < 1 then
        raise exception 'Submission blocked: at least one learning objective is required before submitting for review'
          using errcode = '22023';
      end if;
      if v_out_count < 1 then
        raise exception 'Submission blocked: at least one measurable learning outcome is required before submitting for review'
          using errcode = '22023';
      end if;
      if v_block_count < 1 and char_length(btrim(coalesce(v_lesson.body_markdown, ''))) < 50 then
        raise exception 'Submission blocked: sufficient instructional content is required before submitting for review'
          using errcode = '22023';
      end if;

      v_new_status := 'in_review';
      v_event_action := 'submitted_for_review';
      v_is_pub := false;

    when 'request_revision' then
      if not public.can_review_lesson(v_country) then
        raise exception 'Permission denied: only academic reviewers can request revisions'
          using errcode = '42501';
      end if;
      if v_lesson.status <> 'in_review' then
        raise exception 'Invalid transition: revisions can only be requested on lessons in review (current: %)', v_lesson.status
          using errcode = '22023';
      end if;
      if nullif(btrim(coalesce(p_comments, '')), '') is null then
        raise exception 'Validation error: revision comments are required when requesting revisions'
          using errcode = '22023';
      end if;
      v_new_status := 'revision_requested';
      v_event_action := 'revision_requested';
      v_is_pub := false;

    when 'approve' then
      if not public.can_approve_lesson(v_country) then
        raise exception 'Permission denied: only authorized academic reviewers or approvers can approve lessons'
          using errcode = '42501';
      end if;
      if v_lesson.status <> 'in_review' then
        raise exception 'Invalid transition: only lessons in review can be approved (current: %)', v_lesson.status
          using errcode = '22023';
      end if;
      -- Enforce two-party review for non-super-admins
      if v_lesson.author_id = v_uid and not public.has_role('super_admin') then
        raise exception 'Two-party governance violation: lesson author cannot self-approve their own lesson'
          using errcode = '42501';
      end if;
      v_new_status := 'approved';
      v_event_action := 'approved';
      v_is_pub := false;

    when 'publish' then
      if not public.can_publish_lesson(v_country) then
        raise exception 'Permission denied: only authorized publishing roles can publish lessons'
          using errcode = '42501';
      end if;
      if v_lesson.status <> 'approved' then
        raise exception 'Invalid transition: a lesson must be approved before publishing (current: %)', v_lesson.status
          using errcode = '22023';
      end if;
      v_new_status := 'published';
      v_event_action := 'published';
      v_is_pub := true;

    when 'reopen_draft' then
      if not (public.can_publish_lesson(v_country) or (v_lesson.author_id = v_uid and public.can_author_lesson(v_country))) then
        raise exception 'Permission denied: cannot reopen lesson to draft'
          using errcode = '42501';
      end if;
      if v_lesson.status = 'published' and not public.can_publish_lesson(v_country) then
        raise exception 'Permission denied: only authorized publishing roles can initiate revision of a published lesson'
          using errcode = '42501';
      end if;
      v_new_status := 'draft';
      v_event_action := 'reopened_draft';
      v_is_pub := false;

    when 'archive' then
      if not public.can_publish_lesson(v_country) then
        raise exception 'Permission denied: only authorized administrators can archive lessons'
          using errcode = '42501';
      end if;
      v_new_status := 'archived';
      v_event_action := 'archived';
      v_is_pub := false;

    else
      raise exception 'Invalid workflow action: %', p_action using errcode = '22023';
  end case;

  update public.lessons
  set
    status = v_new_status,
    is_published = v_is_pub,
    submitted_at = case when p_action = 'submit_for_review' then now() else submitted_at end,
    reviewer_id = case when p_action in ('request_revision', 'approve') then v_uid else reviewer_id end,
    review_notes = coalesce(nullif(btrim(coalesce(p_comments, '')), ''), review_notes),
    approved_by = case when p_action = 'approve' then v_uid else approved_by end,
    approved_at = case when p_action = 'approve' then now() else approved_at end,
    published_by = case when p_action = 'publish' then v_uid else published_by end,
    published_at = case when p_action = 'publish' then now() else published_at end,
    updated_at = now()
  where id = p_lesson_id;

  insert into public.lesson_review_events (
    lesson_id,
    actor_user_id,
    action,
    from_status,
    to_status,
    version_number,
    comments
  ) values (
    p_lesson_id,
    v_uid,
    v_event_action,
    v_lesson.status,
    v_new_status,
    v_lesson.version_number,
    nullif(btrim(coalesce(p_comments, '')), '')
  );

  return jsonb_build_object(
    'id', p_lesson_id,
    'from_status', v_lesson.status,
    'status', v_new_status,
    'is_published', v_is_pub,
    'action', p_action,
    'version_number', v_lesson.version_number,
    'updated_at', now()
  );
end;
$$;

-- Harden existing upsert_studio_lesson so non-publishers can never directly publish
create or replace function public.upsert_studio_lesson(
  p_topic_id uuid,
  p_title text,
  p_body_markdown text,
  p_summary text default null,
  p_estimated_minutes integer default 10,
  p_is_free_preview boolean default false,
  p_status text default 'draft',
  p_content_blocks jsonb default '[]'::jsonb,
  p_lesson_id uuid default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_country text;
  v_target_id uuid;
  v_new_version integer := 1;
  v_is_pub boolean;
  v_result jsonb;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select s.country_code into v_country
  from public.topics t
  join public.subjects s on t.subject_id = s.id
  where t.id = p_topic_id;

  if v_country is null then
    raise exception 'Target topic % not found', p_topic_id using errcode = '22023';
  end if;

  if not (
    public.can_author_lesson(v_country)
    or exists (
      select 1 from public.organization_memberships m
      where m.user_id = v_user_id
        and m.status = 'active'
        and m.role in ('institutional_admin', 'school_principal', 'head_of_department', 'teacher', 'curriculum_analyst')
    )
  ) then
    raise exception 'Permission denied: cannot author or edit lesson' using errcode = '42501';
  end if;

  v_is_pub := (p_status = 'published');
  if v_is_pub and not public.can_publish_lesson(v_country) then
    raise exception 'Permission denied: only authorized publishing roles can publish lessons'
      using errcode = '42501';
  end if;

  if p_lesson_id is not null then
    select version_number + 1 into v_new_version
    from public.lessons
    where id = p_lesson_id;

    if v_new_version is null then
      v_new_version := 2;
    end if;

    update public.lessons
    set
      title = btrim(p_title),
      summary = p_summary,
      body_markdown = p_body_markdown,
      content_blocks = coalesce(p_content_blocks, '[]'::jsonb),
      estimated_minutes = coalesce(p_estimated_minutes, 10),
      is_free_preview = coalesce(p_is_free_preview, false),
      status = p_status,
      is_published = v_is_pub,
      version_number = v_new_version,
      published_by = case when v_is_pub then v_user_id else published_by end,
      published_at = case when v_is_pub then coalesce(published_at, now()) else null end,
      updated_at = now()
    where id = p_lesson_id
    returning id into v_target_id;
  else
    insert into public.lessons (
      topic_id,
      title,
      summary,
      body_markdown,
      content_blocks,
      estimated_minutes,
      is_free_preview,
      status,
      is_published,
      version_number,
      author_id,
      published_by,
      published_at
    ) values (
      p_topic_id,
      btrim(p_title),
      p_summary,
      p_body_markdown,
      coalesce(p_content_blocks, '[]'::jsonb),
      coalesce(p_estimated_minutes, 10),
      coalesce(p_is_free_preview, false),
      p_status,
      v_is_pub,
      1,
      v_user_id,
      case when v_is_pub then v_user_id else null end,
      case when v_is_pub then now() else null end
    )
    returning id into v_target_id;
  end if;

  insert into public.lesson_revisions (
    lesson_id,
    version_number,
    title,
    summary,
    body_markdown,
    content_blocks,
    status,
    changed_by_user_id,
    change_summary
  ) values (
    v_target_id,
    v_new_version,
    btrim(p_title),
    p_summary,
    p_body_markdown,
    coalesce(p_content_blocks, '[]'::jsonb),
    p_status,
    v_user_id,
    'Updated in Content Management Studio'
  );

  v_result := jsonb_build_object(
    'id', v_target_id,
    'title', btrim(p_title),
    'status', p_status,
    'version_number', v_new_version,
    'is_published', v_is_pub,
    'updated_at', now()
  );

  return v_result;
end;
$$;

-- Fetch full lesson bundle (lesson + curriculum breadcrumb + questions + revisions + review events)
create or replace function public.get_authored_lesson_bundle(
  p_lesson_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_lesson record;
  v_country text;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select
    l.*,
    co.display_name as country_name,
    c.name as curriculum_name,
    c.code as curriculum_code,
    cv.version_code as curriculum_version_code,
    cv.display_name as curriculum_version_name,
    el.name as education_level_name,
    eg.name as grade_name,
    eg.code as grade_code,
    s.name as subject_name,
    s.code as subject_code,
    s.country_code as subject_country_code,
    mc.code as main_competence_code,
    mc.title as main_competence_title,
    sc.code as specific_competence_code,
    sc.title as specific_competence_title,
    t.title as topic_title,
    st.title as subtopic_title
  into v_lesson
  from public.lessons l
  join public.topics t on t.id = l.topic_id
  join public.subjects s on s.id = t.subject_id
  left join public.countries co on co.country_code = coalesce(l.country_code, s.country_code)
  left join public.curricula c on c.id = coalesce(l.curriculum_id, s.curriculum_id)
  left join public.curriculum_versions cv on cv.id = l.curriculum_version_id
  left join public.education_levels el on el.id = coalesce(l.education_level_id, s.education_level_id)
  left join public.education_grades eg on eg.id = coalesce(l.grade_id, s.grade_id)
  left join public.curriculum_main_competences mc on mc.id = l.main_competence_id
  left join public.curriculum_specific_competences sc on sc.id = l.specific_competence_id
  left join public.subtopics st on st.id = l.subtopic_id
  where l.id = p_lesson_id;

  if not found then
    raise exception 'Lesson % not found', p_lesson_id using errcode = '22023';
  end if;

  v_country := coalesce(v_lesson.country_code, v_lesson.subject_country_code);
  if not (
    v_lesson.author_id = v_uid
    or public.can_author_lesson(v_country)
    or public.can_review_lesson(v_country)
    or public.can_publish_lesson(v_country)
  ) then
    raise exception 'Permission denied' using errcode = '42501';
  end if;

  return jsonb_build_object(
    'lesson', jsonb_build_object(
      'id', v_lesson.id,
      'country_code', v_country,
      'country_name', v_lesson.country_name,
      'curriculum_id', coalesce(v_lesson.curriculum_id, null),
      'curriculum_name', v_lesson.curriculum_name,
      'curriculum_code', v_lesson.curriculum_code,
      'curriculum_version_id', v_lesson.curriculum_version_id,
      'curriculum_version_code', v_lesson.curriculum_version_code,
      'curriculum_version_name', v_lesson.curriculum_version_name,
      'education_level_id', v_lesson.education_level_id,
      'education_level_name', v_lesson.education_level_name,
      'grade_id', v_lesson.grade_id,
      'grade_name', v_lesson.grade_name,
      'grade_code', v_lesson.grade_code,
      'subject_id', v_lesson.subject_id,
      'subject_name', v_lesson.subject_name,
      'subject_code', v_lesson.subject_code,
      'main_competence_id', v_lesson.main_competence_id,
      'main_competence_code', v_lesson.main_competence_code,
      'main_competence_title', v_lesson.main_competence_title,
      'specific_competence_id', v_lesson.specific_competence_id,
      'specific_competence_code', v_lesson.specific_competence_code,
      'specific_competence_title', v_lesson.specific_competence_title,
      'topic_id', v_lesson.topic_id,
      'topic_title', v_lesson.topic_title,
      'subtopic_id', v_lesson.subtopic_id,
      'subtopic_title', v_lesson.subtopic_title,
      'title', v_lesson.title,
      'summary', v_lesson.summary,
      'body_markdown', v_lesson.body_markdown,
      'estimated_minutes', v_lesson.estimated_minutes,
      'language_code', v_lesson.language_code,
      'difficulty_level', v_lesson.difficulty_level,
      'lesson_type', v_lesson.lesson_type,
      'is_free_preview', v_lesson.is_free_preview,
      'learning_objectives', v_lesson.learning_objectives,
      'learning_outcomes', v_lesson.learning_outcomes,
      'content_blocks', v_lesson.content_blocks,
      'teaching_activities', v_lesson.teaching_activities,
      'assessment_criteria', v_lesson.assessment_criteria,
      'status', v_lesson.status,
      'is_published', v_lesson.is_published,
      'version_number', v_lesson.version_number,
      'author_id', v_lesson.author_id,
      'reviewer_id', v_lesson.reviewer_id,
      'review_notes', v_lesson.review_notes,
      'approved_by', v_lesson.approved_by,
      'approved_at', v_lesson.approved_at,
      'published_by', v_lesson.published_by,
      'published_at', v_lesson.published_at,
      'updated_at', v_lesson.updated_at
    ),
    'questions', coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'id', q.id,
            'lesson_id', q.lesson_id,
            'question_type', q.question_type,
            'difficulty_level', q.difficulty_level,
            'question_text', q.question_text,
            'options', q.options,
            'correct_answer', q.correct_answer,
            'explanation', q.explanation,
            'marks', q.marks,
            'learning_outcome_ref', q.learning_outcome_ref,
            'assessment_criteria', q.assessment_criteria,
            'cognitive_tier', q.cognitive_tier,
            'display_order', q.display_order,
            'is_published', q.is_published
          ) order by q.display_order asc, q.created_at asc
        )
        from public.question_bank q
        where q.lesson_id = p_lesson_id
      ),
      '[]'::jsonb
    ),
    'revisions', coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'id', r.id,
            'version_number', r.version_number,
            'title', r.title,
            'summary', r.summary,
            'status', r.status,
            'change_summary', r.change_summary,
            'changed_by_user_id', r.changed_by_user_id,
            'created_at', r.created_at
          ) order by r.version_number desc
        )
        from public.lesson_revisions r
        where r.lesson_id = p_lesson_id
      ),
      '[]'::jsonb
    ),
    'review_events', coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'id', e.id,
            'action', e.action,
            'from_status', e.from_status,
            'to_status', e.to_status,
            'version_number', e.version_number,
            'comments', e.comments,
            'actor_user_id', e.actor_user_id,
            'created_at', e.created_at
          ) order by e.created_at desc
        )
        from public.lesson_review_events e
        where e.lesson_id = p_lesson_id
      ),
      '[]'::jsonb
    )
  );
end;
$$;

-- ============================================================================
-- 9. Question Bank & Media Library Integration RPCs
-- ============================================================================

create or replace function public.upsert_lesson_assessment_question(
  p_lesson_id uuid,
  p_question_type text,
  p_question_text text,
  p_correct_answer jsonb,
  p_options jsonb default '[]'::jsonb,
  p_explanation text default null,
  p_marks numeric default 1,
  p_difficulty_level text default 'medium',
  p_learning_outcome_ref text default null,
  p_assessment_criteria text default null,
  p_cognitive_tier text default 'knowledge',
  p_question_id uuid default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_lesson record;
  v_target_id uuid;
  v_order integer := 1;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select l.id, l.topic_id, l.grade_id, l.subject_id, l.curriculum_id, l.country_code, l.is_published,
         s.country_code as s_country, s.curriculum_id as s_curriculum, s.id as s_id, s.grade_id as s_grade
  into v_lesson
  from public.lessons l
  join public.topics t on t.id = l.topic_id
  join public.subjects s on s.id = t.subject_id
  where l.id = p_lesson_id;

  if not found then
    raise exception 'Lesson % not found', p_lesson_id using errcode = '22023';
  end if;

  if not public.can_author_lesson(coalesce(v_lesson.country_code, v_lesson.s_country)) then
    raise exception 'Permission denied: cannot manage lesson assessment questions' using errcode = '42501';
  end if;

  if p_question_id is not null then
    update public.question_bank
    set
      question_type = p_question_type,
      difficulty_level = coalesce(p_difficulty_level, 'medium'),
      question_text = btrim(p_question_text),
      options = p_options,
      correct_answer = p_correct_answer,
      explanation = nullif(btrim(coalesce(p_explanation, '')), ''),
      marks = coalesce(p_marks, 1),
      learning_outcome_ref = nullif(btrim(coalesce(p_learning_outcome_ref, '')), ''),
      assessment_criteria = nullif(btrim(coalesce(p_assessment_criteria, '')), ''),
      cognitive_tier = coalesce(p_cognitive_tier, 'knowledge'),
      updated_at = now()
    where id = p_question_id
      and lesson_id = p_lesson_id
    returning id into v_target_id;

    if v_target_id is null then
      raise exception 'Question % not found for lesson %', p_question_id, p_lesson_id using errcode = '22023';
    end if;
  else
    select coalesce(max(display_order), 0) + 1 into v_order
    from public.question_bank
    where lesson_id = p_lesson_id;

    insert into public.question_bank (
      country_code,
      curriculum_id,
      subject_id,
      topic_id,
      grade_id,
      lesson_id,
      question_type,
      difficulty_level,
      question_text,
      options,
      correct_answer,
      explanation,
      marks,
      learning_outcome_ref,
      assessment_criteria,
      cognitive_tier,
      display_order,
      is_published,
      author_id
    ) values (
      coalesce(v_lesson.country_code, v_lesson.s_country),
      coalesce(v_lesson.curriculum_id, v_lesson.s_curriculum),
      coalesce(v_lesson.subject_id, v_lesson.s_id),
      v_lesson.topic_id,
      coalesce(v_lesson.grade_id, v_lesson.s_grade),
      p_lesson_id,
      p_question_type,
      coalesce(p_difficulty_level, 'medium'),
      btrim(p_question_text),
      p_options,
      p_correct_answer,
      nullif(btrim(coalesce(p_explanation, '')), ''),
      coalesce(p_marks, 1),
      nullif(btrim(coalesce(p_learning_outcome_ref, '')), ''),
      nullif(btrim(coalesce(p_assessment_criteria, '')), ''),
      coalesce(p_cognitive_tier, 'knowledge'),
      v_order,
      v_lesson.is_published,
      v_uid
    )
    returning id into v_target_id;
  end if;

  return jsonb_build_object(
    'id', v_target_id,
    'lesson_id', p_lesson_id,
    'question_type', p_question_type,
    'marks', coalesce(p_marks, 1)
  );
end;
$$;

create or replace function public.delete_lesson_assessment_question(
  p_question_id uuid
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_country text;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select country_code into v_country from public.question_bank where id = p_question_id;
  if v_country is null then
    raise exception 'Question % not found', p_question_id using errcode = '22023';
  end if;

  if not public.can_author_lesson(v_country) then
    raise exception 'Permission denied' using errcode = '42501';
  end if;

  delete from public.question_bank where id = p_question_id;

  return jsonb_build_object('deleted', true, 'id', p_question_id);
end;
$$;

create or replace function public.register_lesson_media_asset(
  p_title text,
  p_country_code text,
  p_media_type text,
  p_file_url text,
  p_subject_id uuid default null,
  p_description text default null,
  p_storage_bucket text default 'lesson-media',
  p_storage_object_path text default null,
  p_mime_type text default null,
  p_file_size_bytes bigint default 0,
  p_source_reference text default null,
  p_license_type text default 'unverified',
  p_attribution text default null,
  p_alt_text text default null,
  p_transcript text default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_country text := upper(btrim(coalesce(p_country_code, '')));
  v_row public.content_media_assets;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  if not public.can_author_lesson(v_country) then
    raise exception 'Permission denied: not authorized to register media assets for %', v_country
      using errcode = '42501';
  end if;

  if coalesce(p_file_size_bytes, 0) > 26214400 then
    raise exception 'File exceeds maximum allowed size of 25 MB' using errcode = '22023';
  end if;

  -- Never assume uploaded material is copyright-cleared; always start pending_review & copyright_cleared = false
  insert into public.content_media_assets (
    title,
    description,
    country_code,
    subject_id,
    media_type,
    file_url,
    storage_bucket,
    storage_object_path,
    mime_type,
    file_size_bytes,
    source_reference,
    license_type,
    copyright_cleared,
    attribution,
    alt_text,
    transcript,
    review_status,
    uploaded_by_user_id
  ) values (
    btrim(p_title),
    nullif(btrim(coalesce(p_description, '')), ''),
    v_country,
    p_subject_id,
    p_media_type,
    btrim(p_file_url),
    nullif(btrim(coalesce(p_storage_bucket, '')), ''),
    nullif(btrim(coalesce(p_storage_object_path, '')), ''),
    nullif(btrim(coalesce(p_mime_type, '')), ''),
    coalesce(p_file_size_bytes, 0),
    nullif(btrim(coalesce(p_source_reference, '')), ''),
    coalesce(nullif(btrim(coalesce(p_license_type, '')), ''), 'unverified'),
    false,
    nullif(btrim(coalesce(p_attribution, '')), ''),
    nullif(btrim(coalesce(p_alt_text, '')), ''),
    nullif(btrim(coalesce(p_transcript, '')), ''),
    'pending_review',
    v_uid
  )
  returning * into v_row;

  return to_jsonb(v_row);
end;
$$;

-- Grants for all new RPCs
revoke all on function public.get_lesson_authoring_context(text, uuid, uuid, uuid, uuid) from public, anon;
revoke all on function public.get_authoring_grades(uuid, uuid) from public, anon;
revoke all on function public.get_authoring_subjects(uuid, uuid, uuid) from public, anon;
revoke all on function public.get_authoring_main_competences(uuid) from public, anon;
revoke all on function public.get_authoring_specific_competences(uuid) from public, anon;
revoke all on function public.save_authored_lesson(text, uuid, uuid, uuid, uuid, uuid, uuid, uuid, uuid, text, text, uuid, text, integer, text, text, text, boolean, jsonb, jsonb, jsonb, jsonb, text, text, uuid) from public, anon;
revoke all on function public.transition_lesson_workflow(uuid, text, text) from public, anon;
revoke all on function public.get_authored_lesson_bundle(uuid) from public, anon;
revoke all on function public.upsert_lesson_assessment_question(uuid, text, text, jsonb, jsonb, text, numeric, text, text, text, text, uuid) from public, anon;
revoke all on function public.delete_lesson_assessment_question(uuid) from public, anon;
revoke all on function public.register_lesson_media_asset(text, text, text, text, uuid, text, text, text, text, bigint, text, text, text, text, text) from public, anon;

grant execute on function public.get_lesson_authoring_context(text, uuid, uuid, uuid, uuid) to authenticated, service_role;
grant execute on function public.get_authoring_grades(uuid, uuid) to authenticated, service_role;
grant execute on function public.get_authoring_subjects(uuid, uuid, uuid) to authenticated, service_role;
grant execute on function public.get_authoring_main_competences(uuid) to authenticated, service_role;
grant execute on function public.get_authoring_specific_competences(uuid) to authenticated, service_role;
grant execute on function public.save_authored_lesson(text, uuid, uuid, uuid, uuid, uuid, uuid, uuid, uuid, text, text, uuid, text, integer, text, text, text, boolean, jsonb, jsonb, jsonb, jsonb, text, text, uuid) to authenticated, service_role;
grant execute on function public.transition_lesson_workflow(uuid, text, text) to authenticated, service_role;
grant execute on function public.get_authored_lesson_bundle(uuid) to authenticated, service_role;
grant execute on function public.upsert_lesson_assessment_question(uuid, text, text, jsonb, jsonb, text, numeric, text, text, text, text, uuid) to authenticated, service_role;
grant execute on function public.delete_lesson_assessment_question(uuid) to authenticated, service_role;
grant execute on function public.register_lesson_media_asset(text, text, text, text, uuid, text, text, text, text, bigint, text, text, text, text, text) to authenticated, service_role;

commit;
