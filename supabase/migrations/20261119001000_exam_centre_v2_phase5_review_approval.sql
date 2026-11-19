-- ============================================================================
-- LearnTZ Examination Centre 2.0 — Phase 5: Academic Review & Approval Cockpit
-- Migration: 20261119001000_exam_centre_v2_phase5_review_approval.sql
--
-- Adds RBAC-protected examination review queue RPC and structured reviewer
-- checklist decision RPC backed by transition_exam_v2_status & immutable audit.
-- ============================================================================

begin;

-- 1. RPC: list_exam_v2_review_queue
create or replace function public.list_exam_v2_review_queue(
  p_country_code text default null,
  p_status text default 'all_reviewable',
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
  v_status text := nullif(lower(btrim(coalesce(p_status, 'all_reviewable'))), '');
  v_search text := nullif(btrim(coalesce(p_search, '')), '');
  v_limit integer := greatest(1, least(coalesce(p_limit, 20), 100));
  v_offset integer := greatest(0, coalesce(p_offset, 0));
  v_awaiting integer := 0;
  v_revision integer := 0;
  v_approved integer := 0;
  v_published integer := 0;
  v_total integer := 0;
  v_items jsonb := '[]'::jsonb;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  if not (public.can_review_lesson(v_country) or public.can_publish_lesson(v_country)) then
    raise exception 'Permission denied: examination review queue requires academic_reviewer or curriculum_admin role'
      using errcode = '42501';
  end if;

  with scoped as (
    select
      e.id as examination_id,
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
      e.duration_minutes,
      e.total_marks,
      e.status,
      e.is_published,
      e.version_number,
      e.author_id,
      coalesce(
        ap.full_name,
        au.raw_user_meta_data ->> 'full_name',
        au.email,
        'Unknown Author'
      ) as author_name,
      e.review_notes,
      e.submitted_at,
      e.updated_at,
      (select count(*)::integer from public.examination_sections es where es.examination_id = e.id) as section_count,
      (select count(*)::integer from public.examination_questions eq where eq.examination_id = e.id) as question_count,
      (select count(*)::integer from public.examination_competencies ec where ec.examination_id = e.id) as competency_count
    from public.examinations e
    join public.countries co on co.country_code = e.country_code
    join public.curricula c on c.id = e.curriculum_id
    left join public.curriculum_versions cv on cv.id = e.curriculum_version_id
    join public.education_levels el on el.id = e.education_level_id
    join public.education_grades eg on eg.id = e.grade_id
    join public.subjects s on s.id = e.subject_id
    join public.examination_types et on et.id = e.examination_type_id
    left join public.profiles ap on ap.id = e.author_id
    left join auth.users au on au.id = e.author_id
    where (
        public.has_role('super_admin')
        or public.is_current_super_admin()
        or public.can_review_lesson(e.country_code)
        or public.can_publish_lesson(e.country_code)
      )
      and (v_country is null or upper(e.country_code) = v_country)
  ),
  filtered as (
    select * from scoped
    where (
        (v_status = 'all_reviewable' and status in ('submitted_for_review', 'under_review', 'revision_requested', 'approved'))
        or (v_status = 'all' and status in ('submitted_for_review', 'under_review', 'revision_requested', 'approved', 'published'))
        or (v_status not in ('all_reviewable', 'all') and status = v_status)
      )
      and (v_search is null or title ilike '%' || v_search || '%' or subject_name ilike '%' || v_search || '%')
  )
  select
    (select count(*) filter (where status in ('submitted_for_review', 'under_review'))::integer from scoped),
    (select count(*) filter (where status = 'revision_requested')::integer from scoped),
    (select count(*) filter (where status = 'approved')::integer from scoped),
    (select count(*) filter (where status in ('published', 'active', 'completed', 'results_released'))::integer from scoped),
    (select count(*)::integer from filtered),
    coalesce(
      (
        select jsonb_agg(to_jsonb(p))
        from (
          select * from filtered
          order by
            case status
              when 'submitted_for_review' then 1
              when 'under_review' then 2
              when 'revision_requested' then 3
              when 'approved' then 4
              else 5
            end,
            coalesce(submitted_at, updated_at) desc
          limit v_limit offset v_offset
        ) p
      ),
      '[]'::jsonb
    )
  into v_awaiting, v_revision, v_approved, v_published, v_total, v_items;

  return jsonb_build_object(
    'summary', jsonb_build_object(
      'awaiting_review_count', v_awaiting,
      'revision_requested_count', v_revision,
      'approved_count', v_approved,
      'published_count', v_published,
      'total_filtered_count', v_total
    ),
    'capabilities', public.get_lesson_authoring_capabilities(v_country),
    'items', v_items
  );
end;
$$;

-- 2. RPC: record_exam_v2_review_decision
--    Persists reviewer checklist metadata and executes transition_exam_v2_status
create or replace function public.record_exam_v2_review_decision(
  p_examination_id uuid,
  p_action text,
  p_comments text default '',
  p_checklist jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_res jsonb;
begin
  v_res := public.transition_exam_v2_status(p_examination_id, p_action, p_comments);

  if p_checklist is not null and jsonb_typeof(p_checklist) = 'object' and p_checklist <> '{}'::jsonb then
    update public.examinations
    set metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
      'last_review_checklist', p_checklist,
      'last_reviewed_at', now()
    )
    where id = p_examination_id;
  end if;

  return v_res;
end;
$$;

revoke all on function public.list_exam_v2_review_queue(text, text, text, integer, integer) from public, anon;
grant execute on function public.list_exam_v2_review_queue(text, text, text, integer, integer) to authenticated, service_role;

revoke all on function public.record_exam_v2_review_decision(uuid, text, text, jsonb) from public, anon;
grant execute on function public.record_exam_v2_review_decision(uuid, text, text, jsonb) to authenticated, service_role;

commit;
