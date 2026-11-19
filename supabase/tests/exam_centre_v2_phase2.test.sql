begin;
select plan(20);

-- 1. Schema & RPC checks
select has_table('public', 'examinations', 'examinations table exists');
select has_table('public', 'examination_sections', 'examination_sections table exists');
select has_table('public', 'examination_competencies', 'examination_competencies table exists');
select has_table('public', 'examination_review_events', 'examination_review_events table exists');

-- Ephemeral test identities (rolled back cleanly)
insert into auth.users (
  id, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at, aud, role
) values
  (
    '00000000-0000-0000-0000-000000000881',
    'exam_v2_author@learntz.test', '', now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"full_name":"Exam V2 Author"}'::jsonb, now(), now(), 'authenticated', 'authenticated'
  ),
  (
    '00000000-0000-0000-0000-000000000882',
    'exam_v2_reviewer@learntz.test', '', now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"full_name":"Exam V2 Reviewer"}'::jsonb, now(), now(), 'authenticated', 'authenticated'
  ),
  (
    '00000000-0000-0000-0000-000000000883',
    'exam_v2_admin@learntz.test', '', now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"full_name":"Exam V2 Curriculum Admin"}'::jsonb, now(), now(), 'authenticated', 'authenticated'
  ),
  (
    '00000000-0000-0000-0000-000000000884',
    'exam_v2_parent@learntz.test', '', now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"full_name":"Exam V2 Parent"}'::jsonb, now(), now(), 'authenticated', 'authenticated'
  )
on conflict (id) do nothing;

insert into public.user_roles (user_id, role, country_code) values
  ('00000000-0000-0000-0000-000000000881', 'content_author', 'TZ'),
  ('00000000-0000-0000-0000-000000000882', 'academic_reviewer', 'TZ'),
  ('00000000-0000-0000-0000-000000000883', 'curriculum_admin', 'TZ'),
  ('00000000-0000-0000-0000-000000000884', 'parent', null)
on conflict do nothing;

-- 2. Unauthorized parent cannot create an examination
set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000884', true);

select throws_matching(
  $$
    select public.save_exam_v2_examination(
      'TZ',
      (select el.id from public.education_levels el join public.curricula c on c.id = el.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and el.code = 'PRIMARY' limit 1),
      (select eg.id from public.education_grades eg join public.curricula c on c.id = eg.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and eg.code = 'STANDARD_3' limit 1),
      (select id from public.subjects where code = 'tie-pri-english-standard3' limit 1),
      (select id from public.examination_types where country_code = 'TZ' and code = 'TERMINAL' limit 1),
      'Unauthorized Exam'
    );
  $$,
  'Permission denied',
  'Unauthorized parent role is blocked from creating an examination'
);

-- 3. Switch to Content Author: rejects foreign-subject competency
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000881', true);

select throws_matching(
  $$
    select public.save_exam_v2_examination(
      'TZ',
      (select el.id from public.education_levels el join public.curricula c on c.id = el.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and el.code = 'PRIMARY' limit 1),
      (select eg.id from public.education_grades eg join public.curricula c on c.id = eg.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and eg.code = 'STANDARD_3' limit 1),
      (select id from public.subjects where code = 'tie-pri-english-standard3' limit 1),
      (select id from public.examination_types where country_code = 'TZ' and code = 'TERMINAL' limit 1),
      'Bad Competency Exam',
      2026, 'Term I', null, 90, 'en', 'Read carefully.', 'hybrid',
      '[{"section_code":"A","title":"Section A","question_format":"multiple_choice","question_count":10,"marks_allocated":20}]'::jsonb,
      jsonb_build_array(
        jsonb_build_object(
          'specific_competence_id',
          (select sc.id from public.curriculum_specific_competences sc join public.subjects s on s.id = sc.subject_id where s.code = 'tie-pri-mathematics-standard3' limit 1),
          'allocated_marks', 20
        )
      )
    );
  $$,
  'Competency mismatch',
  'Backend rejects Mathematics competency attached to English Language examination'
);

-- 4. Save incomplete draft (0 sections) -> allowed as draft, blocked on submit_for_review
select is(
  public.save_exam_v2_examination(
    'TZ',
    (select el.id from public.education_levels el join public.curricula c on c.id = el.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and el.code = 'PRIMARY' limit 1),
    (select eg.id from public.education_grades eg join public.curricula c on c.id = eg.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and eg.code = 'STANDARD_3' limit 1),
    (select id from public.subjects where code = 'tie-pri-english-standard3' limit 1),
    (select id from public.examination_types where country_code = 'TZ' and code = 'TERMINAL' limit 1),
    'Incomplete Blueprint Draft',
    2026, 'Term I', null, 90, 'en', 'Read carefully.', 'hybrid',
    '[]'::jsonb, '[]'::jsonb
  ) ->> 'status',
  'draft',
  'Author can save an incomplete examination as a draft'
);

select throws_matching(
  $$
    select public.transition_exam_v2_status(
      (select id from public.examinations where title = 'Incomplete Blueprint Draft' limit 1),
      'submit_for_review',
      'Submitting incomplete'
    );
  $$,
  'Incomplete examination blueprint',
  'Submitting an examination with zero sections/marks is rejected by backend'
);

-- 5. Save complete Standard III English Language Terminal Examination with 3 sections (20+15+15=50 marks) & 2 official TIE competencies
select is(
  (
    public.save_exam_v2_examination(
      'TZ',
      (select el.id from public.education_levels el join public.curricula c on c.id = el.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and el.code = 'PRIMARY' limit 1),
      (select eg.id from public.education_grades eg join public.curricula c on c.id = eg.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and eg.code = 'STANDARD_3' limit 1),
      (select id from public.subjects where code = 'tie-pri-english-standard3' limit 1),
      (select id from public.examination_types where country_code = 'TZ' and code = 'TERMINAL' limit 1),
      'English Language Terminal Examination — Standard III',
      2026, 'Term I', date '2026-06-15', 90, 'en',
      'Read all questions carefully and write neatly.', 'hybrid',
      '[
        {"section_code":"A","title":"Multiple Choice","question_format":"multiple_choice","question_count":10,"marks_allocated":20,"display_order":1},
        {"section_code":"B","title":"Fill in the Blanks","question_format":"fill_in_the_blank","question_count":5,"marks_allocated":15,"display_order":2},
        {"section_code":"C","title":"Short Answers","question_format":"short_answer","question_count":5,"marks_allocated":15,"display_order":3}
      ]'::jsonb,
      (
        select jsonb_agg(jsonb_build_object('specific_competence_id', sc.id, 'allocated_marks', 25, 'target_question_count', 10))
        from (
          select sc.id
          from public.curriculum_specific_competences sc
          join public.subjects s on s.id = sc.subject_id
          where s.code = 'tie-pri-english-standard3'
          order by sc.display_order asc
          limit 2
        ) sc
      )
    ) ->> 'total_marks'
  )::numeric,
  50::numeric,
  'Total marks auto-calculated accurately as sum of blueprint sections (20 + 15 + 15 = 50)'
);

-- 6. Verify list_exam_v2_examinations returns real DB-derived counts & items
select cmp_ok(
  (
    public.list_exam_v2_examinations(
      'TZ',
      (select el.id from public.education_levels el join public.curricula c on c.id = el.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and el.code = 'PRIMARY' limit 1),
      (select eg.id from public.education_grades eg join public.curricula c on c.id = eg.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and eg.code = 'STANDARD_3' limit 1),
      (select id from public.subjects where code = 'tie-pri-english-standard3' limit 1),
      (select id from public.examination_types where country_code = 'TZ' and code = 'TERMINAL' limit 1)
    ) -> 'summary' ->> 'draft_count'
  )::int,
  '>=',
  2,
  'list_exam_v2_examinations returns accurate DB-derived draft counts'
);

-- 7. Verify get_exam_v2_examination_detail returns 3 sections & 2 competencies
select is(
  jsonb_array_length(
    public.get_exam_v2_examination_detail(
      (select id from public.examinations where title = 'English Language Terminal Examination — Standard III' limit 1)
    ) -> 'sections'
  ),
  3,
  'Examination detail returns all 3 blueprint sections'
);

select is(
  jsonb_array_length(
    public.get_exam_v2_examination_detail(
      (select id from public.examinations where title = 'English Language Terminal Examination — Standard III' limit 1)
    ) -> 'competencies'
  ),
  2,
  'Examination detail returns both official TIE specific competencies'
);

-- 8. Author submits complete examination for review
select is(
  public.transition_exam_v2_status(
    (select id from public.examinations where title = 'English Language Terminal Examination — Standard III' limit 1),
    'submit_for_review',
    'Ready for academic review'
  ) ->> 'status',
  'submitted_for_review',
  'Complete examination submits cleanly for academic review'
);

-- 9. Author CANNOT approve own examination
select throws_matching(
  $$
    select public.transition_exam_v2_status(
      (select id from public.examinations where title = 'English Language Terminal Examination — Standard III' limit 1),
      'approve',
      'Self-approval attempt'
    );
  $$,
  'Permission denied',
  'Author cannot approve their own examination'
);

-- 10. Academic Reviewer requests revision -> Author resubmits -> Reviewer approves
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000882', true);

select is(
  public.transition_exam_v2_status(
    (select id from public.examinations where title = 'English Language Terminal Examination — Standard III' limit 1),
    'request_revision',
    'Clarify Section B instructions.'
  ) ->> 'status',
  'revision_requested',
  'Academic reviewer can request revisions with comment'
);

select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000881', true);
select is(
  public.transition_exam_v2_status(
    (select id from public.examinations where title = 'English Language Terminal Examination — Standard III' limit 1),
    'submit_for_review',
    'Updated Section B instructions.'
  ) ->> 'status',
  'submitted_for_review',
  'Author can resubmit revised examination'
);

select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000882', true);
select is(
  public.transition_exam_v2_status(
    (select id from public.examinations where title = 'English Language Terminal Examination — Standard III' limit 1),
    'approve',
    'Curriculum alignment verified.'
  ) ->> 'status',
  'approved',
  'Academic reviewer approves resubmitted examination'
);

-- Reviewer cannot publish without curriculum_admin
select throws_matching(
  $$
    select public.transition_exam_v2_status(
      (select id from public.examinations where title = 'English Language Terminal Examination — Standard III' limit 1),
      'publish',
      'Unauthorized publish'
    );
  $$,
  'Permission denied',
  'Academic reviewer cannot publish examination'
);

-- 11. Curriculum Admin publishes approved examination
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000883', true);
select is(
  public.transition_exam_v2_status(
    (select id from public.examinations where title = 'English Language Terminal Examination — Standard III' limit 1),
    'publish',
    'Published for Standard III Term I.'
  ) ->> 'is_published',
  'true',
  'Curriculum admin publishes approved examination'
);

-- 12. Audit log immutability
reset role;
select throws_matching(
  $$
    update public.examination_review_events
    set comments = 'Tampered'
    where examination_id = (select id from public.examinations where title = 'English Language Terminal Examination — Standard III' limit 1);
  $$,
  'Immutable audit log violation',
  'UPDATE on public.examination_review_events is blocked by immutability trigger'
);

select * from finish();
rollback;
