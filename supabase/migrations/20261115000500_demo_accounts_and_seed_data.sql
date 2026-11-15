-- LearnTZ Demo Accounts, Test Users & Seed Data System Migration
-- Migration: 20261115000500_demo_accounts_and_seed_data.sql

begin;

-- ============================================================================
-- 1. Security & Identification: Add is_demo column to core entities
-- ============================================================================

alter table public.parent_accounts
  add column if not exists is_demo boolean not null default false;

create index if not exists parent_accounts_is_demo_idx
  on public.parent_accounts (is_demo);

alter table public.learners
  add column if not exists is_demo boolean not null default false;

create index if not exists learners_is_demo_idx
  on public.learners (is_demo);

alter table public.admin_profiles
  add column if not exists is_demo boolean not null default false;

create index if not exists admin_profiles_is_demo_idx
  on public.admin_profiles (is_demo);

alter table public.parent_subscriptions
  add column if not exists is_demo boolean not null default false;

create index if not exists parent_subscriptions_is_demo_idx
  on public.parent_subscriptions (is_demo);

alter table public.payment_transactions
  add column if not exists is_demo boolean not null default false;

create index if not exists payment_transactions_is_demo_idx
  on public.payment_transactions (is_demo);

-- Fix onboarding_events tight privilege grants
revoke update, delete, truncate, references, trigger
  on public.onboarding_events from authenticated;

-- ============================================================================
-- 2. RWANDA (RW) Curriculum Foundation (REB CBC)
-- ============================================================================

update public.countries
set education_system = 'Rwanda Basic Education Board (REB CBC)'
where country_code = 'RW';

insert into public.education_systems (
  id, country_code, name, code
)
values (
  '20000000-0000-0000-0000-000000000081',
  'RW',
  'Rwanda Basic Education System',
  'RW_BASIC'
)
on conflict (id) do nothing;

insert into public.curriculum_authorities (
  id, country_code, education_system_id, name, code, website_url
)
values (
  '20000000-0000-0000-0000-000000000082',
  'RW',
  '20000000-0000-0000-0000-000000000081',
  'Rwanda Basic Education Board',
  'REB',
  'https://reb.rw'
)
on conflict (id) do nothing;

insert into public.curricula (
  id, country_code, education_system_id, authority_id, name, code, description
)
values (
  '20000000-0000-0000-0000-000000000083',
  'RW',
  '20000000-0000-0000-0000-000000000081',
  '20000000-0000-0000-0000-000000000082',
  'Competence-Based Curriculum',
  'REB_CBC',
  'Rwanda Competence-Based Curriculum for Basic Education supervised by REB.'
)
on conflict (id) do nothing;

insert into public.education_levels (
  id, curriculum_id, name, code, sequence
)
values
  (
    '20000000-0000-0000-0000-000000000091',
    '20000000-0000-0000-0000-000000000083',
    'Primary education',
    'PRIMARY',
    1
  ),
  (
    '20000000-0000-0000-0000-000000000092',
    '20000000-0000-0000-0000-000000000083',
    'Ordinary level secondary education',
    'ORDINARY_LEVEL',
    2
  ),
  (
    '20000000-0000-0000-0000-000000000093',
    '20000000-0000-0000-0000-000000000083',
    'Advanced level secondary education',
    'ADVANCED_LEVEL',
    3
  )
on conflict (id) do nothing;

-- Rwanda Primary Grades P1-P6
insert into public.education_grades (
  id, education_level_id, curriculum_id, name, code, sequence
)
values
  ('20000000-0000-0000-0000-000000000094', '20000000-0000-0000-0000-000000000091', '20000000-0000-0000-0000-000000000083', 'Primary 1', 'P1', 1),
  ('20000000-0000-0000-0000-000000000095', '20000000-0000-0000-0000-000000000091', '20000000-0000-0000-0000-000000000083', 'Primary 2', 'P2', 2),
  ('20000000-0000-0000-0000-000000000096', '20000000-0000-0000-0000-000000000091', '20000000-0000-0000-0000-000000000083', 'Primary 3', 'P3', 3),
  ('20000000-0000-0000-0000-000000000097', '20000000-0000-0000-0000-000000000091', '20000000-0000-0000-0000-000000000083', 'Primary 4', 'P4', 4),
  ('20000000-0000-0000-0000-000000000098', '20000000-0000-0000-0000-000000000091', '20000000-0000-0000-0000-000000000083', 'Primary 5', 'P5', 5),
  ('20000000-0000-0000-0000-000000000099', '20000000-0000-0000-0000-000000000091', '20000000-0000-0000-0000-000000000083', 'Primary 6', 'P6', 6),
  -- Secondary S1-S3
  ('20000000-0000-0000-0000-000000000100', '20000000-0000-0000-0000-000000000092', '20000000-0000-0000-0000-000000000083', 'Senior 1', 'S1', 1),
  ('20000000-0000-0000-0000-000000000101', '20000000-0000-0000-0000-000000000092', '20000000-0000-0000-0000-000000000083', 'Senior 2', 'S2', 2),
  ('20000000-0000-0000-0000-000000000102', '20000000-0000-0000-0000-000000000092', '20000000-0000-0000-0000-000000000083', 'Senior 3', 'S3', 3)
on conflict (id) do nothing;

-- Rwanda Subscription Plan
insert into public.subscription_plans (
  country_code, code, name, price_cents, currency, billing_interval, features, is_active
)
values (
  'RW',
  'rw-family-monthly',
  'LearnRW Family Monthly',
  1200000,
  'RWF',
  'monthly',
  '["Full Rwanda REB curriculum access", "Interactive practice quizzes", "Learner mastery tracking"]'::jsonb,
  true
)
on conflict (country_code, code) do nothing;

-- ============================================================================
-- 3. Core Subjects & Topics for Rwanda (RW)
-- ============================================================================

insert into public.subjects (
  id, country_code, curriculum_id, education_level_id, grade_id, code, name, description, display_order, is_published
)
values
  (
    '30000000-0000-0000-0000-000000000081',
    'RW',
    '20000000-0000-0000-0000-000000000083',
    '20000000-0000-0000-0000-000000000091',
    '20000000-0000-0000-0000-000000000097', -- P4
    'RW_P4_MATH',
    'Mathematics',
    'Primary 4 REB Mathematics',
    1,
    true
  ),
  (
    '30000000-0000-0000-0000-000000000082',
    'RW',
    '20000000-0000-0000-0000-000000000083',
    '20000000-0000-0000-0000-000000000092',
    '20000000-0000-0000-0000-000000000100', -- S1
    'RW_S1_PHY',
    'Physics',
    'Senior 1 REB Physics',
    1,
    true
  )
on conflict (curriculum_id, education_level_id, coalesce(grade_id, '00000000-0000-0000-0000-000000000000'::uuid), code)
do update set is_published = true;

-- Topics for Rwanda
insert into public.topics (
  id, subject_id, title, summary, display_order, is_published
)
values
  (
    '40000000-0000-0000-0000-000000000081',
    '30000000-0000-0000-0000-000000000081',
    'Numbers and Operations to 100,000',
    'Place value, addition, and subtraction within 100,000.',
    1,
    true
  ),
  (
    '40000000-0000-0000-0000-000000000082',
    '30000000-0000-0000-0000-000000000082',
    'Measurements of Physical Quantities',
    'SI units, mass, length, time, and density.',
    1,
    true
  )
on conflict (id) do nothing;

-- Lessons for Rwanda
insert into public.lessons (
  id, topic_id, title, body_markdown, estimated_minutes, is_free_preview, display_order, is_published
)
values
  (
    '50000000-0000-0000-0000-000000000081',
    '40000000-0000-0000-0000-000000000081',
    'Understanding Large Whole Numbers',
    '# Understanding Large Whole Numbers\n\nIn Primary 4, we read and write whole numbers up to 100,000 using standard place-value charts.',
    15,
    true,
    1,
    true
  ),
  (
    '50000000-0000-0000-0000-000000000082',
    '40000000-0000-0000-0000-000000000082',
    'Introduction to Physical Measurements',
    '# Physical Measurements\n\nPhysics begins with accurate measurement. The fundamental SI units include metres (m), kilograms (kg), and seconds (s).',
    20,
    true,
    1,
    true
  )
on conflict (id) do nothing;

-- ============================================================================
-- 4. Environment Verification Function
-- ============================================================================

create or replace function public.is_demo_environment()
returns boolean
language plpgsql
stable
as $$
declare
  v_env text;
begin
  v_env := lower(coalesce(current_setting('app.environment', true), 'development'));
  if v_env = 'production' then
    return false;
  end if;
  return true;
end;
$$;

grant execute on function public.is_demo_environment() to authenticated, anon;

-- ============================================================================
-- 5. Stored Procedure: Reset Demo Data
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

  -- 1. Reset learner activity for demo learners
  delete from public.learner_recommendations
  where learner_id in (select id from public.learners where is_demo = true);
  get diagnostics v_deleted_recs = row_count;

  delete from public.learner_assessment_attempts
  where learner_id in (select id from public.learners where is_demo = true);
  get diagnostics v_deleted_attempts = row_count;

  delete from public.learner_topic_mastery
  where learner_id in (select id from public.learners where is_demo = true);

  delete from public.learner_progress
  where learner_id in (select id from public.learners where is_demo = true);
  get diagnostics v_deleted_progress = row_count;

  -- 2. Reset sessions and tokens
  delete from public.learner_sessions
  where learner_id in (select id from public.learners where is_demo = true);

  delete from public.learner_activation_tokens
  where learner_id in (select id from public.learners where is_demo = true);

  return jsonb_build_object(
    'success', true,
    'message', 'Demo learner activity reset successfully',
    'deleted_recommendations', v_deleted_recs,
    'deleted_assessment_attempts', v_deleted_attempts,
    'deleted_progress_records', v_deleted_progress
  );
end;
$$;

grant execute on function public.reset_demo_data() to authenticated;

-- ============================================================================
-- 6. Stored Procedure: Provision Demo Data (Idempotent)
-- ============================================================================

create or replace function public.provision_demo_data(p_force_reset boolean default false)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  -- Deterministic Parent IDs
  v_parent1_id uuid := 'd1000000-0000-0000-0000-000000000001';
  v_parent2_id uuid := 'd1000000-0000-0000-0000-000000000002';
  v_parent3_id uuid := 'd1000000-0000-0000-0000-000000000003';
  v_parent4_id uuid := 'd1000000-0000-0000-0000-000000000004';
  v_parent5_id uuid := 'd1000000-0000-0000-0000-000000000005';

  -- Deterministic Admin IDs
  v_admin_super_id   uuid := 'd3000000-0000-0000-0000-000000000001';
  v_admin_tz_id      uuid := 'd3000000-0000-0000-0000-000000000002';
  v_admin_ke_id      uuid := 'd3000000-0000-0000-0000-000000000003';
  v_admin_content_id uuid := 'd3000000-0000-0000-0000-000000000004';
  v_admin_finance_id uuid := 'd3000000-0000-0000-0000-000000000005';
  v_admin_support_id uuid := 'd3000000-0000-0000-0000-000000000006';

  -- Bcrypt hashes
  -- 'ParentDemo1234!' -> standard bcrypt
  v_parent_password_hash text := '$2a$10$wN19Q79E3zS8s1.60yT3h.K2nQY5qF8e4g6zG5sO8k3vF5jH2wP.S';
  -- 'AdminDemo1234!' -> standard bcrypt
  v_admin_password_hash  text := '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi';

  -- Learner credential hash for PIN '1234'
  v_learner_pin text := '1234';
  v_learner_salt text := 'learntz_demo_salt';
  v_learner_hash text;

  -- Plan IDs
  v_plan_tz_m uuid;
  v_plan_tz_a uuid;
  v_plan_ke_m uuid;
  v_plan_ug_m uuid;
  v_plan_rw_m uuid;

  -- Education reference IDs
  v_tz_sys uuid := '20000000-0000-0000-0000-000000000001';
  v_tz_cur uuid := '20000000-0000-0000-0000-000000000002';
  v_tz_lvl_pri uuid := '20000000-0000-0000-0000-000000000010';
  v_tz_lvl_sec uuid := '20000000-0000-0000-0000-000000000011';
  v_tz_std2 uuid;
  v_tz_std4 uuid;
  v_tz_std6 uuid;
  v_tz_form2 uuid;

  v_ke_sys uuid := '20000000-0000-0000-0000-000000000021';
  v_ke_cur uuid := '20000000-0000-0000-0000-000000000023';
  v_ke_lvl_pri uuid := '20000000-0000-0000-0000-000000000031';
  v_ke_lvl_jss uuid := '20000000-0000-0000-0000-000000000032';
  v_ke_grade4 uuid;
  v_ke_grade7 uuid;

  v_ug_sys uuid := '20000000-0000-0000-0000-000000000051';
  v_ug_cur uuid;
  v_ug_lvl_pri uuid;
  v_ug_lvl_sec uuid;
  v_ug_p5 uuid;
  v_ug_s2 uuid;

  v_rw_sys uuid := '20000000-0000-0000-0000-000000000081';
  v_rw_cur uuid := '20000000-0000-0000-0000-000000000083';
  v_rw_lvl_pri uuid := '20000000-0000-0000-0000-000000000091';
  v_rw_lvl_sec uuid := '20000000-0000-0000-0000-000000000092';
  v_rw_p4 uuid := '20000000-0000-0000-0000-000000000097';
  v_rw_s1 uuid := '20000000-0000-0000-0000-000000000100';

  -- Temporary variables
  v_sub_id uuid;
  v_subject_id uuid;
  v_topic_id uuid;
  v_lesson_id uuid;
begin
  if not public.is_demo_environment() then
    raise exception 'Demo accounts cannot be provisioned in production environments.' using errcode = '42501';
  end if;

  if p_force_reset then
    perform public.reset_demo_data();
  end if;

  v_parent_password_hash := extensions.crypt('ParentDemo1234!', extensions.gen_salt('bf', 8));
  v_admin_password_hash  := extensions.crypt('AdminDemo1234!', extensions.gen_salt('bf', 8));
  v_learner_hash := public.hash_learner_secret(v_learner_salt, v_learner_pin);

  -- Fetch existing grades and their parent levels
  select id, education_level_id into v_tz_std2, v_tz_lvl_pri from public.education_grades where curriculum_id = v_tz_cur and code = 'STANDARD_2' limit 1;
  select id into v_tz_std4 from public.education_grades where curriculum_id = v_tz_cur and code = 'STANDARD_4' limit 1;
  select id into v_tz_std6 from public.education_grades where curriculum_id = v_tz_cur and code = 'STANDARD_6' limit 1;
  select id, education_level_id into v_tz_form2, v_tz_lvl_sec from public.education_grades where curriculum_id = v_tz_cur and code = 'FORM_2' limit 1;

  select id, education_level_id into v_ke_grade4, v_ke_lvl_pri from public.education_grades where curriculum_id = v_ke_cur and code = 'GRADE_4' limit 1;
  select id, education_level_id into v_ke_grade7, v_ke_lvl_jss from public.education_grades where curriculum_id = v_ke_cur and code = 'GRADE_7' limit 1;

  select id into v_ug_cur from public.curricula where country_code = 'UG' limit 1;
  select id, education_level_id into v_ug_p5, v_ug_lvl_pri from public.education_grades where curriculum_id = v_ug_cur and code = 'P5' limit 1;
  select id, education_level_id into v_ug_s2, v_ug_lvl_sec from public.education_grades where curriculum_id = v_ug_cur and code = 'S2' limit 1;

  select id, education_level_id into v_rw_p4, v_rw_lvl_pri from public.education_grades where curriculum_id = v_rw_cur and code = 'P4' limit 1;
  select id, education_level_id into v_rw_s1, v_rw_lvl_sec from public.education_grades where curriculum_id = v_rw_cur and code = 'S1' limit 1;

  -- Fetch plans
  select id into v_plan_tz_m from public.subscription_plans where country_code = 'TZ' and billing_interval = 'monthly' limit 1;
  select id into v_plan_tz_a from public.subscription_plans where country_code = 'TZ' and billing_interval = 'annual' limit 1;
  select id into v_plan_ke_m from public.subscription_plans where country_code = 'KE' limit 1;
  select id into v_plan_ug_m from public.subscription_plans where country_code = 'UG' limit 1;
  select id into v_plan_rw_m from public.subscription_plans where country_code = 'RW' limit 1;

  -- ==========================================================================
  -- A. PROVISION 5 DEMO PARENT ACCOUNTS
  -- ==========================================================================

  -- Parent 01: Tanzania, 1 Primary Learner
  insert into auth.users (
    id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    phone_change, phone_change_token, email_change_token_current, reauthentication_token,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at
  ) values (
    v_parent1_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
    'parent01@demo.learntz.test', v_parent_password_hash, now(),
    '', '', '', '', '', '', '', '',
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    '{"full_name": "Juma Bakari"}'::jsonb, now(), now()
  ) on conflict (id) do update set
    email = excluded.email,
    encrypted_password = excluded.encrypted_password,
    confirmation_token = '',
    recovery_token = '',
    email_change_token_new = '',
    email_change = '',
    phone_change = '',
    phone_change_token = '',
    email_change_token_current = '',
    reauthentication_token = '';

  insert into auth.identities (
    id, provider_id, user_id, identity_data, provider,
    last_sign_in_at, created_at, updated_at
  ) values (
    v_parent1_id, v_parent1_id::text, v_parent1_id,
    jsonb_build_object(
      'sub', v_parent1_id::text,
      'email', 'parent01@demo.learntz.test',
      'email_verified', true,
      'phone_verified', false
    ),
    'email', now(), now(), now()
  ) on conflict (provider_id, provider) do update set
    identity_data = excluded.identity_data,
    updated_at = now();

  insert into public.profiles (id, full_name)
  values (v_parent1_id, 'Juma Bakari')
  on conflict (id) do update set full_name = excluded.full_name;

  insert into public.parent_accounts (user_id, country_code, phone_number, onboarding_status, is_demo)
  values (v_parent1_id, 'TZ', '+255711000001', 'COMPLETED', true)
  on conflict (user_id) do update set is_demo = true, onboarding_status = 'COMPLETED', country_code = excluded.country_code, phone_number = excluded.phone_number;

  insert into public.user_roles (user_id, role)
  values (v_parent1_id, 'parent')
  on conflict (user_id, role, coalesce(country_code, '')) do nothing;

  -- Parent 02: Tanzania, 3 Children (Std 2, Std 6, Form 2)
  insert into auth.users (
    id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    phone_change, phone_change_token, email_change_token_current, reauthentication_token,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at
  ) values (
    v_parent2_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
    'parent02@demo.learntz.test', v_parent_password_hash, now(),
    '', '', '', '', '', '', '', '',
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    '{"full_name": "Rehema Mwangi"}'::jsonb, now(), now()
  ) on conflict (id) do update set
    email = excluded.email,
    encrypted_password = excluded.encrypted_password,
    confirmation_token = '',
    recovery_token = '',
    email_change_token_new = '',
    email_change = '',
    phone_change = '',
    phone_change_token = '',
    email_change_token_current = '',
    reauthentication_token = '';

  insert into auth.identities (
    id, provider_id, user_id, identity_data, provider,
    last_sign_in_at, created_at, updated_at
  ) values (
    v_parent2_id, v_parent2_id::text, v_parent2_id,
    jsonb_build_object(
      'sub', v_parent2_id::text,
      'email', 'parent02@demo.learntz.test',
      'email_verified', true,
      'phone_verified', false
    ),
    'email', now(), now(), now()
  ) on conflict (provider_id, provider) do update set
    identity_data = excluded.identity_data,
    updated_at = now();

  insert into public.profiles (id, full_name)
  values (v_parent2_id, 'Rehema Mwangi')
  on conflict (id) do update set full_name = excluded.full_name;

  insert into public.parent_accounts (user_id, country_code, phone_number, onboarding_status, is_demo)
  values (v_parent2_id, 'TZ', '+255711000002', 'COMPLETED', true)
  on conflict (user_id) do update set is_demo = true, onboarding_status = 'COMPLETED', country_code = excluded.country_code, phone_number = excluded.phone_number;

  insert into public.user_roles (user_id, role)
  values (v_parent2_id, 'parent')
  on conflict (user_id, role, coalesce(country_code, '')) do nothing;

  -- Parent 03: Kenya, Kenya CBC
  insert into auth.users (
    id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    phone_change, phone_change_token, email_change_token_current, reauthentication_token,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at
  ) values (
    v_parent3_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
    'parent03@demo.learntz.test', v_parent_password_hash, now(),
    '', '', '', '', '', '', '', '',
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    '{"full_name": "Grace Wanjiku"}'::jsonb, now(), now()
  ) on conflict (id) do update set
    email = excluded.email,
    encrypted_password = excluded.encrypted_password,
    confirmation_token = '',
    recovery_token = '',
    email_change_token_new = '',
    email_change = '',
    phone_change = '',
    phone_change_token = '',
    email_change_token_current = '',
    reauthentication_token = '';

  insert into auth.identities (
    id, provider_id, user_id, identity_data, provider,
    last_sign_in_at, created_at, updated_at
  ) values (
    v_parent3_id, v_parent3_id::text, v_parent3_id,
    jsonb_build_object(
      'sub', v_parent3_id::text,
      'email', 'parent03@demo.learntz.test',
      'email_verified', true,
      'phone_verified', false
    ),
    'email', now(), now(), now()
  ) on conflict (provider_id, provider) do update set
    identity_data = excluded.identity_data,
    updated_at = now();

  insert into public.profiles (id, full_name)
  values (v_parent3_id, 'Grace Wanjiku')
  on conflict (id) do update set full_name = excluded.full_name;

  insert into public.parent_accounts (user_id, country_code, phone_number, onboarding_status, is_demo)
  values (v_parent3_id, 'KE', '+254711000003', 'COMPLETED', true)
  on conflict (user_id) do update set is_demo = true, onboarding_status = 'COMPLETED', country_code = excluded.country_code, phone_number = excluded.phone_number;

  insert into public.user_roles (user_id, role)
  values (v_parent3_id, 'parent')
  on conflict (user_id, role, coalesce(country_code, '')) do nothing;

  -- Parent 04: Uganda, Uganda NCDC
  insert into auth.users (
    id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    phone_change, phone_change_token, email_change_token_current, reauthentication_token,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at
  ) values (
    v_parent4_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
    'parent04@demo.learntz.test', v_parent_password_hash, now(),
    '', '', '', '', '', '', '', '',
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    '{"full_name": "Robert Mukasa"}'::jsonb, now(), now()
  ) on conflict (id) do update set
    email = excluded.email,
    encrypted_password = excluded.encrypted_password,
    confirmation_token = '',
    recovery_token = '',
    email_change_token_new = '',
    email_change = '',
    phone_change = '',
    phone_change_token = '',
    email_change_token_current = '',
    reauthentication_token = '';

  insert into auth.identities (
    id, provider_id, user_id, identity_data, provider,
    last_sign_in_at, created_at, updated_at
  ) values (
    v_parent4_id, v_parent4_id::text, v_parent4_id,
    jsonb_build_object(
      'sub', v_parent4_id::text,
      'email', 'parent04@demo.learntz.test',
      'email_verified', true,
      'phone_verified', false
    ),
    'email', now(), now(), now()
  ) on conflict (provider_id, provider) do update set
    identity_data = excluded.identity_data,
    updated_at = now();

  insert into public.profiles (id, full_name)
  values (v_parent4_id, 'Robert Mukasa')
  on conflict (id) do update set full_name = excluded.full_name;

  insert into public.parent_accounts (user_id, country_code, phone_number, onboarding_status, is_demo)
  values (v_parent4_id, 'UG', '+256711000004', 'COMPLETED', true)
  on conflict (user_id) do update set is_demo = true, onboarding_status = 'COMPLETED', country_code = excluded.country_code, phone_number = excluded.phone_number;

  insert into public.user_roles (user_id, role)
  values (v_parent4_id, 'parent')
  on conflict (user_id, role, coalesce(country_code, '')) do nothing;

  -- Parent 05: Rwanda, Rwanda REB
  insert into auth.users (
    id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    phone_change, phone_change_token, email_change_token_current, reauthentication_token,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at
  ) values (
    v_parent5_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
    'parent05@demo.learntz.test', v_parent_password_hash, now(),
    '', '', '', '', '', '', '', '',
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    '{"full_name": "Jean Claude Habimana"}'::jsonb, now(), now()
  ) on conflict (id) do update set
    email = excluded.email,
    encrypted_password = excluded.encrypted_password,
    confirmation_token = '',
    recovery_token = '',
    email_change_token_new = '',
    email_change = '',
    phone_change = '',
    phone_change_token = '',
    email_change_token_current = '',
    reauthentication_token = '';

  insert into auth.identities (
    id, provider_id, user_id, identity_data, provider,
    last_sign_in_at, created_at, updated_at
  ) values (
    v_parent5_id, v_parent5_id::text, v_parent5_id,
    jsonb_build_object(
      'sub', v_parent5_id::text,
      'email', 'parent05@demo.learntz.test',
      'email_verified', true,
      'phone_verified', false
    ),
    'email', now(), now(), now()
  ) on conflict (provider_id, provider) do update set
    identity_data = excluded.identity_data,
    updated_at = now();

  insert into public.profiles (id, full_name)
  values (v_parent5_id, 'Jean Claude Habimana')
  on conflict (id) do update set full_name = excluded.full_name;

  insert into public.parent_accounts (user_id, country_code, phone_number, onboarding_status, is_demo)
  values (v_parent5_id, 'RW', '+250711000005', 'COMPLETED', true)
  on conflict (user_id) do update set is_demo = true, onboarding_status = 'COMPLETED', country_code = excluded.country_code, phone_number = excluded.phone_number;

  insert into public.user_roles (user_id, role)
  values (v_parent5_id, 'parent')
  on conflict (user_id, role, coalesce(country_code, '')) do nothing;

  -- ==========================================================================
  -- B. PROVISION 10 DEMO LEARNER ACCOUNTS
  -- ==========================================================================

  -- Learner 01: TZ-LRN-0101 (Parent 01 / TZ / Std 4 / High Performing)
  insert into public.learners (
    id, first_name, last_name, date_of_birth, gender, country_code,
    education_system_id, curriculum_id, education_level_id, grade_id,
    created_by_parent_user_id, registration_request_id, learner_code, avatar_preset, is_demo
  ) values (
    'd2000000-0000-0000-0000-000000000001', 'Amani', 'Bakari', '2014-04-12', 'female', 'TZ',
    v_tz_sys, v_tz_cur, v_tz_lvl_pri, v_tz_std4,
    v_parent1_id, gen_random_uuid(), 'TZ-LRN-0101', 'owl_scholar', true
  ) on conflict (id) do update set is_demo = true;

  insert into public.parent_learners (
    learner_id, parent_user_id, relationship_role, relationship_status, created_by_parent_user_id
  ) values (
    'd2000000-0000-0000-0000-000000000001', v_parent1_id, 'parent', 'active', v_parent1_id
  ) on conflict (learner_id, parent_user_id) do nothing;

  insert into public.learner_profiles (
    learner_id, parent_id, username, access_status, access_mode,
    credential_type, credential_hash, credential_salt
  ) values (
    'd2000000-0000-0000-0000-000000000001', v_parent1_id, 'amani_tz', 'active', 'independent_device',
    'pin', v_learner_hash, v_learner_salt
  ) on conflict (learner_id) do update set
    username = excluded.username,
    credential_type = excluded.credential_type,
    credential_hash = excluded.credential_hash,
    credential_salt = excluded.credential_salt,
    access_status = excluded.access_status,
    access_mode = excluded.access_mode;

  insert into public.learner_devices (
    learner_id, device_identifier, device_name, device_type, is_active
  ) values (
    'd2000000-0000-0000-0000-000000000001', 'dev-amani-tab', 'Amani Tablet', 'tablet', true
  ) on conflict (learner_id, device_identifier) do nothing;

  -- Learner 02: TZ-LRN-0201 (Parent 02 / TZ / Std 2 / Average Performing)
  insert into public.learners (
    id, first_name, last_name, date_of_birth, gender, country_code,
    education_system_id, curriculum_id, education_level_id, grade_id,
    created_by_parent_user_id, registration_request_id, learner_code, avatar_preset, is_demo
  ) values (
    'd2000000-0000-0000-0000-000000000002', 'Baraka', 'Mwangi', '2016-09-08', 'male', 'TZ',
    v_tz_sys, v_tz_cur, v_tz_lvl_pri, v_tz_std2,
    v_parent2_id, gen_random_uuid(), 'TZ-LRN-0201', 'lion_reader', true
  ) on conflict (id) do update set is_demo = true;

  insert into public.parent_learners (
    learner_id, parent_user_id, relationship_role, relationship_status, created_by_parent_user_id
  ) values (
    'd2000000-0000-0000-0000-000000000002', v_parent2_id, 'parent', 'active', v_parent2_id
  ) on conflict (learner_id, parent_user_id) do nothing;

  insert into public.learner_profiles (
    learner_id, parent_id, username, access_status, access_mode,
    credential_type, credential_hash, credential_salt
  ) values (
    'd2000000-0000-0000-0000-000000000002', v_parent2_id, 'baraka_tz', 'active', 'parent_managed',
    'pin', v_learner_hash, v_learner_salt
  ) on conflict (learner_id) do update set
    username = excluded.username,
    credential_type = excluded.credential_type,
    credential_hash = excluded.credential_hash,
    credential_salt = excluded.credential_salt,
    access_status = excluded.access_status,
    access_mode = excluded.access_mode;

  -- Learner 03: TZ-LRN-0202 (Parent 02 / TZ / Std 6 / High Performing)
  insert into public.learners (
    id, first_name, last_name, date_of_birth, gender, country_code,
    education_system_id, curriculum_id, education_level_id, grade_id,
    created_by_parent_user_id, registration_request_id, learner_code, avatar_preset, is_demo
  ) values (
    'd2000000-0000-0000-0000-000000000003', 'Neema', 'Mwangi', '2012-02-19', 'female', 'TZ',
    v_tz_sys, v_tz_cur, v_tz_lvl_pri, v_tz_std6,
    v_parent2_id, gen_random_uuid(), 'TZ-LRN-0202', 'cheetah_runner', true
  ) on conflict (id) do update set is_demo = true;

  insert into public.parent_learners (
    learner_id, parent_user_id, relationship_role, relationship_status, created_by_parent_user_id
  ) values (
    'd2000000-0000-0000-0000-000000000003', v_parent2_id, 'parent', 'active', v_parent2_id
  ) on conflict (learner_id, parent_user_id) do nothing;

  insert into public.learner_profiles (
    learner_id, parent_id, username, access_status, access_mode,
    credential_type, credential_hash, credential_salt
  ) values (
    'd2000000-0000-0000-0000-000000000003', v_parent2_id, 'neema_tz', 'active', 'independent_device',
    'pin', v_learner_hash, v_learner_salt
  ) on conflict (learner_id) do update set
    username = excluded.username,
    credential_type = excluded.credential_type,
    credential_hash = excluded.credential_hash,
    credential_salt = excluded.credential_salt,
    access_status = excluded.access_status,
    access_mode = excluded.access_mode;

  insert into public.learner_devices (
    learner_id, device_identifier, device_name, device_type, is_active
  ) values (
    'd2000000-0000-0000-0000-000000000003', 'dev-neema-phone', 'Neema Phone', 'phone', true
  ) on conflict (learner_id, device_identifier) do nothing;

  -- Learner 04: TZ-LRN-0203 (Parent 02 / TZ / Form 2 / Requiring Support)
  insert into public.learners (
    id, first_name, last_name, date_of_birth, gender, country_code,
    education_system_id, curriculum_id, education_level_id, grade_id,
    created_by_parent_user_id, registration_request_id, learner_code, avatar_preset, is_demo
  ) values (
    'd2000000-0000-0000-0000-000000000004', 'Juma', 'Mwangi', '2010-06-15', 'male', 'TZ',
    v_tz_sys, v_tz_cur, v_tz_lvl_sec, v_tz_form2,
    v_parent2_id, gen_random_uuid(), 'TZ-LRN-0203', 'elephant_math', true
  ) on conflict (id) do update set is_demo = true;

  insert into public.parent_learners (
    learner_id, parent_user_id, relationship_role, relationship_status, created_by_parent_user_id
  ) values (
    'd2000000-0000-0000-0000-000000000004', v_parent2_id, 'parent', 'active', v_parent2_id
  ) on conflict (learner_id, parent_user_id) do nothing;

  insert into public.learner_profiles (
    learner_id, parent_id, username, access_status, access_mode,
    credential_type, credential_hash, credential_salt
  ) values (
    'd2000000-0000-0000-0000-000000000004', v_parent2_id, 'juma_tz', 'active', 'independent_device',
    'pin', v_learner_hash, v_learner_salt
  ) on conflict (learner_id) do update set
    username = excluded.username,
    credential_type = excluded.credential_type,
    credential_hash = excluded.credential_hash,
    credential_salt = excluded.credential_salt,
    access_status = excluded.access_status,
    access_mode = excluded.access_mode;

  -- Learner 05: KE-LRN-0301 (Parent 03 / KE / CBC Grade 4 / Average Performing)
  insert into public.learners (
    id, first_name, last_name, date_of_birth, gender, country_code,
    education_system_id, curriculum_id, education_level_id, grade_id,
    created_by_parent_user_id, registration_request_id, learner_code, avatar_preset, is_demo
  ) values (
    'd2000000-0000-0000-0000-000000000005', 'Zawadi', 'Wanjiku', '2014-08-20', 'female', 'KE',
    v_ke_sys, v_ke_cur, v_ke_lvl_pri, v_ke_grade4,
    v_parent3_id, gen_random_uuid(), 'KE-LRN-0301', 'giraffe_thinker', true
  ) on conflict (id) do update set is_demo = true;

  insert into public.parent_learners (
    learner_id, parent_user_id, relationship_role, relationship_status, created_by_parent_user_id
  ) values (
    'd2000000-0000-0000-0000-000000000005', v_parent3_id, 'parent', 'active', v_parent3_id
  ) on conflict (learner_id, parent_user_id) do nothing;

  insert into public.learner_profiles (
    learner_id, parent_id, username, access_status, access_mode,
    credential_type, credential_hash, credential_salt
  ) values (
    'd2000000-0000-0000-0000-000000000005', v_parent3_id, 'zawadi_ke', 'active', 'parent_managed',
    'pin', v_learner_hash, v_learner_salt
  ) on conflict (learner_id) do update set
    username = excluded.username,
    credential_type = excluded.credential_type,
    credential_hash = excluded.credential_hash,
    credential_salt = excluded.credential_salt,
    access_status = excluded.access_status,
    access_mode = excluded.access_mode;

  -- Learner 06: KE-LRN-0302 (Parent 03 / KE / CBC Grade 7 / High Performing)
  insert into public.learners (
    id, first_name, last_name, date_of_birth, gender, country_code,
    education_system_id, curriculum_id, education_level_id, grade_id,
    created_by_parent_user_id, registration_request_id, learner_code, avatar_preset, is_demo
  ) values (
    'd2000000-0000-0000-0000-000000000006', 'Kamau', 'Wanjiku', '2011-11-03', 'male', 'KE',
    v_ke_sys, v_ke_cur, v_ke_lvl_jss, v_ke_grade7,
    v_parent3_id, gen_random_uuid(), 'KE-LRN-0302', 'falcon_scout', true
  ) on conflict (id) do update set is_demo = true;

  insert into public.parent_learners (
    learner_id, parent_user_id, relationship_role, relationship_status, created_by_parent_user_id
  ) values (
    'd2000000-0000-0000-0000-000000000006', v_parent3_id, 'parent', 'active', v_parent3_id
  ) on conflict (learner_id, parent_user_id) do nothing;

  insert into public.learner_profiles (
    learner_id, parent_id, username, access_status, access_mode,
    credential_type, credential_hash, credential_salt
  ) values (
    'd2000000-0000-0000-0000-000000000006', v_parent3_id, 'kamau_ke', 'active', 'independent_device',
    'pin', v_learner_hash, v_learner_salt
  ) on conflict (learner_id) do update set
    username = excluded.username,
    credential_type = excluded.credential_type,
    credential_hash = excluded.credential_hash,
    credential_salt = excluded.credential_salt,
    access_status = excluded.access_status,
    access_mode = excluded.access_mode;

  insert into public.learner_devices (
    learner_id, device_identifier, device_name, device_type, is_active
  ) values (
    'd2000000-0000-0000-0000-000000000006', 'dev-kamau-laptop', 'Kamau ChromeBook', 'desktop', true
  ) on conflict (learner_id, device_identifier) do nothing;

  -- Learner 07: UG-LRN-0401 (Parent 04 / UG / Primary P5 / Requiring Support)
  insert into public.learners (
    id, first_name, last_name, date_of_birth, gender, country_code,
    education_system_id, curriculum_id, education_level_id, grade_id,
    created_by_parent_user_id, registration_request_id, learner_code, avatar_preset, is_demo
  ) values (
    'd2000000-0000-0000-0000-000000000007', 'Kato', 'Mukasa', '2013-05-14', 'male', 'UG',
    v_ug_sys, v_ug_cur, v_ug_lvl_pri, v_ug_p5,
    v_parent4_id, gen_random_uuid(), 'UG-LRN-0401', 'zebra_writer', true
  ) on conflict (id) do update set is_demo = true;

  insert into public.parent_learners (
    learner_id, parent_user_id, relationship_role, relationship_status, created_by_parent_user_id
  ) values (
    'd2000000-0000-0000-0000-000000000007', v_parent4_id, 'parent', 'active', v_parent4_id
  ) on conflict (learner_id, parent_user_id) do nothing;

  insert into public.learner_profiles (
    learner_id, parent_id, username, access_status, access_mode,
    credential_type, credential_hash, credential_salt
  ) values (
    'd2000000-0000-0000-0000-000000000007', v_parent4_id, 'kato_ug', 'active', 'parent_managed',
    'pin', v_learner_hash, v_learner_salt
  ) on conflict (learner_id) do update set
    username = excluded.username,
    credential_type = excluded.credential_type,
    credential_hash = excluded.credential_hash,
    credential_salt = excluded.credential_salt,
    access_status = excluded.access_status,
    access_mode = excluded.access_mode;

  -- Learner 08: UG-LRN-0402 (Parent 04 / UG / Senior 2 / High Performing)
  insert into public.learners (
    id, first_name, last_name, date_of_birth, gender, country_code,
    education_system_id, curriculum_id, education_level_id, grade_id,
    created_by_parent_user_id, registration_request_id, learner_code, avatar_preset, is_demo
  ) values (
    'd2000000-0000-0000-0000-000000000008', 'Babirye', 'Mukasa', '2010-01-25', 'female', 'UG',
    v_ug_sys, v_ug_cur, v_ug_lvl_sec, v_ug_s2,
    v_parent4_id, gen_random_uuid(), 'UG-LRN-0402', 'rhino_builder', true
  ) on conflict (id) do update set is_demo = true;

  insert into public.parent_learners (
    learner_id, parent_user_id, relationship_role, relationship_status, created_by_parent_user_id
  ) values (
    'd2000000-0000-0000-0000-000000000008', v_parent4_id, 'parent', 'active', v_parent4_id
  ) on conflict (learner_id, parent_user_id) do nothing;

  insert into public.learner_profiles (
    learner_id, parent_id, username, access_status, access_mode,
    credential_type, credential_hash, credential_salt
  ) values (
    'd2000000-0000-0000-0000-000000000008', v_parent4_id, 'babirye_ug', 'active', 'independent_device',
    'pin', v_learner_hash, v_learner_salt
  ) on conflict (learner_id) do update set
    username = excluded.username,
    credential_type = excluded.credential_type,
    credential_hash = excluded.credential_hash,
    credential_salt = excluded.credential_salt,
    access_status = excluded.access_status,
    access_mode = excluded.access_mode;

  insert into public.learner_devices (
    learner_id, device_identifier, device_name, device_type, is_active
  ) values (
    'd2000000-0000-0000-0000-000000000008', 'dev-babirye-tab', 'Babirye Tab', 'tablet', true
  ) on conflict (learner_id, device_identifier) do nothing;

  -- Learner 09: RW-LRN-0501 (Parent 05 / RW / Primary 4 / Average Performing)
  insert into public.learners (
    id, first_name, last_name, date_of_birth, gender, country_code,
    education_system_id, curriculum_id, education_level_id, grade_id,
    created_by_parent_user_id, registration_request_id, learner_code, avatar_preset, is_demo
  ) values (
    'd2000000-0000-0000-0000-000000000009', 'Mugisha', 'Habimana', '2014-10-10', 'male', 'RW',
    v_rw_sys, v_rw_cur, v_rw_lvl_pri, v_rw_p4,
    v_parent5_id, gen_random_uuid(), 'RW-LRN-0501', 'owl_scholar', true
  ) on conflict (id) do update set is_demo = true;

  insert into public.parent_learners (
    learner_id, parent_user_id, relationship_role, relationship_status, created_by_parent_user_id
  ) values (
    'd2000000-0000-0000-0000-000000000009', v_parent5_id, 'parent', 'active', v_parent5_id
  ) on conflict (learner_id, parent_user_id) do nothing;

  insert into public.learner_profiles (
    learner_id, parent_id, username, access_status, access_mode,
    credential_type, credential_hash, credential_salt
  ) values (
    'd2000000-0000-0000-0000-000000000009', v_parent5_id, 'mugisha_rw', 'active', 'parent_managed',
    'pin', v_learner_hash, v_learner_salt
  ) on conflict (learner_id) do update set
    username = excluded.username,
    credential_type = excluded.credential_type,
    credential_hash = excluded.credential_hash,
    credential_salt = excluded.credential_salt,
    access_status = excluded.access_status,
    access_mode = excluded.access_mode;

  -- Learner 10: RW-LRN-0502 (Parent 05 / RW / Senior 1 / Requiring Support)
  insert into public.learners (
    id, first_name, last_name, date_of_birth, gender, country_code,
    education_system_id, curriculum_id, education_level_id, grade_id,
    created_by_parent_user_id, registration_request_id, learner_code, avatar_preset, is_demo
  ) values (
    'd2000000-0000-0000-0000-000000000010', 'Keza', 'Habimana', '2011-03-30', 'female', 'RW',
    v_rw_sys, v_rw_cur, v_rw_lvl_sec, v_rw_s1,
    v_parent5_id, gen_random_uuid(), 'RW-LRN-0502', 'lion_reader', true
  ) on conflict (id) do update set is_demo = true;

  insert into public.parent_learners (
    learner_id, parent_user_id, relationship_role, relationship_status, created_by_parent_user_id
  ) values (
    'd2000000-0000-0000-0000-000000000010', v_parent5_id, 'parent', 'active', v_parent5_id
  ) on conflict (learner_id, parent_user_id) do nothing;

  insert into public.learner_profiles (
    learner_id, parent_id, username, access_status, access_mode,
    credential_type, credential_hash, credential_salt
  ) values (
    'd2000000-0000-0000-0000-000000000010', v_parent5_id, 'keza_rw', 'active', 'independent_device',
    'pin', v_learner_hash, v_learner_salt
  ) on conflict (learner_id) do update set
    username = excluded.username,
    credential_type = excluded.credential_type,
    credential_hash = excluded.credential_hash,
    credential_salt = excluded.credential_salt,
    access_status = excluded.access_status,
    access_mode = excluded.access_mode;

  insert into public.learner_devices (
    learner_id, device_identifier, device_name, device_type, is_active
  ) values (
    'd2000000-0000-0000-0000-000000000010', 'dev-keza-phone', 'Keza Phone', 'phone', true
  ) on conflict (learner_id, device_identifier) do nothing;

  -- ==========================================================================
  -- C. PROVISION SAMPLE LEARNING PROGRESS & MASTERY
  -- ==========================================================================

  -- Pick lessons for progress data
  select l.id, t.id, s.id into v_lesson_id, v_topic_id, v_subject_id
  from public.lessons l
  join public.topics t on t.id = l.topic_id
  join public.subjects s on s.id = t.subject_id
  limit 1;

  if v_lesson_id is not null then
    -- High performers (Amani, Neema, Kamau, Babirye)
    for v_sub_id in select id from public.learners where id in (
      'd2000000-0000-0000-0000-000000000001',
      'd2000000-0000-0000-0000-000000000003',
      'd2000000-0000-0000-0000-000000000006',
      'd2000000-0000-0000-0000-000000000008'
    ) loop
      insert into public.learner_progress (
        learner_id, lesson_id, status, reading_progress_percent, best_quiz_score_percent, attempts_count
      ) values (
        v_sub_id, v_lesson_id, 'completed', 100, 94, 2
      ) on conflict (learner_id, lesson_id) do nothing;

      insert into public.learner_topic_mastery (
        learner_id, topic_id, mastery_status, accuracy_rate, best_score_percent, quizzes_attempted
      ) values (
        v_sub_id, v_topic_id, 'mastered', 94.00, 96, 4
      ) on conflict (learner_id, topic_id) do update set
        mastery_status = 'mastered', accuracy_rate = 94.00, best_score_percent = 96;

      insert into public.learner_recommendations (
        learner_id, subject_id, topic_id, lesson_id, recommendation_type, title, reason, priority
      ) values (
        v_sub_id, v_subject_id, v_topic_id, v_lesson_id, 'advanced',
        'Advanced Mathematics Olympiad Challenge',
        'Consistently excelling in curriculum practice quizzes (>90%). Ready for advanced multi-step concepts.',
        1
      ) on conflict (learner_id, topic_id, recommendation_type) do nothing;
    end loop;

    -- Average performers (Baraka, Zawadi, Mugisha)
    for v_sub_id in select id from public.learners where id in (
      'd2000000-0000-0000-0000-000000000002',
      'd2000000-0000-0000-0000-000000000005',
      'd2000000-0000-0000-0000-000000000009'
    ) loop
      insert into public.learner_progress (
        learner_id, lesson_id, status, reading_progress_percent, best_quiz_score_percent, attempts_count
      ) values (
        v_sub_id, v_lesson_id, 'completed', 85, 72, 1
      ) on conflict (learner_id, lesson_id) do nothing;

      insert into public.learner_topic_mastery (
        learner_id, topic_id, mastery_status, accuracy_rate, best_score_percent, quizzes_attempted
      ) values (
        v_sub_id, v_topic_id, 'proficient', 72.00, 75, 2
      ) on conflict (learner_id, topic_id) do update set
        mastery_status = 'proficient', accuracy_rate = 72.00, best_score_percent = 75;

      insert into public.learner_recommendations (
        learner_id, subject_id, topic_id, lesson_id, recommendation_type, title, reason, priority
      ) values (
        v_sub_id, v_subject_id, v_topic_id, v_lesson_id, 'spaced_repetition',
        'Consolidate Operations Practice',
        'Moderate performance on first quiz attempt. Spaced review recommended to build speed.',
        2
      ) on conflict (learner_id, topic_id, recommendation_type) do nothing;
    end loop;

    -- Requiring Support (Juma, Kato, Keza)
    for v_sub_id in select id from public.learners where id in (
      'd2000000-0000-0000-0000-000000000004',
      'd2000000-0000-0000-0000-000000000007',
      'd2000000-0000-0000-0000-000000000010'
    ) loop
      insert into public.learner_progress (
        learner_id, lesson_id, status, reading_progress_percent, best_quiz_score_percent, attempts_count
      ) values (
        v_sub_id, v_lesson_id, 'in_progress', 60, 48, 2
      ) on conflict (learner_id, lesson_id) do nothing;

      insert into public.learner_topic_mastery (
        learner_id, topic_id, mastery_status, accuracy_rate, best_score_percent, quizzes_attempted
      ) values (
        v_sub_id, v_topic_id, 'in_progress', 48.00, 52, 2
      ) on conflict (learner_id, topic_id) do update set
        mastery_status = 'in_progress', accuracy_rate = 48.00, best_score_percent = 52;

      insert into public.learner_recommendations (
        learner_id, subject_id, topic_id, lesson_id, recommendation_type, title, reason, priority
      ) values (
        v_sub_id, v_subject_id, v_topic_id, v_lesson_id, 'remedial',
        'Foundational Concept Reinforcement',
        'Assessment results show identified gaps in core concepts. Step-by-step revision flashcards recommended.',
        1
      ) on conflict (learner_id, topic_id, recommendation_type) do nothing;
    end loop;
  end if;

  -- ==========================================================================
  -- D. PROVISION 6 DEMO ADMINISTRATOR ACCOUNTS
  -- ==========================================================================

  delete from public.admin_user_roles
  where admin_id in (v_admin_super_id, v_admin_tz_id, v_admin_ke_id, v_admin_content_id, v_admin_finance_id, v_admin_support_id);

  -- 1. Super Admin (Global)
  insert into auth.users (
    id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    phone_change, phone_change_token, email_change_token_current, reauthentication_token,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at
  ) values (
    v_admin_super_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
    'superadmin@demo.learntz.test', v_admin_password_hash, now(),
    '', '', '', '', '', '', '', '',
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    '{"full_name": "Demo Super Admin"}'::jsonb, now(), now()
  ) on conflict (id) do update set
    email = excluded.email,
    encrypted_password = excluded.encrypted_password,
    confirmation_token = '',
    recovery_token = '',
    email_change_token_new = '',
    email_change = '',
    phone_change = '',
    phone_change_token = '',
    email_change_token_current = '',
    reauthentication_token = '';

  insert into auth.identities (
    id, provider_id, user_id, identity_data, provider,
    last_sign_in_at, created_at, updated_at
  ) values (
    v_admin_super_id, v_admin_super_id::text, v_admin_super_id,
    jsonb_build_object(
      'sub', v_admin_super_id::text,
      'email', 'superadmin@demo.learntz.test',
      'email_verified', true,
      'phone_verified', false
    ),
    'email', now(), now(), now()
  ) on conflict (provider_id, provider) do update set
    identity_data = excluded.identity_data,
    updated_at = now();

  insert into public.profiles (id, full_name)
  values (v_admin_super_id, 'Demo Super Admin')
  on conflict (id) do update set full_name = excluded.full_name;

  insert into public.admin_profiles (id, auth_user_id, email, full_name, account_status, mfa_enrolled, is_demo)
  values (v_admin_super_id, v_admin_super_id, 'superadmin@demo.learntz.test', 'Demo Super Admin', 'ACTIVE', true, true)
  on conflict (id) do update set is_demo = true, account_status = 'ACTIVE', mfa_enrolled = true, auth_user_id = excluded.auth_user_id;

  insert into public.user_roles (user_id, role)
  values (v_admin_super_id, 'super_admin')
  on conflict (user_id, role, coalesce(country_code, '')) do nothing;

  insert into public.admin_user_roles (admin_id, role_id, country_code, approval_status)
  select v_admin_super_id, id, null, 'APPROVED'
  from public.admin_roles where role_name = 'SUPER_ADMIN'
  on conflict (admin_id, role_id, country_code) do update set approval_status = 'APPROVED';

  -- 2. Tanzania Country Admin (TZ Only)
  insert into auth.users (
    id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    phone_change, phone_change_token, email_change_token_current, reauthentication_token,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at
  ) values (
    v_admin_tz_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
    'admin.tz@demo.learntz.test', v_admin_password_hash, now(),
    '', '', '', '', '', '', '', '',
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    '{"full_name": "Demo Tanzania Admin"}'::jsonb, now(), now()
  ) on conflict (id) do update set
    email = excluded.email,
    encrypted_password = excluded.encrypted_password,
    confirmation_token = '',
    recovery_token = '',
    email_change_token_new = '',
    email_change = '',
    phone_change = '',
    phone_change_token = '',
    email_change_token_current = '',
    reauthentication_token = '';

  insert into auth.identities (
    id, provider_id, user_id, identity_data, provider,
    last_sign_in_at, created_at, updated_at
  ) values (
    v_admin_tz_id, v_admin_tz_id::text, v_admin_tz_id,
    jsonb_build_object(
      'sub', v_admin_tz_id::text,
      'email', 'admin.tz@demo.learntz.test',
      'email_verified', true,
      'phone_verified', false
    ),
    'email', now(), now(), now()
  ) on conflict (provider_id, provider) do update set
    identity_data = excluded.identity_data,
    updated_at = now();

  insert into public.profiles (id, full_name)
  values (v_admin_tz_id, 'Demo Tanzania Admin')
  on conflict (id) do update set full_name = excluded.full_name;

  insert into public.admin_profiles (id, auth_user_id, email, full_name, account_status, mfa_enrolled, is_demo)
  values (v_admin_tz_id, v_admin_tz_id, 'admin.tz@demo.learntz.test', 'Demo Tanzania Admin', 'ACTIVE', true, true)
  on conflict (id) do update set is_demo = true, account_status = 'ACTIVE', mfa_enrolled = true, auth_user_id = excluded.auth_user_id;

  insert into public.user_roles (user_id, role, country_code)
  values (v_admin_tz_id, 'country_admin', 'TZ')
  on conflict (user_id, role, coalesce(country_code, '')) do nothing;

  insert into public.admin_user_roles (admin_id, role_id, country_code, approval_status)
  select v_admin_tz_id, id, 'TZ', 'APPROVED'
  from public.admin_roles where role_name = 'COUNTRY_ADMIN'
  on conflict (admin_id, role_id, country_code) do update set approval_status = 'APPROVED';

  -- 3. Kenya Country Admin (KE Only)
  insert into auth.users (
    id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    phone_change, phone_change_token, email_change_token_current, reauthentication_token,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at
  ) values (
    v_admin_ke_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
    'admin.ke@demo.learntz.test', v_admin_password_hash, now(),
    '', '', '', '', '', '', '', '',
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    '{"full_name": "Demo Kenya Admin"}'::jsonb, now(), now()
  ) on conflict (id) do update set
    email = excluded.email,
    encrypted_password = excluded.encrypted_password,
    confirmation_token = '',
    recovery_token = '',
    email_change_token_new = '',
    email_change = '',
    phone_change = '',
    phone_change_token = '',
    email_change_token_current = '',
    reauthentication_token = '';

  insert into auth.identities (
    id, provider_id, user_id, identity_data, provider,
    last_sign_in_at, created_at, updated_at
  ) values (
    v_admin_ke_id, v_admin_ke_id::text, v_admin_ke_id,
    jsonb_build_object(
      'sub', v_admin_ke_id::text,
      'email', 'admin.ke@demo.learntz.test',
      'email_verified', true,
      'phone_verified', false
    ),
    'email', now(), now(), now()
  ) on conflict (provider_id, provider) do update set
    identity_data = excluded.identity_data,
    updated_at = now();

  insert into public.profiles (id, full_name)
  values (v_admin_ke_id, 'Demo Kenya Admin')
  on conflict (id) do update set full_name = excluded.full_name;

  insert into public.admin_profiles (id, auth_user_id, email, full_name, account_status, mfa_enrolled, is_demo)
  values (v_admin_ke_id, v_admin_ke_id, 'admin.ke@demo.learntz.test', 'Demo Kenya Admin', 'ACTIVE', true, true)
  on conflict (id) do update set is_demo = true, account_status = 'ACTIVE', mfa_enrolled = true, auth_user_id = excluded.auth_user_id;

  insert into public.user_roles (user_id, role, country_code)
  values (v_admin_ke_id, 'country_admin', 'KE')
  on conflict (user_id, role, coalesce(country_code, '')) do nothing;

  insert into public.admin_user_roles (admin_id, role_id, country_code, approval_status)
  select v_admin_ke_id, id, 'KE', 'APPROVED'
  from public.admin_roles where role_name = 'COUNTRY_ADMIN'
  on conflict (admin_id, role_id, country_code) do update set approval_status = 'APPROVED';

  -- 4. Content Admin (Global Curriculum & CMS)
  insert into auth.users (
    id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    phone_change, phone_change_token, email_change_token_current, reauthentication_token,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at
  ) values (
    v_admin_content_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
    'admin.content@demo.learntz.test', v_admin_password_hash, now(),
    '', '', '', '', '', '', '', '',
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    '{"full_name": "Demo Content Admin"}'::jsonb, now(), now()
  ) on conflict (id) do update set
    email = excluded.email,
    encrypted_password = excluded.encrypted_password,
    confirmation_token = '',
    recovery_token = '',
    email_change_token_new = '',
    email_change = '',
    phone_change = '',
    phone_change_token = '',
    email_change_token_current = '',
    reauthentication_token = '';

  insert into auth.identities (
    id, provider_id, user_id, identity_data, provider,
    last_sign_in_at, created_at, updated_at
  ) values (
    v_admin_content_id, v_admin_content_id::text, v_admin_content_id,
    jsonb_build_object(
      'sub', v_admin_content_id::text,
      'email', 'admin.content@demo.learntz.test',
      'email_verified', true,
      'phone_verified', false
    ),
    'email', now(), now(), now()
  ) on conflict (provider_id, provider) do update set
    identity_data = excluded.identity_data,
    updated_at = now();

  insert into public.profiles (id, full_name)
  values (v_admin_content_id, 'Demo Content Admin')
  on conflict (id) do update set full_name = excluded.full_name;

  insert into public.admin_profiles (id, auth_user_id, email, full_name, account_status, mfa_enrolled, is_demo)
  values (v_admin_content_id, v_admin_content_id, 'admin.content@demo.learntz.test', 'Demo Content Admin', 'ACTIVE', true, true)
  on conflict (id) do update set is_demo = true, account_status = 'ACTIVE', mfa_enrolled = true, auth_user_id = excluded.auth_user_id;

  insert into public.user_roles (user_id, role)
  values (v_admin_content_id, 'content_admin')
  on conflict (user_id, role, coalesce(country_code, '')) do nothing;

  insert into public.admin_user_roles (admin_id, role_id, country_code, approval_status)
  select v_admin_content_id, id, null, 'APPROVED'
  from public.admin_roles where role_name = 'CONTENT_ADMIN'
  on conflict (admin_id, role_id, country_code) do update set approval_status = 'APPROVED';

  -- 5. Finance Admin (Global Subscriptions & Payments)
  insert into auth.users (
    id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    phone_change, phone_change_token, email_change_token_current, reauthentication_token,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at
  ) values (
    v_admin_finance_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
    'admin.finance@demo.learntz.test', v_admin_password_hash, now(),
    '', '', '', '', '', '', '', '',
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    '{"full_name": "Demo Finance Admin"}'::jsonb, now(), now()
  ) on conflict (id) do update set
    email = excluded.email,
    encrypted_password = excluded.encrypted_password,
    confirmation_token = '',
    recovery_token = '',
    email_change_token_new = '',
    email_change = '',
    phone_change = '',
    phone_change_token = '',
    email_change_token_current = '',
    reauthentication_token = '';

  insert into auth.identities (
    id, provider_id, user_id, identity_data, provider,
    last_sign_in_at, created_at, updated_at
  ) values (
    v_admin_finance_id, v_admin_finance_id::text, v_admin_finance_id,
    jsonb_build_object(
      'sub', v_admin_finance_id::text,
      'email', 'admin.finance@demo.learntz.test',
      'email_verified', true,
      'phone_verified', false
    ),
    'email', now(), now(), now()
  ) on conflict (provider_id, provider) do update set
    identity_data = excluded.identity_data,
    updated_at = now();

  insert into public.profiles (id, full_name)
  values (v_admin_finance_id, 'Demo Finance Admin')
  on conflict (id) do update set full_name = excluded.full_name;

  insert into public.admin_profiles (id, auth_user_id, email, full_name, account_status, mfa_enrolled, is_demo)
  values (v_admin_finance_id, v_admin_finance_id, 'admin.finance@demo.learntz.test', 'Demo Finance Admin', 'ACTIVE', true, true)
  on conflict (id) do update set is_demo = true, account_status = 'ACTIVE', mfa_enrolled = true, auth_user_id = excluded.auth_user_id;

  insert into public.user_roles (user_id, role)
  values (v_admin_finance_id, 'finance_admin')
  on conflict (user_id, role, coalesce(country_code, '')) do nothing;

  insert into public.admin_user_roles (admin_id, role_id, country_code, approval_status)
  select v_admin_finance_id, id, null, 'APPROVED'
  from public.admin_roles where role_name = 'FINANCE_ADMIN'
  on conflict (admin_id, role_id, country_code) do update set approval_status = 'APPROVED';

  -- 6. Support Admin (Customer Support)
  insert into auth.users (
    id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    phone_change, phone_change_token, email_change_token_current, reauthentication_token,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at
  ) values (
    v_admin_support_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
    'admin.support@demo.learntz.test', v_admin_password_hash, now(),
    '', '', '', '', '', '', '', '',
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    '{"full_name": "Demo Support Admin"}'::jsonb, now(), now()
  ) on conflict (id) do update set
    email = excluded.email,
    encrypted_password = excluded.encrypted_password,
    confirmation_token = '',
    recovery_token = '',
    email_change_token_new = '',
    email_change = '',
    phone_change = '',
    phone_change_token = '',
    email_change_token_current = '',
    reauthentication_token = '';

  insert into auth.identities (
    id, provider_id, user_id, identity_data, provider,
    last_sign_in_at, created_at, updated_at
  ) values (
    v_admin_support_id, v_admin_support_id::text, v_admin_support_id,
    jsonb_build_object(
      'sub', v_admin_support_id::text,
      'email', 'admin.support@demo.learntz.test',
      'email_verified', true,
      'phone_verified', false
    ),
    'email', now(), now(), now()
  ) on conflict (provider_id, provider) do update set
    identity_data = excluded.identity_data,
    updated_at = now();

  insert into public.profiles (id, full_name)
  values (v_admin_support_id, 'Demo Support Admin')
  on conflict (id) do update set full_name = excluded.full_name;

  insert into public.admin_profiles (id, auth_user_id, email, full_name, account_status, mfa_enrolled, is_demo)
  values (v_admin_support_id, v_admin_support_id, 'admin.support@demo.learntz.test', 'Demo Support Admin', 'ACTIVE', true, true)
  on conflict (id) do update set is_demo = true, account_status = 'ACTIVE', mfa_enrolled = true, auth_user_id = excluded.auth_user_id;

  insert into public.user_roles (user_id, role)
  values (v_admin_support_id, 'support_admin')
  on conflict (user_id, role, coalesce(country_code, '')) do nothing;

  insert into public.admin_user_roles (admin_id, role_id, country_code, approval_status)
  select v_admin_support_id, id, null, 'APPROVED'
  from public.admin_roles where role_name = 'SUPPORT_ADMIN'
  on conflict (admin_id, role_id, country_code) do update set approval_status = 'APPROVED';

  -- Log provisioning in admin_audit_logs
  insert into public.admin_audit_logs (
    admin_id, action, resource_type, resource_id, metadata
  ) values (
    v_admin_super_id, 'DEMO_SEED_PROVISIONED', 'SYSTEM_DEMO_ACCOUNTS', 'ALL',
    jsonb_build_object('parents', 5, 'learners', 10, 'admins', 6, 'status', 'COMPLETED')
  );

  -- ==========================================================================
  -- E. PROVISION CONTROLLED TEST SUBSCRIPTIONS & TRANSACTIONS
  -- ==========================================================================

  -- 1. Parent 01 (TZ): Active Monthly Premium
  if v_plan_tz_m is not null then
    insert into public.parent_subscriptions (
      id, parent_user_id, plan_id, status, current_period_start, current_period_end, auto_renew, is_demo
    ) values (
      'e1000000-0000-0000-0000-000000000001', v_parent1_id, v_plan_tz_m, 'active',
      now() - interval '15 days', now() + interval '15 days', true, true
    ) on conflict (id, parent_user_id) do update set status = 'active', is_demo = true;

    insert into public.payment_transactions (
      subscription_id, parent_user_id, provider, reference, amount, currency, status, is_demo
    ) values (
      'e1000000-0000-0000-0000-000000000001', v_parent1_id, 'mpesa_tz', 'DEMO-TX-TZ-001', 1500000, 'TZS', 'succeeded', true
    ) on conflict (reference) do nothing;
  end if;

  -- 2. Parent 02 (TZ): Active Annual Family Pass
  if v_plan_tz_a is not null then
    insert into public.parent_subscriptions (
      id, parent_user_id, plan_id, status, current_period_start, current_period_end, auto_renew, is_demo
    ) values (
      'e1000000-0000-0000-0000-000000000002', v_parent2_id, v_plan_tz_a, 'active',
      now() - interval '30 days', now() + interval '335 days', true, true
    ) on conflict (id, parent_user_id) do update set status = 'active', is_demo = true;

    insert into public.payment_transactions (
      subscription_id, parent_user_id, provider, reference, amount, currency, status, is_demo
    ) values (
      'e1000000-0000-0000-0000-000000000002', v_parent2_id, 'mpesa_tz', 'DEMO-TX-TZ-002', 15000000, 'TZS', 'succeeded', true
    ) on conflict (reference) do nothing;
  end if;

  -- 3. Parent 03 (KE): Pending Payment
  if v_plan_ke_m is not null then
    insert into public.parent_subscriptions (
      id, parent_user_id, plan_id, status, current_period_start, current_period_end, auto_renew, is_demo
    ) values (
      'e1000000-0000-0000-0000-000000000003', v_parent3_id, v_plan_ke_m, 'pending_payment',
      now(), now() + interval '3 days', false, true
    ) on conflict (id, parent_user_id) do update set status = 'pending_payment', is_demo = true;

    insert into public.payment_transactions (
      subscription_id, parent_user_id, provider, reference, amount, currency, status, is_demo
    ) values (
      'e1000000-0000-0000-0000-000000000003', v_parent3_id, 'mpesa_ke', 'DEMO-TX-KE-003', 100000, 'KES', 'pending', true
    ) on conflict (reference) do nothing;
  end if;

  -- 4. Parent 04 (UG): Expired Subscription
  if v_plan_ug_m is not null then
    insert into public.parent_subscriptions (
      id, parent_user_id, plan_id, status, current_period_start, current_period_end, auto_renew, is_demo
    ) values (
      'e1000000-0000-0000-0000-000000000004', v_parent4_id, v_plan_ug_m, 'expired',
      now() - interval '60 days', now() - interval '30 days', false, true
    ) on conflict (id, parent_user_id) do update set status = 'expired', is_demo = true;
  end if;

  -- 5. Parent 05 (RW): Cancelled Subscription
  if v_plan_rw_m is not null then
    insert into public.parent_subscriptions (
      id, parent_user_id, plan_id, status, current_period_start, current_period_end, auto_renew, is_demo
    ) values (
      'e1000000-0000-0000-0000-000000000005', v_parent5_id, v_plan_rw_m, 'cancelled',
      now() - interval '20 days', now() + interval '10 days', false, true
    ) on conflict (id, parent_user_id) do update set status = 'cancelled', is_demo = true;
  end if;

  return jsonb_build_object(
    'status', 'success',
    'environment', coalesce(current_setting('app.environment', true), 'development'),
    'parents_provisioned', 5,
    'learners_provisioned', 10,
    'admins_provisioned', 6,
    'subscriptions_configured', 5,
    'timestamp', now()
  );
end;
$$;

grant execute on function public.provision_demo_data(boolean) to authenticated;

-- ============================================================================
-- 7. Stored Procedure: Get Demo Accounts Overview (for Super Admin UI)
-- ============================================================================

create or replace function public.get_demo_accounts_overview()
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_parents jsonb;
  v_learners jsonb;
  v_admins jsonb;
begin
  -- Parents list
  select coalesce(jsonb_agg(parent_entry order by parent_entry->>'email'), '[]'::jsonb)
  into v_parents
  from (
    select distinct on (pa.user_id) jsonb_build_object(
      'id', pa.user_id,
      'email', u.email,
      'full_name', p.full_name,
      'country_code', pa.country_code,
      'phone_number', pa.phone_number,
      'status', pa.onboarding_status,
      'learner_count', (select count(*) from public.parent_learners where parent_user_id = pa.user_id),
      'is_demo', pa.is_demo
    ) as parent_entry
    from public.parent_accounts pa
    join auth.users u on u.id = pa.user_id
    join public.profiles p on p.id = pa.user_id
    where pa.is_demo = true
    order by pa.user_id
  ) s;

  -- Learners list
  select coalesce(jsonb_agg(learner_entry order by learner_entry->>'learner_code'), '[]'::jsonb)
  into v_learners
  from (
    select distinct on (l.id) jsonb_build_object(
      'id', l.id,
      'learner_code', l.learner_code,
      'username', lp.username,
      'full_name', l.first_name || ' ' || l.last_name,
      'country_code', l.country_code,
      'grade_name', coalesce(g.name, 'N/A'),
      'avatar_preset', l.avatar_preset,
      'access_mode', lp.access_mode,
      'access_status', lp.access_status,
      'parent_name', p.full_name,
      'is_demo', l.is_demo
    ) as learner_entry
    from public.learners l
    left join public.learner_profiles lp on lp.learner_id = l.id
    left join public.parent_learners pl on pl.learner_id = l.id
    left join public.profiles p on p.id = pl.parent_user_id
    left join public.education_grades g on g.id = l.grade_id
    where l.is_demo = true
    order by l.id
  ) s;

  -- Admins list
  select coalesce(jsonb_agg(admin_entry order by admin_entry->>'email'), '[]'::jsonb)
  into v_admins
  from (
    select distinct on (ap.id) jsonb_build_object(
      'id', ap.id,
      'email', ap.email,
      'full_name', ap.full_name,
      'role_name', r.role_name,
      'country_code', aur.country_code,
      'account_status', ap.account_status,
      'is_demo', ap.is_demo
    ) as admin_entry
    from public.admin_profiles ap
    left join public.admin_user_roles aur on aur.admin_id = ap.id
    left join public.admin_roles r on r.id = aur.role_id
    where ap.is_demo = true
    order by ap.id
  ) s;

  return jsonb_build_object(
    'parents', v_parents,
    'learners', v_learners,
    'admins', v_admins,
    'summary', jsonb_build_object(
      'total_parents', jsonb_array_length(v_parents),
      'total_learners', jsonb_array_length(v_learners),
      'total_admins', jsonb_array_length(v_admins)
    )
  );
end;
$$;

grant execute on function public.get_demo_accounts_overview() to authenticated;

-- ============================================================================
-- 8. Update KPI Calculation: Exclude Demo Records from Production Metrics
-- ============================================================================

create or replace function public.get_super_admin_control_centre_stats()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  total_learners integer := 0;
  total_parents integer := 0;
  total_subscriptions integer := 0;
  total_exams integer := 0;
  total_admins integer := 0;
  active_countries integer := 0;
  open_tickets integer := 0;
  country_breakdown jsonb;
  recent_audits jsonb;
begin
  if not public.is_current_super_admin() then
    raise exception 'Super administrator authorization required to access Control Centre metrics' using errcode = '42501';
  end if;

  -- Overall counts (strictly excluding demo records)
  select count(*) into total_learners from public.learners where not is_demo;
  select count(*) into total_parents from public.parent_accounts where not is_demo;
  select count(*) into active_countries from public.countries where is_enabled = true;
  select count(*) into total_admins from public.admin_profiles where account_status = 'ACTIVE' and not is_demo;

  if exists (select 1 from information_schema.tables where table_schema = 'public' and table_name = 'parent_subscriptions') then
    select count(*) into total_subscriptions from public.parent_subscriptions where status = 'active' and not is_demo;
  end if;

  if exists (select 1 from information_schema.tables where table_schema = 'public' and table_name = 'national_exams') then
    select count(*) into total_exams from public.national_exams;
  end if;

  if exists (select 1 from information_schema.tables where table_schema = 'public' and table_name = 'support_tickets') then
    select count(*) into open_tickets from public.support_tickets where status in ('open', 'pending');
  end if;

  -- Country performance breakdown
  select jsonb_agg(
    jsonb_build_object(
      'country_code', c.country_code,
      'country_name', c.display_name,
      'currency_code', c.currency_code,
      'is_enabled', c.is_enabled,
      'learner_count', coalesce(l_cnt.cnt, 0),
      'parent_count', coalesce(p_cnt.cnt, 0)
    ) order by c.country_code
  ) into country_breakdown
  from public.countries c
  left join (
    select country_code, count(*) as cnt from public.learners where not is_demo group by country_code
  ) l_cnt on l_cnt.country_code = c.country_code
  left join (
    select country_code, count(*) as cnt from public.parent_accounts where not is_demo group by country_code
  ) p_cnt on p_cnt.country_code = c.country_code;

  -- Recent Audit logs
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', a.id,
        'action_type', a.action_type,
        'target_entity', a.target_entity,
        'target_id', a.target_id,
        'created_at', a.created_at,
        'admin_name', coalesce(p.full_name, 'System')
      ) order by a.created_at desc
    ),
    '[]'::jsonb
  ) into recent_audits
  from (
    select * from public.admin_audit_logs order by created_at desc limit 10
  ) a
  left join public.admin_profiles p on p.id = a.admin_id;

  return jsonb_build_object(
    'total_learners', total_learners,
    'total_parents', total_parents,
    'total_subscriptions', total_subscriptions,
    'total_exams', total_exams,
    'total_admins', total_admins,
    'active_countries', active_countries,
    'open_tickets', open_tickets,
    'system_health', 'OPERATIONAL',
    'country_breakdown', coalesce(country_breakdown, '[]'::jsonb),
    'recent_audits', coalesce(recent_audits, '[]'::jsonb)
  );
end;
$$;

commit;
