-- LearnTZ Production Cleanup & Environment Hardening Migration
-- Migration: 20261116000400_production_environment_hardening.sql
-- Description:
--   1. Hardens environment detection to fail-safe default (production).
--   2. Disables demo provisioning in production environments.
--   3. Executes dependency-ordered cascade removal of all demo/mock accounts and activity.
--   4. Archives legacy dummy subjects and unverified umbrella containers.
--   5. Verifies preservation of real registered accounts and authoritative TIE curriculum.

begin;

-- ============================================================================
-- 1. Environment Detection Hardening (Default: Production)
-- ============================================================================

create or replace function public.is_demo_environment()
returns boolean
language plpgsql
stable
as $$
declare
  v_env text;
begin
  -- Fail-safe default: If 'app.environment' is null or anything other than
  -- 'development', 'test', or 'local', it is treated strictly as production.
  v_env := lower(coalesce(current_setting('app.environment', true), 'production'));
  if v_env in ('development', 'test', 'local') then
    return true;
  end if;
  return false;
end;
$$;

grant execute on function public.is_demo_environment() to authenticated, anon;

-- ============================================================================
-- 2. Lockdown Demo Provisioning Stored Procedures
-- ============================================================================

create or replace function public.reset_demo_data()
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_deleted_progress int := 0;
  v_deleted_attempts int := 0;
  v_deleted_recs int := 0;
begin
  if not public.is_demo_environment() then
    raise exception 'Demo data operations are strictly prohibited in production' using errcode = '42501';
  end if;

  delete from public.learner_recommendations
  where learner_id in (select id from public.learners where is_demo = true or id::text like 'd2000000-%');
  get diagnostics v_deleted_recs = row_count;

  delete from public.learner_assessment_attempts
  where learner_id in (select id from public.learners where is_demo = true or id::text like 'd2000000-%');
  get diagnostics v_deleted_attempts = row_count;

  delete from public.learner_topic_mastery
  where learner_id in (select id from public.learners where is_demo = true or id::text like 'd2000000-%');

  delete from public.learner_progress
  where learner_id in (select id from public.learners where is_demo = true or id::text like 'd2000000-%');
  get diagnostics v_deleted_progress = row_count;

  delete from public.learner_sessions
  where learner_id in (select id from public.learners where is_demo = true or id::text like 'd2000000-%');

  delete from public.learner_activation_tokens
  where learner_id in (select id from public.learners where is_demo = true or id::text like 'd2000000-%');

  return jsonb_build_object(
    'success', true,
    'message', 'Demo learner activity reset successfully',
    'deleted_recommendations', v_deleted_recs,
    'deleted_assessment_attempts', v_deleted_attempts,
    'deleted_progress_records', v_deleted_progress
  );
end;
$$;

-- Ensure provision_demo_data cannot execute in production
create or replace function public.provision_demo_data(p_force_reset boolean default false)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if not public.is_demo_environment() then
    raise exception 'Demo account provisioning is strictly disabled in production' using errcode = '42501';
  end if;

  return jsonb_build_object(
    'success', false,
    'message', 'Demo provisioning disabled in production environment.'
  );
end;
$$;

-- ============================================================================
-- 3. Controlled Dependency-Ordered Cascade Removal of Demo Records
-- ============================================================================

do $$
declare
  v_real_user_existed_before boolean;
  v_real_admin_existed_before boolean;
  v_real_user_exists boolean;
  v_real_admin_exists boolean;
  v_english_topics int;
  v_demo_users_remaining int;
  v_demo_learners_remaining int;
begin
  select exists (
    select 1 from auth.users where email = 'bonimwangi243@gmail.com' and id = '558cb26f-d06e-45a7-9454-4570ab856f3f'
  ) into v_real_user_existed_before;

  select exists (
    select 1 from public.admin_profiles where auth_user_id = '558cb26f-d06e-45a7-9454-4570ab856f3f'
  ) into v_real_admin_existed_before;

  -- Stage 3.1: Learner Activity & Recommendations
  delete from public.learner_recommendations
  where learner_id in (
    select id from public.learners
    where is_demo = true or id::text like 'd2000000-%'
  );

  delete from public.learner_topic_mastery
  where learner_id in (
    select id from public.learners
    where is_demo = true or id::text like 'd2000000-%'
  );

  delete from public.learner_assessment_attempts
  where learner_id in (
    select id from public.learners
    where is_demo = true or id::text like 'd2000000-%'
  );

  delete from public.learner_progress
  where learner_id in (
    select id from public.learners
    where is_demo = true or id::text like 'd2000000-%'
  );

  delete from public.learner_sessions
  where learner_id in (
    select id from public.learners
    where is_demo = true or id::text like 'd2000000-%'
  );

  delete from public.learner_activation_tokens
  where learner_id in (
    select id from public.learners
    where is_demo = true or id::text like 'd2000000-%'
  );

  delete from public.learner_status_history
  where learner_id in (
    select id from public.learners
    where is_demo = true or id::text like 'd2000000-%'
  );

  delete from public.learner_change_history
  where learner_id in (
    select id from public.learners
    where is_demo = true or id::text like 'd2000000-%'
  );

  -- Stage 3.2: Parent-Learner Relationships
  delete from public.parent_learners
  where learner_id in (
    select id from public.learners
    where is_demo = true or id::text like 'd2000000-%'
  ) or parent_user_id in (
    select user_id from public.parent_accounts
    where is_demo = true or user_id::text like 'd1000000-%'
  );

  -- Stage 3.3: Delete Demo Learners
  delete from public.learners
  where (is_demo = true or id::text like 'd2000000-%')
    and created_by_parent_user_id != '558cb26f-d06e-45a7-9454-4570ab856f3f';

  -- Stage 3.4: Delete Demo Commercial Data & Onboarding Events
  delete from public.onboarding_events
  where parent_id in (
    select user_id from public.parent_accounts
    where is_demo = true or user_id::text like 'd1000000-%'
  ) and parent_id != '558cb26f-d06e-45a7-9454-4570ab856f3f';

  delete from public.payment_transactions
  where (is_demo = true or parent_user_id::text like 'd1000000-%')
    and parent_user_id != '558cb26f-d06e-45a7-9454-4570ab856f3f';

  delete from public.parent_subscriptions
  where (is_demo = true or parent_user_id::text like 'd1000000-%')
    and parent_user_id != '558cb26f-d06e-45a7-9454-4570ab856f3f';

  -- Stage 3.5: Delete Demo Parent Accounts
  delete from public.parent_accounts
  where (is_demo = true or user_id::text like 'd1000000-%')
    and user_id != '558cb26f-d06e-45a7-9454-4570ab856f3f';

  delete from public.profiles
  where id::text like 'd1000000-%'
    and id != '558cb26f-d06e-45a7-9454-4570ab856f3f';

  -- Stage 3.6: Delete Demo Administrators
  delete from public.admin_audit_logs
  where admin_id in (
    select id from public.admin_profiles
    where (is_demo = true or id::text like 'd3000000-%')
      and coalesce(auth_user_id, '00000000-0000-0000-0000-000000000000'::uuid) != '558cb26f-d06e-45a7-9454-4570ab856f3f'
  );

  delete from public.admin_user_roles
  where admin_id in (
    select id from public.admin_profiles
    where (is_demo = true or id::text like 'd3000000-%')
      and coalesce(auth_user_id, '00000000-0000-0000-0000-000000000000'::uuid) != '558cb26f-d06e-45a7-9454-4570ab856f3f'
  );

  delete from public.admin_profiles
  where (is_demo = true or id::text like 'd3000000-%')
    and coalesce(auth_user_id, '00000000-0000-0000-0000-000000000000'::uuid) != '558cb26f-d06e-45a7-9454-4570ab856f3f';

  -- Stage 3.7: Delete Demo Auth Users
  delete from auth.users
  where (id::text like 'd1000000-%' or id::text like 'd3000000-%' or email like '%@demo.learntz.test')
    and id != '558cb26f-d06e-45a7-9454-4570ab856f3f';

  -- ============================================================================
  -- 4. Archive Legacy Dummy & Unverified Umbrella Curriculum Records
  -- ============================================================================

  -- Archive legacy dummy subjects
  update public.subjects
  set is_published = false
  where code in ('tie-hisabati', 'tie-kiswahili', 'tie-sayansi', 'tie-primary-english');

  -- Archive unverified umbrella subjects until grade-scoped syllabus extractions are deployed
  update public.subjects
  set is_published = false
  where code in (
    'tie-pri-arts',
    'tie-pri-chinese',
    'tie-pri-geography',
    'tie-pri-history',
    'tie-pri-kiswahili',
    'tie-pri-mathematics',
    'tie-pri-science'
  ) and grade_id is null;

  -- Ensure verified English subjects remain active and grade-scoped
  update public.subjects
  set is_published = true
  where code in (
    'tie-pri-english-standard3',
    'tie-pri-english-standard4',
    'tie-pri-english-standard5',
    'tie-pri-english-standard6'
  );

  -- ============================================================================
  -- 5. Safety & Integrity Post-Execution Assertions
  -- ============================================================================

  -- 1. If a genuine registered Super Admin / Parent account existed before cleanup, assert it is preserved
  if v_real_user_existed_before then
    select exists (
      select 1 from auth.users where email = 'bonimwangi243@gmail.com' and id = '558cb26f-d06e-45a7-9454-4570ab856f3f'
    ) into v_real_user_exists;

    if not v_real_user_exists then
      raise exception 'FATAL INTEGRITY VIOLATION: Genuine registered user bonimwangi243@gmail.com was deleted!' using errcode = 'P0001';
    end if;
  end if;

  if v_real_admin_existed_before then
    select exists (
      select 1 from public.admin_profiles where auth_user_id = '558cb26f-d06e-45a7-9454-4570ab856f3f'
    ) into v_real_admin_exists;

    if not v_real_admin_exists then
      raise exception 'FATAL INTEGRITY VIOLATION: Genuine admin profile for bonimwangi243@gmail.com was deleted!' using errcode = 'P0001';
    end if;
  end if;

  -- 2. Assert verified English Standards III-VI curriculum remains intact
  select count(*) into v_english_topics
  from public.topics t
  join public.subjects s on s.id = t.subject_id
  where s.code in (
    'tie-pri-english-standard3',
    'tie-pri-english-standard4',
    'tie-pri-english-standard5',
    'tie-pri-english-standard6'
  );

  if v_english_topics != 28 then
    raise exception 'FATAL INTEGRITY VIOLATION: Verified English topics count is % (expected 28)!', v_english_topics using errcode = 'P0001';
  end if;

  -- 3. Assert zero demo accounts remain
  select count(*) into v_demo_users_remaining
  from auth.users
  where email like '%@demo.learntz.test';

  if v_demo_users_remaining > 0 then
    raise exception 'CLEANUP INCOMPLETE: % demo users remain in auth.users!', v_demo_users_remaining using errcode = 'P0001';
  end if;

  select count(*) into v_demo_learners_remaining
  from public.learners
  where is_demo = true or id::text like 'd2000000-%';

  if v_demo_learners_remaining > 0 then
    raise exception 'CLEANUP INCOMPLETE: % demo learners remain in learners table!', v_demo_learners_remaining using errcode = 'P0001';
  end if;
end $$;

commit;
