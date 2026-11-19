-- ============================================================================
-- LearnTZ — Official TIE Primary Mathematics & Science Curriculum Ingestion
-- Standards III, IV, V, and VI (2023 Competency-Based Syllabus Edition)
--
-- Authoritative Sources:
--   1. Mathematics Syllabus for Primary School Education Standard III-VI (ISBN 978-9987-09-858-3)
--      SHA-256: baef25143a8133b1a435854134f0971133585bb8674d873ba99b83826a0e6eb8
--   2. Science Syllabus for Primary Education Standard III-VI (ISBN 978-9987-09-860-6)
--      SHA-256: f83ea3623f244c0505b6df390a797db9b014d0449ea99172d5622d1ab95f6157
--
-- Uses 100% natural-key resolution (zero hardcoded grade/curriculum/level UUIDs).
-- Fully idempotent and transaction-safe for fresh resets and repeated runs.
-- ============================================================================

begin;

-- 1. Archive grade-less umbrella subjects superseded by grade-scoped Standards III-VI records
update public.subjects
set is_published = false,
    description = 'Archived umbrella subject superseded by grade-scoped Standards III-VI subjects.'
where country_code = 'TZ'
  and code in ('tie-pri-mathematics', 'tie-pri-science')
  and grade_id is null;

-- 2. Record official syllabus traceability on curriculum_sources (natural key: sha256_checksum)
update public.curriculum_sources
set usage_rights_status = 'permission_pending',
    usage_rights_reviewed_at = now(),
    usage_rights_note = 'Competence codes, official titles, learning activities, and period allocations verified against official 2023 TIE Mathematics Syllabus (ISBN 978-9987-09-858-3).'
where sha256_checksum = 'baef25143a8133b1a435854134f0971133585bb8674d873ba99b83826a0e6eb8';

update public.curriculum_sources
set usage_rights_status = 'permission_pending',
    usage_rights_reviewed_at = now(),
    usage_rights_note = 'Competence codes, official titles, learning activities, and period allocations verified against official 2023 TIE Science Syllabus (ISBN 978-9987-09-860-6).'
where sha256_checksum = 'f83ea3623f244c0505b6df390a797db9b014d0449ea99172d5622d1ab95f6157';

-- ============================================================================
-- Mathematics — Standard III (STANDARD_3): 234 periods
-- ============================================================================
do $$
declare
  v_curriculum_id uuid;
  v_level_id uuid;
  v_grade_id uuid;
  v_version_id uuid;
  v_subject_id uuid;
  v_main_id uuid;
  v_topic_id uuid;
begin
  -- Natural-key resolution: Country (TZ) -> Curriculum (TIE) -> Level (PRIMARY) -> Grade
  select id into v_curriculum_id
  from public.curricula
  where country_code = 'TZ' and code = 'TIE'
  limit 1;
  if v_curriculum_id is null then
    raise exception 'Natural-key resolution failed: TZ TIE curriculum not found';
  end if;

  select id into v_level_id
  from public.education_levels
  where curriculum_id = v_curriculum_id and code = 'PRIMARY'
  limit 1;
  if v_level_id is null then
    raise exception 'Natural-key resolution failed: PRIMARY education level not found for TIE curriculum';
  end if;

  select id into v_grade_id
  from public.education_grades
  where curriculum_id = v_curriculum_id and education_level_id = v_level_id and code = 'STANDARD_3'
  limit 1;
  if v_grade_id is null then
    raise exception 'Natural-key resolution failed: education grade STANDARD_3 not found for TIE PRIMARY';
  end if;

  select id into v_version_id
  from public.curriculum_versions
  where curriculum_id = v_curriculum_id and version_code = 'TIE_PRIMARY_2023'
  limit 1;

  -- Upsert grade-scoped subject by natural key (curriculum_id, education_level_id, grade_id, code)
  select id into v_subject_id
  from public.subjects
  where country_code = 'TZ'
    and curriculum_id = v_curriculum_id
    and education_level_id = v_level_id
    and grade_id = v_grade_id
    and code = 'tie-pri-mathematics-standard3';

  if v_subject_id is null then
    insert into public.subjects (
      country_code, curriculum_id, education_level_id, grade_id,
      code, name, official_name, description, display_order, is_published, classification, language
    ) values (
      'TZ', v_curriculum_id, v_level_id, v_grade_id,
      'tie-pri-mathematics-standard3', 'Mathematics', 'Mathematics Syllabus for Primary Education — Standard III', 'Official 2023 TIE Mathematics syllabus for Standard III (234 periods, 6 periods/week; ISBN 978-9987-09-858-3).',
      4, true, 'compulsory', 'en'
    ) returning id into v_subject_id;
  else
    update public.subjects
    set name = 'Mathematics',
        official_name = 'Mathematics Syllabus for Primary Education — Standard III',
        description = 'Official 2023 TIE Mathematics syllabus for Standard III (234 periods, 6 periods/week; ISBN 978-9987-09-858-3).',
        display_order = 4,
        is_published = true,
        classification = 'compulsory',
        language = 'en',
        updated_at = now()
    where id = v_subject_id;
  end if;

  -- Main Competence 1.0: Demonstrate mastery of elementary mathematical skills
  insert into public.curriculum_main_competences (
    subject_id, curriculum_version_id, code, title, description, display_order, is_published
  ) values (
    v_subject_id, v_version_id, '1.0', 'Demonstrate mastery of elementary mathematical skills', 'Official 2023 TIE Mathematics Standard III Main Competence 1.0 (ISBN 978-9987-09-858-3).', 1, true
  )
  on conflict (subject_id, code) do update
    set title = excluded.title,
        description = excluded.description,
        curriculum_version_id = coalesce(excluded.curriculum_version_id, curriculum_main_competences.curriculum_version_id),
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now()
  returning id into v_main_id;

  -- Specific Competence 1.1: Demonstrate an understanding of the concept of numbers
  v_topic_id := null;
  select id into v_topic_id
  from public.topics
  where subject_id = v_subject_id and competency_code = '1.1';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Demonstrate an understanding of the concept of numbers', 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.1. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.8).', 1, true,
      '1.1', 52, 'The value of a digit in multi-digit whole number is recognised', 8
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Demonstrate an understanding of the concept of numbers',
        summary = 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.1. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.8).',
        display_order = 1,
        period_allocation = 52,
        assessment_criteria = 'The value of a digit in multi-digit whole number is recognised',
        source_page = 8,
        is_published = true,
        updated_at = now()
    where id = v_topic_id;
  end if;

  insert into public.curriculum_specific_competences (
    main_competence_id, subject_id, topic_id, code, title, description,
    period_allocation, assessment_criteria, source_page, display_order, is_published
  ) values (
    v_main_id, v_subject_id, v_topic_id, '1.1', 'Demonstrate an understanding of the concept of numbers', 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.1. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.8).',
    52, 'The value of a digit in multi-digit whole number is recognised', 8, 1, true
  )
  on conflict (topic_id) do update
    set main_competence_id = excluded.main_competence_id,
        code = excluded.code,
        title = excluded.title,
        description = excluded.description,
        period_allocation = excluded.period_allocation,
        assessment_criteria = excluded.assessment_criteria,
        source_page = excluded.source_page,
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now();

  -- Refresh official learning activity subtopics idempotently
  delete from public.subtopics where topic_id = v_topic_id;
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Recognise the value of a digit in a multi-digit whole number', 'TIE 2023 Mathematics Standard III (ISBN 978-9987-09-858-3, p.8)',
    'The value of a digit in multi-digit whole number is recognised', 'The value of a digit in multi-digit whole number is recognised', 13, 1, 8, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Read and write multi-digit whole numbers', 'TIE 2023 Mathematics Standard III (ISBN 978-9987-09-858-3, p.8)',
    'Multi-digit whole numbers are correctly read and written', 'Multi-digit whole numbers are correctly read and written', 13, 2, 8, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(c) Compare whole numbers using symbols =, <, and >', 'TIE 2023 Mathematics Standard III (ISBN 978-9987-09-858-3, p.9)',
    'Whole numbers are correctly compared', 'Whole numbers are correctly compared', 13, 3, 9, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(d) Identify sequences in whole numbers', 'TIE 2023 Mathematics Standard III (ISBN 978-9987-09-858-3, p.9)',
    'Sequence of whole numbers is correctly identified', 'Sequence of whole numbers is correctly identified', 13, 4, 9, true
  );

  -- Specific Competence 1.2: Demonstrate an understanding of basic numerical operations
  v_topic_id := null;
  select id into v_topic_id
  from public.topics
  where subject_id = v_subject_id and competency_code = '1.2';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Demonstrate an understanding of basic numerical operations', 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.2. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.9).', 2, true,
      '1.2', 30, 'Addition and subtraction of whole numbers is performed correctly', 9
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Demonstrate an understanding of basic numerical operations',
        summary = 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.2. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.9).',
        display_order = 2,
        period_allocation = 30,
        assessment_criteria = 'Addition and subtraction of whole numbers is performed correctly',
        source_page = 9,
        is_published = true,
        updated_at = now()
    where id = v_topic_id;
  end if;

  insert into public.curriculum_specific_competences (
    main_competence_id, subject_id, topic_id, code, title, description,
    period_allocation, assessment_criteria, source_page, display_order, is_published
  ) values (
    v_main_id, v_subject_id, v_topic_id, '1.2', 'Demonstrate an understanding of basic numerical operations', 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.2. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.9).',
    30, 'Addition and subtraction of whole numbers is performed correctly', 9, 2, true
  )
  on conflict (topic_id) do update
    set main_competence_id = excluded.main_competence_id,
        code = excluded.code,
        title = excluded.title,
        description = excluded.description,
        period_allocation = excluded.period_allocation,
        assessment_criteria = excluded.assessment_criteria,
        source_page = excluded.source_page,
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now();

  -- Refresh official learning activity subtopics idempotently
  delete from public.subtopics where topic_id = v_topic_id;
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Addition and subtraction of whole numbers', 'TIE 2023 Mathematics Standard III (ISBN 978-9987-09-858-3, p.9)',
    'Addition and subtraction of whole numbers is performed correctly', 'Addition and subtraction of whole numbers is performed correctly', 30, 1, 9, true
  );

  -- Specific Competence 1.3: Demonstrate an understanding of measurements
  v_topic_id := null;
  select id into v_topic_id
  from public.topics
  where subject_id = v_subject_id and competency_code = '1.3';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Demonstrate an understanding of measurements', 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.3. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.10).', 3, true,
      '1.3', 22, 'Measurements of length, mass and volume are recognised accurately', 10
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Demonstrate an understanding of measurements',
        summary = 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.3. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.10).',
        display_order = 3,
        period_allocation = 22,
        assessment_criteria = 'Measurements of length, mass and volume are recognised accurately',
        source_page = 10,
        is_published = true,
        updated_at = now()
    where id = v_topic_id;
  end if;

  insert into public.curriculum_specific_competences (
    main_competence_id, subject_id, topic_id, code, title, description,
    period_allocation, assessment_criteria, source_page, display_order, is_published
  ) values (
    v_main_id, v_subject_id, v_topic_id, '1.3', 'Demonstrate an understanding of measurements', 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.3. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.10).',
    22, 'Measurements of length, mass and volume are recognised accurately', 10, 3, true
  )
  on conflict (topic_id) do update
    set main_competence_id = excluded.main_competence_id,
        code = excluded.code,
        title = excluded.title,
        description = excluded.description,
        period_allocation = excluded.period_allocation,
        assessment_criteria = excluded.assessment_criteria,
        source_page = excluded.source_page,
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now();

  -- Refresh official learning activity subtopics idempotently
  delete from public.subtopics where topic_id = v_topic_id;
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Recognise measurements of length, mass and volume', 'TIE 2023 Mathematics Standard III (ISBN 978-9987-09-858-3, p.10)',
    'Measurements of length, mass and volume are recognised accurately', 'Measurements of length, mass and volume are recognised accurately', 22, 1, 10, true
  );

  -- Specific Competence 1.4: Demonstrate an understanding of elementary geometry
  v_topic_id := null;
  select id into v_topic_id
  from public.topics
  where subject_id = v_subject_id and competency_code = '1.4';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Demonstrate an understanding of elementary geometry', 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.4. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.10).', 4, true,
      '1.4', 30, 'The concept of shape is clearly explained', 10
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Demonstrate an understanding of elementary geometry',
        summary = 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.4. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.10).',
        display_order = 4,
        period_allocation = 30,
        assessment_criteria = 'The concept of shape is clearly explained',
        source_page = 10,
        is_published = true,
        updated_at = now()
    where id = v_topic_id;
  end if;

  insert into public.curriculum_specific_competences (
    main_competence_id, subject_id, topic_id, code, title, description,
    period_allocation, assessment_criteria, source_page, display_order, is_published
  ) values (
    v_main_id, v_subject_id, v_topic_id, '1.4', 'Demonstrate an understanding of elementary geometry', 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.4. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.10).',
    30, 'The concept of shape is clearly explained', 10, 4, true
  )
  on conflict (topic_id) do update
    set main_competence_id = excluded.main_competence_id,
        code = excluded.code,
        title = excluded.title,
        description = excluded.description,
        period_allocation = excluded.period_allocation,
        assessment_criteria = excluded.assessment_criteria,
        source_page = excluded.source_page,
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now();

  -- Refresh official learning activity subtopics idempotently
  delete from public.subtopics where topic_id = v_topic_id;
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Explain the concept of shape', 'TIE 2023 Mathematics Standard III (ISBN 978-9987-09-858-3, p.10)',
    'The concept of shape is clearly explained', 'The concept of shape is clearly explained', 10, 1, 10, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Explain a point, line, line segment, and a ray', 'TIE 2023 Mathematics Standard III (ISBN 978-9987-09-858-3, p.11)',
    'Concept of a point, line, line segment and a ray are correctly explained', 'Concept of a point, line, line segment and a ray are correctly explained', 10, 2, 11, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(c) Construct plane figures using points, lines and line segments', 'TIE 2023 Mathematics Standard III (ISBN 978-9987-09-858-3, p.11)',
    'Plane figures are accurately constructed using point, line and line segment', 'Plane figures are accurately constructed using point, line and line segment', 10, 3, 11, true
  );

  -- Specific Competence 1.5: Demonstrate an understanding of elementary mathematical skills
  v_topic_id := null;
  select id into v_topic_id
  from public.topics
  where subject_id = v_subject_id and competency_code = '1.5';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Demonstrate an understanding of elementary mathematical skills', 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.5. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.12).', 5, true,
      '1.5', 26, 'The concept of fraction is clearly explained using division of objects', 12
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Demonstrate an understanding of elementary mathematical skills',
        summary = 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.5. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.12).',
        display_order = 5,
        period_allocation = 26,
        assessment_criteria = 'The concept of fraction is clearly explained using division of objects',
        source_page = 12,
        is_published = true,
        updated_at = now()
    where id = v_topic_id;
  end if;

  insert into public.curriculum_specific_competences (
    main_competence_id, subject_id, topic_id, code, title, description,
    period_allocation, assessment_criteria, source_page, display_order, is_published
  ) values (
    v_main_id, v_subject_id, v_topic_id, '1.5', 'Demonstrate an understanding of elementary mathematical skills', 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.5. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.12).',
    26, 'The concept of fraction is clearly explained using division of objects', 12, 5, true
  )
  on conflict (topic_id) do update
    set main_competence_id = excluded.main_competence_id,
        code = excluded.code,
        title = excluded.title,
        description = excluded.description,
        period_allocation = excluded.period_allocation,
        assessment_criteria = excluded.assessment_criteria,
        source_page = excluded.source_page,
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now();

  -- Refresh official learning activity subtopics idempotently
  delete from public.subtopics where topic_id = v_topic_id;
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Use division of objects to explain the concept of fraction', 'TIE 2023 Mathematics Standard III (ISBN 978-9987-09-858-3, p.12)',
    'The concept of fraction is clearly explained using division of objects', 'The concept of fraction is clearly explained using division of objects', 13, 1, 12, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Addition and subtraction of fractions of the same denominator', 'TIE 2023 Mathematics Standard III (ISBN 978-9987-09-858-3, p.12)',
    'Operations of addition and subtraction of fractions of the same denominator are performed correctly', 'Operations of addition and subtraction of fractions of the same denominator are performed correctly', 13, 2, 12, true
  );

  -- Main Competence 2.0: Demonstrate mastery of elementary application of mathematics
  insert into public.curriculum_main_competences (
    subject_id, curriculum_version_id, code, title, description, display_order, is_published
  ) values (
    v_subject_id, v_version_id, '2.0', 'Demonstrate mastery of elementary application of mathematics', 'Official 2023 TIE Mathematics Standard III Main Competence 2.0 (ISBN 978-9987-09-858-3).', 2, true
  )
  on conflict (subject_id, code) do update
    set title = excluded.title,
        description = excluded.description,
        curriculum_version_id = coalesce(excluded.curriculum_version_id, curriculum_main_competences.curriculum_version_id),
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now()
  returning id into v_main_id;

  -- Specific Competence 2.1: Demonstrate an understanding of the mathematics of time
  v_topic_id := null;
  select id into v_topic_id
  from public.topics
  where subject_id = v_subject_id and competency_code = '2.1';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Demonstrate an understanding of the mathematics of time', 'Main Competence 2.0: Demonstrate mastery of elementary application of mathematics. Specific Competence 2.1. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.13).', 6, true,
      '2.1', 36, 'Units of measuring time is clearly described', 13
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Demonstrate an understanding of the mathematics of time',
        summary = 'Main Competence 2.0: Demonstrate mastery of elementary application of mathematics. Specific Competence 2.1. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.13).',
        display_order = 6,
        period_allocation = 36,
        assessment_criteria = 'Units of measuring time is clearly described',
        source_page = 13,
        is_published = true,
        updated_at = now()
    where id = v_topic_id;
  end if;

  insert into public.curriculum_specific_competences (
    main_competence_id, subject_id, topic_id, code, title, description,
    period_allocation, assessment_criteria, source_page, display_order, is_published
  ) values (
    v_main_id, v_subject_id, v_topic_id, '2.1', 'Demonstrate an understanding of the mathematics of time', 'Main Competence 2.0: Demonstrate mastery of elementary application of mathematics. Specific Competence 2.1. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.13).',
    36, 'Units of measuring time is clearly described', 13, 1, true
  )
  on conflict (topic_id) do update
    set main_competence_id = excluded.main_competence_id,
        code = excluded.code,
        title = excluded.title,
        description = excluded.description,
        period_allocation = excluded.period_allocation,
        assessment_criteria = excluded.assessment_criteria,
        source_page = excluded.source_page,
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now();

  -- Refresh official learning activity subtopics idempotently
  delete from public.subtopics where topic_id = v_topic_id;
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Describe units of measuring time', 'TIE 2023 Mathematics Standard III (ISBN 978-9987-09-858-3, p.13)',
    'Units of measuring time is clearly described', 'Units of measuring time is clearly described', 9, 1, 13, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Describe time in 12-hour format', 'TIE 2023 Mathematics Standard III (ISBN 978-9987-09-858-3, p.13)',
    'Time in 12-hour format is accurately described', 'Time in 12-hour format is accurately described', 9, 2, 13, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(c) Describe time in 24-hour format', 'TIE 2023 Mathematics Standard III (ISBN 978-9987-09-858-3, p.13)',
    'Time in 24-hour format is accurately described', 'Time in 24-hour format is accurately described', 9, 3, 13, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(d) Recognise number of hours in a day, days in a week, weeks in a month, months in a year', 'TIE 2023 Mathematics Standard III (ISBN 978-9987-09-858-3, p.14)',
    'Number of hours in a day, days in a week, weeks in a month, months in a year are correctly recognised', 'Number of hours in a day, days in a week, weeks in a month, months in a year are correctly recognised', 9, 4, 14, true
  );

  -- Specific Competence 2.2: Demonstrate an understanding of financial mathematics
  v_topic_id := null;
  select id into v_topic_id
  from public.topics
  where subject_id = v_subject_id and competency_code = '2.2';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Demonstrate an understanding of financial mathematics', 'Main Competence 2.0: Demonstrate mastery of elementary application of mathematics. Specific Competence 2.2. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.14).', 7, true,
      '2.2', 38, 'The denomination of Tanzanian currency in shillings and cents is clearly recognised', 14
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Demonstrate an understanding of financial mathematics',
        summary = 'Main Competence 2.0: Demonstrate mastery of elementary application of mathematics. Specific Competence 2.2. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.14).',
        display_order = 7,
        period_allocation = 38,
        assessment_criteria = 'The denomination of Tanzanian currency in shillings and cents is clearly recognised',
        source_page = 14,
        is_published = true,
        updated_at = now()
    where id = v_topic_id;
  end if;

  insert into public.curriculum_specific_competences (
    main_competence_id, subject_id, topic_id, code, title, description,
    period_allocation, assessment_criteria, source_page, display_order, is_published
  ) values (
    v_main_id, v_subject_id, v_topic_id, '2.2', 'Demonstrate an understanding of financial mathematics', 'Main Competence 2.0: Demonstrate mastery of elementary application of mathematics. Specific Competence 2.2. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.14).',
    38, 'The denomination of Tanzanian currency in shillings and cents is clearly recognised', 14, 2, true
  )
  on conflict (topic_id) do update
    set main_competence_id = excluded.main_competence_id,
        code = excluded.code,
        title = excluded.title,
        description = excluded.description,
        period_allocation = excluded.period_allocation,
        assessment_criteria = excluded.assessment_criteria,
        source_page = excluded.source_page,
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now();

  -- Refresh official learning activity subtopics idempotently
  delete from public.subtopics where topic_id = v_topic_id;
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Recognise the denomination of Tanzanian currency in shillings and cents', 'TIE 2023 Mathematics Standard III (ISBN 978-9987-09-858-3, p.14)',
    'The denomination of Tanzanian currency in shillings and cents is clearly recognised', 'The denomination of Tanzanian currency in shillings and cents is clearly recognised', 19, 1, 14, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Addition and subtraction of Tanzanian currency', 'TIE 2023 Mathematics Standard III (ISBN 978-9987-09-858-3, p.15)',
    'Operations of addition and subtraction of amounts of money in shillings and cents are performed correctly', 'Operations of addition and subtraction of amounts of money in shillings and cents are performed correctly', 19, 2, 15, true
  );

end $$;

-- ============================================================================
-- Mathematics — Standard IV (STANDARD_4): 234 periods
-- ============================================================================
do $$
declare
  v_curriculum_id uuid;
  v_level_id uuid;
  v_grade_id uuid;
  v_version_id uuid;
  v_subject_id uuid;
  v_main_id uuid;
  v_topic_id uuid;
begin
  -- Natural-key resolution: Country (TZ) -> Curriculum (TIE) -> Level (PRIMARY) -> Grade
  select id into v_curriculum_id
  from public.curricula
  where country_code = 'TZ' and code = 'TIE'
  limit 1;
  if v_curriculum_id is null then
    raise exception 'Natural-key resolution failed: TZ TIE curriculum not found';
  end if;

  select id into v_level_id
  from public.education_levels
  where curriculum_id = v_curriculum_id and code = 'PRIMARY'
  limit 1;
  if v_level_id is null then
    raise exception 'Natural-key resolution failed: PRIMARY education level not found for TIE curriculum';
  end if;

  select id into v_grade_id
  from public.education_grades
  where curriculum_id = v_curriculum_id and education_level_id = v_level_id and code = 'STANDARD_4'
  limit 1;
  if v_grade_id is null then
    raise exception 'Natural-key resolution failed: education grade STANDARD_4 not found for TIE PRIMARY';
  end if;

  select id into v_version_id
  from public.curriculum_versions
  where curriculum_id = v_curriculum_id and version_code = 'TIE_PRIMARY_2023'
  limit 1;

  -- Upsert grade-scoped subject by natural key (curriculum_id, education_level_id, grade_id, code)
  select id into v_subject_id
  from public.subjects
  where country_code = 'TZ'
    and curriculum_id = v_curriculum_id
    and education_level_id = v_level_id
    and grade_id = v_grade_id
    and code = 'tie-pri-mathematics-standard4';

  if v_subject_id is null then
    insert into public.subjects (
      country_code, curriculum_id, education_level_id, grade_id,
      code, name, official_name, description, display_order, is_published, classification, language
    ) values (
      'TZ', v_curriculum_id, v_level_id, v_grade_id,
      'tie-pri-mathematics-standard4', 'Mathematics', 'Mathematics Syllabus for Primary Education — Standard IV', 'Official 2023 TIE Mathematics syllabus for Standard IV (234 periods, 6 periods/week; ISBN 978-9987-09-858-3).',
      4, true, 'compulsory', 'en'
    ) returning id into v_subject_id;
  else
    update public.subjects
    set name = 'Mathematics',
        official_name = 'Mathematics Syllabus for Primary Education — Standard IV',
        description = 'Official 2023 TIE Mathematics syllabus for Standard IV (234 periods, 6 periods/week; ISBN 978-9987-09-858-3).',
        display_order = 4,
        is_published = true,
        classification = 'compulsory',
        language = 'en',
        updated_at = now()
    where id = v_subject_id;
  end if;

  -- Main Competence 1.0: Demonstrate mastery of elementary mathematical skills
  insert into public.curriculum_main_competences (
    subject_id, curriculum_version_id, code, title, description, display_order, is_published
  ) values (
    v_subject_id, v_version_id, '1.0', 'Demonstrate mastery of elementary mathematical skills', 'Official 2023 TIE Mathematics Standard IV Main Competence 1.0 (ISBN 978-9987-09-858-3).', 1, true
  )
  on conflict (subject_id, code) do update
    set title = excluded.title,
        description = excluded.description,
        curriculum_version_id = coalesce(excluded.curriculum_version_id, curriculum_main_competences.curriculum_version_id),
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now()
  returning id into v_main_id;

  -- Specific Competence 1.1: Demonstrate an understanding of the concept of numbers
  v_topic_id := null;
  select id into v_topic_id
  from public.topics
  where subject_id = v_subject_id and competency_code = '1.1';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Demonstrate an understanding of the concept of numbers', 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.1. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.16).', 1, true,
      '1.1', 12, 'Roman numbers are correctly recognised', 16
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Demonstrate an understanding of the concept of numbers',
        summary = 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.1. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.16).',
        display_order = 1,
        period_allocation = 12,
        assessment_criteria = 'Roman numbers are correctly recognised',
        source_page = 16,
        is_published = true,
        updated_at = now()
    where id = v_topic_id;
  end if;

  insert into public.curriculum_specific_competences (
    main_competence_id, subject_id, topic_id, code, title, description,
    period_allocation, assessment_criteria, source_page, display_order, is_published
  ) values (
    v_main_id, v_subject_id, v_topic_id, '1.1', 'Demonstrate an understanding of the concept of numbers', 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.1. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.16).',
    12, 'Roman numbers are correctly recognised', 16, 1, true
  )
  on conflict (topic_id) do update
    set main_competence_id = excluded.main_competence_id,
        code = excluded.code,
        title = excluded.title,
        description = excluded.description,
        period_allocation = excluded.period_allocation,
        assessment_criteria = excluded.assessment_criteria,
        source_page = excluded.source_page,
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now();

  -- Refresh official learning activity subtopics idempotently
  delete from public.subtopics where topic_id = v_topic_id;
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Recognise Roman numbers (up to M)', 'TIE 2023 Mathematics Standard IV (ISBN 978-9987-09-858-3, p.16)',
    'Roman numbers are correctly recognised', 'Roman numbers are correctly recognised', 12, 1, 16, true
  );

  -- Specific Competence 1.2: Demonstrate an understanding of basic numerical operations
  v_topic_id := null;
  select id into v_topic_id
  from public.topics
  where subject_id = v_subject_id and competency_code = '1.2';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Demonstrate an understanding of basic numerical operations', 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.2. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.16).', 2, true,
      '1.2', 26, 'Whole numbers are correctly multiplied and divided', 16
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Demonstrate an understanding of basic numerical operations',
        summary = 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.2. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.16).',
        display_order = 2,
        period_allocation = 26,
        assessment_criteria = 'Whole numbers are correctly multiplied and divided',
        source_page = 16,
        is_published = true,
        updated_at = now()
    where id = v_topic_id;
  end if;

  insert into public.curriculum_specific_competences (
    main_competence_id, subject_id, topic_id, code, title, description,
    period_allocation, assessment_criteria, source_page, display_order, is_published
  ) values (
    v_main_id, v_subject_id, v_topic_id, '1.2', 'Demonstrate an understanding of basic numerical operations', 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.2. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.16).',
    26, 'Whole numbers are correctly multiplied and divided', 16, 2, true
  )
  on conflict (topic_id) do update
    set main_competence_id = excluded.main_competence_id,
        code = excluded.code,
        title = excluded.title,
        description = excluded.description,
        period_allocation = excluded.period_allocation,
        assessment_criteria = excluded.assessment_criteria,
        source_page = excluded.source_page,
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now();

  -- Refresh official learning activity subtopics idempotently
  delete from public.subtopics where topic_id = v_topic_id;
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Multiplication and division of whole numbers', 'TIE 2023 Mathematics Standard IV (ISBN 978-9987-09-858-3, p.16)',
    'Whole numbers are correctly multiplied and divided', 'Whole numbers are correctly multiplied and divided', 26, 1, 16, true
  );

  -- Specific Competence 1.3: Demonstrate an understanding of measurements
  v_topic_id := null;
  select id into v_topic_id
  from public.topics
  where subject_id = v_subject_id and competency_code = '1.3';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Demonstrate an understanding of measurements', 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.3. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.17).', 3, true,
      '1.3', 38, 'Various components of the measures of length, mass, and volume are correctly converted', 17
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Demonstrate an understanding of measurements',
        summary = 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.3. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.17).',
        display_order = 3,
        period_allocation = 38,
        assessment_criteria = 'Various components of the measures of length, mass, and volume are correctly converted',
        source_page = 17,
        is_published = true,
        updated_at = now()
    where id = v_topic_id;
  end if;

  insert into public.curriculum_specific_competences (
    main_competence_id, subject_id, topic_id, code, title, description,
    period_allocation, assessment_criteria, source_page, display_order, is_published
  ) values (
    v_main_id, v_subject_id, v_topic_id, '1.3', 'Demonstrate an understanding of measurements', 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.3. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.17).',
    38, 'Various components of the measures of length, mass, and volume are correctly converted', 17, 3, true
  )
  on conflict (topic_id) do update
    set main_competence_id = excluded.main_competence_id,
        code = excluded.code,
        title = excluded.title,
        description = excluded.description,
        period_allocation = excluded.period_allocation,
        assessment_criteria = excluded.assessment_criteria,
        source_page = excluded.source_page,
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now();

  -- Refresh official learning activity subtopics idempotently
  delete from public.subtopics where topic_id = v_topic_id;
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Convert between the various components of the measures of length, mass, and volume (millimetres to kilometres, milligrams to tonnes, and millilitres to litres)', 'TIE 2023 Mathematics Standard IV (ISBN 978-9987-09-858-3, p.17)',
    'Various components of the measures of length, mass, and volume are correctly converted', 'Various components of the measures of length, mass, and volume are correctly converted', 19, 1, 17, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Addition and subtraction of measurements for length, mass and volume', 'TIE 2023 Mathematics Standard IV (ISBN 978-9987-09-858-3, p.17)',
    'Addition and subtraction of measurement for length, mass and volume are correctly performed', 'Addition and subtraction of measurement for length, mass and volume are correctly performed', 19, 2, 17, true
  );

  -- Specific Competence 1.4: Demonstrate an understanding of elementary geometry
  v_topic_id := null;
  select id into v_topic_id
  from public.topics
  where subject_id = v_subject_id and competency_code = '1.4';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Demonstrate an understanding of elementary geometry', 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.4. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.17).', 4, true,
      '1.4', 32, 'Perimeters and areas of plane figures are calculated correctly', 17
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Demonstrate an understanding of elementary geometry',
        summary = 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.4. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.17).',
        display_order = 4,
        period_allocation = 32,
        assessment_criteria = 'Perimeters and areas of plane figures are calculated correctly',
        source_page = 17,
        is_published = true,
        updated_at = now()
    where id = v_topic_id;
  end if;

  insert into public.curriculum_specific_competences (
    main_competence_id, subject_id, topic_id, code, title, description,
    period_allocation, assessment_criteria, source_page, display_order, is_published
  ) values (
    v_main_id, v_subject_id, v_topic_id, '1.4', 'Demonstrate an understanding of elementary geometry', 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.4. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.17).',
    32, 'Perimeters and areas of plane figures are calculated correctly', 17, 4, true
  )
  on conflict (topic_id) do update
    set main_competence_id = excluded.main_competence_id,
        code = excluded.code,
        title = excluded.title,
        description = excluded.description,
        period_allocation = excluded.period_allocation,
        assessment_criteria = excluded.assessment_criteria,
        source_page = excluded.source_page,
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now();

  -- Refresh official learning activity subtopics idempotently
  delete from public.subtopics where topic_id = v_topic_id;
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Calculate the perimeters and areas of plane figures (rectangle, square and triangle)', 'TIE 2023 Mathematics Standard IV (ISBN 978-9987-09-858-3, p.17)',
    'Perimeters and areas of plane figures are calculated correctly', 'Perimeters and areas of plane figures are calculated correctly', 32, 1, 17, true
  );

  -- Specific Competence 1.5: Demonstrate an understanding of elementary mathematical skills
  v_topic_id := null;
  select id into v_topic_id
  from public.topics
  where subject_id = v_subject_id and competency_code = '1.5';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Demonstrate an understanding of elementary mathematical skills', 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.5. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.18).', 5, true,
      '1.5', 66, 'Comparing fractions by using =, <, and > is performed correctly', 18
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Demonstrate an understanding of elementary mathematical skills',
        summary = 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.5. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.18).',
        display_order = 5,
        period_allocation = 66,
        assessment_criteria = 'Comparing fractions by using =, <, and > is performed correctly',
        source_page = 18,
        is_published = true,
        updated_at = now()
    where id = v_topic_id;
  end if;

  insert into public.curriculum_specific_competences (
    main_competence_id, subject_id, topic_id, code, title, description,
    period_allocation, assessment_criteria, source_page, display_order, is_published
  ) values (
    v_main_id, v_subject_id, v_topic_id, '1.5', 'Demonstrate an understanding of elementary mathematical skills', 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.5. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.18).',
    66, 'Comparing fractions by using =, <, and > is performed correctly', 18, 5, true
  )
  on conflict (topic_id) do update
    set main_competence_id = excluded.main_competence_id,
        code = excluded.code,
        title = excluded.title,
        description = excluded.description,
        period_allocation = excluded.period_allocation,
        assessment_criteria = excluded.assessment_criteria,
        source_page = excluded.source_page,
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now();

  -- Refresh official learning activity subtopics idempotently
  delete from public.subtopics where topic_id = v_topic_id;
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Compare fractions by using =, <, and > signs', 'TIE 2023 Mathematics Standard IV (ISBN 978-9987-09-858-3, p.18)',
    'Comparing fractions by using =, <, and > is performed correctly', 'Comparing fractions by using =, <, and > is performed correctly', 17, 1, 18, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Multiplication and division of fractions', 'TIE 2023 Mathematics Standard IV (ISBN 978-9987-09-858-3, p.18)',
    'Multiplication and division of fractions are correctly performed', 'Multiplication and division of fractions are correctly performed', 17, 2, 18, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(c) Explain the concept of decimals', 'TIE 2023 Mathematics Standard IV (ISBN 978-9987-09-858-3, p.18)',
    'Concept of decimals is explained correctly', 'Concept of decimals is explained correctly', 16, 3, 18, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(d) Addition and subtraction of decimals', 'TIE 2023 Mathematics Standard IV (ISBN 978-9987-09-858-3, p.19)',
    'Addition and subtraction of decimals are performed correctly', 'Addition and subtraction of decimals are performed correctly', 16, 4, 19, true
  );

  -- Main Competence 2.0: Demonstrate mastery of elementary application of mathematics
  insert into public.curriculum_main_competences (
    subject_id, curriculum_version_id, code, title, description, display_order, is_published
  ) values (
    v_subject_id, v_version_id, '2.0', 'Demonstrate mastery of elementary application of mathematics', 'Official 2023 TIE Mathematics Standard IV Main Competence 2.0 (ISBN 978-9987-09-858-3).', 2, true
  )
  on conflict (subject_id, code) do update
    set title = excluded.title,
        description = excluded.description,
        curriculum_version_id = coalesce(excluded.curriculum_version_id, curriculum_main_competences.curriculum_version_id),
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now()
  returning id into v_main_id;

  -- Specific Competence 2.1: Demonstrate an understanding of the mathematics of time
  v_topic_id := null;
  select id into v_topic_id
  from public.topics
  where subject_id = v_subject_id and competency_code = '2.1';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Demonstrate an understanding of the mathematics of time', 'Main Competence 2.0: Demonstrate mastery of elementary application of mathematics. Specific Competence 2.1. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.19).', 6, true,
      '2.1', 34, 'Measures of time between their component are correctly converted', 19
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Demonstrate an understanding of the mathematics of time',
        summary = 'Main Competence 2.0: Demonstrate mastery of elementary application of mathematics. Specific Competence 2.1. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.19).',
        display_order = 6,
        period_allocation = 34,
        assessment_criteria = 'Measures of time between their component are correctly converted',
        source_page = 19,
        is_published = true,
        updated_at = now()
    where id = v_topic_id;
  end if;

  insert into public.curriculum_specific_competences (
    main_competence_id, subject_id, topic_id, code, title, description,
    period_allocation, assessment_criteria, source_page, display_order, is_published
  ) values (
    v_main_id, v_subject_id, v_topic_id, '2.1', 'Demonstrate an understanding of the mathematics of time', 'Main Competence 2.0: Demonstrate mastery of elementary application of mathematics. Specific Competence 2.1. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.19).',
    34, 'Measures of time between their component are correctly converted', 19, 1, true
  )
  on conflict (topic_id) do update
    set main_competence_id = excluded.main_competence_id,
        code = excluded.code,
        title = excluded.title,
        description = excluded.description,
        period_allocation = excluded.period_allocation,
        assessment_criteria = excluded.assessment_criteria,
        source_page = excluded.source_page,
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now();

  -- Refresh official learning activity subtopics idempotently
  delete from public.subtopics where topic_id = v_topic_id;
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Convert between the components of measures of time (seconds to hours)', 'TIE 2023 Mathematics Standard IV (ISBN 978-9987-09-858-3, p.19)',
    'Measures of time between their component are correctly converted', 'Measures of time between their component are correctly converted', 17, 1, 19, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Addition and subtraction of time', 'TIE 2023 Mathematics Standard IV (ISBN 978-9987-09-858-3, p.19)',
    'Addition and subtraction of time is done correctly', 'Addition and subtraction of time is done correctly', 17, 2, 19, true
  );

  -- Specific Competence 2.2: Demonstrate an understanding of financial mathematics
  v_topic_id := null;
  select id into v_topic_id
  from public.topics
  where subject_id = v_subject_id and competency_code = '2.2';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Demonstrate an understanding of financial mathematics', 'Main Competence 2.0: Demonstrate mastery of elementary application of mathematics. Specific Competence 2.2. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.19).', 7, true,
      '2.2', 26, 'Multiplication and division of Tanzanian currency is performed correctly', 19
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Demonstrate an understanding of financial mathematics',
        summary = 'Main Competence 2.0: Demonstrate mastery of elementary application of mathematics. Specific Competence 2.2. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.19).',
        display_order = 7,
        period_allocation = 26,
        assessment_criteria = 'Multiplication and division of Tanzanian currency is performed correctly',
        source_page = 19,
        is_published = true,
        updated_at = now()
    where id = v_topic_id;
  end if;

  insert into public.curriculum_specific_competences (
    main_competence_id, subject_id, topic_id, code, title, description,
    period_allocation, assessment_criteria, source_page, display_order, is_published
  ) values (
    v_main_id, v_subject_id, v_topic_id, '2.2', 'Demonstrate an understanding of financial mathematics', 'Main Competence 2.0: Demonstrate mastery of elementary application of mathematics. Specific Competence 2.2. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.19).',
    26, 'Multiplication and division of Tanzanian currency is performed correctly', 19, 2, true
  )
  on conflict (topic_id) do update
    set main_competence_id = excluded.main_competence_id,
        code = excluded.code,
        title = excluded.title,
        description = excluded.description,
        period_allocation = excluded.period_allocation,
        assessment_criteria = excluded.assessment_criteria,
        source_page = excluded.source_page,
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now();

  -- Refresh official learning activity subtopics idempotently
  delete from public.subtopics where topic_id = v_topic_id;
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Multiplication and division of Tanzanian currency', 'TIE 2023 Mathematics Standard IV (ISBN 978-9987-09-858-3, p.19)',
    'Multiplication and division of Tanzanian currency is performed correctly', 'Multiplication and division of Tanzanian currency is performed correctly', 26, 1, 19, true
  );

end $$;

-- ============================================================================
-- Mathematics — Standard V (STANDARD_5): 240 periods
-- ============================================================================
do $$
declare
  v_curriculum_id uuid;
  v_level_id uuid;
  v_grade_id uuid;
  v_version_id uuid;
  v_subject_id uuid;
  v_main_id uuid;
  v_topic_id uuid;
begin
  -- Natural-key resolution: Country (TZ) -> Curriculum (TIE) -> Level (PRIMARY) -> Grade
  select id into v_curriculum_id
  from public.curricula
  where country_code = 'TZ' and code = 'TIE'
  limit 1;
  if v_curriculum_id is null then
    raise exception 'Natural-key resolution failed: TZ TIE curriculum not found';
  end if;

  select id into v_level_id
  from public.education_levels
  where curriculum_id = v_curriculum_id and code = 'PRIMARY'
  limit 1;
  if v_level_id is null then
    raise exception 'Natural-key resolution failed: PRIMARY education level not found for TIE curriculum';
  end if;

  select id into v_grade_id
  from public.education_grades
  where curriculum_id = v_curriculum_id and education_level_id = v_level_id and code = 'STANDARD_5'
  limit 1;
  if v_grade_id is null then
    raise exception 'Natural-key resolution failed: education grade STANDARD_5 not found for TIE PRIMARY';
  end if;

  select id into v_version_id
  from public.curriculum_versions
  where curriculum_id = v_curriculum_id and version_code = 'TIE_PRIMARY_2023'
  limit 1;

  -- Upsert grade-scoped subject by natural key (curriculum_id, education_level_id, grade_id, code)
  select id into v_subject_id
  from public.subjects
  where country_code = 'TZ'
    and curriculum_id = v_curriculum_id
    and education_level_id = v_level_id
    and grade_id = v_grade_id
    and code = 'tie-pri-mathematics-standard5';

  if v_subject_id is null then
    insert into public.subjects (
      country_code, curriculum_id, education_level_id, grade_id,
      code, name, official_name, description, display_order, is_published, classification, language
    ) values (
      'TZ', v_curriculum_id, v_level_id, v_grade_id,
      'tie-pri-mathematics-standard5', 'Mathematics', 'Mathematics Syllabus for Primary Education — Standard V', 'Official 2023 TIE Mathematics syllabus for Standard V (240 periods, 6 periods/week; ISBN 978-9987-09-858-3).',
      4, true, 'compulsory', 'en'
    ) returning id into v_subject_id;
  else
    update public.subjects
    set name = 'Mathematics',
        official_name = 'Mathematics Syllabus for Primary Education — Standard V',
        description = 'Official 2023 TIE Mathematics syllabus for Standard V (240 periods, 6 periods/week; ISBN 978-9987-09-858-3).',
        display_order = 4,
        is_published = true,
        classification = 'compulsory',
        language = 'en',
        updated_at = now()
    where id = v_subject_id;
  end if;

  -- Main Competence 1.0: Demonstrate mastery of elementary mathematical skills
  insert into public.curriculum_main_competences (
    subject_id, curriculum_version_id, code, title, description, display_order, is_published
  ) values (
    v_subject_id, v_version_id, '1.0', 'Demonstrate mastery of elementary mathematical skills', 'Official 2023 TIE Mathematics Standard V Main Competence 1.0 (ISBN 978-9987-09-858-3).', 1, true
  )
  on conflict (subject_id, code) do update
    set title = excluded.title,
        description = excluded.description,
        curriculum_version_id = coalesce(excluded.curriculum_version_id, curriculum_main_competences.curriculum_version_id),
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now()
  returning id into v_main_id;

  -- Specific Competence 1.1: Demonstrate an understanding of measurements
  v_topic_id := null;
  select id into v_topic_id
  from public.topics
  where subject_id = v_subject_id and competency_code = '1.1';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Demonstrate an understanding of measurements', 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.1. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.20).', 1, true,
      '1.1', 44, 'Measurements for length, mass and volume are correctly multiplied', 20
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Demonstrate an understanding of measurements',
        summary = 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.1. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.20).',
        display_order = 1,
        period_allocation = 44,
        assessment_criteria = 'Measurements for length, mass and volume are correctly multiplied',
        source_page = 20,
        is_published = true,
        updated_at = now()
    where id = v_topic_id;
  end if;

  insert into public.curriculum_specific_competences (
    main_competence_id, subject_id, topic_id, code, title, description,
    period_allocation, assessment_criteria, source_page, display_order, is_published
  ) values (
    v_main_id, v_subject_id, v_topic_id, '1.1', 'Demonstrate an understanding of measurements', 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.1. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.20).',
    44, 'Measurements for length, mass and volume are correctly multiplied', 20, 1, true
  )
  on conflict (topic_id) do update
    set main_competence_id = excluded.main_competence_id,
        code = excluded.code,
        title = excluded.title,
        description = excluded.description,
        period_allocation = excluded.period_allocation,
        assessment_criteria = excluded.assessment_criteria,
        source_page = excluded.source_page,
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now();

  -- Refresh official learning activity subtopics idempotently
  delete from public.subtopics where topic_id = v_topic_id;
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Multiplication of measurements for length, mass and volume', 'TIE 2023 Mathematics Standard V (ISBN 978-9987-09-858-3, p.20)',
    'Measurements for length, mass and volume are correctly multiplied', 'Measurements for length, mass and volume are correctly multiplied', 22, 1, 20, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Division of measurements for length, mass and volume', 'TIE 2023 Mathematics Standard V (ISBN 978-9987-09-858-3, p.20)',
    'Measurements for length, mass and volume are correctly divided', 'Measurements for length, mass and volume are correctly divided', 22, 2, 20, true
  );

  -- Specific Competence 1.2: Demonstrate an understanding of elementary geometry
  v_topic_id := null;
  select id into v_topic_id
  from public.topics
  where subject_id = v_subject_id and competency_code = '1.2';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Demonstrate an understanding of elementary geometry', 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.2. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.21).', 2, true,
      '1.2', 62, 'Concept of pi is correctly explained', 21
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Demonstrate an understanding of elementary geometry',
        summary = 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.2. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.21).',
        display_order = 2,
        period_allocation = 62,
        assessment_criteria = 'Concept of pi is correctly explained',
        source_page = 21,
        is_published = true,
        updated_at = now()
    where id = v_topic_id;
  end if;

  insert into public.curriculum_specific_competences (
    main_competence_id, subject_id, topic_id, code, title, description,
    period_allocation, assessment_criteria, source_page, display_order, is_published
  ) values (
    v_main_id, v_subject_id, v_topic_id, '1.2', 'Demonstrate an understanding of elementary geometry', 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.2. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.21).',
    62, 'Concept of pi is correctly explained', 21, 2, true
  )
  on conflict (topic_id) do update
    set main_competence_id = excluded.main_competence_id,
        code = excluded.code,
        title = excluded.title,
        description = excluded.description,
        period_allocation = excluded.period_allocation,
        assessment_criteria = excluded.assessment_criteria,
        source_page = excluded.source_page,
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now();

  -- Refresh official learning activity subtopics idempotently
  delete from public.subtopics where topic_id = v_topic_id;
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Explain the concept of pi', 'TIE 2023 Mathematics Standard V (ISBN 978-9987-09-858-3, p.21)',
    'Concept of pi is correctly explained', 'Concept of pi is correctly explained', 21, 1, 21, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Calculate the circumference of a circle', 'TIE 2023 Mathematics Standard V (ISBN 978-9987-09-858-3, p.21)',
    'The circumference of a circle is correctly calculated', 'The circumference of a circle is correctly calculated', 21, 2, 21, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(c) Calculate the area of a circle', 'TIE 2023 Mathematics Standard V (ISBN 978-9987-09-858-3, p.21)',
    'Area of a circle is correctly calculated', 'Area of a circle is correctly calculated', 20, 3, 21, true
  );

  -- Specific Competence 1.3: Demonstrate an understanding of elementary mathematical skills
  v_topic_id := null;
  select id into v_topic_id
  from public.topics
  where subject_id = v_subject_id and competency_code = '1.3';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Demonstrate an understanding of elementary mathematical skills', 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.3. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.22).', 3, true,
      '1.3', 68, 'Even, odd and prime numbers are correctly identified', 22
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Demonstrate an understanding of elementary mathematical skills',
        summary = 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.3. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.22).',
        display_order = 3,
        period_allocation = 68,
        assessment_criteria = 'Even, odd and prime numbers are correctly identified',
        source_page = 22,
        is_published = true,
        updated_at = now()
    where id = v_topic_id;
  end if;

  insert into public.curriculum_specific_competences (
    main_competence_id, subject_id, topic_id, code, title, description,
    period_allocation, assessment_criteria, source_page, display_order, is_published
  ) values (
    v_main_id, v_subject_id, v_topic_id, '1.3', 'Demonstrate an understanding of elementary mathematical skills', 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.3. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.22).',
    68, 'Even, odd and prime numbers are correctly identified', 22, 3, true
  )
  on conflict (topic_id) do update
    set main_competence_id = excluded.main_competence_id,
        code = excluded.code,
        title = excluded.title,
        description = excluded.description,
        period_allocation = excluded.period_allocation,
        assessment_criteria = excluded.assessment_criteria,
        source_page = excluded.source_page,
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now();

  -- Refresh official learning activity subtopics idempotently
  delete from public.subtopics where topic_id = v_topic_id;
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Identify even, odd and prime numbers', 'TIE 2023 Mathematics Standard V (ISBN 978-9987-09-858-3, p.22)',
    'Even, odd and prime numbers are correctly identified', 'Even, odd and prime numbers are correctly identified', 9, 1, 22, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Calculate factors and multiples of numbers not exceeding three digits', 'TIE 2023 Mathematics Standard V (ISBN 978-9987-09-858-3, p.22)',
    'Factors and multiples of numbers not exceeding three digits are correctly calculated', 'Factors and multiples of numbers not exceeding three digits are correctly calculated', 9, 2, 22, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(c) Calculate the Lowest Common Multiple (LCM) and Greatest Common Factor (GCF) of whole numbers', 'TIE 2023 Mathematics Standard V (ISBN 978-9987-09-858-3, p.22)',
    'Lowest Common Multiple (LCM) and Greatest Common Factor (GCF) of whole numbers are correctly calculated', 'Lowest Common Multiple (LCM) and Greatest Common Factor (GCF) of whole numbers are correctly calculated', 9, 3, 22, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(d) Addition and subtraction of fractions with different denominators', 'TIE 2023 Mathematics Standard V (ISBN 978-9987-09-858-3, p.23)',
    'Fractions with different denominators are correctly added and subtracted', 'Fractions with different denominators are correctly added and subtracted', 9, 4, 23, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(e) Addition and subtraction of mixed fractions', 'TIE 2023 Mathematics Standard V (ISBN 978-9987-09-858-3, p.23)',
    'Mixed fractions are correctly added and subtracted', 'Mixed fractions are correctly added and subtracted', 8, 5, 23, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(f) Multiplication of decimals', 'TIE 2023 Mathematics Standard V (ISBN 978-9987-09-858-3, p.23)',
    'Decimals are correctly multiplied', 'Decimals are correctly multiplied', 8, 6, 23, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(g) Divide numbers to obtain an answer with no more than three decimal places', 'TIE 2023 Mathematics Standard V (ISBN 978-9987-09-858-3, p.24)',
    'Decimals to get answer with no more than three decimal places are correctly divided', 'Decimals to get answer with no more than three decimal places are correctly divided', 8, 7, 24, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(h) Convert percentages into fractions and decimals', 'TIE 2023 Mathematics Standard V (ISBN 978-9987-09-858-3, p.24)',
    'Percentages into fractions and decimals are correctly identified', 'Percentages into fractions and decimals are correctly identified', 8, 8, 24, true
  );

  -- Specific Competence 1.4: Demonstrate an elementary understanding of algebra
  v_topic_id := null;
  select id into v_topic_id
  from public.topics
  where subject_id = v_subject_id and competency_code = '1.4';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Demonstrate an elementary understanding of algebra', 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.4. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.25).', 4, true,
      '1.4', 54, 'Concept of algebra is correctly explained', 25
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Demonstrate an elementary understanding of algebra',
        summary = 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.4. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.25).',
        display_order = 4,
        period_allocation = 54,
        assessment_criteria = 'Concept of algebra is correctly explained',
        source_page = 25,
        is_published = true,
        updated_at = now()
    where id = v_topic_id;
  end if;

  insert into public.curriculum_specific_competences (
    main_competence_id, subject_id, topic_id, code, title, description,
    period_allocation, assessment_criteria, source_page, display_order, is_published
  ) values (
    v_main_id, v_subject_id, v_topic_id, '1.4', 'Demonstrate an elementary understanding of algebra', 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.4. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.25).',
    54, 'Concept of algebra is correctly explained', 25, 4, true
  )
  on conflict (topic_id) do update
    set main_competence_id = excluded.main_competence_id,
        code = excluded.code,
        title = excluded.title,
        description = excluded.description,
        period_allocation = excluded.period_allocation,
        assessment_criteria = excluded.assessment_criteria,
        source_page = excluded.source_page,
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now();

  -- Refresh official learning activity subtopics idempotently
  delete from public.subtopics where topic_id = v_topic_id;
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Explain the concept of algebra', 'TIE 2023 Mathematics Standard V (ISBN 978-9987-09-858-3, p.25)',
    'Concept of algebra is correctly explained', 'Concept of algebra is correctly explained', 11, 1, 25, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Identify term, variables, and coefficients in algebraic expressions', 'TIE 2023 Mathematics Standard V (ISBN 978-9987-09-858-3, p.25)',
    'Term, variables, and coefficients of algebraic expressions are correctly identified', 'Term, variables, and coefficients of algebraic expressions are correctly identified', 11, 2, 25, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(c) Write algebraic equations', 'TIE 2023 Mathematics Standard V (ISBN 978-9987-09-858-3, p.25)',
    'Algebraic equations are correctly written', 'Algebraic equations are correctly written', 11, 3, 25, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(d) Simplify algebraic expressions using the right sequence of mathematical operations', 'TIE 2023 Mathematics Standard V (ISBN 978-9987-09-858-3, p.26)',
    'Algebraic expressions using the right sequence of mathematical operations are correctly simplified', 'Algebraic expressions using the right sequence of mathematical operations are correctly simplified', 11, 4, 26, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(e) Calculate simple equations', 'TIE 2023 Mathematics Standard V (ISBN 978-9987-09-858-3, p.26)',
    'Simple algebraic equations are correctly calculated', 'Simple algebraic equations are correctly calculated', 10, 5, 26, true
  );

  -- Main Competence 2.0: Demonstrate mastery of elementary application of mathematics
  insert into public.curriculum_main_competences (
    subject_id, curriculum_version_id, code, title, description, display_order, is_published
  ) values (
    v_subject_id, v_version_id, '2.0', 'Demonstrate mastery of elementary application of mathematics', 'Official 2023 TIE Mathematics Standard V Main Competence 2.0 (ISBN 978-9987-09-858-3).', 2, true
  )
  on conflict (subject_id, code) do update
    set title = excluded.title,
        description = excluded.description,
        curriculum_version_id = coalesce(excluded.curriculum_version_id, curriculum_main_competences.curriculum_version_id),
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now()
  returning id into v_main_id;

  -- Specific Competence 2.1: Demonstrate an understanding of financial mathematics
  v_topic_id := null;
  select id into v_topic_id
  from public.topics
  where subject_id = v_subject_id and competency_code = '2.1';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Demonstrate an understanding of financial mathematics', 'Main Competence 2.0: Demonstrate mastery of elementary application of mathematics. Specific Competence 2.1. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.27).', 5, true,
      '2.1', 12, 'Problems involving sale and purchase correctly solved', 27
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Demonstrate an understanding of financial mathematics',
        summary = 'Main Competence 2.0: Demonstrate mastery of elementary application of mathematics. Specific Competence 2.1. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.27).',
        display_order = 5,
        period_allocation = 12,
        assessment_criteria = 'Problems involving sale and purchase correctly solved',
        source_page = 27,
        is_published = true,
        updated_at = now()
    where id = v_topic_id;
  end if;

  insert into public.curriculum_specific_competences (
    main_competence_id, subject_id, topic_id, code, title, description,
    period_allocation, assessment_criteria, source_page, display_order, is_published
  ) values (
    v_main_id, v_subject_id, v_topic_id, '2.1', 'Demonstrate an understanding of financial mathematics', 'Main Competence 2.0: Demonstrate mastery of elementary application of mathematics. Specific Competence 2.1. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.27).',
    12, 'Problems involving sale and purchase correctly solved', 27, 1, true
  )
  on conflict (topic_id) do update
    set main_competence_id = excluded.main_competence_id,
        code = excluded.code,
        title = excluded.title,
        description = excluded.description,
        period_allocation = excluded.period_allocation,
        assessment_criteria = excluded.assessment_criteria,
        source_page = excluded.source_page,
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now();

  -- Refresh official learning activity subtopics idempotently
  delete from public.subtopics where topic_id = v_topic_id;
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Solve problems involving sale and purchase', 'TIE 2023 Mathematics Standard V (ISBN 978-9987-09-858-3, p.27)',
    'Problems involving sale and purchase correctly solved', 'Problems involving sale and purchase correctly solved', 12, 1, 27, true
  );

end $$;

-- ============================================================================
-- Mathematics — Standard VI (STANDARD_6): 234 periods
-- ============================================================================
do $$
declare
  v_curriculum_id uuid;
  v_level_id uuid;
  v_grade_id uuid;
  v_version_id uuid;
  v_subject_id uuid;
  v_main_id uuid;
  v_topic_id uuid;
begin
  -- Natural-key resolution: Country (TZ) -> Curriculum (TIE) -> Level (PRIMARY) -> Grade
  select id into v_curriculum_id
  from public.curricula
  where country_code = 'TZ' and code = 'TIE'
  limit 1;
  if v_curriculum_id is null then
    raise exception 'Natural-key resolution failed: TZ TIE curriculum not found';
  end if;

  select id into v_level_id
  from public.education_levels
  where curriculum_id = v_curriculum_id and code = 'PRIMARY'
  limit 1;
  if v_level_id is null then
    raise exception 'Natural-key resolution failed: PRIMARY education level not found for TIE curriculum';
  end if;

  select id into v_grade_id
  from public.education_grades
  where curriculum_id = v_curriculum_id and education_level_id = v_level_id and code = 'STANDARD_6'
  limit 1;
  if v_grade_id is null then
    raise exception 'Natural-key resolution failed: education grade STANDARD_6 not found for TIE PRIMARY';
  end if;

  select id into v_version_id
  from public.curriculum_versions
  where curriculum_id = v_curriculum_id and version_code = 'TIE_PRIMARY_2023'
  limit 1;

  -- Upsert grade-scoped subject by natural key (curriculum_id, education_level_id, grade_id, code)
  select id into v_subject_id
  from public.subjects
  where country_code = 'TZ'
    and curriculum_id = v_curriculum_id
    and education_level_id = v_level_id
    and grade_id = v_grade_id
    and code = 'tie-pri-mathematics-standard6';

  if v_subject_id is null then
    insert into public.subjects (
      country_code, curriculum_id, education_level_id, grade_id,
      code, name, official_name, description, display_order, is_published, classification, language
    ) values (
      'TZ', v_curriculum_id, v_level_id, v_grade_id,
      'tie-pri-mathematics-standard6', 'Mathematics', 'Mathematics Syllabus for Primary Education — Standard VI', 'Official 2023 TIE Mathematics syllabus for Standard VI (234 periods, 6 periods/week; ISBN 978-9987-09-858-3).',
      4, true, 'compulsory', 'en'
    ) returning id into v_subject_id;
  else
    update public.subjects
    set name = 'Mathematics',
        official_name = 'Mathematics Syllabus for Primary Education — Standard VI',
        description = 'Official 2023 TIE Mathematics syllabus for Standard VI (234 periods, 6 periods/week; ISBN 978-9987-09-858-3).',
        display_order = 4,
        is_published = true,
        classification = 'compulsory',
        language = 'en',
        updated_at = now()
    where id = v_subject_id;
  end if;

  -- Main Competence 1.0: Demonstrate mastery of elementary mathematical skills
  insert into public.curriculum_main_competences (
    subject_id, curriculum_version_id, code, title, description, display_order, is_published
  ) values (
    v_subject_id, v_version_id, '1.0', 'Demonstrate mastery of elementary mathematical skills', 'Official 2023 TIE Mathematics Standard VI Main Competence 1.0 (ISBN 978-9987-09-858-3).', 1, true
  )
  on conflict (subject_id, code) do update
    set title = excluded.title,
        description = excluded.description,
        curriculum_version_id = coalesce(excluded.curriculum_version_id, curriculum_main_competences.curriculum_version_id),
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now()
  returning id into v_main_id;

  -- Specific Competence 1.1: Demonstrate an understanding of measurements
  v_topic_id := null;
  select id into v_topic_id
  from public.topics
  where subject_id = v_subject_id and competency_code = '1.1';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Demonstrate an understanding of measurements', 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.1. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.28).', 1, true,
      '1.1', 18, 'Problems involving distance and time are adequately solved', 28
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Demonstrate an understanding of measurements',
        summary = 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.1. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.28).',
        display_order = 1,
        period_allocation = 18,
        assessment_criteria = 'Problems involving distance and time are adequately solved',
        source_page = 28,
        is_published = true,
        updated_at = now()
    where id = v_topic_id;
  end if;

  insert into public.curriculum_specific_competences (
    main_competence_id, subject_id, topic_id, code, title, description,
    period_allocation, assessment_criteria, source_page, display_order, is_published
  ) values (
    v_main_id, v_subject_id, v_topic_id, '1.1', 'Demonstrate an understanding of measurements', 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.1. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.28).',
    18, 'Problems involving distance and time are adequately solved', 28, 1, true
  )
  on conflict (topic_id) do update
    set main_competence_id = excluded.main_competence_id,
        code = excluded.code,
        title = excluded.title,
        description = excluded.description,
        period_allocation = excluded.period_allocation,
        assessment_criteria = excluded.assessment_criteria,
        source_page = excluded.source_page,
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now();

  -- Refresh official learning activity subtopics idempotently
  delete from public.subtopics where topic_id = v_topic_id;
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Solve problems involving distance and time', 'TIE 2023 Mathematics Standard VI (ISBN 978-9987-09-858-3, p.28)',
    'Problems involving distance and time are adequately solved', 'Problems involving distance and time are adequately solved', 18, 1, 28, true
  );

  -- Specific Competence 1.2: Demonstrate an understanding of elementary geometry
  v_topic_id := null;
  select id into v_topic_id
  from public.topics
  where subject_id = v_subject_id and competency_code = '1.2';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Demonstrate an understanding of elementary geometry', 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.2. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.28).', 2, true,
      '1.2', 102, 'Area and volume of three-dimensional figures are correctly calculated', 28
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Demonstrate an understanding of elementary geometry',
        summary = 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.2. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.28).',
        display_order = 2,
        period_allocation = 102,
        assessment_criteria = 'Area and volume of three-dimensional figures are correctly calculated',
        source_page = 28,
        is_published = true,
        updated_at = now()
    where id = v_topic_id;
  end if;

  insert into public.curriculum_specific_competences (
    main_competence_id, subject_id, topic_id, code, title, description,
    period_allocation, assessment_criteria, source_page, display_order, is_published
  ) values (
    v_main_id, v_subject_id, v_topic_id, '1.2', 'Demonstrate an understanding of elementary geometry', 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.2. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.28).',
    102, 'Area and volume of three-dimensional figures are correctly calculated', 28, 2, true
  )
  on conflict (topic_id) do update
    set main_competence_id = excluded.main_competence_id,
        code = excluded.code,
        title = excluded.title,
        description = excluded.description,
        period_allocation = excluded.period_allocation,
        assessment_criteria = excluded.assessment_criteria,
        source_page = excluded.source_page,
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now();

  -- Refresh official learning activity subtopics idempotently
  delete from public.subtopics where topic_id = v_topic_id;
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Calculate the area and volume of three dimensional figures (rectangular parallelepiped, square parallelepiped and cylinder)', 'TIE 2023 Mathematics Standard VI (ISBN 978-9987-09-858-3, p.28)',
    'Area and volume of three-dimensional figures are correctly calculated', 'Area and volume of three-dimensional figures are correctly calculated', 34, 1, 28, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Calculate degree of angles in plane figures (triangle, rectangle and circle)', 'TIE 2023 Mathematics Standard VI (ISBN 978-9987-09-858-3, p.29)',
    'Degree of angles in plane figures are correctly calculated', 'Degree of angles in plane figures are correctly calculated', 34, 2, 29, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(c) Describe types of triangles and Pythagoras'' theorem', 'TIE 2023 Mathematics Standard VI (ISBN 978-9987-09-858-3, p.29)',
    'Types of triangles and Pythagoras'' theorem are correctly described', 'Types of triangles and Pythagoras'' theorem are correctly described', 34, 3, 29, true
  );

  -- Specific Competence 1.3: Demonstrate an understanding of elementary mathematical skills
  v_topic_id := null;
  select id into v_topic_id
  from public.topics
  where subject_id = v_subject_id and competency_code = '1.3';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Demonstrate an understanding of elementary mathematical skills', 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.3. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.30).', 3, true,
      '1.3', 52, 'The square of a number is correctly calculated', 30
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Demonstrate an understanding of elementary mathematical skills',
        summary = 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.3. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.30).',
        display_order = 3,
        period_allocation = 52,
        assessment_criteria = 'The square of a number is correctly calculated',
        source_page = 30,
        is_published = true,
        updated_at = now()
    where id = v_topic_id;
  end if;

  insert into public.curriculum_specific_competences (
    main_competence_id, subject_id, topic_id, code, title, description,
    period_allocation, assessment_criteria, source_page, display_order, is_published
  ) values (
    v_main_id, v_subject_id, v_topic_id, '1.3', 'Demonstrate an understanding of elementary mathematical skills', 'Main Competence 1.0: Demonstrate mastery of elementary mathematical skills. Specific Competence 1.3. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.30).',
    52, 'The square of a number is correctly calculated', 30, 3, true
  )
  on conflict (topic_id) do update
    set main_competence_id = excluded.main_competence_id,
        code = excluded.code,
        title = excluded.title,
        description = excluded.description,
        period_allocation = excluded.period_allocation,
        assessment_criteria = excluded.assessment_criteria,
        source_page = excluded.source_page,
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now();

  -- Refresh official learning activity subtopics idempotently
  delete from public.subtopics where topic_id = v_topic_id;
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Calculate the square of a number', 'TIE 2023 Mathematics Standard VI (ISBN 978-9987-09-858-3, p.30)',
    'The square of a number is correctly calculated', 'The square of a number is correctly calculated', 13, 1, 30, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Calculate the square root of a number', 'TIE 2023 Mathematics Standard VI (ISBN 978-9987-09-858-3, p.30)',
    'Square root of a number is calculated correctly', 'Square root of a number is calculated correctly', 13, 2, 30, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(c) Explain the concept of integers', 'TIE 2023 Mathematics Standard VI (ISBN 978-9987-09-858-3, p.30)',
    'Concept of integers is correctly explained', 'Concept of integers is correctly explained', 13, 3, 30, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(d) Perform operations in integers', 'TIE 2023 Mathematics Standard VI (ISBN 978-9987-09-858-3, p.31)',
    'Operations with integers are correctly performed', 'Operations with integers are correctly performed', 13, 4, 31, true
  );

  -- Main Competence 2.0: Demonstrate mastery of elementary application of mathematics
  insert into public.curriculum_main_competences (
    subject_id, curriculum_version_id, code, title, description, display_order, is_published
  ) values (
    v_subject_id, v_version_id, '2.0', 'Demonstrate mastery of elementary application of mathematics', 'Official 2023 TIE Mathematics Standard VI Main Competence 2.0 (ISBN 978-9987-09-858-3).', 2, true
  )
  on conflict (subject_id, code) do update
    set title = excluded.title,
        description = excluded.description,
        curriculum_version_id = coalesce(excluded.curriculum_version_id, curriculum_main_competences.curriculum_version_id),
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now()
  returning id into v_main_id;

  -- Specific Competence 2.1: Demonstrate an understanding of elementary statistics and its applications
  v_topic_id := null;
  select id into v_topic_id
  from public.topics
  where subject_id = v_subject_id and competency_code = '2.1';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Demonstrate an understanding of elementary statistics and its applications', 'Main Competence 2.0: Demonstrate mastery of elementary application of mathematics. Specific Competence 2.1. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.32).', 4, true,
      '2.1', 62, 'Concept of statistics is clearly explained', 32
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Demonstrate an understanding of elementary statistics and its applications',
        summary = 'Main Competence 2.0: Demonstrate mastery of elementary application of mathematics. Specific Competence 2.1. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.32).',
        display_order = 4,
        period_allocation = 62,
        assessment_criteria = 'Concept of statistics is clearly explained',
        source_page = 32,
        is_published = true,
        updated_at = now()
    where id = v_topic_id;
  end if;

  insert into public.curriculum_specific_competences (
    main_competence_id, subject_id, topic_id, code, title, description,
    period_allocation, assessment_criteria, source_page, display_order, is_published
  ) values (
    v_main_id, v_subject_id, v_topic_id, '2.1', 'Demonstrate an understanding of elementary statistics and its applications', 'Main Competence 2.0: Demonstrate mastery of elementary application of mathematics. Specific Competence 2.1. Weekly allocation: 6 periods. Source: TIE 2023 Mathematics Syllabus (ISBN 978-9987-09-858-3, p.32).',
    62, 'Concept of statistics is clearly explained', 32, 1, true
  )
  on conflict (topic_id) do update
    set main_competence_id = excluded.main_competence_id,
        code = excluded.code,
        title = excluded.title,
        description = excluded.description,
        period_allocation = excluded.period_allocation,
        assessment_criteria = excluded.assessment_criteria,
        source_page = excluded.source_page,
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now();

  -- Refresh official learning activity subtopics idempotently
  delete from public.subtopics where topic_id = v_topic_id;
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Explain the concept of statistics', 'TIE 2023 Mathematics Standard VI (ISBN 978-9987-09-858-3, p.32)',
    'Concept of statistics is clearly explained', 'Concept of statistics is clearly explained', 21, 1, 32, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Find the mean, median and mode of ungrouped data', 'TIE 2023 Mathematics Standard VI (ISBN 978-9987-09-858-3, p.33)',
    'The mean, median and mode of ungrouped data is correctly calculated', 'The mean, median and mode of ungrouped data is correctly calculated', 21, 2, 33, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(c) Interpretation and presentation of data using statistical diagrams (pie charts and histograms)', 'TIE 2023 Mathematics Standard VI (ISBN 978-9987-09-858-3, p.33)',
    'Data is accurately interpreted and presented using pie charts and histograms', 'Data is accurately interpreted and presented using pie charts and histograms', 20, 3, 33, true
  );

end $$;

-- ============================================================================
-- Science — Standard III (STANDARD_3): 175 periods
-- ============================================================================
do $$
declare
  v_curriculum_id uuid;
  v_level_id uuid;
  v_grade_id uuid;
  v_version_id uuid;
  v_subject_id uuid;
  v_main_id uuid;
  v_topic_id uuid;
begin
  -- Natural-key resolution: Country (TZ) -> Curriculum (TIE) -> Level (PRIMARY) -> Grade
  select id into v_curriculum_id
  from public.curricula
  where country_code = 'TZ' and code = 'TIE'
  limit 1;
  if v_curriculum_id is null then
    raise exception 'Natural-key resolution failed: TZ TIE curriculum not found';
  end if;

  select id into v_level_id
  from public.education_levels
  where curriculum_id = v_curriculum_id and code = 'PRIMARY'
  limit 1;
  if v_level_id is null then
    raise exception 'Natural-key resolution failed: PRIMARY education level not found for TIE curriculum';
  end if;

  select id into v_grade_id
  from public.education_grades
  where curriculum_id = v_curriculum_id and education_level_id = v_level_id and code = 'STANDARD_3'
  limit 1;
  if v_grade_id is null then
    raise exception 'Natural-key resolution failed: education grade STANDARD_3 not found for TIE PRIMARY';
  end if;

  select id into v_version_id
  from public.curriculum_versions
  where curriculum_id = v_curriculum_id and version_code = 'TIE_PRIMARY_2023'
  limit 1;

  -- Upsert grade-scoped subject by natural key (curriculum_id, education_level_id, grade_id, code)
  select id into v_subject_id
  from public.subjects
  where country_code = 'TZ'
    and curriculum_id = v_curriculum_id
    and education_level_id = v_level_id
    and grade_id = v_grade_id
    and code = 'tie-pri-science-standard3';

  if v_subject_id is null then
    insert into public.subjects (
      country_code, curriculum_id, education_level_id, grade_id,
      code, name, official_name, description, display_order, is_published, classification, language
    ) values (
      'TZ', v_curriculum_id, v_level_id, v_grade_id,
      'tie-pri-science-standard3', 'Science', 'Science Syllabus for Primary Education — Standard III', 'Official 2023 TIE Science syllabus for Standard III (175 periods, 7 periods/week; ISBN 978-9987-09-860-6).',
      5, true, 'compulsory', 'en'
    ) returning id into v_subject_id;
  else
    update public.subjects
    set name = 'Science',
        official_name = 'Science Syllabus for Primary Education — Standard III',
        description = 'Official 2023 TIE Science syllabus for Standard III (175 periods, 7 periods/week; ISBN 978-9987-09-860-6).',
        display_order = 5,
        is_published = true,
        classification = 'compulsory',
        language = 'en',
        updated_at = now()
    where id = v_subject_id;
  end if;

  -- Main Competence 1.0: Demonstrate mastery of scientific theories
  insert into public.curriculum_main_competences (
    subject_id, curriculum_version_id, code, title, description, display_order, is_published
  ) values (
    v_subject_id, v_version_id, '1.0', 'Demonstrate mastery of scientific theories', 'Official 2023 TIE Science Standard III Main Competence 1.0 (ISBN 978-9987-09-860-6).', 1, true
  )
  on conflict (subject_id, code) do update
    set title = excluded.title,
        description = excluded.description,
        curriculum_version_id = coalesce(excluded.curriculum_version_id, curriculum_main_competences.curriculum_version_id),
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now()
  returning id into v_main_id;

  -- Specific Competence 1.1: Demonstrate an elementary understanding of scientific theories
  v_topic_id := null;
  select id into v_topic_id
  from public.topics
  where subject_id = v_subject_id and competency_code = '1.1';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Demonstrate an elementary understanding of scientific theories', 'Main Competence 1.0: Demonstrate mastery of scientific theories. Specific Competence 1.1. Weekly allocation: 7 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.8).', 1, true,
      '1.1', 44, 'The concept of science is clearly explained', 8
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Demonstrate an elementary understanding of scientific theories',
        summary = 'Main Competence 1.0: Demonstrate mastery of scientific theories. Specific Competence 1.1. Weekly allocation: 7 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.8).',
        display_order = 1,
        period_allocation = 44,
        assessment_criteria = 'The concept of science is clearly explained',
        source_page = 8,
        is_published = true,
        updated_at = now()
    where id = v_topic_id;
  end if;

  insert into public.curriculum_specific_competences (
    main_competence_id, subject_id, topic_id, code, title, description,
    period_allocation, assessment_criteria, source_page, display_order, is_published
  ) values (
    v_main_id, v_subject_id, v_topic_id, '1.1', 'Demonstrate an elementary understanding of scientific theories', 'Main Competence 1.0: Demonstrate mastery of scientific theories. Specific Competence 1.1. Weekly allocation: 7 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.8).',
    44, 'The concept of science is clearly explained', 8, 1, true
  )
  on conflict (topic_id) do update
    set main_competence_id = excluded.main_competence_id,
        code = excluded.code,
        title = excluded.title,
        description = excluded.description,
        period_allocation = excluded.period_allocation,
        assessment_criteria = excluded.assessment_criteria,
        source_page = excluded.source_page,
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now();

  -- Refresh official learning activity subtopics idempotently
  delete from public.subtopics where topic_id = v_topic_id;
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Explain the concept of science (meaning and branches of science)', 'TIE 2023 Science Standard III (ISBN 978-9987-09-860-6, p.8)',
    'The concept of science is clearly explained', 'The concept of science is clearly explained', 22, 1, 8, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Describe the human sensory organs', 'TIE 2023 Science Standard III (ISBN 978-9987-09-860-6, p.9)',
    'Human sensory organs are clearly explained', 'Human sensory organs are clearly explained', 22, 2, 9, true
  );

  -- Specific Competence 1.2: Make simple scientific observations
  v_topic_id := null;
  select id into v_topic_id
  from public.topics
  where subject_id = v_subject_id and competency_code = '1.2';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Make simple scientific observations', 'Main Competence 1.0: Demonstrate mastery of scientific theories. Specific Competence 1.2. Weekly allocation: 7 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.10).', 2, true,
      '1.2', 44, 'Different objects in the environment are correctly identified', 10
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Make simple scientific observations',
        summary = 'Main Competence 1.0: Demonstrate mastery of scientific theories. Specific Competence 1.2. Weekly allocation: 7 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.10).',
        display_order = 2,
        period_allocation = 44,
        assessment_criteria = 'Different objects in the environment are correctly identified',
        source_page = 10,
        is_published = true,
        updated_at = now()
    where id = v_topic_id;
  end if;

  insert into public.curriculum_specific_competences (
    main_competence_id, subject_id, topic_id, code, title, description,
    period_allocation, assessment_criteria, source_page, display_order, is_published
  ) values (
    v_main_id, v_subject_id, v_topic_id, '1.2', 'Make simple scientific observations', 'Main Competence 1.0: Demonstrate mastery of scientific theories. Specific Competence 1.2. Weekly allocation: 7 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.10).',
    44, 'Different objects in the environment are correctly identified', 10, 2, true
  )
  on conflict (topic_id) do update
    set main_competence_id = excluded.main_competence_id,
        code = excluded.code,
        title = excluded.title,
        description = excluded.description,
        period_allocation = excluded.period_allocation,
        assessment_criteria = excluded.assessment_criteria,
        source_page = excluded.source_page,
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now();

  -- Refresh official learning activity subtopics idempotently
  delete from public.subtopics where topic_id = v_topic_id;
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Identify different objects in the environment', 'TIE 2023 Science Standard III (ISBN 978-9987-09-860-6, p.10)',
    'Different objects in the environment are correctly identified', 'Different objects in the environment are correctly identified', 15, 1, 10, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Identify living and non-living things', 'TIE 2023 Science Standard III (ISBN 978-9987-09-860-6, p.10)',
    'Living and non-living things found in the environment are correctly identified', 'Living and non-living things found in the environment are correctly identified', 15, 2, 10, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(c) Identify the main groups of living things (plants and animals)', 'TIE 2023 Science Standard III (ISBN 978-9987-09-860-6, p.11)',
    'Main groups of living things are clearly identified', 'Main groups of living things are clearly identified', 14, 3, 11, true
  );

  -- Main Competence 2.0: Demonstrate mastery of elementary scientific skills
  insert into public.curriculum_main_competences (
    subject_id, curriculum_version_id, code, title, description, display_order, is_published
  ) values (
    v_subject_id, v_version_id, '2.0', 'Demonstrate mastery of elementary scientific skills', 'Official 2023 TIE Science Standard III Main Competence 2.0 (ISBN 978-9987-09-860-6).', 2, true
  )
  on conflict (subject_id, code) do update
    set title = excluded.title,
        description = excluded.description,
        curriculum_version_id = coalesce(excluded.curriculum_version_id, curriculum_main_competences.curriculum_version_id),
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now()
  returning id into v_main_id;

  -- Specific Competence 2.1: Conduct simple scientific experiments
  v_topic_id := null;
  select id into v_topic_id
  from public.topics
  where subject_id = v_subject_id and competency_code = '2.1';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Conduct simple scientific experiments', 'Main Competence 2.0: Demonstrate mastery of elementary scientific skills. Specific Competence 2.1. Weekly allocation: 7 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.12).', 3, true,
      '2.1', 43, 'Steps for conducting scientific investigations are clearly described', 12
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Conduct simple scientific experiments',
        summary = 'Main Competence 2.0: Demonstrate mastery of elementary scientific skills. Specific Competence 2.1. Weekly allocation: 7 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.12).',
        display_order = 3,
        period_allocation = 43,
        assessment_criteria = 'Steps for conducting scientific investigations are clearly described',
        source_page = 12,
        is_published = true,
        updated_at = now()
    where id = v_topic_id;
  end if;

  insert into public.curriculum_specific_competences (
    main_competence_id, subject_id, topic_id, code, title, description,
    period_allocation, assessment_criteria, source_page, display_order, is_published
  ) values (
    v_main_id, v_subject_id, v_topic_id, '2.1', 'Conduct simple scientific experiments', 'Main Competence 2.0: Demonstrate mastery of elementary scientific skills. Specific Competence 2.1. Weekly allocation: 7 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.12).',
    43, 'Steps for conducting scientific investigations are clearly described', 12, 1, true
  )
  on conflict (topic_id) do update
    set main_competence_id = excluded.main_competence_id,
        code = excluded.code,
        title = excluded.title,
        description = excluded.description,
        period_allocation = excluded.period_allocation,
        assessment_criteria = excluded.assessment_criteria,
        source_page = excluded.source_page,
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now();

  -- Refresh official learning activity subtopics idempotently
  delete from public.subtopics where topic_id = v_topic_id;
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Describe basic steps in conducting a scientific investigation', 'TIE 2023 Science Standard III (ISBN 978-9987-09-860-6, p.12)',
    'Steps for conducting scientific investigations are clearly described', 'Steps for conducting scientific investigations are clearly described', 15, 1, 12, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Conduct elementary experiments on various living and non-living things', 'TIE 2023 Science Standard III (ISBN 978-9987-09-860-6, p.13)',
    'Elementary experiments on various living and non-living things are correctly conducted', 'Elementary experiments on various living and non-living things are correctly conducted', 14, 2, 13, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(c) Care for living things in the environment', 'TIE 2023 Science Standard III (ISBN 978-9987-09-860-6, p.13)',
    'Living things in the environment are properly cared for', 'Living things in the environment are properly cared for', 14, 3, 13, true
  );

  -- Main Competence 3.0: Demonstrate mastery of ICT skills
  insert into public.curriculum_main_competences (
    subject_id, curriculum_version_id, code, title, description, display_order, is_published
  ) values (
    v_subject_id, v_version_id, '3.0', 'Demonstrate mastery of ICT skills', 'Official 2023 TIE Science Standard III Main Competence 3.0 (ISBN 978-9987-09-860-6).', 3, true
  )
  on conflict (subject_id, code) do update
    set title = excluded.title,
        description = excluded.description,
        curriculum_version_id = coalesce(excluded.curriculum_version_id, curriculum_main_competences.curriculum_version_id),
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now()
  returning id into v_main_id;

  -- Specific Competence 3.1: Use ICT for learning
  v_topic_id := null;
  select id into v_topic_id
  from public.topics
  where subject_id = v_subject_id and competency_code = '3.1';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Use ICT for learning', 'Main Competence 3.0: Demonstrate mastery of ICT skills. Specific Competence 3.1. Weekly allocation: 7 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.14).', 4, true,
      '3.1', 44, 'ICT is properly used to play simple games that explain scientific phenomena and concepts', 14
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Use ICT for learning',
        summary = 'Main Competence 3.0: Demonstrate mastery of ICT skills. Specific Competence 3.1. Weekly allocation: 7 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.14).',
        display_order = 4,
        period_allocation = 44,
        assessment_criteria = 'ICT is properly used to play simple games that explain scientific phenomena and concepts',
        source_page = 14,
        is_published = true,
        updated_at = now()
    where id = v_topic_id;
  end if;

  insert into public.curriculum_specific_competences (
    main_competence_id, subject_id, topic_id, code, title, description,
    period_allocation, assessment_criteria, source_page, display_order, is_published
  ) values (
    v_main_id, v_subject_id, v_topic_id, '3.1', 'Use ICT for learning', 'Main Competence 3.0: Demonstrate mastery of ICT skills. Specific Competence 3.1. Weekly allocation: 7 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.14).',
    44, 'ICT is properly used to play simple games that explain scientific phenomena and concepts', 14, 1, true
  )
  on conflict (topic_id) do update
    set main_competence_id = excluded.main_competence_id,
        code = excluded.code,
        title = excluded.title,
        description = excluded.description,
        period_allocation = excluded.period_allocation,
        assessment_criteria = excluded.assessment_criteria,
        source_page = excluded.source_page,
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now();

  -- Refresh official learning activity subtopics idempotently
  delete from public.subtopics where topic_id = v_topic_id;
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Use ICT to play simple games that promote ability to explain scientific phenomena and concepts', 'TIE 2023 Science Standard III (ISBN 978-9987-09-860-6, p.14)',
    'ICT is properly used to play simple games that explain scientific phenomena and concepts', 'ICT is properly used to play simple games that explain scientific phenomena and concepts', 44, 1, 14, true
  );

end $$;

-- ============================================================================
-- Science — Standard IV (STANDARD_4): 175 periods
-- ============================================================================
do $$
declare
  v_curriculum_id uuid;
  v_level_id uuid;
  v_grade_id uuid;
  v_version_id uuid;
  v_subject_id uuid;
  v_main_id uuid;
  v_topic_id uuid;
begin
  -- Natural-key resolution: Country (TZ) -> Curriculum (TIE) -> Level (PRIMARY) -> Grade
  select id into v_curriculum_id
  from public.curricula
  where country_code = 'TZ' and code = 'TIE'
  limit 1;
  if v_curriculum_id is null then
    raise exception 'Natural-key resolution failed: TZ TIE curriculum not found';
  end if;

  select id into v_level_id
  from public.education_levels
  where curriculum_id = v_curriculum_id and code = 'PRIMARY'
  limit 1;
  if v_level_id is null then
    raise exception 'Natural-key resolution failed: PRIMARY education level not found for TIE curriculum';
  end if;

  select id into v_grade_id
  from public.education_grades
  where curriculum_id = v_curriculum_id and education_level_id = v_level_id and code = 'STANDARD_4'
  limit 1;
  if v_grade_id is null then
    raise exception 'Natural-key resolution failed: education grade STANDARD_4 not found for TIE PRIMARY';
  end if;

  select id into v_version_id
  from public.curriculum_versions
  where curriculum_id = v_curriculum_id and version_code = 'TIE_PRIMARY_2023'
  limit 1;

  -- Upsert grade-scoped subject by natural key (curriculum_id, education_level_id, grade_id, code)
  select id into v_subject_id
  from public.subjects
  where country_code = 'TZ'
    and curriculum_id = v_curriculum_id
    and education_level_id = v_level_id
    and grade_id = v_grade_id
    and code = 'tie-pri-science-standard4';

  if v_subject_id is null then
    insert into public.subjects (
      country_code, curriculum_id, education_level_id, grade_id,
      code, name, official_name, description, display_order, is_published, classification, language
    ) values (
      'TZ', v_curriculum_id, v_level_id, v_grade_id,
      'tie-pri-science-standard4', 'Science', 'Science Syllabus for Primary Education — Standard IV', 'Official 2023 TIE Science syllabus for Standard IV (175 periods, 7 periods/week; ISBN 978-9987-09-860-6).',
      5, true, 'compulsory', 'en'
    ) returning id into v_subject_id;
  else
    update public.subjects
    set name = 'Science',
        official_name = 'Science Syllabus for Primary Education — Standard IV',
        description = 'Official 2023 TIE Science syllabus for Standard IV (175 periods, 7 periods/week; ISBN 978-9987-09-860-6).',
        display_order = 5,
        is_published = true,
        classification = 'compulsory',
        language = 'en',
        updated_at = now()
    where id = v_subject_id;
  end if;

  -- Main Competence 1.0: Demonstrate mastery of scientific theories
  insert into public.curriculum_main_competences (
    subject_id, curriculum_version_id, code, title, description, display_order, is_published
  ) values (
    v_subject_id, v_version_id, '1.0', 'Demonstrate mastery of scientific theories', 'Official 2023 TIE Science Standard IV Main Competence 1.0 (ISBN 978-9987-09-860-6).', 1, true
  )
  on conflict (subject_id, code) do update
    set title = excluded.title,
        description = excluded.description,
        curriculum_version_id = coalesce(excluded.curriculum_version_id, curriculum_main_competences.curriculum_version_id),
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now()
  returning id into v_main_id;

  -- Specific Competence 1.1: Demonstrate an elementary understanding of scientific theories
  v_topic_id := null;
  select id into v_topic_id
  from public.topics
  where subject_id = v_subject_id and competency_code = '1.1';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Demonstrate an elementary understanding of scientific theories', 'Main Competence 1.0: Demonstrate mastery of scientific theories. Specific Competence 1.1. Weekly allocation: 7 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.16).', 1, true,
      '1.1', 30, 'The basic principles of health are clearly explained', 16
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Demonstrate an elementary understanding of scientific theories',
        summary = 'Main Competence 1.0: Demonstrate mastery of scientific theories. Specific Competence 1.1. Weekly allocation: 7 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.16).',
        display_order = 1,
        period_allocation = 30,
        assessment_criteria = 'The basic principles of health are clearly explained',
        source_page = 16,
        is_published = true,
        updated_at = now()
    where id = v_topic_id;
  end if;

  insert into public.curriculum_specific_competences (
    main_competence_id, subject_id, topic_id, code, title, description,
    period_allocation, assessment_criteria, source_page, display_order, is_published
  ) values (
    v_main_id, v_subject_id, v_topic_id, '1.1', 'Demonstrate an elementary understanding of scientific theories', 'Main Competence 1.0: Demonstrate mastery of scientific theories. Specific Competence 1.1. Weekly allocation: 7 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.16).',
    30, 'The basic principles of health are clearly explained', 16, 1, true
  )
  on conflict (topic_id) do update
    set main_competence_id = excluded.main_competence_id,
        code = excluded.code,
        title = excluded.title,
        description = excluded.description,
        period_allocation = excluded.period_allocation,
        assessment_criteria = excluded.assessment_criteria,
        source_page = excluded.source_page,
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now();

  -- Refresh official learning activity subtopics idempotently
  delete from public.subtopics where topic_id = v_topic_id;
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Explain the basic principles of health (balanced diet, physical exercises, personal and environmental hygiene, safety signs and symbols)', 'TIE 2023 Science Standard IV (ISBN 978-9987-09-860-6, p.16)',
    'The basic principles of health are clearly explained', 'The basic principles of health are clearly explained', 8, 1, 16, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Describe types of common human diseases (modes of transmission, causes, control and preventions)', 'TIE 2023 Science Standard IV (ISBN 978-9987-09-860-6, p.17)',
    'Common types of human diseases and their control and prevention are clearly described', 'Common types of human diseases and their control and prevention are clearly described', 8, 2, 17, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(c) Explain the concept of matter (types and characteristics)', 'TIE 2023 Science Standard IV (ISBN 978-9987-09-860-6, p.18)',
    'The concept of matter (types and characteristics) is clearly explained', 'The concept of matter (types and characteristics) is clearly explained', 7, 3, 18, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(d) Explain the concept of combustion (meaning, causes and effects)', 'TIE 2023 Science Standard IV (ISBN 978-9987-09-860-6, p.19)',
    'The concept of combustion is clearly explained', 'The concept of combustion is clearly explained', 7, 4, 19, true
  );

  -- Specific Competence 1.2: Make simple scientific observations
  v_topic_id := null;
  select id into v_topic_id
  from public.topics
  where subject_id = v_subject_id and competency_code = '1.2';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Make simple scientific observations', 'Main Competence 1.0: Demonstrate mastery of scientific theories. Specific Competence 1.2. Weekly allocation: 7 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.20).', 2, true,
      '1.2', 30, 'Life cycles of insect vectors are clearly investigated', 20
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Make simple scientific observations',
        summary = 'Main Competence 1.0: Demonstrate mastery of scientific theories. Specific Competence 1.2. Weekly allocation: 7 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.20).',
        display_order = 2,
        period_allocation = 30,
        assessment_criteria = 'Life cycles of insect vectors are clearly investigated',
        source_page = 20,
        is_published = true,
        updated_at = now()
    where id = v_topic_id;
  end if;

  insert into public.curriculum_specific_competences (
    main_competence_id, subject_id, topic_id, code, title, description,
    period_allocation, assessment_criteria, source_page, display_order, is_published
  ) values (
    v_main_id, v_subject_id, v_topic_id, '1.2', 'Make simple scientific observations', 'Main Competence 1.0: Demonstrate mastery of scientific theories. Specific Competence 1.2. Weekly allocation: 7 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.20).',
    30, 'Life cycles of insect vectors are clearly investigated', 20, 2, true
  )
  on conflict (topic_id) do update
    set main_competence_id = excluded.main_competence_id,
        code = excluded.code,
        title = excluded.title,
        description = excluded.description,
        period_allocation = excluded.period_allocation,
        assessment_criteria = excluded.assessment_criteria,
        source_page = excluded.source_page,
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now();

  -- Refresh official learning activity subtopics idempotently
  delete from public.subtopics where topic_id = v_topic_id;
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Investigate the life cycle of insect vectors (housefly, cockroach and mosquito)', 'TIE 2023 Science Standard IV (ISBN 978-9987-09-860-6, p.20)',
    'Life cycles of insect vectors are clearly investigated', 'Life cycles of insect vectors are clearly investigated', 30, 1, 20, true
  );

  -- Specific Competence 1.3: Demonstrate a basic understanding of types of energy and their uses
  v_topic_id := null;
  select id into v_topic_id
  from public.topics
  where subject_id = v_subject_id and competency_code = '1.3';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Demonstrate a basic understanding of types of energy and their uses', 'Main Competence 1.0: Demonstrate mastery of scientific theories. Specific Competence 1.3. Weekly allocation: 7 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.21).', 3, true,
      '1.3', 30, 'Types of energy and their uses are clearly described', 21
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Demonstrate a basic understanding of types of energy and their uses',
        summary = 'Main Competence 1.0: Demonstrate mastery of scientific theories. Specific Competence 1.3. Weekly allocation: 7 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.21).',
        display_order = 3,
        period_allocation = 30,
        assessment_criteria = 'Types of energy and their uses are clearly described',
        source_page = 21,
        is_published = true,
        updated_at = now()
    where id = v_topic_id;
  end if;

  insert into public.curriculum_specific_competences (
    main_competence_id, subject_id, topic_id, code, title, description,
    period_allocation, assessment_criteria, source_page, display_order, is_published
  ) values (
    v_main_id, v_subject_id, v_topic_id, '1.3', 'Demonstrate a basic understanding of types of energy and their uses', 'Main Competence 1.0: Demonstrate mastery of scientific theories. Specific Competence 1.3. Weekly allocation: 7 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.21).',
    30, 'Types of energy and their uses are clearly described', 21, 3, true
  )
  on conflict (topic_id) do update
    set main_competence_id = excluded.main_competence_id,
        code = excluded.code,
        title = excluded.title,
        description = excluded.description,
        period_allocation = excluded.period_allocation,
        assessment_criteria = excluded.assessment_criteria,
        source_page = excluded.source_page,
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now();

  -- Refresh official learning activity subtopics idempotently
  delete from public.subtopics where topic_id = v_topic_id;
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Describe types of energy (heat, light and sound energy) and their uses', 'TIE 2023 Science Standard IV (ISBN 978-9987-09-860-6, p.21)',
    'Types of energy and their uses are clearly described', 'Types of energy and their uses are clearly described', 30, 1, 21, true
  );

  -- Main Competence 2.0: Demonstrate mastery of elementary scientific skills
  insert into public.curriculum_main_competences (
    subject_id, curriculum_version_id, code, title, description, display_order, is_published
  ) values (
    v_subject_id, v_version_id, '2.0', 'Demonstrate mastery of elementary scientific skills', 'Official 2023 TIE Science Standard IV Main Competence 2.0 (ISBN 978-9987-09-860-6).', 2, true
  )
  on conflict (subject_id, code) do update
    set title = excluded.title,
        description = excluded.description,
        curriculum_version_id = coalesce(excluded.curriculum_version_id, curriculum_main_competences.curriculum_version_id),
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now()
  returning id into v_main_id;

  -- Specific Competence 2.1: Conduct elementary scientific experiments
  v_topic_id := null;
  select id into v_topic_id
  from public.topics
  where subject_id = v_subject_id and competency_code = '2.1';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Conduct elementary scientific experiments', 'Main Competence 2.0: Demonstrate mastery of elementary scientific skills. Specific Competence 2.1. Weekly allocation: 7 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.22).', 4, true,
      '2.1', 30, 'Simple experiments on characteristics of matter are conducted correctly', 22
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Conduct elementary scientific experiments',
        summary = 'Main Competence 2.0: Demonstrate mastery of elementary scientific skills. Specific Competence 2.1. Weekly allocation: 7 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.22).',
        display_order = 4,
        period_allocation = 30,
        assessment_criteria = 'Simple experiments on characteristics of matter are conducted correctly',
        source_page = 22,
        is_published = true,
        updated_at = now()
    where id = v_topic_id;
  end if;

  insert into public.curriculum_specific_competences (
    main_competence_id, subject_id, topic_id, code, title, description,
    period_allocation, assessment_criteria, source_page, display_order, is_published
  ) values (
    v_main_id, v_subject_id, v_topic_id, '2.1', 'Conduct elementary scientific experiments', 'Main Competence 2.0: Demonstrate mastery of elementary scientific skills. Specific Competence 2.1. Weekly allocation: 7 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.22).',
    30, 'Simple experiments on characteristics of matter are conducted correctly', 22, 1, true
  )
  on conflict (topic_id) do update
    set main_competence_id = excluded.main_competence_id,
        code = excluded.code,
        title = excluded.title,
        description = excluded.description,
        period_allocation = excluded.period_allocation,
        assessment_criteria = excluded.assessment_criteria,
        source_page = excluded.source_page,
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now();

  -- Refresh official learning activity subtopics idempotently
  delete from public.subtopics where topic_id = v_topic_id;
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Conduct simple experiments to investigate the states of matter', 'TIE 2023 Science Standard IV (ISBN 978-9987-09-860-6, p.22)',
    'Simple experiments on characteristics of matter are conducted correctly', 'Simple experiments on characteristics of matter are conducted correctly', 10, 1, 22, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Conduct simple experiments to demonstrate importance of air in combustion', 'TIE 2023 Science Standard IV (ISBN 978-9987-09-860-6, p.23)',
    'Simple experiments on importance of air in combustion are correctly conducted', 'Simple experiments on importance of air in combustion are correctly conducted', 10, 2, 23, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(c) Conduct simple experiments on heat, light and sound energy', 'TIE 2023 Science Standard IV (ISBN 978-9987-09-860-6, p.23)',
    'Simple experiments on heat, light and sound energy are correctly conducted', 'Simple experiments on heat, light and sound energy are correctly conducted', 10, 3, 23, true
  );

  -- Main Competence 3.0: Demonstrate mastery of ICT skills
  insert into public.curriculum_main_competences (
    subject_id, curriculum_version_id, code, title, description, display_order, is_published
  ) values (
    v_subject_id, v_version_id, '3.0', 'Demonstrate mastery of ICT skills', 'Official 2023 TIE Science Standard IV Main Competence 3.0 (ISBN 978-9987-09-860-6).', 3, true
  )
  on conflict (subject_id, code) do update
    set title = excluded.title,
        description = excluded.description,
        curriculum_version_id = coalesce(excluded.curriculum_version_id, curriculum_main_competences.curriculum_version_id),
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now()
  returning id into v_main_id;

  -- Specific Competence 3.1: Use ICT for learning
  v_topic_id := null;
  select id into v_topic_id
  from public.topics
  where subject_id = v_subject_id and competency_code = '3.1';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Use ICT for learning', 'Main Competence 3.0: Demonstrate mastery of ICT skills. Specific Competence 3.1. Weekly allocation: 7 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.24).', 5, true,
      '3.1', 25, 'ICT is used properly to draw and arrange various shapes in a logical sequence', 24
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Use ICT for learning',
        summary = 'Main Competence 3.0: Demonstrate mastery of ICT skills. Specific Competence 3.1. Weekly allocation: 7 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.24).',
        display_order = 5,
        period_allocation = 25,
        assessment_criteria = 'ICT is used properly to draw and arrange various shapes in a logical sequence',
        source_page = 24,
        is_published = true,
        updated_at = now()
    where id = v_topic_id;
  end if;

  insert into public.curriculum_specific_competences (
    main_competence_id, subject_id, topic_id, code, title, description,
    period_allocation, assessment_criteria, source_page, display_order, is_published
  ) values (
    v_main_id, v_subject_id, v_topic_id, '3.1', 'Use ICT for learning', 'Main Competence 3.0: Demonstrate mastery of ICT skills. Specific Competence 3.1. Weekly allocation: 7 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.24).',
    25, 'ICT is used properly to draw and arrange various shapes in a logical sequence', 24, 1, true
  )
  on conflict (topic_id) do update
    set main_competence_id = excluded.main_competence_id,
        code = excluded.code,
        title = excluded.title,
        description = excluded.description,
        period_allocation = excluded.period_allocation,
        assessment_criteria = excluded.assessment_criteria,
        source_page = excluded.source_page,
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now();

  -- Refresh official learning activity subtopics idempotently
  delete from public.subtopics where topic_id = v_topic_id;
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Use ICT to draw and arrange various shapes in a logical sequence', 'TIE 2023 Science Standard IV (ISBN 978-9987-09-860-6, p.24)',
    'ICT is used properly to draw and arrange various shapes in a logical sequence', 'ICT is used properly to draw and arrange various shapes in a logical sequence', 25, 1, 24, true
  );

  -- Main Competence 4.0: Design simple computer programmes
  insert into public.curriculum_main_competences (
    subject_id, curriculum_version_id, code, title, description, display_order, is_published
  ) values (
    v_subject_id, v_version_id, '4.0', 'Design simple computer programmes', 'Official 2023 TIE Science Standard IV Main Competence 4.0 (ISBN 978-9987-09-860-6).', 4, true
  )
  on conflict (subject_id, code) do update
    set title = excluded.title,
        description = excluded.description,
        curriculum_version_id = coalesce(excluded.curriculum_version_id, curriculum_main_competences.curriculum_version_id),
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now()
  returning id into v_main_id;

  -- Specific Competence 4.1: Design simple computer programmes
  v_topic_id := null;
  select id into v_topic_id
  from public.topics
  where subject_id = v_subject_id and competency_code = '4.1';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Design simple computer programmes', 'Main Competence 4.0: Design simple computer programmes. Specific Competence 4.1. Weekly allocation: 7 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.25).', 6, true,
      '4.1', 30, 'Simple games that use a single shape are correctly developed by using block-based programming languages', 25
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Design simple computer programmes',
        summary = 'Main Competence 4.0: Design simple computer programmes. Specific Competence 4.1. Weekly allocation: 7 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.25).',
        display_order = 6,
        period_allocation = 30,
        assessment_criteria = 'Simple games that use a single shape are correctly developed by using block-based programming languages',
        source_page = 25,
        is_published = true,
        updated_at = now()
    where id = v_topic_id;
  end if;

  insert into public.curriculum_specific_competences (
    main_competence_id, subject_id, topic_id, code, title, description,
    period_allocation, assessment_criteria, source_page, display_order, is_published
  ) values (
    v_main_id, v_subject_id, v_topic_id, '4.1', 'Design simple computer programmes', 'Main Competence 4.0: Design simple computer programmes. Specific Competence 4.1. Weekly allocation: 7 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.25).',
    30, 'Simple games that use a single shape are correctly developed by using block-based programming languages', 25, 1, true
  )
  on conflict (topic_id) do update
    set main_competence_id = excluded.main_competence_id,
        code = excluded.code,
        title = excluded.title,
        description = excluded.description,
        period_allocation = excluded.period_allocation,
        assessment_criteria = excluded.assessment_criteria,
        source_page = excluded.source_page,
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now();

  -- Refresh official learning activity subtopics idempotently
  delete from public.subtopics where topic_id = v_topic_id;
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Develop simple games that use a single shape by using block-based programming language', 'TIE 2023 Science Standard IV (ISBN 978-9987-09-860-6, p.25)',
    'Simple games that use a single shape are correctly developed by using block-based programming languages', 'Simple games that use a single shape are correctly developed by using block-based programming languages', 30, 1, 25, true
  );

end $$;

-- ============================================================================
-- Science — Standard V (STANDARD_5): 175 periods
-- ============================================================================
do $$
declare
  v_curriculum_id uuid;
  v_level_id uuid;
  v_grade_id uuid;
  v_version_id uuid;
  v_subject_id uuid;
  v_main_id uuid;
  v_topic_id uuid;
begin
  -- Natural-key resolution: Country (TZ) -> Curriculum (TIE) -> Level (PRIMARY) -> Grade
  select id into v_curriculum_id
  from public.curricula
  where country_code = 'TZ' and code = 'TIE'
  limit 1;
  if v_curriculum_id is null then
    raise exception 'Natural-key resolution failed: TZ TIE curriculum not found';
  end if;

  select id into v_level_id
  from public.education_levels
  where curriculum_id = v_curriculum_id and code = 'PRIMARY'
  limit 1;
  if v_level_id is null then
    raise exception 'Natural-key resolution failed: PRIMARY education level not found for TIE curriculum';
  end if;

  select id into v_grade_id
  from public.education_grades
  where curriculum_id = v_curriculum_id and education_level_id = v_level_id and code = 'STANDARD_5'
  limit 1;
  if v_grade_id is null then
    raise exception 'Natural-key resolution failed: education grade STANDARD_5 not found for TIE PRIMARY';
  end if;

  select id into v_version_id
  from public.curriculum_versions
  where curriculum_id = v_curriculum_id and version_code = 'TIE_PRIMARY_2023'
  limit 1;

  -- Upsert grade-scoped subject by natural key (curriculum_id, education_level_id, grade_id, code)
  select id into v_subject_id
  from public.subjects
  where country_code = 'TZ'
    and curriculum_id = v_curriculum_id
    and education_level_id = v_level_id
    and grade_id = v_grade_id
    and code = 'tie-pri-science-standard5';

  if v_subject_id is null then
    insert into public.subjects (
      country_code, curriculum_id, education_level_id, grade_id,
      code, name, official_name, description, display_order, is_published, classification, language
    ) values (
      'TZ', v_curriculum_id, v_level_id, v_grade_id,
      'tie-pri-science-standard5', 'Science', 'Science Syllabus for Primary Education — Standard V', 'Official 2023 TIE Science syllabus for Standard V (175 periods, 6 periods/week; ISBN 978-9987-09-860-6).',
      5, true, 'compulsory', 'en'
    ) returning id into v_subject_id;
  else
    update public.subjects
    set name = 'Science',
        official_name = 'Science Syllabus for Primary Education — Standard V',
        description = 'Official 2023 TIE Science syllabus for Standard V (175 periods, 6 periods/week; ISBN 978-9987-09-860-6).',
        display_order = 5,
        is_published = true,
        classification = 'compulsory',
        language = 'en',
        updated_at = now()
    where id = v_subject_id;
  end if;

  -- Main Competence 1.0: Demonstrate mastery of scientific theories
  insert into public.curriculum_main_competences (
    subject_id, curriculum_version_id, code, title, description, display_order, is_published
  ) values (
    v_subject_id, v_version_id, '1.0', 'Demonstrate mastery of scientific theories', 'Official 2023 TIE Science Standard V Main Competence 1.0 (ISBN 978-9987-09-860-6).', 1, true
  )
  on conflict (subject_id, code) do update
    set title = excluded.title,
        description = excluded.description,
        curriculum_version_id = coalesce(excluded.curriculum_version_id, curriculum_main_competences.curriculum_version_id),
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now()
  returning id into v_main_id;

  -- Specific Competence 1.1: Demonstrate an elementary understanding of scientific theories
  v_topic_id := null;
  select id into v_topic_id
  from public.topics
  where subject_id = v_subject_id and competency_code = '1.1';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Demonstrate an elementary understanding of scientific theories', 'Main Competence 1.0: Demonstrate mastery of scientific theories. Specific Competence 1.1. Weekly allocation: 6 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.26).', 1, true,
      '1.1', 45, 'Human digestive system is correctly explained', 26
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Demonstrate an elementary understanding of scientific theories',
        summary = 'Main Competence 1.0: Demonstrate mastery of scientific theories. Specific Competence 1.1. Weekly allocation: 6 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.26).',
        display_order = 1,
        period_allocation = 45,
        assessment_criteria = 'Human digestive system is correctly explained',
        source_page = 26,
        is_published = true,
        updated_at = now()
    where id = v_topic_id;
  end if;

  insert into public.curriculum_specific_competences (
    main_competence_id, subject_id, topic_id, code, title, description,
    period_allocation, assessment_criteria, source_page, display_order, is_published
  ) values (
    v_main_id, v_subject_id, v_topic_id, '1.1', 'Demonstrate an elementary understanding of scientific theories', 'Main Competence 1.0: Demonstrate mastery of scientific theories. Specific Competence 1.1. Weekly allocation: 6 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.26).',
    45, 'Human digestive system is correctly explained', 26, 1, true
  )
  on conflict (topic_id) do update
    set main_competence_id = excluded.main_competence_id,
        code = excluded.code,
        title = excluded.title,
        description = excluded.description,
        period_allocation = excluded.period_allocation,
        assessment_criteria = excluded.assessment_criteria,
        source_page = excluded.source_page,
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now();

  -- Refresh official learning activity subtopics idempotently
  delete from public.subtopics where topic_id = v_topic_id;
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Explain the human digestive system (meaning, parts and their functions)', 'TIE 2023 Science Standard V (ISBN 978-9987-09-860-6, p.26)',
    'Human digestive system is correctly explained', 'Human digestive system is correctly explained', 12, 1, 26, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Explain the human reproductive systems', 'TIE 2023 Science Standard V (ISBN 978-9987-09-860-6, p.27)',
    'Female and male reproductive systems are correctly explained', 'Female and male reproductive systems are correctly explained', 11, 2, 27, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(c) Explain the growth in animals and plants', 'TIE 2023 Science Standard V (ISBN 978-9987-09-860-6, p.27)',
    'Growth in animals and plants is clearly explained', 'Growth in animals and plants is clearly explained', 11, 3, 27, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(d) Explain the stages of development of the human body', 'TIE 2023 Science Standard V (ISBN 978-9987-09-860-6, p.28)',
    'Stages of development of human body are correctly explained', 'Stages of development of human body are correctly explained', 11, 4, 28, true
  );

  -- Specific Competence 1.2: Demonstrate a basic understanding of types of energy and their uses
  v_topic_id := null;
  select id into v_topic_id
  from public.topics
  where subject_id = v_subject_id and competency_code = '1.2';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Demonstrate a basic understanding of types of energy and their uses', 'Main Competence 1.0: Demonstrate mastery of scientific theories. Specific Competence 1.2. Weekly allocation: 6 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.29).', 2, true,
      '1.2', 45, 'Concept of magnetism is correctly explained', 29
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Demonstrate a basic understanding of types of energy and their uses',
        summary = 'Main Competence 1.0: Demonstrate mastery of scientific theories. Specific Competence 1.2. Weekly allocation: 6 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.29).',
        display_order = 2,
        period_allocation = 45,
        assessment_criteria = 'Concept of magnetism is correctly explained',
        source_page = 29,
        is_published = true,
        updated_at = now()
    where id = v_topic_id;
  end if;

  insert into public.curriculum_specific_competences (
    main_competence_id, subject_id, topic_id, code, title, description,
    period_allocation, assessment_criteria, source_page, display_order, is_published
  ) values (
    v_main_id, v_subject_id, v_topic_id, '1.2', 'Demonstrate a basic understanding of types of energy and their uses', 'Main Competence 1.0: Demonstrate mastery of scientific theories. Specific Competence 1.2. Weekly allocation: 6 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.29).',
    45, 'Concept of magnetism is correctly explained', 29, 2, true
  )
  on conflict (topic_id) do update
    set main_competence_id = excluded.main_competence_id,
        code = excluded.code,
        title = excluded.title,
        description = excluded.description,
        period_allocation = excluded.period_allocation,
        assessment_criteria = excluded.assessment_criteria,
        source_page = excluded.source_page,
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now();

  -- Refresh official learning activity subtopics idempotently
  delete from public.subtopics where topic_id = v_topic_id;
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Explain the concept of magnetism (meaning, properties and applications)', 'TIE 2023 Science Standard V (ISBN 978-9987-09-860-6, p.29)',
    'Concept of magnetism is correctly explained', 'Concept of magnetism is correctly explained', 45, 1, 29, true
  );

  -- Main Competence 2.0: Demonstrate mastery of elementary scientific skills
  insert into public.curriculum_main_competences (
    subject_id, curriculum_version_id, code, title, description, display_order, is_published
  ) values (
    v_subject_id, v_version_id, '2.0', 'Demonstrate mastery of elementary scientific skills', 'Official 2023 TIE Science Standard V Main Competence 2.0 (ISBN 978-9987-09-860-6).', 2, true
  )
  on conflict (subject_id, code) do update
    set title = excluded.title,
        description = excluded.description,
        curriculum_version_id = coalesce(excluded.curriculum_version_id, curriculum_main_competences.curriculum_version_id),
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now()
  returning id into v_main_id;

  -- Specific Competence 2.1: Conduct elementary scientific experiments
  v_topic_id := null;
  select id into v_topic_id
  from public.topics
  where subject_id = v_subject_id and competency_code = '2.1';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Conduct elementary scientific experiments', 'Main Competence 2.0: Demonstrate mastery of elementary scientific skills. Specific Competence 2.1. Weekly allocation: 6 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.30).', 3, true,
      '2.1', 45, 'Simple scientific experiments on growth in animals and plants are correctly conducted', 30
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Conduct elementary scientific experiments',
        summary = 'Main Competence 2.0: Demonstrate mastery of elementary scientific skills. Specific Competence 2.1. Weekly allocation: 6 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.30).',
        display_order = 3,
        period_allocation = 45,
        assessment_criteria = 'Simple scientific experiments on growth in animals and plants are correctly conducted',
        source_page = 30,
        is_published = true,
        updated_at = now()
    where id = v_topic_id;
  end if;

  insert into public.curriculum_specific_competences (
    main_competence_id, subject_id, topic_id, code, title, description,
    period_allocation, assessment_criteria, source_page, display_order, is_published
  ) values (
    v_main_id, v_subject_id, v_topic_id, '2.1', 'Conduct elementary scientific experiments', 'Main Competence 2.0: Demonstrate mastery of elementary scientific skills. Specific Competence 2.1. Weekly allocation: 6 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.30).',
    45, 'Simple scientific experiments on growth in animals and plants are correctly conducted', 30, 1, true
  )
  on conflict (topic_id) do update
    set main_competence_id = excluded.main_competence_id,
        code = excluded.code,
        title = excluded.title,
        description = excluded.description,
        period_allocation = excluded.period_allocation,
        assessment_criteria = excluded.assessment_criteria,
        source_page = excluded.source_page,
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now();

  -- Refresh official learning activity subtopics idempotently
  delete from public.subtopics where topic_id = v_topic_id;
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Conduct simple scientific experiments on growth in animals and plants', 'TIE 2023 Science Standard V (ISBN 978-9987-09-860-6, p.30)',
    'Simple scientific experiments on growth in animals and plants are correctly conducted', 'Simple scientific experiments on growth in animals and plants are correctly conducted', 23, 1, 30, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Conduct simple experiments to demonstrate magnetic properties', 'TIE 2023 Science Standard V (ISBN 978-9987-09-860-6, p.31)',
    'Simple experiments to demonstrate magnetic properties are correctly conducted', 'Simple experiments to demonstrate magnetic properties are correctly conducted', 22, 2, 31, true
  );

  -- Main Competence 3.0: Design simple computer programmes
  insert into public.curriculum_main_competences (
    subject_id, curriculum_version_id, code, title, description, display_order, is_published
  ) values (
    v_subject_id, v_version_id, '3.0', 'Design simple computer programmes', 'Official 2023 TIE Science Standard V Main Competence 3.0 (ISBN 978-9987-09-860-6).', 3, true
  )
  on conflict (subject_id, code) do update
    set title = excluded.title,
        description = excluded.description,
        curriculum_version_id = coalesce(excluded.curriculum_version_id, curriculum_main_competences.curriculum_version_id),
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now()
  returning id into v_main_id;

  -- Specific Competence 3.1: Design simple computer programmes
  v_topic_id := null;
  select id into v_topic_id
  from public.topics
  where subject_id = v_subject_id and competency_code = '3.1';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Design simple computer programmes', 'Main Competence 3.0: Design simple computer programmes. Specific Competence 3.1. Weekly allocation: 6 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.31).', 4, true,
      '3.1', 40, 'Simple games of two shapes are correctly developed using block-based programming language', 31
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Design simple computer programmes',
        summary = 'Main Competence 3.0: Design simple computer programmes. Specific Competence 3.1. Weekly allocation: 6 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.31).',
        display_order = 4,
        period_allocation = 40,
        assessment_criteria = 'Simple games of two shapes are correctly developed using block-based programming language',
        source_page = 31,
        is_published = true,
        updated_at = now()
    where id = v_topic_id;
  end if;

  insert into public.curriculum_specific_competences (
    main_competence_id, subject_id, topic_id, code, title, description,
    period_allocation, assessment_criteria, source_page, display_order, is_published
  ) values (
    v_main_id, v_subject_id, v_topic_id, '3.1', 'Design simple computer programmes', 'Main Competence 3.0: Design simple computer programmes. Specific Competence 3.1. Weekly allocation: 6 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.31).',
    40, 'Simple games of two shapes are correctly developed using block-based programming language', 31, 1, true
  )
  on conflict (topic_id) do update
    set main_competence_id = excluded.main_competence_id,
        code = excluded.code,
        title = excluded.title,
        description = excluded.description,
        period_allocation = excluded.period_allocation,
        assessment_criteria = excluded.assessment_criteria,
        source_page = excluded.source_page,
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now();

  -- Refresh official learning activity subtopics idempotently
  delete from public.subtopics where topic_id = v_topic_id;
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Develop simple games that use two shapes using block-based programming language', 'TIE 2023 Science Standard V (ISBN 978-9987-09-860-6, p.31)',
    'Simple games of two shapes are correctly developed using block-based programming language', 'Simple games of two shapes are correctly developed using block-based programming language', 40, 1, 31, true
  );

end $$;

-- ============================================================================
-- Science — Standard VI (STANDARD_6): 175 periods
-- ============================================================================
do $$
declare
  v_curriculum_id uuid;
  v_level_id uuid;
  v_grade_id uuid;
  v_version_id uuid;
  v_subject_id uuid;
  v_main_id uuid;
  v_topic_id uuid;
begin
  -- Natural-key resolution: Country (TZ) -> Curriculum (TIE) -> Level (PRIMARY) -> Grade
  select id into v_curriculum_id
  from public.curricula
  where country_code = 'TZ' and code = 'TIE'
  limit 1;
  if v_curriculum_id is null then
    raise exception 'Natural-key resolution failed: TZ TIE curriculum not found';
  end if;

  select id into v_level_id
  from public.education_levels
  where curriculum_id = v_curriculum_id and code = 'PRIMARY'
  limit 1;
  if v_level_id is null then
    raise exception 'Natural-key resolution failed: PRIMARY education level not found for TIE curriculum';
  end if;

  select id into v_grade_id
  from public.education_grades
  where curriculum_id = v_curriculum_id and education_level_id = v_level_id and code = 'STANDARD_6'
  limit 1;
  if v_grade_id is null then
    raise exception 'Natural-key resolution failed: education grade STANDARD_6 not found for TIE PRIMARY';
  end if;

  select id into v_version_id
  from public.curriculum_versions
  where curriculum_id = v_curriculum_id and version_code = 'TIE_PRIMARY_2023'
  limit 1;

  -- Upsert grade-scoped subject by natural key (curriculum_id, education_level_id, grade_id, code)
  select id into v_subject_id
  from public.subjects
  where country_code = 'TZ'
    and curriculum_id = v_curriculum_id
    and education_level_id = v_level_id
    and grade_id = v_grade_id
    and code = 'tie-pri-science-standard6';

  if v_subject_id is null then
    insert into public.subjects (
      country_code, curriculum_id, education_level_id, grade_id,
      code, name, official_name, description, display_order, is_published, classification, language
    ) values (
      'TZ', v_curriculum_id, v_level_id, v_grade_id,
      'tie-pri-science-standard6', 'Science', 'Science Syllabus for Primary Education — Standard VI', 'Official 2023 TIE Science syllabus for Standard VI (175 periods, 6 periods/week; ISBN 978-9987-09-860-6).',
      5, true, 'compulsory', 'en'
    ) returning id into v_subject_id;
  else
    update public.subjects
    set name = 'Science',
        official_name = 'Science Syllabus for Primary Education — Standard VI',
        description = 'Official 2023 TIE Science syllabus for Standard VI (175 periods, 6 periods/week; ISBN 978-9987-09-860-6).',
        display_order = 5,
        is_published = true,
        classification = 'compulsory',
        language = 'en',
        updated_at = now()
    where id = v_subject_id;
  end if;

  -- Main Competence 1.0: Demonstrate mastery of scientific theories
  insert into public.curriculum_main_competences (
    subject_id, curriculum_version_id, code, title, description, display_order, is_published
  ) values (
    v_subject_id, v_version_id, '1.0', 'Demonstrate mastery of scientific theories', 'Official 2023 TIE Science Standard VI Main Competence 1.0 (ISBN 978-9987-09-860-6).', 1, true
  )
  on conflict (subject_id, code) do update
    set title = excluded.title,
        description = excluded.description,
        curriculum_version_id = coalesce(excluded.curriculum_version_id, curriculum_main_competences.curriculum_version_id),
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now()
  returning id into v_main_id;

  -- Specific Competence 1.1: Demonstrate elementary understanding of scientific theories
  v_topic_id := null;
  select id into v_topic_id
  from public.topics
  where subject_id = v_subject_id and competency_code = '1.1';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Demonstrate elementary understanding of scientific theories', 'Main Competence 1.0: Demonstrate mastery of scientific theories. Specific Competence 1.1. Weekly allocation: 6 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.33).', 1, true,
      '1.1', 45, 'Respiratory systems in animals and plants are clearly explained', 33
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Demonstrate elementary understanding of scientific theories',
        summary = 'Main Competence 1.0: Demonstrate mastery of scientific theories. Specific Competence 1.1. Weekly allocation: 6 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.33).',
        display_order = 1,
        period_allocation = 45,
        assessment_criteria = 'Respiratory systems in animals and plants are clearly explained',
        source_page = 33,
        is_published = true,
        updated_at = now()
    where id = v_topic_id;
  end if;

  insert into public.curriculum_specific_competences (
    main_competence_id, subject_id, topic_id, code, title, description,
    period_allocation, assessment_criteria, source_page, display_order, is_published
  ) values (
    v_main_id, v_subject_id, v_topic_id, '1.1', 'Demonstrate elementary understanding of scientific theories', 'Main Competence 1.0: Demonstrate mastery of scientific theories. Specific Competence 1.1. Weekly allocation: 6 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.33).',
    45, 'Respiratory systems in animals and plants are clearly explained', 33, 1, true
  )
  on conflict (topic_id) do update
    set main_competence_id = excluded.main_competence_id,
        code = excluded.code,
        title = excluded.title,
        description = excluded.description,
        period_allocation = excluded.period_allocation,
        assessment_criteria = excluded.assessment_criteria,
        source_page = excluded.source_page,
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now();

  -- Refresh official learning activity subtopics idempotently
  delete from public.subtopics where topic_id = v_topic_id;
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Explain respiratory systems in animals and plants (meaning, parts and mechanisms)', 'TIE 2023 Science Standard VI (ISBN 978-9987-09-860-6, p.33)',
    'Respiratory systems in animals and plants are clearly explained', 'Respiratory systems in animals and plants are clearly explained', 12, 1, 33, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Explain the concept of acids and bases (meaning, properties, source and uses)', 'TIE 2023 Science Standard VI (ISBN 978-9987-09-860-6, p.34)',
    'The concepts of acids and bases are clearly explained', 'The concepts of acids and bases are clearly explained', 11, 2, 34, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(c) Explain the concept of a machine (meaning, types and uses)', 'TIE 2023 Science Standard VI (ISBN 978-9987-09-860-6, p.34)',
    'The concept of a machine and its uses are clearly explained', 'The concept of a machine and its uses are clearly explained', 11, 3, 34, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(d) Explain the concepts of floating and sinking', 'TIE 2023 Science Standard VI (ISBN 978-9987-09-860-6, p.35)',
    'The concepts of floating and sinking of objects are explained clearly', 'The concepts of floating and sinking of objects are explained clearly', 11, 4, 35, true
  );

  -- Specific Competence 1.2: Demonstrate a basic understanding of types of energy and their uses
  v_topic_id := null;
  select id into v_topic_id
  from public.topics
  where subject_id = v_subject_id and competency_code = '1.2';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Demonstrate a basic understanding of types of energy and their uses', 'Main Competence 1.0: Demonstrate mastery of scientific theories. Specific Competence 1.2. Weekly allocation: 6 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.36).', 2, true,
      '1.2', 45, 'The concept of electricity is clearly explained', 36
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Demonstrate a basic understanding of types of energy and their uses',
        summary = 'Main Competence 1.0: Demonstrate mastery of scientific theories. Specific Competence 1.2. Weekly allocation: 6 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.36).',
        display_order = 2,
        period_allocation = 45,
        assessment_criteria = 'The concept of electricity is clearly explained',
        source_page = 36,
        is_published = true,
        updated_at = now()
    where id = v_topic_id;
  end if;

  insert into public.curriculum_specific_competences (
    main_competence_id, subject_id, topic_id, code, title, description,
    period_allocation, assessment_criteria, source_page, display_order, is_published
  ) values (
    v_main_id, v_subject_id, v_topic_id, '1.2', 'Demonstrate a basic understanding of types of energy and their uses', 'Main Competence 1.0: Demonstrate mastery of scientific theories. Specific Competence 1.2. Weekly allocation: 6 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.36).',
    45, 'The concept of electricity is clearly explained', 36, 2, true
  )
  on conflict (topic_id) do update
    set main_competence_id = excluded.main_competence_id,
        code = excluded.code,
        title = excluded.title,
        description = excluded.description,
        period_allocation = excluded.period_allocation,
        assessment_criteria = excluded.assessment_criteria,
        source_page = excluded.source_page,
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now();

  -- Refresh official learning activity subtopics idempotently
  delete from public.subtopics where topic_id = v_topic_id;
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Explain the concept of electricity (meaning, sources and uses)', 'TIE 2023 Science Standard VI (ISBN 978-9987-09-860-6, p.36)',
    'The concept of electricity is clearly explained', 'The concept of electricity is clearly explained', 23, 1, 36, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Describe simple electric circuit (parts, type, symbols and constructions)', 'TIE 2023 Science Standard VI (ISBN 978-9987-09-860-6, p.37)',
    'The concept of simple electric circuit is explained clearly', 'The concept of simple electric circuit is explained clearly', 22, 2, 37, true
  );

  -- Main Competence 2.0: Demonstrate mastery of elementary scientific skills
  insert into public.curriculum_main_competences (
    subject_id, curriculum_version_id, code, title, description, display_order, is_published
  ) values (
    v_subject_id, v_version_id, '2.0', 'Demonstrate mastery of elementary scientific skills', 'Official 2023 TIE Science Standard VI Main Competence 2.0 (ISBN 978-9987-09-860-6).', 2, true
  )
  on conflict (subject_id, code) do update
    set title = excluded.title,
        description = excluded.description,
        curriculum_version_id = coalesce(excluded.curriculum_version_id, curriculum_main_competences.curriculum_version_id),
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now()
  returning id into v_main_id;

  -- Specific Competence 2.1: Conduct elementary scientific experiments
  v_topic_id := null;
  select id into v_topic_id
  from public.topics
  where subject_id = v_subject_id and competency_code = '2.1';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Conduct elementary scientific experiments', 'Main Competence 2.0: Demonstrate mastery of elementary scientific skills. Specific Competence 2.1. Weekly allocation: 6 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.38).', 3, true,
      '2.1', 45, 'Experiments to identify acids and bases substances in the environment are correctly conducted', 38
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Conduct elementary scientific experiments',
        summary = 'Main Competence 2.0: Demonstrate mastery of elementary scientific skills. Specific Competence 2.1. Weekly allocation: 6 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.38).',
        display_order = 3,
        period_allocation = 45,
        assessment_criteria = 'Experiments to identify acids and bases substances in the environment are correctly conducted',
        source_page = 38,
        is_published = true,
        updated_at = now()
    where id = v_topic_id;
  end if;

  insert into public.curriculum_specific_competences (
    main_competence_id, subject_id, topic_id, code, title, description,
    period_allocation, assessment_criteria, source_page, display_order, is_published
  ) values (
    v_main_id, v_subject_id, v_topic_id, '2.1', 'Conduct elementary scientific experiments', 'Main Competence 2.0: Demonstrate mastery of elementary scientific skills. Specific Competence 2.1. Weekly allocation: 6 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.38).',
    45, 'Experiments to identify acids and bases substances in the environment are correctly conducted', 38, 1, true
  )
  on conflict (topic_id) do update
    set main_competence_id = excluded.main_competence_id,
        code = excluded.code,
        title = excluded.title,
        description = excluded.description,
        period_allocation = excluded.period_allocation,
        assessment_criteria = excluded.assessment_criteria,
        source_page = excluded.source_page,
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now();

  -- Refresh official learning activity subtopics idempotently
  delete from public.subtopics where topic_id = v_topic_id;
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Conduct simple experiments to identify acids and bases in the environment', 'TIE 2023 Science Standard VI (ISBN 978-9987-09-860-6, p.38)',
    'Experiments to identify acids and bases substances in the environment are correctly conducted', 'Experiments to identify acids and bases substances in the environment are correctly conducted', 12, 1, 38, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Conduct simple experiments about machines', 'TIE 2023 Science Standard VI (ISBN 978-9987-09-860-6, p.38)',
    'Simple experiments about machines are correctly conducted', 'Simple experiments about machines are correctly conducted', 11, 2, 38, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(c) Conduct simple experiments on floating or sinking', 'TIE 2023 Science Standard VI (ISBN 978-9987-09-860-6, p.39)',
    'Experiments to identify objects that float or sink are correctly conducted', 'Experiments to identify objects that float or sink are correctly conducted', 11, 3, 39, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(d) Conduct experiments on simple electric circuits', 'TIE 2023 Science Standard VI (ISBN 978-9987-09-860-6, p.39)',
    'Experiments on simple electric circuits are correctly conducted', 'Experiments on simple electric circuits are correctly conducted', 11, 4, 39, true
  );

  -- Main Competence 3.0: Design simple computer programmes
  insert into public.curriculum_main_competences (
    subject_id, curriculum_version_id, code, title, description, display_order, is_published
  ) values (
    v_subject_id, v_version_id, '3.0', 'Design simple computer programmes', 'Official 2023 TIE Science Standard VI Main Competence 3.0 (ISBN 978-9987-09-860-6).', 3, true
  )
  on conflict (subject_id, code) do update
    set title = excluded.title,
        description = excluded.description,
        curriculum_version_id = coalesce(excluded.curriculum_version_id, curriculum_main_competences.curriculum_version_id),
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now()
  returning id into v_main_id;

  -- Specific Competence 3.1: Design simple computer programmes
  v_topic_id := null;
  select id into v_topic_id
  from public.topics
  where subject_id = v_subject_id and competency_code = '3.1';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Design simple computer programmes', 'Main Competence 3.0: Design simple computer programmes. Specific Competence 3.1. Weekly allocation: 6 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.40).', 4, true,
      '3.1', 40, 'Simple games that use more than two shapes are correctly developed using block-based programming languages', 40
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Design simple computer programmes',
        summary = 'Main Competence 3.0: Design simple computer programmes. Specific Competence 3.1. Weekly allocation: 6 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.40).',
        display_order = 4,
        period_allocation = 40,
        assessment_criteria = 'Simple games that use more than two shapes are correctly developed using block-based programming languages',
        source_page = 40,
        is_published = true,
        updated_at = now()
    where id = v_topic_id;
  end if;

  insert into public.curriculum_specific_competences (
    main_competence_id, subject_id, topic_id, code, title, description,
    period_allocation, assessment_criteria, source_page, display_order, is_published
  ) values (
    v_main_id, v_subject_id, v_topic_id, '3.1', 'Design simple computer programmes', 'Main Competence 3.0: Design simple computer programmes. Specific Competence 3.1. Weekly allocation: 6 periods. Source: TIE 2023 Science Syllabus (ISBN 978-9987-09-860-6, p.40).',
    40, 'Simple games that use more than two shapes are correctly developed using block-based programming languages', 40, 1, true
  )
  on conflict (topic_id) do update
    set main_competence_id = excluded.main_competence_id,
        code = excluded.code,
        title = excluded.title,
        description = excluded.description,
        period_allocation = excluded.period_allocation,
        assessment_criteria = excluded.assessment_criteria,
        source_page = excluded.source_page,
        display_order = excluded.display_order,
        is_published = true,
        updated_at = now();

  -- Refresh official learning activity subtopics idempotently
  delete from public.subtopics where topic_id = v_topic_id;
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Develop simple games that use more than two shapes using block-based programming languages', 'TIE 2023 Science Standard VI (ISBN 978-9987-09-860-6, p.40)',
    'Simple games that use more than two shapes are correctly developed using block-based programming languages', 'Simple games that use more than two shapes are correctly developed using block-based programming languages', 40, 1, 40, true
  );

end $$;

commit;
