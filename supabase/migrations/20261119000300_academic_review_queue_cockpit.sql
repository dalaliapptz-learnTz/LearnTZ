-- ============================================================================
-- LearnTZ — Academic Review Queue Cockpit Backend RPCs, Assignment & Immutable Audit
-- Migration: 20261119000300_academic_review_queue_cockpit.sql
--
-- Reuses existing public.lessons, public.lesson_revisions, public.lesson_review_events,
-- and existing RBAC helpers (can_review_lesson, can_approve_lesson, can_publish_lesson).
-- ============================================================================

begin;

-- 1. Extend lesson_review_events action check to include reviewer_assigned
do $$
declare
  v_conname text;
begin
  for v_conname in
    select conname
    from pg_constraint
    where conrelid = 'public.lesson_review_events'::regclass
      and contype = 'c'
      and pg_get_constraintdef(oid) ilike '%action%'
  loop
    execute format('alter table public.lesson_review_events drop constraint if exists %I', v_conname);
  end loop;
end $$;

alter table public.lesson_review_events
  add constraint lesson_review_events_action_check check (action in (
    'draft_saved',
    'submitted_for_review',
    'reviewer_assigned',
    'revision_requested',
    'approved',
    'published',
    'archived',
    'reopened_draft'
  ));

-- 2. Enforce immutability of lesson_review_events (audit records cannot be modified or deleted)
create or replace function public.prevent_lesson_review_event_mutation()
returns trigger
language plpgsql
as $$
begin
  raise exception 'Immutable audit log violation: lesson_review_events records cannot be modified or deleted'
    using errcode = '42501';
end;
$$;

drop trigger if exists lesson_review_events_immutable on public.lesson_review_events;
create trigger lesson_review_events_immutable
  before update or delete on public.lesson_review_events
  for each row execute function public.prevent_lesson_review_event_mutation();

-- 3. Performance index for Academic Review Queue filtering & pagination
create index if not exists lessons_review_queue_idx
  on public.lessons (status, country_code, subject_id, grade_id, submitted_at desc nulls last, updated_at desc);

-- 4. RPC: get_academic_review_queue_summary
--    Returns actual database-derived counts & filter options for authorized reviewers/admins
create or replace function public.get_academic_review_queue_summary(
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
  v_awaiting integer := 0;
  v_revision integer := 0;
  v_approved integer := 0;
  v_published integer := 0;
  v_assigned_to_me integer := 0;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  if not (public.can_review_lesson(v_country) or public.can_publish_lesson(v_country)) then
    raise exception 'Permission denied: academic review queue requires academic_reviewer or curriculum_admin role'
      using errcode = '42501';
  end if;

  select
    count(*) filter (where l.status = 'in_review')::integer,
    count(*) filter (where l.status = 'revision_requested')::integer,
    count(*) filter (where l.status = 'approved')::integer,
    count(*) filter (where l.status = 'published')::integer,
    count(*) filter (where l.status = 'in_review' and l.reviewer_id = v_uid)::integer
  into v_awaiting, v_revision, v_approved, v_published, v_assigned_to_me
  from public.lessons l
  join public.topics t on t.id = l.topic_id
  join public.subjects s on s.id = t.subject_id
  where (v_country is null or coalesce(l.country_code, s.country_code) = v_country)
    and (
      public.has_role('super_admin')
      or public.can_review_lesson(coalesce(l.country_code, s.country_code))
      or public.can_publish_lesson(coalesce(l.country_code, s.country_code))
    );

  return jsonb_build_object(
    'country_code', coalesce(v_country, 'ALL'),
    'awaiting_review_count', v_awaiting,
    'revision_requested_count', v_revision,
    'approved_count', v_approved,
    'published_count', v_published,
    'assigned_to_me_count', v_assigned_to_me,
    'capabilities', public.get_lesson_authoring_capabilities(v_country),
    'filter_options', jsonb_build_object(
      'countries', coalesce(
        (
          select jsonb_agg(
            jsonb_build_object(
              'country_code', co.country_code,
              'display_name', co.display_name
            ) order by (case when co.country_code = 'TZ' then 0 else 1 end), co.country_code
          )
          from public.countries co
          where co.is_enabled = true
        ),
        '[]'::jsonb
      ),
      'education_levels', coalesce(
        (
          select jsonb_agg(
            jsonb_build_object(
              'id', el.id,
              'name', el.name,
              'code', el.code,
              'country_code', c.country_code
            ) order by c.country_code, el.sequence
          )
          from public.education_levels el
          join public.curricula c on c.id = el.curriculum_id
          where el.is_enabled = true
            and (v_country is null or c.country_code = v_country)
        ),
        '[]'::jsonb
      ),
      'grades', coalesce(
        (
          select jsonb_agg(
            jsonb_build_object(
              'id', eg.id,
              'name', eg.name,
              'code', eg.code,
              'education_level_id', eg.education_level_id,
              'country_code', c.country_code
            ) order by c.country_code, el.sequence, eg.sequence
          )
          from public.education_grades eg
          join public.education_levels el on el.id = eg.education_level_id
          join public.curricula c on c.id = eg.curriculum_id
          where eg.is_enabled = true
            and (v_country is null or c.country_code = v_country)
        ),
        '[]'::jsonb
      ),
      'subjects', coalesce(
        (
          select jsonb_agg(
            jsonb_build_object(
              'id', s.id,
              'name', s.name,
              'code', s.code,
              'grade_id', s.grade_id,
              'grade_name', eg.name,
              'education_level_id', s.education_level_id,
              'country_code', s.country_code
            ) order by s.country_code, coalesce(eg.sequence, 0), s.display_order, s.name
          )
          from public.subjects s
          left join public.education_grades eg on eg.id = s.grade_id
          where s.is_published = true
            and (v_country is null or s.country_code = v_country)
        ),
        '[]'::jsonb
      )
    )
  );
end;
$$;

-- 5. RPC: list_academic_review_queue
--    Multi-country, multi-filter, paginated review queue backed by real database records
create or replace function public.list_academic_review_queue(
  p_country_code text default null,
  p_education_level_id uuid default null,
  p_grade_id uuid default null,
  p_subject_id uuid default null,
  p_status text default 'all_reviewable',
  p_search text default null,
  p_assigned_reviewer_id uuid default null,
  p_only_unassigned boolean default false,
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
  v_status text := nullif(lower(btrim(coalesce(p_status, 'all_reviewable'))), '');
  v_search text := nullif(btrim(coalesce(p_search, '')), '');
  v_limit integer := greatest(1, least(coalesce(p_limit, 20), 100));
  v_offset integer := greatest(0, coalesce(p_offset, 0));
  v_total integer := 0;
  v_items jsonb := '[]'::jsonb;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  if not (public.can_review_lesson(v_country) or public.can_publish_lesson(v_country)) then
    raise exception 'Permission denied: academic review queue requires academic_reviewer or curriculum_admin role'
      using errcode = '42501';
  end if;

  with filtered as (
    select
      l.id as lesson_id,
      l.title,
      coalesce(l.country_code, s.country_code) as country_code,
      coalesce(co.display_name, coalesce(l.country_code, s.country_code)) as country_name,
      coalesce(l.curriculum_id, s.curriculum_id) as curriculum_id,
      coalesce(c.name, 'National Curriculum') as curriculum_name,
      coalesce(cv.display_name, cv.version_code) as curriculum_version_name,
      coalesce(l.education_level_id, s.education_level_id) as education_level_id,
      coalesce(el.name, 'Primary Education') as education_level_name,
      coalesce(l.grade_id, s.grade_id) as grade_id,
      coalesce(eg.name, 'Unspecified Grade') as grade_name,
      coalesce(l.subject_id, s.id) as subject_id,
      s.name as subject_name,
      s.code as subject_code,
      mc.code as main_competence_code,
      mc.title as main_competence_title,
      sc.code as specific_competence_code,
      sc.title as specific_competence_title,
      l.author_id,
      coalesce(
        author_prof.full_name,
        author_usr.raw_user_meta_data ->> 'full_name',
        author_usr.email,
        'Unknown Author'
      ) as author_name,
      l.reviewer_id,
      coalesce(
        rev_prof.full_name,
        rev_usr.raw_user_meta_data ->> 'full_name',
        rev_usr.email
      ) as reviewer_name,
      l.submitted_at,
      l.approved_at,
      l.published_at,
      l.updated_at,
      l.status,
      l.is_published,
      l.version_number,
      l.review_notes,
      (select count(*)::integer from public.question_bank qb where qb.lesson_id = l.id) as question_count
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
    left join public.profiles author_prof on author_prof.id = l.author_id
    left join auth.users author_usr on author_usr.id = l.author_id
    left join public.profiles rev_prof on rev_prof.id = l.reviewer_id
    left join auth.users rev_usr on rev_usr.id = l.reviewer_id
    where (
        public.has_role('super_admin')
        or public.can_review_lesson(coalesce(l.country_code, s.country_code))
        or public.can_publish_lesson(coalesce(l.country_code, s.country_code))
      )
      and (v_country is null or coalesce(l.country_code, s.country_code) = v_country)
      and (p_education_level_id is null or coalesce(l.education_level_id, s.education_level_id) = p_education_level_id)
      and (p_grade_id is null or coalesce(l.grade_id, s.grade_id) = p_grade_id)
      and (p_subject_id is null or coalesce(l.subject_id, s.id) = p_subject_id)
      and (
        (v_status = 'all_reviewable' and l.status in ('in_review', 'revision_requested', 'approved'))
        or (v_status = 'all' and l.status in ('in_review', 'revision_requested', 'approved', 'published'))
        or (v_status not in ('all_reviewable', 'all') and l.status = v_status)
      )
      and (
        v_search is null
        or l.title ilike '%' || v_search || '%'
        or coalesce(s.name, '') ilike '%' || v_search || '%'
        or coalesce(sc.title, '') ilike '%' || v_search || '%'
        or coalesce(mc.title, '') ilike '%' || v_search || '%'
      )
      and (
        (p_only_unassigned = true and l.reviewer_id is null)
        or (p_only_unassigned = false and (p_assigned_reviewer_id is null or l.reviewer_id = p_assigned_reviewer_id))
      )
  )
  select
    (select count(*)::integer from filtered),
    coalesce(
      (
        select jsonb_agg(row_data)
        from (
          select to_jsonb(f) as row_data
          from filtered f
          order by
            case f.status
              when 'in_review' then 1
              when 'revision_requested' then 2
              when 'approved' then 3
              when 'published' then 4
              else 5
            end,
            coalesce(f.submitted_at, f.updated_at) desc
          limit v_limit
          offset v_offset
        ) paged
      ),
      '[]'::jsonb
    )
  into v_total, v_items;

  return jsonb_build_object(
    'total_count', v_total,
    'limit', v_limit,
    'offset', v_offset,
    'has_more', (v_offset + v_limit) < v_total,
    'items', v_items
  );
end;
$$;

-- 6. RPC: assign_lesson_reviewer
--    Allows authorized reviewers to claim a lesson or curriculum_admin to assign a reviewer
create or replace function public.assign_lesson_reviewer(
  p_lesson_id uuid,
  p_reviewer_id uuid default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_target_reviewer uuid := coalesce(p_reviewer_id, auth.uid());
  v_lesson record;
  v_country text;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select l.*, s.country_code as subject_country_code
  into v_lesson
  from public.lessons l
  join public.topics t on t.id = l.topic_id
  join public.subjects s on s.id = t.subject_id
  where l.id = p_lesson_id;

  if not found then
    raise exception 'Lesson % not found', p_lesson_id using errcode = '22023';
  end if;

  v_country := coalesce(v_lesson.country_code, v_lesson.subject_country_code);

  if not (public.can_review_lesson(v_country) or public.can_publish_lesson(v_country)) then
    raise exception 'Permission denied: only authorized reviewers or curriculum admins can assign reviewers'
      using errcode = '42501';
  end if;

  -- Non-admins may only claim for themselves
  if v_target_reviewer <> v_uid and not public.can_publish_lesson(v_country) then
    raise exception 'Permission denied: reviewers can only assign themselves; curriculum admins may assign other reviewers'
      using errcode = '42501';
  end if;

  -- Prevent author from self-assigning as reviewer (except super_admin)
  if v_lesson.author_id = v_target_reviewer and not public.has_role('super_admin') then
    raise exception 'Two-party governance violation: lesson author cannot be assigned as reviewer'
      using errcode = '42501';
  end if;

  update public.lessons
  set reviewer_id = v_target_reviewer,
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
    'reviewer_assigned',
    v_lesson.status,
    v_lesson.status,
    v_lesson.version_number,
    'Assigned reviewer: ' || v_target_reviewer::text
  );

  return jsonb_build_object(
    'lesson_id', p_lesson_id,
    'reviewer_id', v_target_reviewer,
    'status', v_lesson.status
  );
end;
$$;

revoke all on function public.get_academic_review_queue_summary(text) from public, anon;
revoke all on function public.list_academic_review_queue(text, uuid, uuid, uuid, text, text, uuid, boolean, integer, integer) from public, anon;
revoke all on function public.assign_lesson_reviewer(uuid, uuid) from public, anon;

grant execute on function public.get_academic_review_queue_summary(text) to authenticated, service_role;
grant execute on function public.list_academic_review_queue(text, uuid, uuid, uuid, text, text, uuid, boolean, integer, integer) to authenticated, service_role;
grant execute on function public.assign_lesson_reviewer(uuid, uuid) to authenticated, service_role;

commit;
