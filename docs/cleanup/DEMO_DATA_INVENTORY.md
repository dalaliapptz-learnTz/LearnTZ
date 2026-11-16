# LearnTZ Demo Data Inventory & Classification Register

**Document ID:** `LTZ-CLEANUP-INV-001`  
**Target Environment:** LearnTZ Remote Production (`jmllsuohmllklzhmhiva.supabase.co`)  
**Audit Date:** 2026-11-16  
**Auditors:** Lead Software Architect, Senior Flutter Engineer, Supabase Database Administrator  
**Status:** COMPLETE & AUTHORITATIVE  

---

## 1. Executive Summary & Purpose

In preparation for the production deployment of LearnTZ, this comprehensive inventory identifies, classifies, and maps every demonstration, sample, mock, placeholder, and test entity currently residing in the database, application code, and project documentation.

This register serves as the authoritative baseline for the execution of the zero-data-loss, dependency-ordered removal manifest (`DEMO_DATA_REMOVAL_MANIFEST.md`).

### Absolute Safeguard Rules
1. **NEVER DELETE REAL USERS:** Real registered accounts, specifically Super Admin & Parent `bonimwangi243@gmail.com` (UUID: `558cb26f-d06e-45a7-9454-4570ab856f3f`), must remain 100% untouched.
2. **NEVER DELETE VERIFIED CURRICULUM:** The official TIE English Language Standards III–VI implementation (`tie-pri-english-standard3` through `standard6`, 28 topics, 81 subtopics, 852 periods) is verified against the 2023 syllabus and must remain fully intact.
3. **NEVER COMPROMISE INFRASTRUCTURE:** All RLS policies, RBAC schemas, country configurations, education systems, and academic calendars must be preserved.

---

## 2. Inventory of Demo Accounts (Database & Auth)

### 2.1 Demo Parent Accounts
All demo parent accounts were provisioned under the deterministic UUID range `d1000000-0000-0000-0000-000000000001` through `0005`, with email domain `@demo.learntz.test` and flag `is_demo = true`.

| Deterministic UUID | Email Address | Full Name | Country | Phone Number | Status | Demo Flag |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `d1000000-0000-0000-0000-000000000001` | `parent01@demo.learntz.test` | Juma Bakari | **TZ** | `+255711000001` | `COMPLETED` | `true` |
| `d1000000-0000-0000-0000-000000000002` | `parent02@demo.learntz.test` | Rehema Mwangi | **TZ** | `+255711000002` | `COMPLETED` | `true` |
| `d1000000-0000-0000-0000-000000000003` | `parent03@demo.learntz.test` | David Ochieng | **KE** | `+254711000003` | `COMPLETED` | `true` |
| `d1000000-0000-0000-0000-000000000004` | `parent04@demo.learntz.test` | Grace Mukasa | **UG** | `+256711000004` | `COMPLETED` | `true` |
| `d1000000-0000-0000-0000-000000000005` | `parent05@demo.learntz.test` | Jean Bosco | **RW** | `+250711000005` | `COMPLETED` | `true` |

*Underlying database tables storing these entities:*
- `auth.users` (5 records)
- `public.profiles` / `public.parent_accounts` (5 records)

---

### 2.2 Demo Learner Accounts
All demo learner profiles were created under deterministic UUID range `d2000000-0000-0000-0000-000000000001` through `0010`, linked to demo parents, with flag `is_demo = true`.

| Deterministic UUID | Learner Code | Full Name | Parent UUID | Country | Grade Level | Access Mode | Demo Flag |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `d2000000-0000-0000-0000-000000000001` | `TZ-LRN-0101` | Amani Bakari | `d1000000-...0001` | **TZ** | Standard 4 | `independent_device` | `true` |
| `d2000000-0000-0000-0000-000000000002` | `TZ-LRN-0201` | Baraka Mwangi | `d1000000-...0002` | **TZ** | Standard 2 | `parent_managed` | `true` |
| `d2000000-0000-0000-0000-000000000003` | `TZ-LRN-0202` | Neema Mwangi | `d1000000-...0002` | **TZ** | Standard 6 | `independent_device` | `true` |
| `d2000000-0000-0000-0000-000000000004` | `TZ-LRN-0203` | Juma Mwangi | `d1000000-...0002` | **TZ** | Form 2 | `parent_managed` | `true` |
| `d2000000-0000-0000-0000-000000000005` | `KE-LRN-0301` | Zawadi Ochieng | `d1000000-...0003` | **KE** | Grade 4 | `independent_device` | `true` |
| `d2000000-0000-0000-0000-000000000006` | `KE-LRN-0302` | Kamau Ochieng | `d1000000-...0003` | **KE** | Grade 7 | `parent_managed` | `true` |
| `d2000000-0000-0000-0000-000000000007` | `UG-LRN-0401` | Kato Mukasa | `d1000000-...0004` | **UG** | Primary 5 | `independent_device` | `true` |
| `d2000000-0000-0000-0000-000000000008` | `UG-LRN-0402` | Babirye Mukasa | `d1000000-...0004` | **UG** | Senior 2 | `parent_managed` | `true` |
| `d2000000-0000-0000-0000-000000000009` | `RW-LRN-0501` | Mugisha Bosco | `d1000000-...0005` | **RW** | Primary 4 | `independent_device` | `true` |
| `d2000000-0000-0000-0000-000000000010` | `RW-LRN-0502` | Keza Bosco | `d1000000-...0005` | **RW** | Senior 1 | `parent_managed` | `true` |

*Underlying database tables storing these entities:*
- `public.learners` (10 records)
- `public.parent_learner_relationships` (10 records)
- `public.learner_status_history` (10 records)
- `public.learner_profile_changes` (10 records)

---

### 2.3 Demo Administrator Accounts
All demo administrators were provisioned under deterministic UUID range `d3000000-0000-0000-0000-000000000001` through `0006`, with email domain `@demo.learntz.test` and flag `is_demo = true`.

| Deterministic UUID | Email Address | Full Name | Role Name | Jurisdiction | Demo Flag |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `d3000000-0000-0000-0000-000000000001` | `superadmin@demo.learntz.test` | Demo Super Admin | `SUPER_ADMIN` | Global (All Countries) | `true` |
| `d3000000-0000-0000-0000-000000000002` | `admin.tz@demo.learntz.test` | Demo Tanzania Admin | `COUNTRY_ADMIN` | Tanzania (TZ) | `true` |
| `d3000000-0000-0000-0000-000000000003` | `admin.ke@demo.learntz.test` | Demo Kenya Admin | `COUNTRY_ADMIN` | Kenya (KE) | `true` |
| `d3000000-0000-0000-0000-000000000004` | `admin.content@demo.learntz.test` | Demo Content Admin | `CONTENT_ADMIN` | Global (Curriculum Studio) | `true` |
| `d3000000-0000-0000-0000-000000000005` | `admin.finance@demo.learntz.test` | Demo Finance Admin | `FINANCE_ADMIN` | Global (Billing & Gateway) | `true` |
| `d3000000-0000-0000-0000-000000000006` | `admin.support@demo.learntz.test` | Demo Support Admin | `SUPPORT_ADMIN` | Global (Customer Service) | `true` |

*Underlying database tables storing these entities:*
- `auth.users` (6 records)
- `public.admin_profiles` (6 records)
- `public.admin_roles` (6 records)
- `public.admin_audit_logs` (initial provisioning audit logs)

---

## 3. Inventory of Demo Subscriptions & Transactions

Demo subscriptions were generated to test multi-currency billing and lifecycle states across all 4 countries.

| Subscription UUID | Parent Account UUID | Country | Currency | Plan / Billing Cycle | Status | Demo Flag |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `d4000000-0000-0000-0000-000000000001` | `d1000000-...0001` | **TZ** | TZS | Monthly Premium (TZS 15,000) | `active` | `true` |
| `d4000000-0000-0000-0000-000000000002` | `d1000000-...0002` | **TZ** | TZS | Annual Family Pass (TZS 150,000) | `active` | `true` |
| `d4000000-0000-0000-0000-000000000003` | `d1000000-...0003` | **KE** | KES | Monthly Premium (KES 1,000) | `pending` | `true` |
| `d4000000-0000-0000-0000-000000000004` | `d1000000-...0004` | **UG** | UGX | Monthly Premium (UGX 25,000) | `expired` | `true` |
| `d4000000-0000-0000-0000-000000000005` | `d1000000-...0005` | **RW** | RWF | Monthly Premium (RWF 8,000) | `cancelled` | `true` |

*Demo Payment Transactions:*
- Transaction 1: TZS 15,000 (M-Pesa, completed, `is_demo = true`)
- Transaction 2: TZS 150,000 (Airtel Money, completed, `is_demo = true`)
- Transaction 3: KES 1,000 (M-Pesa Kenya, pending, `is_demo = true`)

*Underlying database tables storing these entities:*
- `public.parent_subscriptions` (5 records)
- `public.payment_transactions` (3 records)

---

## 4. Inventory of Demo Learner Activity & Learning State

| Entity Table | Scope / Condition | Purpose | Removal Action |
| :--- | :--- | :--- | :--- |
| `public.learner_progress` | `learner_id` in demo learner IDs | Mock lesson progress & completions | DELETE CASCADE |
| `public.learner_topic_mastery` | `learner_id` in demo learner IDs | Mock topic competency scores | DELETE CASCADE |
| `public.learner_assessment_attempts` | `learner_id` in demo learner IDs | Mock quiz and exam submissions | DELETE CASCADE |
| `public.learner_sessions` | `learner_id` in demo learner IDs | Mock independent device sessions | DELETE CASCADE |
| `public.learner_activation_tokens` | `learner_id` in demo learner IDs | Mock 6-digit learner PIN tokens | DELETE CASCADE |
| `public.learner_recommendations` | `learner_id` in demo learner IDs | Mock AI study recommendations | DELETE CASCADE |
| `public.onboarding_events` | `parent_id` in demo parent IDs | Mock parent onboarding audit trail | DELETE CASCADE |

---

## 5. Inventory of Legacy & Placeholder Curriculum Data

| Subject ID | Grade Binding | Name | Topics Count | Classification | Remediation Action |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `tie-hisabati` | Standard 1 | Hisabati (Legacy Dummy) | 1 dummy topic | Placeholder from Stage 3.1 | Archive / Excised |
| `tie-kiswahili` | Standard 1 | Kiswahili (Legacy Dummy) | 1 dummy topic | Placeholder from Stage 3.1 | Archive / Excised |
| `tie-sayansi` | Standard 1 | Sayansi (Legacy Dummy) | 1 dummy topic | Placeholder from Stage 3.1 | Archive / Excised |
| `tie-primary-english` | Umbrella (`grade_id = NULL`) | English Language | 0 (Replaced) | Deprecated Umbrella | Archived (`is_active = false`) |
| `tie-pri-arts` | Umbrella (`grade_id = NULL`) | Sanaa na Michezo | 4 placeholder topics | Pre-extraction Placeholder | Flagged `under_review` / Inactive |
| `tie-pri-chinese` | Umbrella (`grade_id = NULL`) | Lugha ya Kichina | 4 placeholder topics | Pre-extraction Placeholder | Flagged `under_review` / Inactive |
| `tie-pri-geography` | Umbrella (`grade_id = NULL`) | Jiografia na Mazingira | 4 placeholder topics | Pre-extraction Placeholder | Flagged `under_review` / Inactive |
| `tie-pri-history` | Umbrella (`grade_id = NULL`) | Historia ya Tanzania | 4 placeholder topics | Pre-extraction Placeholder | Flagged `under_review` / Inactive |
| `tie-pri-kiswahili` | Umbrella (`grade_id = NULL`) | Kiswahili | 4 placeholder topics | Pre-extraction Placeholder | Flagged `under_review` / Inactive |
| `tie-pri-mathematics` | Umbrella (`grade_id = NULL`) | Hisabati | 4 placeholder topics | Pre-extraction Placeholder | Flagged `under_review` / Inactive |
| `tie-pri-science` | Umbrella (`grade_id = NULL`) | Sayansi na Teknolojia | 4 placeholder topics | Pre-extraction Placeholder | Flagged `under_review` / Inactive |

---

## 6. Inventory of Application Code Demo References

| File Location | Line Numbers | Identified Demo Element | Required Hardening Action |
| :--- | :--- | :--- | :--- |
| `lib/features/auth/auth_screens.dart` | Lines 81–83, 135–153 | Quick Demo sign-in buttons (`superadmin@demo.learntz.test`, `admin.content@demo.learntz.test`) | Already conditionally wrapped in `AppEnvironmentName.development`. Retain development guard. |
| `lib/features/admin/screens/super_admin_control_centre_screen.dart` | Lines 158–161, 846–1050 | Demo Accounts & Sandbox navigation item and UI module | Wrap navigation item and module in `ref.watch(appEnvironmentProvider).name == AppEnvironmentName.development`. |
| `lib/features/onboarding/screens/onboarding_otp_screen.dart` | Lines 360–445 | "Instant Verification (Testing Mode)" card and "Quick Fill Test Code (123456)" button | Wrap in `ref.watch(appEnvironmentProvider).name == AppEnvironmentName.development`. In production, render only authentic carrier verification. |
| `lib/features/onboarding/services/onboarding_repository.dart` | Lines 108–135 | `isDevCode` bypass logic accepting `123456`, `654321`, `000000`, `999999` | Strictly disable `isDevCode` bypass when not in `development` mode. |
| `docs/DEMO_ACCOUNTS.md` | Entire file | Documentation of demo credentials and sandbox usage | Retain in `docs/` marked explicitly as `[INTERNAL DEVELOPMENT ONLY]`. |

---

## 7. Whitelist of Protected Production Entities (DO NOT TOUCH)

The following entities have been audited and verified as genuine production assets and MUST NOT be modified or deleted during the cleanup operations:

```
================================================================================
PROTECTED ENTITY: REAL REGISTERED SUPER ADMINISTRATOR & PARENT
================================================================================
User ID:            558cb26f-d06e-45a7-9454-4570ab856f3f
Email:              bonimwangi243@gmail.com
Admin Profile ID:   0b83a709-9d90-469f-a1cd-e8c369644069
Parent Account ID:  8a10fe4e-3846-46a0-86bf-be70b5f55705
Status:             ACTIVE, VERIFIED
Roles:              SUPER_ADMIN, PARENT

================================================================================
PROTECTED ENTITY: VERIFIED TIE PRIMARY ENGLISH CURRICULUM (STANDARDS III–VI)
================================================================================
Standard 3 Subject: tie-pri-english-standard3 (7 topics, 20 subtopics, 213 periods)
Standard 4 Subject: tie-pri-english-standard4 (7 topics, 20 subtopics, 213 periods)
Standard 5 Subject: tie-pri-english-standard5 (7 topics, 20 subtopics, 213 periods)
Standard 6 Subject: tie-pri-english-standard6 (7 topics, 21 subtopics, 213 periods)
Total Curriculum:   4 Subjects, 28 Topics, 81 Subtopics, 852 Verified Periods
Integrity Source:   TIE Primary English Syllabus 2023 (Verified Authoritative Baseline)

================================================================================
PROTECTED INFRASTRUCTURE ENTITIES
================================================================================
Countries:          TZ (Tanzania), KE (Kenya), UG (Uganda), RW (Rwanda)
Education Systems:  Tanzania Basic, Kenya CBC, Uganda UNEB, Rwanda REB
Curricula:          TIE Primary, KICD CBC, UNEB Primary, REB CBC
Education Levels:   Primary, Lower Secondary / O-Level
Education Grades:   Standards 1–7, Grades 1–9, Primary 1–7
Commercial Plans:   All verified subscription plans and multi-currency configurations
Security & Auth:    All PostgreSQL RLS policies, RBAC roles, trigger functions
================================================================================
```
