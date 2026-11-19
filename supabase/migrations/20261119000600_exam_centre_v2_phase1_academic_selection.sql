-- ============================================================================
-- LearnTZ Examination Centre 2.0 — Phase 1: Academic Selection & Curriculum Integration
-- Migration: 20261119000600_exam_centre_v2_phase1_academic_selection.sql
--
-- Reuses existing LearnTZ curriculum tables (countries, curricula,
-- curriculum_versions, education_levels, education_grades, subjects,
-- curriculum_main_competences, curriculum_specific_competences, question_bank).
-- Zero hardcoded curriculum/grade/subject UUIDs; 100% natural-key resolution.
-- ============================================================================

begin;

-- ============================================================================
-- 1. Table: public.examination_types
--    Country- and education-level-configurable examination types
--    (Terminal, Mid-Term, Annual, Monthly Test, Mock, Diagnostic, National Practice)
-- ============================================================================
create table if not exists public.examination_types (
  id uuid primary key default gen_random_uuid(),
  country_code text not null references public.countries (country_code) on delete restrict,
  education_level_code text, -- NULL applies to all education levels in the country; or e.g. 'PRIMARY', 'SECONDARY'
  code text not null check (char_length(btrim(code)) between 2 and 40),
  name text not null check (char_length(btrim(name)) between 2 and 120),
  description text not null default '',
  default_duration_minutes integer not null default 90 check (default_duration_minutes between 15 and 360),
  default_total_marks numeric not null default 50 check (default_total_marks between 1 and 500),
  allows_online_delivery boolean not null default true,
  allows_printed_delivery boolean not null default true,
  requires_academic_review boolean not null default true,
  display_order integer not null default 0,
  is_active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb check (jsonb_typeof(metadata) = 'object'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists examination_types_natural_key_uidx
  on public.examination_types (country_code, coalesce(education_level_code, '*'), code);

create index if not exists examination_types_country_active_idx
  on public.examination_types (country_code, is_active, display_order);

drop trigger if exists examination_types_set_updated_at on public.examination_types;
create trigger examination_types_set_updated_at
  before update on public.examination_types
  for each row execute function public.set_updated_at();

alter table public.examination_types enable row level security;
revoke all on public.examination_types from public, anon, authenticated;
grant select on public.examination_types to anon, authenticated;
grant insert, update, delete on public.examination_types to authenticated;

drop policy if exists "Anyone reads active examination types" on public.examination_types;
create policy "Anyone reads active examination types"
  on public.examination_types for select
  using (
    is_active = true
    or public.has_role('super_admin')
    or public.has_role('curriculum_admin', examination_types.country_code)
  );

drop policy if exists "Admins manage examination types" on public.examination_types;
create policy "Admins manage examination types"
  on public.examination_types for all to authenticated
  using (
    public.has_role('super_admin')
    or public.has_role('curriculum_admin', examination_types.country_code)
    or public.is_current_super_admin()
  )
  with check (
    public.has_role('super_admin')
    or public.has_role('curriculum_admin', examination_types.country_code)
    or public.is_current_super_admin()
  );

-- Seed canonical examination types dynamically for all enabled countries (no hardcoded UUIDs)
do $$
declare
  v_country record;
begin
  for v_country in
    select country_code from public.countries where is_enabled = true
  loop
    insert into public.examination_types (
      country_code, education_level_code, code, name, description,
      default_duration_minutes, default_total_marks,
      allows_online_delivery, allows_printed_delivery, requires_academic_review,
      display_order, is_active, metadata
    ) values
      (
        v_country.country_code, null, 'TERMINAL', 'Terminal Examination',
        'End-of-term summative assessment measuring mastery of competencies covered during the academic term.',
        90, 50, true, true, true, 1, true,
        '{"assessment_category":"summative","recommended_sections":["Multiple Choice","Matching","Fill in the Blanks","Short Answers","Comprehension","Writing"]}'::jsonb
      ),
      (
        v_country.country_code, null, 'MID_TERM', 'Mid-Term Examination',
        'Mid-term progress examination evaluating learner mastery across the first half of the term.',
        60, 50, true, true, true, 2, true,
        '{"assessment_category":"formative_summative"}'::jsonb
      ),
      (
        v_country.country_code, null, 'ANNUAL', 'Annual Examination',
        'Comprehensive end-of-year examination covering the full academic year curriculum competencies.',
        120, 100, true, true, true, 3, true,
        '{"assessment_category":"summative"}'::jsonb
      ),
      (
        v_country.country_code, null, 'MONTHLY_TEST', 'Monthly Test',
        'Focused monthly competency check to monitor ongoing classroom progress.',
        45, 25, true, true, true, 4, true,
        '{"assessment_category":"formative"}'::jsonb
      ),
      (
        v_country.country_code, null, 'MOCK', 'Mock Examination',
        'Simulated examination modeled after national assessment standards for readiness evaluation.',
        120, 100, true, true, true, 5, true,
        '{"assessment_category":"simulation"}'::jsonb
      ),
      (
        v_country.country_code, null, 'DIAGNOSTIC', 'Diagnostic Assessment',
        'Baseline competency assessment identifying learner strengths and learning gaps prior to instruction.',
        45, 30, true, true, true, 6, true,
        '{"assessment_category":"diagnostic"}'::jsonb
      )
    on conflict (country_code, coalesce(education_level_code, '*'), code) do update
      set name = excluded.name,
          description = excluded.description,
          default_duration_minutes = excluded.default_duration_minutes,
          default_total_marks = excluded.default_total_marks,
          display_order = excluded.display_order,
          is_active = true,
          updated_at = now();
  end loop;
end $$;

-- ============================================================================
-- 2. RPC: Step 1 — get_exam_v2_countries
--    Returns enabled countries with their active national curriculum & version
-- ============================================================================
create or replace function public.get_exam_v2_countries()
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  return coalesce(
    (
      select jsonb_agg(
        jsonb_build_object(
          'country_code', co.country_code,
          'display_name', co.display_name,
          'curriculum_id', c.id,
          'curriculum_code', c.code,
          'curriculum_name', c.name,
          'authority_name', ca.name,
          'authority_code', ca.code,
          'curriculum_version_id', cv.id,
          'curriculum_version_code', cv.version_code,
          'curriculum_version_name', coalesce(cv.display_name, cv.official_document_version)
        )
        order by (case when co.country_code = 'TZ' then 0 else 1 end), co.display_name asc
      )
      from public.countries co
      join lateral (
        select cur.*
        from public.curricula cur
        where cur.country_code = co.country_code
          and cur.is_enabled = true
        order by cur.created_at asc
        limit 1
      ) c on true
      left join public.curriculum_authorities ca on ca.id = c.authority_id
      left join lateral (
        select v.*
        from public.curriculum_versions v
        where v.curriculum_id = c.id
        order by
          case v.status when 'published' then 1 when 'approved' then 2 else 3 end,
          v.created_at desc
        limit 1
      ) cv on true
      where co.is_enabled = true
    ),
    '[]'::jsonb
  );
end;
$$;

-- ============================================================================
-- 3. RPC: Step 2 — get_exam_v2_education_levels
--    Returns enabled education levels for the selected country's curriculum
-- ============================================================================
create or replace function public.get_exam_v2_education_levels(
  p_country_code text
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_country text := nullif(upper(btrim(coalesce(p_country_code, ''))), '');
begin
  if v_country is null then
    return '[]'::jsonb;
  end if;

  return coalesce(
    (
      select jsonb_agg(
        jsonb_build_object(
          'id', el.id,
          'curriculum_id', el.curriculum_id,
          'country_code', c.country_code,
          'code', el.code,
          'name', el.name,
          'sequence', el.sequence,
          'grade_count', (
            select count(*)::integer
            from public.education_grades eg
            where eg.education_level_id = el.id
              and eg.is_enabled = true
          )
        )
        order by el.sequence asc, el.name asc
      )
      from public.education_levels el
      join public.curricula c on c.id = el.curriculum_id
      where c.country_code = v_country
        and c.is_enabled = true
        and el.is_enabled = true
    ),
    '[]'::jsonb
  );
end;
$$;

-- ============================================================================
-- 4. RPC: Step 3 — get_exam_v2_grades
--    Returns enabled grades/forms/classes for the selected education level
-- ============================================================================
create or replace function public.get_exam_v2_grades(
  p_curriculum_id uuid,
  p_education_level_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  if p_curriculum_id is null or p_education_level_id is null then
    return '[]'::jsonb;
  end if;

  return coalesce(
    (
      select jsonb_agg(
        jsonb_build_object(
          'id', eg.id,
          'curriculum_id', eg.curriculum_id,
          'education_level_id', eg.education_level_id,
          'code', eg.code,
          'name', eg.name,
          'sequence', eg.sequence,
          'subject_count', (
            select count(*)::integer
            from public.subjects s
            where s.grade_id = eg.id
              and s.curriculum_id = eg.curriculum_id
              and s.is_published = true
          )
        )
        order by eg.sequence asc, eg.name asc
      )
      from public.education_grades eg
      where eg.curriculum_id = p_curriculum_id
        and eg.education_level_id = p_education_level_id
        and eg.is_enabled = true
    ),
    '[]'::jsonb
  );
end;
$$;

-- ============================================================================
-- 5. RPC: Step 4 — get_exam_v2_subjects
--    Returns published subjects strictly scoped to the selected grade
-- ============================================================================
create or replace function public.get_exam_v2_subjects(
  p_curriculum_id uuid,
  p_education_level_id uuid,
  p_grade_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  if p_curriculum_id is null or p_education_level_id is null or p_grade_id is null then
    return '[]'::jsonb;
  end if;

  return coalesce(
    (
      select jsonb_agg(
        jsonb_build_object(
          'id', s.id,
          'curriculum_id', s.curriculum_id,
          'education_level_id', s.education_level_id,
          'grade_id', s.grade_id,
          'country_code', s.country_code,
          'code', s.code,
          'name', s.name,
          'official_name', s.official_name,
          'language', coalesce(s.language, 'en'),
          'main_competence_count', (
            select count(*)::integer
            from public.curriculum_main_competences mc
            where mc.subject_id = s.id and mc.is_published = true
          ),
          'specific_competence_count', (
            select count(*)::integer
            from public.curriculum_specific_competences sc
            where sc.subject_id = s.id and sc.is_published = true
          )
        )
        order by s.display_order asc, s.name asc
      )
      from public.subjects s
      where s.curriculum_id = p_curriculum_id
        and s.education_level_id = p_education_level_id
        and s.grade_id = p_grade_id
        and s.is_published = true
    ),
    '[]'::jsonb
  );
end;
$$;

-- ============================================================================
-- 6. RPC: Step 5 — get_exam_v2_examination_types
--    Returns active examination types for the selected country & level
-- ============================================================================
create or replace function public.get_exam_v2_examination_types(
  p_country_code text,
  p_education_level_id uuid default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_country text := nullif(upper(btrim(coalesce(p_country_code, ''))), '');
  v_level_code text;
begin
  if v_country is null then
    return '[]'::jsonb;
  end if;

  if p_education_level_id is not null then
    select el.code into v_level_code
    from public.education_levels el
    where el.id = p_education_level_id;
  end if;

  return coalesce(
    (
      select jsonb_agg(
        jsonb_build_object(
          'id', et.id,
          'country_code', et.country_code,
          'education_level_code', et.education_level_code,
          'code', et.code,
          'name', et.name,
          'description', et.description,
          'default_duration_minutes', et.default_duration_minutes,
          'default_total_marks', et.default_total_marks,
          'allows_online_delivery', et.allows_online_delivery,
          'allows_printed_delivery', et.allows_printed_delivery,
          'requires_academic_review', et.requires_academic_review
        )
        order by et.display_order asc, et.name asc
      )
      from public.examination_types et
      where et.country_code = v_country
        and et.is_active = true
        and (
          et.education_level_code is null
          or v_level_code is null
          or upper(et.education_level_code) = upper(v_level_code)
        )
    ),
    '[]'::jsonb
  );
end;
$$;

-- ============================================================================
-- 7. RPC: get_exam_v2_academic_context_summary
--    Validates the full 5-step relational hierarchy on the server and returns:
--    - Verified academic context & curriculum version metadata
--    - Official curriculum_main_competences & curriculum_specific_competences
--    - Real DB-derived question bank & paper counts for this exact context
-- ============================================================================
create or replace function public.get_exam_v2_academic_context_summary(
  p_country_code text,
  p_education_level_id uuid,
  p_grade_id uuid,
  p_subject_id uuid,
  p_examination_type_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_country text := nullif(upper(btrim(coalesce(p_country_code, ''))), '');
  v_country_name text;
  v_cur_id uuid;
  v_cur_code text;
  v_cur_name text;
  v_auth_name text;
  v_auth_code text;
  v_ver_id uuid;
  v_ver_code text;
  v_ver_name text;
  v_lvl_code text;
  v_lvl_name text;
  v_grd_code text;
  v_grd_name text;
  v_subj_code text;
  v_subj_name text;
  v_subj_official text;
  v_subj_lang text;
  v_type_code text;
  v_type_name text;
  v_type_desc text;
  v_type_duration integer;
  v_type_marks numeric;
  v_type_online boolean;
  v_type_printed boolean;
  v_type_review boolean;
  v_question_count integer := 0;
  v_paper_count integer := 0;
  v_lesson_count integer := 0;
begin
  if v_country is null or p_education_level_id is null or p_grade_id is null
     or p_subject_id is null or p_examination_type_id is null then
    raise exception 'All five academic context selections (country, education level, grade, subject, examination type) are required'
      using errcode = '22023';
  end if;

  -- Validate Country -> Curriculum -> Education Level -> Grade -> Subject chain
  select
    co.display_name,
    c.id, c.code, c.name,
    ca.name, ca.code,
    el.code, el.name,
    eg.code, eg.name,
    s.code, s.name, s.official_name, coalesce(s.language, 'en')
  into
    v_country_name,
    v_cur_id, v_cur_code, v_cur_name,
    v_auth_name, v_auth_code,
    v_lvl_code, v_lvl_name,
    v_grd_code, v_grd_name,
    v_subj_code, v_subj_name, v_subj_official, v_subj_lang
  from public.subjects s
  join public.education_grades eg on eg.id = s.grade_id
  join public.education_levels el on el.id = s.education_level_id
  join public.curricula c on c.id = s.curriculum_id
  join public.countries co on co.country_code = c.country_code
  left join public.curriculum_authorities ca on ca.id = c.authority_id
  where s.id = p_subject_id
    and s.grade_id = p_grade_id
    and s.education_level_id = p_education_level_id
    and eg.education_level_id = p_education_level_id
    and el.curriculum_id = c.id
    and upper(c.country_code) = v_country
    and s.is_published = true
    and eg.is_enabled = true
    and el.is_enabled = true
    and c.is_enabled = true
    and co.is_enabled = true;

  if not found then
    raise exception 'Academic hierarchy mismatch: subject, grade, education level, and country do not form a valid active curriculum chain'
      using errcode = '22023';
  end if;

  -- Validate Examination Type belongs to Country (and Education Level if scoped)
  select
    et.code, et.name, et.description,
    et.default_duration_minutes, et.default_total_marks,
    et.allows_online_delivery, et.allows_printed_delivery, et.requires_academic_review
  into
    v_type_code, v_type_name, v_type_desc,
    v_type_duration, v_type_marks,
    v_type_online, v_type_printed, v_type_review
  from public.examination_types et
  where et.id = p_examination_type_id
    and upper(et.country_code) = v_country
    and et.is_active = true
    and (et.education_level_code is null or upper(et.education_level_code) = upper(v_lvl_code));

  if not found then
    raise exception 'Academic hierarchy mismatch: examination type is not valid for country % and education level %', v_country, v_lvl_code
      using errcode = '22023';
  end if;

  -- Resolve approved/published curriculum version
  select cv.id, cv.version_code, coalesce(cv.display_name, cv.official_document_version)
  into v_ver_id, v_ver_code, v_ver_name
  from public.curriculum_versions cv
  where cv.curriculum_id = v_cur_id
  order by
    case cv.status when 'published' then 1 when 'approved' then 2 else 3 end,
    cv.created_at desc
  limit 1;

  -- Real DB-derived metrics for this exact academic context
  select count(*)::integer into v_question_count
  from public.question_bank qb
  where qb.subject_id = p_subject_id;

  select count(*)::integer into v_paper_count
  from public.examination_papers ep
  where ep.subject_id = p_subject_id
    and upper(ep.country_code) = v_country;

  select count(*)::integer into v_lesson_count
  from public.lessons l
  join public.topics t on t.id = l.topic_id
  where t.subject_id = p_subject_id;

  return jsonb_build_object(
    'context', jsonb_build_object(
      'country_code', v_country,
      'country_name', v_country_name,
      'curriculum_id', v_cur_id,
      'curriculum_code', v_cur_code,
      'curriculum_name', v_cur_name,
      'authority_name', v_auth_name,
      'authority_code', v_auth_code,
      'curriculum_version_id', v_ver_id,
      'curriculum_version_code', v_ver_code,
      'curriculum_version_name', v_ver_name,
      'education_level_id', p_education_level_id,
      'education_level_code', v_lvl_code,
      'education_level_name', v_lvl_name,
      'grade_id', p_grade_id,
      'grade_code', v_grd_code,
      'grade_name', v_grd_name,
      'subject_id', p_subject_id,
      'subject_code', v_subj_code,
      'subject_name', v_subj_name,
      'subject_official_name', v_subj_official,
      'language', v_subj_lang,
      'examination_type_id', p_examination_type_id,
      'examination_type_code', v_type_code,
      'examination_type_name', v_type_name,
      'examination_type_description', v_type_desc,
      'default_duration_minutes', v_type_duration,
      'default_total_marks', v_type_marks,
      'allows_online_delivery', v_type_online,
      'allows_printed_delivery', v_type_printed,
      'requires_academic_review', v_type_review,
      'suggested_examination_title', v_subj_name || ' ' || v_type_name || ' — ' || v_grd_name
    ),
    'stats', jsonb_build_object(
      'question_bank_count', v_question_count,
      'examination_papers_count', v_paper_count,
      'aligned_lessons_count', v_lesson_count
    ),
    'main_competences', coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'id', mc.id,
            'code', mc.code,
            'title', mc.title,
            'description', mc.description,
            'display_order', mc.display_order,
            'specific_competences', coalesce(
              (
                select jsonb_agg(
                  jsonb_build_object(
                    'id', sc.id,
                    'topic_id', sc.topic_id,
                    'code', sc.code,
                    'title', sc.title,
                    'description', sc.description,
                    'period_allocation', sc.period_allocation,
                    'assessment_criteria', sc.assessment_criteria,
                    'source_page', sc.source_page,
                    'question_count', (
                      select count(*)::integer
                      from public.question_bank qb
                      where qb.topic_id = sc.topic_id
                    ),
                    'subtopic_count', (
                      select count(*)::integer
                      from public.subtopics st
                      where st.topic_id = sc.topic_id
                        and st.is_published = true
                    )
                  )
                  order by sc.display_order asc, sc.code asc
                )
                from public.curriculum_specific_competences sc
                where sc.main_competence_id = mc.id
                  and sc.is_published = true
              ),
              '[]'::jsonb
            )
          )
          order by mc.display_order asc, mc.code asc
        )
        from public.curriculum_main_competences mc
        where mc.subject_id = p_subject_id
          and mc.is_published = true
      ),
      '[]'::jsonb
    )
  );
end;
$$;

-- Grants for all Phase 1 cascading selection RPCs
revoke all on function public.get_exam_v2_countries() from public;
grant execute on function public.get_exam_v2_countries() to anon, authenticated, service_role;

revoke all on function public.get_exam_v2_education_levels(text) from public;
grant execute on function public.get_exam_v2_education_levels(text) to anon, authenticated, service_role;

revoke all on function public.get_exam_v2_grades(uuid, uuid) from public;
grant execute on function public.get_exam_v2_grades(uuid, uuid) to anon, authenticated, service_role;

revoke all on function public.get_exam_v2_subjects(uuid, uuid, uuid) from public;
grant execute on function public.get_exam_v2_subjects(uuid, uuid, uuid) to anon, authenticated, service_role;

revoke all on function public.get_exam_v2_examination_types(text, uuid) from public;
grant execute on function public.get_exam_v2_examination_types(text, uuid) to anon, authenticated, service_role;

revoke all on function public.get_exam_v2_academic_context_summary(text, uuid, uuid, uuid, uuid) from public;
grant execute on function public.get_exam_v2_academic_context_summary(text, uuid, uuid, uuid, uuid) to anon, authenticated, service_role;

commit;
