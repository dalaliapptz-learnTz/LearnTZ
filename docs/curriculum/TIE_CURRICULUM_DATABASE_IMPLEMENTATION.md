# LearnTZ — TIE Curriculum Database Implementation Report
**Database Platform:** PostgreSQL 15+ via Supabase Managed Infrastructure  
**Project Ref:** `jmllsuohmllklzhmhiva` (Production)  
**Schema Scope:** `public` schema curriculum hierarchy  
**Architectural Baseline:** Migration `20261116000200_tie_english_primary_curriculum_remediation.sql`  
**Status:** Implemented & Verified • STAGE E/G Deliverable  

---

## 1. Executive Database Summary

The LearnTZ curriculum database architecture implements a strict, multi-tenant, competency-first model. Following the successful remediation of English Language Standards III–VI, the database enforces **grade-scoped subjects**, ensuring that primary classes (Standard 1 through 6) display only their authorized curriculum structures without data bleeding or duplicate topics.

---

## 2. Core Migration Evolution

| Migration Name | Core Objectives & Impact |
| :--- | :--- |
| `20261111000200_stage2_learner_management.sql` | Established `education_levels` and `education_grades` with scoped uniqueness constraints. |
| `20261111000300_stage3_curriculum_foundation.sql` | Established `curriculum_authorities`, `curricula`, `curriculum_sources`, and review history. |
| `20261112001000_phase5_learner_content_delivery.sql` | Created base `subjects`, `topics`, `lessons`, and `quizzes`. |
| `20261113000200_phase2_dashboards_and_explorer.sql` | Added original `get_curriculum_explorer_tree` RPC. |
| `20261115000600_tie_primary_curriculum_ingestion.sql` | Introduced `subtopics` table; added `competency_code`, `period_allocation`, `assessment_criteria`, and `source_page` columns. (*Contained 4 placeholder gap records*). |
| **`20261116000200_tie_english_primary_curriculum_remediation.sql`** | **Authoritative Reference Migration:** Excised 4 gap records, archived umbrella subject, created 4 grade-scoped English subjects (`standard3`–`6`), ingested 28 topics and 81 subtopics. |

---

## 3. Grade Scoping Architecture

### The Problem in Legacy Ingestion
In legacy migration `20261115000600`, subjects were defined at the broad education level:
```sql
-- Legacy Flawed Approach
insert into public.subjects (..., grade_id, code, name)
values (..., null, 'tie-pri-english', 'English Language');
```
Because `grade_id` was `NULL`, topics from all four standards were attached to a single subject node. When querying by a specific standard in the Curriculum Explorer, the condition `(p_grade_id is null or s.grade_id is null or s.grade_id = p_grade_id)` caused all topics to display simultaneously for every grade.

### The Remediated Production Pattern
In production, subjects are strictly scoped to their respective `grade_id`:
```sql
-- Production Grade-Scoped Architecture
insert into public.subjects (
  country_code, curriculum_id, education_level_id, grade_id,
  code, name, official_name, description, display_order, is_published, classification, language
) values (
  'TZ', '20000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000010', '03705394-edb4-41c8-813d-30d5a37b9c2e',
  'tie-pri-english-standard3', 'English Language', 'English Language Syllabus for Primary Education — Standard III',
  'Developing English language competencies for Standard III (244 periods, 7 periods/week)...',
  3, true, 'compulsory', 'en'
);
```

---

## 4. Enhanced RPC: `get_curriculum_explorer_tree`

The primary delivery mechanism for the Flutter frontend is the high-performance RPC function `public.get_curriculum_explorer_tree`:

```sql
create or replace function public.get_curriculum_explorer_tree(
  p_country_code text,
  p_education_system_id uuid,
  p_education_level_id uuid default null,
  p_grade_id uuid default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_country text := upper(btrim(coalesce(p_country_code, '')));
  v_result jsonb := '[]'::jsonb;
begin
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'subject_id', s.id,
        'subject_name', s.name,
        'official_name', coalesce(s.official_name, s.name),
        'subject_code', s.code,
        'description', s.description,
        'classification', coalesce(s.classification, 'compulsory'),
        'language', coalesce(s.language, 'en'),
        'grade_id', s.grade_id,
        'display_order', s.display_order,
        'topics', coalesce(
          (
            select jsonb_agg(
              jsonb_build_object(
                'topic_id', t.id,
                'title', t.title,
                'summary', t.summary,
                'competency_code', t.competency_code,
                'period_allocation', t.period_allocation,
                'assessment_criteria', t.assessment_criteria,
                'source_page', t.source_page,
                'display_order', t.display_order,
                'subtopics', coalesce(
                  (
                    select jsonb_agg(
                      jsonb_build_object(
                        'subtopic_id', st.id,
                        'title', st.title,
                        'learning_outcome', st.learning_outcome,
                        'period_allocation', st.period_allocation,
                        'source_page', st.source_page,
                        'display_order', st.display_order
                      ) order by st.display_order
                    )
                    from public.subtopics st
                    where st.topic_id = t.id and st.is_published
                  ),
                  '[]'::jsonb
                ),
                'lessons', coalesce(
                  (
                    select jsonb_agg(
                      jsonb_build_object(
                        'lesson_id', l.id,
                        'title', l.title,
                        'estimated_minutes', l.estimated_minutes,
                        'is_free_preview', l.is_free_preview,
                        'display_order', l.display_order
                      ) order by l.display_order
                    )
                    from public.lessons l
                    where l.topic_id = t.id and l.is_published
                  ),
                  '[]'::jsonb
                )
              ) order by t.display_order
            )
            from public.topics t
            where t.subject_id = s.id and t.is_published
          ),
          '[]'::jsonb
        )
      ) order by s.display_order
    ),
    '[]'::jsonb
  )
  into v_result
  from public.subjects s
  where s.country_code = v_country
    and s.is_published
    and (p_education_level_id is null or s.education_level_id = p_education_level_id)
    and (p_grade_id is null or s.grade_id is null or s.grade_id = p_grade_id);

  return v_result;
end;
$$;
```

---

## 5. Security & Row Level Security (RLS) Policies

All curriculum tables enforce Row Level Security:

1. **`public.subjects`**:
   - `SELECT`: Permitted for `anon` and `authenticated` where `is_published = true`.
   - `ALL`: Restricted to `super_admin` or `curriculum_admin` with matching `country_code`.
2. **`public.topics`**:
   - `SELECT`: Permitted for `anon` and `authenticated` where `is_published = true`.
   - `ALL`: Restricted to authorized curriculum admins.
3. **`public.subtopics`**:
   - `SELECT`: Permitted for `anon` and `authenticated` where `is_published = true`.
   - `ALL`: Restricted to authorized curriculum admins.
4. **`public.curriculum_sources`**:
   - Storage and review restricted to verified educational staff to protect copyright boundaries.

---

## 6. Migration Execution Plan for Remaining Subjects

To migrate the remaining seven primary subjects to this verified pattern:
1. Author migration `20261116000300_tie_primary_all_subjects_remediation.sql`.
2. Clean up legacy umbrella subjects (`tie-pri-kiswahili`, `tie-pri-mathematics`, etc.).
3. Insert 4 grade-scoped subject records for each of:
   - Kiswahili (`tie-pri-kiswahili-standard3` to `standard6`)
   - Mathematics (`tie-pri-mathematics-standard3` to `standard6`)
   - Science (`tie-pri-science-standard3` to `standard6`)
   - Geography (`tie-pri-geography-standard3` to `standard6`)
   - History (`tie-pri-history-standard3` to `standard6`)
   - Arts & Sports (`tie-pri-arts-standard3` to `standard6`)
   - Chinese (`tie-pri-chinese-standard3` to `standard6`)
4. Populate topics and subtopics with official TIE 2023 matrix tables.
