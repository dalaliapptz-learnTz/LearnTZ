-- ============================================================================
-- LearnTZ Examination Centre 2.0 — Phase 4: Examination Paper Builder
-- Migration: 20261119000900_exam_centre_v2_phase4_paper_builder.sql
--
-- Stores versioned, immutable snapshots of attached Question Bank items inside
-- public.examination_questions so later bank edits never mutate existing papers.
-- Supports section assignment, reordering, auto-numbering, marks recalculation,
-- and staff/learner-safe paper preview.
-- ============================================================================

begin;

-- ============================================================================
-- 1. Table: public.examination_questions (Versioned snapshots per paper)
-- ============================================================================
create table if not exists public.examination_questions (
  id uuid primary key default gen_random_uuid(),
  examination_id uuid not null references public.examinations (id) on delete cascade,
  section_id uuid not null references public.examination_sections (id) on delete cascade,
  source_question_id uuid references public.question_bank (id) on delete set null,
  source_question_version integer not null default 1,
  specific_competence_id uuid references public.curriculum_specific_competences (id) on delete set null,
  question_number integer not null default 1 check (question_number >= 1),
  display_order integer not null default 1 check (display_order >= 1),
  marks numeric not null default 1 check (marks > 0 and marks <= 500),
  question_type text not null,
  question_text text not null check (char_length(btrim(question_text)) >= 1),
  options jsonb not null default '[]'::jsonb,
  correct_answer jsonb not null default '{}'::jsonb,
  marking_rubric jsonb not null default '{}'::jsonb,
  explanation text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists examination_questions_exam_order_idx
  on public.examination_questions (examination_id, section_id, display_order asc);

drop trigger if exists examination_questions_set_updated_at on public.examination_questions;
create trigger examination_questions_set_updated_at
  before update on public.examination_questions
  for each row execute function public.set_updated_at();

alter table public.examination_questions enable row level security;
revoke all on public.examination_questions from public, anon, authenticated;
grant select, insert, update, delete on public.examination_questions to authenticated;

drop policy if exists "Authorized staff manage examination paper questions" on public.examination_questions;
create policy "Authorized staff manage examination paper questions"
  on public.examination_questions for all to authenticated
  using (
    exists (
      select 1 from public.examinations e
      where e.id = examination_questions.examination_id
        and (
          e.author_id = auth.uid()
          or public.can_author_lesson(e.country_code)
          or public.can_review_lesson(e.country_code)
          or public.can_publish_lesson(e.country_code)
        )
    )
  )
  with check (
    exists (
      select 1 from public.examinations e
      where e.id = examination_questions.examination_id
        and (
          public.can_publish_lesson(e.country_code)
          or (e.status in ('draft', 'revision_requested') and e.author_id = auth.uid() and public.can_author_lesson(e.country_code))
        )
    )
  );

-- ============================================================================
-- 2. Internal helper: renumber_and_recalc_exam_v2_paper
--    Renumbers all questions 1..N across sections in display_order and
--    recalculates section.marks_allocated & examinations.total_marks.
-- ============================================================================
create or replace function public.renumber_and_recalc_exam_v2_paper(
  p_examination_id uuid
)
returns numeric
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_total numeric := 0;
  v_q_count integer := 0;
begin
  -- Sequentially number all attached questions across sections
  with ordered as (
    select
      eq.id,
      row_number() over (
        order by es.display_order asc, es.section_code asc, eq.display_order asc, eq.created_at asc
      )::integer as new_q_num,
      row_number() over (
        partition by eq.section_id
        order by eq.display_order asc, eq.created_at asc
      )::integer as new_sec_order
    from public.examination_questions eq
    join public.examination_sections es on es.id = eq.section_id
    where eq.examination_id = p_examination_id
  )
  update public.examination_questions eq
  set question_number = o.new_q_num,
      display_order = o.new_sec_order,
      updated_at = now()
  from ordered o
  where eq.id = o.id;

  -- Update each section's question_count & marks_allocated when it has attached questions
  update public.examination_sections es
  set question_count = sub.cnt,
      marks_allocated = sub.sum_marks,
      updated_at = now()
  from (
    select section_id, count(*)::integer as cnt, sum(marks)::numeric as sum_marks
    from public.examination_questions
    where examination_id = p_examination_id
    group by section_id
  ) sub
  where es.id = sub.section_id;

  select count(*)::integer, coalesce(sum(marks), 0)::numeric
  into v_q_count, v_total
  from public.examination_questions
  where examination_id = p_examination_id;

  -- Recompute examination total_marks from sections sum
  select coalesce(sum(marks_allocated), 0)::numeric
  into v_total
  from public.examination_sections
  where examination_id = p_examination_id;

  update public.examinations
  set total_marks = v_total,
      updated_at = now()
  where id = p_examination_id;

  return v_total;
end;
$$;

-- ============================================================================
-- 3. RPC: add_exam_v2_paper_question
--    Attaches an immutable versioned snapshot of a question_bank record
-- ============================================================================
create or replace function public.add_exam_v2_paper_question(
  p_examination_id uuid,
  p_section_id uuid,
  p_source_question_id uuid,
  p_marks numeric default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_exam record;
  v_q record;
  v_next_order integer;
  v_new_id uuid;
  v_total_marks numeric;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select * into v_exam from public.examinations where id = p_examination_id;
  if not found then
    raise exception 'Examination % not found', p_examination_id using errcode = '22023';
  end if;

  if not (public.can_author_lesson(v_exam.country_code) or public.can_publish_lesson(v_exam.country_code)) then
    raise exception 'Permission denied: modifying examination paper requires authoring role' using errcode = '42501';
  end if;

  if v_exam.status not in ('draft', 'revision_requested') and not public.can_publish_lesson(v_exam.country_code) then
    raise exception 'Cannot modify paper questions while examination is in status %', v_exam.status using errcode = '42501';
  end if;

  if not exists (
    select 1 from public.examination_sections
    where id = p_section_id and examination_id = p_examination_id
  ) then
    raise exception 'Section % does not belong to examination %', p_section_id, p_examination_id using errcode = '22023';
  end if;

  select * into v_q from public.question_bank where id = p_source_question_id;
  if not found then
    raise exception 'Question % not found', p_source_question_id using errcode = '22023';
  end if;

  if v_q.subject_id <> v_exam.subject_id then
    raise exception 'Question subject mismatch: question belongs to a different subject than this examination'
      using errcode = '22023';
  end if;

  select coalesce(max(display_order), 0) + 1 into v_next_order
  from public.examination_questions
  where section_id = p_section_id;

  insert into public.examination_questions (
    examination_id, section_id, source_question_id, source_question_version,
    specific_competence_id, question_number, display_order, marks,
    question_type, question_text, options, correct_answer, marking_rubric, explanation
  ) values (
    p_examination_id, p_section_id, v_q.id, coalesce(v_q.version_number, 1),
    v_q.specific_competence_id, v_next_order, v_next_order,
    greatest(1, coalesce(p_marks, v_q.marks, 1)),
    v_q.question_type,
    v_q.question_text,
    coalesce(v_q.options, '[]'::jsonb),
    coalesce(v_q.correct_answer, '{}'::jsonb),
    coalesce(v_q.marking_rubric, '{}'::jsonb),
    coalesce(v_q.explanation, '')
  )
  returning id into v_new_id;

  v_total_marks := public.renumber_and_recalc_exam_v2_paper(p_examination_id);

  return jsonb_build_object(
    'id', v_new_id,
    'examination_id', p_examination_id,
    'total_marks', v_total_marks
  );
end;
$$;

-- ============================================================================
-- 4. RPC: reorder_exam_v2_paper_questions
-- ============================================================================
create or replace function public.reorder_exam_v2_paper_questions(
  p_examination_id uuid,
  p_section_id uuid,
  p_ordered_ids uuid[]
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_exam record;
  v_idx integer := 0;
  v_qid uuid;
  v_total numeric;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select * into v_exam from public.examinations where id = p_examination_id;
  if not found then
    raise exception 'Examination % not found', p_examination_id using errcode = '22023';
  end if;

  if not (public.can_author_lesson(v_exam.country_code) or public.can_publish_lesson(v_exam.country_code)) then
    raise exception 'Permission denied' using errcode = '42501';
  end if;

  foreach v_qid in array p_ordered_ids
  loop
    v_idx := v_idx + 1;
    update public.examination_questions
    set display_order = v_idx, updated_at = now()
    where id = v_qid
      and examination_id = p_examination_id
      and section_id = p_section_id;
  end loop;

  v_total := public.renumber_and_recalc_exam_v2_paper(p_examination_id);

  return jsonb_build_object(
    'examination_id', p_examination_id,
    'total_marks', v_total
  );
end;
$$;

-- ============================================================================
-- 5. RPC: remove_exam_v2_paper_question
-- ============================================================================
create or replace function public.remove_exam_v2_paper_question(
  p_examination_question_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_exam_id uuid;
  v_country text;
  v_total numeric;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select eq.examination_id, e.country_code
  into v_exam_id, v_country
  from public.examination_questions eq
  join public.examinations e on e.id = eq.examination_id
  where eq.id = p_examination_question_id;

  if not found then
    raise exception 'Paper question % not found', p_examination_question_id using errcode = '22023';
  end if;

  if not (public.can_author_lesson(v_country) or public.can_publish_lesson(v_country)) then
    raise exception 'Permission denied' using errcode = '42501';
  end if;

  delete from public.examination_questions where id = p_examination_question_id;
  v_total := public.renumber_and_recalc_exam_v2_paper(v_exam_id);

  return jsonb_build_object(
    'examination_id', v_exam_id,
    'total_marks', v_total
  );
end;
$$;

-- ============================================================================
-- 6. RPC: get_exam_v2_paper_builder
--    Returns complete paper builder & formatted preview payload
--    SECURITY: strips correct_answer, marking_rubric & explanation for non-staff
-- ============================================================================
create or replace function public.get_exam_v2_paper_builder(
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
  v_is_staff boolean := false;
  v_q_count integer := 0;
  v_sec_count integer := 0;
  v_comp_count integer := 0;
  v_issues text[] := array[]::text[];
begin
  select
    e.*,
    co.display_name as country_name,
    c.name as curriculum_name,
    cv.version_code as curriculum_version_code,
    el.name as education_level_name,
    eg.name as grade_name,
    s.name as subject_name,
    et.name as examination_type_name
  into v_exam
  from public.examinations e
  join public.countries co on co.country_code = e.country_code
  join public.curricula c on c.id = e.curriculum_id
  left join public.curriculum_versions cv on cv.id = e.curriculum_version_id
  join public.education_levels el on el.id = e.education_level_id
  join public.education_grades eg on eg.id = e.grade_id
  join public.subjects s on s.id = e.subject_id
  join public.examination_types et on et.id = e.examination_type_id
  where e.id = p_examination_id;

  if not found then
    raise exception 'Examination % not found', p_examination_id using errcode = '22023';
  end if;

  if v_uid is not null then
    v_is_staff := v_exam.author_id = v_uid
      or public.can_author_lesson(v_exam.country_code)
      or public.can_review_lesson(v_exam.country_code)
      or public.can_publish_lesson(v_exam.country_code);
  end if;

  if not v_is_staff and not (v_exam.is_published = true and v_exam.status in ('published', 'active', 'completed', 'results_released')) then
    raise exception 'Permission denied' using errcode = '42501';
  end if;

  select count(*)::integer into v_sec_count from public.examination_sections where examination_id = p_examination_id;
  select count(*)::integer into v_q_count from public.examination_questions where examination_id = p_examination_id;
  select count(*)::integer into v_comp_count from public.examination_competencies where examination_id = p_examination_id;

  if v_sec_count = 0 then
    v_issues := array_append(v_issues, 'Add at least one examination section.');
  end if;
  if v_q_count = 0 then
    v_issues := array_append(v_issues, 'Attach at least one question from Question Bank 2.0.');
  end if;
  if v_comp_count = 0 then
    v_issues := array_append(v_issues, 'Map at least one official curriculum specific competence.');
  end if;

  return jsonb_build_object(
    'examination', jsonb_build_object(
      'id', v_exam.id,
      'title', v_exam.title,
      'country_code', v_exam.country_code,
      'country_name', v_exam.country_name,
      'curriculum_name', v_exam.curriculum_name,
      'curriculum_version_code', v_exam.curriculum_version_code,
      'education_level_name', v_exam.education_level_name,
      'grade_name', v_exam.grade_name,
      'subject_id', v_exam.subject_id,
      'subject_name', v_exam.subject_name,
      'examination_type_name', v_exam.examination_type_name,
      'academic_year', v_exam.academic_year,
      'academic_term', v_exam.academic_term,
      'duration_minutes', v_exam.duration_minutes,
      'total_marks', v_exam.total_marks,
      'instructions', v_exam.instructions,
      'delivery_mode', v_exam.delivery_mode,
      'status', v_exam.status,
      'is_published', v_exam.is_published,
      'version_number', v_exam.version_number
    ),
    'validation', jsonb_build_object(
      'is_valid', array_length(v_issues, 1) is null,
      'issues', to_jsonb(v_issues),
      'section_count', v_sec_count,
      'question_count', v_q_count,
      'competency_count', v_comp_count
    ),
    'sections', coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'id', es.id,
            'section_code', es.section_code,
            'title', es.title,
            'question_format', es.question_format,
            'instructions', es.instructions,
            'question_count', es.question_count,
            'marks_allocated', es.marks_allocated,
            'display_order', es.display_order,
            'questions', coalesce(
              (
                select jsonb_agg(
                  jsonb_build_object(
                    'id', eq.id,
                    'section_id', eq.section_id,
                    'source_question_id', eq.source_question_id,
                    'source_question_version', eq.source_question_version,
                    'specific_competence_id', eq.specific_competence_id,
                    'specific_competence_code', sc.code,
                    'question_number', eq.question_number,
                    'display_order', eq.display_order,
                    'marks', eq.marks,
                    'question_type', eq.question_type,
                    'question_text', eq.question_text,
                    'options', eq.options,
                    'correct_answer', case when v_is_staff then eq.correct_answer else null end,
                    'marking_rubric', case when v_is_staff then eq.marking_rubric else null end,
                    'explanation', case when v_is_staff then eq.explanation else null end
                  )
                  order by eq.display_order asc, eq.question_number asc
                )
                from public.examination_questions eq
                left join public.curriculum_specific_competences sc on sc.id = eq.specific_competence_id
                where eq.section_id = es.id
              ),
              '[]'::jsonb
            )
          )
          order by es.display_order asc, es.section_code asc
        )
        from public.examination_sections es
        where es.examination_id = p_examination_id
      ),
      '[]'::jsonb
    )
  );
end;
$$;

revoke all on function public.renumber_and_recalc_exam_v2_paper(uuid) from public, anon, authenticated;
grant execute on function public.renumber_and_recalc_exam_v2_paper(uuid) to service_role;

revoke all on function public.add_exam_v2_paper_question(uuid, uuid, uuid, numeric) from public, anon;
grant execute on function public.add_exam_v2_paper_question(uuid, uuid, uuid, numeric) to authenticated, service_role;

revoke all on function public.reorder_exam_v2_paper_questions(uuid, uuid, uuid[]) from public, anon;
grant execute on function public.reorder_exam_v2_paper_questions(uuid, uuid, uuid[]) to authenticated, service_role;

revoke all on function public.remove_exam_v2_paper_question(uuid) from public, anon;
grant execute on function public.remove_exam_v2_paper_question(uuid) to authenticated, service_role;

revoke all on function public.get_exam_v2_paper_builder(uuid) from public;
grant execute on function public.get_exam_v2_paper_builder(uuid) to anon, authenticated, service_role;

commit;
