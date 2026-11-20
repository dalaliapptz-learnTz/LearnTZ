-- ============================================================================
-- Allow authenticated parents/guardians to add a school during Add/Edit Learner
-- Migration: 20261120000200_parent_add_school_rpc.sql
--
-- Deduplicates case-insensitively within (country_code, education_system_id)
-- and validates system/country integrity server-side.
-- ============================================================================

begin;

create or replace function public.add_parent_school(
  p_country_code text,
  p_education_system_id uuid,
  p_name text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_country text := upper(btrim(coalesce(p_country_code, '')));
  v_clean_name text := regexp_replace(btrim(coalesce(p_name, '')), '\s+', ' ', 'g');
  v_school record;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  if char_length(v_clean_name) < 2 or char_length(v_clean_name) > 200 then
    raise exception 'School name must be between 2 and 200 characters'
      using errcode = '22023';
  end if;

  if not exists (
    select 1
    from public.education_systems es
    where es.id = p_education_system_id
      and es.country_code = v_country
      and es.is_enabled = true
  ) then
    raise exception 'Selected education system is not valid for this country'
      using errcode = '23503';
  end if;

  -- Return existing matching school (case-insensitive) to avoid duplicates
  select id, country_code, education_system_id, name, is_enabled
  into v_school
  from public.schools
  where country_code = v_country
    and education_system_id = p_education_system_id
    and lower(btrim(name)) = lower(v_clean_name)
  limit 1;

  if not found then
    insert into public.schools (
      country_code,
      education_system_id,
      name,
      is_enabled
    )
    values (
      v_country,
      p_education_system_id,
      v_clean_name,
      true
    )
    returning id, country_code, education_system_id, name, is_enabled
    into v_school;
  elsif v_school.is_enabled = false then
    update public.schools
    set is_enabled = true, updated_at = now()
    where id = v_school.id
    returning id, country_code, education_system_id, name, is_enabled
    into v_school;
  end if;

  return jsonb_build_object(
    'id', v_school.id,
    'country_code', v_school.country_code,
    'education_system_id', v_school.education_system_id,
    'name', v_school.name,
    'is_enabled', v_school.is_enabled
  );
end;
$$;

revoke all on function public.add_parent_school(text, uuid, text) from public, anon;
grant execute on function public.add_parent_school(text, uuid, text) to authenticated;

commit;
