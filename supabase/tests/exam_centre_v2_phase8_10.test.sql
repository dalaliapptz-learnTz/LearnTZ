begin;
select plan(12);

select has_table('public', 'examination_attempts', 'examination_attempts exists');
select has_table('public', 'examination_responses', 'examination_responses exists');
select has_table('public', 'examination_results', 'examination_results exists');
select has_table('public', 'examination_competency_results', 'examination_competency_results exists');

-- Ephemeral identities & learner
insert into auth.users (
  id, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at, aud, role
) values
  ('00000000-0000-0000-0000-000000000831', 'p810_admin@learntz.test', '', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"full_name":"Phase810 Admin"}'::jsonb, now(), now(), 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-000000000832', 'p810_parent@learntz.test', '', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"full_name":"Phase810 Parent"}'::jsonb, now(), now(), 'authenticated', 'authenticated')
on conflict (id) do nothing;

insert into public.user_roles (user_id, role, country_code) values
  ('00000000-0000-0000-0000-000000000831', 'curriculum_admin', 'TZ'),
  ('00000000-0000-0000-0000-000000000831', 'super_admin', null),
  ('00000000-0000-0000-0000-000000000832', 'parent', null)
on conflict do nothing;

insert into public.parent_accounts (user_id, country_code) values
  ('00000000-0000-0000-0000-000000000832', 'TZ')
on conflict (user_id) do nothing;

insert into public.learners (
  id, created_by_parent_user_id, first_name, last_name, date_of_birth,
  country_code, education_system_id, curriculum_id, education_level_id, grade_id, registration_request_id
)
select
  '00000000-0000-0000-0000-000000000839'::uuid,
  '00000000-0000-0000-0000-000000000832'::uuid,
  'Amani', 'Hassan', date '2016-03-11',
  'TZ', es.id, c.id, el.id, g3.id, gen_random_uuid()
from public.curricula c
join public.education_systems es on es.country_code = c.country_code
join public.education_levels el on el.curriculum_id = c.id and el.code = 'PRIMARY'
join public.education_grades g3 on g3.education_level_id = el.id and g3.code = 'STANDARD_3'
where c.country_code = 'TZ' and c.code = 'TIE'
limit 1
on conflict (id) do nothing;

-- Setup published Standard III English Terminal Exam with 1 MCQ (2m) + 1 Writing (6m) = 8 marks
set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000831', true);

do $$
declare
  v_lvl uuid; v_grd uuid; v_eng uuid; v_type uuid; v_sc1 uuid; v_sc2 uuid;
  v_exam_id uuid; v_sec_id uuid; v_q1 uuid; v_q2 uuid;
begin
  select el.id into v_lvl from public.education_levels el join public.curricula c on c.id = el.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and el.code = 'PRIMARY' limit 1;
  select eg.id into v_grd from public.education_grades eg join public.curricula c on c.id = eg.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and eg.code = 'STANDARD_3' limit 1;
  select id into v_eng from public.subjects where code = 'tie-pri-english-standard3' limit 1;
  select id into v_type from public.examination_types where country_code = 'TZ' and code = 'TERMINAL' limit 1;
  select sc.id into v_sc1 from public.curriculum_specific_competences sc where sc.subject_id = v_eng and sc.code = '1.1' limit 1;
  select sc.id into v_sc2 from public.curriculum_specific_competences sc where sc.subject_id = v_eng and sc.code = '1.2' limit 1;

  v_exam_id := (public.save_exam_v2_examination(
    'TZ', v_lvl, v_grd, v_eng, v_type,
    'Phase810 Online Delivery Test',
    2026, 'Term I', null, 60, 'en', 'Answer all questions.', 'online',
    '[{"section_code":"A","title":"Questions","question_format":"multiple_choice","question_count":2,"marks_allocated":8,"display_order":1}]'::jsonb,
    jsonb_build_array(
      jsonb_build_object('specific_competence_id', v_sc1, 'allocated_marks', 2),
      jsonb_build_object('specific_competence_id', v_sc2, 'allocated_marks', 6)
    )
  ) ->> 'id')::uuid;

  select id into v_sec_id from public.examination_sections where examination_id = v_exam_id limit 1;

  v_q1 := (public.save_exam_v2_question(
    'TZ', v_lvl, v_grd, v_eng, v_sc1, 'multiple_choice',
    'P810_MCQ: Opposite of happy?', '{"answer":"Sad"}'::jsonb, '["Excited","Sad","Kind","Friendly"]'::jsonb, '{}'::jsonb, 2
  ) ->> 'id')::uuid;

  v_q2 := (public.save_exam_v2_question(
    'TZ', v_lvl, v_grd, v_eng, v_sc2, 'writing',
    'P810_WRITING: Write two sentences about your school.', '{}'::jsonb, '[]'::jsonb, '{"guidance":"3 marks per complete sentence"}'::jsonb, 6
  ) ->> 'id')::uuid;

  perform public.add_exam_v2_paper_question(v_exam_id, v_sec_id, v_q1, 2);
  perform public.add_exam_v2_paper_question(v_exam_id, v_sec_id, v_q2, 6);
  perform public.transition_exam_v2_status(v_exam_id, 'submit_for_review', 'Ready');
  perform public.transition_exam_v2_status(v_exam_id, 'approve', 'Approved');
  perform public.transition_exam_v2_status(v_exam_id, 'publish', 'Published');
  perform public.register_exam_v2_candidate(v_exam_id, '00000000-0000-0000-0000-000000000839'::uuid);
end $$;

-- 1. Switch to Parent/Learner session: start attempt -> NO correct_answer leaked!
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000832', true);

select is(
  public.start_exam_v2_attempt(
    (select id from public.examinations where title = 'Phase810 Online Delivery Test' limit 1),
    '00000000-0000-0000-0000-000000000839'::uuid
  ) -> 'questions' -> 0 ->> 'correct_answer',
  null,
  'SECURITY: start_exam_v2_attempt never leaks correct_answer to learner'
);

-- 2. Auto-save both answers using attempt_id & question_id returned by start_exam_v2_attempt
select is(
  (
    with p as (
      select public.start_exam_v2_attempt(
        (select id from public.examinations where title = 'Phase810 Online Delivery Test' limit 1),
        '00000000-0000-0000-0000-000000000839'::uuid
      ) as d
    )
    select (
      public.save_exam_v2_response(
        (d ->> 'attempt_id')::uuid,
        (d -> 'questions' -> 0 ->> 'id')::uuid,
        '{"answer":"Sad"}'::jsonb
      ) ->> 'saved'
    )::boolean from p
  ),
  true,
  'Auto-saves objective MCQ response cleanly'
);

select is(
  (
    with p as (
      select public.start_exam_v2_attempt(
        (select id from public.examinations where title = 'Phase810 Online Delivery Test' limit 1),
        '00000000-0000-0000-0000-000000000839'::uuid
      ) as d
    )
    select (
      public.save_exam_v2_response(
        (d ->> 'attempt_id')::uuid,
        (d -> 'questions' -> 1 ->> 'id')::uuid,
        '{"text":"My school has clean classrooms. I love reading English books."}'::jsonb
      ) ->> 'saved'
    )::boolean from p
  ),
  true,
  'Auto-saves subjective writing response cleanly'
);

-- 3. Submit attempt: MCQ auto-marked (2/2), Writing queued for manual marking (unmarked_count = 1)
select is(
  (
    with p as (
      select public.start_exam_v2_attempt(
        (select id from public.examinations where title = 'Phase810 Online Delivery Test' limit 1),
        '00000000-0000-0000-0000-000000000839'::uuid
      ) as d
    )
    select (
      public.submit_exam_v2_attempt((d ->> 'attempt_id')::uuid) ->> 'unmarked_count'
    )::int from p
  ),
  1,
  'Submission auto-marks objective MCQ and queues subjective writing for manual marking'
);

-- 4. Duplicate submission is prevented (switch to admin to look up attempt id cleanly)
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000831', true);
select throws_matching(
  $$
    select public.submit_exam_v2_attempt(
      (select id from public.examination_attempts where learner_id = '00000000-0000-0000-0000-000000000839' limit 1)
    );
  $$,
  'Attempt already submitted',
  'Duplicate submission is prevented by backend'
);

-- 5. Releasing results before manual marking is blocked

select throws_matching(
  $$
    select public.release_exam_v2_results(
      (select id from public.examinations where title = 'Phase810 Online Delivery Test' limit 1)
    );
  $$,
  'awaiting manual marking',
  'Blocks releasing results while subjective responses remain unmarked'
);

-- 6. Examiner manually marks Writing (5/6) -> total becomes 7/8 = 87.5%
select is(
  (
    public.mark_exam_v2_response(
      (select er.id from public.examination_responses er where er.marking_status = 'awaiting_manual_marking' limit 1),
      5,
      'Clear grammar and sentence structure.'
    ) ->> 'percentage'
  )::numeric,
  87.50::numeric,
  'Manual marking updates total result accurately (2 + 5 = 7 / 8 = 87.5%)'
);

-- 7. Release results -> returns accurate aggregate analytics & marks examination results_released
select is(
  (
    public.release_exam_v2_results(
      (select id from public.examinations where title = 'Phase810 Online Delivery Test' limit 1)
    ) ->> 'average_percentage'
  )::numeric,
  87.50::numeric,
  'Controlled result release publishes results and returns accurate analytics (87.5%)'
);

select * from finish();
rollback;
