-- ============================================================================
-- Revision Centre: Categorized Drills by Subject -> Main Competence -> Specific Competence
-- Migration: 20261120000400_revision_drills_by_competence.sql
-- ============================================================================

begin;

create or replace function public.get_learner_revision_drill_catalog(
  p_learner_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_learner record;
  v_result jsonb;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  if not (public.is_authorized_learner_parent(p_learner_id) or public.has_role('super_admin')) then
    raise exception 'Not authorized to access revision drills for this learner'
      using errcode = '42501';
  end if;

  select l.id, l.curriculum_id, l.education_level_id, l.grade_id
  into v_learner
  from public.learners l
  where l.id = p_learner_id;

  if not found then
    raise exception 'Learner not found' using errcode = 'P0002';
  end if;

  with eligible_subjects as (
    select s.id, s.name, s.display_order
    from public.subjects s
    where s.curriculum_id = v_learner.curriculum_id
      and (v_learner.education_level_id is null or s.education_level_id = v_learner.education_level_id)
      and s.is_published = true
    order by s.display_order asc, s.name asc
  ),
  competence_tree as (
    select
      es.id as subject_id,
      es.name as subject_name,
      es.display_order as subject_order,
      coalesce(
        (
          select jsonb_agg(comp_obj order by mc_order asc, mc_code asc)
          from (
            select
              mc.display_order as mc_order,
              mc.code as mc_code,
              jsonb_build_object(
                'main_competence_id', mc.id,
                'code', mc.code,
                'title', mc.title,
                'specific_competences', coalesce(
                  (
                    select jsonb_agg(
                      jsonb_build_object(
                        'specific_competence_id', sc.id,
                        'topic_id', sc.topic_id,
                        'code', sc.code,
                        'title', sc.title,
                        'accuracy_rate', coalesce(m.accuracy_rate, 0),
                        'quizzes_attempted', coalesce(m.quizzes_attempted, 0),
                        'mastery_status', coalesce(m.mastery_status, 'not_started'),
                        'question_count', (
                          select count(*)::integer
                          from public.question_bank qb
                          where qb.topic_id = sc.topic_id
                            and qb.is_published = true
                        )
                      )
                      order by sc.display_order asc, sc.code asc
                    )
                    from public.curriculum_specific_competences sc
                    left join public.learner_topic_mastery m
                      on m.topic_id = sc.topic_id
                     and m.learner_id = p_learner_id
                    where sc.main_competence_id = mc.id
                      and sc.is_published = true
                  ),
                  '[]'::jsonb
                )
              ) as comp_obj
            from public.curriculum_main_competences mc
            where mc.subject_id = es.id
              and mc.is_published = true
          ) mc_rows
        ),
        '[]'::jsonb
      ) as competences,
      -- Fallback for published topics not yet mapped to curriculum_specific_competences
      coalesce(
        (
          select jsonb_agg(
            jsonb_build_object(
              'specific_competence_id', t.id,
              'topic_id', t.id,
              'code', 'T' || t.display_order::text,
              'title', t.title,
              'accuracy_rate', coalesce(m.accuracy_rate, 0),
              'quizzes_attempted', coalesce(m.quizzes_attempted, 0),
              'mastery_status', coalesce(m.mastery_status, 'not_started'),
              'question_count', (
                select count(*)::integer
                from public.question_bank qb
                where qb.topic_id = t.id
                  and qb.is_published = true
              )
            )
            order by t.display_order asc, t.title asc
          )
          from public.topics t
          left join public.learner_topic_mastery m
            on m.topic_id = t.id
           and m.learner_id = p_learner_id
          where t.subject_id = es.id
            and t.is_published = true
            and not exists (
              select 1
              from public.curriculum_specific_competences sc
              where sc.topic_id = t.id
                and sc.is_published = true
            )
        ),
        '[]'::jsonb
      ) as unmapped_topics
    from eligible_subjects es
  )
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'subject_id', ct.subject_id,
        'subject_name', ct.subject_name,
        'competences', case
          when jsonb_array_length(ct.unmapped_topics) > 0 then
            ct.competences || jsonb_build_array(
              jsonb_build_object(
                'main_competence_id', ct.subject_id::text || ':general',
                'code', 'GEN',
                'title', 'General Topics',
                'specific_competences', ct.unmapped_topics
              )
            )
          else ct.competences
        end
      )
      order by ct.subject_order asc, ct.subject_name asc
    ),
    '[]'::jsonb
  )
  into v_result
  from competence_tree ct
  where jsonb_array_length(ct.competences) > 0
     or jsonb_array_length(ct.unmapped_topics) > 0;

  return v_result;
end;
$$;

revoke all on function public.get_learner_revision_drill_catalog(uuid) from public, anon;
grant execute on function public.get_learner_revision_drill_catalog(uuid) to authenticated;

commit;
