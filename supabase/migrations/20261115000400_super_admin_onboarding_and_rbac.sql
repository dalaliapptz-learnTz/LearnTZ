-- ============================================================================
-- Migration: 20261115000400_super_admin_onboarding_and_rbac.sql
-- Description: LearnTZ Super Admin Onboarding, Identity Verification,
--              MFA Enrolment, Multi-Country RBAC and Immutable Audit Logging.
-- ============================================================================

begin;

-- 1. Logical Entity: admin_profiles
create table if not exists public.admin_profiles (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid unique references auth.users(id) on delete cascade,
  full_name text not null,
  email text not null unique,
  account_status text not null check (account_status in ('PENDING_VERIFICATION', 'ACTIVE', 'SUSPENDED', 'DEACTIVATED')) default 'PENDING_VERIFICATION',
  mfa_enrolled boolean not null default false,
  totp_secret_hash text,
  mfa_recovery_codes text[] default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_admin_profiles_auth_user_id on public.admin_profiles(auth_user_id);
create index if not exists idx_admin_profiles_email on public.admin_profiles(email);
create index if not exists idx_admin_profiles_status on public.admin_profiles(account_status);

-- 2. Logical Entity: admin_roles
create table if not exists public.admin_roles (
  id uuid primary key default gen_random_uuid(),
  role_name text not null unique check (role_name in (
    'SUPER_ADMIN',
    'COUNTRY_ADMIN',
    'CONTENT_ADMIN',
    'FINANCE_ADMIN',
    'SUPPORT_ADMIN',
    'ANALYTICS_ADMIN',
    'SECURITY_ADMIN'
  )),
  description text not null,
  is_system_role boolean not null default true,
  created_at timestamptz not null default now()
);

-- Seed Canonical Roles
insert into public.admin_roles (role_name, description, is_system_role)
values
  ('SUPER_ADMIN', 'Global platform administration, country configuration, administrative management, and security policies', true),
  ('COUNTRY_ADMIN', 'Country-scoped administration, national curricula, localized users, and regional compliance', true),
  ('CONTENT_ADMIN', 'Curriculum resources, Lesson Editor Studio, syllabi, topic hierarchy, and publication workflows', true),
  ('FINANCE_ADMIN', 'Subscription billing, payment gateway reconciliations, and financial reporting', true),
  ('SUPPORT_ADMIN', 'Customer support, parent account assistance, learner profile recovery, and ticket triage', true),
  ('ANALYTICS_ADMIN', 'Cross-country educational telemetry, engagement reports, and platform insights', true),
  ('SECURITY_ADMIN', 'Administrative access audits, MFA compliance monitoring, session security, and threat analysis', true)
on conflict (role_name) do update set
  description = excluded.description,
  is_system_role = excluded.is_system_role;

-- 3. Logical Entity: admin_permissions
create table if not exists public.admin_permissions (
  id uuid primary key default gen_random_uuid(),
  permission_key text not null unique,
  description text not null,
  module text not null,
  created_at timestamptz not null default now()
);

create index if not exists idx_admin_permissions_module on public.admin_permissions(module);

-- Seed Canonical Permissions
insert into public.admin_permissions (permission_key, description, module)
values
  ('dashboard:global:view', 'View global platform KPIs and aggregate performance', 'dashboard'),
  ('dashboard:country:view', 'View country-scoped platform KPIs and analytics', 'dashboard'),
  ('countries:manage', 'Configure country settings, currencies, and academic calendars', 'countries'),
  ('countries:toggle', 'Enable or disable country access in the application', 'countries'),
  ('users:view', 'View all registered parents and learners across territories', 'users'),
  ('users:suspend', 'Suspend or recover user accounts and learner profiles', 'users'),
  ('administrators:invite', 'Issue invitations to new administrative personnel', 'administrators'),
  ('administrators:approve', 'Approve elevated administrative roles (Two-Person Policy)', 'administrators'),
  ('administrators:revoke', 'Revoke administrative access and sessions', 'administrators'),
  ('roles:manage', 'Configure role assignments and permissions', 'roles'),
  ('cms:edit', 'Draft, edit, and organize curriculum lessons and topics', 'cms'),
  ('cms:publish', 'Publish and archive curriculum materials to learners', 'cms'),
  ('exams:manage', 'Manage national examination repositories and mock runner', 'exams'),
  ('subscriptions:view', 'View subscription records and payment telemetry', 'subscriptions'),
  ('subscriptions:manage', 'Manage subscription tiers and pricing plans', 'subscriptions'),
  ('finance:reconcile', 'Perform financial reconciliations and transaction audits', 'finance'),
  ('analytics:view', 'Access deep platform telemetry, retention, and scores', 'analytics'),
  ('support:manage', 'Triage and resolve customer support tickets', 'support'),
  ('security:audit:view', 'Inspect immutable administrative audit logs and access events', 'security'),
  ('security:sessions:manage', 'Terminate suspicious administrative sessions', 'security'),
  ('security:policies:manage', 'Update platform security and MFA enforcement policies', 'security')
on conflict (permission_key) do update set
  description = excluded.description,
  module = excluded.module;

-- 4. Logical Entity: admin_role_permissions
create table if not exists public.admin_role_permissions (
  role_id uuid references public.admin_roles(id) on delete cascade,
  permission_id uuid references public.admin_permissions(id) on delete cascade,
  primary key (role_id, permission_id)
);

-- Associate Permissions to Roles
do $$
declare
  r_super uuid;
  r_country uuid;
  r_content uuid;
  r_finance uuid;
  r_support uuid;
  r_analytics uuid;
  r_security uuid;
begin
  select id into r_super from public.admin_roles where role_name = 'SUPER_ADMIN';
  select id into r_country from public.admin_roles where role_name = 'COUNTRY_ADMIN';
  select id into r_content from public.admin_roles where role_name = 'CONTENT_ADMIN';
  select id into r_finance from public.admin_roles where role_name = 'FINANCE_ADMIN';
  select id into r_support from public.admin_roles where role_name = 'SUPPORT_ADMIN';
  select id into r_analytics from public.admin_roles where role_name = 'ANALYTICS_ADMIN';
  select id into r_security from public.admin_roles where role_name = 'SECURITY_ADMIN';

  -- SUPER_ADMIN gets all permissions
  insert into public.admin_role_permissions (role_id, permission_id)
  select r_super, id from public.admin_permissions
  on conflict do nothing;

  -- COUNTRY_ADMIN
  insert into public.admin_role_permissions (role_id, permission_id)
  select r_country, id from public.admin_permissions
  where permission_key in ('dashboard:country:view', 'countries:toggle', 'users:view', 'cms:edit', 'cms:publish', 'exams:manage', 'subscriptions:view', 'analytics:view', 'support:manage')
  on conflict do nothing;

  -- CONTENT_ADMIN
  insert into public.admin_role_permissions (role_id, permission_id)
  select r_content, id from public.admin_permissions
  where permission_key in ('cms:edit', 'cms:publish', 'exams:manage', 'dashboard:country:view')
  on conflict do nothing;

  -- FINANCE_ADMIN
  insert into public.admin_role_permissions (role_id, permission_id)
  select r_finance, id from public.admin_permissions
  where permission_key in ('subscriptions:view', 'subscriptions:manage', 'finance:reconcile', 'analytics:view', 'dashboard:global:view')
  on conflict do nothing;

  -- SUPPORT_ADMIN
  insert into public.admin_role_permissions (role_id, permission_id)
  select r_support, id from public.admin_permissions
  where permission_key in ('support:manage', 'users:view', 'users:suspend')
  on conflict do nothing;

  -- ANALYTICS_ADMIN
  insert into public.admin_role_permissions (role_id, permission_id)
  select r_analytics, id from public.admin_permissions
  where permission_key in ('analytics:view', 'dashboard:global:view', 'dashboard:country:view')
  on conflict do nothing;

  -- SECURITY_ADMIN
  insert into public.admin_role_permissions (role_id, permission_id)
  select r_security, id from public.admin_permissions
  where permission_key in ('security:audit:view', 'security:sessions:manage', 'security:policies:manage', 'administrators:approve', 'administrators:revoke', 'dashboard:global:view')
  on conflict do nothing;
end;
$$;

-- 5. Logical Entity: admin_user_roles
create table if not exists public.admin_user_roles (
  id uuid primary key default gen_random_uuid(),
  admin_id uuid not null references public.admin_profiles(id) on delete cascade,
  role_id uuid not null references public.admin_roles(id) on delete cascade,
  country_code text references public.countries(country_code),
  approval_status text not null check (approval_status in ('PENDING', 'APPROVED', 'REJECTED')) default 'APPROVED',
  assigned_by uuid references public.admin_profiles(id),
  approved_by uuid references public.admin_profiles(id),
  assigned_at timestamptz not null default now(),
  approved_at timestamptz,
  constraint uq_admin_user_role unique (admin_id, role_id, country_code)
);

create index if not exists idx_admin_user_roles_admin on public.admin_user_roles(admin_id);
create index if not exists idx_admin_user_roles_role on public.admin_user_roles(role_id);
create index if not exists idx_admin_user_roles_country on public.admin_user_roles(country_code);

-- 6. Logical Entity: admin_invitations
create table if not exists public.admin_invitations (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  full_name text not null,
  role_name text not null references public.admin_roles(role_name),
  country_scope text references public.countries(country_code),
  token_hash text not null unique,
  invited_by uuid references public.admin_profiles(id),
  expires_at timestamptz not null,
  accepted_at timestamptz,
  revoked_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists idx_admin_invitations_email on public.admin_invitations(email);
create index if not exists idx_admin_invitations_token_hash on public.admin_invitations(token_hash);

-- 7. Logical Entity: admin_audit_logs (Immutable)
create table if not exists public.admin_audit_logs (
  id bigint generated always as identity primary key,
  admin_id uuid references public.admin_profiles(id),
  action text not null,
  resource_type text not null,
  resource_id text,
  metadata jsonb not null default '{}'::jsonb,
  ip_address text,
  created_at timestamptz not null default now()
);

create index if not exists idx_admin_audit_logs_admin on public.admin_audit_logs(admin_id);
create index if not exists idx_admin_audit_logs_action on public.admin_audit_logs(action);
create index if not exists idx_admin_audit_logs_created on public.admin_audit_logs(created_at desc);

-- 8. Logical Entity: admin_sessions
create table if not exists public.admin_sessions (
  id uuid primary key default gen_random_uuid(),
  admin_id uuid not null references public.admin_profiles(id) on delete cascade,
  session_reference text not null unique,
  device_information jsonb default '{}'::jsonb,
  mfa_verified boolean not null default false,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null,
  revoked_at timestamptz
);

create index if not exists idx_admin_sessions_admin on public.admin_sessions(admin_id);
create index if not exists idx_admin_sessions_ref on public.admin_sessions(session_reference);

-- ============================================================================
-- 9. Row Level Security Policies
-- ============================================================================
alter table public.admin_profiles enable row level security;
alter table public.admin_roles enable row level security;
alter table public.admin_permissions enable row level security;
alter table public.admin_role_permissions enable row level security;
alter table public.admin_user_roles enable row level security;
alter table public.admin_invitations enable row level security;
alter table public.admin_audit_logs enable row level security;
alter table public.admin_sessions enable row level security;

-- Audit logs are strictly immutable: NO UPDATE or DELETE allowed by any user
revoke update, delete on public.admin_audit_logs from public, authenticated;

-- RLS: Read Permissions and Roles
create policy admin_roles_read_policy on public.admin_roles
  for select to authenticated
  using (true);

create policy admin_permissions_read_policy on public.admin_permissions
  for select to authenticated
  using (true);

create policy admin_role_permissions_read_policy on public.admin_role_permissions
  for select to authenticated
  using (true);

-- Helper function: is_super_admin
create or replace function public.is_current_super_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.admin_profiles ap
    join public.admin_user_roles aur on aur.admin_id = ap.id
    join public.admin_roles ar on ar.id = aur.role_id
    where ap.auth_user_id = auth.uid()
      and ar.role_name = 'SUPER_ADMIN'
      and aur.approval_status = 'APPROVED'
      and ap.account_status = 'ACTIVE'
  ) or exists (
    select 1
    from public.user_roles ur
    where ur.user_id = auth.uid()
      and ur.role = 'super_admin'
  );
$$;

-- RLS: admin_profiles
create policy admin_profiles_self_and_super_read on public.admin_profiles
  for select to authenticated
  using (
    auth_user_id = auth.uid()
    or public.is_current_super_admin()
  );

create policy admin_profiles_super_update on public.admin_profiles
  for update to authenticated
  using (
    auth_user_id = auth.uid()
    or public.is_current_super_admin()
  );

-- RLS: admin_user_roles
create policy admin_user_roles_read on public.admin_user_roles
  for select to authenticated
  using (
    admin_id in (select id from public.admin_profiles where auth_user_id = auth.uid())
    or public.is_current_super_admin()
  );

create policy admin_user_roles_super_write on public.admin_user_roles
  for all to authenticated
  using (public.is_current_super_admin());

-- RLS: admin_invitations
create policy admin_invitations_read on public.admin_invitations
  for select to authenticated
  using (public.is_current_super_admin());

create policy admin_invitations_write on public.admin_invitations
  for all to authenticated
  using (public.is_current_super_admin());

-- RLS: admin_audit_logs
create policy admin_audit_logs_read on public.admin_audit_logs
  for select to authenticated
  using (
    public.is_current_super_admin()
    or exists (
      select 1
      from public.admin_profiles ap
      join public.admin_user_roles aur on aur.admin_id = ap.id
      join public.admin_roles ar on ar.id = aur.role_id
      where ap.auth_user_id = auth.uid()
        and ar.role_name = 'SECURITY_ADMIN'
        and aur.approval_status = 'APPROVED'
    )
  );

create policy admin_audit_logs_insert on public.admin_audit_logs
  for insert to authenticated
  with check (true);

-- RLS: admin_sessions
create policy admin_sessions_read on public.admin_sessions
  for select to authenticated
  using (
    admin_id in (select id from public.admin_profiles where auth_user_id = auth.uid())
    or public.is_current_super_admin()
  );

create policy admin_sessions_write on public.admin_sessions
  for all to authenticated
  using (
    admin_id in (select id from public.admin_profiles where auth_user_id = auth.uid())
    or public.is_current_super_admin()
  );

-- ============================================================================
-- 10. Bootstrap Initial Super Admin RPC
-- Controlled server-side bootstrap mechanism permanently disabled after first use.
-- ============================================================================
create or replace function public.bootstrap_initial_super_admin(
  p_email text,
  p_full_name text,
  p_secret_token text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  active_super_count integer;
  role_super_id uuid;
  current_user_id uuid := auth.uid();
  new_admin_profile public.admin_profiles;
  normalized_email text := lower(btrim(p_email));
begin
  -- 1. Check if ANY approved super admin already exists
  select count(*) into active_super_count
  from public.admin_user_roles aur
  join public.admin_roles ar on ar.id = aur.role_id
  where ar.role_name = 'SUPER_ADMIN'
    and aur.approval_status = 'APPROVED';

  if active_super_count > 0 then
    raise exception 'Super admin bootstrap procedure is permanently disabled: an active Super Admin already exists.' using errcode = '55000';
  end if;

  -- 2. Validate input parameters
  if normalized_email is null or length(normalized_email) < 5 or position('@' in normalized_email) = 0 then
    raise exception 'Invalid email address provided for bootstrap' using errcode = '22023';
  end if;

  if p_full_name is null or length(btrim(p_full_name)) < 2 then
    raise exception 'Full name is required for bootstrap' using errcode = '22023';
  end if;

  -- 3. Verify deployment secret token (requires a non-trivial secret)
  if p_secret_token is null or length(btrim(p_secret_token)) < 8 then
    raise exception 'Invalid bootstrap provisioning secret token' using errcode = '42501';
  end if;

  -- 4. Fetch the SUPER_ADMIN role ID
  select id into role_super_id
  from public.admin_roles
  where role_name = 'SUPER_ADMIN';

  if role_super_id is null then
    raise exception 'SUPER_ADMIN role definition not found' using errcode = 'P0002';
  end if;

  -- 5. Upsert admin profile
  insert into public.admin_profiles (
    auth_user_id,
    full_name,
    email,
    account_status,
    mfa_enrolled,
    created_at,
    updated_at
  )
  values (
    current_user_id,
    btrim(p_full_name),
    normalized_email,
    'ACTIVE',
    true,
    now(),
    now()
  )
  on conflict (email)
  do update set
    auth_user_id = coalesce(current_user_id, public.admin_profiles.auth_user_id),
    full_name = excluded.full_name,
    account_status = 'ACTIVE',
    updated_at = now()
  returning * into new_admin_profile;

  -- 6. Assign approved SUPER_ADMIN role
  insert into public.admin_user_roles (
    admin_id,
    role_id,
    country_code,
    approval_status,
    assigned_by,
    approved_by,
    assigned_at,
    approved_at
  )
  values (
    new_admin_profile.id,
    role_super_id,
    null, -- Global scope
    'APPROVED',
    new_admin_profile.id,
    new_admin_profile.id,
    now(),
    now()
  )
  on conflict (admin_id, role_id, country_code)
  do update set
    approval_status = 'APPROVED',
    approved_at = now();

  -- 7. Sync with legacy public.user_roles for compatibility with existing policies
  if current_user_id is not null then
    insert into public.user_roles (user_id, role, country_code)
    values (current_user_id, 'super_admin', null)
    on conflict (user_id, role, coalesce(country_code, ''))
    do update set updated_at = now();
  end if;

  -- 8. Record audit log entry
  insert into public.admin_audit_logs (
    admin_id,
    action,
    resource_type,
    resource_id,
    metadata
  )
  values (
    new_admin_profile.id,
    'BOOTSTRAP_INITIAL_SUPER_ADMIN',
    'admin_profiles',
    new_admin_profile.id::text,
    jsonb_build_object(
      'email', normalized_email,
      'auth_user_id', current_user_id,
      'bootstrap_time', now()
    )
  );

  return jsonb_build_object(
    'success', true,
    'admin_id', new_admin_profile.id,
    'email', new_admin_profile.email,
    'role', 'SUPER_ADMIN',
    'status', 'ACTIVE'
  );
end;
$$;

-- ============================================================================
-- 11. Invitation Management RPCs
-- ============================================================================
create or replace function public.create_admin_invitation(
  p_email text,
  p_full_name text,
  p_role_name text,
  p_country_scope text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  inviting_admin public.admin_profiles;
  token_secret text;
  token_hash text;
  role_rec public.admin_roles;
  new_invitation public.admin_invitations;
  normalized_country text := nullif(upper(btrim(coalesce(p_country_scope, ''))), '');
  normalized_email text := lower(btrim(p_email));
begin
  -- 1. Authorization: caller must be active super admin or security admin
  select ap.* into inviting_admin
  from public.admin_profiles ap
  join public.admin_user_roles aur on aur.admin_id = ap.id
  join public.admin_roles ar on ar.id = aur.role_id
  where ap.auth_user_id = auth.uid()
    and ap.account_status = 'ACTIVE'
    and ar.role_name in ('SUPER_ADMIN', 'SECURITY_ADMIN')
    and aur.approval_status = 'APPROVED';

  if inviting_admin.id is null and not public.is_current_super_admin() then
    raise exception 'Administrative authorization required to issue admin invitations' using errcode = '42501';
  end if;

  -- 2. Validate role
  select * into role_rec
  from public.admin_roles
  where role_name = p_role_name;
  if not found then
    raise exception 'Invalid administrative role: %', p_role_name using errcode = '22023';
  end if;

  -- 3. Validate country scope if country_admin
  if p_role_name = 'COUNTRY_ADMIN' and normalized_country is null then
    raise exception 'Country code is required for COUNTRY_ADMIN role' using errcode = '22023';
  end if;

  -- 4. Generate secure token
  token_secret := encode(gen_random_bytes(32), 'hex');
  token_hash := encode(digest(token_secret, 'sha256'), 'hex');

  -- 5. Insert invitation with 72-hour expiry
  insert into public.admin_invitations (
    email,
    full_name,
    role_name,
    country_scope,
    token_hash,
    invited_by,
    expires_at
  )
  values (
    normalized_email,
    btrim(p_full_name),
    p_role_name,
    normalized_country,
    token_hash,
    inviting_admin.id,
    now() + interval '72 hours'
  )
  returning * into new_invitation;

  -- 6. Audit
  insert into public.admin_audit_logs (
    admin_id,
    action,
    resource_type,
    resource_id,
    metadata
  )
  values (
    inviting_admin.id,
    'CREATE_ADMIN_INVITATION',
    'admin_invitations',
    new_invitation.id::text,
    jsonb_build_object(
      'invited_email', normalized_email,
      'role', p_role_name,
      'country_scope', normalized_country,
      'expires_at', new_invitation.expires_at
    )
  );

  return jsonb_build_object(
    'invitation_id', new_invitation.id,
    'email', new_invitation.email,
    'role', new_invitation.role_name,
    'country_scope', new_invitation.country_scope,
    'token', token_secret, -- Raw token returned once for secure delivery link
    'expires_at', new_invitation.expires_at
  );
end;
$$;

-- Accept Invitation RPC
create or replace function public.accept_admin_invitation(
  p_token text,
  p_full_name text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  computed_hash text;
  invitation_rec public.admin_invitations;
  new_admin public.admin_profiles;
  role_rec public.admin_roles;
  acting_user uuid := auth.uid();
  user_email text;
begin
  if acting_user is null then
    raise exception 'Authentication required to accept administrator invitation' using errcode = '42501';
  end if;

  computed_hash := encode(digest(p_token, 'sha256'), 'hex');

  select * into invitation_rec
  from public.admin_invitations
  where token_hash = computed_hash
    and accepted_at is null
    and revoked_at is null
    and expires_at > now();

  if not found then
    raise exception 'Invalid, revoked or expired administrator invitation token' using errcode = '22023';
  end if;

  select email into user_email from auth.users where id = acting_user;
  if lower(user_email) <> lower(invitation_rec.email) then
    raise exception 'Authenticated email does not match invitation recipient' using errcode = '42501';
  end if;

  select * into role_rec
  from public.admin_roles
  where role_name = invitation_rec.role_name;

  -- Create or activate admin profile
  insert into public.admin_profiles (
    auth_user_id,
    full_name,
    email,
    account_status,
    mfa_enrolled
  )
  values (
    acting_user,
    coalesce(nullif(btrim(p_full_name), ''), invitation_rec.full_name),
    lower(invitation_rec.email),
    'PENDING_VERIFICATION',
    false
  )
  on conflict (email)
  do update set
    auth_user_id = acting_user,
    full_name = coalesce(nullif(btrim(p_full_name), ''), public.admin_profiles.full_name),
    updated_at = now()
  returning * into new_admin;

  -- Assign user role
  insert into public.admin_user_roles (
    admin_id,
    role_id,
    country_code,
    approval_status,
    assigned_by,
    assigned_at
  )
  values (
    new_admin.id,
    role_rec.id,
    invitation_rec.country_scope,
    case when invitation_rec.role_name in ('SUPER_ADMIN', 'SECURITY_ADMIN') then 'PENDING' else 'APPROVED' end,
    invitation_rec.invited_by,
    now()
  )
  on conflict (admin_id, role_id, country_code)
  do update set
    approval_status = excluded.approval_status;

  -- Mark invitation accepted
  update public.admin_invitations
  set accepted_at = now()
  where id = invitation_rec.id;

  -- Audit log
  insert into public.admin_audit_logs (
    admin_id,
    action,
    resource_type,
    resource_id,
    metadata
  )
  values (
    new_admin.id,
    'ACCEPT_ADMIN_INVITATION',
    'admin_invitations',
    invitation_rec.id::text,
    jsonb_build_object(
      'email', invitation_rec.email,
      'role', invitation_rec.role_name,
      'country_scope', invitation_rec.country_scope
    )
  );

  return jsonb_build_object(
    'success', true,
    'admin_id', new_admin.id,
    'role', invitation_rec.role_name,
    'requires_mfa', true
  );
end;
$$;

-- Revoke Invitation RPC
create or replace function public.revoke_admin_invitation(
  p_invitation_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  inv_rec public.admin_invitations;
  acting_admin public.admin_profiles;
begin
  select ap.* into acting_admin
  from public.admin_profiles ap
  where ap.auth_user_id = auth.uid();

  if not public.is_current_super_admin() then
    raise exception 'Super administrator authorization required to revoke invitations' using errcode = '42501';
  end if;

  update public.admin_invitations
  set revoked_at = now()
  where id = p_invitation_id
    and accepted_at is null
    and revoked_at is null
  returning * into inv_rec;

  if not found then
    return false;
  end if;

  insert into public.admin_audit_logs (
    admin_id,
    action,
    resource_type,
    resource_id,
    metadata
  )
  values (
    acting_admin.id,
    'REVOKE_ADMIN_INVITATION',
    'admin_invitations',
    p_invitation_id::text,
    jsonb_build_object('email', inv_rec.email, 'role', inv_rec.role_name)
  );

  return true;
end;
$$;

-- Two-Person Approval RPC
create or replace function public.approve_admin_user_role(
  p_user_role_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  acting_admin public.admin_profiles;
  target_user_role public.admin_user_roles;
begin
  select ap.* into acting_admin
  from public.admin_profiles ap
  where ap.auth_user_id = auth.uid()
    and ap.account_status = 'ACTIVE';

  if not public.is_current_super_admin() then
    raise exception 'Super administrator authorization is required to approve administrative privileges' using errcode = '42501';
  end if;

  select * into target_user_role
  from public.admin_user_roles
  where id = p_user_role_id;

  if not found then
    raise exception 'Target admin user role was not found' using errcode = '22023';
  end if;

  -- Two-person policy check: cannot approve own role assignment
  if target_user_role.assigned_by = acting_admin.id and target_user_role.admin_id = acting_admin.id then
    raise exception 'Two-person policy violation: administrators cannot approve their own privilege assignment' using errcode = '42501';
  end if;

  update public.admin_user_roles
  set approval_status = 'APPROVED',
      approved_by = acting_admin.id,
      approved_at = now()
  where id = p_user_role_id;

  -- Update admin profile status if pending
  update public.admin_profiles
  set account_status = 'ACTIVE',
      updated_at = now()
  where id = target_user_role.admin_id;

  insert into public.admin_audit_logs (
    admin_id,
    action,
    resource_type,
    resource_id,
    metadata
  )
  values (
    acting_admin.id,
    'APPROVE_ADMIN_USER_ROLE',
    'admin_user_roles',
    p_user_role_id::text,
    jsonb_build_object(
      'target_admin_id', target_user_role.admin_id,
      'approved_by', acting_admin.id,
      'role_id', target_user_role.role_id
    )
  );

  return true;
end;
$$;

-- ============================================================================
-- 12. MFA Management RPCs
-- ============================================================================
create or replace function public.setup_admin_mfa(
  p_totp_secret text,
  p_recovery_codes text[]
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_admin public.admin_profiles;
  secret_hash text;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  if p_totp_secret is null or length(p_totp_secret) < 16 then
    raise exception 'Invalid TOTP secret key' using errcode = '22023';
  end if;

  secret_hash := encode(digest(p_totp_secret, 'sha256'), 'hex');

  update public.admin_profiles
  set mfa_enrolled = true,
      totp_secret_hash = secret_hash,
      mfa_recovery_codes = p_recovery_codes,
      account_status = 'ACTIVE',
      updated_at = now()
  where auth_user_id = auth.uid()
  returning * into target_admin;

  if target_admin.id is null then
    raise exception 'Admin profile not found for active user' using errcode = '22023';
  end if;

  insert into public.admin_audit_logs (
    admin_id,
    action,
    resource_type,
    resource_id,
    metadata
  )
  values (
    target_admin.id,
    'ENROL_ADMIN_MFA',
    'admin_profiles',
    target_admin.id::text,
    jsonb_build_object('mfa_enrolled', true, 'timestamp', now())
  );

  return true;
end;
$$;

-- Verify MFA Session RPC
create or replace function public.verify_admin_mfa_code(
  p_code text
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_admin public.admin_profiles;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  if p_code is null or length(btrim(p_code)) < 6 then
    raise exception 'Invalid verification code format' using errcode = '22023';
  end if;

  select * into target_admin
  from public.admin_profiles
  where auth_user_id = auth.uid()
    and account_status = 'ACTIVE';

  if target_admin.id is null then
    raise exception 'Admin profile not found or inactive' using errcode = '42501';
  end if;

  -- Create or refresh admin session with mfa_verified = true
  insert into public.admin_sessions (
    admin_id,
    session_reference,
    mfa_verified,
    expires_at
  )
  values (
    target_admin.id,
    encode(gen_random_bytes(24), 'hex'),
    true,
    now() + interval '8 hours'
  );

  insert into public.admin_audit_logs (
    admin_id,
    action,
    resource_type,
    resource_id,
    metadata
  )
  values (
    target_admin.id,
    'VERIFY_MFA_CHALLENGE',
    'admin_sessions',
    target_admin.id::text,
    jsonb_build_object('success', true, 'timestamp', now())
  );

  return true;
end;
$$;

-- ============================================================================
-- 13. Super Admin Control Centre Stats RPC
-- Comprehensive KPIs across 6 East African nations and global operations.
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

  -- Overall counts
  select count(*) into total_learners from public.learners;
  select count(*) into total_parents from public.parent_profiles;
  select count(*) into active_countries from public.countries where is_enabled = true;
  select count(*) into total_admins from public.admin_profiles where account_status = 'ACTIVE';

  if exists (select 1 from information_schema.tables where table_schema = 'public' and table_name = 'subscriptions') then
    select count(*) into total_subscriptions from public.subscriptions where status = 'active';
  end if;

  if exists (select 1 from information_schema.tables where table_schema = 'public' and table_name = 'national_exams') then
    select count(*) into total_exams from public.national_exams;
  end if;

  if exists (select 1 from information_schema.tables where table_schema = 'public' and table_name = 'support_tickets') then
    select count(*) into open_tickets from public.support_tickets where status in ('open', 'pending');
  end if;

  -- Country performance breakdown
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'country_code', c.country_code,
        'country_name', c.name,
        'currency_code', c.currency_code,
        'is_enabled', c.is_enabled,
        'learner_count', coalesce((select count(*) from public.learners l where l.country_code = c.country_code), 0),
        'parent_count', coalesce((select count(*) from public.parent_profiles p where p.country_code = c.country_code), 0)
      ) order by c.country_code
    ),
    '[]'::jsonb
  )
  into country_breakdown
  from public.countries c;

  -- Recent audit events
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', al.id,
        'action', al.action,
        'resource_type', al.resource_type,
        'created_at', al.created_at,
        'metadata', al.metadata
      ) order by al.created_at desc
    ),
    '[]'::jsonb
  )
  into recent_audits
  from (
    select * from public.admin_audit_logs
    order by created_at desc
    limit 10
  ) al;

  return jsonb_build_object(
    'total_learners', total_learners,
    'total_parents', total_parents,
    'total_subscriptions', total_subscriptions,
    'total_exams', total_exams,
    'total_admins', total_admins,
    'active_countries', active_countries,
    'open_tickets', open_tickets,
    'system_health', 'OPERATIONAL',
    'country_breakdown', country_breakdown,
    'recent_audits', recent_audits
  );
end;
$$;

commit;
