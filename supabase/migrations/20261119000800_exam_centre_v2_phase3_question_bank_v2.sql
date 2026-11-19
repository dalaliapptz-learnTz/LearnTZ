-- ============================================================================
-- LearnTZ Examination Centre 2.0 — Phase 3: Question Bank 2.0
-- Migration: 20261119000800_exam_centre_v2_phase3_question_bank_v2.sql
--
-- Extends existing public.question_bank (zero duplicate tables) with full
-- curriculum classification, all 14 question formats, marking rubrics,
-- source/copyright metadata, review workflow, versioning, and immutable audit.
-- ============================================================================

begin;

-- ============================================================================
-- 1. Extend public.question_bank for Question Bank 2.0
-- ============================================================================
alter table public.question_bank
  add column if not exists curriculum_version_id uuid references public.curriculum_versions (id) on delete set null,
  add column if not exists education_level_id uuid references public.education_levels (id) on delete set null,
  add column if not exists main_competence_id uuid references public.curriculum_main_competences (id) on delete set null,
  add column if not exists specific_competence_id uuid references public.curriculum_specific_competences (id) on delete set null,
  add column if not exists language_code text not null default 'en',
  add column if not exists marking_rubric jsonb not null default '{}'::jsonb,
  add column if not exists source_reference text not null default '',
  add column if not exists copyright_notice text not null default '',
  add column if not exists review_status text not null default 'approved',
  add column if not exists author_id uuid references auth.users (id) on delete set null,
  add column if not exists reviewer_id uuid references auth.users (id) on delete set null,
  add column if not exists review_notes text,
  add column if not exists version_number integer not null default 1;

-- Backfill main_competence_id & specific_competence_id from topic_id where available
update public.question_bank qb
set specific_competence_id = sc.id,
    main_competence_id = sc.main_competence_id
from public.curriculum_specific_competences sc
where sc.topic_id = qb.topic_id
  and qb.specific_competence_id is null;

-- Drop any existing question_type / review_status check constraints cleanly before recreating
do $$
declare
  v_conname text;
begin
  for v_conname in
    select conname
    from pg_constraint
    where conrelid = 'public.question_bank'::regclass
      and contype = 'c'
      and (pg_get_constraintdef(oid) ilike '%question_type%' or pg_get_constraintdef(oid) ilike '%review_status%')
  loop
    execute format('alter table public.question_bank drop constraint if exists %I', v_conname);
  end loop;
end $$;

alter table public.question_bank
  add constraint question_bank_question_type_v2_check check (question_type in (
    'multiple_choice',
    'true_false',
    'fill_in_the_blank',
    'matching',
    'short_answer',
    'comprehension',
    'writing',
    'sentence_construction',
    'ordering',
    'ordering_sequencing',
    'word_completion',
    'image_based',
    'audio_based',
    'oral_assessment',
    'oral_response',
    'worked_problem',
    'structured_writing',
    'essay'
  ));

alter table public.question_bank
  add constraint question_bank_review_status_check check (review_status in (
    'draft',
    'in_review',
    'revision_requested',
    'approved',
    'archived'
  ));

create index if not exists question_bank_v2_context_idx
  on public.question_bank (subject_id, specific_competence_id, review_status, question_type, difficulty_level);

-- ============================================================================
-- 2. Table: public.question_bank_review_events (Immutable audit log)
-- ============================================================================
create table if not exists public.question_bank_review_events (
  id uuid primary key default gen_random_uuid(),
  question_id uuid not null references public.question_bank (id) on delete cascade,
  action text not null check (action in (
    'draft_saved',
    'submitted_for_review',
    'revision_requested',
    'approved',
    'archived'
  )),
  from_status text,
  to_status text not null,
  version_number integer not null default 1,
  comments text not null default '',
  actor_user_id uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists question_bank_review_events_q_idx
  on public.question_bank_review_events (question_id, created_at desc);

create or replace function public.prevent_question_review_event_mutation()
returns trigger
language plpgsql
as $$
begin
  raise exception 'Immutable audit log violation: question_bank_review_events cannot be modified or deleted'
    using errcode = '42501';
end;
$$;

drop trigger if exists question_bank_review_events_immutable on public.question_bank_review_events;
create trigger question_bank_review_events_immutable
  before update or delete on public.question_bank_review_events
  for each row execute function public.prevent_question_review_event_mutation();

alter table public.question_bank_review_events enable row level security;
revoke all on public.question_bank_review_events from public, anon, authenticated;
grant select, insert on public.question_bank_review_events to authenticated;

drop policy if exists "Authorized staff read question review events" on public.question_bank_review_events;
create policy "Authorized staff read question review events"
  on public.question_bank_review_events for select to authenticated
  using (
    exists (
      select 1 from public.question_bank qb
      where qb.id = question_bank_review_events.question_id
        and (
          qb.author_id = auth.uid()
          or public.can_author_lesson(qb.country_code)
          or public.can_review_lesson(qb.country_code)
          or public.can_publish_lesson(qb.country_code)
        )
    )
  );

-- ============================================================================
-- 3. RPC: save_exam_v2_question
--    Creates or updates a curriculum-mapped reusable question in question_bank
-- ============================================================================
create or replace function public.save_exam_v2_question(
  p_country_code text,
  p_education_level_id uuid,
  p_grade_id uuid,
  p_subject_id uuid,
  p_specific_competence_id uuid,
  p_question_type text,
  p_question_text text,
  p_correct_answer jsonb default '{}'::jsonb,
  p_options jsonb default '[]'::jsonb,
  p_marking_rubric jsonb default '{}'::jsonb,
  p_marks numeric default 2,
  p_difficulty_level text default 'medium',
  p_cognitive_tier text default 'comprehension',
  p_language_code text default 'en',
  p_explanation text default '',
  p_source_reference text default '',
  p_copyright_notice text default '',
  p_question_id uuid default null
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
  v_mc_id uuid;
  v_topic_id uuid;
  v_q_id uuid := p_question_id;
  v_existing_status text;
  v_existing_author uuid;
  v_version integer := 1;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  if v_country is null then
    raise exception 'Country code is required' using errcode = '22023';
  end if;

  if not (public.can_author_lesson(v_country) or public.can_publish_lesson(v_country)) then
    raise exception 'Permission denied: authoring questions requires authorized staff role'
      using errcode = '42501';
  end if;

  if char_length(btrim(coalesce(p_question_text, ''))) < 3 then
    raise exception 'Question statement must be at least 3 characters' using errcode = '22023';
  end if;

  if coalesce(p_marks, 0) <= 0 then
    raise exception 'Assigned marks must be greater than 0' using errcode = '22023';
  end if;

  -- Validate Country -> Curriculum -> Level -> Grade -> Subject chain
  select c.id into v_cur_id
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
    raise exception 'Academic hierarchy mismatch: invalid country, level, grade, and subject chain'
      using errcode = '22023';
  end if;

  -- Validate Specific Competence belongs to Subject
  select sc.main_competence_id, sc.topic_id
  into v_mc_id, v_topic_id
  from public.curriculum_specific_competences sc
  where sc.id = p_specific_competence_id
    and sc.subject_id = p_subject_id
    and sc.is_published = true;

  if not found then
    raise exception 'Competency mismatch: specific competence % does not belong to subject %', p_specific_competence_id, p_subject_id
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

  if v_q_id is not null then
    select review_status, author_id, version_number
    into v_existing_status, v_existing_author, v_version
    from public.question_bank
    where id = v_q_id;

    if not found then
      raise exception 'Question % not found', v_q_id using errcode = '22023';
    end if;

    if v_existing_author is not null and v_existing_author <> v_uid and not public.can_publish_lesson(v_country) then
      raise exception 'Permission denied: only the author or curriculum administrator can edit this question'
        using errcode = '42501';
    end if;

    v_version := v_version + 1;

    update public.question_bank
    set specific_competence_id = p_specific_competence_id,
        main_competence_id = v_mc_id,
        topic_id = v_topic_id,
        question_type = p_question_type,
        question_text = btrim(p_question_text),
        options = coalesce(p_options, '[]'::jsonb),
        correct_answer = coalesce(p_correct_answer, '{}'::jsonb),
        marking_rubric = coalesce(p_marking_rubric, '{}'::jsonb),
        marks = p_marks,
        difficulty_level = coalesce(nullif(btrim(p_difficulty_level), ''), 'medium'),
        cognitive_tier = coalesce(nullif(btrim(p_cognitive_tier), ''), 'comprehension'),
        language_code = coalesce(nullif(btrim(p_language_code), ''), 'en'),
        explanation = coalesce(p_explanation, ''),
        source_reference = coalesce(p_source_reference, ''),
        copyright_notice = coalesce(p_copyright_notice, ''),
        review_status = 'draft',
        is_published = false,
        version_number = v_version,
        updated_at = now()
    where id = v_q_id;
  else
    insert into public.question_bank (
      country_code, curriculum_id, curriculum_version_id,
      education_level_id, grade_id, subject_id, topic_id,
      main_competence_id, specific_competence_id,
      question_type, difficulty_level, cognitive_tier,
      question_text, options, correct_answer, marking_rubric,
      marks, language_code, explanation, source_reference, copyright_notice,
      review_status, is_published, version_number, author_id
    ) values (
      v_country, v_cur_id, v_ver_id,
      p_education_level_id, p_grade_id, p_subject_id, v_topic_id,
      v_mc_id, p_specific_competence_id,
      p_question_type,
      coalesce(nullif(btrim(p_difficulty_level), ''), 'medium'),
      coalesce(nullif(btrim(p_cognitive_tier), ''), 'comprehension'),
      btrim(p_question_text),
      coalesce(p_options, '[]'::jsonb),
      coalesce(p_correct_answer, '{}'::jsonb),
      coalesce(p_marking_rubric, '{}'::jsonb),
      p_marks,
      coalesce(nullif(btrim(p_language_code), ''), 'en'),
      coalesce(p_explanation, ''),
      coalesce(p_source_reference, ''),
      coalesce(p_copyright_notice, ''),
      'draft', false, 1, v_uid
    )
    returning id into v_q_id;
  end if;

  insert into public.question_bank_review_events (
    question_id, action, from_status, to_status, version_number, comments, actor_user_id
  ) values (
    v_q_id, 'draft_saved', v_existing_status, 'draft', v_version,
    'Question saved to Question Bank 2.0.', v_uid
  );

  return jsonb_build_object(
    'id', v_q_id,
    'review_status', 'draft',
    'is_published', false,
    'version_number', v_version
  );
end;
$$;

-- ============================================================================
-- 4. RPC: list_exam_v2_questions
--    Returns real DB-derived summary & questions for the academic context.
--    SECURITY: Never exposes correct_answer or marking_rubric to non-staff!
-- ============================================================================
create or replace function public.list_exam_v2_questions(
  p_country_code text default null,
  p_education_level_id uuid default null,
  p_grade_id uuid default null,
  p_subject_id uuid default null,
  p_specific_competence_id uuid default null,
  p_question_type text default null,
  p_difficulty_level text default null,
  p_review_status text default null,
  p_search text default null,
  p_limit integer default 25,
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
  v_is_staff boolean := false;
  v_qtype text := nullif(lower(btrim(coalesce(p_question_type, ''))), '');
  v_diff text := nullif(lower(btrim(coalesce(p_difficulty_level, ''))), '');
  v_rstat text := nullif(lower(btrim(coalesce(p_review_status, ''))), '');
  v_search text := nullif(btrim(coalesce(p_search, '')), '');
  v_limit integer := greatest(1, least(coalesce(p_limit, 25), 100));
  v_offset integer := greatest(0, coalesce(p_offset, 0));
  v_total integer := 0;
  v_draft integer := 0;
  v_in_review integer := 0;
  v_approved integer := 0;
  v_items jsonb := '[]'::jsonb;
begin
  if v_uid is not null then
    v_is_staff := public.can_author_lesson(v_country)
      or public.can_review_lesson(v_country)
      or public.can_publish_lesson(v_country);
  end if;

  with scoped as (
    select
      qb.id,
      qb.country_code,
      qb.subject_id,
      s.name as subject_name,
      qb.main_competence_id,
      mc.code as main_competence_code,
      mc.title as main_competence_title,
      qb.specific_competence_id,
      sc.code as specific_competence_code,
      sc.title as specific_competence_title,
      qb.question_type,
      qb.difficulty_level,
      qb.cognitive_tier,
      qb.question_text,
      qb.options,
      case when v_is_staff then qb.correct_answer else null end as correct_answer,
      case when v_is_staff then qb.marking_rubric else null end as marking_rubric,
      case when v_is_staff then qb.explanation else null end as explanation,
      coalesce(qb.marks, 1) as marks,
      qb.language_code,
      qb.source_reference,
      qb.copyright_notice,
      qb.review_status,
      qb.is_published,
      qb.version_number,
      qb.author_id,
      qb.review_notes,
      qb.updated_at
    from public.question_bank qb
    join public.subjects s on s.id = qb.subject_id
    left join public.curriculum_main_competences mc on mc.id = qb.main_competence_id
    left join public.curriculum_specific_competences sc on sc.id = qb.specific_competence_id
    where (
        v_is_staff
        or (qb.is_published = true and qb.review_status = 'approved')
      )
      and (v_country is null or upper(qb.country_code) = v_country)
      and (p_education_level_id is null or coalesce(qb.education_level_id, s.education_level_id) = p_education_level_id)
      and (p_grade_id is null or coalesce(qb.grade_id, s.grade_id) = p_grade_id)
      and (p_subject_id is null or qb.subject_id = p_subject_id)
  ),
  filtered as (
    select * from scoped
    where (p_specific_competence_id is null or specific_competence_id = p_specific_competence_id)
      and (v_qtype is null or v_qtype = 'all' or question_type = v_qtype)
      and (v_diff is null or v_diff = 'all' or difficulty_level = v_diff)
      and (v_rstat is null or v_rstat = 'all' or review_status = v_rstat)
      and (v_search is null or question_text ilike '%' || v_search || '%' or coalesce(specific_competence_title, '') ilike '%' || v_search || '%')
  )
  select
    (select count(*)::integer from scoped),
    (select count(*) filter (where review_status in ('draft', 'revision_requested'))::integer from scoped),
    (select count(*) filter (where review_status = 'in_review')::integer from scoped),
    (select count(*) filter (where review_status = 'approved')::integer from scoped),
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
  into v_total, v_draft, v_in_review, v_approved, v_items;

  return jsonb_build_object(
    'summary', jsonb_build_object(
      'total_count', v_total,
      'draft_count', v_draft,
      'in_review_count', v_in_review,
      'approved_count', v_approved
    ),
    'items', v_items
  );
end;
$$;

-- ============================================================================
-- 5. RPC: transition_exam_v2_question_status
-- ============================================================================
create or replace function public.transition_exam_v2_question_status(
  p_question_id uuid,
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
  v_q record;
  v_action text := lower(btrim(coalesce(p_action, '')));
  v_to_status text;
  v_is_pub boolean;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select * into v_q from public.question_bank where id = p_question_id;
  if not found then
    raise exception 'Question % not found', p_question_id using errcode = '22023';
  end if;

  v_is_pub := v_q.is_published;

  if v_action = 'submit_for_review' then
    if not (public.can_author_lesson(v_q.country_code) or public.can_publish_lesson(v_q.country_code)) then
      raise exception 'Permission denied: submitting question requires authoring role' using errcode = '42501';
    end if;
    v_to_status := 'in_review';
    v_is_pub := false;
    update public.question_bank
    set review_status = v_to_status, is_published = false, updated_at = now()
    where id = p_question_id;

  elsif v_action = 'request_revision' then
    if not (public.can_review_lesson(v_q.country_code) or public.can_publish_lesson(v_q.country_code)) then
      raise exception 'Permission denied: requesting question revision requires reviewer role' using errcode = '42501';
    end if;
    if nullif(btrim(coalesce(p_comments, '')), '') is null then
      raise exception 'Comments are required when requesting question revision' using errcode = '22023';
    end if;
    v_to_status := 'revision_requested';
    v_is_pub := false;
    update public.question_bank
    set review_status = v_to_status, is_published = false, reviewer_id = v_uid,
        review_notes = btrim(p_comments), updated_at = now()
    where id = p_question_id;

  elsif v_action = 'approve' then
    if not (public.can_review_lesson(v_q.country_code) or public.can_approve_lesson(v_q.country_code) or public.can_publish_lesson(v_q.country_code)) then
      raise exception 'Permission denied: approving questions requires academic reviewer role' using errcode = '42501';
    end if;
    if v_q.author_id = v_uid and not public.has_role('super_admin') and not public.is_current_super_admin() then
      raise exception 'Two-party review violation: question author cannot approve their own question'
        using errcode = '42501';
    end if;
    v_to_status := 'approved';
    v_is_pub := true;
    update public.question_bank
    set review_status = v_to_status, is_published = true, reviewer_id = v_uid,
        review_notes = coalesce(nullif(btrim(p_comments), ''), review_notes),
        updated_at = now()
    where id = p_question_id;

  elsif v_action = 'archive' then
    if not public.can_publish_lesson(v_q.country_code) then
      raise exception 'Permission denied: archiving questions requires curriculum_admin or super_admin role' using errcode = '42501';
    end if;
    v_to_status := 'archived';
    v_is_pub := false;
    update public.question_bank
    set review_status = v_to_status, is_published = false, updated_at = now()
    where id = p_question_id;
  else
    raise exception 'Unsupported question review action: %', v_action using errcode = '22023';
  end if;

  insert into public.question_bank_review_events (
    question_id, action, from_status, to_status, version_number, comments, actor_user_id
  ) values (
    p_question_id,
    case v_action
      when 'submit_for_review' then 'submitted_for_review'
      when 'request_revision' then 'revision_requested'
      when 'approve' then 'approved'
      when 'archive' then 'archived'
      else v_action
    end,
    v_q.review_status,
    v_to_status,
    v_q.version_number,
    coalesce(btrim(p_comments), ''),
    v_uid
  );

  return jsonb_build_object(
    'id', p_question_id,
    'review_status', v_to_status,
    'is_published', v_is_pub
  );
end;
$$;

revoke all on function public.save_exam_v2_question(text, uuid, uuid, uuid, uuid, text, text, jsonb, jsonb, jsonb, numeric, text, text, text, text, text, text, uuid) from public, anon;
grant execute on function public.save_exam_v2_question(text, uuid, uuid, uuid, uuid, text, text, jsonb, jsonb, jsonb, numeric, text, text, text, text, text, text, uuid) to authenticated, service_role;

revoke all on function public.list_exam_v2_questions(text, uuid, uuid, uuid, uuid, text, text, text, text, integer, integer) from public;
grant execute on function public.list_exam_v2_questions(text, uuid, uuid, uuid, uuid, text, text, text, text, integer, integer) to anon, authenticated, service_role;

revoke all on function public.transition_exam_v2_question_status(uuid, text, text) from public, anon;
grant execute on function public.transition_exam_v2_question_status(uuid, text, text) to authenticated, service_role;

commit;
