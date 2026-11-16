#!/usr/bin/env python3
"""
Generate Supabase SQL Migration for TIE English Language Primary Curriculum Remediation.
Ingests authoritatively verified Standards III, IV, V, VI from tie_english_primary_std3_6_verified.json.
Remediates the 4 framework-gap placeholder records.
"""

import json
import os

GRADE_UUIDS = {
    'STANDARD_3': '03705394-edb4-41c8-813d-30d5a37b9c2e',
    'STANDARD_4': 'deeb8105-49e8-45ff-83ac-97a85633cef2',
    'STANDARD_5': '75e4ca53-91c0-4d22-a23f-5854272817d8',
    'STANDARD_6': 'd5942cbc-51b0-4031-b407-c632a8f2742d',
}

CURRICULUM_ID = '20000000-0000-0000-0000-000000000002'
LEVEL_ID = '20000000-0000-0000-0000-000000000010'
COUNTRY_CODE = 'TZ'

def escape_sql(val):
    if val is None:
        return 'null'
    s = str(val).replace("'", "''")
    return f"'{s}'"

def distribute_periods(total, count):
    if count <= 0:
        return []
    base = total // count
    rem = total % count
    return [base + (1 if i < rem else 0) for i in range(count)]

def main():
    json_path = os.path.join(os.path.dirname(__file__), '../../data/curriculum/tz_extracted/tie_english_primary_std3_6_verified.json')
    with open(json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    sql_lines = []
    sql_lines.append("-- ============================================================================")
    sql_lines.append("-- LearnTZ — TIE English Language Primary Curriculum Remediation (Std III–VI)")
    sql_lines.append("-- Authoritative 2023 Competency-Based Syllabus Ingestion & Gap Remediation")
    sql_lines.append("-- Sourced from: data/curriculum/tz/sw-1727168466-ENGLISH Syllabus III-VI FINAL.pdf")
    sql_lines.append("-- ISBN: 978-9987-09-726-5 | 64 Pages | First Edition 2023 by TIE under MoEST")
    sql_lines.append("-- SHA-256: ae6b2f5d28b60bb77bd3bb2d7816535bacb671934cca4660705cfa937f9aacd2")
    sql_lines.append("-- ============================================================================\n")
    sql_lines.append("begin;\n")

    sql_lines.append("-- 1. Remediate the 4 Framework-Gap Placeholder Records from Migration 20261115000600")
    sql_lines.append("-- These 4 placeholder topics collapsed Standards III-VI into 4 artificial topics under umbrella 'tie-pri-english'.")
    sql_lines.append("do $$")
    sql_lines.append("declare")
    sql_lines.append("  v_gap_topic_ids uuid[];")
    sql_lines.append("begin")
    sql_lines.append("  select array_agg(id) into v_gap_topic_ids")
    sql_lines.append("  from public.topics")
    sql_lines.append("  where id in (")
    sql_lines.append("    '0db9d085-051c-4d2a-87d2-336c9868b3c3', -- Greetings & Self-Introduction")
    sql_lines.append("    '9b9a9125-7a95-4d86-9ead-71f69000655b', -- Simple Present and Continuous")
    sql_lines.append("    '19b4c5be-5438-47a4-9e99-0283a2b702d7', -- Giving Directions")
    sql_lines.append("    '5022a6ff-7d00-4e50-8920-d6e626a5a544'  -- Letter Writing & Composition")
    sql_lines.append("  );")
    sql_lines.append("")
    sql_lines.append("  if v_gap_topic_ids is not null and array_length(v_gap_topic_ids, 1) > 0 then")
    sql_lines.append("    -- Remove subtopics attached to gap topics")
    sql_lines.append("    delete from public.subtopics where topic_id = any(v_gap_topic_ids);")
    sql_lines.append("    -- Remove the gap topics")
    sql_lines.append("    delete from public.topics where id = any(v_gap_topic_ids);")
    sql_lines.append("  end if;")
    sql_lines.append("")
    sql_lines.append("  -- Unpublish/archive the legacy grade-less umbrella subject so only grade-scoped subjects display")
    sql_lines.append("  update public.subjects")
    sql_lines.append("  set is_published = false,")
    sql_lines.append("      description = 'Archived umbrella subject superseded by grade-specific subjects (Std III-VI).'")
    sql_lines.append("  where id = 'aad316b8-8d97-4d79-9f01-a1946886185d';")
    sql_lines.append("end $$;\n")

    sql_lines.append("-- 2. Update Curriculum Source rights clearance and verification status")
    sql_lines.append("update public.curriculum_sources")
    sql_lines.append("set verification_status = 'verified',")
    sql_lines.append("    usage_rights_status = 'permission_pending',")
    sql_lines.append("    usage_rights_reviewed_at = now(),")
    sql_lines.append("    usage_rights_note = 'Reference metadata (competence codes, titles, learning activities, period allocations) verified against official 2023 TIE syllabus. Commercial full-text publication permission is pending; LearnTZ educational content, lessons, and assessments are original proprietary creations.'")
    sql_lines.append("where id = 'e8301da6-b2e7-4540-990b-c939a0faa22d';\n")

    sql_lines.append("-- 3. Ingest Authoritative Grade-Scoped Subjects, Competence Topics, and Learning Activity Subtopics")

    for s_idx, standard_data in enumerate(data['standards']):
        std_name = standard_data['standard']
        grade_code = standard_data['grade_code']
        grade_uuid = GRADE_UUIDS[grade_code]
        std_suffix = grade_code.lower().replace('_', '')
        subj_code = f"tie-pri-english-{std_suffix}"
        std_num = std_name.split(' ')[-1]
        official_name = f"English Language Syllabus for Primary Education — Standard {std_num}"
        total_periods = standard_data['total_periods']
        weekly_periods = standard_data['weekly_periods']
        desc = f"Developing English language competencies for {std_name} ({total_periods} periods, {weekly_periods} periods/week): listening, speaking, reading fluency, functional grammar, and writing as prescribed by TIE 2023 syllabus."

        sql_lines.append(f"-- ============================================================================")
        sql_lines.append(f"-- {std_name} ({grade_code}): {total_periods} Periods, {weekly_periods} Periods/Week")
        sql_lines.append(f"-- ============================================================================")
        sql_lines.append("do $$")
        sql_lines.append("declare")
        sql_lines.append("  v_subject_id uuid;")
        sql_lines.append("  v_topic_id uuid;")
        sql_lines.append("begin")
        sql_lines.append(f"  -- Subject: {std_name}")
        sql_lines.append("  v_subject_id := null;")
        sql_lines.append("  select id into v_subject_id from public.subjects")
        sql_lines.append(f"  where country_code = '{COUNTRY_CODE}' and curriculum_id = '{CURRICULUM_ID}' and code = '{subj_code}' and grade_id = '{grade_uuid}';")
        sql_lines.append("")
        sql_lines.append("  if v_subject_id is null then")
        sql_lines.append("    insert into public.subjects (")
        sql_lines.append("      country_code, curriculum_id, education_level_id, grade_id,")
        sql_lines.append("      code, name, official_name, description, display_order, is_published, classification, language")
        sql_lines.append("    ) values (")
        sql_lines.append(f"      '{COUNTRY_CODE}', '{CURRICULUM_ID}', '{LEVEL_ID}', '{grade_uuid}',")
        sql_lines.append(f"      '{subj_code}', 'English Language', {escape_sql(official_name)}, {escape_sql(desc)}, 3, true, 'compulsory', 'en'")
        sql_lines.append("    ) returning id into v_subject_id;")
        sql_lines.append("  else")
        sql_lines.append("    update public.subjects")
        sql_lines.append(f"    set name = 'English Language', official_name = {escape_sql(official_name)}, description = {escape_sql(desc)},")
        sql_lines.append("        classification = 'compulsory', language = 'en', is_published = true, display_order = 3")
        sql_lines.append("    where id = v_subject_id;")
        sql_lines.append("  end if;")
        sql_lines.append("")

        topic_display_order = 0
        for mc in standard_data['main_competences']:
            main_code = mc['main_code']
            main_title = mc['main_title']

            for sc in mc['specific_competences']:
                topic_display_order += 1
                sc_code = sc['code']
                sc_title = sc['title']
                sc_periods = sc['periods']
                first_page = sc['source_pages'][0] if sc.get('source_pages') else 8
                summary = f"Main Competence {main_code}: {main_title}. Specific Competence {sc_code}. Weekly allocation: {weekly_periods} periods."
                
                # Derive assessment criteria for topic from its learning activities
                las = sc.get('learning_activities', [])
                topic_criteria = las[0]['assessment_criteria'] if las else 'Learners demonstrate required competence as evaluated against syllabus criteria.'

                sql_lines.append(f"  -- Specific Competence {sc_code}: {sc_title}")
                sql_lines.append("  v_topic_id := null;")
                sql_lines.append("  select id into v_topic_id from public.topics")
                sql_lines.append(f"  where subject_id = v_subject_id and competency_code = '{sc_code}';")
                sql_lines.append("")
                sql_lines.append("  if v_topic_id is null then")
                sql_lines.append("    insert into public.topics (")
                sql_lines.append("      subject_id, title, summary, display_order, is_published,")
                sql_lines.append("      competency_code, period_allocation, assessment_criteria, source_page")
                sql_lines.append("    ) values (")
                sql_lines.append(f"      v_subject_id, {escape_sql(sc_title)}, {escape_sql(summary)}, {topic_display_order}, true,")
                sql_lines.append(f"      '{sc_code}', {sc_periods}, {escape_sql(topic_criteria)}, {first_page}")
                sql_lines.append("    ) returning id into v_topic_id;")
                sql_lines.append("  else")
                sql_lines.append("    update public.topics")
                sql_lines.append(f"    set title = {escape_sql(sc_title)}, summary = {escape_sql(summary)}, display_order = {topic_display_order},")
                sql_lines.append(f"        period_allocation = {sc_periods}, assessment_criteria = {escape_sql(topic_criteria)},")
                sql_lines.append(f"        source_page = {first_page}, is_published = true")
                sql_lines.append("    where id = v_topic_id;")
                sql_lines.append("  end if;")
                sql_lines.append("")
                sql_lines.append(f"  -- Delete existing subtopics for clean re-insertion of verified activities")
                sql_lines.append("  delete from public.subtopics where topic_id = v_topic_id;")
                sql_lines.append("")

                subtopic_periods = distribute_periods(sc_periods, len(las))
                for la_idx, la in enumerate(las):
                    la_letter = la['letter']
                    la_act = la['activity']
                    subtopic_title = f"{la_letter} {la_act}"
                    subtopic_methods = la['methods']
                    subtopic_criteria = la['assessment_criteria']
                    subtopic_resources = la['resources']
                    la_periods = subtopic_periods[la_idx]
                    la_order = la_idx + 1

                    sql_lines.append(f"  insert into public.subtopics (")
                    sql_lines.append(f"    topic_id, title, description, learning_outcome, assessment_criteria,")
                    sql_lines.append(f"    period_allocation, display_order, source_page, is_published")
                    sql_lines.append(f"  ) values (")
                    sql_lines.append(f"    v_topic_id, {escape_sql(subtopic_title)}, {escape_sql(subtopic_resources)}, {escape_sql(subtopic_methods)}, {escape_sql(subtopic_criteria)},")
                    sql_lines.append(f"    {la_periods}, {la_order}, {first_page}, true")
                    sql_lines.append(f"  );")
                sql_lines.append("")

        sql_lines.append("end $$;\n")

    sql_lines.append("commit;\n")

    out_file = os.path.join(os.path.dirname(__file__), '../../supabase/migrations/20261116000200_tie_english_primary_curriculum_remediation.sql')
    with open(out_file, 'w', encoding='utf-8') as f:
        f.write('\n'.join(sql_lines))

    print(f"Generated migration script: {out_file}")
    print(f"Total lines: {len(sql_lines)}")

if __name__ == '__main__':
    main()
