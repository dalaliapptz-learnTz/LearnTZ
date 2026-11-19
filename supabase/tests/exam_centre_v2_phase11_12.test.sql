begin;
select plan(8);

select has_table('public', 'examination_grading_policies', 'examination_grading_policies exists');
select has_table('public', 'examination_offline_sync_batches', 'examination_offline_sync_batches exists');

-- 1. Multi-country configurable grading policies resolve differently per country (zero hardcoded thresholds)
select is(
  public.resolve_exam_v2_grade_band('TZ', 'PRIMARY', 85) ->> 'grade',
  'A',
  'Tanzania Primary 85% resolves to Grade A via TZ_PRIMARY_STANDARD'
);

select is(
  public.resolve_exam_v2_grade_band('KE', 'PRIMARY', 85) ->> 'grade',
  'EE',
  'Kenya Primary 85% resolves to EE (Exceeding Expectations) via KE_CBC_PERFORMANCE'
);

select is(
  public.resolve_exam_v2_grade_band('UG', 'PRIMARY', 85) ->> 'grade',
  'D1',
  'Uganda Primary 85% resolves to D1 via UG_PRIMARY_AGGREGATE'
);

select cmp_ok(
  jsonb_array_length(public.list_exam_v2_grading_policies(null)),
  '>=',
  2,
  'list_exam_v2_grading_policies returns multi-country grading policies'
);

-- 2. Offline sync enforcement: blocked when allow_offline_sync = false, succeeds when true
insert into auth.users (
  id, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at, aud, role
) values
  ('00000000-0000-0000-0000-000000000821', 'p11_admin@learntz.test', '', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"full_name":"Phase11 Admin"}'::jsonb, now(), now(), 'authenticated', 'authenticated')
on conflict (id) do nothing;

insert into public.user_roles (user_id, role, country_code) values
  ('00000000-0000-0000-0000-000000000821', 'super_admin', null)
on conflict do nothing;

insert into public.parent_accounts (user_id, country_code) values
  ('00000000-0000-0000-0000-000000000821', 'TZ')
on conflict (user_id) do nothing;

insert into public.learners (
  id, created_by_parent_user_id, first_name, last_name, date_of_birth,
  country_code, education_system_id, curriculum_id, education_level_id, grade_id, registration_request_id
)
select
  '00000000-0000-0000-0000-000000000829'::uuid,
  '00000000-0000-0000-0000-000000000821'::uuid,
  'Zuri', 'Mamba', date '2016-06-01',
  'TZ', es.id, c.id, el.id, g3.id, gen_random_uuid()
from public.curricula c
join public.education_systems es on es.country_code = c.country_code
join public.education_levels el on el.curriculum_id = c.id and el.code = 'PRIMARY'
join public.education_grades g3 on g3.education_level_id = el.id and g3.code = 'STANDARD_3'
where c.country_code = 'TZ' and c.code = 'TIE'
limit 1
on conflict (id) do nothing;

set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000821', true);

do $$
declare
  v_lvl uuid; v_grd uuid; v_eng uuid; v_type uuid; v_sc uuid;
  v_exam_id uuid; v_sec_id uuid; v_q1 uuid;
begin
  select el.id into v_lvl from public.education_levels el join public.curricula c on c.id = el.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and el.code = 'PRIMARY' limit 1;
  select eg.id into v_grd from public.education_grades eg join public.curricula c on c.id = eg.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and eg.code = 'STANDARD_3' limit 1;
  select id into v_eng from public.subjects where code = 'tie-pri-english-standard3' limit 1;
  select id into v_type from public.examination_types where country_code = 'TZ' and code = 'TERMINAL' limit 1;
  select sc.id into v_sc from public.curriculum_specific_competences sc where sc.subject_id = v_eng order by sc.display_order limit 1;

  v_exam_id := (public.save_exam_v2_examination(
    'TZ', v_lvl, v_grd, v_eng, v_type, 'Phase11 Offline Sync Test',
    2026, 'Term I', null, 60, 'en', 'Instructions', 'hybrid',
    '[{"section_code":"A","title":"MCQ","question_format":"multiple_choice","question_count":1,"marks_allocated":2,"display_order":1}]'::jsonb,
    jsonb_build_array(jsonb_build_object('specific_competence_id', v_sc, 'allocated_marks', 2))
  ) ->> 'id')::uuid;

  select id into v_sec_id from public.examination_sections where examination_id = v_exam_id limit 1;
  v_q1 := (public.save_exam_v2_question('TZ', v_lvl, v_grd, v_eng, v_sc, 'multiple_choice', 'P11_Q1', '{"answer":"A"}'::jsonb, '["A","B"]'::jsonb, '{}'::jsonb, 2) ->> 'id')::uuid;
  perform public.add_exam_v2_paper_question(v_exam_id, v_sec_id, v_q1, 2);
  perform public.transition_exam_v2_status(v_exam_id, 'submit_for_review', 'Ready');
  perform public.transition_exam_v2_status(v_exam_id, 'approve', 'Approved');
  perform public.transition_exam_v2_status(v_exam_id, 'publish', 'Published');
  perform public.start_exam_v2_attempt(v_exam_id, '00000000-0000-0000-0000-000000000829'::uuid);
end $$;

-- Blocked by default because allow_offline_sync = false
select throws_matching(
  $$
    select public.sync_exam_v2_offline_responses(
      (select id from public.examination_attempts where learner_id = '00000000-0000-0000-0000-000000000829' limit 1),
      '[]'::jsonb, 'device-1', 'abc123'
    );
  $$,
  'Offline synchronization is not enabled',
  'Rejects offline sync when allow_offline_sync is false'
);

-- Enable offline sync explicitly -> batch sync succeeds
update public.examinations
set allow_offline_sync = true
where title = 'Phase11 Offline Sync Test';

select is(
  (
    public.sync_exam_v2_offline_responses(
      (select id from public.examination_attempts where learner_id = '00000000-0000-0000-0000-000000000829' limit 1),
      jsonb_build_array(
        jsonb_build_object(
          'examination_question_id',
          (select eq.id from public.examination_questions eq join public.examinations e on e.id = eq.examination_id where e.title = 'Phase11 Offline Sync Test' limit 1),
          'response_payload',
          '{"answer":"A"}'::jsonb
        )
      ),
      'android-tablet-01',
      'sha256-test-digest'
    ) ->> 'synced_count'
  )::int,
  1,
  'Offline batch sync persists encrypted-origin responses when explicitly enabled'
);

select * from finish();
rollback;
