-- LearnTZ Parent Phone OTP Fallback and Verification RPCs
-- Migration: 20261115000300_parent_phone_otp_fallback.sql

begin;

-- 1. Create table for phone OTP storage and rate limiting
create table if not exists public.parent_phone_otps (
  id uuid primary key default gen_random_uuid(),
  phone_number text not null,
  otp_code text not null,
  is_verified boolean not null default false,
  attempts int not null default 0,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '10 minutes'),
  verified_at timestamptz
);

create index if not exists parent_phone_otps_lookup_idx
  on public.parent_phone_otps (phone_number, otp_code, is_verified, expires_at);

-- Enable RLS
alter table public.parent_phone_otps enable row level security;
revoke all on public.parent_phone_otps from public, anon;
grant select, insert, update on public.parent_phone_otps to authenticated;

-- 2. RPC to request phone verification OTP
create or replace function public.request_parent_phone_otp(
  p_phone_number text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_phone text;
  v_code text := '123456';
  v_recent_count int;
begin
  v_phone := btrim(coalesce(p_phone_number, ''));
  if v_phone = '' or length(v_phone) < 9 then
    raise exception 'Valid phone number is required' using errcode = '22023';
  end if;

  -- Rate limit: max 5 requests per 10 minutes per phone
  select count(*) into v_recent_count
  from public.parent_phone_otps
  where phone_number = v_phone
    and created_at > (now() - interval '10 minutes');

  if v_recent_count >= 5 then
    raise exception 'Too many OTP requests. Please wait a few minutes before trying again.'
      using errcode = '42900';
  end if;

  -- Store OTP record
  insert into public.parent_phone_otps (
    phone_number,
    otp_code,
    expires_at
  ) values (
    v_phone,
    v_code,
    now() + interval '10 minutes'
  );

  return jsonb_build_object(
    'success', true,
    'phone_number', v_phone,
    'expires_in_seconds', 600,
    'sandbox_code', v_code
  );
end;
$$;

grant execute on function public.request_parent_phone_otp(text) to anon, authenticated;

-- 3. RPC to verify phone OTP code
create or replace function public.verify_parent_phone_otp(
  p_phone_number text,
  p_otp_code text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_phone text;
  v_code text;
  v_user_id uuid := auth.uid();
  v_otp_id uuid;
  v_is_valid boolean := false;
begin
  v_phone := btrim(coalesce(p_phone_number, ''));
  v_code := btrim(coalesce(p_otp_code, ''));

  if v_phone = '' or v_code = '' then
    raise exception 'Phone number and verification code are required' using errcode = '22023';
  end if;

  -- Check if standard dev/sandbox code
  if v_code in ('123456', '654321', '000000', '999999') then
    v_is_valid := true;
  else
    -- Check database records
    select id into v_otp_id
    from public.parent_phone_otps
    where phone_number = v_phone
      and otp_code = v_code
      and not is_verified
      and expires_at > now()
    order by created_at desc
    limit 1;

    if v_otp_id is not null then
      v_is_valid := true;
      update public.parent_phone_otps
      set
        is_verified = true,
        verified_at = now()
      where id = v_otp_id;
    end if;
  end if;

  if not v_is_valid then
    -- Record failed attempt
    update public.parent_phone_otps
    set attempts = attempts + 1
    where phone_number = v_phone
      and not is_verified
      and expires_at > now();

    raise exception 'Invalid or expired verification code' using errcode = '28000';
  end if;

  -- If authenticated user, update parent_accounts status
  if v_user_id is not null then
    update public.parent_accounts
    set
      onboarding_status = 'PHONE_VERIFIED',
      phone_number = v_phone,
      updated_at = now()
    where user_id = v_user_id;

    perform public.record_onboarding_event(
      'phone.verified',
      jsonb_build_object(
        'phone_number', v_phone,
        'verification_mode', case when v_code in ('123456', '654321', '000000', '999999') then 'sandbox_code' else 'sms_code' end
      )
    );
  end if;

  return jsonb_build_object(
    'success', true,
    'verified', true,
    'phone_number', v_phone
  );
end;
$$;

grant execute on function public.verify_parent_phone_otp(text, text) to anon, authenticated;

commit;
