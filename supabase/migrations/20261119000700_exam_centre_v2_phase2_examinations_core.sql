-- ============================================================================
-- LearnTZ Examination Centre 2.0 — Phase 2: Examination Database, Metadata,
-- Curriculum Coverage, Blueprint Sections & Controlled Lifecycle
-- Migration: 20261119000700_exam_centre_v2_phase2_examinations_core.sql
--
-- Reuses existing curriculum tables, examination_types, and RBAC helpers
-- (can_author_lesson, can_review_lesson, can_approve_lesson, can_publish_lesson).
-- Zero hardcoded UUIDs; strict server-side hierarchy & two-party validation.
-- ============================================================================

begin;

-- ============================================================================
-- 1. Table: public.examinations
-- ============================================================================
create table if not exists public.examinations (
  id uuid primary key default gen_random_uuid(),
  country_code text not null references public.countries (country_code) on delete restrict,
  curriculum_id uuid not null references public.curricula (id) on delete restrict,
  curriculum_version_id uuid references public.curriculum_versions (id) on delete restrict,
  education_level_id uuid not null references public.education_levels (id) on delete restrict,
  grade_id uuid not null references public.education_grades (id) on delete restrict,
  subject_id uuid not null references public.subjects (id) on delete restrict,
  examination_type_id uuid not null references public.examination_types (id) on delete restrict,
  title text not null check (char_length(btrim(title)) between 3 and 240),
  academic_year integer not null default extract(year from now())::integer check (academic_year between 2020 and 2100),
  academic_term text not null default 'Term I' check (char_length(btrim(academic_term)) between 1 and 60),
  examination_date date,
  duration_minutes integer not null default 90 check (duration_minutes between 15 and 360),
  total_marks numeric not null default 0 check (total_marks >= 0 and total_marks <= 1000),
  language_code text not null default 'en' check (char_length(btrim(language_code)) between 2 and 12),
  instructions text not null default 'Read all questions carefully. Answer all questions unless otherwise instructed.',
  delivery_mode text not null default 'hybrid' check (delivery_mode in ('online', 'printed', 'hybrid')),
  allow_offline_sync boolean not null default false,
  randomize_questions boolean not null default false,
  randomize_options boolean not null default false,
  max_attempts integer not null default 1 check (max_attempts between 1 and 10),
  status text not null default 'draft' check (status in (
    'draft',
    'submitted_for_review',
    'under_review',
    'revision_requested',
    'approved',
    'published',
    'active',
    'completed',
    'results_released',
    'archived'
  )),
  is_published boolean not null default false,
  version_number integer not null default 1 check (version_number >= 1),
  author_id uuid references auth.users (id) on delete set null,
  reviewer_id uuid references auth.users (id) on delete set null,
  review_notes text,
  submitted_at timestamptz,
  approved_by uuid references auth.users (id) on delete set null,
  approved_at timestamptz,
  published_by uuid references auth.users (id) on delete set null,
  published_at timestamptz,
  metadata jsonb not null default '{}'::jsonb check (jsonb_typeof(metadata) = 'object'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists examinations_context_idx
  on public.examinations (country_code, education_level_id, grade_id, subject_id, examination_type_id, status);

create index if not exists examinations_status_updated_idx
  on public.examinations (status, updated_at desc);

drop trigger if exists examinations_set_updated_at on public.examinations;
create trigger examinations_set_updated_at
  before update on public.examinations
  for each row execute function public.set_updated_at();

alter table public.examinations enable row level security;
revoke all on public.examinations from public, anon, authenticated;
grant select, insert, update, delete on public.examinations to authenticated;

drop policy if exists "Authorized staff and published readers view examinations" on public.examinations;
create policy "Authorized staff and published readers view examinations"
  on public.examinations for select to authenticated
  using (
    (is_published = true and status in ('published', 'active', 'completed', 'results_released'))
    or author_id = auth.uid()
    or public.can_author_lesson(country_code)
    or public.can_review_lesson(country_code)
    or public.can_publish_lesson(country_code)
  );

drop policy if exists "Authors manage own draft examinations" on public.examinations;
create policy "Authors manage own draft examinations"
  on public.examinations for all to authenticated
  using (
    status in ('draft', 'revision_requested')
    and is_published = false
    and (author_id = auth.uid() or author_id is null)
    and public.can_author_lesson(country_code)
  )
  with check (
    status in ('draft', 'submitted_for_review')
    and is_published = false
    and (author_id = auth.uid() or author_id is null)
    and public.can_author_lesson(country_code)
  );

drop policy if exists "Publishers manage examinations" on public.examinations;
create policy "Publishers manage examinations"
  on public.examinations for all to authenticated
  using (public.can_publish_lesson(country_code))
  with check (public.can_publish_lesson(country_code));

-- ============================================================================
-- 2. Table: public.examination_sections (Blueprint structure)
-- ============================================================================
create table if not exists public.examination_sections (
  id uuid primary key default gen_random_uuid(),
  examination_id uuid not null references public.examinations (id) on delete cascade,
  section_code text not null check (char_length(btrim(section_code)) between 1 and 12),
  title text not null check (char_length(btrim(title)) between 2 and 160),
  question_format text not null check (question_format in (
    'multiple_choice',
    'matching',
    'fill_in_the_blank',
    'short_answer',
    'comprehension',
    'writing',
    'true_false',
    'sentence_construction',
    'ordering',
    'word_completion',
    'image_based',
    'audio_based',
    'oral_assessment',
    'essay'
  )),
  instructions text not null default '',
  question_count integer not null default 1 check (question_count between 1 and 200),
  marks_allocated numeric not null default 1 check (marks_allocated > 0 and marks_allocated <= 500),
  display_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (examination_id, section_code)
);

create index if not exists examination_sections_exam_order_idx
  on public.examination_sections (examination_id, display_order asc);

drop trigger if exists examination_sections_set_updated_at on public.examination_sections;
create trigger examination_sections_set_updated_at
  before update on public.examination_sections
  for each row execute function public.set_updated_at();

alter table public.examination_sections enable row level security;
revoke all on public.examination_sections from public, anon, authenticated;
grant select, insert, update, delete on public.examination_sections to authenticated;

drop policy if exists "Examination sections follow parent examination visibility" on public.examination_sections;
create policy "Examination sections follow parent examination visibility"
  on public.examination_sections for select to authenticated
  using (
    exists (
      select 1 from public.examinations e
      where e.id = examination_sections.examination_id
        and (
          (e.is_published = true and e.status in ('published', 'active', 'completed', 'results_released'))
          or e.author_id = auth.uid()
          or public.can_author_lesson(e.country_code)
          or public.can_review_lesson(e.country_code)
          or public.can_publish_lesson(e.country_code)
        )
    )
  );

drop policy if exists "Authorized staff manage examination sections" on public.examination_sections;
create policy "Authorized staff manage examination sections"
  on public.examination_sections for all to authenticated
  using (
    exists (
      select 1 from public.examinations e
      where e.id = examination_sections.examination_id
        and (
          public.can_publish_lesson(e.country_code)
          or (e.status in ('draft', 'revision_requested') and e.author_id = auth.uid() and public.can_author_lesson(e.country_code))
        )
    )
  )
  with check (
    exists (
      select 1 from public.examinations e
      where e.id = examination_sections.examination_id
        and (
          public.can_publish_lesson(e.country_code)
          or (e.status in ('draft', 'revision_requested') and e.author_id = auth.uid() and public.can_author_lesson(e.country_code))
        )
    )
  );

-- ============================================================================
-- 3. Table: public.examination_competencies (Official curriculum coverage)
-- ============================================================================
create table if not exists public.examination_competencies (
  id uuid primary key default gen_random_uuid(),
  examination_id uuid not null references public.examinations (id) on delete cascade,
  main_competence_id uuid not null references public.curriculum_main_competences (id) on delete restrict,
  specific_competence_id uuid not null references public.curriculum_specific_competences (id) on delete restrict,
  allocated_marks numeric not null default 0 check (allocated_marks >= 0 and allocated_marks <= 500),
  target_question_count integer not null default 1 check (target_question_count >= 0 and target_question_count <= 200),
  notes text not null default '',
  created_at timestamptz not null default now(),
  unique (examination_id, specific_competence_id)
);

create index if not exists examination_competencies_exam_idx
  on public.examination_competencies (examination_id);

alter table public.examination_competencies enable row level security;
revoke all on public.examination_competencies from public, anon, authenticated;
grant select, insert, update, delete on public.examination_competencies to authenticated;

drop policy if exists "Examination competencies follow parent examination visibility" on public.examination_competencies;
create policy "Examination competencies follow parent examination visibility"
  on public.examination_competencies for select to authenticated
  using (
    exists (
      select 1 from public.examinations e
      where e.id = examination_competencies.examination_id
        and (
          (e.is_published = true and e.status in ('published', 'active', 'completed', 'results_released'))
          or e.author_id = auth.uid()
          or public.can_author_lesson(e.country_code)
          or public.can_review_lesson(e.country_code)
          or public.can_publish_lesson(e.country_code)
        )
    )
  );

drop policy if exists "Authorized staff manage examination competencies" on public.examination_competencies;
create policy "Authorized staff manage examination competencies"
  on public.examination_competencies for all to authenticated
  using (
    exists (
      select 1 from public.examinations e
      where e.id = examination_competencies.examination_id
        and (
          public.can_publish_lesson(e.country_code)
          or (e.status in ('draft', 'revision_requested') and e.author_id = auth.uid() and public.can_author_lesson(e.country_code))
        )
    )
  )
  with check (
    exists (
      select 1 from public.examinations e
      where e.id = examination_competencies.examination_id
        and (
          public.can_publish_lesson(e.country_code)
          or (e.status in ('draft', 'revision_requested') and e.author_id = auth.uid() and public.can_author_lesson(e.country_code))
        )
    )
  );

-- ============================================================================
-- 4. Table: public.examination_review_events (Immutable audit log)
-- ============================================================================
create table if not exists public.examination_review_events (
  id uuid primary key default gen_random_uuid(),
  examination_id uuid not null references public.examinations (id) on delete cascade,
  action text not null check (action in (
    'draft_saved',
    'submitted_for_review',
    'review_started',
    'revision_requested',
    'approved',
    'published',
    'activated',
    'completed',
    'results_released',
    'archived'
  )),
  from_status text,
  to_status text not null,
  version_number integer not null default 1,
  comments text not null default '',
  actor_user_id uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists examination_review_events_exam_created_idx
  on public.examination_review_events (examination_id, created_at desc);

create or replace function public.prevent_examination_review_event_mutation()
returns trigger
language plpgsql
as $$
begin
  raise exception 'Immutable audit log violation: examination_review_events cannot be modified or deleted'
    using errcode = '42501';
end;
$$;

drop trigger if exists examination_review_events_immutable on public.examination_review_events;
create trigger examination_review_events_immutable
  before update or delete on public.examination_review_events
  for each row execute function public.prevent_examination_review_event_mutation();

alter table public.examination_review_events enable row level security;
revoke all on public.examination_review_events from public, anon, authenticated;
grant select, insert on public.examination_review_events to authenticated;

drop policy if exists "Authorized staff read examination review events" on public.examination_review_events;
create policy "Authorized staff read examination review events"
  on public.examination_review_events for select to authenticated
  using (
    exists (
      select 1 from public.examinations e
      where e.id = examination_review_events.examination_id
        and (
          e.author_id = auth.uid()
          or public.can_author_lesson(e.country_code)
          or public.can_review_lesson(e.country_code)
          or public.can_publish_lesson(e.country_code)
        )
    )
  );

-- ============================================================================
-- 5. RPC: save_exam_v2_examination
--    Atomically saves/updates an examination, its blueprint sections, and
--    curriculum competency coverage with strict relational validation.
-- ============================================================================
create or replace function public.save_exam_v2_examination(
  p_country_code text,
  p_education_level_id uuid,
  p_grade_id uuid,
  p_subject_id uuid,
  p_examination_type_id uuid,
  p_title text,
  p_academic_year integer default null,
  p_academic_term text default 'Term I',
  p_examination_date date default null,
  p_duration_minutes integer default 90,
  p_language_code text default 'en',
  p_instructions text default 'Read all questions carefully. Answer all questions unless otherwise instructed.',
  p_delivery_mode text default 'hybrid',
  p_sections jsonb default '[]'::jsonb,
  p_competencies jsonb default '[]'::jsonb,
  p_examination_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_country text := nullif(upper(btrim(coalesce(p_country_code, ''))), '');
  v_cur_id uuid;
  v_ver_id uuid;
  v_lvl_code text;
  v_exam_id uuid := p_examination_id;
  v_existing_status text;
  v_existing_author uuid;
  v_version integer := 1;
  v_total_marks numeric := 0;
  v_sec jsonb;
  v_sec_idx integer := 0;
  v_comp jsonb;
  v_sc_id uuid;
  v_mc_id uuid;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  if v_country is null then
    raise exception 'Country code is required' using errcode = '22023';
  end if;

  if not (public.can_author_lesson(v_country) or public.can_publish_lesson(v_country)) then
    raise exception 'Permission denied: creating or editing examinations requires authorized academic staff role'
      using errcode = '42501';
  end if;

  -- Validate Country -> Curriculum -> Education Level -> Grade -> Subject chain
  select c.id, el.code
  into v_cur_id, v_lvl_code
  from public.subjects s
  join public.education_grades eg on eg.id = s.grade_id
  join public.education_levels el on el.id = s.education_level_id
  join public.curricula c on c.id = s.curriculum_id
  where s.id = p_subject_id
    and s.grade_id = p_grade_id
    and s.education_level_id = p_education_level_id
    and eg.education_level_id = p_education_level_id
    and upper(c.country_code) = v_country
    and s.is_published = true;

  if not found then
    raise exception 'Academic hierarchy mismatch: subject, grade, education level, and country do not form a valid curriculum chain'
      using errcode = '22023';
  end if;

  -- Validate Examination Type belongs to Country (and Level if scoped)
  if not exists (
    select 1 from public.examination_types et
    where et.id = p_examination_type_id
      and upper(et.country_code) = v_country
      and et.is_active = true
      and (et.education_level_code is null or upper(et.education_level_code) = upper(v_lvl_code))
  ) then
    raise exception 'Academic hierarchy mismatch: examination type is not valid for country % and education level %', v_country, v_lvl_code
      using errcode = '22023';
  end if;

  -- Resolve approved/published curriculum version
  select cv.id into v_ver_id
  from public.curriculum_versions cv
  where cv.curriculum_id = v_cur_id
  order by
    case cv.status when 'published' then 1 when 'approved' then 2 else 3 end,
    cv.created_at desc
  limit 1;

  -- Compute total_marks strictly from sections array
  if jsonb_typeof(coalesce(p_sections, '[]'::jsonb)) <> 'array' then
    raise exception 'p_sections must be a JSON array' using errcode = '22023';
  end if;

  for v_sec in select * from jsonb_array_elements(coalesce(p_sections, '[]'::jsonb))
  loop
    v_total_marks := v_total_marks + coalesce((v_sec ->> 'marks_allocated')::numeric, 0);
  end loop;

  if v_exam_id is not null then
    select status, author_id, version_number
    into v_existing_status, v_existing_author, v_version
    from public.examinations
    where id = v_exam_id;

    if not found then
      raise exception 'Examination % not found', v_exam_id using errcode = '22023';
    end if;

    if v_existing_status not in ('draft', 'revision_requested') and not public.can_publish_lesson(v_country) then
      raise exception 'Examination in status % cannot be edited directly', v_existing_status using errcode = '42501';
    end if;

    if v_existing_author is not null and v_existing_author <> v_uid and not public.can_publish_lesson(v_country) then
      raise exception 'Permission denied: only the author or a curriculum administrator can edit this draft'
        using errcode = '42501';
    end if;

    v_version := v_version + 1;

    update public.examinations
    set title = btrim(p_title),
        academic_year = coalesce(p_academic_year, extract(year from now())::integer),
        academic_term = coalesce(nullif(btrim(p_academic_term), ''), 'Term I'),
        examination_date = p_examination_date,
        duration_minutes = coalesce(p_duration_minutes, 90),
        total_marks = v_total_marks,
        language_code = coalesce(nullif(btrim(p_language_code), ''), 'en'),
        instructions = coalesce(p_instructions, ''),
        delivery_mode = coalesce(nullif(btrim(p_delivery_mode), ''), 'hybrid'),
        version_number = v_version,
        updated_at = now()
    where id = v_exam_id;
  else
    insert into public.examinations (
      country_code, curriculum_id, curriculum_version_id,
      education_level_id, grade_id, subject_id, examination_type_id,
      title, academic_year, academic_term, examination_date,
      duration_minutes, total_marks, language_code, instructions,
      delivery_mode, status, is_published, version_number, author_id
    ) values (
      v_country, v_cur_id, v_ver_id,
      p_education_level_id, p_grade_id, p_subject_id, p_examination_type_id,
      btrim(p_title),
      coalesce(p_academic_year, extract(year from now())::integer),
      coalesce(nullif(btrim(p_academic_term), ''), 'Term I'),
      p_examination_date,
      coalesce(p_duration_minutes, 90),
      v_total_marks,
      coalesce(nullif(btrim(p_language_code), ''), 'en'),
      coalesce(p_instructions, ''),
      coalesce(nullif(btrim(p_delivery_mode), ''), 'hybrid'),
      'draft', false, 1, v_uid
    )
    returning id into v_exam_id;
  end if;

  -- Replace blueprint sections atomically
  delete from public.examination_sections where examination_id = v_exam_id;
  v_sec_idx := 0;
  for v_sec in select * from jsonb_array_elements(coalesce(p_sections, '[]'::jsonb))
  loop
    v_sec_idx := v_sec_idx + 1;
    insert into public.examination_sections (
      examination_id, section_code, title, question_format,
      instructions, question_count, marks_allocated, display_order
    ) values (
      v_exam_id,
      coalesce(nullif(btrim(v_sec ->> 'section_code'), ''), chr(64 + least(v_sec_idx, 26))),
      btrim(coalesce(v_sec ->> 'title', 'Section ' || v_sec_idx)),
      coalesce(nullif(btrim(v_sec ->> 'question_format'), ''), 'multiple_choice'),
      coalesce(v_sec ->> 'instructions', ''),
      greatest(1, coalesce((v_sec ->> 'question_count')::integer, 1)),
      greatest(1, coalesce((v_sec ->> 'marks_allocated')::numeric, 1)),
      coalesce((v_sec ->> 'display_order')::integer, v_sec_idx)
    );
  end loop;

  -- Replace curriculum competency coverage atomically (strictly validating subject ownership!)
  delete from public.examination_competencies where examination_id = v_exam_id;
  if jsonb_typeof(coalesce(p_competencies, '[]'::jsonb)) = 'array' then
    for v_comp in select * from jsonb_array_elements(coalesce(p_competencies, '[]'::jsonb))
    loop
      v_sc_id := (v_comp ->> 'specific_competence_id')::uuid;
      select sc.main_competence_id into v_mc_id
      from public.curriculum_specific_competences sc
      where sc.id = v_sc_id
        and sc.subject_id = p_subject_id
        and sc.is_published = true;

      if not found then
        raise exception 'Competency mismatch: specific competence % does not belong to subject %', v_sc_id, p_subject_id
          using errcode = '22023';
      end if;

      insert into public.examination_competencies (
        examination_id, main_competence_id, specific_competence_id,
        allocated_marks, target_question_count, notes
      ) values (
        v_exam_id, v_mc_id, v_sc_id,
        greatest(0, coalesce((v_comp ->> 'allocated_marks')::numeric, 0)),
        greatest(0, coalesce((v_comp ->> 'target_question_count')::integer, 1)),
        coalesce(v_comp ->> 'notes', '')
      )
      on conflict (examination_id, specific_competence_id) do update
        set allocated_marks = excluded.allocated_marks,
            target_question_count = excluded.target_question_count,
            notes = excluded.notes;
    end loop;
  end if;

  insert into public.examination_review_events (
    examination_id, action, from_status, to_status, version_number, comments, actor_user_id
  ) values (
    v_exam_id,
    'draft_saved',
    v_existing_status,
    coalesce(v_existing_status, 'draft'),
    v_version,
    'Saved examination metadata, blueprint sections, and curriculum coverage.',
    v_uid
  );

  return jsonb_build_object(
    'id', v_exam_id,
    'status', coalesce(v_existing_status, 'draft'),
    'is_published', false,
    'total_marks', v_total_marks,
    'version_number', v_version
  );
end;
$$;

-- ============================================================================
-- 6. RPC: list_exam_v2_examinations
--    Returns real DB-derived examinations + summary counts for the context
-- ============================================================================
create or replace function public.list_exam_v2_examinations(
  p_country_code text default null,
  p_education_level_id uuid default null,
  p_grade_id uuid default null,
  p_subject_id uuid default null,
  p_examination_type_id uuid default null,
  p_status text default null,
  p_search text default null,
  p_limit integer default 20,
  p_offset integer default 0
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
  v_status text := nullif(lower(btrim(coalesce(p_status, ''))), '');
  v_search text := nullif(btrim(coalesce(p_search, '')), '');
  v_limit integer := greatest(1, least(coalesce(p_limit, 20), 100));
  v_offset integer := greatest(0, coalesce(p_offset, 0));
  v_total integer := 0;
  v_draft integer := 0;
  v_review integer := 0;
  v_approved integer := 0;
  v_published integer := 0;
  v_items jsonb := '[]'::jsonb;
begin
  with scoped as (
    select
      e.id,
      e.title,
      e.country_code,
      co.display_name as country_name,
      e.curriculum_id,
      c.name as curriculum_name,
      cv.version_code as curriculum_version_code,
      e.education_level_id,
      el.name as education_level_name,
      e.grade_id,
      eg.name as grade_name,
      e.subject_id,
      s.name as subject_name,
      e.examination_type_id,
      et.name as examination_type_name,
      e.academic_year,
      e.academic_term,
      e.examination_date,
      e.duration_minutes,
      e.total_marks,
      e.language_code,
      e.delivery_mode,
      e.status,
      e.is_published,
      e.version_number,
      e.author_id,
      e.review_notes,
      e.updated_at,
      (select count(*)::integer from public.examination_sections es where es.examination_id = e.id) as section_count,
      (select count(*)::integer from public.examination_competencies ec where ec.examination_id = e.id) as competency_count
    from public.examinations e
    join public.countries co on co.country_code = e.country_code
    join public.curricula c on c.id = e.curriculum_id
    left join public.curriculum_versions cv on cv.id = e.curriculum_version_id
    join public.education_levels el on el.id = e.education_level_id
    join public.education_grades eg on eg.id = e.grade_id
    join public.subjects s on s.id = e.subject_id
    join public.examination_types et on et.id = e.examination_type_id
    where (
        (e.is_published = true and e.status in ('published', 'active', 'completed', 'results_released'))
        or (v_uid is not null and (
          e.author_id = v_uid
          or public.can_author_lesson(e.country_code)
          or public.can_review_lesson(e.country_code)
          or public.can_publish_lesson(e.country_code)
        ))
      )
      and (v_country is null or upper(e.country_code) = v_country)
      and (p_education_level_id is null or e.education_level_id = p_education_level_id)
      and (p_grade_id is null or e.grade_id = p_grade_id)
      and (p_subject_id is null or e.subject_id = p_subject_id)
      and (p_examination_type_id is null or e.examination_type_id = p_examination_type_id)
  ),
  filtered as (
    select * from scoped
    where (v_status is null or v_status = 'all' or status = v_status)
      and (v_search is null or title ilike '%' || v_search || '%' or academic_term ilike '%' || v_search || '%')
  )
  select
    (select count(*)::integer from scoped),
    (select count(*) filter (where status in ('draft', 'revision_requested'))::integer from scoped),
    (select count(*) filter (where status in ('submitted_for_review', 'under_review'))::integer from scoped),
    (select count(*) filter (where status = 'approved')::integer from scoped),
    (select count(*) filter (where status in ('published', 'active', 'completed', 'results_released'))::integer from scoped),
    coalesce(
      (
        select jsonb_agg(to_jsonb(p))
        from (
          select * from filtered
          order by updated_at desc
          limit v_limit offset v_offset
        ) p
      ),
      '[]'::jsonb
    )
  into v_total, v_draft, v_review, v_approved, v_published, v_items;

  return jsonb_build_object(
    'summary', jsonb_build_object(
      'total_count', v_total,
      'draft_count', v_draft,
      'under_review_count', v_review,
      'approved_count', v_approved,
      'published_count', v_published
    ),
    'items', v_items
  );
end;
$$;

-- ============================================================================
-- 7. RPC: get_exam_v2_examination_detail
-- ============================================================================
create or replace function public.get_exam_v2_examination_detail(
  p_examination_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_exam record;
begin
  select e.* into v_exam
  from public.examinations e
  where e.id = p_examination_id;

  if not found then
    raise exception 'Examination % not found', p_examination_id using errcode = '22023';
  end if;

  if not (
    (v_exam.is_published = true and v_exam.status in ('published', 'active', 'completed', 'results_released'))
    or (v_uid is not null and (
      v_exam.author_id = v_uid
      or public.can_author_lesson(v_exam.country_code)
      or public.can_review_lesson(v_exam.country_code)
      or public.can_publish_lesson(v_exam.country_code)
    ))
  ) then
    raise exception 'Permission denied' using errcode = '42501';
  end if;

  return jsonb_build_object(
    'examination', to_jsonb(v_exam),
    'sections', coalesce(
      (
        select jsonb_agg(to_jsonb(es) order by es.display_order asc, es.section_code asc)
        from public.examination_sections es
        where es.examination_id = p_examination_id
      ),
      '[]'::jsonb
    ),
    'competencies', coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'id', ec.id,
            'main_competence_id', ec.main_competence_id,
            'main_competence_code', mc.code,
            'main_competence_title', mc.title,
            'specific_competence_id', ec.specific_competence_id,
            'specific_competence_code', sc.code,
            'specific_competence_title', sc.title,
            'allocated_marks', ec.allocated_marks,
            'target_question_count', ec.target_question_count,
            'notes', ec.notes
          )
          order by mc.display_order asc, sc.display_order asc
        )
        from public.examination_competencies ec
        join public.curriculum_main_competences mc on mc.id = ec.main_competence_id
        join public.curriculum_specific_competences sc on sc.id = ec.specific_competence_id
        where ec.examination_id = p_examination_id
      ),
      '[]'::jsonb
    ),
    'review_events', coalesce(
      (
        select jsonb_agg(to_jsonb(ev) order by ev.created_at desc)
        from public.examination_review_events ev
        where ev.examination_id = p_examination_id
      ),
      '[]'::jsonb
    )
  );
end;
$$;

-- ============================================================================
-- 8. RPC: transition_exam_v2_status
--    Enforces blueprint completeness, two-party review, and RBAC transitions
-- ============================================================================
create or replace function public.transition_exam_v2_status(
  p_examination_id uuid,
  p_action text,
  p_comments text default ''
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_exam record;
  v_action text := lower(btrim(coalesce(p_action, '')));
  v_to_status text;
  v_sec_count integer := 0;
  v_comp_count integer := 0;
  v_is_pub boolean;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select * into v_exam from public.examinations where id = p_examination_id;
  if not found then
    raise exception 'Examination % not found', p_examination_id using errcode = '22023';
  end if;

  v_is_pub := v_exam.is_published;

  if v_action = 'submit_for_review' then
    if not (public.can_author_lesson(v_exam.country_code) or public.can_publish_lesson(v_exam.country_code)) then
      raise exception 'Permission denied: submitting examination requires authoring role' using errcode = '42501';
    end if;
    if v_exam.status not in ('draft', 'revision_requested') then
      raise exception 'Only draft or revision_requested examinations can be submitted for review' using errcode = '22023';
    end if;

    select count(*)::integer into v_sec_count from public.examination_sections where examination_id = p_examination_id;
    select count(*)::integer into v_comp_count from public.examination_competencies where examination_id = p_examination_id;

    if v_sec_count < 1 or coalesce(v_exam.total_marks, 0) <= 0 then
      raise exception 'Incomplete examination blueprint: at least one section with marks > 0 is required before submission'
        using errcode = '22023';
    end if;
    if v_comp_count < 1 then
      raise exception 'Incomplete curriculum coverage: at least one official specific competence must be mapped before submission'
        using errcode = '22023';
    end if;

    v_to_status := 'submitted_for_review';
    update public.examinations
    set status = v_to_status, submitted_at = now(), updated_at = now()
    where id = p_examination_id;

  elsif v_action = 'request_revision' then
    if not (public.can_review_lesson(v_exam.country_code) or public.can_publish_lesson(v_exam.country_code)) then
      raise exception 'Permission denied: requesting revisions requires academic reviewer role' using errcode = '42501';
    end if;
    if nullif(btrim(coalesce(p_comments, '')), '') is null then
      raise exception 'Revision comments are required when requesting revisions' using errcode = '22023';
    end if;
    v_to_status := 'revision_requested';
    update public.examinations
    set status = v_to_status, reviewer_id = v_uid, review_notes = btrim(p_comments), updated_at = now()
    where id = p_examination_id;

  elsif v_action = 'approve' then
    if not (public.can_approve_lesson(v_exam.country_code) or public.can_review_lesson(v_exam.country_code)) then
      raise exception 'Permission denied: approving examinations requires academic reviewer or approver role' using errcode = '42501';
    end if;
    if v_exam.author_id = v_uid and not public.has_role('super_admin') and not public.is_current_super_admin() then
      raise exception 'Two-party review violation: examination author cannot approve their own examination'
        using errcode = '42501';
    end if;
    if v_exam.status not in ('submitted_for_review', 'under_review') then
      raise exception 'Only submitted or under-review examinations can be approved' using errcode = '22023';
    end if;
    v_to_status := 'approved';
    update public.examinations
    set status = v_to_status, reviewer_id = coalesce(reviewer_id, v_uid),
        approved_by = v_uid, approved_at = now(),
        review_notes = coalesce(nullif(btrim(p_comments), ''), review_notes),
        updated_at = now()
    where id = p_examination_id;

  elsif v_action = 'publish' then
    if not public.can_publish_lesson(v_exam.country_code) then
      raise exception 'Permission denied: publishing examinations requires curriculum_admin or super_admin role'
        using errcode = '42501';
    end if;
    if v_exam.status <> 'approved' then
      raise exception 'Only approved examinations can be published' using errcode = '22023';
    end if;
    v_to_status := 'published';
    v_is_pub := true;
    update public.examinations
    set status = v_to_status, is_published = true,
        published_by = v_uid, published_at = now(), updated_at = now()
    where id = p_examination_id;

  else
    raise exception 'Unsupported examination workflow action: %', v_action using errcode = '22023';
  end if;

  insert into public.examination_review_events (
    examination_id, action, from_status, to_status, version_number, comments, actor_user_id
  ) values (
    p_examination_id,
    case v_action
      when 'submit_for_review' then 'submitted_for_review'
      when 'request_revision' then 'revision_requested'
      when 'approve' then 'approved'
      when 'publish' then 'published'
      else v_action
    end,
    v_exam.status,
    v_to_status,
    v_exam.version_number,
    coalesce(btrim(p_comments), ''),
    v_uid
  );

  return jsonb_build_object(
    'id', p_examination_id,
    'status', v_to_status,
    'is_published', v_is_pub
  );
end;
$$;

revoke all on function public.save_exam_v2_examination(text, uuid, uuid, uuid, uuid, text, integer, text, date, integer, text, text, text, jsonb, jsonb, uuid) from public, anon;
grant execute on function public.save_exam_v2_examination(text, uuid, uuid, uuid, uuid, text, integer, text, date, integer, text, text, text, jsonb, jsonb, uuid) to authenticated, service_role;

revoke all on function public.list_exam_v2_examinations(text, uuid, uuid, uuid, uuid, text, text, integer, integer) from public;
grant execute on function public.list_exam_v2_examinations(text, uuid, uuid, uuid, uuid, text, text, integer, integer) to anon, authenticated, service_role;

revoke all on function public.get_exam_v2_examination_detail(uuid) from public;
grant execute on function public.get_exam_v2_examination_detail(uuid) to authenticated, service_role;

revoke all on function public.transition_exam_v2_status(uuid, text, text) from public, anon;
grant execute on function public.transition_exam_v2_status(uuid, text, text) to authenticated, service_role;

commit;
