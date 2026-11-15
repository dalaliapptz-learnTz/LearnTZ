-- LearnTZ Child Onboarding & Independent Device Access Migration
-- Migration: 20261115000200_learner_independent_access_and_devices.sql

begin;

-- ============================================================================
-- 1. Create table public.learner_profiles
-- ============================================================================

create table if not exists public.learner_profiles (
  id uuid primary key default gen_random_uuid(),
  learner_id uuid not null unique references public.learners (id) on delete cascade,
  parent_id uuid not null references public.parent_accounts (user_id) on delete cascade,
  username text unique check (username is null or char_length(btrim(username)) between 3 and 40),
  access_status text not null default 'active'
    check (access_status in ('active', 'pending_setup', 'suspended')),
  access_mode text not null default 'parent_managed'
    check (access_mode in ('parent_managed', 'independent_device', 'setup_later')),
  credential_type text
    check (credential_type is null or credential_type in ('pin', 'password')),
  credential_hash text,
  credential_salt text,
  failed_login_attempts integer not null default 0
    check (failed_login_attempts >= 0),
  locked_until timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists learner_profiles_parent_idx
  on public.learner_profiles (parent_id);

create index if not exists learner_profiles_username_idx
  on public.learner_profiles (lower(username))
  where username is not null;

create index if not exists learner_profiles_status_idx
  on public.learner_profiles (access_status);

-- ============================================================================
-- 2. Create table public.learner_devices
-- ============================================================================

create table if not exists public.learner_devices (
  id uuid primary key default gen_random_uuid(),
  learner_id uuid not null references public.learners (id) on delete cascade,
  device_identifier text not null check (char_length(btrim(device_identifier)) >= 1),
  device_name text not null check (char_length(btrim(device_name)) >= 1),
  device_type text not null
    check (device_type in ('phone', 'tablet', 'desktop', 'web')),
  is_active boolean not null default true,
  last_active_at timestamptz not null default now(),
  last_sync_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  constraint learner_devices_identifier_unique unique (learner_id, device_identifier)
);

create index if not exists learner_devices_learner_active_idx
  on public.learner_devices (learner_id, is_active, last_active_at desc);

-- ============================================================================
-- 3. Create table public.learner_activation_tokens
-- ============================================================================

create table if not exists public.learner_activation_tokens (
  id uuid primary key default gen_random_uuid(),
  learner_id uuid not null references public.learners (id) on delete cascade,
  token_code text not null check (char_length(btrim(token_code)) >= 4),
  token_hash text not null,
  created_by_parent_id uuid not null references public.parent_accounts (user_id) on delete cascade,
  expires_at timestamptz not null,
  used_at timestamptz,
  attempts_count integer not null default 0 check (attempts_count >= 0),
  created_at timestamptz not null default now()
);

create index if not exists learner_activation_tokens_code_idx
  on public.learner_activation_tokens (token_code)
  where used_at is null;

create index if not exists learner_activation_tokens_learner_idx
  on public.learner_activation_tokens (learner_id, expires_at desc);

-- ============================================================================
-- 4. Create table public.learner_sessions
-- ============================================================================

create table if not exists public.learner_sessions (
  id uuid primary key default gen_random_uuid(),
  learner_id uuid not null references public.learners (id) on delete cascade,
  device_id uuid references public.learner_devices (id) on delete set null,
  session_token_hash text not null unique,
  session_status text not null default 'active'
    check (session_status in ('active', 'revoked', 'expired')),
  expires_at timestamptz not null,
  revoked_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists learner_sessions_token_idx
  on public.learner_sessions (session_token_hash)
  where session_status = 'active';

create index if not exists learner_sessions_learner_status_idx
  on public.learner_sessions (learner_id, session_status);

-- ============================================================================
-- 5. Auto-provisioning trigger for learner_profiles
-- ============================================================================

create or replace function public.provision_learner_profile()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_default_user text;
begin
  v_default_user := lower(regexp_replace(new.first_name, '[^a-zA-Z0-9]', '', 'g'))
    || '-' || lower(substr(replace(gen_random_uuid()::text, '-', ''), 1, 4));

  insert into public.learner_profiles (
    learner_id,
    parent_id,
    username,
    access_status,
    access_mode
  ) values (
    new.id,
    new.created_by_parent_user_id,
    v_default_user,
    'active',
    'parent_managed'
  )
  on conflict (learner_id) do nothing;

  return new;
end;
$$;

drop trigger if exists trg_learners_provision_profile on public.learners;
create trigger trg_learners_provision_profile
  after insert on public.learners
  for each row execute function public.provision_learner_profile();

-- Backfill existing learners
insert into public.learner_profiles (
  learner_id,
  parent_id,
  username,
  access_status,
  access_mode
)
select
  l.id,
  l.created_by_parent_user_id,
  lower(regexp_replace(l.first_name, '[^a-zA-Z0-9]', '', 'g'))
    || '-' || lower(substr(replace(l.id::text, '-', ''), 1, 4)),
  'active',
  'parent_managed'
from public.learners l
where not exists (
  select 1 from public.learner_profiles p where p.learner_id = l.id
);

-- ============================================================================
-- 6. Helper: Secure Hash Function (Postgres 14+ native SHA-256)
-- ============================================================================

create or replace function public.hash_learner_secret(
  p_salt text,
  p_secret text
)
returns text
language plpgsql
immutable
security definer
set search_path = ''
as $$
begin
  return encode(sha256(convert_to(coalesce(p_salt, '') || coalesce(p_secret, ''), 'UTF8')), 'hex');
end;
$$;

grant execute on function public.hash_learner_secret(text, text) to anon, authenticated;

-- ============================================================================
-- 7. Parent RPC: Set Learner Access Mode & Credentials
-- ============================================================================

create or replace function public.set_learner_access_mode(
  p_learner_id uuid,
  p_access_mode text,
  p_username text default null,
  p_credential_type text default null,
  p_secret text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_learner public.learners;
  v_salt text;
  v_hash text;
  v_cleaned_username text;
  v_result jsonb;
begin
  if v_user_id is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;

  if not public.is_authorized_learner_parent(p_learner_id) then
    raise exception 'You do not have authorization to manage this learner' using errcode = '42501';
  end if;

  select * into v_learner from public.learners where id = p_learner_id;
  if not found then
    raise exception 'Learner not found' using errcode = 'P0002';
  end if;

  if p_access_mode not in ('parent_managed', 'independent_device', 'setup_later') then
    raise exception 'Invalid access mode: %', p_access_mode using errcode = '22023';
  end if;

  if p_username is not null and btrim(p_username) <> '' then
    v_cleaned_username := lower(btrim(p_username));
    if char_length(v_cleaned_username) < 3 then
      raise exception 'Username must be at least 3 characters' using errcode = '22023';
    end if;
  end if;

  if p_secret is not null and btrim(p_secret) <> '' then
    if p_credential_type not in ('pin', 'password') then
      raise exception 'Credential type must be pin or password' using errcode = '22023';
    end if;

    if p_credential_type = 'pin' then
      if p_secret !~ '^[0-9]{4,6}$' then
        raise exception 'PIN must be between 4 and 6 digits' using errcode = '22023';
      end if;
      -- Never allow DOB as PIN
      if to_char(v_learner.date_of_birth, 'YYYY') = p_secret
         or to_char(v_learner.date_of_birth, 'MMDD') = p_secret
         or to_char(v_learner.date_of_birth, 'DDMM') = p_secret then
        raise exception 'PIN cannot be the child birth date or year' using errcode = '22023';
      end if;
    elsif p_credential_type = 'password' then
      if char_length(p_secret) < 6 then
        raise exception 'Password must be at least 6 characters' using errcode = '22023';
      end if;
    end if;

    v_salt := substr(md5(gen_random_uuid()::text || now()::text), 1, 16);
    v_hash := public.hash_learner_secret(v_salt, p_secret);
  end if;

  update public.learner_profiles
  set
    access_mode = p_access_mode,
    username = coalesce(v_cleaned_username, username),
    credential_type = coalesce(p_credential_type, credential_type),
    credential_hash = coalesce(v_hash, credential_hash),
    credential_salt = coalesce(v_salt, credential_salt),
    access_status = 'active',
    failed_login_attempts = 0,
    locked_until = null,
    updated_at = now()
  where learner_id = p_learner_id;

  select jsonb_build_object(
    'learner_id', p_learner_id,
    'learner_code', v_learner.learner_code,
    'access_mode', p_access_mode,
    'username', coalesce(v_cleaned_username, (select username from public.learner_profiles where learner_id = p_learner_id)),
    'credential_type', p_credential_type,
    'status', 'active'
  ) into v_result;

  return v_result;
end;
$$;

grant execute on function public.set_learner_access_mode(uuid, text, text, text, text) to authenticated;

-- ============================================================================
-- 8. Parent RPC: Generate Single-Use Device Activation Code
-- ============================================================================

create or replace function public.generate_learner_activation_token(
  p_learner_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_learner public.learners;
  v_code text;
  v_hash text;
  v_expires timestamptz;
  v_token_id uuid;
begin
  if v_user_id is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;

  if not public.is_authorized_learner_parent(p_learner_id) then
    raise exception 'You do not have authorization to generate tokens for this learner' using errcode = '42501';
  end if;

  select * into v_learner from public.learners where id = p_learner_id;
  if not found then
    raise exception 'Learner not found' using errcode = 'P0002';
  end if;

  -- Invalidate any existing unused tokens for this learner
  update public.learner_activation_tokens
  set used_at = now()
  where learner_id = p_learner_id and used_at is null;

  -- Generate 6-character uppercase alphanumeric code (e.g. 'LTZ-4927' format or 6 chars)
  v_code := upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 6));
  v_hash := public.hash_learner_secret('token_salt', v_code);
  v_expires := now() + interval '15 minutes';

  insert into public.learner_activation_tokens (
    learner_id,
    token_code,
    token_hash,
    created_by_parent_id,
    expires_at
  ) values (
    p_learner_id,
    v_code,
    v_hash,
    v_user_id,
    v_expires
  )
  returning id into v_token_id;

  return jsonb_build_object(
    'token_id', v_token_id,
    'token_code', v_code,
    'learner_id', p_learner_id,
    'learner_code', v_learner.learner_code,
    'learner_name', v_learner.first_name || ' ' || v_learner.last_name,
    'expires_at', v_expires,
    'expires_in_seconds', 900,
    'qr_payload', jsonb_build_object(
      'action', 'link_device',
      'code', v_code,
      'learner_code', v_learner.learner_code,
      'v', 1
    )::text
  );
end;
$$;

grant execute on function public.generate_learner_activation_token(uuid) to authenticated;

-- ============================================================================
-- 9. Child / Learner Device Linking RPC (via Activation Code)
-- ============================================================================

create or replace function public.link_learner_device(
  p_token_code text,
  p_device_identifier text,
  p_device_name text,
  p_device_type text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_token public.learner_activation_tokens;
  v_learner public.learners;
  v_profile public.learner_profiles;
  v_clean_code text;
  v_device_id uuid;
  v_session_token text;
  v_session_hash text;
  v_session_expires timestamptz;
  v_clean_type text;
begin
  v_clean_code := upper(btrim(coalesce(p_token_code, '')));
  if v_clean_code = '' then
    raise exception 'Activation code is required' using errcode = '22023';
  end if;

  select * into v_token
  from public.learner_activation_tokens
  where token_code = v_clean_code
    and used_at is null
  order by created_at desc
  limit 1;

  if not found then
    raise exception 'Invalid or already used activation code' using errcode = '42501';
  end if;

  if v_token.expires_at < now() then
    update public.learner_activation_tokens
    set used_at = now()
    where id = v_token.id;
    raise exception 'Activation code has expired. Please request a new code from parent' using errcode = '42501';
  end if;

  -- Mark token as used immediately (single-use)
  update public.learner_activation_tokens
  set used_at = now()
  where id = v_token.id;

  select * into v_learner from public.learners where id = v_token.learner_id;
  select * into v_profile from public.learner_profiles where learner_id = v_token.learner_id;

  if v_profile.access_status = 'suspended' then
    raise exception 'Learner access is currently suspended. Please ask your parent' using errcode = '42501';
  end if;

  v_clean_type := lower(btrim(coalesce(p_device_type, 'phone')));
  if v_clean_type not in ('phone', 'tablet', 'desktop', 'web') then
    v_clean_type := 'phone';
  end if;

  -- Register or update device
  insert into public.learner_devices (
    learner_id,
    device_identifier,
    device_name,
    device_type,
    is_active,
    last_active_at,
    last_sync_at
  ) values (
    v_learner.id,
    btrim(p_device_identifier),
    btrim(p_device_name),
    v_clean_type,
    true,
    now(),
    now()
  )
  on conflict (learner_id, device_identifier) do update
    set
      device_name = excluded.device_name,
      device_type = excluded.device_type,
      is_active = true,
      last_active_at = now()
  returning id into v_device_id;

  -- Create persistent session (30 days)
  v_session_token := 'ltz_sess_' || replace(gen_random_uuid()::text, '-', '') || replace(gen_random_uuid()::text, '-', '');
  v_session_hash := public.hash_learner_secret('session_salt', v_session_token);
  v_session_expires := now() + interval '30 days';

  insert into public.learner_sessions (
    learner_id,
    device_id,
    session_token_hash,
    session_status,
    expires_at
  ) values (
    v_learner.id,
    v_device_id,
    v_session_hash,
    'active',
    v_session_expires
  );

  -- Ensure profile access_mode reflects independent device
  update public.learner_profiles
  set access_mode = 'independent_device', updated_at = now()
  where learner_id = v_learner.id;

  return jsonb_build_object(
    'session_token', v_session_token,
    'session_expires_at', v_session_expires,
    'device_id', v_device_id,
    'learner', jsonb_build_object(
      'id', v_learner.id,
      'first_name', v_learner.first_name,
      'last_name', v_learner.last_name,
      'full_name', v_learner.first_name || ' ' || v_learner.last_name,
      'learner_code', v_learner.learner_code,
      'avatar_preset', v_learner.avatar_preset,
      'country_code', v_learner.country_code,
      'education_system_id', v_learner.education_system_id,
      'curriculum_id', v_learner.curriculum_id,
      'education_level_id', v_learner.education_level_id,
      'grade_id', v_learner.grade_id,
      'access_mode', 'independent_device'
    )
  );
end;
$$;

grant execute on function public.link_learner_device(text, text, text, text) to anon, authenticated;

-- ============================================================================
-- 10. Learner Credential Authentication RPC (Learner ID/Username + PIN/Password)
-- ============================================================================

create or replace function public.authenticate_learner_credential(
  p_identifier text,
  p_secret text,
  p_device_identifier text default 'default_device',
  p_device_name text default 'Independent Device',
  p_device_type text default 'phone'
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_clean_id text;
  v_learner public.learners;
  v_profile public.learner_profiles;
  v_calculated_hash text;
  v_device_id uuid;
  v_session_token text;
  v_session_hash text;
  v_session_expires timestamptz;
  v_clean_type text;
begin
  v_clean_id := upper(btrim(coalesce(p_identifier, '')));
  if v_clean_id = '' or coalesce(p_secret, '') = '' then
    raise exception 'Identifier and PIN/Password are required' using errcode = '22023';
  end if;

  -- Lookup learner by learner_code or profile username
  select l.*, p.* into v_learner
  from public.learners l
  join public.learner_profiles p on p.learner_id = l.id
  where upper(l.learner_code) = v_clean_id
     or upper(p.username) = v_clean_id
  limit 1;

  if v_learner.id is null then
    raise exception 'Invalid Learner ID or credentials' using errcode = '42501';
  end if;

  select * into v_profile from public.learner_profiles where learner_id = v_learner.id;

  -- Check lockout
  if v_profile.locked_until is not null and v_profile.locked_until > now() then
    raise exception 'Account temporarily locked due to too many failed attempts. Try again later or ask parent'
      using errcode = '42501';
  end if;

  if v_profile.access_status = 'suspended' then
    raise exception 'Learner account is suspended. Please ask your parent' using errcode = '42501';
  end if;

  if v_profile.credential_hash is null or v_profile.credential_salt is null then
    raise exception 'Independent login not configured yet. Please ask parent to set up your PIN or device code'
      using errcode = '42501';
  end if;

  -- Verify credential hash
  v_calculated_hash := public.hash_learner_secret(v_profile.credential_salt, p_secret);

  if v_calculated_hash <> v_profile.credential_hash then
    update public.learner_profiles
    set
      failed_login_attempts = failed_login_attempts + 1,
      locked_until = case
        when failed_login_attempts + 1 >= 5 then now() + interval '15 minutes'
        else null
      end
    where learner_id = v_learner.id;

    raise exception 'Invalid Learner ID or PIN/Password' using errcode = '42501';
  end if;

  -- Credentials valid! Reset failed attempts
  update public.learner_profiles
  set failed_login_attempts = 0, locked_until = null, updated_at = now()
  where learner_id = v_learner.id;

  v_clean_type := lower(btrim(coalesce(p_device_type, 'phone')));
  if v_clean_type not in ('phone', 'tablet', 'desktop', 'web') then
    v_clean_type := 'phone';
  end if;

  -- Register/update device
  insert into public.learner_devices (
    learner_id,
    device_identifier,
    device_name,
    device_type,
    is_active,
    last_active_at,
    last_sync_at
  ) values (
    v_learner.id,
    btrim(p_device_identifier),
    btrim(p_device_name),
    v_clean_type,
    true,
    now(),
    now()
  )
  on conflict (learner_id, device_identifier) do update
    set
      device_name = excluded.device_name,
      device_type = excluded.device_type,
      is_active = true,
      last_active_at = now()
  returning id into v_device_id;

  -- Create session
  v_session_token := 'ltz_sess_' || replace(gen_random_uuid()::text, '-', '') || replace(gen_random_uuid()::text, '-', '');
  v_session_hash := public.hash_learner_secret('session_salt', v_session_token);
  v_session_expires := now() + interval '30 days';

  insert into public.learner_sessions (
    learner_id,
    device_id,
    session_token_hash,
    session_status,
    expires_at
  ) values (
    v_learner.id,
    v_device_id,
    v_session_hash,
    'active',
    v_session_expires
  );

  return jsonb_build_object(
    'session_token', v_session_token,
    'session_expires_at', v_session_expires,
    'device_id', v_device_id,
    'learner', jsonb_build_object(
      'id', v_learner.id,
      'first_name', v_learner.first_name,
      'last_name', v_learner.last_name,
      'full_name', v_learner.first_name || ' ' || v_learner.last_name,
      'learner_code', v_learner.learner_code,
      'avatar_preset', v_learner.avatar_preset,
      'country_code', v_learner.country_code,
      'education_system_id', v_learner.education_system_id,
      'curriculum_id', v_learner.curriculum_id,
      'education_level_id', v_learner.education_level_id,
      'grade_id', v_learner.grade_id,
      'access_mode', v_profile.access_mode
    )
  );
end;
$$;

grant execute on function public.authenticate_learner_credential(text, text, text, text, text) to anon, authenticated;

-- ============================================================================
-- 11. Validate Learner Session RPC
-- ============================================================================

create or replace function public.validate_learner_session(
  p_session_token text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_hash text;
  v_session public.learner_sessions;
  v_learner public.learners;
  v_profile public.learner_profiles;
begin
  v_hash := public.hash_learner_secret('session_salt', p_session_token);

  select * into v_session
  from public.learner_sessions
  where session_token_hash = v_hash
    and session_status = 'active';

  if not found or v_session.expires_at < now() then
    return jsonb_build_object('valid', false);
  end if;

  select * into v_learner from public.learners where id = v_session.learner_id;
  select * into v_profile from public.learner_profiles where learner_id = v_session.learner_id;

  if v_profile.access_status = 'suspended' then
    return jsonb_build_object('valid', false, 'reason', 'suspended');
  end if;

  -- Update device last active
  if v_session.device_id is not null then
    update public.learner_devices
    set last_active_at = now()
    where id = v_session.device_id;
  end if;

  return jsonb_build_object(
    'valid', true,
    'learner', jsonb_build_object(
      'id', v_learner.id,
      'first_name', v_learner.first_name,
      'last_name', v_learner.last_name,
      'full_name', v_learner.first_name || ' ' || v_learner.last_name,
      'learner_code', v_learner.learner_code,
      'avatar_preset', v_learner.avatar_preset,
      'country_code', v_learner.country_code,
      'education_system_id', v_learner.education_system_id,
      'curriculum_id', v_learner.curriculum_id,
      'education_level_id', v_learner.education_level_id,
      'grade_id', v_learner.grade_id,
      'access_mode', v_profile.access_mode
    )
  );
end;
$$;

grant execute on function public.validate_learner_session(text) to anon, authenticated;

-- ============================================================================
-- 12. Parent RPC: Revoke Device Access
-- ============================================================================

create or replace function public.revoke_learner_device(
  p_learner_id uuid,
  p_device_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;

  if not public.is_authorized_learner_parent(p_learner_id) then
    raise exception 'Unauthorized to manage this learner' using errcode = '42501';
  end if;

  -- Deactivate device
  update public.learner_devices
  set is_active = false
  where id = p_device_id and learner_id = p_learner_id;

  -- Revoke all active sessions on this device
  update public.learner_sessions
  set session_status = 'revoked', revoked_at = now()
  where device_id = p_device_id and learner_id = p_learner_id;

  return true;
end;
$$;

grant execute on function public.revoke_learner_device(uuid, uuid) to authenticated;

-- ============================================================================
-- 13. Parent RPC: Reset Learner PIN / Password
-- ============================================================================

create or replace function public.reset_learner_pin(
  p_learner_id uuid,
  p_new_pin text,
  p_credential_type text default 'pin'
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_learner public.learners;
  v_salt text;
  v_hash text;
begin
  if v_user_id is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;

  if not public.is_authorized_learner_parent(p_learner_id) then
    raise exception 'Unauthorized to manage this learner' using errcode = '42501';
  end if;

  select * into v_learner from public.learners where id = p_learner_id;

  if p_credential_type = 'pin' then
    if p_new_pin !~ '^[0-9]{4,6}$' then
      raise exception 'PIN must be between 4 and 6 digits' using errcode = '22023';
    end if;
    if to_char(v_learner.date_of_birth, 'YYYY') = p_new_pin
       or to_char(v_learner.date_of_birth, 'MMDD') = p_new_pin
       or to_char(v_learner.date_of_birth, 'DDMM') = p_new_pin then
      raise exception 'PIN cannot be the child birth date or year' using errcode = '22023';
    end if;
  elsif char_length(p_new_pin) < 6 then
    raise exception 'Password must be at least 6 characters' using errcode = '22023';
  end if;

  v_salt := substr(md5(gen_random_uuid()::text || now()::text), 1, 16);
  v_hash := public.hash_learner_secret(v_salt, p_new_pin);

  update public.learner_profiles
  set
    credential_type = p_credential_type,
    credential_hash = v_hash,
    credential_salt = v_salt,
    failed_login_attempts = 0,
    locked_until = null,
    updated_at = now()
  where learner_id = p_learner_id;

  return true;
end;
$$;

grant execute on function public.reset_learner_pin(uuid, text, text) to authenticated;

-- ============================================================================
-- 14. Parent RPC: Suspend / Reactivate Learner Access
-- ============================================================================

create or replace function public.toggle_learner_access_status(
  p_learner_id uuid,
  p_suspend boolean
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_new_status text := case when p_suspend then 'suspended' else 'active' end;
begin
  if v_user_id is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;

  if not public.is_authorized_learner_parent(p_learner_id) then
    raise exception 'Unauthorized to manage this learner' using errcode = '42501';
  end if;

  update public.learner_profiles
  set access_status = v_new_status, updated_at = now()
  where learner_id = p_learner_id;

  if p_suspend then
    -- Invalidate all active sessions for this learner
    update public.learner_sessions
    set session_status = 'revoked', revoked_at = now()
    where learner_id = p_learner_id and session_status = 'active';
  end if;

  return true;
end;
$$;

grant execute on function public.toggle_learner_access_status(uuid, boolean) to authenticated;

-- ============================================================================
-- 15. Parent RPC: Get Child Device Management Overview
-- ============================================================================

create or replace function public.get_learner_device_management(
  p_learner_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_learner public.learners;
  v_profile public.learner_profiles;
  v_devices jsonb := '[]'::jsonb;
  v_active_token jsonb := null;
  v_dev record;
  v_tok record;
begin
  if v_user_id is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;

  if not public.is_authorized_learner_parent(p_learner_id) then
    raise exception 'Unauthorized to view this learner device management' using errcode = '42501';
  end if;

  select * into v_learner from public.learners where id = p_learner_id;
  if not found then
    raise exception 'Learner not found' using errcode = 'P0002';
  end if;

  select * into v_profile from public.learner_profiles where learner_id = p_learner_id;

  -- Registered devices list
  for v_dev in (
    select id, device_identifier, device_name, device_type, is_active, last_active_at, last_sync_at, created_at
    from public.learner_devices
    where learner_id = p_learner_id
    order by last_active_at desc
  ) loop
    v_devices := v_devices || jsonb_build_object(
      'id', v_dev.id,
      'device_identifier', v_dev.device_identifier,
      'device_name', v_dev.device_name,
      'device_type', v_dev.device_type,
      'is_active', v_dev.is_active,
      'last_active_at', v_dev.last_active_at,
      'last_sync_at', v_dev.last_sync_at,
      'created_at', v_dev.created_at
    );
  end loop;

  -- Active unexpired activation token
  select * into v_tok
  from public.learner_activation_tokens
  where learner_id = p_learner_id
    and used_at is null
    and expires_at > now()
  order by created_at desc
  limit 1;

  if v_tok.id is not null then
    v_active_token := jsonb_build_object(
      'token_id', v_tok.id,
      'token_code', v_tok.token_code,
      'expires_at', v_tok.expires_at,
      'expires_in_seconds', extract(epoch from (v_tok.expires_at - now()))::int
    );
  end if;

  return jsonb_build_object(
    'learner_id', v_learner.id,
    'learner_code', v_learner.learner_code,
    'full_name', v_learner.first_name || ' ' || v_learner.last_name,
    'avatar_preset', v_learner.avatar_preset,
    'access_mode', coalesce(v_profile.access_mode, 'parent_managed'),
    'access_status', coalesce(v_profile.access_status, 'active'),
    'username', v_profile.username,
    'has_credentials', (v_profile.credential_hash is not null),
    'credential_type', v_profile.credential_type,
    'devices', v_devices,
    'active_activation_token', v_active_token
  );
end;
$$;

grant execute on function public.get_learner_device_management(uuid) to authenticated;

-- ============================================================================
-- 16. Multi-Device Synchronisation RPC (Sync Device Learning Activity)
-- ============================================================================

create or replace function public.sync_learner_device_activity(
  p_learner_id uuid,
  p_session_token text,
  p_events jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_hash text;
  v_session public.learner_sessions;
  v_event record;
  v_processed_count integer := 0;
  v_duplicate_count integer := 0;
  v_client_event_id uuid;
  v_event_type text;
  v_payload jsonb;
  v_recorded_at timestamptz;
begin
  -- Validate session or parent authorization
  if p_session_token is not null and btrim(p_session_token) <> '' then
    v_hash := public.hash_learner_secret('session_salt', p_session_token);
    select * into v_session
    from public.learner_sessions
    where session_token_hash = v_hash
      and session_status = 'active'
      and learner_id = p_learner_id;

    if not found or v_session.expires_at < now() then
      raise exception 'Invalid or expired learner session' using errcode = '42501';
    end if;

    -- Update last sync on device
    if v_session.device_id is not null then
      update public.learner_devices
      set last_sync_at = now(), last_active_at = now()
      where id = v_session.device_id;
    end if;
  else
    if auth.uid() is null or not public.is_authorized_learner_parent(p_learner_id) then
      raise exception 'Authorization required' using errcode = '42501';
    end if;
  end if;

  if p_events is null or jsonb_typeof(p_events) <> 'array' then
    raise exception 'Events payload must be a JSON array' using errcode = '22023';
  end if;

  -- Process each event idempotently with timestamp conflict resolution
  for v_event in select * from jsonb_to_recordset(p_events) as x(
    client_event_id uuid,
    event_type text,
    payload jsonb,
    client_recorded_at timestamptz
  )
  loop
    v_client_event_id := v_event.client_event_id;
    v_event_type := v_event.event_type;
    v_payload := coalesce(v_event.payload, '{}'::jsonb);
    v_recorded_at := coalesce(v_event.client_recorded_at, now());

    if v_client_event_id is null or v_event_type is null then
      continue;
    end if;

    if exists (select 1 from public.learner_sync_events where client_event_id = v_client_event_id) then
      v_duplicate_count := v_duplicate_count + 1;
      continue;
    end if;

    insert into public.learner_sync_events (
      client_event_id,
      learner_id,
      event_type,
      payload,
      client_recorded_at,
      processed_at
    ) values (
      v_client_event_id,
      p_learner_id,
      v_event_type,
      v_payload,
      v_recorded_at,
      now()
    );

    v_processed_count := v_processed_count + 1;
  end loop;

  return jsonb_build_object(
    'learner_id', p_learner_id,
    'processed_count', v_processed_count,
    'duplicate_count', v_duplicate_count,
    'synchronized_at', now()
  );
end;
$$;

grant execute on function public.sync_learner_device_activity(uuid, text, jsonb) to anon, authenticated;

-- ============================================================================
-- 17. Row Level Security Policies
-- ============================================================================

alter table public.learner_profiles enable row level security;
alter table public.learner_devices enable row level security;
alter table public.learner_activation_tokens enable row level security;
alter table public.learner_sessions enable row level security;

revoke all on public.learner_profiles, public.learner_devices,
  public.learner_activation_tokens, public.learner_sessions from public, anon;

grant select, update on public.learner_profiles to authenticated;
grant select, insert, update, delete on public.learner_devices to authenticated;
grant select, insert, update on public.learner_activation_tokens to authenticated;
grant select, update on public.learner_sessions to authenticated;

-- Learner Profiles policies
create policy "Parents read own learner profiles"
  on public.learner_profiles for select to authenticated
  using (
    parent_id = auth.uid()
    or public.is_authorized_learner_parent(learner_id)
    or public.has_role('super_admin')
  );

create policy "Parents update own learner profiles"
  on public.learner_profiles for update to authenticated
  using (
    parent_id = auth.uid()
    or public.is_authorized_learner_parent(learner_id)
    or public.has_role('super_admin')
  )
  with check (
    parent_id = auth.uid()
    or public.is_authorized_learner_parent(learner_id)
    or public.has_role('super_admin')
  );

-- Learner Devices policies
create policy "Parents view own learner devices"
  on public.learner_devices for select to authenticated
  using (
    public.is_authorized_learner_parent(learner_id)
    or public.has_role('super_admin')
  );

create policy "Parents manage own learner devices"
  on public.learner_devices for all to authenticated
  using (
    public.is_authorized_learner_parent(learner_id)
    or public.has_role('super_admin')
  )
  with check (
    public.is_authorized_learner_parent(learner_id)
    or public.has_role('super_admin')
  );

-- Learner Activation Tokens policies
create policy "Parents view own activation tokens"
  on public.learner_activation_tokens for select to authenticated
  using (
    created_by_parent_id = auth.uid()
    or public.is_authorized_learner_parent(learner_id)
    or public.has_role('super_admin')
  );

create policy "Parents create activation tokens"
  on public.learner_activation_tokens for insert to authenticated
  with check (
    created_by_parent_id = auth.uid()
    and public.is_authorized_learner_parent(learner_id)
  );

commit;
