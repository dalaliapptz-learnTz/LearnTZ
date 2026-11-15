-- LearnTZ pgTAP Security and Schema Tests
-- Test Suite: Learner Independent Access & Device Management
-- File: supabase/tests/learner_independent_access.test.sql

begin;
select plan(24);

-- 1. Table existence tests
select has_table('public', 'learner_profiles', 'Table public.learner_profiles should exist');
select has_table('public', 'learner_devices', 'Table public.learner_devices should exist');
select has_table('public', 'learner_activation_tokens', 'Table public.learner_activation_tokens should exist');
select has_table('public', 'learner_sessions', 'Table public.learner_sessions should exist');

-- 2. Column existence tests on learner_profiles
select has_column('public', 'learner_profiles', 'id', 'learner_profiles.id exists');
select has_column('public', 'learner_profiles', 'learner_id', 'learner_profiles.learner_id exists');
select has_column('public', 'learner_profiles', 'parent_id', 'learner_profiles.parent_id exists');
select has_column('public', 'learner_profiles', 'username', 'learner_profiles.username exists');
select has_column('public', 'learner_profiles', 'access_mode', 'learner_profiles.access_mode exists');
select has_column('public', 'learner_profiles', 'access_status', 'learner_profiles.access_status exists');
select has_column('public', 'learner_profiles', 'credential_type', 'learner_profiles.credential_type exists');
select has_column('public', 'learner_profiles', 'credential_hash', 'learner_profiles.credential_hash exists');
select has_column('public', 'learner_profiles', 'locked_until', 'learner_profiles.locked_until exists');

-- 3. Column existence tests on learner_devices
select has_column('public', 'learner_devices', 'device_identifier', 'learner_devices.device_identifier exists');
select has_column('public', 'learner_devices', 'device_name', 'learner_devices.device_name exists');
select has_column('public', 'learner_devices', 'device_type', 'learner_devices.device_type exists');
select has_column('public', 'learner_devices', 'is_active', 'learner_devices.is_active exists');

-- 4. RPC Functions existence tests
select has_function('public', 'hash_learner_secret', ARRAY['text', 'text'], 'hash_learner_secret exists');
select has_function('public', 'set_learner_access_mode', ARRAY['uuid', 'text', 'text', 'text', 'text'], 'set_learner_access_mode exists');
select has_function('public', 'generate_learner_activation_token', ARRAY['uuid'], 'generate_learner_activation_token exists');
select has_function('public', 'link_learner_device', ARRAY['text', 'text', 'text', 'text'], 'link_learner_device exists');
select has_function('public', 'authenticate_learner_credential', ARRAY['text', 'text', 'text', 'text', 'text'], 'authenticate_learner_credential exists');
select has_function('public', 'revoke_learner_device', ARRAY['uuid', 'uuid'], 'revoke_learner_device exists');
select has_function('public', 'get_learner_device_management', ARRAY['uuid'], 'get_learner_device_management exists');

select * from finish();
rollback;
