-- ============================================================================
-- LearnTZ pgTAP Test Suite: Demo Accounts & Sandbox Provisioning Engine
-- File: supabase/tests/demo_accounts_provisioning.test.sql
-- ============================================================================

begin;
select plan(22);

-- 1. Function existence tests
select has_function('public', 'is_demo_environment', ARRAY[]::text[], 'is_demo_environment RPC exists');
select has_function('public', 'provision_demo_data', ARRAY['boolean'], 'provision_demo_data RPC exists');
select has_function('public', 'reset_demo_data', ARRAY[]::text[], 'reset_demo_data RPC exists');
select has_function('public', 'get_demo_accounts_overview', ARRAY[]::text[], 'get_demo_accounts_overview RPC exists');

-- 2. Verify is_demo columns exist across critical platform tables
select has_column('public', 'parent_accounts', 'is_demo', 'parent_accounts.is_demo exists');
select has_column('public', 'learners', 'is_demo', 'learners.is_demo exists');
select has_column('public', 'admin_profiles', 'is_demo', 'admin_profiles.is_demo exists');
select has_column('public', 'parent_subscriptions', 'is_demo', 'parent_subscriptions.is_demo exists');
select has_column('public', 'payment_transactions', 'is_demo', 'payment_transactions.is_demo exists');

-- 3. Environment check (must be true in local/staging test runner)
select ok(public.is_demo_environment(), 'Local testing stack is recognized as demo/sandbox environment');

-- 4. Execute provisioning idempotently
select is(
  (public.provision_demo_data(false) ->> 'status')::text,
  'success',
  'provision_demo_data completes successfully with status: success'
);

-- 5. Validate Demo Overview counts
select is(
  ((public.get_demo_accounts_overview() -> 'summary') ->> 'total_parents')::int,
  5,
  'Exactly 5 demo parent accounts are provisioned'
);

select is(
  ((public.get_demo_accounts_overview() -> 'summary') ->> 'total_learners')::int,
  10,
  'Exactly 10 demo learner accounts are provisioned'
);

select is(
  ((public.get_demo_accounts_overview() -> 'summary') ->> 'total_admins')::int,
  6,
  'Exactly 6 demo administrator accounts are provisioned'
);

-- 6. Validate Country Coverage
select results_eq(
  $$ select distinct country_code from public.parent_accounts where is_demo = true order by country_code $$,
  $$ values ('KE'), ('RW'), ('TZ'), ('UG') $$,
  'Demo parents cover Tanzania, Kenya, Uganda, and Rwanda'
);

-- 7. Validate Demo Parent 02 has multiple learners (child switching test scenario)
select results_eq(
  $$ 
    select count(*)::int 
    from public.parent_learners 
    where parent_user_id = 'd1000000-0000-0000-0000-000000000002' 
  $$,
  $$ values (3) $$,
  'Demo Parent 02 has exactly 3 linked learners for multi-child switching'
);

-- 8. Validate Learner Independent PIN Authentication (Amani Bakari Std 4)
select is(
  ((public.authenticate_learner_credential('TZ-LRN-0101', '1234', 'TEST-DEV-001', 'Test Device', 'phone') -> 'learner') ->> 'id')::text,
  'd2000000-0000-0000-0000-000000000001',
  'Demo learner TZ-LRN-0101 authenticates successfully with PIN 1234 returning learner ID'
);

select ok(
  (public.authenticate_learner_credential('TZ-LRN-0101', '1234', 'TEST-DEV-001', 'Test Device', 'phone') ->> 'session_token') is not null,
  'Demo learner TZ-LRN-0101 session token is generated'
);

-- 9. Validate invalid PIN throws an error
select throws_ok(
  $$ select public.authenticate_learner_credential('TZ-LRN-0101', '9999', 'TEST-DEV-001', 'Test Device', 'phone') $$,
  '42501',
  'Invalid Learner ID or PIN/Password',
  'Invalid PIN 9999 is rejected with 42501 exception'
);

-- 10. Validate Demo Admin Profiles and Canonical Roles
select results_eq(
  $$
    select r.role_name
    from public.admin_user_roles ur
    join public.admin_roles r on r.id = ur.role_id
    join public.admin_profiles ap on ap.id = ur.admin_id
    where ap.auth_user_id = 'd3000000-0000-0000-0000-000000000001'
  $$,
  $$ values ('SUPER_ADMIN') $$,
  'Demo Admin 01 has SUPER_ADMIN role'
);

-- 11. Validate Reset Demo Data RPC
select is(
  (public.reset_demo_data() ->> 'success')::boolean,
  true,
  'reset_demo_data executes successfully with success: true'
);

-- 12. Verify demo profiles persist after reset
select is(
  (select count(*)::int from public.learners where is_demo = true),
  10,
  'All 10 learners persist after reset_demo_data'
);

select * from finish();
rollback;
