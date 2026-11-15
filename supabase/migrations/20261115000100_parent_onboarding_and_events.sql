-- LearnTZ Parent Onboarding Flow & Events Migration
-- Migration: 20261115000100_parent_onboarding_and_events.sql

begin;

-- 1. Extend parent_accounts with phone_number and onboarding_status
alter table public.parent_accounts
  add column if not exists phone_number text,
  add column if not exists onboarding_status text not null default 'NOT_STARTED'
    check (onboarding_status in (
      'NOT_STARTED',
      'COUNTRY_SELECTED',
      'PARENT_REGISTERED',
      'PHONE_VERIFICATION_PENDING',
      'PHONE_VERIFIED',
      'CHILD_REGISTRATION_PENDING',
      'CHILDREN_ADDED',
      'PROFILE_CONFIRMATION_PENDING',
      'COMPLETED'
    ));

create index if not exists parent_accounts_phone_idx
  on public.parent_accounts (phone_number)
  where phone_number is not null;

create index if not exists parent_accounts_onboarding_idx
  on public.parent_accounts (onboarding_status);

-- 2. Extend learners table with learner_code and avatar_preset
alter table public.learners
  add column if not exists learner_code text,
  add column if not exists avatar_preset text not null default 'owl_scholar'
    check (avatar_preset in (
      'owl_scholar',
      'lion_reader',
      'cheetah_runner',
      'giraffe_thinker',
      'elephant_math',
      'zebra_writer',
      'falcon_scout',
      'rhino_builder'
    ));

-- Generate unique learner_code if not present
create or replace function public.generate_learner_code()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_prefix text := 'LTZ';
  v_year text := to_char(coalesce(new.created_at, now()), 'YY');
  v_hash text;
begin
  if new.learner_code is null or btrim(new.learner_code) = '' then
    v_hash := upper(substr(md5(new.id::text || gen_random_uuid()::text), 1, 6));
    new.learner_code := v_prefix || '-' || v_year || '-' || v_hash;
  end if;
  return new;
end;
$$;

drop trigger if exists set_learner_code_on_insert on public.learners;
create trigger set_learner_code_on_insert
  before insert on public.learners
  for each row execute function public.generate_learner_code();

-- Backfill any existing learners missing learner_code
update public.learners
set learner_code = 'LTZ-' || to_char(created_at, 'YY') || '-' || upper(substr(md5(id::text), 1, 6))
where learner_code is null;

create unique index if not exists learners_learner_code_unique_idx
  on public.learners (learner_code);

-- 3. Create onboarding_events table
create table if not exists public.onboarding_events (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid not null references auth.users (id) on delete cascade,
  event_type text not null check (char_length(btrim(event_type)) between 1 and 60),
  event_metadata jsonb not null default '{}'::jsonb
    check (jsonb_typeof(event_metadata) = 'object'),
  created_at timestamptz not null default now()
);

create index if not exists onboarding_events_parent_created_idx
  on public.onboarding_events (parent_id, created_at desc);

create index if not exists onboarding_events_type_idx
  on public.onboarding_events (event_type);

-- RLS on onboarding_events
alter table public.onboarding_events enable row level security;

revoke all on public.onboarding_events from public, anon;
grant select, insert on public.onboarding_events to authenticated;

drop policy if exists onboarding_events_parent_select on public.onboarding_events;
create policy onboarding_events_parent_select
  on public.onboarding_events
  for select
  to authenticated
  using (parent_id = auth.uid());

drop policy if exists onboarding_events_parent_insert on public.onboarding_events;
create policy onboarding_events_parent_insert
  on public.onboarding_events
  for insert
  to authenticated
  with check (parent_id = auth.uid());

-- 4. Check if phone is already registered
create or replace function public.check_phone_registered(
  p_phone_number text
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_normalized text;
begin
  v_normalized := btrim(coalesce(p_phone_number, ''));
  if v_normalized = '' then
    return false;
  end if;
  return exists (
    select 1 from public.parent_accounts
    where phone_number = v_normalized
  );
end;
$$;

grant execute on function public.check_phone_registered(text) to anon, authenticated;

-- 5. Record Onboarding Event RPC
create or replace function public.record_onboarding_event(
  p_event_type text,
  p_metadata jsonb default '{}'::jsonb
)
returns public.onboarding_events
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_event public.onboarding_events;
begin
  if v_user_id is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;

  insert into public.onboarding_events (
    parent_id,
    event_type,
    event_metadata
  ) values (
    v_user_id,
    btrim(p_event_type),
    coalesce(p_metadata, '{}'::jsonb)
  )
  returning * into v_event;

  return v_event;
end;
$$;

grant execute on function public.record_onboarding_event(text, jsonb) to authenticated;

-- 6. Update Parent Onboarding Status RPC
create or replace function public.update_parent_onboarding_status(
  p_status text,
  p_phone_number text default null
)
returns public.parent_accounts
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_account public.parent_accounts;
begin
  if v_user_id is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;

  update public.parent_accounts
  set
    onboarding_status = p_status,
    phone_number = coalesce(nullif(btrim(coalesce(p_phone_number, '')), ''), phone_number),
    updated_at = now()
  where user_id = v_user_id
  returning * into v_account;

  if not found then
    raise exception 'Parent account not found' using errcode = 'P0002';
  end if;

  perform public.record_onboarding_event(
    'onboarding.status_updated',
    jsonb_build_object(
      'new_status', p_status,
      'phone_number', p_phone_number
    )
  );

  return v_account;
end;
$$;

grant execute on function public.update_parent_onboarding_status(text, text) to authenticated;

-- 7. Complete Parent Onboarding Atomic Transaction
create or replace function public.complete_parent_onboarding(
  p_learners jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_learner_obj jsonb;
  v_created_learners jsonb := '[]'::jsonb;
  v_new_learner public.learners;
  v_req_id uuid;
  v_dob date;
  v_first_name text;
  v_middle_name text;
  v_last_name text;
  v_gender text;
  v_country_code text;
  v_sys_id uuid;
  v_cur_id uuid;
  v_lvl_id uuid;
  v_grd_id uuid;
  v_sch_id uuid;
  v_avatar text;
begin
  if v_user_id is null then
    raise exception 'Authentication is required' using errcode = '28000';
  end if;

  if jsonb_array_length(coalesce(p_learners, '[]'::jsonb)) = 0 then
    raise exception 'At least one child profile is required to complete onboarding'
      using errcode = '22023';
  end if;

  -- Create each learner transactionally
  for v_learner_obj in select * from jsonb_array_elements(p_learners) loop
    v_req_id := coalesce(
      (v_learner_obj->>'registration_request_id')::uuid,
      gen_random_uuid()
    );
    v_first_name := btrim(coalesce(v_learner_obj->>'first_name', ''));
    v_middle_name := nullif(btrim(coalesce(v_learner_obj->>'middle_name', '')), '');
    v_last_name := btrim(coalesce(v_learner_obj->>'last_name', ''));
    v_dob := (v_learner_obj->>'date_of_birth')::date;
    v_gender := v_learner_obj->>'gender';
    v_country_code := upper(btrim(v_learner_obj->>'country_code'));
    v_sys_id := (v_learner_obj->>'education_system_id')::uuid;
    v_cur_id := (v_learner_obj->>'curriculum_id')::uuid;
    v_lvl_id := (v_learner_obj->>'education_level_id')::uuid;
    v_grd_id := (v_learner_obj->>'grade_id')::uuid;
    v_sch_id := (v_learner_obj->>'school_id')::uuid;
    v_avatar := coalesce(v_learner_obj->>'avatar_preset', 'owl_scholar');

    if v_first_name = '' or v_last_name = '' then
      raise exception 'Child first name and last name are required'
        using errcode = '22023';
    end if;

    if v_dob is null or v_dob > current_date then
      raise exception 'Valid date of birth is required'
        using errcode = '22023';
    end if;

    -- Validate education structure
    perform public.validate_learner_education(
      v_country_code, v_sys_id, v_cur_id, v_lvl_id, v_grd_id, v_sch_id
    );

    -- Insert learner record
    insert into public.learners (
      first_name,
      middle_name,
      last_name,
      date_of_birth,
      gender,
      country_code,
      education_system_id,
      curriculum_id,
      education_level_id,
      grade_id,
      school_id,
      avatar_preset,
      created_by_parent_user_id,
      registration_request_id
    ) values (
      v_first_name,
      v_middle_name,
      v_last_name,
      v_dob,
      v_gender,
      v_country_code,
      v_sys_id,
      v_cur_id,
      v_lvl_id,
      v_grd_id,
      v_sch_id,
      v_avatar,
      v_user_id,
      v_req_id
    )
    on conflict (created_by_parent_user_id, registration_request_id) do update
      set updated_at = now()
    returning * into v_new_learner;

    -- Link in parent_learners
    insert into public.parent_learners (
      learner_id,
      parent_user_id,
      relationship_role,
      relationship_status,
      created_by_parent_user_id
    ) values (
      v_new_learner.id,
      v_user_id,
      'parent',
      'active',
      v_user_id
    )
    on conflict (learner_id, parent_user_id) do nothing;

    -- Update avatar in learner_social_profiles if created
    update public.learner_social_profiles
    set avatar_preset = v_avatar
    where learner_id = v_new_learner.id;

    v_created_learners := v_created_learners || jsonb_build_object(
      'id', v_new_learner.id,
      'learner_code', v_new_learner.learner_code,
      'full_name', v_first_name || ' ' || v_last_name,
      'grade_id', v_new_learner.grade_id
    );
  end loop;

  -- Update parent account to COMPLETED
  update public.parent_accounts
  set
    onboarding_status = 'COMPLETED',
    updated_at = now()
  where user_id = v_user_id;

  -- Record audit and onboarding event
  perform public.record_onboarding_event(
    'onboarding.completed',
    jsonb_build_object(
      'children_count', jsonb_array_length(p_learners),
      'learners', v_created_learners
    )
  );

  return jsonb_build_object(
    'success', true,
    'status', 'COMPLETED',
    'created_learners', v_created_learners
  );
end;
$$;

grant execute on function public.complete_parent_onboarding(jsonb) to authenticated;

-- 8. Convenient parent_profiles view
create or replace view public.parent_profiles as
select
  p.id as user_id,
  p.full_name,
  pa.phone_number,
  u.email,
  pa.country_code,
  c.display_name as country_name,
  c.currency_code,
  pa.onboarding_status,
  p.created_at,
  p.updated_at
from public.profiles p
join public.parent_accounts pa on pa.user_id = p.id
join public.countries c on c.country_code = pa.country_code
left join auth.users u on u.id = p.id;

grant select on public.parent_profiles to authenticated;

commit;
