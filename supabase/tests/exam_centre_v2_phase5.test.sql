begin;
select plan(9);

select has_function('public', 'list_exam_v2_review_queue', ARRAY['text','text','text','integer','integer'], 'list_exam_v2_review_queue exists');
select has_function('public', 'record_exam_v2_review_decision', ARRAY['uuid','text','text','jsonb'], 'record_exam_v2_review_decision exists');

-- Ephemeral identities
insert into auth.users (
  id, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at, aud, role
) values
  ('00000000-0000-0000-0000-000000000851', 'rev5_author@learntz.test', '', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"full_name":"Phase5 Author"}'::jsonb, now(), now(), 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-000000000852', 'rev5_reviewer@learntz.test', '', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"full_name":"Phase5 Reviewer"}'::jsonb, now(), now(), 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-000000000853', 'rev5_admin@learntz.test', '', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"full_name":"Phase5 Admin"}'::jsonb, now(), now(), 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-000000000854', 'rev5_parent@learntz.test', '', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{"full_name":"Phase5 Parent"}'::jsonb, now(), now(), 'authenticated', 'authenticated')
on conflict (id) do nothing;

insert into public.user_roles (user_id, role, country_code) values
  ('00000000-0000-0000-0000-000000000851', 'content_author', 'TZ'),
  ('00000000-0000-0000-0000-000000000852', 'academic_reviewer', 'TZ'),
  ('00000000-0000-0000-0000-000000000853', 'curriculum_admin', 'TZ'),
  ('00000000-0000-0000-0000-000000000854', 'parent', null)
on conflict do nothing;

-- 1. Unauthorized parent & plain author blocked from examination review queue
set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000854', true);
select throws_matching($$ select public.list_exam_v2_review_queue('TZ'); $$, 'Permission denied', 'Parent blocked from examination review queue');

select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000851', true);
select throws_matching($$ select public.list_exam_v2_review_queue('TZ'); $$, 'Permission denied', 'Plain content_author blocked from examination review queue');

-- 2. Author creates & submits an English Std III Terminal Examination
do $$
declare
  v_lvl uuid; v_grd uuid; v_eng uuid; v_type uuid; v_sc uuid; v_res jsonb;
begin
  select el.id into v_lvl from public.education_levels el join public.curricula c on c.id = el.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and el.code = 'PRIMARY' limit 1;
  select eg.id into v_grd from public.education_grades eg join public.curricula c on c.id = eg.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and eg.code = 'STANDARD_3' limit 1;
  select id into v_eng from public.subjects where code = 'tie-pri-english-standard3' limit 1;
  select id into v_type from public.examination_types where country_code = 'TZ' and code = 'TERMINAL' limit 1;
  select sc.id into v_sc from public.curriculum_specific_competences sc where sc.subject_id = v_eng order by sc.display_order limit 1;

  v_res := public.save_exam_v2_examination(
    'TZ', v_lvl, v_grd, v_eng, v_type,
    'Phase5 Review Test: English Terminal',
    2026, 'Term I', null, 90, 'en', 'Read carefully.', 'hybrid',
    '[{"section_code":"A","title":"Multiple Choice","question_format":"multiple_choice","question_count":5,"marks_allocated":20,"display_order":1}]'::jsonb,
    jsonb_build_array(jsonb_build_object('specific_competence_id', v_sc, 'allocated_marks', 20))
  );

  perform public.transition_exam_v2_status((v_res ->> 'id')::uuid, 'submit_for_review', 'Ready for Phase 5 review');
end $$;

-- 3. Reviewer sees item in review queue & approves with checklist
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000852', true);

select cmp_ok(
  (public.list_exam_v2_review_queue('TZ', 'submitted_for_review', 'Phase5 Review Test', 10, 0) -> 'summary' ->> 'awaiting_review_count')::int,
  '>=',
  1,
  'Academic reviewer sees submitted examination in review queue'
);

select is(
  public.record_exam_v2_review_decision(
    (select id from public.examinations where title = 'Phase5 Review Test: English Terminal' limit 1),
    'approve',
    'All 10 checklist items verified.',
    '{"curriculum_alignment":true,"age_appropriate":true,"marks_verified":true}'::jsonb
  ) ->> 'status',
  'approved',
  'Academic reviewer approves examination with persisted checklist'
);

select is(
  (
    select metadata -> 'last_review_checklist' ->> 'curriculum_alignment'
    from public.examinations
    where title = 'Phase5 Review Test: English Terminal'
    limit 1
  ),
  'true',
  'Reviewer checklist JSONB persisted on examination metadata'
);

-- 4. Curriculum Admin publishes approved examination
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000853', true);

select is(
  public.record_exam_v2_review_decision(
    (select id from public.examinations where title = 'Phase5 Review Test: English Terminal' limit 1),
    'publish',
    'Approved for Term I release.',
    '{}'::jsonb
  ) ->> 'is_published',
  'true',
  'Curriculum admin publishes approved examination'
);

select cmp_ok(
  (
    select count(*)::int
    from public.examination_review_events
    where examination_id = (select id from public.examinations where title = 'Phase5 Review Test: English Terminal' limit 1)
  ),
  '>=',
  4,
  'Complete immutable audit trail recorded (draft_saved, submitted, approved, published)'
);

select * from finish();
rollback;
