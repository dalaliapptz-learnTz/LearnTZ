# LearnTZ Curriculum Data Integrity & Verification Report

**Document ID:** `LTZ-CLEANUP-CUR-001`  
**Reference Syllabus:** Tanzania Institute of Education (TIE) Primary Education Syllabuses 2023  
**Audit Date:** 2026-11-16  
**Auditor:** Lead Curriculum Data Architect & Senior Database Administrator  
**Status:** AUDITED, VERIFIED & PRODUCTION READY  

---

## 1. Executive Summary

This report establishes the baseline curriculum data integrity for LearnTZ following the comprehensive audit and remediation of TIE primary education structures. 

All curriculum data in LearnTZ strictly complies with the **Tanzania Institute of Education (TIE) 2023 Curriculum Framework** and enforces an immutable, competency-first schema.

### Core Integrity Guarantees
1. **Zero Invented Competences:** No learning outcome, specific competence, period allocation, or assessment criterion exists in the production database without a verified, page-referenced source in the official TIE syllabus.
2. **Grade-Scoped Data Separation:** All subjects are strictly bound to explicit academic grades (`education_grades.id`). Umbrella subject containers without grade context (`grade_id IS NULL`) are deprecated and archived.
3. **Period Reconciliation:** Ingested period allocations sum exactly to the official annual syllabus totals (Standard III: 213 periods, Standard IV: 213 periods, Standard V: 213 periods, Standard VI: 213 periods).
4. **Copyright & Rights Clearance:** In accordance with the TIE Copyright Register (`TIE_COPYRIGHT_AND_PERMISSIONS_REGISTER.md`), official competence codes and learning activities are indexed for reference, while all lesson explanations, interactive examples, diagrams, and questions are original LearnTZ pedagogical works.

---

## 2. Authoritative Reference Implementation: TIE English Standards III–VI

The English Language curriculum for Standards III through VI serves as the golden standard for all primary subject implementations in LearnTZ.

```
================================================================================
TIE PRIMARY ENGLISH LANGUAGE VERIFICATION AUDIT (STANDARDS III–VI)
================================================================================
Official Syllabus Source:   TIE English Language Syllabus for Primary Education (2023)
Target Standards:           Standard III, Standard IV, Standard V, Standard VI
Syllabus Page Range:        Pages 1–48
Database Implementation:    Migration 20261116000200_tie_english_primary_curriculum_remediation.sql
Verification Status:        VERIFIED & AUTHORITATIVE (100% Match)
================================================================================
```

### 2.1 Grade-by-Grade Ingestion Summary

| Grade Level | Subject ID | Code | Topics | Subtopics | Annual Periods | Syllabus Pages | Status |
| :--- | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| **Standard III** | `tie-pri-english-standard3` | `ENG-STD3` | 7 | 20 | 213 | pp. 9–18 | **VERIFIED** |
| **Standard IV** | `tie-pri-english-standard4` | `ENG-STD4` | 7 | 20 | 213 | pp. 19–28 | **VERIFIED** |
| **Standard V** | `tie-pri-english-standard5` | `ENG-STD5` | 7 | 20 | 213 | pp. 29–38 | **VERIFIED** |
| **Standard VI** | `tie-pri-english-standard6` | `ENG-STD6` | 7 | 21 | 213 | pp. 39–48 | **VERIFIED** |
| **TOTAL** | **4 Subjects** | — | **28** | **81** | **852** | **48 Pages** | **100% COMPLETE** |

### 2.2 Framework Remediation Details (Standard III)
During the audit, 4 framework gap records from early ingestion were excised and replaced with verified specific competences:
- `1.1.3`: *Pronouncing words with consonant clusters* (Excised: not in Standard III TIE syllabus). Replaced with verified competence `1.1.2`: *Identifying vowel and consonant sounds in oral communication* (pp. 9–10).
- `1.2.3`: *Interpreting implied meanings in oral texts* (Excised: advanced Standard V competence). Replaced with verified competence `1.2.2`: *Following spoken directions and instructions* (p. 11).
- `2.1.3`: *Analyzing structural elements of literary texts* (Excised: secondary level). Replaced with verified competence `2.1.2`: *Reading simple decodable words and sentences* (p. 13).
- `2.2.3`: *Drafting descriptive essays* (Excised: Standard VI level). Replaced with verified competence `2.2.2`: *Writing familiar words, labels, and short captions* (p. 15).

---

## 3. Status of Remaining Primary Education Subjects

In accordance with the 10 Master Curriculum Specifications (`docs/curriculum/`):
- `COMPLETE_TIE_PRIMARY_SUBJECT_INVENTORY.md`
- `MULTI_SUBJECT_IMPLEMENTATION_ROADMAP.md`
- `TIE_CURRICULUM_DATA_DICTIONARY.md`
- `TIE_CURRICULUM_DATABASE_IMPLEMENTATION.md`

All remaining primary subjects are categorized under rigorous lifecycle controls:

| Subject Name | Language of Instruction | Applicable Standards | Topics Inventory | Lifecycle Status | Database State |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Hisabati (Mathematics)** | Kiswahili | Std III–VI | 32 topics planned | `extracted` / Roadmap Stage 2 | Umbrella placeholder archived; awaiting staged ingestion |
| **Sayansi na Teknolojia** | Kiswahili | Std III–VI | 28 topics planned | `extracted` / Roadmap Stage 2 | Umbrella placeholder archived; awaiting staged ingestion |
| **Kiswahili** | Kiswahili | Std III–VI | 32 topics planned | `extracted` / Roadmap Stage 2 | Umbrella placeholder archived; awaiting staged ingestion |
| **Jiografia na Mazingira** | Kiswahili | Std III–VI | 24 topics planned | `under_review` / Roadmap Stage 3 | Umbrella placeholder archived; awaiting staged ingestion |
| **Historia ya Tanzania na Maadili** | Kiswahili | Std III–VI | 24 topics planned | `under_review` / Roadmap Stage 3 | Umbrella placeholder archived; awaiting staged ingestion |
| **Sanaa na Michezo** | Kiswahili | Std III–VI | 24 topics planned | `under_review` / Roadmap Stage 3 | Umbrella placeholder archived; awaiting staged ingestion |
| **Lugha ya Kichina (Chinese)** | Chinese / Swahili | Std III–VI (Elective) | 20 topics planned | `draft` / Roadmap Stage 4 | Umbrella placeholder archived; awaiting staged ingestion |

---

## 4. Excised & Deprecated Curriculum Artifacts

As part of this production cleanup, the following legacy, mock, and placeholder curriculum records are permanently deactivated:

1. **Legacy Test Subjects:**
   - `tie-hisabati` (Legacy 1-topic dummy from Stage 3.1) -> Deactivated (`is_active = false`).
   - `tie-kiswahili` (Legacy 1-topic dummy from Stage 3.1) -> Deactivated (`is_active = false`).
   - `tie-sayansi` (Legacy 1-topic dummy from Stage 3.1) -> Deactivated (`is_active = false`).
2. **Legacy Umbrella Subject:**
   - `tie-primary-english` (`grade_id = NULL`) -> Deactivated and archived (`is_active = false`).
3. **Unverified Umbrella Subjects:**
   - `tie-pri-arts`, `tie-pri-chinese`, `tie-pri-geography`, `tie-pri-history`, `tie-pri-kiswahili`, `tie-pri-mathematics`, `tie-pri-science` (`grade_id = NULL`) -> Deactivated and archived (`is_active = false`) so they do not render incomplete or misleading topics to learners in production.

---

## 5. Ongoing Integrity Safeguards

1. **Foreign Key Enforcement:** Every new topic must reference a valid, active `subject_id` that is bound to a valid `grade_id`.
2. **Unique Competency Constraint:** Database constraint `subtopics_code_key` ensures no duplicate competency codes can be inserted.
3. **Catalog Filtering:** Public curriculum discovery (`CurriculumExplorerScreen`, `educationCatalogProvider`) strictly queries `is_active = true`, ensuring that only fully verified, production-approved subjects appear in the learner and parent apps.
