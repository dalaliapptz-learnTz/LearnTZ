-- ============================================================================
-- LearnTZ Examination Centre 2.0 — Phases 11 & 12: Offline Sync Integrity
-- & Multi-Country Configurable Grading Policies
-- Migration: 20261119001300_exam_centre_v2_phase11_12_offline_sync_and_grading_policies.sql
-- ============================================================================

begin;

-- ============================================================================
-- 1. Table: public.examination_grading_policies
--    Country & education-level configurable grading scales (no hardcoded global thresholds)
-- ============================================================================
create table if not exists public.examination_grading_policies (
  id uuid primary key default gen_random_uuid(),
  country_code text not null references public.countries (country_code) on delete restrict,
  education_level_code text, -- NULL = all levels in country, or e.g. 'PRIMARY', 'SECONDARY'
  policy_code text not null check (char_length(btrim(policy_code)) between 2 and 60),
  name text not null check (char_length(btrim(name)) between 3 and 160),
  description text not null default '',
  grade_bands jsonb not null check (jsonb_typeof(grade_bands) = 'array'),
  is_default boolean not null default false,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists examination_grading_policies_natural_uidx
  on public.examination_grading_policies (country_code, coalesce(education_level_code, '*'), policy_code);

drop trigger if exists examination_grading_policies_set_updated_at on public.examination_grading_policies;
create trigger examination_grading_policies_set_updated_at
  before update on public.examination_grading_policies
  for each row execute function public.set_updated_at();

alter table public.examination_grading_policies enable row level security;
revoke all on public.examination_grading_policies from public, anon, authenticated;
grant select on public.examination_grading_policies to anon, authenticated;
grant insert, update, delete on public.examination_grading_policies to authenticated;

drop policy if exists "Anyone reads active grading policies" on public.examination_grading_policies;
create policy "Anyone reads active grading policies"
  on public.examination_grading_policies for select
  using (is_active = true or public.has_role('super_admin') or public.is_current_super_admin());

drop policy if exists "Admins manage grading policies" on public.examination_grading_policies;
create policy "Admins manage grading policies"
  on public.examination_grading_policies for all to authenticated
  using (public.has_role('super_admin') or public.is_current_super_admin() or public.has_role('curriculum_admin', country_code))
  with check (public.has_role('super_admin') or public.is_current_super_admin() or public.has_role('curriculum_admin', country_code));

-- Seed country-specific grading policies dynamically for enabled countries
do $$
begin
  if exists (select 1 from public.countries where country_code = 'TZ') then
    insert into public.examination_grading_policies (
      country_code, education_level_code, policy_code, name, description, grade_bands, is_default, is_active
    ) values (
      'TZ', 'PRIMARY', 'TZ_PRIMARY_STANDARD',
      'Tanzania Primary Assessment Scale (A–E)',
      'Configurable primary education grading bands for Tanzania (TIE/NECTA aligned).',
      '[
        {"grade":"A","label":"Excellent","min_percentage":81,"max_percentage":100,"mastery_band":"strong"},
        {"grade":"B","label":"Very Good","min_percentage":61,"max_percentage":80.99,"mastery_band":"strong"},
        {"grade":"C","label":"Good","min_percentage":41,"max_percentage":60.99,"mastery_band":"developing"},
        {"grade":"D","label":"Satisfactory","min_percentage":21,"max_percentage":40.99,"mastery_band":"needs_improvement"},
        {"grade":"E","label":"Needs Support","min_percentage":0,"max_percentage":20.99,"mastery_band":"needs_improvement"}
      ]'::jsonb,
      true, true
    )
    on conflict (country_code, coalesce(education_level_code, '*'), policy_code) do update
      set name = excluded.name, grade_bands = excluded.grade_bands, is_default = true, is_active = true, updated_at = now();
  end if;

  if exists (select 1 from public.countries where country_code = 'KE') then
    insert into public.examination_grading_policies (
      country_code, education_level_code, policy_code, name, description, grade_bands, is_default, is_active
    ) values (
      'KE', 'PRIMARY', 'KE_CBC_PERFORMANCE',
      'Kenya CBC Performance Levels (EE–BE)',
      'Competency-Based Curriculum assessment rubric levels for Kenya primary education.',
      '[
        {"grade":"EE","label":"Exceeding Expectations","min_percentage":80,"max_percentage":100,"mastery_band":"strong"},
        {"grade":"ME","label":"Meeting Expectations","min_percentage":60,"max_percentage":79.99,"mastery_band":"strong"},
        {"grade":"AE","label":"Approaching Expectations","min_percentage":40,"max_percentage":59.99,"mastery_band":"developing"},
        {"grade":"BE","label":"Below Expectations","min_percentage":0,"max_percentage":39.99,"mastery_band":"needs_improvement"}
      ]'::jsonb,
      true, true
    )
    on conflict (country_code, coalesce(education_level_code, '*'), policy_code) do update
      set name = excluded.name, grade_bands = excluded.grade_bands, is_default = true, is_active = true, updated_at = now();
  end if;

  if exists (select 1 from public.countries where country_code = 'UG') then
    insert into public.examination_grading_policies (
      country_code, education_level_code, policy_code, name, description, grade_bands, is_default, is_active
    ) values (
      'UG', 'PRIMARY', 'UG_PRIMARY_AGGREGATE',
      'Uganda Primary Assessment Scale (D1–F9)',
      'Configurable primary education aggregate bands for Uganda.',
      '[
        {"grade":"D1","label":"Distinction 1","min_percentage":85,"max_percentage":100,"mastery_band":"strong"},
        {"grade":"D2","label":"Distinction 2","min_percentage":75,"max_percentage":84.99,"mastery_band":"strong"},
        {"grade":"C3-C6","label":"Credit","min_percentage":50,"max_percentage":74.99,"mastery_band":"developing"},
        {"grade":"P7-P8","label":"Pass","min_percentage":35,"max_percentage":49.99,"mastery_band":"needs_improvement"},
        {"grade":"F9","label":"Fail","min_percentage":0,"max_percentage":34.99,"mastery_band":"needs_improvement"}
      ]'::jsonb,
      true, true
    )
    on conflict (country_code, coalesce(education_level_code, '*'), policy_code) do update
      set name = excluded.name, grade_bands = excluded.grade_bands, is_default = true, is_active = true, updated_at = now();
  end if;
end $$;

-- ============================================================================
-- 2. Table: public.examination_offline_sync_batches (Phase 11 Offline Audit)
-- ============================================================================
create table if not exists public.examination_offline_sync_batches (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null references public.examination_attempts (id) on delete cascade,
  examination_id uuid not null references public.examinations (id) on delete cascade,
  learner_id uuid not null references public.learners (id) on delete cascade,
  client_device_id text not null default '',
  payload_sha256 text not null default '',
  synced_count integer not null default 0,
  synced_by uuid references auth.users (id) on delete set null,
  synced_at timestamptz not null default now()
);

create index if not exists exam_offline_sync_batches_attempt_idx
  on public.examination_offline_sync_batches (attempt_id, synced_at desc);

alter table public.examination_offline_sync_batches enable row level security;
revoke all on public.examination_offline_sync_batches from public, anon, authenticated;
grant select on public.examination_offline_sync_batches to authenticated;

drop policy if exists "Staff view offline sync batches" on public.examination_offline_sync_batches;
create policy "Staff view offline sync batches"
  on public.examination_offline_sync_batches for select to authenticated
  using (
    exists (
      select 1 from public.examinations e
      where e.id = examination_offline_sync_batches.examination_id
        and (public.can_publish_lesson(e.country_code) or public.can_review_lesson(e.country_code))
    )
  );

-- ============================================================================
-- 3. RPC: sync_exam_v2_offline_responses
--    Explicitly requires examinations.allow_offline_sync = true
-- ============================================================================
create or replace function public.sync_exam_v2_offline_responses(
  p_attempt_id uuid,
  p_responses jsonb,
  p_client_device_id text default '',
  p_payload_sha256 text default ''
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_attempt record;
  v_exam record;
  v_item jsonb;
  v_qid uuid;
  v_payload jsonb;
  v_q_marks numeric;
  v_count integer := 0;
  v_batch_id uuid;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select * into v_attempt from public.examination_attempts where id = p_attempt_id;
  if not found then
    raise exception 'Attempt % not found', p_attempt_id using errcode = '22023';
  end if;

  select * into v_exam from public.examinations where id = v_attempt.examination_id;
  if not coalesce(v_exam.allow_offline_sync, false) then
    raise exception 'Offline synchronization is not enabled for this examination' using errcode = '42501';
  end if;

  if v_attempt.status <> 'in_progress' then
    raise exception 'Cannot sync offline responses: attempt is already closed' using errcode = '22023';
  end if;

  if jsonb_typeof(coalesce(p_responses, '[]'::jsonb)) <> 'array' then
    raise exception 'p_responses must be a JSON array' using errcode = '22023';
  end if;

  for v_item in select * from jsonb_array_elements(coalesce(p_responses, '[]'::jsonb))
  loop
    v_qid := (v_item ->> 'examination_question_id')::uuid;
    v_payload := coalesce(v_item -> 'response_payload', '{}'::jsonb);

    select marks into v_q_marks
    from public.examination_questions
    where id = v_qid and examination_id = v_attempt.examination_id;

    if found then
      insert into public.examination_responses (
        attempt_id, examination_question_id, response_payload, saved_at, max_marks, marking_status
      ) values (
        p_attempt_id, v_qid, v_payload, now(), v_q_marks, 'pending'
      )
      on conflict (attempt_id, examination_question_id) do update
        set response_payload = excluded.response_payload,
            saved_at = now();
      v_count := v_count + 1;
    end if;
  end loop;

  insert into public.examination_offline_sync_batches (
    attempt_id, examination_id, learner_id, client_device_id, payload_sha256, synced_count, synced_by
  ) values (
    p_attempt_id, v_attempt.examination_id, v_attempt.learner_id,
    coalesce(btrim(p_client_device_id), ''), coalesce(btrim(p_payload_sha256), ''), v_count, v_uid
  )
  returning id into v_batch_id;

  return jsonb_build_object(
    'batch_id', v_batch_id,
    'attempt_id', p_attempt_id,
    'synced_count', v_count
  );
end;
$$;

-- ============================================================================
-- 4. RPC: resolve_exam_v2_grade_band
-- ============================================================================
create or replace function public.resolve_exam_v2_grade_band(
  p_country_code text,
  p_education_level_code text,
  p_percentage numeric
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_country text := upper(btrim(coalesce(p_country_code, 'TZ')));
  v_lvl text := nullif(upper(btrim(coalesce(p_education_level_code, ''))), '');
  v_policy record;
  v_band jsonb;
begin
  select * into v_policy
  from public.examination_grading_policies gp
  where upper(gp.country_code) = v_country
    and gp.is_active = true
    and (gp.education_level_code is null or upper(gp.education_level_code) = v_lvl)
  order by (case when upper(gp.education_level_code) = v_lvl then 0 else 1 end), gp.is_default desc
  limit 1;

  if not found then
    return jsonb_build_object('policy_code', null, 'grade', null, 'label', 'Unconfigured', 'mastery_band', 'developing');
  end if;

  select b into v_band
  from jsonb_array_elements(v_policy.grade_bands) b
  where p_percentage >= coalesce((b ->> 'min_percentage')::numeric, 0)
    and p_percentage <= coalesce((b ->> 'max_percentage')::numeric, 100)
  limit 1;

  return jsonb_build_object(
    'policy_code', v_policy.policy_code,
    'policy_name', v_policy.name,
    'grade', v_band ->> 'grade',
    'label', v_band ->> 'label',
    'mastery_band', coalesce(v_band ->> 'mastery_band', 'developing')
  );
end;
$$;

-- ============================================================================
-- 5. RPC: list_exam_v2_grading_policies
-- ============================================================================
create or replace function public.list_exam_v2_grading_policies(
  p_country_code text default null
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
  return coalesce(
    (
      select jsonb_agg(
        jsonb_build_object(
          'id', gp.id,
          'country_code', gp.country_code,
          'education_level_code', gp.education_level_code,
          'policy_code', gp.policy_code,
          'name', gp.name,
          'description', gp.description,
          'grade_bands', gp.grade_bands,
          'is_default', gp.is_default
        )
        order by (case when gp.country_code = 'TZ' then 0 else 1 end), gp.country_code, gp.policy_code
      )
      from public.examination_grading_policies gp
      where gp.is_active = true
        and (v_country is null or upper(gp.country_code) = v_country)
    ),
    '[]'::jsonb
  );
end;
$$;

revoke all on function public.sync_exam_v2_offline_responses(uuid, jsonb, text, text) from public, anon;
grant execute on function public.sync_exam_v2_offline_responses(uuid, jsonb, text, text) to authenticated, service_role;

revoke all on function public.resolve_exam_v2_grade_band(text, text, numeric) from public;
grant execute on function public.resolve_exam_v2_grade_band(text, text, numeric) to anon, authenticated, service_role;

revoke all on function public.list_exam_v2_grading_policies(text) from public;
grant execute on function public.list_exam_v2_grading_policies(text) to anon, authenticated, service_role;

commit;
