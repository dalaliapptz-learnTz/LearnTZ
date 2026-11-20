-- ============================================================================
-- LearnTZ Gamification System 2.0
-- Migration: 20261120000100_gamification_system_v2.sql
--
-- Features:
--   1. Learning Streaks (learner-local calendar dates, current/longest, weekly calendar, milestones)
--   2. Badges & Achievements (configurable criteria, locked/in-progress/earned, notifications)
--   3. Leaderboards & Rankings (weekly/monthly/subject, cohort-scoped, child-safe privacy opt-in)
--   4. Auditable, idempotent, server-side XP ledger with daily anti-manipulation caps
--   5. Automatic triggers on real lesson, practice assessment, and examination events
--   6. Parent visibility RPC for children's achievements and activity
-- ============================================================================

begin;

-- ============================================================================
-- 1. Configurable XP Rules (anti-manipulation daily caps + server-side XP)
-- ============================================================================
create table if not exists public.gamification_xp_rules (
  rule_key text primary key,
  title text not null,
  xp_amount integer not null check (xp_amount > 0 and xp_amount <= 1000),
  max_per_day integer not null default 20 check (max_per_day >= 1 and max_per_day <= 100),
  is_active boolean not null default true,
  updated_at timestamptz not null default now()
);

drop trigger if exists gamification_xp_rules_set_updated_at on public.gamification_xp_rules;
create trigger gamification_xp_rules_set_updated_at
  before update on public.gamification_xp_rules
  for each row execute function public.set_updated_at();

insert into public.gamification_xp_rules (rule_key, title, xp_amount, max_per_day, is_active)
values
  ('lesson_completed', 'Lesson Completed', 25, 12, true),
  ('quiz_passed', 'Lesson Quiz Passed', 30, 12, true),
  ('quiz_perfect_bonus', 'Perfect Score Bonus', 15, 12, true),
  ('assessment_passed', 'Topic Practice Passed', 40, 10, true),
  ('exam_completed', 'Examination Completed', 75, 5, true),
  ('streak_milestone_3', '3-Day Learning Streak', 20, 1, true),
  ('streak_milestone_7', '7-Day Learning Streak', 50, 1, true),
  ('streak_milestone_14', '14-Day Learning Streak', 100, 1, true),
  ('streak_milestone_30', '30-Day Learning Streak', 250, 1, true),
  ('badge_reward', 'Achievement Badge Reward', 25, 25, true)
on conflict (rule_key) do update set
  title = excluded.title,
  xp_amount = excluded.xp_amount,
  max_per_day = excluded.max_per_day,
  is_active = excluded.is_active;

alter table public.gamification_xp_rules enable row level security;
revoke all on public.gamification_xp_rules from public, anon, authenticated;
grant select on public.gamification_xp_rules to authenticated;

drop policy if exists "Authenticated users read gamification xp rules" on public.gamification_xp_rules;
create policy "Authenticated users read gamification xp rules"
  on public.gamification_xp_rules for select to authenticated using (true);

drop policy if exists "Admins manage gamification xp rules" on public.gamification_xp_rules;
create policy "Admins manage gamification xp rules"
  on public.gamification_xp_rules for all to authenticated
  using (public.has_role('super_admin'))
  with check (public.has_role('super_admin'));

-- ============================================================================
-- 2. Extend existing public.achievement_badges (no duplicate badge table)
-- ============================================================================
alter table public.achievement_badges
  drop constraint if exists achievement_badges_category_check;

alter table public.achievement_badges
  add constraint achievement_badges_category_check
  check (category in ('learning', 'social', 'competition', 'consistency', 'streak', 'mastery', 'assessment'));

alter table public.achievement_badges
  add column if not exists rule_metric text not null default 'xp_total',
  add column if not exists target_value integer not null default 1 check (target_value >= 1),
  add column if not exists tier text not null default 'bronze'
    check (tier in ('bronze', 'silver', 'gold', 'platinum')),
  add column if not exists xp_reward integer not null default 0 check (xp_reward >= 0),
  add column if not exists is_active boolean not null default true,
  add column if not exists sort_order integer not null default 100;

insert into public.achievement_badges (
  badge_key, name, description, category, icon_name, points_required,
  rule_metric, target_value, tier, xp_reward, is_active, sort_order
)
values
  ('first_lesson', 'First Step', 'Complete your first verified lesson on LearnTZ', 'learning', 'menu_book', 25, 'lessons_completed', 1, 'bronze', 10, true, 10),
  ('lesson_explorer_5', 'Lesson Explorer', 'Complete 5 curriculum lessons', 'learning', 'auto_stories', 125, 'lessons_completed', 5, 'silver', 25, true, 20),
  ('lesson_scholar_20', 'Curriculum Scholar', 'Complete 20 curriculum lessons', 'mastery', 'school', 500, 'lessons_completed', 20, 'gold', 60, true, 30),
  ('streak_3_days', '3-Day Spark', 'Learn on LearnTZ for 3 consecutive days', 'streak', 'local_fire_department', 60, 'longest_streak', 3, 'bronze', 20, true, 40),
  ('study_streak_7', '7-Day Scholar', 'Maintain a 7-day learning streak', 'streak', 'bolt', 150, 'longest_streak', 7, 'silver', 50, true, 50),
  ('streak_30_days', '30-Day Champion', 'Maintain a 30-day learning streak', 'streak', 'workspace_premium', 500, 'longest_streak', 30, 'platinum', 150, true, 60),
  ('practice_starter', 'Practice Pro', 'Pass your first lesson quiz or topic practice', 'assessment', 'quiz', 30, 'assessments_passed', 1, 'bronze', 15, true, 70),
  ('perfect_scorer', 'Perfect Score', 'Achieve 100% on a verified quiz or practice assessment', 'mastery', 'verified', 50, 'perfect_scores', 1, 'silver', 30, true, 80),
  ('exam_finisher', 'Exam Ready', 'Complete a verified practice examination', 'assessment', 'assignment_turned_in', 75, 'exams_completed', 1, 'gold', 50, true, 90),
  ('xp_rising_100', 'Rising Learner', 'Earn 100 verified learning XP', 'mastery', 'trending_up', 100, 'xp_total', 100, 'bronze', 0, true, 100),
  ('xp_achiever_500', 'Dedicated Achiever', 'Earn 500 verified learning XP', 'mastery', 'stars', 500, 'xp_total', 500, 'silver', 0, true, 110),
  ('xp_master_1000', 'LearnTZ Master', 'Earn 1,000 verified learning XP', 'mastery', 'emoji_events', 1000, 'xp_total', 1000, 'gold', 0, true, 120)
on conflict (badge_key) do update set
  name = excluded.name,
  description = excluded.description,
  category = excluded.category,
  icon_name = excluded.icon_name,
  points_required = excluded.points_required,
  rule_metric = excluded.rule_metric,
  target_value = excluded.target_value,
  tier = excluded.tier,
  xp_reward = excluded.xp_reward,
  is_active = excluded.is_active,
  sort_order = excluded.sort_order;

drop policy if exists "Admins manage achievement badges" on public.achievement_badges;
create policy "Admins manage achievement badges"
  on public.achievement_badges for all to authenticated
  using (public.has_role('super_admin'))
  with check (public.has_role('super_admin'));

-- ============================================================================
-- 3. Learner Gamification Profile (streaks, XP balance, child-safe privacy)
-- ============================================================================
create table if not exists public.learner_gamification_profiles (
  learner_id uuid primary key references public.learners (id) on delete cascade,
  timezone text not null default 'Africa/Dar_es_Salaam',
  total_xp integer not null default 0 check (total_xp >= 0),
  current_streak integer not null default 0 check (current_streak >= 0),
  longest_streak integer not null default 0 check (longest_streak >= 0),
  last_active_date date,
  leaderboard_opt_in boolean not null default false,
  leaderboard_alias text
    check (leaderboard_alias is null or char_length(btrim(leaderboard_alias)) between 2 and 24),
  show_badges_on_profile boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists learner_gamification_profiles_set_updated_at on public.learner_gamification_profiles;
create trigger learner_gamification_profiles_set_updated_at
  before update on public.learner_gamification_profiles
  for each row execute function public.set_updated_at();

alter table public.learner_gamification_profiles enable row level security;
revoke all on public.learner_gamification_profiles from public, anon, authenticated;
grant select on public.learner_gamification_profiles to authenticated;

drop policy if exists "Parents and admins read learner gamification profile" on public.learner_gamification_profiles;
create policy "Parents and admins read learner gamification profile"
  on public.learner_gamification_profiles for select to authenticated
  using (
    public.is_authorized_learner_parent(learner_id)
    or public.has_role('super_admin')
  );

-- ============================================================================
-- 4. Auditable, Append-Only XP Transaction Ledger (server-write only)
-- ============================================================================
create table if not exists public.gamification_xp_ledger (
  id uuid primary key default gen_random_uuid(),
  learner_id uuid not null references public.learners (id) on delete cascade,
  event_type text not null,
  source_table text not null,
  source_id text not null,
  idempotency_key text not null unique,
  subject_id uuid references public.subjects (id) on delete set null,
  xp_amount integer not null check (xp_amount > 0 and xp_amount <= 1000),
  activity_date date not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists gamification_xp_ledger_learner_date_idx
  on public.gamification_xp_ledger (learner_id, activity_date desc, created_at desc);

create index if not exists gamification_xp_ledger_subject_date_idx
  on public.gamification_xp_ledger (subject_id, activity_date desc)
  where subject_id is not null;

alter table public.gamification_xp_ledger enable row level security;
-- Strict anti-manipulation: authenticated clients can NEVER insert/update/delete XP!
revoke all on public.gamification_xp_ledger from public, anon, authenticated;
grant select on public.gamification_xp_ledger to authenticated;

drop policy if exists "Parents and admins read learner xp ledger" on public.gamification_xp_ledger;
create policy "Parents and admins read learner xp ledger"
  on public.gamification_xp_ledger for select to authenticated
  using (
    public.is_authorized_learner_parent(learner_id)
    or public.has_role('super_admin')
  );

-- ============================================================================
-- 5. Learner Daily Activity Calendar (learner-local calendar dates)
-- ============================================================================
create table if not exists public.learner_daily_activity (
  learner_id uuid not null references public.learners (id) on delete cascade,
  activity_date date not null,
  lessons_completed integer not null default 0 check (lessons_completed >= 0),
  assessments_completed integer not null default 0 check (assessments_completed >= 0),
  exams_completed integer not null default 0 check (exams_completed >= 0),
  xp_earned integer not null default 0 check (xp_earned >= 0),
  updated_at timestamptz not null default now(),
  primary key (learner_id, activity_date)
);

alter table public.learner_daily_activity enable row level security;
revoke all on public.learner_daily_activity from public, anon, authenticated;
grant select on public.learner_daily_activity to authenticated;

drop policy if exists "Parents and admins read learner daily activity" on public.learner_daily_activity;
create policy "Parents and admins read learner daily activity"
  on public.learner_daily_activity for select to authenticated
  using (
    public.is_authorized_learner_parent(learner_id)
    or public.has_role('super_admin')
  );

-- ============================================================================
-- 6. Internal Server-Side Helpers (NOT callable directly by clients)
-- ============================================================================

-- Helper: resolve learner's local calendar date safely
create or replace function public._gamification_local_date(p_timezone text)
returns date
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_tz text := coalesce(nullif(btrim(p_timezone), ''), 'Africa/Dar_es_Salaam');
begin
  return (now() at time zone v_tz)::date;
exception when others then
  return (now() at time zone 'Africa/Dar_es_Salaam')::date;
end;
$$;

revoke all on function public._gamification_local_date(text) from public, anon, authenticated;

-- Helper: recompute current_streak and longest_streak from learner_daily_activity
create or replace function public._gamification_recompute_streaks(
  p_learner_id uuid,
  p_today date
)
returns table (
  current_streak integer,
  longest_streak integer,
  last_active_date date
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_dates date[];
  v_cur integer := 0;
  v_longest integer := 0;
  v_run integer := 0;
  v_prev date := null;
  v_last date := null;
  v_d date;
  v_cursor date;
begin
  select array_agg(activity_date order by activity_date asc)
  into v_dates
  from public.learner_daily_activity
  where learner_id = p_learner_id
    and (xp_earned > 0 or lessons_completed > 0 or assessments_completed > 0 or exams_completed > 0);

  if v_dates is null or array_length(v_dates, 1) is null then
    return query select 0, 0, null::date;
    return;
  end if;

  -- Compute longest streak across all recorded active local dates
  foreach v_d in array v_dates loop
    if v_prev is not null and v_d = v_prev + 1 then
      v_run := v_run + 1;
    else
      v_run := 1;
    end if;
    if v_run > v_longest then
      v_longest := v_run;
    end if;
    v_prev := v_d;
    v_last := v_d;
  end loop;

  -- Compute current active streak (must include today or yesterday in learner-local date)
  if v_last = p_today or v_last = p_today - 1 then
    v_cursor := v_last;
    v_cur := 0;
    while v_cursor = any(v_dates) loop
      v_cur := v_cur + 1;
      v_cursor := v_cursor - 1;
    end loop;
  else
    v_cur := 0;
  end if;

  return query select v_cur, v_longest, v_last;
end;
$$;

revoke all on function public._gamification_recompute_streaks(uuid, date) from public, anon, authenticated;

-- Helper: evaluate & award achievements + badge notifications
create or replace function public._gamification_evaluate_badges(
  p_learner_id uuid,
  p_today date
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_lessons_completed integer := 0;
  v_assessments_passed integer := 0;
  v_perfect_scores integer := 0;
  v_exams_completed integer := 0;
  v_total_xp integer := 0;
  v_longest_streak integer := 0;
  v_current_streak integer := 0;
  v_badge record;
  v_metric_val integer;
  v_inserted_id uuid;
  v_awarded_count integer := 0;
begin
  select count(*)::integer into v_lessons_completed
  from public.learner_progress
  where learner_id = p_learner_id and status = 'completed';

  select (
    (select count(*) from public.learner_progress where learner_id = p_learner_id and best_quiz_score_percent >= 70)
    + (select count(*) from public.learner_assessment_attempts where learner_id = p_learner_id and passed = true)
  )::integer into v_assessments_passed;

  select (
    (select count(*) from public.learner_progress where learner_id = p_learner_id and best_quiz_score_percent = 100)
    + (select count(*) from public.learner_assessment_attempts where learner_id = p_learner_id and score_percent = 100)
  )::integer into v_perfect_scores;

  select (
    (select count(*) from public.examination_attempts
      where learner_id = p_learner_id
        and status in ('submitted', 'auto_marked', 'marked', 'results_released'))
    + (select count(*) from public.learner_exam_attempts
      where learner_id = p_learner_id and status = 'completed')
  )::integer into v_exams_completed;

  select coalesce(total_xp, 0), coalesce(longest_streak, 0), coalesce(current_streak, 0)
  into v_total_xp, v_longest_streak, v_current_streak
  from public.learner_gamification_profiles
  where learner_id = p_learner_id;

  for v_badge in
    select *
    from public.achievement_badges
    where is_active = true
      and badge_key not in (
        select badge_key from public.learner_badges where learner_id = p_learner_id
      )
    order by sort_order asc
  loop
    v_metric_val := case v_badge.rule_metric
      when 'lessons_completed' then v_lessons_completed
      when 'assessments_passed' then v_assessments_passed
      when 'perfect_scores' then v_perfect_scores
      when 'exams_completed' then v_exams_completed
      when 'longest_streak' then greatest(v_longest_streak, v_current_streak)
      when 'xp_total' then v_total_xp
      else 0
    end;

    if v_metric_val >= v_badge.target_value then
      insert into public.learner_badges (learner_id, badge_key)
      values (p_learner_id, v_badge.badge_key)
      on conflict (learner_id, badge_key) do nothing
      returning id into v_inserted_id;

      if v_inserted_id is not null then
        v_awarded_count := v_awarded_count + 1;

        -- Notify learner in existing social_notifications table
        insert into public.social_notifications (
          recipient_learner_id,
          notification_type,
          title,
          body,
          target_route
        )
        values (
          p_learner_id,
          'badge_awarded',
          'Achievement Unlocked: ' || v_badge.name,
          v_badge.description,
          '/learn'
        );

        -- Award bonus badge XP idempotently if configured
        if v_badge.xp_reward > 0 then
          insert into public.gamification_xp_ledger (
            learner_id, event_type, source_table, source_id,
            idempotency_key, subject_id, xp_amount, activity_date, metadata
          )
          values (
            p_learner_id,
            'badge_reward',
            'achievement_badges',
            v_badge.badge_key,
            'badge_reward:' || p_learner_id::text || ':' || v_badge.badge_key,
            null,
            v_badge.xp_reward,
            p_today,
            jsonb_build_object('badge_name', v_badge.name, 'tier', v_badge.tier)
          )
          on conflict (idempotency_key) do nothing;

          if found then
            v_total_xp := v_total_xp + v_badge.xp_reward;
            update public.learner_gamification_profiles
            set total_xp = v_total_xp
            where learner_id = p_learner_id;
          end if;
        end if;
      end if;
    end if;
  end loop;

  return v_awarded_count;
end;
$$;

revoke all on function public._gamification_evaluate_badges(uuid, date) from public, anon, authenticated;

-- Core internal XP & Streak recorder (ONLY called by verified triggers)
create or replace function public._record_verified_gamification_event(
  p_learner_id uuid,
  p_event_type text,
  p_source_table text,
  p_source_id text,
  p_idempotency_key text,
  p_subject_id uuid default null,
  p_metadata jsonb default '{}'::jsonb
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_rule record;
  v_tz text;
  v_today date;
  v_daily_count integer;
  v_inserted_id uuid;
  v_streak record;
begin
  if p_learner_id is null or p_event_type is null or p_idempotency_key is null then
    return false;
  end if;

  -- Lookup configurable XP rule
  select * into v_rule
  from public.gamification_xp_rules
  where rule_key = p_event_type and is_active = true;

  if not found then
    return false;
  end if;

  -- Ensure gamification profile exists
  insert into public.learner_gamification_profiles (learner_id)
  values (p_learner_id)
  on conflict (learner_id) do nothing;

  select timezone into v_tz
  from public.learner_gamification_profiles
  where learner_id = p_learner_id;

  v_today := public._gamification_local_date(v_tz);

  -- Anti-manipulation: enforce daily cap per event type
  select count(*)::integer into v_daily_count
  from public.gamification_xp_ledger
  where learner_id = p_learner_id
    and event_type = p_event_type
    and activity_date = v_today;

  if v_daily_count >= v_rule.max_per_day then
    return false;
  end if;

  -- Idempotent insert into auditable XP ledger
  insert into public.gamification_xp_ledger (
    learner_id, event_type, source_table, source_id,
    idempotency_key, subject_id, xp_amount, activity_date, metadata
  )
  values (
    p_learner_id, p_event_type, p_source_table, p_source_id,
    p_idempotency_key, p_subject_id, v_rule.xp_amount, v_today, coalesce(p_metadata, '{}'::jsonb)
  )
  on conflict (idempotency_key) do nothing
  returning id into v_inserted_id;

  if v_inserted_id is null then
    return false;
  end if;

  -- Update daily activity calendar
  insert into public.learner_daily_activity (
    learner_id, activity_date, lessons_completed, assessments_completed, exams_completed, xp_earned
  )
  values (
    p_learner_id,
    v_today,
    case when p_event_type = 'lesson_completed' then 1 else 0 end,
    case when p_event_type in ('quiz_passed', 'assessment_passed') then 1 else 0 end,
    case when p_event_type = 'exam_completed' then 1 else 0 end,
    v_rule.xp_amount
  )
  on conflict (learner_id, activity_date) do update set
    lessons_completed = public.learner_daily_activity.lessons_completed + excluded.lessons_completed,
    assessments_completed = public.learner_daily_activity.assessments_completed + excluded.assessments_completed,
    exams_completed = public.learner_daily_activity.exams_completed + excluded.exams_completed,
    xp_earned = public.learner_daily_activity.xp_earned + excluded.xp_earned,
    updated_at = now();

  -- Recompute streaks & update total_xp from ledger
  select * into v_streak
  from public._gamification_recompute_streaks(p_learner_id, v_today);

  update public.learner_gamification_profiles
  set
    total_xp = (select coalesce(sum(xp_amount), 0)::integer from public.gamification_xp_ledger where learner_id = p_learner_id),
    current_streak = coalesce(v_streak.current_streak, 0),
    longest_streak = greatest(longest_streak, coalesce(v_streak.longest_streak, 0)),
    last_active_date = v_streak.last_active_date,
    updated_at = now()
  where learner_id = p_learner_id;

  -- Evaluate badges & notifications
  perform public._gamification_evaluate_badges(p_learner_id, v_today);

  return true;
end;
$$;

revoke all on function public._record_verified_gamification_event(uuid, text, text, text, text, uuid, jsonb)
  from public, anon, authenticated;

-- ============================================================================
-- 7. Automatic Triggers on Real Learning Events (Reuse Existing Engine)
-- ============================================================================

-- Trigger A: Lesson completions & lesson quizzes (public.learner_progress)
create or replace function public.trg_gamification_on_learner_progress()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_subject_id uuid;
  v_lesson_title text;
begin
  select t.subject_id, l.title
  into v_subject_id, v_lesson_title
  from public.lessons l
  join public.topics t on t.id = l.topic_id
  where l.id = new.lesson_id;

  -- 1) Lesson marked completed
  if new.status = 'completed' and (tg_op = 'INSERT' or old.status is distinct from 'completed') then
    perform public._record_verified_gamification_event(
      new.learner_id,
      'lesson_completed',
      'learner_progress',
      new.lesson_id::text,
      'lesson_completed:' || new.learner_id::text || ':' || new.lesson_id::text,
      v_subject_id,
      jsonb_build_object('lesson_title', coalesce(v_lesson_title, 'Lesson'))
    );
  end if;

  -- 2) Lesson quiz passed (>= 70%)
  if coalesce(new.best_quiz_score_percent, 0) >= 70
     and (tg_op = 'INSERT' or coalesce(old.best_quiz_score_percent, 0) < 70) then
    perform public._record_verified_gamification_event(
      new.learner_id,
      'quiz_passed',
      'learner_progress',
      new.lesson_id::text,
      'quiz_passed:' || new.learner_id::text || ':' || new.lesson_id::text,
      v_subject_id,
      jsonb_build_object('score_percent', new.best_quiz_score_percent, 'lesson_title', coalesce(v_lesson_title, 'Lesson'))
    );
  end if;

  -- 3) Perfect quiz score bonus (100%)
  if coalesce(new.best_quiz_score_percent, 0) = 100
     and (tg_op = 'INSERT' or coalesce(old.best_quiz_score_percent, 0) < 100) then
    perform public._record_verified_gamification_event(
      new.learner_id,
      'quiz_perfect_bonus',
      'learner_progress',
      new.lesson_id::text,
      'quiz_perfect:' || new.learner_id::text || ':' || new.lesson_id::text,
      v_subject_id,
      jsonb_build_object('score_percent', 100, 'lesson_title', coalesce(v_lesson_title, 'Lesson'))
    );
  end if;

  return new;
end;
$$;

drop trigger if exists gamification_on_learner_progress on public.learner_progress;
create trigger gamification_on_learner_progress
  after insert or update on public.learner_progress
  for each row execute function public.trg_gamification_on_learner_progress();

-- Trigger B: Topic practice assessments (public.learner_assessment_attempts)
create or replace function public.trg_gamification_on_assessment_attempt()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_subject_id uuid;
begin
  if new.topic_id is not null then
    select subject_id into v_subject_id from public.topics where id = new.topic_id;
  end if;

  if new.passed = true then
    perform public._record_verified_gamification_event(
      new.learner_id,
      'assessment_passed',
      'learner_assessment_attempts',
      new.id::text,
      'assessment_passed:' || new.id::text,
      v_subject_id,
      jsonb_build_object('score_percent', new.score_percent)
    );
  end if;

  if new.score_percent = 100 then
    perform public._record_verified_gamification_event(
      new.learner_id,
      'quiz_perfect_bonus',
      'learner_assessment_attempts',
      new.id::text,
      'assessment_perfect:' || new.id::text,
      v_subject_id,
      jsonb_build_object('score_percent', 100)
    );
  end if;

  return new;
end;
$$;

drop trigger if exists gamification_on_assessment_attempt on public.learner_assessment_attempts;
create trigger gamification_on_assessment_attempt
  after insert on public.learner_assessment_attempts
  for each row execute function public.trg_gamification_on_assessment_attempt();

-- Trigger C: Examination Centre 2.0 completions (public.examination_attempts)
create or replace function public.trg_gamification_on_examination_attempt()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_subject_id uuid;
  v_exam_title text;
begin
  if new.status in ('submitted', 'auto_marked', 'marked', 'results_released')
     and (tg_op = 'INSERT' or old.status not in ('submitted', 'auto_marked', 'marked', 'results_released')) then
    select subject_id, title into v_subject_id, v_exam_title
    from public.examinations
    where id = new.examination_id;

    perform public._record_verified_gamification_event(
      new.learner_id,
      'exam_completed',
      'examination_attempts',
      new.id::text,
      'exam_completed:' || new.id::text,
      v_subject_id,
      jsonb_build_object('exam_title', coalesce(v_exam_title, 'Examination'))
    );
  end if;

  return new;
end;
$$;

drop trigger if exists gamification_on_examination_attempt on public.examination_attempts;
create trigger gamification_on_examination_attempt
  after insert or update on public.examination_attempts
  for each row execute function public.trg_gamification_on_examination_attempt();

-- ============================================================================
-- 8. Authenticated Client RPCs
-- ============================================================================

-- RPC 1: Full Learner Gamification Overview (dashboard + badges + calendar + rank)
create or replace function public.get_learner_gamification_overview(
  p_learner_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_learner record;
  v_profile record;
  v_today date;
  v_streak record;
  v_age_tier text := 'primary';
  v_level_text text := '';
  v_weekly_xp integer := 0;
  v_monthly_xp integer := 0;
  v_lessons_completed integer := 0;
  v_assessments_passed integer := 0;
  v_perfect_scores integer := 0;
  v_exams_completed integer := 0;
  v_weekly_calendar jsonb;
  v_badges jsonb;
  v_recent_notifications jsonb;
  v_recent_events jsonb;
  v_my_weekly_rank integer;
  v_cohort_participants integer := 0;
begin
  if not (public.is_authorized_learner_parent(p_learner_id) or public.has_role('super_admin')) then
    raise exception 'Not authorized to access gamification overview for this learner'
      using errcode = '42501';
  end if;

  select
    l.*,
    el.code as level_code,
    el.name as level_name,
    eg.name as grade_name
  into v_learner
  from public.learners l
  left join public.education_levels el on el.id = l.education_level_id
  left join public.education_grades eg on eg.id = l.grade_id
  where l.id = p_learner_id;

  if not found then
    raise exception 'Learner not found' using errcode = 'P0002';
  end if;

  -- Determine age-adaptive presentation tier: primary | o_level | a_level
  v_level_text := lower(coalesce(v_learner.level_code, '') || ' ' || coalesce(v_learner.level_name, '') || ' ' || coalesce(v_learner.grade_name, ''));
  if v_level_text ~ '(a-level|a_level|advanced|form 5|form 6|form v|form vi|kidato cha 5|kidato cha 6)' then
    v_age_tier := 'a_level';
  elsif v_level_text ~ '(o-level|o_level|ordinary|secondary|form 1|form 2|form 3|form 4|form i|form ii|form iii|form iv|kidato)' then
    v_age_tier := 'o_level';
  else
    v_age_tier := 'primary';
  end if;

  -- Ensure profile row exists
  insert into public.learner_gamification_profiles (learner_id)
  values (p_learner_id)
  on conflict (learner_id) do nothing;

  select * into v_profile
  from public.learner_gamification_profiles
  where learner_id = p_learner_id;

  v_today := public._gamification_local_date(v_profile.timezone);

  -- Refresh streak against current learner-local date
  select * into v_streak
  from public._gamification_recompute_streaks(p_learner_id, v_today);

  if v_profile.current_streak is distinct from coalesce(v_streak.current_streak, 0)
     or v_profile.longest_streak < coalesce(v_streak.longest_streak, 0) then
    update public.learner_gamification_profiles
    set
      current_streak = coalesce(v_streak.current_streak, 0),
      longest_streak = greatest(longest_streak, coalesce(v_streak.longest_streak, 0)),
      last_active_date = v_streak.last_active_date
    where learner_id = p_learner_id
    returning * into v_profile;
  end if;

  -- Weekly and monthly verified XP
  select
    coalesce(sum(xp_amount) filter (where activity_date >= v_today - 6), 0)::integer,
    coalesce(sum(xp_amount) filter (where activity_date >= v_today - 29), 0)::integer
  into v_weekly_xp, v_monthly_xp
  from public.gamification_xp_ledger
  where learner_id = p_learner_id;

  -- Verified activity counts for badge progress
  select count(*)::integer into v_lessons_completed
  from public.learner_progress
  where learner_id = p_learner_id and status = 'completed';

  select (
    (select count(*) from public.learner_progress where learner_id = p_learner_id and best_quiz_score_percent >= 70)
    + (select count(*) from public.learner_assessment_attempts where learner_id = p_learner_id and passed = true)
  )::integer into v_assessments_passed;

  select (
    (select count(*) from public.learner_progress where learner_id = p_learner_id and best_quiz_score_percent = 100)
    + (select count(*) from public.learner_assessment_attempts where learner_id = p_learner_id and score_percent = 100)
  )::integer into v_perfect_scores;

  select (
    (select count(*) from public.examination_attempts
      where learner_id = p_learner_id
        and status in ('submitted', 'auto_marked', 'marked', 'results_released'))
    + (select count(*) from public.learner_exam_attempts
      where learner_id = p_learner_id and status = 'completed')
  )::integer into v_exams_completed;

  -- 7-day learner-local activity calendar
  select coalesce(jsonb_agg(day_obj order by d asc), '[]'::jsonb)
  into v_weekly_calendar
  from (
    select
      gs.d::date as d,
      jsonb_build_object(
        'date', to_char(gs.d::date, 'YYYY-MM-DD'),
        'day_label', to_char(gs.d::date, 'Dy'),
        'is_today', gs.d::date = v_today,
        'is_active', coalesce(lda.xp_earned, 0) > 0,
        'xp_earned', coalesce(lda.xp_earned, 0),
        'lessons_completed', coalesce(lda.lessons_completed, 0)
      ) as day_obj
    from generate_series(v_today - 6, v_today, interval '1 day') as gs(d)
    left join public.learner_daily_activity lda
      on lda.learner_id = p_learner_id and lda.activity_date = gs.d::date
  ) cal;

  -- Full badge catalog with locked / in_progress / earned states
  select coalesce(jsonb_agg(badge_obj order by sort_order asc, badge_key asc), '[]'::jsonb)
  into v_badges
  from (
    select
      ab.sort_order,
      ab.badge_key,
      jsonb_build_object(
        'badge_key', ab.badge_key,
        'name', ab.name,
        'description', ab.description,
        'category', ab.category,
        'icon_name', ab.icon_name,
        'tier', ab.tier,
        'xp_reward', ab.xp_reward,
        'target_value', ab.target_value,
        'current_value', least(ab.target_value, m.val),
        'progress_percent', least(100, round((m.val::numeric / greatest(ab.target_value, 1)::numeric) * 100)::integer),
        'status', case
          when lb.awarded_at is not null then 'earned'
          when m.val > 0 then 'in_progress'
          else 'locked'
        end,
        'awarded_at', lb.awarded_at
      ) as badge_obj
    from public.achievement_badges ab
    left join public.learner_badges lb
      on lb.badge_key = ab.badge_key and lb.learner_id = p_learner_id
    cross join lateral (
      select case ab.rule_metric
        when 'lessons_completed' then v_lessons_completed
        when 'assessments_passed' then v_assessments_passed
        when 'perfect_scores' then v_perfect_scores
        when 'exams_completed' then v_exams_completed
        when 'longest_streak' then greatest(v_profile.longest_streak, v_profile.current_streak)
        when 'xp_total' then v_profile.total_xp
        else 0
      end as val
    ) m
    where ab.is_active = true
  ) b;

  -- Recent badge notifications
  select coalesce(jsonb_agg(notif_obj), '[]'::jsonb)
  into v_recent_notifications
  from (
    select jsonb_build_object(
      'id', sn.id,
      'title', sn.title,
      'body', sn.body,
      'is_read', sn.is_read,
      'created_at', sn.created_at
    ) as notif_obj
    from public.social_notifications sn
    where sn.recipient_learner_id = p_learner_id
      and sn.notification_type = 'badge_awarded'
    order by sn.created_at desc
    limit 5
  ) n;

  -- Recent verified XP ledger entries (auditable feed)
  select coalesce(jsonb_agg(ev_obj), '[]'::jsonb)
  into v_recent_events
  from (
    select jsonb_build_object(
      'id', gxl.id,
      'event_type', gxl.event_type,
      'xp_amount', gxl.xp_amount,
      'activity_date', to_char(gxl.activity_date, 'YYYY-MM-DD'),
      'metadata', gxl.metadata,
      'created_at', gxl.created_at
    ) as ev_obj
    from public.gamification_xp_ledger gxl
    where gxl.learner_id = p_learner_id
    order by gxl.created_at desc
    limit 10
  ) e;

  -- Cohort weekly rank summary (even if opted out, learner sees their own standing privately)
  with cohort as (
    select
      l.id as learner_id,
      coalesce(gp.leaderboard_opt_in, false) as opt_in,
      coalesce(sum(gxl.xp_amount) filter (where gxl.activity_date >= v_today - 6), 0)::integer as period_xp,
      coalesce(gp.current_streak, 0) as streak
    from public.learners l
    left join public.learner_gamification_profiles gp on gp.learner_id = l.id
    left join public.gamification_xp_ledger gxl on gxl.learner_id = l.id
    where l.status = 'active'
      and l.country_code = v_learner.country_code
      and l.curriculum_id is not distinct from v_learner.curriculum_id
      and l.education_level_id is not distinct from v_learner.education_level_id
      and l.grade_id is not distinct from v_learner.grade_id
      and (coalesce(gp.leaderboard_opt_in, false) = true or l.id = p_learner_id)
    group by l.id, gp.leaderboard_opt_in, gp.current_streak
  ),
  ranked as (
    select
      learner_id,
      opt_in,
      row_number() over (order by period_xp desc, streak desc, learner_id asc)::integer as rnk
    from cohort
  )
  select
    (select rnk from ranked where learner_id = p_learner_id),
    (select count(*)::integer from cohort where opt_in = true)
  into v_my_weekly_rank, v_cohort_participants;

  return jsonb_build_object(
    'learner_id', p_learner_id,
    'age_tier', v_age_tier,
    'grade_name', v_learner.grade_name,
    'level_name', v_learner.level_name,
    'country_code', v_learner.country_code,
    'timezone', v_profile.timezone,
    'total_xp', v_profile.total_xp,
    'weekly_xp', v_weekly_xp,
    'monthly_xp', v_monthly_xp,
    'current_streak', v_profile.current_streak,
    'longest_streak', v_profile.longest_streak,
    'last_active_date', v_profile.last_active_date,
    'leaderboard_opt_in', v_profile.leaderboard_opt_in,
    'leaderboard_alias', v_profile.leaderboard_alias,
    'weekly_rank', v_my_weekly_rank,
    'cohort_participants', v_cohort_participants,
    'weekly_calendar', v_weekly_calendar,
    'badges', v_badges,
    'recent_notifications', v_recent_notifications,
    'recent_xp_events', v_recent_events
  );
end;
$$;

revoke all on function public.get_learner_gamification_overview(uuid) from public, anon;
grant execute on function public.get_learner_gamification_overview(uuid) to authenticated;

-- RPC 2: Cohort-Scoped, Privacy-Safe Leaderboard (weekly, monthly, subject)
create or replace function public.get_gamification_leaderboard(
  p_learner_id uuid,
  p_period text default 'weekly',
  p_subject_id uuid default null,
  p_limit integer default 25
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_learner record;
  v_tz text;
  v_today date;
  v_since date;
  v_period text := lower(coalesce(p_period, 'weekly'));
  v_limit integer := least(greatest(coalesce(p_limit, 25), 1), 100);
  v_entries jsonb;
  v_my_entry jsonb;
  v_cohort_label text;
begin
  if not (public.is_authorized_learner_parent(p_learner_id) or public.has_role('super_admin')) then
    raise exception 'Not authorized to view leaderboard for this learner'
      using errcode = '42501';
  end if;

  if v_period not in ('weekly', 'monthly', 'all_time') then
    raise exception 'Invalid period: must be weekly, monthly, or all_time'
      using errcode = '22023';
  end if;

  select
    l.*,
    eg.name as grade_name,
    el.name as level_name
  into v_learner
  from public.learners l
  left join public.education_grades eg on eg.id = l.grade_id
  left join public.education_levels el on el.id = l.education_level_id
  where l.id = p_learner_id;

  if not found then
    raise exception 'Learner not found' using errcode = 'P0002';
  end if;

  select coalesce(timezone, 'Africa/Dar_es_Salaam') into v_tz
  from public.learner_gamification_profiles
  where learner_id = p_learner_id;

  v_today := public._gamification_local_date(v_tz);
  v_since := case v_period
    when 'weekly' then v_today - 6
    when 'monthly' then v_today - 29
    else date '2000-01-01'
  end;

  v_cohort_label := trim(both ' · ' from
    coalesce(v_learner.grade_name, v_learner.level_name, 'Learners') || ' · ' || v_learner.country_code
  );

  with cohort_scores as (
    select
      l.id as learner_id,
      coalesce(gp.leaderboard_opt_in, false) as opt_in,
      -- Child-safe display label: alias OR FirstName + Last Initial (never full PII!)
      coalesce(
        nullif(btrim(gp.leaderboard_alias), ''),
        l.first_name || ' ' || left(l.last_name, 1) || '.'
      ) as display_label,
      coalesce(sum(gxl.xp_amount), 0)::integer as period_xp,
      coalesce(gp.current_streak, 0) as current_streak,
      (select count(*)::integer from public.learner_badges lb where lb.learner_id = l.id) as badges_count
    from public.learners l
    left join public.learner_gamification_profiles gp on gp.learner_id = l.id
    left join public.gamification_xp_ledger gxl
      on gxl.learner_id = l.id
     and gxl.activity_date >= v_since
     and (p_subject_id is null or gxl.subject_id = p_subject_id)
    where l.status = 'active'
      and l.country_code = v_learner.country_code
      and l.curriculum_id is not distinct from v_learner.curriculum_id
      and l.education_level_id is not distinct from v_learner.education_level_id
      and l.grade_id is not distinct from v_learner.grade_id
      and (coalesce(gp.leaderboard_opt_in, false) = true or l.id = p_learner_id)
    group by l.id, gp.leaderboard_opt_in, gp.leaderboard_alias, l.first_name, l.last_name, gp.current_streak
  ),
  public_ranked as (
    select
      row_number() over (order by period_xp desc, current_streak desc, badges_count desc, learner_id asc)::integer as rank,
      learner_id,
      display_label,
      period_xp,
      current_streak,
      badges_count,
      (learner_id = p_learner_id) as is_current_learner
    from cohort_scores
    where opt_in = true
  ),
  all_ranked as (
    select
      row_number() over (order by period_xp desc, current_streak desc, badges_count desc, learner_id asc)::integer as rank,
      learner_id,
      opt_in,
      display_label,
      period_xp,
      current_streak,
      badges_count
    from cohort_scores
  )
  select
    coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'rank', pr.rank,
            'display_label', pr.display_label,
            'xp', pr.period_xp,
            'current_streak', pr.current_streak,
            'badges_count', pr.badges_count,
            'is_current_learner', pr.is_current_learner
          )
          order by pr.rank asc
        )
        from (select * from public_ranked order by rank asc limit v_limit) pr
      ),
      '[]'::jsonb
    ),
    (
      select jsonb_build_object(
        'rank', ar.rank,
        'display_label', ar.display_label,
        'xp', ar.period_xp,
        'current_streak', ar.current_streak,
        'badges_count', ar.badges_count,
        'is_opted_in', ar.opt_in
      )
      from all_ranked ar
      where ar.learner_id = p_learner_id
    )
  into v_entries, v_my_entry;

  return jsonb_build_object(
    'period', v_period,
    'subject_id', p_subject_id,
    'cohort_label', v_cohort_label,
    'my_standing', v_my_entry,
    'entries', v_entries
  );
end;
$$;

revoke all on function public.get_gamification_leaderboard(uuid, text, uuid, integer) from public, anon;
grant execute on function public.get_gamification_leaderboard(uuid, text, uuid, integer) to authenticated;

-- RPC 3: Privacy Controls (opt-in/out of public rankings + safe display alias + timezone)
create or replace function public.update_learner_gamification_preferences(
  p_learner_id uuid,
  p_leaderboard_opt_in boolean,
  p_leaderboard_alias text default null,
  p_timezone text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_clean_alias text;
  v_profile record;
begin
  if not (public.is_authorized_learner_parent(p_learner_id) or public.has_role('super_admin')) then
    raise exception 'Not authorized to update gamification preferences for this learner'
      using errcode = '42501';
  end if;

  if p_leaderboard_alias is not null then
    v_clean_alias := nullif(btrim(regexp_replace(p_leaderboard_alias, '[^a-zA-Z0-9 _-]', '', 'g')), '');
    if v_clean_alias is not null and (char_length(v_clean_alias) < 2 or char_length(v_clean_alias) > 24) then
      raise exception 'Display alias must be between 2 and 24 characters'
        using errcode = '22023';
    end if;
  end if;

  insert into public.learner_gamification_profiles (
    learner_id, leaderboard_opt_in, leaderboard_alias, timezone
  )
  values (
    p_learner_id,
    coalesce(p_leaderboard_opt_in, false),
    v_clean_alias,
    coalesce(nullif(btrim(p_timezone), ''), 'Africa/Dar_es_Salaam')
  )
  on conflict (learner_id) do update set
    leaderboard_opt_in = coalesce(p_leaderboard_opt_in, public.learner_gamification_profiles.leaderboard_opt_in),
    leaderboard_alias = case
      when p_leaderboard_alias is not null then v_clean_alias
      else public.learner_gamification_profiles.leaderboard_alias
    end,
    timezone = coalesce(nullif(btrim(p_timezone), ''), public.learner_gamification_profiles.timezone),
    updated_at = now()
  returning * into v_profile;

  return jsonb_build_object(
    'learner_id', v_profile.learner_id,
    'leaderboard_opt_in', v_profile.leaderboard_opt_in,
    'leaderboard_alias', v_profile.leaderboard_alias,
    'timezone', v_profile.timezone
  );
end;
$$;

revoke all on function public.update_learner_gamification_preferences(uuid, boolean, text, text) from public, anon;
grant execute on function public.update_learner_gamification_preferences(uuid, boolean, text, text) to authenticated;

-- RPC 4: Parent Visibility into Children's Gamification Achievements & Activity
create or replace function public.get_parent_children_gamification_summary()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_result jsonb;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select coalesce(jsonb_agg(child_obj order by full_name asc), '[]'::jsonb)
  into v_result
  from (
    select
      trim(l.first_name || ' ' || l.last_name) as full_name,
      jsonb_build_object(
        'learner_id', l.id,
        'full_name', trim(l.first_name || ' ' || l.last_name),
        'total_xp', coalesce(gp.total_xp, 0),
        'weekly_xp', coalesce((
          select sum(gxl.xp_amount)::integer
          from public.gamification_xp_ledger gxl
          where gxl.learner_id = l.id
            and gxl.activity_date >= public._gamification_local_date(coalesce(gp.timezone, 'Africa/Dar_es_Salaam')) - 6
        ), 0),
        'current_streak', coalesce(gp.current_streak, 0),
        'longest_streak', coalesce(gp.longest_streak, 0),
        'last_active_date', gp.last_active_date,
        'leaderboard_opt_in', coalesce(gp.leaderboard_opt_in, false),
        'earned_badges_count', (
          select count(*)::integer from public.learner_badges lb where lb.learner_id = l.id
        ),
        'recent_badges', coalesce((
          select jsonb_agg(
            jsonb_build_object(
              'badge_key', ab.badge_key,
              'name', ab.name,
              'tier', ab.tier,
              'icon_name', ab.icon_name,
              'awarded_at', lb.awarded_at
            )
            order by lb.awarded_at desc
          )
          from (
            select badge_key, awarded_at
            from public.learner_badges
            where learner_id = l.id
            order by awarded_at desc
            limit 4
          ) lb
          join public.achievement_badges ab on ab.badge_key = lb.badge_key
        ), '[]'::jsonb)
      ) as child_obj
    from public.learners l
    left join public.learner_gamification_profiles gp on gp.learner_id = l.id
    where public.is_authorized_learner_parent(l.id)
  ) rows;

  return v_result;
end;
$$;

revoke all on function public.get_parent_children_gamification_summary() from public, anon;
grant execute on function public.get_parent_children_gamification_summary() to authenticated;

commit;
