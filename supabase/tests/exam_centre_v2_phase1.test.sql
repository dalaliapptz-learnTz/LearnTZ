begin;
select plan(20);

-- 1. Verify schema & RPCs exist
select has_table('public', 'examination_types', 'examination_types table exists');
select has_function('public', 'get_exam_v2_countries', ARRAY[]::text[], 'get_exam_v2_countries exists');
select has_function('public', 'get_exam_v2_education_levels', ARRAY['text'], 'get_exam_v2_education_levels exists');
select has_function('public', 'get_exam_v2_grades', ARRAY['uuid', 'uuid'], 'get_exam_v2_grades exists');
select has_function('public', 'get_exam_v2_subjects', ARRAY['uuid', 'uuid', 'uuid'], 'get_exam_v2_subjects exists');
select has_function('public', 'get_exam_v2_examination_types', ARRAY['text', 'uuid'], 'get_exam_v2_examination_types exists');
select has_function(
  'public',
  'get_exam_v2_academic_context_summary',
  ARRAY['text', 'uuid', 'uuid', 'uuid', 'uuid'],
  'get_exam_v2_academic_context_summary exists'
);

-- 2. Step 1: Country selection loads Tanzania with TIE curriculum & approved version
select ok(
  exists (
    select 1
    from jsonb_array_elements(public.get_exam_v2_countries()) c
    where c ->> 'country_code' = 'TZ'
      and c ->> 'curriculum_code' = 'TIE'
      and c ->> 'curriculum_version_code' = 'TIE_PRIMARY_2023'
  ),
  'Step 1: Country dropdown returns Tanzania with TIE curriculum and TIE_PRIMARY_2023 version'
);

-- Multi-country isolation: multiple enabled countries load cleanly alongside TZ
select cmp_ok(
  jsonb_array_length(public.get_exam_v2_countries()),
  '>=',
  2,
  'Multi-country: get_exam_v2_countries returns Tanzania and additional configured countries'
);

-- 3. Step 2: Education Level loads Primary Education for Tanzania
select ok(
  exists (
    select 1
    from jsonb_array_elements(public.get_exam_v2_education_levels('TZ')) el
    where el ->> 'code' = 'PRIMARY'
  ),
  'Step 2: Education Level dropdown returns Primary Education for Tanzania'
);

-- 4. Step 3: Grade/Form/Class loads Standard III dynamically (no hardcoded UUIDs)
select ok(
  exists (
    select 1
    from jsonb_array_elements(
      public.get_exam_v2_grades(
        (select id from public.curricula where country_code = 'TZ' and code = 'TIE' limit 1),
        (select el.id from public.education_levels el join public.curricula c on c.id = el.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and el.code = 'PRIMARY' limit 1)
      )
    ) g
    where g ->> 'code' = 'STANDARD_3'
  ),
  'Step 3: Grade dropdown returns Standard III for Tanzania Primary Education'
);

-- 5. Step 4: Subject dropdown loads English Language (plus Math & Science) strictly scoped to Standard III
select ok(
  exists (
    select 1
    from jsonb_array_elements(
      public.get_exam_v2_subjects(
        (select id from public.curricula where country_code = 'TZ' and code = 'TIE' limit 1),
        (select el.id from public.education_levels el join public.curricula c on c.id = el.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and el.code = 'PRIMARY' limit 1),
        (select eg.id from public.education_grades eg join public.curricula c on c.id = eg.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and eg.code = 'STANDARD_3' limit 1)
      )
    ) s
    where s ->> 'code' = 'tie-pri-english-standard3'
      and (s ->> 'main_competence_count')::int = 3
      and (s ->> 'specific_competence_count')::int = 5
  ),
  'Step 4: Subject dropdown returns Standard III English Language with 3 main & 5 specific TIE competences'
);

-- 6. Step 5: Examination Type loads Terminal Examination for Tanzania Primary Education
select ok(
  exists (
    select 1
    from jsonb_array_elements(
      public.get_exam_v2_examination_types(
        'TZ',
        (select el.id from public.education_levels el join public.curricula c on c.id = el.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and el.code = 'PRIMARY' limit 1)
      )
    ) et
    where et ->> 'code' = 'TERMINAL'
      and et ->> 'name' = 'Terminal Examination'
  ),
  'Step 5: Examination Type dropdown returns Terminal Examination for Tanzania'
);

-- 7. Full reference context summary: TZ -> Primary -> Standard III -> English Language -> Terminal Examination
select is(
  public.get_exam_v2_academic_context_summary(
    'TZ',
    (select el.id from public.education_levels el join public.curricula c on c.id = el.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and el.code = 'PRIMARY' limit 1),
    (select eg.id from public.education_grades eg join public.curricula c on c.id = eg.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and eg.code = 'STANDARD_3' limit 1),
    (select id from public.subjects where code = 'tie-pri-english-standard3' limit 1),
    (select id from public.examination_types where country_code = 'TZ' and code = 'TERMINAL' limit 1)
  ) -> 'context' ->> 'curriculum_version_code',
  'TIE_PRIMARY_2023',
  'Context summary preserves approved TIE_PRIMARY_2023 curriculum version'
);

select is(
  jsonb_array_length(
    public.get_exam_v2_academic_context_summary(
      'TZ',
      (select el.id from public.education_levels el join public.curricula c on c.id = el.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and el.code = 'PRIMARY' limit 1),
      (select eg.id from public.education_grades eg join public.curricula c on c.id = eg.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and eg.code = 'STANDARD_3' limit 1),
      (select id from public.subjects where code = 'tie-pri-english-standard3' limit 1),
      (select id from public.examination_types where country_code = 'TZ' and code = 'TERMINAL' limit 1)
    ) -> 'main_competences'
  ),
  3,
  'Context summary returns exact 3 official TIE Main Competences for Standard III English Language'
);

-- Verify Mathematics Std V also loads cleanly with its 2 Main Competences
select is(
  jsonb_array_length(
    public.get_exam_v2_academic_context_summary(
      'TZ',
      (select el.id from public.education_levels el join public.curricula c on c.id = el.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and el.code = 'PRIMARY' limit 1),
      (select eg.id from public.education_grades eg join public.curricula c on c.id = eg.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and eg.code = 'STANDARD_5' limit 1),
      (select id from public.subjects where code = 'tie-pri-mathematics-standard5' limit 1),
      (select id from public.examination_types where country_code = 'TZ' and code = 'TERMINAL' limit 1)
    ) -> 'main_competences'
  ),
  2,
  'Context summary returns exact 2 official TIE Main Competences for Standard V Mathematics'
);

-- 8. Server-side validation rejects mismatched Grade (Standard IV) + Subject (Standard III English)
select throws_matching(
  $$
    select public.get_exam_v2_academic_context_summary(
      'TZ',
      (select el.id from public.education_levels el join public.curricula c on c.id = el.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and el.code = 'PRIMARY' limit 1),
      (select eg.id from public.education_grades eg join public.curricula c on c.id = eg.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and eg.code = 'STANDARD_4' limit 1),
      (select id from public.subjects where code = 'tie-pri-english-standard3' limit 1),
      (select id from public.examination_types where country_code = 'TZ' and code = 'TERMINAL' limit 1)
    );
  $$,
  'Academic hierarchy mismatch',
  'Backend rejects mismatched Standard IV grade paired with Standard III English subject'
);

-- 9. Server-side validation rejects cross-country Examination Type mismatch (KE type with TZ country)
select throws_matching(
  $$
    select public.get_exam_v2_academic_context_summary(
      'TZ',
      (select el.id from public.education_levels el join public.curricula c on c.id = el.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and el.code = 'PRIMARY' limit 1),
      (select eg.id from public.education_grades eg join public.curricula c on c.id = eg.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and eg.code = 'STANDARD_3' limit 1),
      (select id from public.subjects where code = 'tie-pri-english-standard3' limit 1),
      (select id from public.examination_types where country_code = 'KE' and code = 'TERMINAL' limit 1)
    );
  $$,
  'Academic hierarchy mismatch',
  'Backend rejects Kenya examination type paired with Tanzania academic context'
);

-- 10. Server-side validation rejects missing selection
select throws_matching(
  $$
    select public.get_exam_v2_academic_context_summary('TZ', null, null, null, null);
  $$,
  'All five academic context selections',
  'Backend rejects incomplete 5-step selection'
);

-- 11. RLS blocks non-admin authenticated user from modifying examination_types
insert into auth.users (
  id, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at, aud, role
) values (
  '00000000-0000-0000-0000-000000000999',
  'exam_parent@learntz.test', '', now(),
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"full_name":"Exam Test Parent"}'::jsonb, now(), now(), 'authenticated', 'authenticated'
) on conflict (id) do nothing;

set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000999', true);

select throws_matching(
  $$
    insert into public.examination_types (country_code, code, name)
    values ('TZ', 'UNAUTHORIZED_TEST', 'Unauthorized Test');
  $$,
  'row-level security policy',
  'RLS blocks non-admin user from inserting into examination_types'
);

select * from finish();
rollback;
