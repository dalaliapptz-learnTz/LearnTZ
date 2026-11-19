begin;
select plan(14);

-- 1. Schema & RPC existence
select has_table('public', 'question_bank_review_events', 'question_bank_review_events table exists');
select has_function(
  'public',
  'save_exam_v2_question',
  ARRAY['text','uuid','uuid','uuid','uuid','text','text','jsonb','jsonb','jsonb','numeric','text','text','text','text','text','text','uuid'],
  'save_exam_v2_question exists'
);
select has_function(
  'public',
  'list_exam_v2_questions',
  ARRAY['text','uuid','uuid','uuid','uuid','text','text','text','text','integer','integer'],
  'list_exam_v2_questions exists'
);
select has_function(
  'public',
  'transition_exam_v2_question_status',
  ARRAY['uuid','text','text'],
  'transition_exam_v2_question_status exists'
);

-- Ephemeral test identities (rolled back cleanly)
insert into auth.users (
  id, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at, aud, role
) values
  (
    '00000000-0000-0000-0000-000000000871',
    'qbank_author@learntz.test', '', now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"full_name":"QBank Author"}'::jsonb, now(), now(), 'authenticated', 'authenticated'
  ),
  (
    '00000000-0000-0000-0000-000000000872',
    'qbank_reviewer@learntz.test', '', now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"full_name":"QBank Reviewer"}'::jsonb, now(), now(), 'authenticated', 'authenticated'
  ),
  (
    '00000000-0000-0000-0000-000000000873',
    'qbank_parent@learntz.test', '', now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"full_name":"QBank Parent"}'::jsonb, now(), now(), 'authenticated', 'authenticated'
  )
on conflict (id) do nothing;

insert into public.user_roles (user_id, role, country_code) values
  ('00000000-0000-0000-0000-000000000871', 'content_author', 'TZ'),
  ('00000000-0000-0000-0000-000000000872', 'academic_reviewer', 'TZ'),
  ('00000000-0000-0000-0000-000000000873', 'parent', null)
on conflict do nothing;

set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000871', true);

-- 2. Reject foreign-subject competency (Math competence on English question)
select throws_matching(
  $$
    select public.save_exam_v2_question(
      'TZ',
      (select el.id from public.education_levels el join public.curricula c on c.id = el.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and el.code = 'PRIMARY' limit 1),
      (select eg.id from public.education_grades eg join public.curricula c on c.id = eg.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and eg.code = 'STANDARD_3' limit 1),
      (select id from public.subjects where code = 'tie-pri-english-standard3' limit 1),
      (select sc.id from public.curriculum_specific_competences sc join public.subjects s on s.id = sc.subject_id where s.code = 'tie-pri-mathematics-standard3' limit 1),
      'multiple_choice',
      'What is 2 + 2?',
      '{"answer":"B"}'::jsonb,
      '["3","4","5","6"]'::jsonb
    );
  $$,
  'Competency mismatch',
  'Rejects Mathematics specific competence attached to English Language question'
);

-- 3. Author creates Standard III English multiple_choice question
select is(
  public.save_exam_v2_question(
    'TZ',
    (select el.id from public.education_levels el join public.curricula c on c.id = el.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and el.code = 'PRIMARY' limit 1),
    (select eg.id from public.education_grades eg join public.curricula c on c.id = eg.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and eg.code = 'STANDARD_3' limit 1),
    (select id from public.subjects where code = 'tie-pri-english-standard3' limit 1),
    (select sc.id from public.curriculum_specific_competences sc join public.subjects s on s.id = sc.subject_id where s.code = 'tie-pri-english-standard3' and sc.code = '1.1' limit 1),
    'multiple_choice',
    'Choose the opposite of the word "big":',
    '{"answer":"Small"}'::jsonb,
    '["Tall","Small","Long","Wide"]'::jsonb,
    '{}'::jsonb,
    2, 'easy', 'knowledge', 'en',
    'Small is the antonym of big.',
    'TIE Standard III English Unit 1',
    'LearnTZ Original'
  ) ->> 'review_status',
  'draft',
  'Author saves Standard III English multiple_choice question as draft'
);

-- 4. Author creates manual-marking writing question with rubric
select is(
  public.save_exam_v2_question(
    'TZ',
    (select el.id from public.education_levels el join public.curricula c on c.id = el.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and el.code = 'PRIMARY' limit 1),
    (select eg.id from public.education_grades eg join public.curricula c on c.id = eg.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and eg.code = 'STANDARD_3' limit 1),
    (select id from public.subjects where code = 'tie-pri-english-standard3' limit 1),
    (select sc.id from public.curriculum_specific_competences sc join public.subjects s on s.id = sc.subject_id where s.code = 'tie-pri-english-standard3' and sc.code = '1.2' limit 1),
    'writing',
    'Write three simple sentences describing your school.',
    '{}'::jsonb,
    '[]'::jsonb,
    '{"criteria":[{"label":"Grammar & punctuation","marks":3},{"label":"Relevance","marks":3}]}'::jsonb,
    6, 'medium', 'application', 'en',
    'Award marks for complete sentences with capital letters and full stops.',
    'TIE Standard III English Unit 2',
    'LearnTZ Original'
  ) ->> 'is_published',
  'false',
  'Writing question with marking rubric stays unpublished until approved'
);

-- 5. Author submits MCQ for review & cannot self-approve
select is(
  public.transition_exam_v2_question_status(
    (select id from public.question_bank where question_text = 'Choose the opposite of the word "big":' limit 1),
    'submit_for_review',
    'Ready for review'
  ) ->> 'review_status',
  'in_review',
  'Author submits question for academic review'
);

select throws_matching(
  $$
    select public.transition_exam_v2_question_status(
      (select id from public.question_bank where question_text = 'Choose the opposite of the word "big":' limit 1),
      'approve',
      'Self approve attempt'
    );
  $$,
  'Permission denied',
  'Author cannot self-approve their own question'
);

-- 6. Reviewer requests revision -> Author resubmits -> Reviewer approves
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000872', true);

select is(
  public.transition_exam_v2_question_status(
    (select id from public.question_bank where question_text = 'Choose the opposite of the word "big":' limit 1),
    'request_revision',
    'Verify option capitalization.'
  ) ->> 'review_status',
  'revision_requested',
  'Reviewer can request revision with comment'
);

select is(
  public.transition_exam_v2_question_status(
    (select id from public.question_bank where question_text = 'Choose the opposite of the word "big":' limit 1),
    'approve',
    'Verified against TIE Standard III English 1.1.'
  ) ->> 'is_published',
  'true',
  'Reviewer approves question and publishes it to approved bank'
);

-- 7. Staff sees correct_answer in list_exam_v2_questions
select is(
  (
    public.list_exam_v2_questions(
      'TZ', null, null,
      (select id from public.subjects where code = 'tie-pri-english-standard3' limit 1),
      null, 'multiple_choice', null, 'approved', 'opposite of the word', 10, 0
    ) -> 'items' -> 0 -> 'correct_answer' ->> 'answer'
  ),
  'Small',
  'Authorized staff receives answer key in Question Bank 2.0'
);

-- 8. SECURITY: Non-staff (parent/learner) NEVER receives correct_answer!
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000873', true);

select is(
  (
    public.list_exam_v2_questions(
      'TZ', null, null,
      (select id from public.subjects where code = 'tie-pri-english-standard3' limit 1),
      null, 'multiple_choice', null, 'approved', 'opposite of the word', 10, 0
    ) -> 'items' -> 0 ->> 'correct_answer'
  ),
  null,
  'SECURITY: Non-staff caller NEVER receives correct_answer from Question Bank RPC'
);

-- 9. Audit log immutability
reset role;
select throws_matching(
  $$
    delete from public.question_bank_review_events
    where question_id = (select id from public.question_bank where question_text = 'Choose the opposite of the word "big":' limit 1);
  $$,
  'Immutable audit log violation',
  'DELETE on question_bank_review_events is blocked by immutability trigger'
);

select * from finish();
rollback;
