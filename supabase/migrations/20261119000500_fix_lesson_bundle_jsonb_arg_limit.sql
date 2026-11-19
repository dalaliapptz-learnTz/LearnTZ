-- ============================================================================
-- Fix: get_authored_lesson_bundle exceeded PostgreSQL's 100-argument function
-- limit (51 key-value pairs = 102 args in a single jsonb_build_object call,
-- SQLSTATE 54023). Split into two concatenated jsonb_build_object(...) calls.
-- ============================================================================

create or replace function public.get_authored_lesson_bundle(
  p_lesson_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_lesson record;
  v_country text;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select
    l.*,
    co.display_name as country_name,
    c.name as curriculum_name,
    c.code as curriculum_code,
    cv.version_code as curriculum_version_code,
    cv.display_name as curriculum_version_name,
    el.name as education_level_name,
    eg.name as grade_name,
    eg.code as grade_code,
    s.name as subject_name,
    s.code as subject_code,
    s.country_code as subject_country_code,
    mc.code as main_competence_code,
    mc.title as main_competence_title,
    sc.code as specific_competence_code,
    sc.title as specific_competence_title,
    t.title as topic_title,
    st.title as subtopic_title
  into v_lesson
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
  left join public.subtopics st on st.id = l.subtopic_id
  where l.id = p_lesson_id;

  if not found then
    raise exception 'Lesson % not found', p_lesson_id using errcode = '22023';
  end if;

  v_country := coalesce(v_lesson.country_code, v_lesson.subject_country_code);
  if not (
    v_lesson.author_id = v_uid
    or public.can_author_lesson(v_country)
    or public.can_review_lesson(v_country)
    or public.can_publish_lesson(v_country)
  ) then
    raise exception 'Permission denied' using errcode = '42501';
  end if;

  return jsonb_build_object(
    'lesson', (
      jsonb_build_object(
        'id', v_lesson.id,
        'country_code', v_country,
        'country_name', v_lesson.country_name,
        'curriculum_id', v_lesson.curriculum_id,
        'curriculum_name', v_lesson.curriculum_name,
        'curriculum_code', v_lesson.curriculum_code,
        'curriculum_version_id', v_lesson.curriculum_version_id,
        'curriculum_version_code', v_lesson.curriculum_version_code,
        'curriculum_version_name', v_lesson.curriculum_version_name,
        'education_level_id', v_lesson.education_level_id,
        'education_level_name', v_lesson.education_level_name,
        'grade_id', v_lesson.grade_id,
        'grade_name', v_lesson.grade_name,
        'grade_code', v_lesson.grade_code,
        'subject_id', v_lesson.subject_id,
        'subject_name', v_lesson.subject_name,
        'subject_code', v_lesson.subject_code,
        'main_competence_id', v_lesson.main_competence_id,
        'main_competence_code', v_lesson.main_competence_code,
        'main_competence_title', v_lesson.main_competence_title,
        'specific_competence_id', v_lesson.specific_competence_id,
        'specific_competence_code', v_lesson.specific_competence_code,
        'specific_competence_title', v_lesson.specific_competence_title,
        'topic_id', v_lesson.topic_id,
        'topic_title', v_lesson.topic_title,
        'subtopic_id', v_lesson.subtopic_id,
        'subtopic_title', v_lesson.subtopic_title
      ) || jsonb_build_object(
        'title', v_lesson.title,
        'summary', v_lesson.summary,
        'body_markdown', v_lesson.body_markdown,
        'estimated_minutes', v_lesson.estimated_minutes,
        'language_code', v_lesson.language_code,
        'difficulty_level', v_lesson.difficulty_level,
        'lesson_type', v_lesson.lesson_type,
        'is_free_preview', v_lesson.is_free_preview,
        'learning_objectives', v_lesson.learning_objectives,
        'learning_outcomes', v_lesson.learning_outcomes,
        'content_blocks', v_lesson.content_blocks,
        'teaching_activities', v_lesson.teaching_activities,
        'assessment_criteria', v_lesson.assessment_criteria,
        'status', v_lesson.status,
        'is_published', v_lesson.is_published,
        'version_number', v_lesson.version_number,
        'author_id', v_lesson.author_id,
        'reviewer_id', v_lesson.reviewer_id,
        'review_notes', v_lesson.review_notes,
        'approved_by', v_lesson.approved_by,
        'approved_at', v_lesson.approved_at,
        'published_by', v_lesson.published_by,
        'published_at', v_lesson.published_at,
        'updated_at', v_lesson.updated_at
      )
    ),
    'questions', coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'id', q.id,
            'lesson_id', q.lesson_id,
            'question_type', q.question_type,
            'difficulty_level', q.difficulty_level,
            'question_text', q.question_text,
            'options', q.options,
            'correct_answer', q.correct_answer,
            'explanation', q.explanation,
            'marks', q.marks,
            'learning_outcome_ref', q.learning_outcome_ref,
            'assessment_criteria', q.assessment_criteria,
            'cognitive_tier', q.cognitive_tier,
            'display_order', q.display_order,
            'is_published', q.is_published
          ) order by q.display_order asc, q.created_at asc
        )
        from public.question_bank q
        where q.lesson_id = p_lesson_id
      ),
      '[]'::jsonb
    ),
    'revisions', coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'id', r.id,
            'version_number', r.version_number,
            'title', r.title,
            'summary', r.summary,
            'status', r.status,
            'change_summary', r.change_summary,
            'changed_by_user_id', r.changed_by_user_id,
            'created_at', r.created_at
          ) order by r.version_number desc
        )
        from public.lesson_revisions r
        where r.lesson_id = p_lesson_id
      ),
      '[]'::jsonb
    ),
    'review_events', coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'id', e.id,
            'action', e.action,
            'from_status', e.from_status,
            'to_status', e.to_status,
            'version_number', e.version_number,
            'comments', e.comments,
            'actor_user_id', e.actor_user_id,
            'created_at', e.created_at
          ) order by e.created_at desc
        )
        from public.lesson_review_events e
        where e.lesson_id = p_lesson_id
      ),
      '[]'::jsonb
    ),
    'capabilities', public.get_lesson_authoring_capabilities(v_country)
  );
end;
$$;
