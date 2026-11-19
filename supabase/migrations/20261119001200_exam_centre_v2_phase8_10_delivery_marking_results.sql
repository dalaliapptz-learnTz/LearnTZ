-- ============================================================================
-- LearnTZ Examination Centre 2.0 — Phases 8, 9 & 10: Online Examination Delivery,
-- Server-Authoritative Timer, Auto & Manual Marking, Competency Results & Release
-- Migration: 20261119001200_exam_centre_v2_phase8_10_delivery_marking_results.sql
-- ============================================================================

begin;

-- ============================================================================
-- 1. Table: public.examination_attempts
-- ============================================================================
create table if not exists public.examination_attempts (
  id uuid primary key default gen_random_uuid(),
  examination_id uuid not null references public.examinations (id) on delete cascade,
  candidate_id uuid references public.examination_candidates (id) on delete set null,
  learner_id uuid not null references public.learners (id) on delete cascade,
  attempt_number integer not null default 1 check (attempt_number >= 1),
  started_at timestamptz not null default now(),
  server_deadline_at timestamptz not null,
  submitted_at timestamptz,
  status text not null default 'in_progress' check (status in (
    'in_progress',
    'submitted',
    'auto_marked',
    'marking_in_progress',
    'marked',
    'results_released',
    'expired'
  )),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (examination_id, learner_id, attempt_number)
);

create index if not exists examination_attempts_exam_learner_idx
  on public.examination_attempts (examination_id, learner_id, status);

drop trigger if exists examination_attempts_set_updated_at on public.examination_attempts;
create trigger examination_attempts_set_updated_at
  before update on public.examination_attempts
  for each row execute function public.set_updated_at();

alter table public.examination_attempts enable row level security;
revoke all on public.examination_attempts from public, anon, authenticated;
grant select, insert, update on public.examination_attempts to authenticated;

drop policy if exists "Staff and owning parents view examination attempts" on public.examination_attempts;
create policy "Staff and owning parents view examination attempts"
  on public.examination_attempts for select to authenticated
  using (
    exists (
      select 1 from public.learners l
      where l.id = examination_attempts.learner_id
        and l.created_by_parent_user_id = auth.uid()
    )
    or exists (
      select 1 from public.examinations e
      where e.id = examination_attempts.examination_id
        and (
          public.can_review_lesson(e.country_code)
          or public.can_publish_lesson(e.country_code)
        )
    )
  );

-- ============================================================================
-- 2. Table: public.examination_responses
-- ============================================================================
create table if not exists public.examination_responses (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null references public.examination_attempts (id) on delete cascade,
  examination_question_id uuid not null references public.examination_questions (id) on delete cascade,
  response_payload jsonb not null default '{}'::jsonb,
  saved_at timestamptz not null default now(),
  auto_marked boolean not null default false,
  marks_awarded numeric check (marks_awarded is null or marks_awarded >= 0),
  max_marks numeric not null default 1 check (max_marks > 0),
  marking_status text not null default 'pending' check (marking_status in (
    'pending',
    'auto_marked',
    'awaiting_manual_marking',
    'manually_marked',
    'moderated'
  )),
  marked_by uuid references auth.users (id) on delete set null,
  marked_at timestamptz,
  marker_feedback text not null default '',
  unique (attempt_id, examination_question_id)
);

create index if not exists examination_responses_attempt_idx
  on public.examination_responses (attempt_id, marking_status);

alter table public.examination_responses enable row level security;
revoke all on public.examination_responses from public, anon, authenticated;
grant select, insert, update on public.examination_responses to authenticated;

drop policy if exists "Staff view examination responses" on public.examination_responses;
create policy "Staff view examination responses"
  on public.examination_responses for select to authenticated
  using (
    exists (
      select 1 from public.examination_attempts a
      join public.examinations e on e.id = a.examination_id
      where a.id = examination_responses.attempt_id
        and (
          public.can_review_lesson(e.country_code)
          or public.can_publish_lesson(e.country_code)
        )
    )
  );

-- ============================================================================
-- 3. Tables: public.examination_results & public.examination_competency_results
-- ============================================================================
create table if not exists public.examination_results (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null unique references public.examination_attempts (id) on delete cascade,
  examination_id uuid not null references public.examinations (id) on delete cascade,
  learner_id uuid not null references public.learners (id) on delete cascade,
  marks_awarded numeric not null default 0,
  total_marks numeric not null default 0,
  percentage numeric not null default 0,
  unmarked_count integer not null default 0,
  is_released boolean not null default false,
  released_by uuid references auth.users (id) on delete set null,
  released_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists examination_results_exam_learner_idx
  on public.examination_results (examination_id, learner_id, is_released);

drop trigger if exists examination_results_set_updated_at on public.examination_results;
create trigger examination_results_set_updated_at
  before update on public.examination_results
  for each row execute function public.set_updated_at();

alter table public.examination_results enable row level security;
revoke all on public.examination_results from public, anon, authenticated;
grant select on public.examination_results to authenticated;

drop policy if exists "Released results visible to owning parent and staff" on public.examination_results;
create policy "Released results visible to owning parent and staff"
  on public.examination_results for select to authenticated
  using (
    (
      is_released = true
      and exists (
        select 1 from public.learners l
        where l.id = examination_results.learner_id
          and l.created_by_parent_user_id = auth.uid()
      )
    )
    or exists (
      select 1 from public.examinations e
      where e.id = examination_results.examination_id
        and (public.can_review_lesson(e.country_code) or public.can_publish_lesson(e.country_code))
    )
  );

create table if not exists public.examination_competency_results (
  id uuid primary key default gen_random_uuid(),
  result_id uuid not null references public.examination_results (id) on delete cascade,
  examination_id uuid not null references public.examinations (id) on delete cascade,
  learner_id uuid not null references public.learners (id) on delete cascade,
  specific_competence_id uuid not null references public.curriculum_specific_competences (id) on delete restrict,
  marks_awarded numeric not null default 0,
  max_marks numeric not null default 0,
  percentage numeric not null default 0,
  mastery_band text not null default 'developing' check (mastery_band in ('strong', 'developing', 'needs_improvement')),
  unique (result_id, specific_competence_id)
);

alter table public.examination_competency_results enable row level security;
revoke all on public.examination_competency_results from public, anon, authenticated;
grant select on public.examination_competency_results to authenticated;

drop policy if exists "Competency results follow parent result visibility" on public.examination_competency_results;
create policy "Competency results follow parent result visibility"
  on public.examination_competency_results for select to authenticated
  using (
    exists (
      select 1 from public.examination_results r
      where r.id = examination_competency_results.result_id
    )
  );

-- ============================================================================
-- 4. Internal helper: recalculate_exam_v2_attempt_results
-- ============================================================================
create or replace function public.recalculate_exam_v2_attempt_results(
  p_attempt_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_attempt record;
  v_total_marks numeric := 0;
  v_awarded numeric := 0;
  v_unmarked integer := 0;
  v_pct numeric := 0;
  v_res_id uuid;
begin
  select * into v_attempt from public.examination_attempts where id = p_attempt_id;
  if not found then
    raise exception 'Attempt % not found', p_attempt_id using errcode = '22023';
  end if;

  select coalesce(sum(marks), 0)::numeric into v_total_marks
  from public.examination_questions
  where examination_id = v_attempt.examination_id;

  select
    coalesce(sum(coalesce(marks_awarded, 0)), 0)::numeric,
    count(*) filter (where marking_status = 'awaiting_manual_marking')::integer
  into v_awarded, v_unmarked
  from public.examination_responses
  where attempt_id = p_attempt_id;

  if v_total_marks > 0 then
    v_pct := round((v_awarded / v_total_marks) * 100.0, 2);
  else
    v_pct := 0;
  end if;

  insert into public.examination_results (
    attempt_id, examination_id, learner_id,
    marks_awarded, total_marks, percentage, unmarked_count
  ) values (
    p_attempt_id, v_attempt.examination_id, v_attempt.learner_id,
    v_awarded, v_total_marks, v_pct, v_unmarked
  )
  on conflict (attempt_id) do update
    set marks_awarded = excluded.marks_awarded,
        total_marks = excluded.total_marks,
        percentage = excluded.percentage,
        unmarked_count = excluded.unmarked_count,
        updated_at = now()
  returning id into v_res_id;

  -- Recompute per-competency breakdown
  delete from public.examination_competency_results where result_id = v_res_id;

  insert into public.examination_competency_results (
    result_id, examination_id, learner_id, specific_competence_id,
    marks_awarded, max_marks, percentage, mastery_band
  )
  select
    v_res_id,
    v_attempt.examination_id,
    v_attempt.learner_id,
    eq.specific_competence_id,
    coalesce(sum(coalesce(er.marks_awarded, 0)), 0)::numeric as awarded,
    coalesce(sum(eq.marks), 0)::numeric as max_m,
    case when sum(eq.marks) > 0
      then round((coalesce(sum(coalesce(er.marks_awarded, 0)), 0) / sum(eq.marks)) * 100.0, 2)
      else 0 end as pct,
    case
      when sum(eq.marks) > 0 and (coalesce(sum(coalesce(er.marks_awarded, 0)), 0) / sum(eq.marks)) * 100.0 >= 75 then 'strong'
      when sum(eq.marks) > 0 and (coalesce(sum(coalesce(er.marks_awarded, 0)), 0) / sum(eq.marks)) * 100.0 >= 50 then 'developing'
      else 'needs_improvement'
    end as band
  from public.examination_questions eq
  left join public.examination_responses er
    on er.examination_question_id = eq.id
   and er.attempt_id = p_attempt_id
  where eq.examination_id = v_attempt.examination_id
    and eq.specific_competence_id is not null
  group by eq.specific_competence_id;

  update public.examination_attempts
  set status = case
        when v_unmarked > 0 then 'marking_in_progress'
        else 'marked'
      end,
      updated_at = now()
  where id = p_attempt_id
    and status not in ('results_released');

  return jsonb_build_object(
    'result_id', v_res_id,
    'marks_awarded', v_awarded,
    'total_marks', v_total_marks,
    'percentage', v_pct,
    'unmarked_count', v_unmarked
  );
end;
$$;

-- ============================================================================
-- 5. RPC: start_exam_v2_attempt
--    Server-authoritative timer, recovery on reconnect, zero answer keys leaked
-- ============================================================================
create or replace function public.start_exam_v2_attempt(
  p_examination_id uuid,
  p_learner_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_exam record;
  v_cand record;
  v_attempt record;
  v_attempt_count integer := 0;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select * into v_exam from public.examinations where id = p_examination_id;
  if not found then
    raise exception 'Examination % not found', p_examination_id using errcode = '22023';
  end if;

  if not (v_exam.is_published = true and v_exam.status in ('published', 'active')) then
    raise exception 'Examination is not open for online delivery' using errcode = '42501';
  end if;

  -- Verify caller is either the learner's parent or authorized exam staff
  if not (
    exists (select 1 from public.learners l where l.id = p_learner_id and l.created_by_parent_user_id = v_uid)
    or public.can_publish_lesson(v_exam.country_code)
    or public.can_review_lesson(v_exam.country_code)
  ) then
    raise exception 'Permission denied: caller is not authorized to start attempt for this learner' using errcode = '42501';
  end if;

  select * into v_cand
  from public.examination_candidates
  where examination_id = p_examination_id and learner_id = p_learner_id
  limit 1;

  -- Recovery: return existing in_progress attempt if not expired
  select * into v_attempt
  from public.examination_attempts
  where examination_id = p_examination_id
    and learner_id = p_learner_id
    and status = 'in_progress'
    and server_deadline_at > now()
  order by attempt_number desc
  limit 1;

  if not found then
    select count(*)::integer into v_attempt_count
    from public.examination_attempts
    where examination_id = p_examination_id and learner_id = p_learner_id;

    if v_attempt_count >= v_exam.max_attempts then
      raise exception 'Maximum attempt limit (%) reached for this examination', v_exam.max_attempts
        using errcode = '22023';
    end if;

    insert into public.examination_attempts (
      examination_id, candidate_id, learner_id, attempt_number,
      started_at, server_deadline_at, status
    ) values (
      p_examination_id, v_cand.id, p_learner_id, v_attempt_count + 1,
      now(), now() + make_interval(mins => v_exam.duration_minutes), 'in_progress'
    )
    returning * into v_attempt;

    if v_cand.id is not null then
      update public.examination_candidates
      set status = 'started', attendance_status = 'present', updated_at = now()
      where id = v_cand.id;
    end if;
  end if;

  return jsonb_build_object(
    'attempt_id', v_attempt.id,
    'examination_id', v_exam.id,
    'examination_title', v_exam.title,
    'instructions', v_exam.instructions,
    'duration_minutes', v_exam.duration_minutes,
    'total_marks', v_exam.total_marks,
    'started_at', v_attempt.started_at,
    'server_deadline_at', v_attempt.server_deadline_at,
    'status', v_attempt.status,
    -- STRICTLY SANITIZED: NO correct_answer, marking_rubric, or explanation!
    'questions', coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'id', eq.id,
            'section_id', eq.section_id,
            'question_number', eq.question_number,
            'marks', eq.marks,
            'question_type', eq.question_type,
            'question_text', eq.question_text,
            'options', eq.options,
            'saved_response', (
              select er.response_payload
              from public.examination_responses er
              where er.attempt_id = v_attempt.id
                and er.examination_question_id = eq.id
              limit 1
            )
          )
          order by eq.question_number asc
        )
        from public.examination_questions eq
        where eq.examination_id = p_examination_id
      ),
      '[]'::jsonb
    )
  );
end;
$$;

-- ============================================================================
-- 6. RPC: save_exam_v2_response (Auto-save with server-deadline check)
-- ============================================================================
create or replace function public.save_exam_v2_response(
  p_attempt_id uuid,
  p_examination_question_id uuid,
  p_response_payload jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_attempt record;
  v_q record;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select * into v_attempt from public.examination_attempts where id = p_attempt_id;
  if not found then
    raise exception 'Attempt % not found', p_attempt_id using errcode = '22023';
  end if;

  if v_attempt.status <> 'in_progress' then
    raise exception 'Attempt already submitted or closed' using errcode = '22023';
  end if;

  if now() > v_attempt.server_deadline_at then
    update public.examination_attempts set status = 'expired', updated_at = now() where id = p_attempt_id;
    raise exception 'Examination time expired' using errcode = '22023';
  end if;

  select * into v_q
  from public.examination_questions
  where id = p_examination_question_id
    and examination_id = v_attempt.examination_id;

  if not found then
    raise exception 'Question does not belong to this examination' using errcode = '22023';
  end if;

  insert into public.examination_responses (
    attempt_id, examination_question_id, response_payload, saved_at, max_marks, marking_status
  ) values (
    p_attempt_id, p_examination_question_id, coalesce(p_response_payload, '{}'::jsonb), now(), v_q.marks, 'pending'
  )
  on conflict (attempt_id, examination_question_id) do update
    set response_payload = excluded.response_payload,
        saved_at = now();

  return jsonb_build_object('attempt_id', p_attempt_id, 'question_id', p_examination_question_id, 'saved', true);
end;
$$;

-- ============================================================================
-- 7. RPC: submit_exam_v2_attempt
--    Prevents duplicate submission, auto-marks objective items, queues manual
--    items, and computes per-competency results
-- ============================================================================
create or replace function public.submit_exam_v2_attempt(
  p_attempt_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_attempt record;
  v_q record;
  v_resp record;
  v_expected text;
  v_actual text;
  v_summary jsonb;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select * into v_attempt from public.examination_attempts where id = p_attempt_id;
  if not found then
    raise exception 'Attempt % not found', p_attempt_id using errcode = '22023';
  end if;

  if v_attempt.status <> 'in_progress' then
    raise exception 'Attempt already submitted' using errcode = '22023';
  end if;

  -- Mark each question in the paper
  for v_q in
    select * from public.examination_questions
    where examination_id = v_attempt.examination_id
    order by question_number asc
  loop
    select * into v_resp
    from public.examination_responses
    where attempt_id = p_attempt_id and examination_question_id = v_q.id;

    if not found then
      insert into public.examination_responses (
        attempt_id, examination_question_id, response_payload, max_marks,
        auto_marked, marks_awarded, marking_status
      ) values (
        p_attempt_id, v_q.id, '{}'::jsonb, v_q.marks,
        true, 0, 'auto_marked'
      );
      continue;
    end if;

    if v_q.question_type in ('multiple_choice', 'true_false', 'fill_in_the_blank', 'matching', 'word_completion') then
      v_expected := lower(btrim(coalesce(v_q.correct_answer ->> 'answer', '')));
      v_actual := lower(btrim(coalesce(v_resp.response_payload ->> 'answer', '')));

      update public.examination_responses
      set auto_marked = true,
          marks_awarded = case when v_expected <> '' and v_actual = v_expected then v_q.marks else 0 end,
          marking_status = 'auto_marked',
          marked_at = now()
      where id = v_resp.id;
    else
      update public.examination_responses
      set auto_marked = false,
          marking_status = 'awaiting_manual_marking'
      where id = v_resp.id;
    end if;
  end loop;

  update public.examination_attempts
  set submitted_at = now(), status = 'submitted', updated_at = now()
  where id = p_attempt_id;

  if v_attempt.candidate_id is not null then
    update public.examination_candidates
    set status = 'submitted', updated_at = now()
    where id = v_attempt.candidate_id;
  end if;

  v_summary := public.recalculate_exam_v2_attempt_results(p_attempt_id);
  return v_summary || jsonb_build_object('attempt_id', p_attempt_id, 'submitted', true);
end;
$$;

-- ============================================================================
-- 8. RPC: mark_exam_v2_response (Manual marking by authorized examiner)
-- ============================================================================
create or replace function public.mark_exam_v2_response(
  p_response_id uuid,
  p_marks_awarded numeric,
  p_feedback text default ''
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_row record;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select er.*, a.examination_id, e.country_code
  into v_row
  from public.examination_responses er
  join public.examination_attempts a on a.id = er.attempt_id
  join public.examinations e on e.id = a.examination_id
  where er.id = p_response_id;

  if not found then
    raise exception 'Response % not found', p_response_id using errcode = '22023';
  end if;

  if not (public.can_review_lesson(v_row.country_code) or public.can_publish_lesson(v_row.country_code)) then
    raise exception 'Permission denied: manual marking requires authorized examiner/reviewer role' using errcode = '42501';
  end if;

  if p_marks_awarded < 0 or p_marks_awarded > v_row.max_marks then
    raise exception 'Awarded marks (%) must be between 0 and max marks (%)', p_marks_awarded, v_row.max_marks
      using errcode = '22023';
  end if;

  update public.examination_responses
  set marks_awarded = p_marks_awarded,
      marking_status = 'manually_marked',
      marked_by = v_uid,
      marked_at = now(),
      marker_feedback = coalesce(btrim(p_feedback), '')
  where id = p_response_id;

  return public.recalculate_exam_v2_attempt_results(v_row.attempt_id);
end;
$$;

-- ============================================================================
-- 9. RPC: release_exam_v2_results (Controlled result publication + analytics)
-- ============================================================================
create or replace function public.release_exam_v2_results(
  p_examination_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_exam record;
  v_unmarked integer := 0;
  v_count integer := 0;
  v_avg numeric := 0;
  v_high numeric := 0;
  v_low numeric := 0;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select * into v_exam from public.examinations where id = p_examination_id;
  if not found then
    raise exception 'Examination % not found', p_examination_id using errcode = '22023';
  end if;

  if not public.can_publish_lesson(v_exam.country_code) then
    raise exception 'Permission denied: releasing results requires curriculum_admin or super_admin role'
      using errcode = '42501';
  end if;

  select coalesce(sum(unmarked_count), 0)::integer into v_unmarked
  from public.examination_results
  where examination_id = p_examination_id;

  if v_unmarked > 0 then
    raise exception 'Cannot release results: % response(s) still awaiting manual marking', v_unmarked
      using errcode = '22023';
  end if;

  update public.examination_results
  set is_released = true, released_by = v_uid, released_at = now(), updated_at = now()
  where examination_id = p_examination_id;

  update public.examination_attempts
  set status = 'results_released', updated_at = now()
  where examination_id = p_examination_id and status = 'marked';

  update public.examinations
  set status = 'results_released', updated_at = now()
  where id = p_examination_id;

  insert into public.examination_review_events (
    examination_id, action, from_status, to_status, version_number, comments, actor_user_id
  ) values (
    p_examination_id, 'results_released', v_exam.status, 'results_released',
    v_exam.version_number, 'Examination results approved and released.', v_uid
  );

  select
    count(*)::integer,
    coalesce(round(avg(percentage), 2), 0),
    coalesce(max(percentage), 0),
    coalesce(min(percentage), 0)
  into v_count, v_avg, v_high, v_low
  from public.examination_results
  where examination_id = p_examination_id;

  return jsonb_build_object(
    'examination_id', p_examination_id,
    'released', true,
    'candidate_count', v_count,
    'average_percentage', v_avg,
    'highest_percentage', v_high,
    'lowest_percentage', v_low
  );
end;
$$;

revoke all on function public.recalculate_exam_v2_attempt_results(uuid) from public, anon, authenticated;
grant execute on function public.recalculate_exam_v2_attempt_results(uuid) to service_role;

revoke all on function public.start_exam_v2_attempt(uuid, uuid) from public, anon;
grant execute on function public.start_exam_v2_attempt(uuid, uuid) to authenticated, service_role;

revoke all on function public.save_exam_v2_response(uuid, uuid, jsonb) from public, anon;
grant execute on function public.save_exam_v2_response(uuid, uuid, jsonb) to authenticated, service_role;

revoke all on function public.submit_exam_v2_attempt(uuid) from public, anon;
grant execute on function public.submit_exam_v2_attempt(uuid) to authenticated, service_role;

revoke all on function public.mark_exam_v2_response(uuid, numeric, text) from public, anon;
grant execute on function public.mark_exam_v2_response(uuid, numeric, text) to authenticated, service_role;

revoke all on function public.release_exam_v2_results(uuid) from public, anon;
grant execute on function public.release_exam_v2_results(uuid) to authenticated, service_role;

commit;
