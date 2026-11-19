begin;
select plan(12);

select has_table('public', 'examination_questions', 'examination_questions table exists');
select has_function('public', 'add_exam_v2_paper_question', ARRAY['uuid','uuid','uuid','numeric'], 'add_exam_v2_paper_question exists');
select has_function('public', 'reorder_exam_v2_paper_questions', ARRAY['uuid','uuid','uuid[]'], 'reorder_exam_v2_paper_questions exists');
select has_function('public', 'remove_exam_v2_paper_question', ARRAY['uuid'], 'remove_exam_v2_paper_question exists');
select has_function('public', 'get_exam_v2_paper_builder', ARRAY['uuid'], 'get_exam_v2_paper_builder exists');

-- Ephemeral identities
insert into auth.users (
  id, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at, aud, role
) values
  (
    '00000000-0000-0000-0000-000000000861',
    'paper_author@learntz.test', '', now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"full_name":"Paper Author"}'::jsonb, now(), now(), 'authenticated', 'authenticated'
  )
on conflict (id) do nothing;

insert into public.user_roles (user_id, role, country_code) values
  ('00000000-0000-0000-0000-000000000861', 'content_author', 'TZ')
on conflict do nothing;

set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000861', true);

-- Setup: Create an English Std III Terminal Examination + 2 English questions + 1 Math question
do $$
declare
  v_lvl uuid;
  v_grd uuid;
  v_eng uuid;
  v_math uuid;
  v_type uuid;
  v_sc_eng uuid;
  v_sc_math uuid;
begin
  select el.id into v_lvl from public.education_levels el join public.curricula c on c.id = el.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and el.code = 'PRIMARY' limit 1;
  select eg.id into v_grd from public.education_grades eg join public.curricula c on c.id = eg.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and eg.code = 'STANDARD_3' limit 1;
  select id into v_eng from public.subjects where code = 'tie-pri-english-standard3' limit 1;
  select id into v_math from public.subjects where code = 'tie-pri-mathematics-standard3' limit 1;
  select id into v_type from public.examination_types where country_code = 'TZ' and code = 'TERMINAL' limit 1;
  select sc.id into v_sc_eng from public.curriculum_specific_competences sc where sc.subject_id = v_eng order by sc.display_order limit 1;
  select sc.id into v_sc_math from public.curriculum_specific_competences sc where sc.subject_id = v_math order by sc.display_order limit 1;

  perform public.save_exam_v2_examination(
    'TZ', v_lvl, v_grd, v_eng, v_type,
    'PaperBuilder Test: English Terminal',
    2026, 'Term I', null, 90, 'en', 'Read carefully.', 'hybrid',
    '[{"section_code":"A","title":"Multiple Choice","question_format":"multiple_choice","question_count":2,"marks_allocated":4,"display_order":1}]'::jsonb,
    jsonb_build_array(jsonb_build_object('specific_competence_id', v_sc_eng, 'allocated_marks', 4))
  );

  perform public.save_exam_v2_question(
    'TZ', v_lvl, v_grd, v_eng, v_sc_eng,
    'multiple_choice', 'PB_Q1: The opposite of big is:', '{"answer":"Small"}'::jsonb, '["Tall","Small","Long","Wide"]'::jsonb, '{}'::jsonb, 2
  );

  perform public.save_exam_v2_question(
    'TZ', v_lvl, v_grd, v_eng, v_sc_eng,
    'fill_in_the_blank', 'PB_Q2: The sun rises in the ____.', '{"answer":"east"}'::jsonb, '[]'::jsonb, '{}'::jsonb, 3
  );

  perform public.save_exam_v2_question(
    'TZ', v_lvl, v_grd, v_math, v_sc_math,
    'short_answer', 'PB_MATH: What is 5 + 7?', '{"answer":"12"}'::jsonb, '[]'::jsonb, '{}'::jsonb, 2
  );
end $$;

-- 1. Cross-subject question attachment is rejected
select throws_matching(
  $$
    select public.add_exam_v2_paper_question(
      (select id from public.examinations where title = 'PaperBuilder Test: English Terminal' limit 1),
      (select es.id from public.examination_sections es join public.examinations e on e.id = es.examination_id where e.title = 'PaperBuilder Test: English Terminal' limit 1),
      (select id from public.question_bank where question_text = 'PB_MATH: What is 5 + 7?' limit 1),
      null
    );
  $$,
  'Question subject mismatch',
  'Rejects attaching a Mathematics question to an English Language examination paper'
);

-- 2. Attach Q1 (2 marks) and Q2 (3 marks) -> auto-recalculates total_marks = 5
select is(
  (
    public.add_exam_v2_paper_question(
      (select id from public.examinations where title = 'PaperBuilder Test: English Terminal' limit 1),
      (select es.id from public.examination_sections es join public.examinations e on e.id = es.examination_id where e.title = 'PaperBuilder Test: English Terminal' limit 1),
      (select id from public.question_bank where question_text = 'PB_Q1: The opposite of big is:' limit 1),
      null
    ) ->> 'total_marks'
  )::numeric,
  2::numeric,
  'Attaching first question updates total_marks to 2'
);

select is(
  (
    public.add_exam_v2_paper_question(
      (select id from public.examinations where title = 'PaperBuilder Test: English Terminal' limit 1),
      (select es.id from public.examination_sections es join public.examinations e on e.id = es.examination_id where e.title = 'PaperBuilder Test: English Terminal' limit 1),
      (select id from public.question_bank where question_text = 'PB_Q2: The sun rises in the ____.' limit 1),
      null
    ) ->> 'total_marks'
  )::numeric,
  5::numeric,
  'Attaching second question auto-recalculates total_marks = 2 + 3 = 5'
);

-- 3. Snapshot immutability: editing original question_bank item does NOT mutate examination_questions snapshot
update public.question_bank
set question_text = 'EDITED IN BANK LATER'
where question_text = 'PB_Q1: The opposite of big is:';

select is(
  (
    select eq.question_text
    from public.examination_questions eq
    join public.examinations e on e.id = eq.examination_id
    where e.title = 'PaperBuilder Test: English Terminal'
      and eq.question_number = 1
    limit 1
  ),
  'PB_Q1: The opposite of big is:',
  'Versioned snapshot in examination_questions is unaffected by later edits to question_bank'
);

-- 4. Reordering swaps Q2 to question_number 1 and Q1 to question_number 2
select lives_ok(
  $$
    select public.reorder_exam_v2_paper_questions(
      (select id from public.examinations where title = 'PaperBuilder Test: English Terminal' limit 1),
      (select es.id from public.examination_sections es join public.examinations e on e.id = es.examination_id where e.title = 'PaperBuilder Test: English Terminal' limit 1),
      array[
        (select eq.id from public.examination_questions eq join public.examinations e on e.id = eq.examination_id where e.title = 'PaperBuilder Test: English Terminal' and eq.question_text like 'PB_Q2%' limit 1),
        (select eq.id from public.examination_questions eq join public.examinations e on e.id = eq.examination_id where e.title = 'PaperBuilder Test: English Terminal' and eq.question_text like 'PB_Q1%' limit 1)
      ]
    );
  $$,
  'reorder_exam_v2_paper_questions reorders questions cleanly'
);

select is(
  (
    public.get_exam_v2_paper_builder(
      (select id from public.examinations where title = 'PaperBuilder Test: English Terminal' limit 1)
    ) -> 'sections' -> 0 -> 'questions' -> 0 ->> 'question_text'
  ),
  'PB_Q2: The sun rises in the ____.',
  'After reorder, PB_Q2 is now first in Section A with question_number 1'
);

-- 5. Removing Q2 leaves Q1 with question_number = 1 and total_marks = 2
select is(
  (
    public.remove_exam_v2_paper_question(
      (select eq.id from public.examination_questions eq join public.examinations e on e.id = eq.examination_id where e.title = 'PaperBuilder Test: English Terminal' and eq.question_text like 'PB_Q2%' limit 1)
    ) ->> 'total_marks'
  )::numeric,
  2::numeric,
  'Removing a question renumbers remaining items and recalculates total_marks = 2'
);

select * from finish();
rollback;
