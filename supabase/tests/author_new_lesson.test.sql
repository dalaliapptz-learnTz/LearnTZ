begin;
select plan(28);

-- 1. Verify schema objects & functions exist
select has_table('public', 'curriculum_main_competences', 'curriculum_main_competences table exists');
select has_table('public', 'curriculum_specific_competences', 'curriculum_specific_competences table exists');
select has_table('public', 'lesson_review_events', 'lesson_review_events table exists');
select has_function('public', 'get_lesson_authoring_context', ARRAY['text', 'uuid', 'uuid', 'uuid', 'uuid'], 'get_lesson_authoring_context exists');
select has_function('public', 'get_authoring_grades', ARRAY['uuid', 'uuid'], 'get_authoring_grades exists');
select has_function('public', 'get_authoring_subjects', ARRAY['uuid', 'uuid', 'uuid'], 'get_authoring_subjects exists');
select has_function('public', 'get_authoring_main_competences', ARRAY['uuid'], 'get_authoring_main_competences exists');
select has_function('public', 'get_authoring_specific_competences', ARRAY['uuid'], 'get_authoring_specific_competences exists');
select has_function('public', 'transition_lesson_workflow', ARRAY['uuid', 'text', 'text'], 'transition_lesson_workflow exists');

-- Create ephemeral test identities inside transaction (rolled back at end)
insert into auth.users (
  id, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at, aud, role
) values
  (
    '00000000-0000-0000-0000-000000000971',
    'author_test@learntz.test', '', now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"full_name":"Test Content Author"}'::jsonb, now(), now(), 'authenticated', 'authenticated'
  ),
  (
    '00000000-0000-0000-0000-000000000972',
    'reviewer_test@learntz.test', '', now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"full_name":"Test Academic Reviewer"}'::jsonb, now(), now(), 'authenticated', 'authenticated'
  ),
  (
    '00000000-0000-0000-0000-000000000973',
    'publisher_test@learntz.test', '', now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"full_name":"Test Curriculum Admin"}'::jsonb, now(), now(), 'authenticated', 'authenticated'
  ),
  (
    '00000000-0000-0000-0000-000000000974',
    'parent_test@learntz.test', '', now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"full_name":"Test Parent User"}'::jsonb, now(), now(), 'authenticated', 'authenticated'
  )
on conflict (id) do nothing;

insert into public.user_roles (user_id, role, country_code) values
  ('00000000-0000-0000-0000-000000000971', 'content_author', 'TZ'),
  ('00000000-0000-0000-0000-000000000972', 'academic_reviewer', 'TZ'),
  ('00000000-0000-0000-0000-000000000973', 'curriculum_admin', 'TZ'),
  ('00000000-0000-0000-0000-000000000974', 'parent', null)
on conflict do nothing;

-- Verify official TIE competences were backfilled without invention
select cmp_ok(
  (
    select count(*)::int
    from public.curriculum_main_competences mc
    join public.subjects s on s.id = mc.subject_id
    where s.code = 'tie-pri-english-standard3'
  ),
  '=',
  3,
  'TC-05: Standard 3 English has exact 3 official TIE main competences (1.0, 2.0, 3.0)'
);

select cmp_ok(
  (
    select count(*)::int
    from public.curriculum_specific_competences sc
    join public.subjects s on s.id = sc.subject_id
    where s.code = 'tie-pri-english-standard3'
  ),
  '=',
  5,
  'TC-06: Standard 3 English has exact 5 official TIE specific competences'
);

-- Switch to Content Author session
set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000971', true);

-- TC-03: Grade dropdown loads actual DB records
select cmp_ok(
  jsonb_array_length(
    public.get_authoring_grades(
      '20000000-0000-0000-0000-000000000002'::uuid,
      '20000000-0000-0000-0000-000000000010'::uuid
    )
  ),
  '>=',
  6,
  'TC-03: get_authoring_grades returns real TIE primary grades from DB'
);

-- TC-04: Subject dropdown filters strictly by selected grade
select cmp_ok(
  jsonb_array_length(
    public.get_authoring_subjects(
      '20000000-0000-0000-0000-000000000002'::uuid,
      (select id from public.education_grades where curriculum_id = '20000000-0000-0000-0000-000000000002' and code = 'STANDARD_3' limit 1),
      '20000000-0000-0000-0000-000000000010'::uuid
    )
  ),
  '>=',
  3,
  'TC-04: get_authoring_subjects returns Standard 3 grade-scoped subjects (English, Mathematics, Science)'
);

-- TC-09: Invalid curriculum relationship (Standard 4 grade paired with Standard 3 subject) is rejected by backend
select throws_matching(
  $$
    select public.save_authored_lesson(
      'TZ',
      '20000000-0000-0000-0000-000000000002'::uuid,
      (select id from public.curriculum_versions where version_code = 'TIE_PRIMARY_2023' limit 1),
      '20000000-0000-0000-0000-000000000010'::uuid,
      (select id from public.education_grades where curriculum_id = '20000000-0000-0000-0000-000000000002' and code = 'STANDARD_4' limit 1),
      (select id from public.subjects where code = 'tie-pri-english-standard3' limit 1),
      (select mc.id from public.curriculum_main_competences mc join public.subjects s on s.id = mc.subject_id where s.code = 'tie-pri-english-standard3' and mc.code = '1.0' limit 1),
      (select sc.id from public.curriculum_specific_competences sc join public.subjects s on s.id = sc.subject_id where s.code = 'tie-pri-english-standard3' and sc.code = '1.1' limit 1),
      (select sc.topic_id from public.curriculum_specific_competences sc join public.subjects s on s.id = sc.subject_id where s.code = 'tie-pri-english-standard3' and sc.code = '1.1' limit 1),
      'Mismatched Grade Lesson',
      'Body content for mismatch test'
    );
  $$,
  'Curriculum alignment error',
  'TC-09: Backend rejects mismatched grade and subject relationship'
);

-- TC-10 & TC-11: Author saves valid draft lesson with real foreign keys and it stays unpublished
select is(
  (
    select (
      public.save_authored_lesson(
        'TZ',
        '20000000-0000-0000-0000-000000000002'::uuid,
        (select id from public.curriculum_versions where version_code = 'TIE_PRIMARY_2023' limit 1),
        '20000000-0000-0000-0000-000000000010'::uuid,
        (select id from public.education_grades where curriculum_id = '20000000-0000-0000-0000-000000000002' and code = 'STANDARD_3' limit 1),
        (select id from public.subjects where code = 'tie-pri-english-standard3' limit 1),
        (select mc.id from public.curriculum_main_competences mc join public.subjects s on s.id = mc.subject_id where s.code = 'tie-pri-english-standard3' and mc.code = '1.0' limit 1),
        (select sc.id from public.curriculum_specific_competences sc join public.subjects s on s.id = sc.subject_id where s.code = 'tie-pri-english-standard3' and sc.code = '1.1' limit 1),
        (select sc.topic_id from public.curriculum_specific_competences sc join public.subjects s on s.id = sc.subject_id where s.code = 'tie-pri-english-standard3' and sc.code = '1.1' limit 1),
        'Listening to Simple Stories at Home and School',
        '# Listening to Simple Stories\n\nLearners practise listening carefully and writing dictated familiar words accurately.',
        (select st.id from public.subtopics st join public.topics t on t.id = st.topic_id join public.subjects s on s.id = t.subject_id where s.code = 'tie-pri-english-standard3' and t.competency_code = '1.1' order by st.display_order limit 1),
        'Guided listening and dictation lesson aligned to TIE Standard 3 Specific Competence 1.1.',
        25,
        'en',
        'standard',
        'core_instruction',
        false,
        '["Listen attentively to dictated familiar words", "Answer comprehension questions from a short story"]'::jsonb,
        '[{"id":"lo-1","outcome":"Write 10 dictated familiar words with at least 80% accuracy","cognitive_level":"application","assessable":true}]'::jsonb,
        '[{"id":"b1","type":"heading","title":"Listening Warm-up","content":"Prepare learners to listen closely."},{"id":"b2","type":"text_explanation","title":"Core Explanation","content":"Careful listening helps identify letter sounds and word boundaries."}]'::jsonb,
        '[{"id":"a1","title":"Dictation Practice","activity_type":"individual","estimated_minutes":10,"learning_objective":"Write dictated words","materials":"Exercise book, pencil","instructions":"Listen and write each word spoken twice.","expected_response":"Accurate spelling of familiar words","assessment_criteria":"Dictated words are written correctly"}]'::jsonb,
        'Dictated words are written correctly',
        'Initial draft created'
      )
    )->>'is_published'
  ),
  'false',
  'TC-10 & TC-11: Saved lesson draft has valid foreign keys and remains unpublished'
);

-- TC-17: Author attaches an oral_response question to the lesson in question_bank
select lives_ok(
  $$
    select public.upsert_lesson_assessment_question(
      (select id from public.lessons where title = 'Listening to Simple Stories at Home and School' limit 1),
      'oral_response',
      'Retell two events from the school story in your own words.',
      '{"expected_points":["Setting","Main event"]}'::jsonb,
      '[]'::jsonb,
      'Check pronunciation and story sequence.',
      4,
      'easy',
      'lo-1',
      'Questions on simple stories are responded to correctly'
    );
  $$,
  'TC-17: Author adds oral_response assessment question to existing question_bank'
);

-- TC-14: Media asset registration defaults to copyright_cleared = false and pending_review
select is(
  (
    select (
      public.register_lesson_media_asset(
        'Standard 3 Listening Audio Prompt',
        'TZ',
        'audio',
        'lesson-media/tz/std3-listening.mp3',
        (select id from public.subjects where code = 'tie-pri-english-standard3' limit 1),
        'Slow-paced dictation audio for Standard 3',
        'lesson-media',
        'tz/std3-listening.mp3',
        'audio/mpeg',
        512000,
        'Original LearnTZ Studio Recording',
        'unverified',
        'LearnTZ Audio Team',
        'Audio recording of 10 familiar Standard 3 words',
        'Word 1: book. Word 2: desk...'
      )
    )->>'copyright_cleared'
  ),
  'false',
  'TC-14: Registered media asset never assumes copyright_cleared = true'
);

-- Author submits draft for academic review
select is(
  (
    select (
      public.transition_lesson_workflow(
        (select id from public.lessons where title = 'Listening to Simple Stories at Home and School' limit 1),
        'submit_for_review',
        'Ready for academic review'
      )
    )->>'status'
  ),
  'in_review',
  'Author submits completed draft for academic review'
);

-- TC-13: Author CANNOT approve or publish their own lesson
select throws_matching(
  $$
    select public.transition_lesson_workflow(
      (select id from public.lessons where title = 'Listening to Simple Stories at Home and School' limit 1),
      'approve',
      'Self-approval attempt'
    );
  $$,
  'Permission denied',
  'TC-13: Content author cannot approve lesson'
);

-- TC-18: Unauthorized parent user cannot see unpublished lesson or call authoring RPCs
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000974', true);

select is(
  (select count(*)::int from public.lessons where title = 'Listening to Simple Stories at Home and School'),
  0,
  'TC-18: Parent/learner cannot see unpublished draft/in_review lesson via RLS'
);

select throws_matching(
  $$
    select public.get_authoring_grades('20000000-0000-0000-0000-000000000002'::uuid, null);
  $$,
  'Permission denied',
  'TC-18: Unauthorized user is blocked from authoring dropdown RPCs'
);

-- TC-12: Academic Reviewer requests revision with feedback
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000972', true);

select is(
  (
    select (
      public.transition_lesson_workflow(
        (select id from public.lessons where title = 'Listening to Simple Stories at Home and School' limit 1),
        'request_revision',
        'Please add a worked example block before the dictation activity.'
      )
    )->>'status'
  ),
  'revision_requested',
  'TC-12: Academic reviewer can request revisions with comments'
);

-- Author updates draft (creates version 2) and re-submits for review
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000971', true);

select is(
  (
    select (
      public.save_authored_lesson(
        'TZ',
        '20000000-0000-0000-0000-000000000002'::uuid,
        (select id from public.curriculum_versions where version_code = 'TIE_PRIMARY_2023' limit 1),
        '20000000-0000-0000-0000-000000000010'::uuid,
        (select id from public.education_grades where curriculum_id = '20000000-0000-0000-0000-000000000002' and code = 'STANDARD_3' limit 1),
        (select id from public.subjects where code = 'tie-pri-english-standard3' limit 1),
        (select mc.id from public.curriculum_main_competences mc join public.subjects s on s.id = mc.subject_id where s.code = 'tie-pri-english-standard3' and mc.code = '1.0' limit 1),
        (select sc.id from public.curriculum_specific_competences sc join public.subjects s on s.id = sc.subject_id where s.code = 'tie-pri-english-standard3' and sc.code = '1.1' limit 1),
        (select sc.topic_id from public.curriculum_specific_competences sc join public.subjects s on s.id = sc.subject_id where s.code = 'tie-pri-english-standard3' and sc.code = '1.1' limit 1),
        'Listening to Simple Stories at Home and School',
        '# Listening to Simple Stories\n\nIncludes worked example before dictation.',
        null,
        'Revised lesson with worked example.',
        25,
        'en',
        'standard',
        'core_instruction',
        false,
        '["Listen attentively to dictated familiar words"]'::jsonb,
        '[{"id":"lo-1","outcome":"Write 10 dictated familiar words with at least 80% accuracy","cognitive_level":"application","assessable":true}]'::jsonb,
        '[{"id":"b1","type":"worked_example","title":"Worked Dictation Example","content":"Listen to the word: school -> s-c-h-o-o-l."}]'::jsonb,
        '[]'::jsonb,
        'Dictated words are written correctly',
        'Added worked example per reviewer feedback',
        (select id from public.lessons where title = 'Listening to Simple Stories at Home and School' limit 1)
      )
    )->>'version_number'
  ),
  '2',
  'TC-19: Revising draft increments version_number to 2 and preserves version history'
);

select lives_ok(
  $$
    select public.transition_lesson_workflow(
      (select id from public.lessons where title = 'Listening to Simple Stories at Home and School' limit 1),
      'submit_for_review',
      'Resubmitted after adding worked example'
    );
  $$,
  'Author resubmits revised draft for review'
);

-- Academic reviewer approves, but CANNOT publish
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000972', true);

select is(
  (
    select (
      public.transition_lesson_workflow(
        (select id from public.lessons where title = 'Listening to Simple Stories at Home and School' limit 1),
        'approve',
        'Pedagogically sound and TIE-aligned.'
      )
    )->>'status'
  ),
  'approved',
  'TC-13: Academic reviewer approves submitted lesson'
);

select throws_matching(
  $$
    select public.transition_lesson_workflow(
      (select id from public.lessons where title = 'Listening to Simple Stories at Home and School' limit 1),
      'publish',
      'Reviewer attempting to publish'
    );
  $$,
  'Permission denied',
  'TC-13: Academic reviewer without publishing role cannot publish lesson'
);

-- Curriculum Admin publishes approved lesson & version history is preserved
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000973', true);

select is(
  (
    select (
      public.transition_lesson_workflow(
        (select id from public.lessons where title = 'Listening to Simple Stories at Home and School' limit 1),
        'publish',
        'Approved for learner delivery'
      )
    )->>'is_published'
  ),
  'true',
  'TC-13: Curriculum Admin publishes approved lesson'
);

select cmp_ok(
  (
    select count(*)::int
    from public.lesson_revisions
    where lesson_id = (select id from public.lessons where title = 'Listening to Simple Stories at Home and School' limit 1)
  ),
  '=',
  2,
  'TC-19: Published lesson retains full revision history (2 versions)'
);

select * from finish();
rollback;
