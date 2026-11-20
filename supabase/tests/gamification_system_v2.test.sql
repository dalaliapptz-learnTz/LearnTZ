-- ============================================================================
-- pgTAP Verification Suite: LearnTZ Gamification System 2.0
-- ============================================================================
begin;

select plan(17);

-- 1. Core tables & seeded rules/badges exist
select ok(
  (select count(*) >= 8 from public.gamification_xp_rules where is_active = true),
  'Configurable gamification_xp_rules seeded'
);

select ok(
  (select count(*) >= 10 from public.achievement_badges where is_active = true and rule_metric is not null),
  'Enriched achievement_badges catalog seeded with configurable rule_metric and target_value'
);

-- Setup test parent, second parent (for RLS isolation), learner, subject/topic/lesson
do $$
declare
  v_parent_1 uuid := '11111111-1111-4111-8111-111111111101';
  v_parent_2 uuid := '11111111-1111-4111-8111-111111111102';
  v_learner_1 uuid := '22222222-2222-4222-8222-222222222201';
  v_sys_id uuid;
  v_curr_id uuid;
  v_lvl_id uuid;
  v_grade_id uuid;
  v_subj_id uuid;
  v_topic_id uuid;
  v_lesson_id uuid;
begin
  -- Create auth users (trigger automatically provisions parent_accounts)
  insert into auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_user_meta_data, created_at, updated_at)
  values
    (v_parent_1, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'gamif_parent1@learntz.test', 'x', now(), '{"full_name":"Parent One"}'::jsonb, now(), now()),
    (v_parent_2, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'gamif_parent2@learntz.test', 'x', now(), '{"full_name":"Parent Two"}'::jsonb, now(), now())
  on conflict (id) do nothing;

  -- Lookup an existing TZ primary curriculum/grade/lesson (natural key resolution, zero hardcoded UUIDs)
  select l.id, t.id, s.id, s.curriculum_id, s.education_level_id
  into v_lesson_id, v_topic_id, v_subj_id, v_curr_id, v_lvl_id
  from public.lessons l
  join public.topics t on t.id = l.topic_id
  join public.subjects s on s.id = t.subject_id
  where s.country_code = 'TZ'
  limit 1;

  select education_system_id into v_sys_id
  from public.curricula where id = v_curr_id;

  select id into v_grade_id
  from public.education_grades
  where education_level_id = v_lvl_id
  order by name asc
  limit 1;

  insert into public.learners (
    id, first_name, last_name, date_of_birth, gender, country_code,
    education_system_id, curriculum_id, education_level_id, grade_id,
    status, created_by_parent_user_id, registration_request_id
  )
  values (
    v_learner_1, 'Amina', 'Hassan', date '2016-04-12', 'female', 'TZ',
    v_sys_id, v_curr_id, v_lvl_id, v_grade_id,
    'active', v_parent_1, gen_random_uuid()
  )
  on conflict (id) do nothing;

  insert into public.parent_learners (parent_user_id, learner_id, relationship_role, created_by_parent_user_id)
  values (v_parent_1, v_learner_1, 'parent', v_parent_1)
  on conflict do nothing;

  -- Store discovered lesson_id & subject_id in temp table for test assertions
  create temp table if not exists _gamif_test_ctx (
    learner_id uuid,
    parent_1 uuid,
    parent_2 uuid,
    subject_id uuid,
    lesson_id uuid
  ) on commit drop;
  delete from _gamif_test_ctx;
  insert into _gamif_test_ctx values (v_learner_1, v_parent_1, v_parent_2, v_subj_id, v_lesson_id);
  grant select on _gamif_test_ctx to authenticated;
end;
$$;

-- 2. Trigger on real lesson completion awards verified XP + first_lesson badge + notification
do $$
declare
  v_ctx record;
begin
  select * into v_ctx from _gamif_test_ctx;
  insert into public.learner_progress (learner_id, lesson_id, status, reading_progress_percent, completed_at)
  values (v_ctx.learner_id, v_ctx.lesson_id, 'completed', 100, now());
end;
$$;

select is(
  (select total_xp from public.learner_gamification_profiles where learner_id = '22222222-2222-4222-8222-222222222201'),
  35,
  'Lesson completion awards 25 XP + 10 XP first_lesson badge bonus (35 XP total)'
);

select is(
  (select current_streak from public.learner_gamification_profiles where learner_id = '22222222-2222-4222-8222-222222222201'),
  1,
  'First verified learning activity starts a 1-day streak'
);

select ok(
  exists (
    select 1 from public.learner_badges
    where learner_id = '22222222-2222-4222-8222-222222222201'
      and badge_key = 'first_lesson'
  ),
  'first_lesson badge automatically awarded on lesson completion'
);

select ok(
  exists (
    select 1 from public.social_notifications
    where recipient_learner_id = '22222222-2222-4222-8222-222222222201'
      and notification_type = 'badge_awarded'
  ),
  'Badge award automatically inserts learner notification'
);

-- 3. Idempotency: updating the same completed lesson does NOT mint duplicate XP
do $$
declare
  v_ctx record;
begin
  select * into v_ctx from _gamif_test_ctx;
  update public.learner_progress
  set updated_at = now()
  where learner_id = v_ctx.learner_id and lesson_id = v_ctx.lesson_id;
end;
$$;

select is(
  (select total_xp from public.learner_gamification_profiles where learner_id = '22222222-2222-4222-8222-222222222201'),
  35,
  'Duplicate update on already-completed lesson does not mint duplicate XP'
);

-- 4. Perfect quiz score triggers quiz_passed (30) + quiz_perfect_bonus (15) + practice_starter (15) + perfect_scorer (30) = +90 XP (total 125 XP + xp_rising_100 badge!)
do $$
declare
  v_ctx record;
begin
  select * into v_ctx from _gamif_test_ctx;
  update public.learner_progress
  set best_quiz_score_percent = 100, attempts_count = 1
  where learner_id = v_ctx.learner_id and lesson_id = v_ctx.lesson_id;
end;
$$;

select is(
  (select total_xp from public.learner_gamification_profiles where learner_id = '22222222-2222-4222-8222-222222222201'),
  125,
  '100% quiz awards verified quiz + perfect + badge rewards accurately (125 XP)'
);

select ok(
  exists (
    select 1 from public.learner_badges
    where learner_id = '22222222-2222-4222-8222-222222222201'
      and badge_key = 'xp_rising_100'
  ),
  'xp_rising_100 milestone badge awarded automatically upon crossing 100 XP'
);

-- Switch to authenticated Parent 1 session
set local role authenticated;
select set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111101', true);

-- 5. Anti-manipulation: authenticated client CANNOT insert into gamification_xp_ledger
select throws_ok(
  $$
  insert into public.gamification_xp_ledger (
    learner_id, event_type, source_table, source_id, idempotency_key, xp_amount, activity_date
  ) values (
    '22222222-2222-4222-8222-222222222201', 'lesson_completed', 'fake', '1', 'fake:1', 500, current_date
  );
  $$,
  '42501',
  null,
  'Authenticated clients are blocked from directly inserting into gamification_xp_ledger'
);

-- 6. Overview RPC returns weekly calendar (7 days), badges with statuses, and child-safe default opt_in = false
select is(
  jsonb_array_length((public.get_learner_gamification_overview('22222222-2222-4222-8222-222222222201')->'weekly_calendar')),
  7,
  'Overview RPC returns 7-day learner-local weekly activity calendar'
);

select is(
  (public.get_learner_gamification_overview('22222222-2222-4222-8222-222222222201')->>'leaderboard_opt_in')::boolean,
  false,
  'Child-safe default: leaderboard_opt_in defaults to false'
);

-- 7. Leaderboard hides opted-out learner from public entries while returning private my_standing
select is(
  jsonb_array_length((public.get_gamification_leaderboard('22222222-2222-4222-8222-222222222201', 'weekly')->'entries')),
  0,
  'Opted-out learner is not exposed in public leaderboard entries'
);

-- 8. Opt-in with safe display alias exposes alias (never full surname) in weekly & subject leaderboards
select is(
  (public.update_learner_gamification_preferences('22222222-2222-4222-8222-222222222201', true, 'StarAmina')->>'leaderboard_alias'),
  'StarAmina',
  'Learner/parent can opt in and set child-safe leaderboard alias'
);

select is(
  (public.get_gamification_leaderboard(
    '22222222-2222-4222-8222-222222222201',
    'weekly',
    (select subject_id from _gamif_test_ctx)
  )->'entries'->0->>'display_label'),
  'StarAmina',
  'Subject-scoped weekly leaderboard displays opted-in learner using safe alias'
);

-- 9. Parent visibility RPC returns child XP, streak, and recent badges
select is(
  (public.get_parent_children_gamification_summary()->0->>'total_xp')::integer,
  125,
  'Parent dashboard summary RPC exposes child verified XP and achievements'
);

-- 10. RLS / Authorization isolation: Parent 2 cannot view Parent 1's child overview
select set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111102', true);

select throws_ok(
  $$
  select public.get_learner_gamification_overview('22222222-2222-4222-8222-222222222201');
  $$,
  '42501',
  null,
  'Unauthorized parent is denied access to another family learner gamification overview'
);

select * from finish();
rollback;
