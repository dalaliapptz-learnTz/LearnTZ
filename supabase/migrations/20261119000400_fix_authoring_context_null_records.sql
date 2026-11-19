-- ============================================================================
-- Fix: get_lesson_authoring_context untyped record variables when called
-- without pre-selected grade/subject/level (e.g. from Content Studio Dashboard).
-- Replaces untyped `record` variables with explicit scalar variables so NULL
-- optional parameters never raise SQLSTATE 55000 ("record is not assigned yet").
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
  v_country_name text;
  v_curriculum_id uuid := p_curriculum_id;
  v_curriculum_name text;
  v_curriculum_code text;
  v_authority_name text;
  v_authority_code text;
  v_version_id uuid;
  v_version_code text;
  v_version_name text;
  v_level_id uuid := p_education_level_id;
  v_level_name text;
  v_grade_id uuid := p_grade_id;
  v_grade_name text;
  v_subject_id uuid := p_subject_id;
  v_subject_name text;
  v_tmp_country text;
  v_tmp_cur uuid;
  v_tmp_lvl uuid;
  v_tmp_grd uuid;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  -- If subject_id is given, derive parent hierarchy from subject
  if v_subject_id is not null then
    select s.country_code, s.curriculum_id, s.education_level_id, s.grade_id, s.name
    into v_tmp_country, v_tmp_cur, v_tmp_lvl, v_tmp_grd, v_subject_name
    from public.subjects s
    where s.id = v_subject_id;

    if found then
      v_country := coalesce(v_tmp_country, v_country);
      v_curriculum_id := coalesce(v_curriculum_id, v_tmp_cur);
      v_level_id := coalesce(v_level_id, v_tmp_lvl);
      v_grade_id := coalesce(v_grade_id, v_tmp_grd);
    else
      v_subject_id := null;
    end if;
  end if;

  -- If grade_id is given, derive level & curriculum
  if v_grade_id is not null then
    select eg.education_level_id, eg.curriculum_id, eg.name
    into v_tmp_lvl, v_tmp_cur, v_grade_name
    from public.education_grades eg
    where eg.id = v_grade_id;

    if found then
      v_level_id := coalesce(v_level_id, v_tmp_lvl);
      v_curriculum_id := coalesce(v_curriculum_id, v_tmp_cur);
    else
      v_grade_id := null;
    end if;
  end if;

  -- If education_level_id is given, derive curriculum
  if v_level_id is not null then
    select el.curriculum_id, el.name
    into v_tmp_cur, v_level_name
    from public.education_levels el
    where el.id = v_level_id;

    if found then
      v_curriculum_id := coalesce(v_curriculum_id, v_tmp_cur);
    else
      v_level_id := null;
    end if;
  end if;

  -- Resolve curriculum
  if v_curriculum_id is not null then
    select c.id, c.country_code, c.name, c.code, ca.name, ca.code
    into v_curriculum_id, v_tmp_country, v_curriculum_name, v_curriculum_code, v_authority_name, v_authority_code
    from public.curricula c
    left join public.curriculum_authorities ca on ca.id = c.authority_id
    where c.id = v_curriculum_id;

    if found then
      v_country := coalesce(v_country, v_tmp_country);
    end if;
  else
    select c.id, c.country_code, c.name, c.code, ca.name, ca.code
    into v_curriculum_id, v_tmp_country, v_curriculum_name, v_curriculum_code, v_authority_name, v_authority_code
    from public.curricula c
    left join public.curriculum_authorities ca on ca.id = c.authority_id
    where (v_country is null or c.country_code = v_country)
      and c.is_enabled = true
    order by (case when c.country_code = 'TZ' then 0 else 1 end), c.created_at asc
    limit 1;

    if found then
      v_country := v_tmp_country;
    end if;
  end if;

  if v_country is null then
    v_country := 'TZ';
  end if;

  if not (public.can_author_lesson(v_country) or public.can_review_lesson(v_country) or public.can_publish_lesson(v_country)) then
    raise exception 'Permission denied: lesson authoring requires authorized staff role' using errcode = '42501';
  end if;

  select co.display_name
  into v_country_name
  from public.countries co
  where co.country_code = v_country;

  -- Resolve latest curriculum version for the active curriculum
  if v_curriculum_id is not null then
    select cv.id, cv.version_code, coalesce(cv.display_name, cv.official_document_version)
    into v_version_id, v_version_code, v_version_name
    from public.curriculum_versions cv
    where cv.curriculum_id = v_curriculum_id
    order by
      case cv.status when 'published' then 1 when 'approved' then 2 else 3 end,
      cv.created_at desc
    limit 1;
  end if;

  -- Resolve default level if not selected yet
  if v_level_id is null and v_curriculum_id is not null then
    select el.id, el.name
    into v_level_id, v_level_name
    from public.education_levels el
    where el.curriculum_id = v_curriculum_id
      and el.is_enabled = true
    order by el.sequence asc
    limit 1;
  end if;

  return jsonb_build_object(
    'country_code', v_country,
    'country_name', coalesce(v_country_name, v_country),
    'curriculum_id', v_curriculum_id,
    'curriculum_name', v_curriculum_name,
    'curriculum_code', v_curriculum_code,
    'authority_name', v_authority_name,
    'authority_code', v_authority_code,
    'curriculum_version_id', v_version_id,
    'curriculum_version_code', v_version_code,
    'curriculum_version_name', v_version_name,
    'education_level_id', v_level_id,
    'education_level_name', v_level_name,
    'grade_id', v_grade_id,
    'grade_name', v_grade_name,
    'subject_id', v_subject_id,
    'subject_name', v_subject_name,
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
        where el.curriculum_id = v_curriculum_id
          and el.is_enabled = true
      ),
      '[]'::jsonb
    )
  );
end;
$$;
