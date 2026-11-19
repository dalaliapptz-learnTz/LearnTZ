begin;
select plan(10);

select has_table('public', 'examination_sessions', 'examination_sessions table exists');
select has_table('public', 'examination_candidates', 'examination_candidates table exists');
select has_function('public', 'get_exam_v2_dashboard', ARRAY['text','uuid','uuid','uuid'], 'get_exam_v2_dashboard exists');
select has_function('public', 'register_exam_v2_candidate', ARRAY['uuid','uuid','uuid','boolean','text'], 'register_exam_v2_candidate exists');

-- Ephemeral identities & learners
insert into auth.users (
  id, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at, aud, role
) values
  ('00000000-0000-0000-0000-000000000841', 'p67_admin@learntz.test', '', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"full_name":"Phase67 Admin"}'::jsonb, now(), now(), 'authenticated', 'authenticated')
on conflict (id) do nothing;

insert into public.user_roles (user_id, role, country_code) values
  ('00000000-0000-0000-0000-000000000841', 'curriculum_admin', 'TZ')
on conflict do nothing;

insert into public.parent_accounts (user_id, country_code) values
  ('00000000-0000-0000-0000-000000000841', 'TZ')
on conflict (user_id) do nothing;

insert into public.learners (
  id, created_by_parent_user_id, first_name, last_name, date_of_birth,
  country_code, education_system_id, curriculum_id, education_level_id, grade_id, registration_request_id
)
select
  '00000000-0000-0000-0000-000000000848'::uuid,
  '00000000-0000-0000-0000-000000000841'::uuid,
  'Neema', 'Moshi', date '2016-04-10',
  'TZ',
  es.id, c.id, el.id, g3.id, gen_random_uuid()
from public.curricula c
join public.education_systems es on es.country_code = c.country_code
join public.education_levels el on el.curriculum_id = c.id and el.code = 'PRIMARY'
join public.education_grades g3 on g3.education_level_id = el.id and g3.code = 'STANDARD_3'
where c.country_code = 'TZ' and c.code = 'TIE'
limit 1
on conflict (id) do nothing;

insert into public.learners (
  id, created_by_parent_user_id, first_name, last_name, date_of_birth,
  country_code, education_system_id, curriculum_id, education_level_id, grade_id, registration_request_id
)
select
  '00000000-0000-0000-0000-000000000849'::uuid,
  '00000000-0000-0000-0000-000000000841'::uuid,
  'Juma', 'Kileo', date '2014-05-12',
  'TZ',
  es.id, c.id, el.id, g5.id, gen_random_uuid()
from public.curricula c
join public.education_systems es on es.country_code = c.country_code
join public.education_levels el on el.curriculum_id = c.id and el.code = 'PRIMARY'
join public.education_grades g5 on g5.education_level_id = el.id and g5.code = 'STANDARD_5'
where c.country_code = 'TZ' and c.code = 'TIE'
limit 1
on conflict (id) do nothing;

set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000841', true);

-- Create examination
do $$
declare
  v_lvl uuid; v_grd uuid; v_eng uuid; v_type uuid; v_sc uuid;
begin
  select el.id into v_lvl from public.education_levels el join public.curricula c on c.id = el.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and el.code = 'PRIMARY' limit 1;
  select eg.id into v_grd from public.education_grades eg join public.curricula c on c.id = eg.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and eg.code = 'STANDARD_3' limit 1;
  select id into v_eng from public.subjects where code = 'tie-pri-english-standard3' limit 1;
  select id into v_type from public.examination_types where country_code = 'TZ' and code = 'TERMINAL' limit 1;
  select sc.id into v_sc from public.curriculum_specific_competences sc where sc.subject_id = v_eng order by sc.display_order limit 1;

  perform public.save_exam_v2_examination(
    'TZ', v_lvl, v_grd, v_eng, v_type,
    'Phase67 Test: English Terminal',
    2026, 'Term I', null, 90, 'en', 'Read carefully.', 'hybrid',
    '[{"section_code":"A","title":"Multiple Choice","question_format":"multiple_choice","question_count":5,"marks_allocated":20,"display_order":1}]'::jsonb,
    jsonb_build_array(jsonb_build_object('specific_competence_id', v_sc, 'allocated_marks', 20))
  );
end $$;

-- 1. Schedule session cleanly (and reject invalid time window)
select throws_matching(
  $$
    select public.create_exam_v2_session(
      (select id from public.examinations where title = 'Phase67 Test: English Terminal' limit 1),
      'Invalid Window Session',
      now() + interval '2 hours',
      now() + interval '1 hour'
    );
  $$,
  'Session end time must be after start time',
  'Rejects session where ends_at <= starts_at'
);

select is(
  public.create_exam_v2_session(
    (select id from public.examinations where title = 'Phase67 Test: English Terminal' limit 1),
    'Morning Sitting — Term I',
    now() + interval '1 day',
    now() + interval '1 day 2 hours',
    'online',
    'Digital Hall A',
    'Log in 10 minutes early.'
  ) ->> 'status',
  'scheduled',
  'Schedules upcoming examination session cleanly'
);

-- 2. Register eligible Standard III learner -> auto-generates TZ-2026-0001
select is(
  public.register_exam_v2_candidate(
    (select id from public.examinations where title = 'Phase67 Test: English Terminal' limit 1),
    '00000000-0000-0000-0000-000000000848'::uuid,
    (select id from public.examination_sessions where title = 'Morning Sitting — Term I' limit 1),
    false,
    null
  ) ->> 'examination_number',
  'TZ-2026-0001',
  'Registers eligible Standard III learner and allocates unique examination number'
);

-- 3. Ineligible Standard V learner rejected without override
select throws_matching(
  $$
    select public.register_exam_v2_candidate(
      (select id from public.examinations where title = 'Phase67 Test: English Terminal' limit 1),
      '00000000-0000-0000-0000-000000000849'::uuid,
      null, false, null
    );
  $$,
  'Learner eligibility mismatch',
  'Rejects ineligible Standard V learner without explicit admin override'
);

-- 4. Attendance update works cleanly
select is(
  public.record_exam_v2_attendance(
    (select id from public.examination_candidates where learner_id = '00000000-0000-0000-0000-000000000848' limit 1),
    'present'
  ) ->> 'attendance_status',
  'present',
  'Records candidate attendance as present'
);

-- 5. Dashboard returns real DB-derived metrics (candidates >= 1, upcoming_sessions >= 1)
select ok(
  (public.get_exam_v2_dashboard('TZ') -> 'metrics' ->> 'total_candidates')::int >= 1
  and (public.get_exam_v2_dashboard('TZ') -> 'metrics' ->> 'upcoming_sessions_count')::int >= 1,
  'Dashboard returns real DB-derived candidate and upcoming session counts'
);

select * from finish();
rollback;
