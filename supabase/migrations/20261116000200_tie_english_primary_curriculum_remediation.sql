-- ============================================================================
-- LearnTZ — TIE English Language Primary Curriculum Remediation (Std III–VI)
-- Authoritative 2023 Competency-Based Syllabus Ingestion & Gap Remediation
-- Sourced from: data/curriculum/tz/sw-1727168466-ENGLISH Syllabus III-VI FINAL.pdf
-- ISBN: 978-9987-09-726-5 | 64 Pages | First Edition 2023 by TIE under MoEST
-- SHA-256: ae6b2f5d28b60bb77bd3bb2d7816535bacb671934cca4660705cfa937f9aacd2
-- ============================================================================

begin;

-- 1. Remediate the 4 Framework-Gap Placeholder Records from Migration 20261115000600
-- These 4 placeholder topics collapsed Standards III-VI into 4 artificial topics under umbrella 'tie-pri-english'.
do $$
declare
  v_gap_topic_ids uuid[];
begin
  select array_agg(id) into v_gap_topic_ids
  from public.topics
  where id in (
    '0db9d085-051c-4d2a-87d2-336c9868b3c3', -- Greetings & Self-Introduction
    '9b9a9125-7a95-4d86-9ead-71f69000655b', -- Simple Present and Continuous
    '19b4c5be-5438-47a4-9e99-0283a2b702d7', -- Giving Directions
    '5022a6ff-7d00-4e50-8920-d6e626a5a544'  -- Letter Writing & Composition
  );

  if v_gap_topic_ids is not null and array_length(v_gap_topic_ids, 1) > 0 then
    -- Remove subtopics attached to gap topics
    delete from public.subtopics where topic_id = any(v_gap_topic_ids);
    -- Remove the gap topics
    delete from public.topics where id = any(v_gap_topic_ids);
  end if;

  -- Unpublish/archive the legacy grade-less umbrella subject so only grade-scoped subjects display
  update public.subjects
  set is_published = false,
      description = 'Archived umbrella subject superseded by grade-specific subjects (Std III-VI).'
  where id = 'aad316b8-8d97-4d79-9f01-a1946886185d';
end $$;

-- 2. Update Curriculum Source rights clearance and verification status
update public.curriculum_sources
set verification_status = 'verified',
    usage_rights_status = 'permission_pending',
    usage_rights_reviewed_at = now(),
    usage_rights_note = 'Reference metadata (competence codes, titles, learning activities, period allocations) verified against official 2023 TIE syllabus. Commercial full-text publication permission is pending; LearnTZ educational content, lessons, and assessments are original proprietary creations.'
where id = 'e8301da6-b2e7-4540-990b-c939a0faa22d';

-- 3. Ingest Authoritative Grade-Scoped Subjects, Competence Topics, and Learning Activity Subtopics
-- ============================================================================
-- Standard III (STANDARD_3): 244 Periods, 7 Periods/Week
-- ============================================================================
do $$
declare
  v_subject_id uuid;
  v_topic_id uuid;
begin
  -- Subject: Standard III
  v_subject_id := null;
  select id into v_subject_id from public.subjects
  where country_code = 'TZ' and curriculum_id = '20000000-0000-0000-0000-000000000002' and code = 'tie-pri-english-standard3' and grade_id = '03705394-edb4-41c8-813d-30d5a37b9c2e';

  if v_subject_id is null then
    insert into public.subjects (
      country_code, curriculum_id, education_level_id, grade_id,
      code, name, official_name, description, display_order, is_published, classification, language
    ) values (
      'TZ', '20000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000010', '03705394-edb4-41c8-813d-30d5a37b9c2e',
      'tie-pri-english-standard3', 'English Language', 'English Language Syllabus for Primary Education — Standard III', 'Developing English language competencies for Standard III (244 periods, 7 periods/week): listening, speaking, reading fluency, functional grammar, and writing as prescribed by TIE 2023 syllabus.', 3, true, 'compulsory', 'en'
    ) returning id into v_subject_id;
  else
    update public.subjects
    set name = 'English Language', official_name = 'English Language Syllabus for Primary Education — Standard III', description = 'Developing English language competencies for Standard III (244 periods, 7 periods/week): listening, speaking, reading fluency, functional grammar, and writing as prescribed by TIE 2023 syllabus.',
        classification = 'compulsory', language = 'en', is_published = true, display_order = 3
    where id = v_subject_id;
  end if;

  -- Specific Competence 1.1: Develop listening and speaking skills
  v_topic_id := null;
  select id into v_topic_id from public.topics
  where subject_id = v_subject_id and competency_code = '1.1';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Develop listening and speaking skills', 'Main Competence 1.0: Demonstrate mastery of basic English language skills. Specific Competence 1.1. Weekly allocation: 7 periods.', 1, true,
      '1.1', 30, 'Dictated words are written correctly', 8
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Develop listening and speaking skills', summary = 'Main Competence 1.0: Demonstrate mastery of basic English language skills. Specific Competence 1.1. Weekly allocation: 7 periods.', display_order = 1,
        period_allocation = 30, assessment_criteria = 'Dictated words are written correctly',
        source_page = 8, is_published = true
    where id = v_topic_id;
  end if;

  -- Delete existing subtopics for clean re-insertion of verified activities
  delete from public.subtopics where topic_id = v_topic_id;

  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Write dictated words', 'Texts and audio/audiovisual materials for listening and speaking', 'Dictation: Guide the pupils through writing words (use only words that the pupil has already learned to spell)', 'Dictated words are written correctly',
    15, 1, 8, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Listen and respond to questions based on simple stories from familiar contexts (home, school)', 'Texts and audio/audiovisual materials for listening and speaking', 'Prediction: Show the pupils a cover of a book to predict what the story is about. Storytelling: Tell the pupils a story using facial expressions, voices and gestures to support understanding.', 'Questions on simple stories in a familiar environment are responded to correctly',
    15, 2, 8, true
  );

  -- Specific Competence 1.2: Develop phonemic awareness and pronunciation of English letters
  v_topic_id := null;
  select id into v_topic_id from public.topics
  where subject_id = v_subject_id and competency_code = '1.2';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Develop phonemic awareness and pronunciation of English letters', 'Main Competence 1.0: Demonstrate mastery of basic English language skills. Specific Competence 1.2. Weekly allocation: 7 periods.', 2, true,
      '1.2', 64, 'Simple and short texts are read aloud fluently', 9
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Develop phonemic awareness and pronunciation of English letters', summary = 'Main Competence 1.0: Demonstrate mastery of basic English language skills. Specific Competence 1.2. Weekly allocation: 7 periods.', display_order = 2,
        period_allocation = 64, assessment_criteria = 'Simple and short texts are read aloud fluently',
        source_page = 9, is_published = true
    where id = v_topic_id;
  end if;

  -- Delete existing subtopics for clean re-insertion of verified activities
  delete from public.subtopics where topic_id = v_topic_id;

  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Read aloud simple short stories', 'Manila paper, cards, texts and audio/audiovisual materials with phonemes', 'Discussion: Give the pupils a list of words and guide them through pronouncing familiar words. Songs: Guide the pupils through singing songs with targeted words.', 'Simple and short texts are read aloud fluently',
    32, 1, 9, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Read short, simple texts for comprehension', 'Manila paper, cards, texts and audio/audiovisual materials with phonemes', 'Demonstration: Demonstrate by reading a text and asking comprehension questions. Scanning: Guide the pupils through picking and combining specific words from a text to generate the general idea.', 'Short texts are read for comprehension',
    32, 2, 9, true
  );

  -- Specific Competence 1.3: Use appropriate grammar and vocabulary both orally and in writing
  v_topic_id := null;
  select id into v_topic_id from public.topics
  where subject_id = v_subject_id and competency_code = '1.3';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Use appropriate grammar and vocabulary both orally and in writing', 'Main Competence 1.0: Demonstrate mastery of basic English language skills. Specific Competence 1.3. Weekly allocation: 7 periods.', 3, true,
      '1.3', 38, 'Personal pronouns are used correctly', 10
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Use appropriate grammar and vocabulary both orally and in writing', summary = 'Main Competence 1.0: Demonstrate mastery of basic English language skills. Specific Competence 1.3. Weekly allocation: 7 periods.', display_order = 3,
        period_allocation = 38, assessment_criteria = 'Personal pronouns are used correctly',
        source_page = 10, is_published = true
    where id = v_topic_id;
  end if;

  -- Delete existing subtopics for clean re-insertion of verified activities
  delete from public.subtopics where topic_id = v_topic_id;

  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Use personal pronouns', 'Texts and audio/audiovisual materials with grammar and vocabulary', 'Matching: Use pictures to guide the pupils through pronouncing the words him, her, it, them, you, etc. Songs: Guide the pupils through singing songs with pronouns and ask them some questions about the pronouns.', 'Personal pronouns are used correctly',
    10, 1, 10, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Express possession using the verbs have and has', 'Texts and audio/audiovisual materials with grammar and vocabulary', 'Describing: Guide the pupils through expressing possessions using have and has. Draw and Describe: Ask the pupils to draw pictures and describe them using have and has.', 'Possessions are well expressed using the verbs have and has',
    10, 2, 10, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(c) Express routines and ongoing activities in school and home contexts (target: simple present tense, present continuous tense)', 'Texts and audio/audiovisual materials with grammar and vocabulary', 'Demonstration: Demonstrate the use and structure of simple present tense, and present continuous tense. Chart: Use a chart with columns for the simple present and present continuous process to show the pupils how -s, -es and -ies are added to the verb. Pictures: Show the pupils a series of pictures with sentences underneath narrating what is happening in the images.', 'Routines and ongoing activities in school and home contexts are expressed correctly',
    9, 3, 10, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(d) Use conjunctions in oral and written contexts (target: and, but)', 'Texts and audio/audiovisual materials with grammar and vocabulary', 'Songs: Play recorded songs about conjunctions and ask the pupils to identify the conjunctions. Explanation: Compose pairs of simple sentences for pupils to see how and and but are used.', 'Conjunctions are used in oral and written contexts',
    9, 4, 10, true
  );

  -- Specific Competence 2.1: Read a variety of simple texts appropriately
  v_topic_id := null;
  select id into v_topic_id from public.topics
  where subject_id = v_subject_id and competency_code = '2.1';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Read a variety of simple texts appropriately', 'Main Competence 2.0: Comprehend oral and written information. Specific Competence 2.1. Weekly allocation: 7 periods.', 4, true,
      '2.1', 56, 'Two syllables and grade-appropriate words are read correctly', 12
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Read a variety of simple texts appropriately', summary = 'Main Competence 2.0: Comprehend oral and written information. Specific Competence 2.1. Weekly allocation: 7 periods.', display_order = 4,
        period_allocation = 56, assessment_criteria = 'Two syllables and grade-appropriate words are read correctly',
        source_page = 12, is_published = true
    where id = v_topic_id;
  end if;

  -- Delete existing subtopics for clean re-insertion of verified activities
  delete from public.subtopics where topic_id = v_topic_id;

  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Read two-syllable and grade-appropriate words', 'Various reading texts', 'Explain and demonstrate: Demonstrate and explain the structure of syllables. Syllable Match-Ups: Give the pupils cards with single syllables to match up and make new two-syllable words.', 'Two syllables and grade-appropriate words are read correctly',
    19, 1, 12, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Read multi-syllable and grade-appropriate words', 'Various reading texts', 'Clapping Games: Guide the pupils through identifying syllables in spoken words by clapping for each syllable. Jumping syllables: Lead the pupils to separate words into syllables and create new words. Songs: Use fun songs such as The Wheels on the Bus, Old McDonald, The Itsy Bitsy Spider, Bingo, and Row Row Row Your Boat to learn to pronounce words into syllables. Using pictures: Guide the pupils through identifying and saying multi syllabic words from magazines or online sources.', 'Multi-syllable and grade-appropriate words are read correctly',
    19, 2, 12, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(c) Read aloud a variety of grade-level texts', 'Various reading texts', 'Modelling: Read a text aloud then ask the pupils to read the texts after you have read. Question and Answer: Ask questions before, during and after reading a text.', 'A variety of grade-level texts are read aloud',
    18, 3, 12, true
  );

  -- Specific Competence 3.1: Demonstrate knowledge of the basic features of spoken language
  v_topic_id := null;
  select id into v_topic_id from public.topics
  where subject_id = v_subject_id and competency_code = '3.1';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Demonstrate knowledge of the basic features of spoken language', 'Main Competence 3.0: Communicate effectively in different contexts. Specific Competence 3.1. Weekly allocation: 7 periods.', 5, true,
      '3.1', 56, 'Words with short and long vowels are identified', 14
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Demonstrate knowledge of the basic features of spoken language', summary = 'Main Competence 3.0: Communicate effectively in different contexts. Specific Competence 3.1. Weekly allocation: 7 periods.', display_order = 5,
        period_allocation = 56, assessment_criteria = 'Words with short and long vowels are identified',
        source_page = 14, is_published = true
    where id = v_topic_id;
  end if;

  -- Delete existing subtopics for clean re-insertion of verified activities
  delete from public.subtopics where topic_id = v_topic_id;

  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Identify words with short and long vowels (e.g., ship/sheep, full/fool, to/too)', 'Wallcharts, texts and audio/audiovisual materials with features of spoken language', 'Read and write: Guide the pupils through pronouncing and writing words with long vowels. Sort the words: Guide pupils through sorting the words based on how long vowel sounds are spelled.', 'Words with short and long vowels are identified',
    19, 1, 14, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Pronounce words with long vowel sounds with speed and fluency', 'Wallcharts, texts and audio/audiovisual materials with features of spoken language', 'Discussion: Ask the pupils to discuss and circle the correct spelling of words with long vowel sounds.', 'Words with long vowels are pronounced with speed and fluency',
    19, 2, 14, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(c) Read short phrases and simple sentences with short and long vowels', 'Wallcharts, texts and audio/audiovisual materials with features of spoken language', 'Instructional routines: Guide the pupils through using ''touch and say'' to read phrases containing long vowels.', 'Short phrases and simple sentences with short and long vowels are read correctly',
    18, 3, 14, true
  );

end $$;

-- ============================================================================
-- Standard IV (STANDARD_4): 234 Periods, 7 Periods/Week
-- ============================================================================
do $$
declare
  v_subject_id uuid;
  v_topic_id uuid;
begin
  -- Subject: Standard IV
  v_subject_id := null;
  select id into v_subject_id from public.subjects
  where country_code = 'TZ' and curriculum_id = '20000000-0000-0000-0000-000000000002' and code = 'tie-pri-english-standard4' and grade_id = 'deeb8105-49e8-45ff-83ac-97a85633cef2';

  if v_subject_id is null then
    insert into public.subjects (
      country_code, curriculum_id, education_level_id, grade_id,
      code, name, official_name, description, display_order, is_published, classification, language
    ) values (
      'TZ', '20000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000010', 'deeb8105-49e8-45ff-83ac-97a85633cef2',
      'tie-pri-english-standard4', 'English Language', 'English Language Syllabus for Primary Education — Standard IV', 'Developing English language competencies for Standard IV (234 periods, 7 periods/week): listening, speaking, reading fluency, functional grammar, and writing as prescribed by TIE 2023 syllabus.', 3, true, 'compulsory', 'en'
    ) returning id into v_subject_id;
  else
    update public.subjects
    set name = 'English Language', official_name = 'English Language Syllabus for Primary Education — Standard IV', description = 'Developing English language competencies for Standard IV (234 periods, 7 periods/week): listening, speaking, reading fluency, functional grammar, and writing as prescribed by TIE 2023 syllabus.',
        classification = 'compulsory', language = 'en', is_published = true, display_order = 3
    where id = v_subject_id;
  end if;

  -- Specific Competence 1.1: Develop vocabulary by relating words with objects in the environment
  v_topic_id := null;
  select id into v_topic_id from public.topics
  where subject_id = v_subject_id and competency_code = '1.1';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Develop vocabulary by relating words with objects in the environment', 'Main Competence 1.0: Demonstrate mastery of basic English language skills. Specific Competence 1.1. Weekly allocation: 7 periods.', 1, true,
      '1.1', 22, 'Words are associated with objects found in different contexts', 16
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Develop vocabulary by relating words with objects in the environment', summary = 'Main Competence 1.0: Demonstrate mastery of basic English language skills. Specific Competence 1.1. Weekly allocation: 7 periods.', display_order = 1,
        period_allocation = 22, assessment_criteria = 'Words are associated with objects found in different contexts',
        source_page = 16, is_published = true
    where id = v_topic_id;
  end if;

  -- Delete existing subtopics for clean re-insertion of verified activities
  delete from public.subtopics where topic_id = v_topic_id;

  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Associate words with objects found in different contexts (e.g., home, hospital, market, bus station)', 'Realia, word lists, charts and audio/audiovisual materials with environmental vocabulary', 'Direct/explicit instruction: Guide the pupils through learning words in their immediate surroundings. Repetition and multiple exposures: Expose the pupils to new words.', 'Words are associated with objects found in different contexts',
    8, 1, 16, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Match objects with their respective characteristics', 'Realia, word lists, charts and audio/audiovisual materials with environmental vocabulary', 'Vocabulary 7-up game: Guide the pupils through matching vocabulary with objects in a simple game.', 'Words are matched with their respective characteristics',
    7, 2, 16, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(c) Construct short sentences using vocabulary referring to objects found in different settings', 'Realia, word lists, charts and audio/audiovisual materials with environmental vocabulary', 'Word walls: Ask the pupils to construct sentences with words on the word wall.', 'Short sentences are constructed by using vocabulary referring to objects found in different settings',
    7, 3, 16, true
  );

  -- Specific Competence 1.2: Use appropriate grammar and vocabulary both orally and in writing
  v_topic_id := null;
  select id into v_topic_id from public.topics
  where subject_id = v_subject_id and competency_code = '1.2';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Use appropriate grammar and vocabulary both orally and in writing', 'Main Competence 1.0: Demonstrate mastery of basic English language skills. Specific Competence 1.2. Weekly allocation: 7 periods.', 2, true,
      '1.2', 40, 'Quantities are expressed using appropriate words', 17
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Use appropriate grammar and vocabulary both orally and in writing', summary = 'Main Competence 1.0: Demonstrate mastery of basic English language skills. Specific Competence 1.2. Weekly allocation: 7 periods.', display_order = 2,
        period_allocation = 40, assessment_criteria = 'Quantities are expressed using appropriate words',
        source_page = 17, is_published = true
    where id = v_topic_id;
  end if;

  -- Delete existing subtopics for clean re-insertion of verified activities
  delete from public.subtopics where topic_id = v_topic_id;

  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Talk about quantity using appropriate words (e.g., some, many, any, much)', 'Charts, texts and audio/audiovisual materials with grammar and vocabulary', 'Explanation: Guide the pupils through talking about quantities of things using some, many, any, much. Role play: Guide the pupils through playing the roles of sellers and buyers in shopping using the expressions ''How much is it'' and ''How many do we want/need''.', 'Quantities are expressed using appropriate words',
    10, 1, 17, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Express location using appropriate prepositions of place and time (target: in, at, on, under, inside, outside, over, near)', 'Charts, texts and audio/audiovisual materials with grammar and vocabulary', 'Games: Use games like ''Simon Says'' to guide the pupils through responding to commands with prepositions. Preposition race: Ask the pupils to follow instructions that include prepositions of place and time.', 'Location is expressed using appropriate prepositions of place and time',
    10, 2, 17, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(c) Express past events (target: simple past tense, past continuous tense)', 'Charts, texts and audio/audiovisual materials with grammar and vocabulary', 'Game: Ask the pupils to change irregular verbs in present tense into past tense.', 'Past events are expressed correctly',
    10, 3, 17, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(d) Use conjunctions in oral and written contexts (target: so, because)', 'Charts, texts and audio/audiovisual materials with grammar and vocabulary', 'Link-Up Game: Guide the pupils in pairs through writing a sentence at the same time using so and because. ''SLAP-IT'' Game: Guide the pupils through getting the correct word and gaining a point for their group in the game.', 'Conjunctions are well used in oral and written contexts',
    10, 4, 17, true
  );

  -- Specific Competence 2.1: Respond appropriately in a familiar communicative context
  v_topic_id := null;
  select id into v_topic_id from public.topics
  where subject_id = v_subject_id and competency_code = '2.1';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Respond appropriately in a familiar communicative context', 'Main Competence 2.0: Comprehend oral and written information. Specific Competence 2.1. Weekly allocation: 7 periods.', 3, true,
      '2.1', 42, 'Simple dialogues are produced on school, market and home contexts', 19
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Respond appropriately in a familiar communicative context', summary = 'Main Competence 2.0: Comprehend oral and written information. Specific Competence 2.1. Weekly allocation: 7 periods.', display_order = 3,
        period_allocation = 42, assessment_criteria = 'Simple dialogues are produced on school, market and home contexts',
        source_page = 19, is_published = true
    where id = v_topic_id;
  end if;

  -- Delete existing subtopics for clean re-insertion of verified activities
  delete from public.subtopics where topic_id = v_topic_id;

  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Participate in simple dialogues about school, market and home contexts', 'Wallcharts, texts and audio/audiovisual materials with communicative contexts', 'Dialogue: Use a dialogue with the appropriate vocabulary for market and home. Roleplay: Guide the pupils through role-playing a teacher-pupil conversation on a particular topic.', 'Simple dialogues are produced on school, market and home contexts',
    42, 1, 19, true
  );

  -- Specific Competence 2.2: Read appropriately a variety of simple texts
  v_topic_id := null;
  select id into v_topic_id from public.topics
  where subject_id = v_subject_id and competency_code = '2.2';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Read appropriately a variety of simple texts', 'Main Competence 2.0: Comprehend oral and written information. Specific Competence 2.2. Weekly allocation: 7 periods.', 4, true,
      '2.2', 30, 'Grade-level simple texts are read aloud with appropriate intonation', 20
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Read appropriately a variety of simple texts', summary = 'Main Competence 2.0: Comprehend oral and written information. Specific Competence 2.2. Weekly allocation: 7 periods.', display_order = 4,
        period_allocation = 30, assessment_criteria = 'Grade-level simple texts are read aloud with appropriate intonation',
        source_page = 20, is_published = true
    where id = v_topic_id;
  end if;

  -- Delete existing subtopics for clean re-insertion of verified activities
  delete from public.subtopics where topic_id = v_topic_id;

  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Read aloud grade-level simple texts with appropriate intonation', 'Simple texts with a variety of topics', 'Demonstration: Read aloud, model, and verbalize the words in the text. Reader''s Theatre: Assign the pupils in groups to take turns in reading their scripts with appropriate intonation.', 'Grade-level simple texts are read aloud with appropriate intonation',
    15, 1, 20, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Read grade-level simple texts of different natures fluently', 'Simple texts with a variety of topics', 'Modelling: Reading simple texts and ask the pupils to read in groups.', 'Grade-level simple texts of different natures are read fluently',
    15, 2, 20, true
  );

  -- Specific Competence 3.1: Demonstrate knowledge of the basic features of spoken language
  v_topic_id := null;
  select id into v_topic_id from public.topics
  where subject_id = v_subject_id and competency_code = '3.1';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Demonstrate knowledge of the basic features of spoken language', 'Main Competence 3.0: Communicate effectively in different contexts. Specific Competence 3.1. Weekly allocation: 7 periods.', 5, true,
      '3.1', 35, 'Words with the same sound are pronounced correctly', 21
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Demonstrate knowledge of the basic features of spoken language', summary = 'Main Competence 3.0: Communicate effectively in different contexts. Specific Competence 3.1. Weekly allocation: 7 periods.', display_order = 5,
        period_allocation = 35, assessment_criteria = 'Words with the same sound are pronounced correctly',
        source_page = 21, is_published = true
    where id = v_topic_id;
  end if;

  -- Delete existing subtopics for clean re-insertion of verified activities
  delete from public.subtopics where topic_id = v_topic_id;

  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Pronounce words with similar sounds (e.g., see/sea, by/bye/buy, right/write)', 'Wallcharts, texts and audio/audiovisual materials with features of spoken language', 'Listen and Repeat: Pronounce a word and ask your pupils to pronounce it after you. Tongue twisters: Guide the pupils through reciting tongue twisters with the correct pronunciation.', 'Words with the same sound are pronounced correctly',
    12, 1, 21, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Convey simple ideas using words with similar sounds', 'Wallcharts, texts and audio/audiovisual materials with features of spoken language', 'Modelling: Construct complete and correct sentences with two words with the same sound. Discussion: Guide the pupils through discussing a particular topic.', 'Simple ideas are conveyed using words with the same sound',
    12, 2, 21, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(c) Use words with opposite meanings in spoken contexts', 'Wallcharts, texts and audio/audiovisual materials with features of spoken language', 'Brainstorming: Lead the pupils in groups to compose sentences using the antonyms of given words. Matching: Guide the pupils through matching words with their antonyms. Complete the list: Assign the pupils to complete the column of antonyms for each word provided in another column. Memory games: Mix words and their antonyms and ask the pupils to match them.', 'Words with opposite meanings are used in spoken contexts',
    11, 3, 21, true
  );

  -- Specific Competence 3.2: Produce short written messages using appropriate grammar and vocabulary
  v_topic_id := null;
  select id into v_topic_id from public.topics
  where subject_id = v_subject_id and competency_code = '3.2';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Produce short written messages using appropriate grammar and vocabulary', 'Main Competence 3.0: Communicate effectively in different contexts. Specific Competence 3.2. Weekly allocation: 7 periods.', 6, true,
      '3.2', 30, 'The form and content of wishes and messages are identified', 23
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Produce short written messages using appropriate grammar and vocabulary', summary = 'Main Competence 3.0: Communicate effectively in different contexts. Specific Competence 3.2. Weekly allocation: 7 periods.', display_order = 6,
        period_allocation = 30, assessment_criteria = 'The form and content of wishes and messages are identified',
        source_page = 23, is_published = true
    where id = v_topic_id;
  end if;

  -- Delete existing subtopics for clean re-insertion of verified activities
  delete from public.subtopics where topic_id = v_topic_id;

  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Identify the form and content of wishes and messages', 'Realia, word lists, charts, calendars, cards and audio/audiovisual materials with appropriate vocabulary', 'Task-based learning: Guide the pupils through identifying the form and content of written messages from a sample of cards.', 'The form and content of wishes and messages are identified',
    10, 1, 23, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Write wishes and messages to parents, teachers and friends', 'Realia, word lists, charts, calendars, cards and audio/audiovisual materials with appropriate vocabulary', 'Guided writing: Guide the pupils through writing their wishes in groups. Games: Guide the pupils through using the ''Association game'' to write messages to parents, teachers and friends.', 'Wishes and messages are written to parents, teachers and friends correctly',
    10, 2, 23, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(c) Prepare a schedule of daily routines', 'Realia, word lists, charts, calendars, cards and audio/audiovisual materials with appropriate vocabulary', 'Match up: Guide the pupils through matching different times of the day with their daily routine. Composing: Guide the pupils through composing their schedules for daily routines.', 'Schedules of daily routines are prepared correctly',
    10, 3, 23, true
  );

  -- Specific Competence 3.3: Demonstrate basic skills in creative writing
  v_topic_id := null;
  select id into v_topic_id from public.topics
  where subject_id = v_subject_id and competency_code = '3.3';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Demonstrate basic skills in creative writing', 'Main Competence 3.0: Communicate effectively in different contexts. Specific Competence 3.3. Weekly allocation: 7 periods.', 7, true,
      '3.3', 35, 'Simple sentences are written using visual/audiovisual stimuli', 24
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Demonstrate basic skills in creative writing', summary = 'Main Competence 3.0: Communicate effectively in different contexts. Specific Competence 3.3. Weekly allocation: 7 periods.', display_order = 7,
        period_allocation = 35, assessment_criteria = 'Simple sentences are written using visual/audiovisual stimuli',
        source_page = 24, is_published = true
    where id = v_topic_id;
  end if;

  -- Delete existing subtopics for clean re-insertion of verified activities
  delete from public.subtopics where topic_id = v_topic_id;

  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Write simple sentences using visual/audiovisual stimuli (e.g., pictures, charts, diagrams)', 'Picture, charts, diagrams and simple texts with a variety of issues', 'Pictures: Use pictures to guide the pupils through describing and writing sentences. Mix and fix sentences: Guide the pupils through constructing sentences by re-arranging mixed parts of sentences. What''s missing? Guide the pupils through identifying the skipped parts or sentences.', 'Simple sentences are written using visual/audiovisual stimuli',
    18, 1, 24, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Write simple guided paragraphs using appropriate conjunctions and punctuation marks (target: and, but, comma, full stop, question marks)', 'Picture, charts, diagrams and simple texts with a variety of issues', 'Brainstorming: Ask the pupils to brainstorm on a chosen topic. Hook-On Sentences: Guide the pupils to write simple guided paragraphs by hooking one sentence to another.', 'Simple guided paragraphs are written using appropriate conjunctions and punctuation marks',
    17, 2, 24, true
  );

end $$;

-- ============================================================================
-- Standard V (STANDARD_5): 224 Periods, 6 Periods/Week
-- ============================================================================
do $$
declare
  v_subject_id uuid;
  v_topic_id uuid;
begin
  -- Subject: Standard V
  v_subject_id := null;
  select id into v_subject_id from public.subjects
  where country_code = 'TZ' and curriculum_id = '20000000-0000-0000-0000-000000000002' and code = 'tie-pri-english-standard5' and grade_id = '75e4ca53-91c0-4d22-a23f-5854272817d8';

  if v_subject_id is null then
    insert into public.subjects (
      country_code, curriculum_id, education_level_id, grade_id,
      code, name, official_name, description, display_order, is_published, classification, language
    ) values (
      'TZ', '20000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000010', '75e4ca53-91c0-4d22-a23f-5854272817d8',
      'tie-pri-english-standard5', 'English Language', 'English Language Syllabus for Primary Education — Standard V', 'Developing English language competencies for Standard V (224 periods, 6 periods/week): listening, speaking, reading fluency, functional grammar, and writing as prescribed by TIE 2023 syllabus.', 3, true, 'compulsory', 'en'
    ) returning id into v_subject_id;
  else
    update public.subjects
    set name = 'English Language', official_name = 'English Language Syllabus for Primary Education — Standard V', description = 'Developing English language competencies for Standard V (224 periods, 6 periods/week): listening, speaking, reading fluency, functional grammar, and writing as prescribed by TIE 2023 syllabus.',
        classification = 'compulsory', language = 'en', is_published = true, display_order = 3
    where id = v_subject_id;
  end if;

  -- Specific Competence 1.1: Develop vocabulary by relating words with objects in the environment
  v_topic_id := null;
  select id into v_topic_id from public.topics
  where subject_id = v_subject_id and competency_code = '1.1';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Develop vocabulary by relating words with objects in the environment', 'Main Competence 1.0: Demonstrate mastery of basic English language skills. Specific Competence 1.1. Weekly allocation: 6 periods.', 1, true,
      '1.1', 22, 'Synonyms and antonyms of the targeted words are found in different texts', 26
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Develop vocabulary by relating words with objects in the environment', summary = 'Main Competence 1.0: Demonstrate mastery of basic English language skills. Specific Competence 1.1. Weekly allocation: 6 periods.', display_order = 1,
        period_allocation = 22, assessment_criteria = 'Synonyms and antonyms of the targeted words are found in different texts',
        source_page = 26, is_published = true
    where id = v_topic_id;
  end if;

  -- Delete existing subtopics for clean re-insertion of verified activities
  delete from public.subtopics where topic_id = v_topic_id;

  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Find synonyms and antonyms of targeted words in different texts', 'Realia, word lists, charts and audio/audiovisual materials with environmental vocabulary', 'Matching: Mix the sticky notes with pairs of synonyms and antonyms for pupils to match. Word Pairs Game: Give the pupils pairs of words and let them say whether they are synonyms or antonyms. Rewriting History: Guide the pupils through picking a paragraph on social issues and rewriting sentences using synonyms.', 'Synonyms and antonyms of the targeted words are found in different texts',
    8, 1, 26, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Solve word puzzles from various media', 'Realia, word lists, charts and audio/audiovisual materials with environmental vocabulary', 'Modelling: Select a simple word puzzle and demonstrate to the pupils how to do the puzzle. Collaborative: Select a simple word puzzle and solve it with the pupils.', 'Word puzzles from various media are solved',
    7, 2, 26, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(c) Construct short passages using vocabulary referring to objects found in different settings', 'Realia, word lists, charts and audio/audiovisual materials with environmental vocabulary', 'Sing or rhyme it: Guide the pupils through creating a short song or poem that includes chosen words. Use song/poem to write: Guide the pupils through writing a short passage based on a song or poem.', 'Short passages are constructed using vocabulary referring to objects found in different settings',
    7, 3, 26, true
  );

  -- Specific Competence 1.2: Use appropriate grammar and vocabulary both orally and in writing
  v_topic_id := null;
  select id into v_topic_id from public.topics
  where subject_id = v_subject_id and competency_code = '1.2';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Use appropriate grammar and vocabulary both orally and in writing', 'Main Competence 1.0: Demonstrate mastery of basic English language skills. Specific Competence 1.2. Weekly allocation: 6 periods.', 2, true,
      '1.2', 54, 'Things are compared based on size, quality and quantity', 27
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Use appropriate grammar and vocabulary both orally and in writing', summary = 'Main Competence 1.0: Demonstrate mastery of basic English language skills. Specific Competence 1.2. Weekly allocation: 6 periods.', display_order = 2,
        period_allocation = 54, assessment_criteria = 'Things are compared based on size, quality and quantity',
        source_page = 27, is_published = true
    where id = v_topic_id;
  end if;

  -- Delete existing subtopics for clean re-insertion of verified activities
  delete from public.subtopics where topic_id = v_topic_id;

  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Compare things based on size, quality and quantity (e.g., big-bigger-biggest, much-more-most)', 'Charts, texts and audio/audiovisual materials with grammar and vocabulary', 'Defining concept: Define an adjective and ask the pupils to give examples. Brainstorming: Ask the pupils about different things they see in terms of size, quality and quantity. Word chart: Provide the pupils with an adjective chart. Game: Fill in the blanks: Guide the pupils through guessing missing comparative adjectives in sentences. Observation: Guide the pupils through describing objects they see in terms of sizes, quality and quantity.', 'Things are compared based on size, quality and quantity',
    9, 1, 27, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Express location using appropriate prepositions of direction (target: towards, between, beside, from, into, onto, through, across)', 'Charts, texts and audio/audiovisual materials with grammar and vocabulary', 'Descriptive passage: Guide the pupils through circling the prepositions in the passage. ''Do As I Say'' Game: Guide the pupils through using commands with prepositions to move into different positions. The List Challenger: Guide the pupils through creating sentences using the given prepositions.', 'Location is expressed using appropriate prepositions of direction',
    9, 2, 27, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(c) Express possession using adjectives and pronouns (target: my, mine, yours, his, her, hers, their, theirs)', 'Charts, texts and audio/audiovisual materials with grammar and vocabulary', 'Songs: Guide the pupils through singing relevant songs with adjectives and pronouns. Games: Use Stop me drills and Hot-chair games to guide the pupils through expressing adjectives and pronouns.', 'Possessions are expressed using adjectives and pronouns',
    9, 3, 27, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(d) Express completed and unfinished actions (structure: present perfect, past perfect tense)', 'Charts, texts and audio/audiovisual materials with grammar and vocabulary', 'Dialogue: Prepare a dialogue using present perfect and past perfect tenses and let the pupils practice it. I know What You Will Say Game: Lead the pupils in groups to complete questions using the present perfect or past simple.', 'Completed and unfinished actions are expressed correctly',
    9, 4, 27, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(e) Use conjunctions in oral and written contexts (target: too... to, either... or, neither... nor)', 'Charts, texts and audio/audiovisual materials with grammar and vocabulary', 'Songs: Play recorded songs with conjunctions for pupils to identify and sing. Read and choose: Guide the pupils through reading sentences and choosing correct conjunctions. Sentence completion: Guide the pupils through completing sentences with missing conjunctions.', 'Conjunctions are used in oral and written contexts',
    9, 5, 27, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(f) Use active and passive voices in oral and written contexts', 'Charts, texts and audio/audiovisual materials with grammar and vocabulary', 'Matching: Provide active and passive voice sentences on cards for pupils to match. Rewriting: Guide the pupils through rewriting sentences from active to passive voice.', 'Active and passive voices are used in oral and written contexts',
    9, 6, 27, true
  );

  -- Specific Competence 2.1: Comprehend information presented orally
  v_topic_id := null;
  select id into v_topic_id from public.topics
  where subject_id = v_subject_id and competency_code = '2.1';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Comprehend information presented orally', 'Main Competence 2.0: Comprehend oral and written information. Specific Competence 2.1. Weekly allocation: 6 periods.', 3, true,
      '2.1', 30, 'Oral instructions from different contexts are followed', 31
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Comprehend information presented orally', summary = 'Main Competence 2.0: Comprehend oral and written information. Specific Competence 2.1. Weekly allocation: 6 periods.', display_order = 3,
        period_allocation = 30, assessment_criteria = 'Oral instructions from different contexts are followed',
        source_page = 31, is_published = true
    where id = v_topic_id;
  end if;

  -- Delete existing subtopics for clean re-insertion of verified activities
  delete from public.subtopics where topic_id = v_topic_id;

  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Follow oral instructions from different contexts (e.g., instructions on taking medicines, recipe, drawing, making things)', 'Charts, texts and audio/audiovisual materials with oral instructions', 'Role-play: Guide the pupils through role-playing scenarios with oral instructions (e.g., a doctor and a patient).', 'Oral instructions from different contexts are followed',
    6, 1, 31, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Listen to and record messages from different sources', 'Charts, texts and audio/audiovisual materials with oral instructions', 'Dictation: Dictate messages for the pupils to record. Group listening: Have the pupils listen to an audio message and take notes.', 'Messages from different sources are listened to and recorded',
    6, 2, 31, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(c) Identify major ideas from conversations in familiar contexts', 'Charts, texts and audio/audiovisual materials with oral instructions', 'Listening and summarizing: Have pupils listen to dialogues and extract key themes.', 'Major ideas from conversations in familiar contexts are identified',
    6, 3, 31, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(d) Summarise main ideas of a story presented orally', 'Charts, texts and audio/audiovisual materials with oral instructions', 'Oral retelling: Ask pupils to retell the story outline in 3-4 sentences.', 'Main ideas of a story presented orally are summarised',
    6, 4, 31, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(e) Retell oral stories in logical sequence', 'Charts, texts and audio/audiovisual materials with oral instructions', 'Timeline storytelling: Have pupils use sequential connectors (first, then, next, finally) to recount a story.', 'Oral stories are retold in logical sequence',
    6, 5, 31, true
  );

  -- Specific Competence 2.2: Construct meaning from simple texts
  v_topic_id := null;
  select id into v_topic_id from public.topics
  where subject_id = v_subject_id and competency_code = '2.2';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Construct meaning from simple texts', 'Main Competence 2.0: Comprehend oral and written information. Specific Competence 2.2. Weekly allocation: 6 periods.', 4, true,
      '2.2', 22, 'Grade-level texts on cross-cutting issues are read and understood', 32
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Construct meaning from simple texts', summary = 'Main Competence 2.0: Comprehend oral and written information. Specific Competence 2.2. Weekly allocation: 6 periods.', display_order = 4,
        period_allocation = 22, assessment_criteria = 'Grade-level texts on cross-cutting issues are read and understood',
        source_page = 32, is_published = true
    where id = v_topic_id;
  end if;

  -- Delete existing subtopics for clean re-insertion of verified activities
  delete from public.subtopics where topic_id = v_topic_id;

  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Read grade-level texts on cross-cutting issues (e.g. corruption, gender, child rights, environment)', 'Texts, leaflets, posters on cross-cutting themes', 'Guided reading: Guide pupils through reading thematic texts and discussing core issues.', 'Grade-level texts on cross-cutting issues are read and understood',
    8, 1, 32, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Deduce meaning of unfamiliar words using contextual clues', 'Texts, leaflets, posters on cross-cutting themes', 'Context detective: Ask pupils to identify surrounding keywords that clarify unknown words.', 'Meaning of unfamiliar words is deduced using contextual clues',
    7, 2, 32, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(c) Summarise information presented in a text', 'Texts, leaflets, posters on cross-cutting themes', 'Paragraph reduction: Guide pupils to reduce a 3-paragraph text to main bullet points.', 'Information presented in a text is accurately summarised',
    7, 3, 32, true
  );

  -- Specific Competence 2.3: Respond appropriately in a familiar communicative context
  v_topic_id := null;
  select id into v_topic_id from public.topics
  where subject_id = v_subject_id and competency_code = '2.3';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Respond appropriately in a familiar communicative context', 'Main Competence 2.0: Comprehend oral and written information. Specific Competence 2.3. Weekly allocation: 6 periods.', 5, true,
      '2.3', 24, 'Main ideas from conversations in familiar contexts are identified', 33
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Respond appropriately in a familiar communicative context', summary = 'Main Competence 2.0: Comprehend oral and written information. Specific Competence 2.3. Weekly allocation: 6 periods.', display_order = 5,
        period_allocation = 24, assessment_criteria = 'Main ideas from conversations in familiar contexts are identified',
        source_page = 33, is_published = true
    where id = v_topic_id;
  end if;

  -- Delete existing subtopics for clean re-insertion of verified activities
  delete from public.subtopics where topic_id = v_topic_id;

  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Identify main ideas from conversations on familiar communicative contexts (e.g. at the post office, police station, bank)', 'Realia, mock banking slips, stamps, dialogue audio', 'Simulated field scenarios: Create mock post office and banking dialogues.', 'Main ideas from conversations in familiar contexts are identified',
    12, 1, 33, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Respond to questions based on conversations in familiar communicative contexts', 'Realia, mock banking slips, stamps, dialogue audio', 'Role-play Q&A: Pairs ask and answer realistic institutional questions.', 'Questions based on institutional conversations are responded to accurately',
    12, 2, 33, true
  );

  -- Specific Competence 2.4: Read appropriately a variety of simple texts
  v_topic_id := null;
  select id into v_topic_id from public.topics
  where subject_id = v_subject_id and competency_code = '2.4';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Read appropriately a variety of simple texts', 'Main Competence 2.0: Comprehend oral and written information. Specific Competence 2.4. Weekly allocation: 6 periods.', 6, true,
      '2.4', 24, 'Grade-level texts are read aloud with correct stress, intonation and pronunciation', 34
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Read appropriately a variety of simple texts', summary = 'Main Competence 2.0: Comprehend oral and written information. Specific Competence 2.4. Weekly allocation: 6 periods.', display_order = 6,
        period_allocation = 24, assessment_criteria = 'Grade-level texts are read aloud with correct stress, intonation and pronunciation',
        source_page = 34, is_published = true
    where id = v_topic_id;
  end if;

  -- Delete existing subtopics for clean re-insertion of verified activities
  delete from public.subtopics where topic_id = v_topic_id;

  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Read aloud grade-level texts with appropriate pronunciation and intonation', 'Graded readers, literary anthologies, audio recordings', 'Pronunciation drills and choral reading: Pupils practice rhythm and sentence stress.', 'Grade-level texts are read aloud with correct stress, intonation and pronunciation',
    12, 1, 34, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Reading silently for comprehension and pleasure', 'Graded readers, literary anthologies, audio recordings', 'Silent sustained reading (SSR): Allocate 15 minutes of independent quiet reading followed by a log entry.', 'Pupils demonstrate comprehension from silent reading through targeted checks',
    12, 2, 34, true
  );

  -- Specific Competence 3.1: Demonstrate knowledge of the basic features of spoken language
  v_topic_id := null;
  select id into v_topic_id from public.topics
  where subject_id = v_subject_id and competency_code = '3.1';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Demonstrate knowledge of the basic features of spoken language', 'Main Competence 3.0: Communicate effectively in different contexts. Specific Competence 3.1. Weekly allocation: 6 periods.', 7, true,
      '3.1', 34, 'Falling and rising intonation patterns are demonstrated correctly', 36
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Demonstrate knowledge of the basic features of spoken language', summary = 'Main Competence 3.0: Communicate effectively in different contexts. Specific Competence 3.1. Weekly allocation: 6 periods.', display_order = 7,
        period_allocation = 34, assessment_criteria = 'Falling and rising intonation patterns are demonstrated correctly',
        source_page = 36, is_published = true
    where id = v_topic_id;
  end if;

  -- Delete existing subtopics for clean re-insertion of verified activities
  delete from public.subtopics where topic_id = v_topic_id;

  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Practise falling and rising intonation in questions and statements', 'Audio clips, flashcards with punctuation pitch cues', 'Pitch graphing: Draw pitch arrows on the board to illustrate rising question pitch and falling statements.', 'Falling and rising intonation patterns are demonstrated correctly',
    12, 1, 36, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Practise word stress in compound and multi-syllable words', 'Audio clips, flashcards with punctuation pitch cues', 'Stress tapping: Tap desk loudly on accented syllable (e.g. DOC-tor, po-TATO).', 'Word stress is placed correctly on accented syllables',
    11, 2, 36, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(c) Use question tags in conversational contexts (e.g. isn''t it?, aren''t you?, didn''t they?)', 'Audio clips, flashcards with punctuation pitch cues', 'Tag completion games: Pupils complete partner prompts with matching auxiliary tag.', 'Question tags are used correctly in oral communication',
    11, 3, 36, true
  );

  -- Specific Competence 3.2: Produce short and basic oral messages with a logical structure and intelligible pronunciation
  v_topic_id := null;
  select id into v_topic_id from public.topics
  where subject_id = v_subject_id and competency_code = '3.2';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Produce short and basic oral messages with a logical structure and intelligible pronunciation', 'Main Competence 3.0: Communicate effectively in different contexts. Specific Competence 3.2. Weekly allocation: 6 periods.', 8, true,
      '3.2', 10, 'Statements that can be verified as true or false are clearly formulated', 37
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Produce short and basic oral messages with a logical structure and intelligible pronunciation', summary = 'Main Competence 3.0: Communicate effectively in different contexts. Specific Competence 3.2. Weekly allocation: 6 periods.', display_order = 8,
        period_allocation = 10, assessment_criteria = 'Statements that can be verified as true or false are clearly formulated',
        source_page = 37, is_published = true
    where id = v_topic_id;
  end if;

  -- Delete existing subtopics for clean re-insertion of verified activities
  delete from public.subtopics where topic_id = v_topic_id;

  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Make statements about objects and ideas that can be judged as true or false', 'Fact cards, picture scenes, science charts', 'Fact check game: Pupils give factual statements about geography and science for peers to evaluate.', 'Statements that can be verified as true or false are clearly formulated',
    5, 1, 37, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Present simple speeches about self and family members on familiar topics (e.g. my pet, my brother, birthday party, wedding)', 'Family photos, personal artifacts, cue cards', 'Show and tell: Pupils bring an object or photo and deliver a 2-minute structured oral presentation.', 'Simple speeches on familiar topics are delivered with logical flow and clear pronunciation',
    5, 2, 37, true
  );

  -- Specific Competence 3.3: Produce short written messages using appropriate grammar and vocabulary
  v_topic_id := null;
  select id into v_topic_id from public.topics
  where subject_id = v_subject_id and competency_code = '3.3';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Produce short written messages using appropriate grammar and vocabulary', 'Main Competence 3.0: Communicate effectively in different contexts. Specific Competence 3.3. Weekly allocation: 6 periods.', 9, true,
      '3.3', 20, 'Structural elements of notes of appreciation, gratitude and apology are identified', 38
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Produce short written messages using appropriate grammar and vocabulary', summary = 'Main Competence 3.0: Communicate effectively in different contexts. Specific Competence 3.3. Weekly allocation: 6 periods.', display_order = 9,
        period_allocation = 20, assessment_criteria = 'Structural elements of notes of appreciation, gratitude and apology are identified',
        source_page = 38, is_published = true
    where id = v_topic_id;
  end if;

  -- Delete existing subtopics for clean re-insertion of verified activities
  delete from public.subtopics where topic_id = v_topic_id;

  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Identify the form and content of appreciation, thanks and apology notes', 'Sample greeting cards, letter templates, envelopes', 'Text structural analysis: Examine realia samples of polite notes and identify salutation, reason, and closing.', 'Structural elements of notes of appreciation, gratitude and apology are identified',
    10, 1, 38, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Write appreciation, thanks and apology notes to teachers, friends and parents', 'Sample greeting cards, letter templates, envelopes', 'Guided letter drafting: Pupils draft personal thank-you notes for real school events.', 'Polite notes are drafted with appropriate tone, correct spelling and standard layout',
    10, 2, 38, true
  );

  -- Specific Competence 3.4: Demonstrate basic skills in creative writing
  v_topic_id := null;
  select id into v_topic_id from public.topics
  where subject_id = v_subject_id and competency_code = '3.4';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Demonstrate basic skills in creative writing', 'Main Competence 3.0: Communicate effectively in different contexts. Specific Competence 3.4. Weekly allocation: 6 periods.', 10, true,
      '3.4', 14, 'Personal journals are created and maintained with reflective entries', 40
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Demonstrate basic skills in creative writing', summary = 'Main Competence 3.0: Communicate effectively in different contexts. Specific Competence 3.4. Weekly allocation: 6 periods.', display_order = 10,
        period_allocation = 14, assessment_criteria = 'Personal journals are created and maintained with reflective entries',
        source_page = 40, is_published = true
    where id = v_topic_id;
  end if;

  -- Delete existing subtopics for clean re-insertion of verified activities
  delete from public.subtopics where topic_id = v_topic_id;

  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Create a journal to record inspiring things (at home, at school, from TV and radio programmes, etc.)', 'Journal notebooks, prompt cards, literary magazines', 'Personal diary keeping: Maintain a weekly reflective diary with prompt starters.', 'Personal journals are created and maintained with reflective entries',
    5, 1, 40, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Devise a topic for a poem from the ideas recorded in a journal', 'Journal notebooks, prompt cards, literary magazines', 'Mind mapping: Extract central emotional themes from journal entries into poetic titles.', 'Poetic themes and titles are generated from journal material',
    5, 2, 40, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(c) Use basic figures of speech (simile, metaphor, personification) to write a four-line stanza', 'Anthologies of children''s poetry, figurative language charts', 'Poetic devices workshop: Create comparative phrases using ''as... as'' and ''like'', building into a 4-line rhymed or unrhymed stanza.', 'A 4-line stanza incorporating similes, metaphors or personification is composed',
    4, 3, 40, true
  );

end $$;

-- ============================================================================
-- Standard VI (STANDARD_6): 150 Periods, 6 Periods/Week
-- ============================================================================
do $$
declare
  v_subject_id uuid;
  v_topic_id uuid;
begin
  -- Subject: Standard VI
  v_subject_id := null;
  select id into v_subject_id from public.subjects
  where country_code = 'TZ' and curriculum_id = '20000000-0000-0000-0000-000000000002' and code = 'tie-pri-english-standard6' and grade_id = 'd5942cbc-51b0-4031-b407-c632a8f2742d';

  if v_subject_id is null then
    insert into public.subjects (
      country_code, curriculum_id, education_level_id, grade_id,
      code, name, official_name, description, display_order, is_published, classification, language
    ) values (
      'TZ', '20000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000010', 'd5942cbc-51b0-4031-b407-c632a8f2742d',
      'tie-pri-english-standard6', 'English Language', 'English Language Syllabus for Primary Education — Standard VI', 'Developing English language competencies for Standard VI (150 periods, 6 periods/week): listening, speaking, reading fluency, functional grammar, and writing as prescribed by TIE 2023 syllabus.', 3, true, 'compulsory', 'en'
    ) returning id into v_subject_id;
  else
    update public.subjects
    set name = 'English Language', official_name = 'English Language Syllabus for Primary Education — Standard VI', description = 'Developing English language competencies for Standard VI (150 periods, 6 periods/week): listening, speaking, reading fluency, functional grammar, and writing as prescribed by TIE 2023 syllabus.',
        classification = 'compulsory', language = 'en', is_published = true, display_order = 3
    where id = v_subject_id;
  end if;

  -- Specific Competence 1.1: Develop vocabulary by relating words with objects in the environment
  v_topic_id := null;
  select id into v_topic_id from public.topics
  where subject_id = v_subject_id and competency_code = '1.1';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Develop vocabulary by relating words with objects in the environment', 'Main Competence 1.0: Demonstrate mastery of basic English language skills. Specific Competence 1.1. Weekly allocation: 6 periods.', 1, true,
      '1.1', 20, 'Dialogue is composed using vocabulary referring to objects found in different settings', 42
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Develop vocabulary by relating words with objects in the environment', summary = 'Main Competence 1.0: Demonstrate mastery of basic English language skills. Specific Competence 1.1. Weekly allocation: 6 periods.', display_order = 1,
        period_allocation = 20, assessment_criteria = 'Dialogue is composed using vocabulary referring to objects found in different settings',
        source_page = 42, is_published = true
    where id = v_topic_id;
  end if;

  -- Delete existing subtopics for clean re-insertion of verified activities
  delete from public.subtopics where topic_id = v_topic_id;

  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Compose a dialogue using vocabulary referring to objects found in different settings', 'Realia, environmental word lists, role-play props', 'Brainstorming and scriptwriting: Guide pupils through writing and dramatising realistic dialogues set in agricultural, airport, and trade environments.', 'Dialogue is composed using vocabulary referring to objects found in different settings',
    10, 1, 42, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Compose a story using vocabulary referring to objects found in different settings', 'Realia, environmental word lists, role-play props', 'Guided narrative composition: Pupils compose a cohesive short story integrating specialized contextual nouns.', 'A story is composed using vocabulary referring to objects found in different settings',
    10, 2, 42, true
  );

  -- Specific Competence 1.2: Use appropriate grammar and vocabulary both orally and in writing
  v_topic_id := null;
  select id into v_topic_id from public.topics
  where subject_id = v_subject_id and competency_code = '1.2';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Use appropriate grammar and vocabulary both orally and in writing', 'Main Competence 1.0: Demonstrate mastery of basic English language skills. Specific Competence 1.2. Weekly allocation: 6 periods.', 2, true,
      '1.2', 42, 'Nationalities are expressed accurately using proper descriptive adjectives', 44
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Use appropriate grammar and vocabulary both orally and in writing', summary = 'Main Competence 1.0: Demonstrate mastery of basic English language skills. Specific Competence 1.2. Weekly allocation: 6 periods.', display_order = 2,
        period_allocation = 42, assessment_criteria = 'Nationalities are expressed accurately using proper descriptive adjectives',
        source_page = 44, is_published = true
    where id = v_topic_id;
  end if;

  -- Delete existing subtopics for clean re-insertion of verified activities
  delete from public.subtopics where topic_id = v_topic_id;

  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Express nationalities using appropriate adjectives (e.g. Tanzanian, Japanese, Norwegian)', 'World maps, national flags, identity cards, travel documents', 'Country-to-nationality matching: World maps and flags used to practice proper adjective suffixes (-ian, -ese, -ish).', 'Nationalities are expressed accurately using proper descriptive adjectives',
    9, 1, 44, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Use relative pronouns in appropriate contexts (e.g., who, whose, whom)', 'Sentence strips, grammar substitution tables', 'Sentence combining: Merge two simple clauses into a complex sentence using relative pronouns.', 'Relative pronouns who, whose, and whom are used accurately in defining clauses',
    9, 2, 44, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(c) Express future actions (structure: will, shall, going to)', 'Calendars, career charts, weather forecasts', 'Future planning: Pupils write and talk about career aspirations and planned holiday schedules.', 'Future intentions and predictions are expressed using will, shall, and going to',
    8, 3, 44, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(d) Use conjunctions in oral and written contexts (target: yet, despite, in spite of, so... that)', 'Charts with conjunction matrices, reading texts', 'Contrastive conjunction drills: Construct complex sentences expressing concession and cause-effect.', 'Concessive and result conjunctions are used correctly in speech and writing',
    8, 4, 44, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(e) Express conditional situations (target: Conditional Type 1 & Type 2: if + present -> will; if + past -> would)', 'Conditional prompt cards, game boards', 'Hypothetical question chains: ''If you won a prize, what would you do?'' oral practice.', 'Conditional clauses type 1 and 2 are constructed with accurate verb forms',
    8, 5, 44, true
  );

  -- Specific Competence 2.1: Comprehend information presented orally
  v_topic_id := null;
  select id into v_topic_id from public.topics
  where subject_id = v_subject_id and competency_code = '2.1';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Comprehend information presented orally', 'Main Competence 2.0: Comprehend oral and written information. Specific Competence 2.1. Weekly allocation: 6 periods.', 3, true,
      '2.1', 18, 'Key information from broadcast media is accurately reported orally', 47
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Comprehend information presented orally', summary = 'Main Competence 2.0: Comprehend oral and written information. Specific Competence 2.1. Weekly allocation: 6 periods.', display_order = 3,
        period_allocation = 18, assessment_criteria = 'Key information from broadcast media is accurately reported orally',
        source_page = 47, is_published = true
    where id = v_topic_id;
  end if;

  -- Delete existing subtopics for clean re-insertion of verified activities
  delete from public.subtopics where topic_id = v_topic_id;

  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Report orally information from radio, TV and online broadcasts', 'Radio recordings, news transcripts, audio playback devices', 'Broadcast summary: Pupils listen to a simulated news broadcast and deliver an oral headline brief.', 'Key information from broadcast media is accurately reported orally',
    6, 1, 47, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Participate in conversations on contemporary social issues (e.g. climate change, digital safety, health)', 'Articles, posters on national environmental and health issues', 'Fishbowl discussions: Small groups discuss current national and global issues.', 'Pupils engage actively in discussions using substantiated points',
    6, 2, 47, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(c) Engage in oral presentations based on research or project findings', 'Project charts, survey question sheets', 'Mini-project defense: Present findings from a simple survey or school inquiry.', 'Oral presentations are delivered clearly with supporting arguments',
    6, 3, 47, true
  );

  -- Specific Competence 2.2: Construct meaning from simple texts
  v_topic_id := null;
  select id into v_topic_id from public.topics
  where subject_id = v_subject_id and competency_code = '2.2';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Construct meaning from simple texts', 'Main Competence 2.0: Comprehend oral and written information. Specific Competence 2.2. Weekly allocation: 6 periods.', 4, true,
      '2.2', 20, 'Figurative and idiomatic expressions are correctly interpreted in context', 49
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Construct meaning from simple texts', summary = 'Main Competence 2.0: Comprehend oral and written information. Specific Competence 2.2. Weekly allocation: 6 periods.', display_order = 4,
        period_allocation = 20, assessment_criteria = 'Figurative and idiomatic expressions are correctly interpreted in context',
        source_page = 49, is_published = true
    where id = v_topic_id;
  end if;

  -- Delete existing subtopics for clean re-insertion of verified activities
  delete from public.subtopics where topic_id = v_topic_id;

  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Interpret figurative and idiomatic language from a text (e.g. idioms, riddles, proverbs)', 'Dictionary of idioms, proverb collection cards', 'Idiom decoding: Match common English idioms and proverbs with their figurative meanings.', 'Figurative and idiomatic expressions are correctly interpreted in context',
    7, 1, 49, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Infer meaning from a text', 'Short mystery stories, allegorical passages', 'Reading between the lines: Deduce author attitude, unstated motives, and implied outcomes.', 'Implied meanings and inferences are correctly drawn from written texts',
    7, 2, 49, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(c) Relate the content of a text with real life', 'Narrative passages reflecting community life', 'Text-to-self / text-to-world connections: Discuss how characters'' dilemmas apply to local communities.', 'Textual themes are thoughtfully connected to real-life situations',
    6, 3, 49, true
  );

  -- Specific Competence 2.3: Respond appropriately in a familiar communicative context
  v_topic_id := null;
  select id into v_topic_id from public.topics
  where subject_id = v_subject_id and competency_code = '2.3';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Respond appropriately in a familiar communicative context', 'Main Competence 2.0: Comprehend oral and written information. Specific Competence 2.3. Weekly allocation: 6 periods.', 5, true,
      '2.3', 20, 'Logical, polite, and communicative conclusions are provided for conversations', 51
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Respond appropriately in a familiar communicative context', summary = 'Main Competence 2.0: Comprehend oral and written information. Specific Competence 2.3. Weekly allocation: 6 periods.', display_order = 5,
        period_allocation = 20, assessment_criteria = 'Logical, polite, and communicative conclusions are provided for conversations',
        source_page = 51, is_published = true
    where id = v_topic_id;
  end if;

  -- Delete existing subtopics for clean re-insertion of verified activities
  delete from public.subtopics where topic_id = v_topic_id;

  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Give an appropriate and logical conclusion to a conversation', 'Role-play transcripts, community interaction cards', 'Dialogue resolution: Provide truncated dialogue scripts for pupils to compose an effective conclusion.', 'Logical, polite, and communicative conclusions are provided for conversations',
    7, 1, 51, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Debate on topical issues (e.g. gender, entrepreneurship, corruption, education)', 'Debate guidelines, scorecards, topic briefs', 'Structured parliamentary debate: Proposition and opposition teams debate motions with timed speeches.', 'Arguments on topical motions are articulated persuasively and respectfully',
    7, 2, 51, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(c) Give appropriate responses to riddles', 'Traditional and modern English riddle anthologies', 'Riddle contest: Solve and compose creative riddles requiring wordplay and logic.', 'Riddles are decoded and solved using analytical language skills',
    6, 3, 51, true
  );

  -- Specific Competence 3.1: Demonstrate knowledge of the basic features of spoken language
  v_topic_id := null;
  select id into v_topic_id from public.topics
  where subject_id = v_subject_id and competency_code = '3.1';

  if v_topic_id is null then
    insert into public.topics (
      subject_id, title, summary, display_order, is_published,
      competency_code, period_allocation, assessment_criteria, source_page
    ) values (
      v_subject_id, 'Demonstrate knowledge of the basic features of spoken language', 'Main Competence 3.0: Communicate effectively in different contexts. Specific Competence 3.1. Weekly allocation: 6 periods.', 6, true,
      '3.1', 30, 'Vocal pitch, stress, and intonation accurately convey intended emotional feelings', 53
    ) returning id into v_topic_id;
  else
    update public.topics
    set title = 'Demonstrate knowledge of the basic features of spoken language', summary = 'Main Competence 3.0: Communicate effectively in different contexts. Specific Competence 3.1. Weekly allocation: 6 periods.', display_order = 6,
        period_allocation = 30, assessment_criteria = 'Vocal pitch, stress, and intonation accurately convey intended emotional feelings',
        source_page = 53, is_published = true
    where id = v_topic_id;
  end if;

  -- Delete existing subtopics for clean re-insertion of verified activities
  delete from public.subtopics where topic_id = v_topic_id;

  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(a) Express feelings using appropriate intonation patterns (e.g., surprise, shock, happiness, sadness)', 'Audio recordings, emoji prompt cards, theatre scripts', 'Emotion intonation drills: Speak identical sentences with varying pitch contours to reflect diverse emotional states.', 'Vocal pitch, stress, and intonation accurately convey intended emotional feelings',
    15, 1, 53, true
  );
  insert into public.subtopics (
    topic_id, title, description, learning_outcome, assessment_criteria,
    period_allocation, display_order, source_page, is_published
  ) values (
    v_topic_id, '(b) Use appropriate backchannels in conversations (e.g. so, well, right, uh-huh, wow, yeah, really)', 'Dialogue transcripts, conversational audio clips', 'Active listening simulations: Practice realistic conversational listening cues during peer dialogues.', 'Conversational backchannels are deployed naturally to sustain dialogue',
    15, 2, 53, true
  );

end $$;

commit;
