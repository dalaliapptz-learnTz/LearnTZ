-- ============================================================================
-- Test: super_admin_security.test.sql
-- Verify Super Admin bootstrap, roles, permissions, invitations and audit logging
-- ============================================================================

begin;
select plan(9);

-- 1. Verify tables exist
select has_table('public', 'admin_profiles', 'admin_profiles table exists');
select has_table('public', 'admin_roles', 'admin_roles table exists');
select has_table('public', 'admin_permissions', 'admin_permissions table exists');
select has_table('public', 'admin_user_roles', 'admin_user_roles table exists');
select has_table('public', 'admin_invitations', 'admin_invitations table exists');
select has_table('public', 'admin_audit_logs', 'admin_audit_logs table exists');

-- 2. Verify Canonical Roles are seeded
select results_eq(
  $$ select count(*)::int from public.admin_roles where role_name in ('SUPER_ADMIN', 'COUNTRY_ADMIN', 'CONTENT_ADMIN', 'FINANCE_ADMIN', 'SUPPORT_ADMIN', 'ANALYTICS_ADMIN', 'SECURITY_ADMIN') $$,
  $$ values (7) $$,
  'All 7 Canonical Roles are populated in admin_roles'
);

-- 3. Verify RPC functions exist
select has_function('public', 'bootstrap_initial_super_admin', ARRAY['text', 'text', 'text'], 'bootstrap_initial_super_admin RPC exists');
select has_function('public', 'create_admin_invitation', ARRAY['text', 'text', 'text', 'text'], 'create_admin_invitation RPC exists');

rollback;
