begin;
select plan(36);

-- Create ephemeral content author identity inside transaction (rolled back at end)
insert into auth.users (
  id, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at, aud, role
) values (
  '00000000-0000-0000-0000-000000000981',
  'math_science_author@learntz.test', '', now(),
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"full_name":"TIE Math & Science Author"}'::jsonb, now(), now(), 'authenticated', 'authenticated'
) on conflict (id) do nothing;

insert into public.user_roles (user_id, role, country_code) values
  ('00000000-0000-0000-0000-000000000981', 'content_author', 'TZ')
on conflict do nothing;

-- ============================================================================
-- 1. Natural-key verification: Tanzania TIE Primary Standards III-VI exist
-- ============================================================================
select is(
  (
    select count(*)::int
    from public.education_grades eg
    join public.education_levels el on el.id = eg.education_level_id
    join public.curricula c on c.id = eg.curriculum_id
    where c.country_code = 'TZ'
      and c.code = 'TIE'
      and el.code = 'PRIMARY'
      and eg.code in ('STANDARD_3', 'STANDARD_4', 'STANDARD_5', 'STANDARD_6')
  ),
  4,
  'Natural-key lookup finds all 4 Tanzania TIE Primary grades (STANDARD_3..STANDARD_6)'
);

-- ============================================================================
-- 2. All 8 grade-subject combinations exist and link to natural-key grades
-- ============================================================================
select is(
  (
    select count(*)::int
    from public.subjects s
    join public.education_grades eg on eg.id = s.grade_id
    join public.education_levels el on el.id = s.education_level_id
    join public.curricula c on c.id = s.curriculum_id
    where c.country_code = 'TZ'
      and c.code = 'TIE'
      and el.code = 'PRIMARY'
      and s.code in (
        'tie-pri-mathematics-standard3',
        'tie-pri-mathematics-standard4',
        'tie-pri-mathematics-standard5',
        'tie-pri-mathematics-standard6',
        'tie-pri-science-standard3',
        'tie-pri-science-standard4',
        'tie-pri-science-standard5',
        'tie-pri-science-standard6'
      )
      and s.is_published = true
  ),
  8,
  'All 8 TIE Primary Mathematics and Science subjects (Std III-VI) exist and are published'
);

-- Verify zero duplicate subject codes
select is(
  (
    select count(*)::int
    from (
      select s.code
      from public.subjects s
      where s.code like 'tie-pri-mathematics-standard%'
         or s.code like 'tie-pri-science-standard%'
      group by s.code
      having count(*) > 1
    ) dups
  ),
  0,
  'Zero duplicate subject records exist for TIE Primary Mathematics & Science'
);

-- ============================================================================
-- 3. Exact official TIE Main & Specific Competence counts per grade & subject
-- ============================================================================
-- Mathematics Std III: 2 main, 7 specific
select is(
  (select count(*)::int from public.curriculum_main_competences mc join public.subjects s on s.id = mc.subject_id where s.code = 'tie-pri-mathematics-standard3'),
  2, 'Math Std III has exact 2 official TIE main competences'
);
select is(
  (select count(*)::int from public.curriculum_specific_competences sc join public.subjects s on s.id = sc.subject_id where s.code = 'tie-pri-mathematics-standard3'),
  7, 'Math Std III has exact 7 official TIE specific competences'
);

-- Mathematics Std IV: 2 main, 7 specific
select is(
  (select count(*)::int from public.curriculum_main_competences mc join public.subjects s on s.id = mc.subject_id where s.code = 'tie-pri-mathematics-standard4'),
  2, 'Math Std IV has exact 2 official TIE main competences'
);
select is(
  (select count(*)::int from public.curriculum_specific_competences sc join public.subjects s on s.id = sc.subject_id where s.code = 'tie-pri-mathematics-standard4'),
  7, 'Math Std IV has exact 7 official TIE specific competences'
);

-- Mathematics Std V: 2 main, 5 specific
select is(
  (select count(*)::int from public.curriculum_main_competences mc join public.subjects s on s.id = mc.subject_id where s.code = 'tie-pri-mathematics-standard5'),
  2, 'Math Std V has exact 2 official TIE main competences'
);
select is(
  (select count(*)::int from public.curriculum_specific_competences sc join public.subjects s on s.id = sc.subject_id where s.code = 'tie-pri-mathematics-standard5'),
  5, 'Math Std V has exact 5 official TIE specific competences'
);

-- Mathematics Std VI: 2 main, 4 specific
select is(
  (select count(*)::int from public.curriculum_main_competences mc join public.subjects s on s.id = mc.subject_id where s.code = 'tie-pri-mathematics-standard6'),
  2, 'Math Std VI has exact 2 official TIE main competences'
);
select is(
  (select count(*)::int from public.curriculum_specific_competences sc join public.subjects s on s.id = sc.subject_id where s.code = 'tie-pri-mathematics-standard6'),
  4, 'Math Std VI has exact 4 official TIE specific competences'
);

-- Science Std III: 3 main, 4 specific
select is(
  (select count(*)::int from public.curriculum_main_competences mc join public.subjects s on s.id = mc.subject_id where s.code = 'tie-pri-science-standard3'),
  3, 'Science Std III has exact 3 official TIE main competences'
);
select is(
  (select count(*)::int from public.curriculum_specific_competences sc join public.subjects s on s.id = sc.subject_id where s.code = 'tie-pri-science-standard3'),
  4, 'Science Std III has exact 4 official TIE specific competences'
);

-- Science Std IV: 4 main, 6 specific
select is(
  (select count(*)::int from public.curriculum_main_competences mc join public.subjects s on s.id = mc.subject_id where s.code = 'tie-pri-science-standard4'),
  4, 'Science Std IV has exact 4 official TIE main competences'
);
select is(
  (select count(*)::int from public.curriculum_specific_competences sc join public.subjects s on s.id = sc.subject_id where s.code = 'tie-pri-science-standard4'),
  6, 'Science Std IV has exact 6 official TIE specific competences'
);

-- Science Std V: 3 main, 4 specific
select is(
  (select count(*)::int from public.curriculum_main_competences mc join public.subjects s on s.id = mc.subject_id where s.code = 'tie-pri-science-standard5'),
  3, 'Science Std V has exact 3 official TIE main competences'
);
select is(
  (select count(*)::int from public.curriculum_specific_competences sc join public.subjects s on s.id = sc.subject_id where s.code = 'tie-pri-science-standard5'),
  4, 'Science Std V has exact 4 official TIE specific competences'
);

-- Science Std VI: 3 main, 4 specific
select is(
  (select count(*)::int from public.curriculum_main_competences mc join public.subjects s on s.id = mc.subject_id where s.code = 'tie-pri-science-standard6'),
  3, 'Science Std VI has exact 3 official TIE main competences'
);
select is(
  (select count(*)::int from public.curriculum_specific_competences sc join public.subjects s on s.id = sc.subject_id where s.code = 'tie-pri-science-standard6'),
  4, 'Science Std VI has exact 4 official TIE specific competences'
);

-- ============================================================================
-- 4. Verbatim official TIE wording & source traceability verification
-- ============================================================================
select is(
  (
    select sc.title
    from public.curriculum_specific_competences sc
    join public.subjects s on s.id = sc.subject_id
    where s.code = 'tie-pri-mathematics-standard6' and sc.code = '2.1'
  ),
  'Demonstrate an understanding of elementary statistics and its applications',
  'Math Std VI 2.1 preserves verbatim official TIE wording (elementary statistics)'
);

select is(
  (
    select sc.title
    from public.curriculum_specific_competences sc
    join public.subjects s on s.id = sc.subject_id
    where s.code = 'tie-pri-mathematics-standard5' and sc.code = '2.1'
  ),
  'Demonstrate an understanding of financial mathematics',
  'Math Std V 2.1 preserves verbatim official TIE wording (financial mathematics)'
);

select is(
  (
    select sc.title
    from public.curriculum_specific_competences sc
    join public.subjects s on s.id = sc.subject_id
    where s.code = 'tie-pri-science-standard4' and sc.code = '4.1'
  ),
  'Design simple computer programmes',
  'Science Std IV 4.1 preserves verbatim official TIE wording'
);

select ok(
  (
    select count(*) = 23
    from public.curriculum_specific_competences sc
    join public.subjects s on s.id = sc.subject_id
    where s.code like 'tie-pri-mathematics-standard%'
      and sc.description like '%978-9987-09-858-3%'
      and sc.source_page is not null
  ),
  'All 23 Mathematics specific competences record official TIE ISBN 978-9987-09-858-3 and source page'
);

select ok(
  (
    select count(*) = 18
    from public.curriculum_specific_competences sc
    join public.subjects s on s.id = sc.subject_id
    where s.code like 'tie-pri-science-standard%'
      and sc.description like '%978-9987-09-860-6%'
      and sc.source_page is not null
  ),
  'All 18 Science specific competences record official TIE ISBN 978-9987-09-860-6 and source page'
);

-- ============================================================================
-- 5. Four Cascading Dropdown RPCs as authenticated Content Author (all 8 combos)
-- ============================================================================
set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000981', true);

-- Helper check: Dropdown 2 (Subjects) returns Mathematics & Science for each of Std III-VI
select ok(
  exists (
    select 1
    from jsonb_array_elements(
      public.get_authoring_subjects(
        (select id from public.curricula where country_code = 'TZ' and code = 'TIE' limit 1),
        (select eg.id from public.education_grades eg join public.curricula c on c.id = eg.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and eg.code = 'STANDARD_3' limit 1),
        (select el.id from public.education_levels el join public.curricula c on c.id = el.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and el.code = 'PRIMARY' limit 1)
      )
    ) elem
    where elem ->> 'code' = 'tie-pri-mathematics-standard3'
  )
  and exists (
    select 1
    from jsonb_array_elements(
      public.get_authoring_subjects(
        (select id from public.curricula where country_code = 'TZ' and code = 'TIE' limit 1),
        (select eg.id from public.education_grades eg join public.curricula c on c.id = eg.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and eg.code = 'STANDARD_3' limit 1),
        (select el.id from public.education_levels el join public.curricula c on c.id = el.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and el.code = 'PRIMARY' limit 1)
      )
    ) elem
    where elem ->> 'code' = 'tie-pri-science-standard3'
  ),
  'Dropdown 2 (Std III) exposes both Mathematics and Science'
);

select ok(
  exists (
    select 1
    from jsonb_array_elements(
      public.get_authoring_subjects(
        (select id from public.curricula where country_code = 'TZ' and code = 'TIE' limit 1),
        (select eg.id from public.education_grades eg join public.curricula c on c.id = eg.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and eg.code = 'STANDARD_4' limit 1),
        (select el.id from public.education_levels el join public.curricula c on c.id = el.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and el.code = 'PRIMARY' limit 1)
      )
    ) elem
    where elem ->> 'code' = 'tie-pri-mathematics-standard4'
  )
  and exists (
    select 1
    from jsonb_array_elements(
      public.get_authoring_subjects(
        (select id from public.curricula where country_code = 'TZ' and code = 'TIE' limit 1),
        (select eg.id from public.education_grades eg join public.curricula c on c.id = eg.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and eg.code = 'STANDARD_4' limit 1),
        (select el.id from public.education_levels el join public.curricula c on c.id = el.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and el.code = 'PRIMARY' limit 1)
      )
    ) elem
    where elem ->> 'code' = 'tie-pri-science-standard4'
  ),
  'Dropdown 2 (Std IV) exposes both Mathematics and Science'
);

select ok(
  exists (
    select 1
    from jsonb_array_elements(
      public.get_authoring_subjects(
        (select id from public.curricula where country_code = 'TZ' and code = 'TIE' limit 1),
        (select eg.id from public.education_grades eg join public.curricula c on c.id = eg.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and eg.code = 'STANDARD_5' limit 1),
        (select el.id from public.education_levels el join public.curricula c on c.id = el.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and el.code = 'PRIMARY' limit 1)
      )
    ) elem
    where elem ->> 'code' = 'tie-pri-mathematics-standard5'
  )
  and exists (
    select 1
    from jsonb_array_elements(
      public.get_authoring_subjects(
        (select id from public.curricula where country_code = 'TZ' and code = 'TIE' limit 1),
        (select eg.id from public.education_grades eg join public.curricula c on c.id = eg.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and eg.code = 'STANDARD_5' limit 1),
        (select el.id from public.education_levels el join public.curricula c on c.id = el.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and el.code = 'PRIMARY' limit 1)
      )
    ) elem
    where elem ->> 'code' = 'tie-pri-science-standard5'
  ),
  'Dropdown 2 (Std V) exposes both Mathematics and Science'
);

select ok(
  exists (
    select 1
    from jsonb_array_elements(
      public.get_authoring_subjects(
        (select id from public.curricula where country_code = 'TZ' and code = 'TIE' limit 1),
        (select eg.id from public.education_grades eg join public.curricula c on c.id = eg.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and eg.code = 'STANDARD_6' limit 1),
        (select el.id from public.education_levels el join public.curricula c on c.id = el.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and el.code = 'PRIMARY' limit 1)
      )
    ) elem
    where elem ->> 'code' = 'tie-pri-mathematics-standard6'
  )
  and exists (
    select 1
    from jsonb_array_elements(
      public.get_authoring_subjects(
        (select id from public.curricula where country_code = 'TZ' and code = 'TIE' limit 1),
        (select eg.id from public.education_grades eg join public.curricula c on c.id = eg.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and eg.code = 'STANDARD_6' limit 1),
        (select el.id from public.education_levels el join public.curricula c on c.id = el.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and el.code = 'PRIMARY' limit 1)
      )
    ) elem
    where elem ->> 'code' = 'tie-pri-science-standard6'
  ),
  'Dropdown 2 (Std VI) exposes both Mathematics and Science'
);

-- Dropdown 3 (Main Competences) & Dropdown 4 (Specific Competences) for Math Std III-VI
select is(
  jsonb_array_length(
    public.get_authoring_main_competences(
      (select id from public.subjects where code = 'tie-pri-mathematics-standard3' limit 1)
    )
  ),
  2, 'Dropdown 3 returns 2 Main Competences for Math Std III'
);

select is(
  jsonb_array_length(
    public.get_authoring_specific_competences(
      (select mc.id from public.curriculum_main_competences mc join public.subjects s on s.id = mc.subject_id where s.code = 'tie-pri-mathematics-standard5' and mc.code = '1.0' limit 1)
    )
  ),
  4, 'Dropdown 4 returns 4 Specific Competences for Math Std V Main Competence 1.0'
);

select is(
  jsonb_array_length(
    public.get_authoring_main_competences(
      (select id from public.subjects where code = 'tie-pri-science-standard4' limit 1)
    )
  ),
  4, 'Dropdown 3 returns 4 Main Competences for Science Std IV'
);

select is(
  jsonb_array_length(
    public.get_authoring_specific_competences(
      (select mc.id from public.curriculum_main_competences mc join public.subjects s on s.id = mc.subject_id where s.code = 'tie-pri-science-standard6' and mc.code = '1.0' limit 1)
    )
  ),
  2, 'Dropdown 4 returns 2 Specific Competences for Science Std VI Main Competence 1.0'
);

-- Verify subtopics (learning activities) exist for Math and Science specific competences
select cmp_ok(
  (
    select count(*)::int
    from public.subtopics st
    join public.topics t on t.id = st.topic_id
    join public.subjects s on s.id = t.subject_id
    where s.code like 'tie-pri-mathematics-standard%'
  ),
  '>=',
  40,
  'Mathematics specific competences include official TIE specific learning activities as subtopics'
);

select cmp_ok(
  (
    select count(*)::int
    from public.subtopics st
    join public.topics t on t.id = st.topic_id
    join public.subjects s on s.id = t.subject_id
    where s.code like 'tie-pri-science-standard%'
  ),
  '>=',
  30,
  'Science specific competences include official TIE specific learning activities as subtopics'
);

-- ============================================================================
-- 6. End-to-end lesson authoring against ingested Mathematics & Science records
-- ============================================================================
select is(
  (
    public.save_authored_lesson(
      'TZ',
      (select id from public.curricula where country_code = 'TZ' and code = 'TIE' limit 1),
      (select id from public.curriculum_versions where version_code = 'TIE_PRIMARY_2023' limit 1),
      (select el.id from public.education_levels el join public.curricula c on c.id = el.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and el.code = 'PRIMARY' limit 1),
      (select eg.id from public.education_grades eg join public.curricula c on c.id = eg.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and eg.code = 'STANDARD_5' limit 1),
      (select id from public.subjects where code = 'tie-pri-mathematics-standard5' limit 1),
      (select mc.id from public.curriculum_main_competences mc join public.subjects s on s.id = mc.subject_id where s.code = 'tie-pri-mathematics-standard5' and mc.code = '1.0' limit 1),
      (select sc.id from public.curriculum_specific_competences sc join public.subjects s on s.id = sc.subject_id where s.code = 'tie-pri-mathematics-standard5' and sc.code = '1.4' limit 1),
      (select sc.topic_id from public.curriculum_specific_competences sc join public.subjects s on s.id = sc.subject_id where s.code = 'tie-pri-mathematics-standard5' and sc.code = '1.4' limit 1),
      'Solving Linear Equations with One Unknown',
      '# Linear Equations\n\nLearners formulate and solve simple algebraic equations in one unknown.'
    ) ->> 'status'
  ),
  'draft',
  'Author can save a real draft lesson linked to Std V Mathematics Specific Competence 1.4'
);

select is(
  (
    public.save_authored_lesson(
      'TZ',
      (select id from public.curricula where country_code = 'TZ' and code = 'TIE' limit 1),
      (select id from public.curriculum_versions where version_code = 'TIE_PRIMARY_2023' limit 1),
      (select el.id from public.education_levels el join public.curricula c on c.id = el.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and el.code = 'PRIMARY' limit 1),
      (select eg.id from public.education_grades eg join public.curricula c on c.id = eg.curriculum_id where c.country_code = 'TZ' and c.code = 'TIE' and eg.code = 'STANDARD_6' limit 1),
      (select id from public.subjects where code = 'tie-pri-science-standard6' limit 1),
      (select mc.id from public.curriculum_main_competences mc join public.subjects s on s.id = mc.subject_id where s.code = 'tie-pri-science-standard6' and mc.code = '1.0' limit 1),
      (select sc.id from public.curriculum_specific_competences sc join public.subjects s on s.id = sc.subject_id where s.code = 'tie-pri-science-standard6' and sc.code = '1.2' limit 1),
      (select sc.topic_id from public.curriculum_specific_competences sc join public.subjects s on s.id = sc.subject_id where s.code = 'tie-pri-science-standard6' and sc.code = '1.2' limit 1),
      'Series and Parallel Electric Circuits',
      '# Electric Circuits\n\nLearners explore simple electric circuits and Ohm''s law in everyday life.'
    ) ->> 'is_published'
  ),
  'false',
  'Author can save a real draft lesson linked to Std VI Science Specific Competence 1.2 (stays unpublished)'
);

select * from finish();
rollback;
