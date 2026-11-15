begin;
select plan(7);

-- Test 1: Onboarding events table exists
select has_table('public', 'onboarding_events', 'onboarding_events table should exist');

-- Test 2: RLS enabled on onboarding_events
select table_privs_are(
  'public',
  'onboarding_events',
  'authenticated',
  array['SELECT', 'INSERT'],
  'authenticated should have select and insert on onboarding_events'
);

-- Test 3: Check check_phone_registered function exists
select has_function(
  'public',
  'check_phone_registered',
  array['text'],
  'check_phone_registered function should exist'
);

-- Test 4: Check record_onboarding_event function exists
select has_function(
  'public',
  'record_onboarding_event',
  array['text', 'jsonb'],
  'record_onboarding_event function should exist'
);

-- Test 5: Check update_parent_onboarding_status function exists
select has_function(
  'public',
  'update_parent_onboarding_status',
  array['text', 'text'],
  'update_parent_onboarding_status function should exist'
);

-- Test 6: Check complete_parent_onboarding function exists
select has_function(
  'public',
  'complete_parent_onboarding',
  array['jsonb'],
  'complete_parent_onboarding function should exist'
);

-- Test 7: parent_profiles view exists
select has_view('public', 'parent_profiles', 'parent_profiles view should exist');

select * from finish();
rollback;
