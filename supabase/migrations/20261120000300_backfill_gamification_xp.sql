-- ============================================================================
-- Idempotent Backfill for Existing Completed Lessons, Quizzes & Assessments
-- Migration: 20261120000300_backfill_gamification_xp.sql
--
-- Ensures learners who completed lessons/quizzes before Gamification 2.0 was
-- deployed immediately receive their verified XP, streaks, and milestone badges.
-- ============================================================================

begin;

do $$
declare
  v_row record;
begin
  -- 1. Backfill completed lessons & quizzes from learner_progress
  for v_row in
    select
      lp.learner_id,
      lp.lesson_id,
      lp.status,
      lp.best_quiz_score_percent,
      t.subject_id,
      l.title as lesson_title
    from public.learner_progress lp
    join public.lessons l on l.id = lp.lesson_id
    join public.topics t on t.id = l.topic_id
    where lp.status = 'completed'
       or coalesce(lp.best_quiz_score_percent, 0) >= 70
  loop
    if v_row.status = 'completed' then
      perform public._record_verified_gamification_event(
        v_row.learner_id,
        'lesson_completed',
        'learner_progress',
        v_row.lesson_id::text,
        'lesson_completed:' || v_row.learner_id::text || ':' || v_row.lesson_id::text,
        v_row.subject_id,
        jsonb_build_object('lesson_title', coalesce(v_row.lesson_title, 'Lesson'), 'backfilled', true)
      );
    end if;

    if coalesce(v_row.best_quiz_score_percent, 0) >= 70 then
      perform public._record_verified_gamification_event(
        v_row.learner_id,
        'quiz_passed',
        'learner_progress',
        v_row.lesson_id::text,
        'quiz_passed:' || v_row.learner_id::text || ':' || v_row.lesson_id::text,
        v_row.subject_id,
        jsonb_build_object('score_percent', v_row.best_quiz_score_percent, 'backfilled', true)
      );
    end if;

    if coalesce(v_row.best_quiz_score_percent, 0) = 100 then
      perform public._record_verified_gamification_event(
        v_row.learner_id,
        'quiz_perfect_bonus',
        'learner_progress',
        v_row.lesson_id::text,
        'quiz_perfect:' || v_row.learner_id::text || ':' || v_row.lesson_id::text,
        v_row.subject_id,
        jsonb_build_object('score_percent', 100, 'backfilled', true)
      );
    end if;
  end loop;

  -- 2. Backfill passed topic assessments
  for v_row in
    select
      laa.id,
      laa.learner_id,
      laa.score_percent,
      t.subject_id
    from public.learner_assessment_attempts laa
    left join public.topics t on t.id = laa.topic_id
    where laa.passed = true
  loop
    perform public._record_verified_gamification_event(
      v_row.learner_id,
      'assessment_passed',
      'learner_assessment_attempts',
      v_row.id::text,
      'assessment_passed:' || v_row.id::text,
      v_row.subject_id,
      jsonb_build_object('score_percent', v_row.score_percent, 'backfilled', true)
    );
  end loop;

  -- 3. Backfill submitted/marked examinations
  for v_row in
    select
      ea.id,
      ea.learner_id,
      e.subject_id,
      e.title as exam_title
    from public.examination_attempts ea
    join public.examinations e on e.id = ea.examination_id
    where ea.status in ('submitted', 'auto_marked', 'marked', 'results_released')
  loop
    perform public._record_verified_gamification_event(
      v_row.learner_id,
      'exam_completed',
      'examination_attempts',
      v_row.id::text,
      'exam_completed:' || v_row.id::text,
      v_row.subject_id,
      jsonb_build_object('exam_title', coalesce(v_row.exam_title, 'Examination'), 'backfilled', true)
    );
  end loop;
end;
$$;

commit;
