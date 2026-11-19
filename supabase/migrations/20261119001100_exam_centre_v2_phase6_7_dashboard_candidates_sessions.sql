-- ============================================================================
-- LearnTZ Examination Centre 2.0 — Phase 6 & 7: Examination Dashboard,
-- Candidate Management & Examination Sessions
-- Migration: 20261119001100_exam_centre_v2_phase6_7_dashboard_candidates_sessions.sql
--
-- Reuses public.examinations and public.learners. Enforces server-side learner
-- eligibility validation, unique examination numbers, attendance tracking,
-- and real DB-derived dashboard metrics.
-- ============================================================================

begin;

-- ============================================================================
-- 1. Table: public.examination_sessions
-- ============================================================================
create table if not exists public.examination_sessions (
  id uuid primary key default gen_random_uuid(),
  examination_id uuid not null references public.examinations (id) on delete cascade,
  title text not null check (char_length(btrim(title)) between 3 and 200),
  delivery_mode text not null default 'online' check (delivery_mode in ('online', 'printed', 'hybrid')),
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  venue text not null default '',
  instructions text not null default '',
  status text not null default 'scheduled' check (status in ('scheduled', 'active', 'completed', 'cancelled')),
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint examination_sessions_time_window_check check (ends_at > starts_at)
);

create index if not exists examination_sessions_exam_starts_idx
  on public.examination_sessions (examination_id, starts_at asc);

drop trigger if exists examination_sessions_set_updated_at on public.examination_sessions;
create trigger examination_sessions_set_updated_at
  before update on public.examination_sessions
  for each row execute function public.set_updated_at();

alter table public.examination_sessions enable row level security;
revoke all on public.examination_sessions from public, anon, authenticated;
grant select, insert, update, delete on public.examination_sessions to authenticated;

drop policy if exists "Authorized staff and readers view examination sessions" on public.examination_sessions;
create policy "Authorized staff and readers view examination sessions"
  on public.examination_sessions for select to authenticated
  using (
    exists (
      select 1 from public.examinations e
      where e.id = examination_sessions.examination_id
        and (
          e.is_published = true
          or e.author_id = auth.uid()
          or public.can_author_lesson(e.country_code)
          or public.can_review_lesson(e.country_code)
          or public.can_publish_lesson(e.country_code)
        )
    )
  );

drop policy if exists "Authorized staff manage examination sessions" on public.examination_sessions;
create policy "Authorized staff manage examination sessions"
  on public.examination_sessions for all to authenticated
  using (
    exists (
      select 1 from public.examinations e
      where e.id = examination_sessions.examination_id
        and (public.can_publish_lesson(e.country_code) or public.can_author_lesson(e.country_code))
    )
  )
  with check (
    exists (
      select 1 from public.examinations e
      where e.id = examination_sessions.examination_id
        and (public.can_publish_lesson(e.country_code) or public.can_author_lesson(e.country_code))
    )
  );

-- ============================================================================
-- 2. Table: public.examination_candidates
-- ============================================================================
create table if not exists public.examination_candidates (
  id uuid primary key default gen_random_uuid(),
  examination_id uuid not null references public.examinations (id) on delete cascade,
  session_id uuid references public.examination_sessions (id) on delete set null,
  learner_id uuid not null references public.learners (id) on delete cascade,
  examination_number text not null check (char_length(btrim(examination_number)) between 3 and 64),
  status text not null default 'registered' check (status in ('registered', 'started', 'submitted', 'absent', 'disqualified')),
  attendance_status text not null default 'pending' check (attendance_status in ('pending', 'present', 'absent', 'excused')),
  eligibility_override boolean not null default false,
  eligibility_override_reason text,
  registered_by uuid references auth.users (id) on delete set null,
  registered_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (examination_id, learner_id),
  unique (examination_id, examination_number)
);

create index if not exists examination_candidates_exam_idx
  on public.examination_candidates (examination_id, status, attendance_status);

create index if not exists examination_candidates_learner_idx
  on public.examination_candidates (learner_id);

drop trigger if exists examination_candidates_set_updated_at on public.examination_candidates;
create trigger examination_candidates_set_updated_at
  before update on public.examination_candidates
  for each row execute function public.set_updated_at();

alter table public.examination_candidates enable row level security;
revoke all on public.examination_candidates from public, anon, authenticated;
grant select, insert, update, delete on public.examination_candidates to authenticated;

drop policy if exists "Authorized staff manage examination candidates" on public.examination_candidates;
create policy "Authorized staff manage examination candidates"
  on public.examination_candidates for all to authenticated
  using (
    exists (
      select 1 from public.examinations e
      where e.id = examination_candidates.examination_id
        and (
          public.can_publish_lesson(e.country_code)
          or public.can_review_lesson(e.country_code)
          or public.can_author_lesson(e.country_code)
        )
    )
  )
  with check (
    exists (
      select 1 from public.examinations e
      where e.id = examination_candidates.examination_id
        and (public.can_publish_lesson(e.country_code) or public.can_author_lesson(e.country_code))
    )
  );

-- ============================================================================
-- 3. RPC: get_exam_v2_dashboard
--    100% real DB-derived metrics, recent activity & upcoming sessions
-- ============================================================================
create or replace function public.get_exam_v2_dashboard(
  p_country_code text default null,
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
  v_total integer := 0;
  v_draft integer := 0;
  v_review integer := 0;
  v_approved integer := 0;
  v_published integer := 0;
  v_completed integer := 0;
  v_candidates integer := 0;
  v_upcoming integer := 0;
  v_recent jsonb := '[]'::jsonb;
  v_sessions jsonb := '[]'::jsonb;
begin
  with scoped_exams as (
    select
      e.*,
      eg.name as grade_name,
      s.name as subject_name,
      et.name as examination_type_name
    from public.examinations e
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
  )
  select
    count(*)::integer,
    count(*) filter (where status in ('draft', 'revision_requested'))::integer,
    count(*) filter (where status in ('submitted_for_review', 'under_review'))::integer,
    count(*) filter (where status = 'approved')::integer,
    count(*) filter (where status in ('published', 'active'))::integer,
    count(*) filter (where status in ('completed', 'results_released'))::integer,
    coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'id', r.id,
            'title', r.title,
            'grade_name', r.grade_name,
            'subject_name', r.subject_name,
            'examination_type_name', r.examination_type_name,
            'status', r.status,
            'total_marks', r.total_marks,
            'updated_at', r.updated_at
          )
        )
        from (select * from scoped_exams order by updated_at desc limit 8) r
      ),
      '[]'::jsonb
    )
  into v_total, v_draft, v_review, v_approved, v_published, v_completed, v_recent
  from scoped_exams;

  select count(*)::integer into v_candidates
  from public.examination_candidates ec
  join public.examinations e on e.id = ec.examination_id
  where (v_country is null or upper(e.country_code) = v_country)
    and (p_education_level_id is null or e.education_level_id = p_education_level_id)
    and (p_grade_id is null or e.grade_id = p_grade_id)
    and (p_subject_id is null or e.subject_id = p_subject_id);

  select
    count(*)::integer,
    coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'id', s.id,
            'examination_id', s.examination_id,
            'examination_title', s.exam_title,
            'title', s.title,
            'delivery_mode', s.delivery_mode,
            'starts_at', s.starts_at,
            'ends_at', s.ends_at,
            'venue', s.venue,
            'status', s.status
          )
        )
        from (
          select es.*, e.title as exam_title
          from public.examination_sessions es
          join public.examinations e on e.id = es.examination_id
          where es.status in ('scheduled', 'active')
            and es.ends_at >= now()
            and (v_country is null or upper(e.country_code) = v_country)
            and (p_education_level_id is null or e.education_level_id = p_education_level_id)
            and (p_grade_id is null or e.grade_id = p_grade_id)
            and (p_subject_id is null or e.subject_id = p_subject_id)
          order by es.starts_at asc
          limit 5
        ) s
      ),
      '[]'::jsonb
    )
  into v_upcoming, v_sessions
  from public.examination_sessions es
  join public.examinations e on e.id = es.examination_id
  where es.status in ('scheduled', 'active')
    and es.ends_at >= now()
    and (v_country is null or upper(e.country_code) = v_country)
    and (p_education_level_id is null or e.education_level_id = p_education_level_id)
    and (p_grade_id is null or e.grade_id = p_grade_id)
    and (p_subject_id is null or e.subject_id = p_subject_id);

  return jsonb_build_object(
    'metrics', jsonb_build_object(
      'total_examinations', v_total,
      'draft_count', v_draft,
      'under_review_count', v_review,
      'approved_count', v_approved,
      'published_count', v_published,
      'completed_count', v_completed,
      'total_candidates', v_candidates,
      'upcoming_sessions_count', v_upcoming
    ),
    'recent_activity', v_recent,
    'upcoming_sessions', v_sessions
  );
end;
$$;

-- ============================================================================
-- 4. RPC: create_exam_v2_session
-- ============================================================================
create or replace function public.create_exam_v2_session(
  p_examination_id uuid,
  p_title text,
  p_starts_at timestamptz,
  p_ends_at timestamptz,
  p_delivery_mode text default 'online',
  p_venue text default '',
  p_instructions text default ''
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_exam record;
  v_id uuid;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select * into v_exam from public.examinations where id = p_examination_id;
  if not found then
    raise exception 'Examination % not found', p_examination_id using errcode = '22023';
  end if;

  if not (public.can_publish_lesson(v_exam.country_code) or public.can_author_lesson(v_exam.country_code)) then
    raise exception 'Permission denied: scheduling sessions requires authorized staff role' using errcode = '42501';
  end if;

  if p_ends_at <= p_starts_at then
    raise exception 'Session end time must be after start time' using errcode = '22023';
  end if;

  insert into public.examination_sessions (
    examination_id, title, delivery_mode, starts_at, ends_at, venue, instructions, created_by
  ) values (
    p_examination_id, btrim(p_title), coalesce(nullif(btrim(p_delivery_mode), ''), 'online'),
    p_starts_at, p_ends_at, coalesce(p_venue, ''), coalesce(p_instructions, ''), v_uid
  )
  returning id into v_id;

  return jsonb_build_object('id', v_id, 'examination_id', p_examination_id, 'status', 'scheduled');
end;
$$;

-- ============================================================================
-- 5. RPC: register_exam_v2_candidate
--    Enforces Section 8 learner eligibility (country & grade match unless
--    authorized administrator provides an explicit override reason)
-- ============================================================================
create or replace function public.register_exam_v2_candidate(
  p_examination_id uuid,
  p_learner_id uuid,
  p_session_id uuid default null,
  p_override_eligibility boolean default false,
  p_override_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_exam record;
  v_learner record;
  v_exam_grade_code text;
  v_seq integer;
  v_exam_number text;
  v_cand_id uuid;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select e.*, eg.code as grade_code, eg.name as grade_name
  into v_exam
  from public.examinations e
  join public.education_grades eg on eg.id = e.grade_id
  where e.id = p_examination_id;

  if not found then
    raise exception 'Examination % not found', p_examination_id using errcode = '22023';
  end if;

  if not (public.can_publish_lesson(v_exam.country_code) or public.can_author_lesson(v_exam.country_code)) then
    raise exception 'Permission denied: registering candidates requires authorized staff role' using errcode = '42501';
  end if;

  select * into v_learner from public.learners where id = p_learner_id;
  if not found then
    raise exception 'Learner % not found', p_learner_id using errcode = '22023';
  end if;

  v_exam_grade_code := upper(coalesce(v_exam.grade_code, ''));

  -- Check eligibility: country and grade_id must match unless authorized admin overrides
  if upper(coalesce(v_learner.country_code, '')) <> upper(v_exam.country_code)
     or v_learner.grade_id <> v_exam.grade_id then
    if not coalesce(p_override_eligibility, false) then
      raise exception 'Learner eligibility mismatch: learner profile (% / grade %) does not match examination (% / %)',
        coalesce(v_learner.country_code, '?'), v_learner.grade_id,
        v_exam.country_code, v_exam.grade_name
        using errcode = '22023';
    end if;
    if not public.can_publish_lesson(v_exam.country_code) then
      raise exception 'Permission denied: eligibility override requires curriculum_admin or super_admin role'
        using errcode = '42501';
    end if;
    if nullif(btrim(coalesce(p_override_reason, '')), '') is null then
      raise exception 'An explicit reason is required for learner eligibility override' using errcode = '22023';
    end if;
  end if;

  select count(*)::integer + 1 into v_seq
  from public.examination_candidates
  where examination_id = p_examination_id;

  v_exam_number := upper(v_exam.country_code) || '-' || v_exam.academic_year::text || '-' || lpad(v_seq::text, 4, '0');

  insert into public.examination_candidates (
    examination_id, session_id, learner_id, examination_number,
    eligibility_override, eligibility_override_reason, registered_by
  ) values (
    p_examination_id, p_session_id, p_learner_id, v_exam_number,
    coalesce(p_override_eligibility, false), nullif(btrim(coalesce(p_override_reason, '')), ''), v_uid
  )
  returning id into v_cand_id;

  return jsonb_build_object(
    'id', v_cand_id,
    'examination_number', v_exam_number,
    'status', 'registered'
  );
end;
$$;

-- ============================================================================
-- 6. RPC: record_exam_v2_attendance
-- ============================================================================
create or replace function public.record_exam_v2_attendance(
  p_candidate_id uuid,
  p_attendance_status text
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_country text;
  v_att text := lower(btrim(coalesce(p_attendance_status, '')));
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select e.country_code into v_country
  from public.examination_candidates ec
  join public.examinations e on e.id = ec.examination_id
  where ec.id = p_candidate_id;

  if not found then
    raise exception 'Candidate % not found', p_candidate_id using errcode = '22023';
  end if;

  if not (public.can_publish_lesson(v_country) or public.can_author_lesson(v_country) or public.can_review_lesson(v_country)) then
    raise exception 'Permission denied' using errcode = '42501';
  end if;

  update public.examination_candidates
  set attendance_status = v_att,
      status = case when v_att = 'absent' then 'absent' when status = 'absent' and v_att = 'present' then 'registered' else status end,
      updated_at = now()
  where id = p_candidate_id;

  return jsonb_build_object('id', p_candidate_id, 'attendance_status', v_att);
end;
$$;

-- ============================================================================
-- 7. RPC: list_exam_v2_candidates_and_sessions
-- ============================================================================
create or replace function public.list_exam_v2_candidates_and_sessions(
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
  v_country text;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select country_code into v_country from public.examinations where id = p_examination_id;
  if not found then
    raise exception 'Examination % not found', p_examination_id using errcode = '22023';
  end if;

  if not (public.can_publish_lesson(v_country) or public.can_author_lesson(v_country) or public.can_review_lesson(v_country)) then
    raise exception 'Permission denied' using errcode = '42501';
  end if;

  return jsonb_build_object(
    'sessions', coalesce(
      (
        select jsonb_agg(to_jsonb(es) order by es.starts_at asc)
        from public.examination_sessions es
        where es.examination_id = p_examination_id
      ),
      '[]'::jsonb
    ),
    'candidates', coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'id', ec.id,
            'examination_id', ec.examination_id,
            'session_id', ec.session_id,
            'learner_id', ec.learner_id,
            'learner_name', btrim(l.first_name || ' ' || l.last_name),
            'grade_name', eg.name,
            'examination_number', ec.examination_number,
            'status', ec.status,
            'attendance_status', ec.attendance_status,
            'eligibility_override', ec.eligibility_override,
            'registered_at', ec.registered_at
          )
          order by ec.examination_number asc
        )
        from public.examination_candidates ec
        join public.learners l on l.id = ec.learner_id
        left join public.education_grades eg on eg.id = l.grade_id
        where ec.examination_id = p_examination_id
      ),
      '[]'::jsonb
    )
  );
end;
$$;

revoke all on function public.get_exam_v2_dashboard(text, uuid, uuid, uuid) from public;
grant execute on function public.get_exam_v2_dashboard(text, uuid, uuid, uuid) to anon, authenticated, service_role;

revoke all on function public.create_exam_v2_session(uuid, text, timestamptz, timestamptz, text, text, text) from public, anon;
grant execute on function public.create_exam_v2_session(uuid, text, timestamptz, timestamptz, text, text, text) to authenticated, service_role;

revoke all on function public.register_exam_v2_candidate(uuid, uuid, uuid, boolean, text) from public, anon;
grant execute on function public.register_exam_v2_candidate(uuid, uuid, uuid, boolean, text) to authenticated, service_role;

revoke all on function public.record_exam_v2_attendance(uuid, text) from public, anon;
grant execute on function public.record_exam_v2_attendance(uuid, text) to authenticated, service_role;

revoke all on function public.list_exam_v2_candidates_and_sessions(uuid) from public, anon;
grant execute on function public.list_exam_v2_candidates_and_sessions(uuid) to authenticated, service_role;

commit;
