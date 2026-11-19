begin;
select plan(26);

-- 1. Verify Academic Review Queue RPCs exist
select has_function('public', 'get_academic_review_queue_summary', ARRAY['text'], 'get_academic_review_queue_summary RPC exists');
select has_function(
  'public',
  'list_academic_review_queue',
  ARRAY['text', 'uuid', 'uuid', 'uuid', 'text', 'text', 'uuid', 'boolean', 'integer', 'integer'],
  'list_academic_review_queue RPC exists'
);
select has_function('public', 'assign_lesson_reviewer', ARRAY['uuid', 'uuid'], 'assign_lesson_reviewer RPC exists');

-- Ephemeral test identities (rolled back cleanly at end of transaction)
insert into auth.users (
  id, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at, aud, role
) values
  (
    '00000000-0000-0000-0000-000000000991',
    'queue_author@learntz.test', '', now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"full_name":"Queue Test Author"}'::jsonb, now(), now(), 'authenticated', 'authenticated'
  ),
  (
    '00000000-0000-0000-0000-000000000992',
    'queue_reviewer@learntz.test', '', now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"full_name":"Queue Academic Reviewer"}'::jsonb, now(), now(), 'authenticated', 'authenticated'
  ),
  (
    '00000000-0000-0000-0000-000000000993',
    'queue_admin@learntz.test', '', now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"full_name":"Queue Curriculum Admin"}'::jsonb, now(), now(), 'authenticated', 'authenticated'
  ),
  (
    '00000000-0000-0000-0000-000000000994',
    'queue_parent@learntz.test', '', now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"full_name":"Queue Unauthorized Parent"}'::jsonb, now(), now(), 'authenticated', 'authenticated'
  )
on conflict (id) do nothing;

insert into public.user_roles (user_id, role, country_code) values
  ('00000000-0000-0000-0000-000000000991', 'content_author', 'TZ'),
  ('00000000-0000-0000-0000-000000000992', 'academic_reviewer', 'TZ'),
  ('00000000-0000-0000-0000-000000000993', 'curriculum_admin', 'TZ'),
  ('00000000-0000-0000-0000-000000000994', 'parent', null)
on conflict do nothing;

-- ============================================================================
-- 2. RBAC Enforcement: Unauthorized parent and plain content_author are blocked
-- ============================================================================
set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000994', true);

select throws_matching(
  $$ select public.get_academic_review_queue_summary('TZ'); $$,
  'Permission denied',
  'Parent role is blocked from get_academic_review_queue_summary'
);

select throws_matching(
  $$ select public.list_academic_review_queue('TZ'); $$,
  'Permission denied',
  'Parent role is blocked from list_academic_review_queue'
);

select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000991', true);

select throws_matching(
  $$ select public.get_academic_review_queue_summary('TZ'); $$,
  'Permission denied',
  'Plain content_author is blocked from Academic Review Queue summary'
);

select throws_matching(
  $$ select public.list_academic_review_queue('TZ'); $$,
  'Permission denied',
  'Plain content_author is blocked from listing Academic Review Queue'
);

-- ============================================================================
-- 3. Author creates 2 real lessons (Math Std IV + Science Std V) & submits both
-- ============================================================================
do $$
declare
  v_cur_id uuid;
  v_ver_id uuid;
  v_lvl_id uuid;
  v_g4_id uuid;
  v_g5_id uuid;
  v_math_s4 uuid;
  v_sci_s5 uuid;
  v_res1 jsonb;
  v_res2 jsonb;
begin
  select id into v_cur_id from public.curricula where country_code = 'TZ' and code = 'TIE' limit 1;
  select id into v_ver_id from public.curriculum_versions where version_code = 'TIE_PRIMARY_2023' limit 1;
  select id into v_lvl_id from public.education_levels where curriculum_id = v_cur_id and code = 'PRIMARY' limit 1;
  select id into v_g4_id from public.education_grades where curriculum_id = v_cur_id and code = 'STANDARD_4' limit 1;
  select id into v_g5_id from public.education_grades where curriculum_id = v_cur_id and code = 'STANDARD_5' limit 1;
  select id into v_math_s4 from public.subjects where code = 'tie-pri-mathematics-standard4' limit 1;
  select id into v_sci_s5 from public.subjects where code = 'tie-pri-science-standard5' limit 1;

  v_res1 := public.save_authored_lesson(
    'TZ', v_cur_id, v_ver_id, v_lvl_id, v_g4_id, v_math_s4,
    (select id from public.curriculum_main_competences where subject_id = v_math_s4 and code = '1.0' limit 1),
    (select id from public.curriculum_specific_competences where subject_id = v_math_s4 and code = '1.2' limit 1),
    (select topic_id from public.curriculum_specific_competences where subject_id = v_math_s4 and code = '1.2' limit 1),
    'QueueTest: Adding and Subtracting Fractions',
    '# Fractions\n\nLearners add and subtract fractions with like denominators.',
    null,
    'Guided Standard IV Mathematics lesson on fractions.',
    35, 'en', 'standard', 'core_instruction', false,
    '["Add fractions with like denominators", "Subtract fractions with like denominators"]'::jsonb,
    '[{"id":"lo-1","outcome":"Solve 8/10 fraction addition and subtraction problems accurately","cognitive_level":"application","assessable":true}]'::jsonb,
    '[{"id":"b1","type":"heading","title":"Understanding Fractions","content":"Review numerator and denominator."},{"id":"b2","type":"worked_example","title":"Worked Example","content":"2/7 + 3/7 = 5/7."}]'::jsonb,
    '[{"id":"a1","title":"Fraction Strip Practice","activity_type":"pair","estimated_minutes":10,"learning_objective":"Add like fractions","materials":"Fraction strips","instructions":"Combine strips and record sums.","expected_response":"Correct fraction sums","assessment_criteria":"Fractions are added correctly"}]'::jsonb,
    'Fractions with like denominators are added and subtracted accurately',
    'Initial Math draft'
  );

  v_res2 := public.save_authored_lesson(
    'TZ', v_cur_id, v_ver_id, v_lvl_id, v_g5_id, v_sci_s5,
    (select id from public.curriculum_main_competences where subject_id = v_sci_s5 and code = '1.0' limit 1),
    (select id from public.curriculum_specific_competences where subject_id = v_sci_s5 and code = '1.1' limit 1),
    (select topic_id from public.curriculum_specific_competences where subject_id = v_sci_s5 and code = '1.1' limit 1),
    'QueueTest: States of Matter and Physical Changes',
    '# Matter\n\nLearners investigate solids, liquids, and gases.',
    null,
    'Guided Standard V Science lesson on states of matter.',
    40, 'en', 'standard', 'core_instruction', false,
    '["Identify properties of solids, liquids, and gases", "Explain melting and evaporation"]'::jsonb,
    '[{"id":"lo-1","outcome":"Classify everyday materials into three states of matter","cognitive_level":"comprehension","assessable":true}]'::jsonb,
    '[{"id":"b1","type":"heading","title":"Three States of Matter","content":"Observe water as ice, liquid, and steam."}]'::jsonb,
    '[{"id":"a1","title":"Classroom Observation","activity_type":"group","estimated_minutes":15,"learning_objective":"Compare states of matter","materials":"Ice cubes, beaker, water","instructions":"Observe melting ice and record findings.","expected_response":"Accurate state properties","assessment_criteria":"States of matter are distinguished accurately"}]'::jsonb,
    'Properties of solids, liquids, and gases are explained accurately',
    'Initial Science draft'
  );

  perform public.transition_lesson_workflow((v_res1 ->> 'id')::uuid, 'submit_for_review', 'Ready for Math review');
  perform public.transition_lesson_workflow((v_res2 ->> 'id')::uuid, 'submit_for_review', 'Ready for Science review');
end $$;

-- ============================================================================
-- 4. Academic Reviewer inspects summary counts, filters, pagination & claims
-- ============================================================================
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000992', true);

select cmp_ok(
  (public.get_academic_review_queue_summary('TZ') ->> 'awaiting_review_count')::int,
  '>=',
  2,
  'Summary returns real DB-derived awaiting_review_count >= 2'
);

-- Search filter finds exact Mathematics lesson
select is(
  (public.list_academic_review_queue('TZ', null, null, null, 'in_review', 'QueueTest: Adding and Subtracting Fractions', null, false, 20, 0) ->> 'total_count')::int,
  1,
  'Search filter matches exact submitted lesson by title'
);

-- Subject filter narrows strictly to Science Std V
select is(
  (
    public.list_academic_review_queue(
      'TZ', null, null,
      (select id from public.subjects where code = 'tie-pri-science-standard5' limit 1),
      'in_review', 'QueueTest:', null, false, 20, 0
    ) ->> 'total_count'
  )::int,
  1,
  'Subject filter returns only matching Science Std V lesson'
);

-- Grade filter narrows strictly to Standard IV
select is(
  (
    public.list_academic_review_queue(
      'TZ', null,
      (select eg.id from public.education_grades eg join public.curricula c on c.id = eg.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and eg.code = 'STANDARD_4' limit 1),
      null, 'in_review', 'QueueTest:', null, false, 20, 0
    ) ->> 'total_count'
  )::int,
  1,
  'Grade filter returns only matching Standard IV lesson'
);

-- Pagination check: limit=1, offset=0 has_more=true; offset=1 returns 2nd item
select is(
  (public.list_academic_review_queue('TZ', null, null, null, 'in_review', 'QueueTest:', null, false, 1, 0) ->> 'has_more')::boolean,
  true,
  'Pagination sets has_more = true when more items exist beyond page size'
);

select is(
  jsonb_array_length(
    public.list_academic_review_queue('TZ', null, null, null, 'in_review', 'QueueTest:', null, false, 1, 1) -> 'items'
  ),
  1,
  'Pagination offset=1 returns the second item cleanly'
);

-- Verify queue item carries real competence & author metadata
select is(
  (
    public.list_academic_review_queue('TZ', null, null, null, 'in_review', 'QueueTest: Adding and Subtracting Fractions', null, false, 5, 0)
    -> 'items' -> 0 ->> 'specific_competence_code'
  ),
  '1.2',
  'Queue item includes real specific_competence_code from database'
);

-- Reviewer claims the Mathematics lesson
select is(
  (
    public.assign_lesson_reviewer(
      (select id from public.lessons where title = 'QueueTest: Adding and Subtracting Fractions' limit 1),
      null
    ) ->> 'reviewer_id'
  ),
  '00000000-0000-0000-0000-000000000992',
  'Academic reviewer can claim an unassigned lesson for review'
);

-- Verify assigned_to_me filter now returns 1 and only_unassigned returns 1 (the Science lesson)
select is(
  (
    public.list_academic_review_queue(
      'TZ', null, null, null, 'in_review', 'QueueTest:',
      '00000000-0000-0000-0000-000000000992'::uuid, false, 20, 0
    ) ->> 'total_count'
  )::int,
  1,
  'Assigned reviewer filter returns exact claimed lesson'
);

select is(
  (
    public.list_academic_review_queue(
      'TZ', null, null, null, 'in_review', 'QueueTest:',
      null, true, 20, 0
    ) ->> 'total_count'
  )::int,
  1,
  'only_unassigned filter returns only the unclaimed Science lesson'
);

-- Verify reviewer_assigned audit event was recorded
select cmp_ok(
  (
    select count(*)::int
    from public.lesson_review_events
    where lesson_id = (select id from public.lessons where title = 'QueueTest: Adding and Subtracting Fractions' limit 1)
      and action = 'reviewer_assigned'
  ),
  '=',
  1,
  'Claiming a lesson records reviewer_assigned in lesson_review_events'
);

-- ============================================================================
-- 5. Full Review -> Request Revision -> Resubmit -> Approve -> Publish lifecycle
-- ============================================================================
-- Reviewer requests revision with persisted comments
select is(
  (
    public.transition_lesson_workflow(
      (select id from public.lessons where title = 'QueueTest: Adding and Subtracting Fractions' limit 1),
      'request_revision',
      'Please add a worked example with visual fraction bars.'
    ) ->> 'status'
  ),
  'revision_requested',
  'Reviewer can request revisions with persisted comment'
);

-- Author revises and resubmits
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000991', true);
select is(
  (
    public.transition_lesson_workflow(
      (select id from public.lessons where title = 'QueueTest: Adding and Subtracting Fractions' limit 1),
      'submit_for_review',
      'Added worked example with fraction bars.'
    ) ->> 'status'
  ),
  'in_review',
  'Author can resubmit revised lesson back into in_review queue'
);

-- Reviewer approves
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000992', true);
select is(
  (
    public.transition_lesson_workflow(
      (select id from public.lessons where title = 'QueueTest: Adding and Subtracting Fractions' limit 1),
      'approve',
      'Meets TIE Standard IV Mathematics criteria.'
    ) ->> 'status'
  ),
  'approved',
  'Academic reviewer can approve resubmitted lesson'
);

-- Academic reviewer (without curriculum_admin) CANNOT publish
select throws_matching(
  $$
    select public.transition_lesson_workflow(
      (select id from public.lessons where title = 'QueueTest: Adding and Subtracting Fractions' limit 1),
      'publish',
      'Attempted unauthorized publish'
    );
  $$,
  'Permission denied',
  'Academic reviewer cannot publish without curriculum_admin / super_admin role'
);

-- Curriculum Admin cannot assign the lesson author as reviewer (two-party rule)
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000993', true);
select throws_matching(
  $$
    select public.assign_lesson_reviewer(
      (select id from public.lessons where title = 'QueueTest: States of Matter and Physical Changes' limit 1),
      '00000000-0000-0000-0000-000000000991'::uuid
    );
  $$,
  'cannot be assigned as reviewer',
  'Two-party review blocks assigning the lesson author as reviewer'
);

-- Curriculum Admin publishes approved lesson
select is(
  (
    public.transition_lesson_workflow(
      (select id from public.lessons where title = 'QueueTest: Adding and Subtracting Fractions' limit 1),
      'publish',
      'Approved for Tanzania Primary Standard IV learners.'
    ) ->> 'is_published'
  ),
  'true',
  'Curriculum admin can publish an approved lesson'
);

-- ============================================================================
-- 6. Immutable Audit Trail verification (UPDATE & DELETE blocked even as postgres)
-- ============================================================================
reset role;

select throws_matching(
  $$
    update public.lesson_review_events
    set comments = 'Tampered comment'
    where lesson_id = (select id from public.lessons where title = 'QueueTest: Adding and Subtracting Fractions' limit 1);
  $$,
  'Immutable audit log violation',
  'UPDATE on public.lesson_review_events is blocked by immutability trigger'
);

select throws_matching(
  $$
    delete from public.lesson_review_events
    where lesson_id = (select id from public.lessons where title = 'QueueTest: Adding and Subtracting Fractions' limit 1);
  $$,
  'Immutable audit log violation',
  'DELETE on public.lesson_review_events is blocked by immutability trigger'
);

select * from finish();
rollback;
