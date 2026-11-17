-- ============================================================================
-- LearnTZ — Content Management Studio Redesign & Multi-Country Hierarchy
-- Hierarchy: Country → Education Level → Grade/Class → Subject → Topics → Lessons
-- ============================================================================

-- 1. Ensure all 6 East African nations have education systems, authorities, and curricula

-- Burundi (BI)
insert into public.education_systems (id, country_code, name, code)
values (
  '20000000-0000-0000-0000-000000000201',
  'BI',
  'Burundi Système d''Education Fondamentale',
  'BI_FONDAMENTALE'
)
on conflict (country_code, code) do nothing;

insert into public.curriculum_authorities (id, country_code, education_system_id, name, code, website_url, is_enabled)
select
  '20000000-0000-0000-0000-000000000202',
  'BI',
  es.id,
  'Bureau de l''Education Fondamentale et Post-Fondamentale',
  'BEPES',
  'https://meec.gov.bi',
  true
from public.education_systems es
where es.country_code = 'BI' and es.code = 'BI_FONDAMENTALE'
on conflict (education_system_id, code) do update
set name = excluded.name, website_url = excluded.website_url, is_enabled = true;

insert into public.curricula (id, country_code, education_system_id, authority_id, name, code, description)
select
  '20000000-0000-0000-0000-000000000203',
  'BI',
  es.id,
  ca.id,
  'Curriculum de l''Enseignement Fondamental',
  'BEPES_CEF',
  'Programme national de l''enseignement fondamental du Burundi'
from public.education_systems es
join public.curriculum_authorities ca on ca.education_system_id = es.id and ca.code = 'BEPES'
where es.country_code = 'BI'
on conflict (id) do nothing;

insert into public.education_levels (id, curriculum_id, name, code, sequence)
select
  '20000000-0000-0000-0000-000000000204',
  c.id,
  'Enseignement Fondamental',
  'BI_FOND',
  1
from public.curricula c
where c.country_code = 'BI' and c.code = 'BEPES_CEF'
on conflict (curriculum_id, code) do nothing;

insert into public.education_grades (id, education_level_id, curriculum_id, name, code, sequence)
select g.id, el.id, el.curriculum_id, g.name, g.code, g.sequence
from (values
  ('20000000-0000-0000-0000-000000000205'::uuid, '1ère Année', 'BI_P1', 1),
  ('20000000-0000-0000-0000-000000000206'::uuid, '2ème Année', 'BI_P2', 2),
  ('20000000-0000-0000-0000-000000000207'::uuid, '3ème Année', 'BI_P3', 3),
  ('20000000-0000-0000-0000-000000000208'::uuid, '4ème Année', 'BI_P4', 4),
  ('20000000-0000-0000-0000-000000000209'::uuid, '5ème Année', 'BI_P5', 5),
  ('20000000-0000-0000-0000-00000000020a'::uuid, '6ème Année', 'BI_P6', 6)
) as g(id, name, code, sequence)
cross join (
  select el.id, el.curriculum_id
  from public.education_levels el
  join public.curricula c on c.id = el.curriculum_id
  where c.country_code = 'BI' and el.code = 'BI_FOND'
  limit 1
) el
on conflict (id) do nothing;

-- South Sudan (SS)
insert into public.education_systems (id, country_code, name, code)
values (
  '20000000-0000-0000-0000-000000000301',
  'SS',
  'South Sudan General Education System',
  'SS_GENERAL'
)
on conflict (country_code, code) do nothing;

insert into public.curriculum_authorities (id, country_code, education_system_id, name, code, website_url, is_enabled)
select
  '20000000-0000-0000-0000-000000000302',
  'SS',
  es.id,
  'Ministry of General Education and Instruction',
  'MOGEI',
  'https://mogeiss.org',
  true
from public.education_systems es
where es.country_code = 'SS' and es.code = 'SS_GENERAL'
on conflict (education_system_id, code) do update
set name = excluded.name, website_url = excluded.website_url, is_enabled = true;

insert into public.curricula (id, country_code, education_system_id, authority_id, name, code, description)
select
  '20000000-0000-0000-0000-000000000303',
  'SS',
  es.id,
  ca.id,
  'South Sudan National Curriculum',
  'MOGEI_SNC',
  'South Sudan National Curriculum Framework'
from public.education_systems es
join public.curriculum_authorities ca on ca.education_system_id = es.id and ca.code = 'MOGEI'
where es.country_code = 'SS'
on conflict (id) do nothing;

insert into public.education_levels (id, curriculum_id, name, code, sequence)
select
  '20000000-0000-0000-0000-000000000304',
  c.id,
  'Primary Education',
  'SS_PRI',
  1
from public.curricula c
where c.country_code = 'SS' and c.code = 'MOGEI_SNC'
on conflict (curriculum_id, code) do nothing;

insert into public.education_grades (id, education_level_id, curriculum_id, name, code, sequence)
select g.id, el.id, el.curriculum_id, g.name, g.code, g.sequence
from (values
  ('20000000-0000-0000-0000-000000000305'::uuid, 'Primary 1', 'SS_P1', 1),
  ('20000000-0000-0000-0000-000000000306'::uuid, 'Primary 2', 'SS_P2', 2),
  ('20000000-0000-0000-0000-000000000307'::uuid, 'Primary 3', 'SS_P3', 3),
  ('20000000-0000-0000-0000-000000000308'::uuid, 'Primary 4', 'SS_P4', 4),
  ('20000000-0000-0000-0000-000000000309'::uuid, 'Primary 5', 'SS_P5', 5),
  ('20000000-0000-0000-0000-00000000030a'::uuid, 'Primary 6', 'SS_P6', 6),
  ('20000000-0000-0000-0000-00000000030b'::uuid, 'Primary 7', 'SS_P7', 7),
  ('20000000-0000-0000-0000-00000000030c'::uuid, 'Primary 8', 'SS_P8', 8)
) as g(id, name, code, sequence)
cross join (
  select el.id, el.curriculum_id
  from public.education_levels el
  join public.curricula c on c.id = el.curriculum_id
  where c.country_code = 'SS' and el.code = 'SS_PRI'
  limit 1
) el
on conflict (id) do nothing;

-- 2. Enhanced get_content_studio_catalog returning grade and level metadata
create or replace function public.get_content_studio_catalog(
  p_country_code text default null,
  p_search text default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_result jsonb;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select coalesce(jsonb_agg(s_rec), '[]'::jsonb) into v_result
  from (
    select
      s.id as subject_id,
      s.name as subject_name,
      s.code as subject_code,
      s.country_code,
      s.display_order as subject_order,
      s.education_level_id,
      el.name as education_level_name,
      s.grade_id,
      eg.name as grade_name,
      coalesce(eg.sequence, 0) as grade_sequence,
      s.official_name,
      s.classification,
      s.language,
      s.is_published,
      coalesce(ca.name, 'National Curriculum Authority') as authority_name,
      coalesce(ca.code, s.country_code) as authority_code,
      (
        select coalesce(jsonb_agg(t_rec), '[]'::jsonb)
        from (
          select
            t.id as topic_id,
            t.title as topic_title,
            t.summary as topic_summary,
            t.display_order as topic_order,
            t.is_published as topic_is_published,
            t.competency_code,
            t.period_allocation,
            t.assessment_criteria,
            t.source_page,
            (
              select coalesce(jsonb_agg(l_rec), '[]'::jsonb)
              from (
                select
                  l.id as lesson_id,
                  l.title as lesson_title,
                  l.summary as lesson_summary,
                  l.estimated_minutes,
                  l.is_free_preview,
                  l.display_order as lesson_order,
                  l.status as lesson_status,
                  l.is_published as lesson_is_published,
                  l.version_number,
                  l.updated_at
                from public.lessons l
                where l.topic_id = t.id
                order by l.display_order asc, l.created_at asc
              ) l_rec
            ) as lessons
          from public.topics t
          where t.subject_id = s.id
            and (p_search is null or t.title ilike '%' || p_search || '%' or coalesce(t.competency_code, '') ilike '%' || p_search || '%')
          order by t.display_order asc, t.created_at asc
        ) t_rec
      ) as topics
    from public.subjects s
    left join public.education_levels el on el.id = s.education_level_id
    left join public.education_grades eg on eg.id = s.grade_id
    left join public.curricula c on c.id = s.curriculum_id
    left join lateral (
      select name, code
      from public.curriculum_authorities ca
      where ca.country_code = s.country_code
      limit 1
    ) ca on true
    where (p_country_code is null or s.country_code = p_country_code)
      and (
        p_search is null
        or s.name ilike '%' || p_search || '%'
        or s.code ilike '%' || p_search || '%'
        or coalesce(eg.name, '') ilike '%' || p_search || '%'
        or coalesce(el.name, '') ilike '%' || p_search || '%'
        or exists (
          select 1 from public.topics t
          where t.subject_id = s.id and (t.title ilike '%' || p_search || '%' or coalesce(t.competency_code, '') ilike '%' || p_search || '%')
        )
      )
    order by s.country_code asc, coalesce(eg.sequence, 0) asc, s.display_order asc, s.name asc
  ) s_rec;

  return v_result;
end;
$$;

-- 3. Comprehensive Multi-Country Curriculum Hierarchy RPC
create or replace function public.get_content_studio_hierarchy(
  p_country_code text default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_result jsonb;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select coalesce(jsonb_agg(c_rec), '[]'::jsonb) into v_result
  from (
    select
      co.country_code,
      co.display_name as country_name,
      co.product_name,
      co.currency_code,
      co.is_enabled,
      coalesce(ca.name, 'National Curriculum Authority') as authority_name,
      coalesce(ca.code, co.country_code) as authority_code,
      '2023 Edition' as active_version,
      (
        select count(distinct el.id)::int
        from public.curricula cur
        join public.education_levels el on el.curriculum_id = cur.id
        where cur.country_code = co.country_code
      ) as total_levels,
      (
        select count(distinct eg.id)::int
        from public.curricula cur
        join public.education_levels el on el.curriculum_id = cur.id
        join public.education_grades eg on eg.education_level_id = el.id
        where cur.country_code = co.country_code
      ) as total_grades,
      (
        select count(distinct s.id)::int
        from public.subjects s
        where s.country_code = co.country_code
      ) as total_subjects,
      (
        select count(distinct l.id)::int
        from public.lessons l
        join public.topics t on l.topic_id = t.id
        join public.subjects s on t.subject_id = s.id
        where s.country_code = co.country_code
      ) as total_lessons,
      (
        select coalesce(jsonb_agg(el_rec), '[]'::jsonb)
        from (
          select
            el.id as level_id,
            el.name as level_name,
            el.code as level_code,
            el.sequence as level_sequence,
            (
              select coalesce(jsonb_agg(g_rec), '[]'::jsonb)
              from (
                select
                  eg.id as grade_id,
                  eg.name as grade_name,
                  eg.code as grade_code,
                  eg.sequence as grade_sequence,
                  (
                    select coalesce(jsonb_agg(sub_rec), '[]'::jsonb)
                    from (
                      select
                        s.id as subject_id,
                        s.name as subject_name,
                        s.code as subject_code,
                        s.official_name,
                        s.classification,
                        s.language,
                        s.is_published,
                        s.display_order,
                        (select count(*)::int from public.topics t where t.subject_id = s.id) as topic_count,
                        (
                          select count(*)::int
                          from public.lessons l
                          join public.topics t on l.topic_id = t.id
                          where t.subject_id = s.id
                        ) as lesson_count,
                        (
                          select count(distinct t.competency_code)::int
                          from public.topics t
                          where t.subject_id = s.id and t.competency_code is not null
                        ) as competency_count,
                        (
                          select coalesce(sum(t.period_allocation), 0)::int
                          from public.topics t
                          where t.subject_id = s.id
                        ) as total_periods
                      from public.subjects s
                      where s.grade_id = eg.id
                         or (s.grade_id is null and s.education_level_id = el.id)
                      order by s.display_order asc, s.name asc
                    ) sub_rec
                  ) as subjects
                from public.education_grades eg
                where eg.education_level_id = el.id
                order by eg.sequence asc
              ) g_rec
            ) as grades
          from public.curricula cur
          join public.education_levels el on el.curriculum_id = cur.id
          where cur.country_code = co.country_code
          order by el.sequence asc
        ) el_rec
      ) as education_levels
    from public.countries co
    left join lateral (
      select name, code
      from public.curriculum_authorities ca
      where ca.country_code = co.country_code
      limit 1
    ) ca on true
    where (p_country_code is null or co.country_code = p_country_code)
    order by (case when co.country_code = 'TZ' then 0 else 1 end), co.country_code asc
  ) c_rec;

  return v_result;
end;
$$;

-- 4. RPC: get_subject_workspace_detail
create or replace function public.get_subject_workspace_detail(
  p_subject_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_result jsonb;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select to_jsonb(sub) into v_result
  from (
    select
      s.id as subject_id,
      s.name as subject_name,
      s.code as subject_code,
      s.official_name,
      s.classification,
      s.language,
      s.country_code,
      s.is_published,
      coalesce(el.name, 'Primary Education') as education_level_name,
      coalesce(eg.name, 'Standard III') as grade_name,
      coalesce(ca.name, 'Tanzania Institute of Education (TIE)') as authority_name,
      coalesce(ca.code, 'TIE') as authority_code,
      '2023 Official Syllabus Edition' as curriculum_version,
      'TIE English Language Syllabus for Primary Education Standards III-VI (2023)' as source_document_title,
      (
        select coalesce(jsonb_agg(top_rec), '[]'::jsonb)
        from (
          select
            t.id as topic_id,
            t.title as topic_title,
            t.summary as topic_summary,
            t.display_order as topic_order,
            t.is_published as topic_is_published,
            t.competency_code,
            t.period_allocation,
            t.assessment_criteria,
            t.source_page,
            (
              select coalesce(jsonb_agg(les_rec), '[]'::jsonb)
              from (
                select
                  l.id as lesson_id,
                  l.title as lesson_title,
                  l.summary as lesson_summary,
                  l.estimated_minutes,
                  l.is_free_preview,
                  l.display_order as lesson_order,
                  l.status as lesson_status,
                  l.is_published as lesson_is_published,
                  l.version_number,
                  l.updated_at
                from public.lessons l
                where l.topic_id = t.id
                order by l.display_order asc
              ) les_rec
            ) as lessons
          from public.topics t
          where t.subject_id = s.id
          order by t.display_order asc
        ) top_rec
      ) as topics
    from public.subjects s
    left join public.education_levels el on el.id = s.education_level_id
    left join public.education_grades eg on eg.id = s.grade_id
    left join public.curricula c on c.id = s.curriculum_id
    left join lateral (
      select name, code
      from public.curriculum_authorities ca
      where ca.country_code = s.country_code
      limit 1
    ) ca on true
    where s.id = p_subject_id
  ) sub;

  return v_result;
end;
$$;

-- 5. RPC: studio_upsert_topic
create or replace function public.studio_upsert_topic(
  p_subject_id uuid,
  p_title text,
  p_competency_code text default null,
  p_period_allocation integer default 30,
  p_assessment_criteria text default null,
  p_source_page integer default null,
  p_topic_id uuid default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_country text;
  v_target_id uuid;
  v_order integer;
  v_row record;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select country_code into v_country from public.subjects where id = p_subject_id;
  if v_country is null then
    raise exception 'Subject not found' using errcode = '22023';
  end if;

  if p_topic_id is not null then
    update public.topics
    set
      title = p_title,
      competency_code = p_competency_code,
      period_allocation = p_period_allocation,
      assessment_criteria = p_assessment_criteria,
      source_page = p_source_page,
      updated_at = now()
    where id = p_topic_id and subject_id = p_subject_id
    returning * into v_row;
    v_target_id := p_topic_id;
  else
    select coalesce(max(display_order), 0) + 1 into v_order
    from public.topics where subject_id = p_subject_id;

    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      p_subject_id, p_title, '', v_order, true,
      p_competency_code, p_period_allocation, p_assessment_criteria, p_source_page
    )
    returning * into v_row;
    v_target_id := v_row.id;
  end if;

  return jsonb_build_object(
    'success', true,
    'topic_id', v_target_id,
    'title', v_row.title
  );
end;
$$;

-- 6. RPC: studio_update_subject_workflow_status
create or replace function public.studio_update_subject_workflow_status(
  p_subject_id uuid,
  p_status text,
  p_review_notes text default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_country text;
  v_is_pub boolean;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select country_code into v_country from public.subjects where id = p_subject_id;
  if v_country is null then
    raise exception 'Subject not found' using errcode = '22023';
  end if;

  v_is_pub := (p_status = 'published');

  update public.subjects
  set
    is_published = v_is_pub,
    updated_at = now()
  where id = p_subject_id;

  -- Cascade publication flag to child topics
  if p_status = 'published' then
    update public.topics set is_published = true where subject_id = p_subject_id;
  end if;

  return jsonb_build_object(
    'success', true,
    'subject_id', p_subject_id,
    'status', p_status,
    'is_published', v_is_pub
  );
end;
$$;

-- Grant execution permissions on newly added RPCs
grant execute on function public.get_content_studio_catalog(text, text) to authenticated;
grant execute on function public.get_content_studio_hierarchy(text) to authenticated;
grant execute on function public.get_subject_workspace_detail(uuid) to authenticated;
grant execute on function public.studio_upsert_topic(uuid, text, text, integer, text, integer, uuid) to authenticated;
grant execute on function public.studio_update_subject_workflow_status(uuid, text, text) to authenticated;
