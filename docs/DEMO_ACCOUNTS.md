# LearnTZ — Demo Accounts, Test Users & Seed Data System

This document provides the reference guide, credentials, security policies, and maintenance procedures for the LearnTZ Demo Accounts and Sandbox Data Provisioning Engine.

---

## 1. Architectural Overview & Security Guarantees

LearnTZ implements an **integrated, production-isolated demo provisioning engine** built on standard PostgreSQL, Supabase Authentication (GoTrue), and Row Level Security (RLS).

### Non-Negotiable Guarantees
1. **Production Isolation**: Demo data operations (`provision_demo_data`, `reset_demo_data`) verify the execution environment via `public.is_demo_environment()`. If `app.environment = 'production'`, execution is aborted immediately with PostgreSQL error code `42501` (Insufficient Privilege).
2. **Deterministic Identities**: All demo records use hardcoded UUIDv4 namespaces (`d1000000-...` for parents, `d2000000-...` for learners, `d3000000-...` for admins, `e1000000-...` for subscriptions). This ensures full idempotency without primary key churn or foreign key fragmentation.
3. **Real Authentication**: Demo accounts are **not disconnected mock records**. Parents and Administrators use real `auth.users` identities with bcrypt passwords (`ParentDemo1234!` and `AdminDemo1234!`). Learners authenticate via `authenticate_learner_credential` using PIN `1234`.
4. **Analytics & KPI Isolation**: All demo records carry `is_demo = true`. Production KPI aggregation procedures (including `public.get_super_admin_control_centre_stats()`) explicitly filter `where not is_demo` to ensure business reporting remains unpolluted.

---

## 2. Demo Parent Accounts

| Parent Account | Email | Password | Country | Linked Learners | Subscription Scenario |
| :--- | :--- | :--- | :---: | :--- | :--- |
| **Demo Parent 01** | `parent01@demo.learntz.test` | `ParentDemo1234!` | **TZ** | Amani Bakari (Std 4) | Active Monthly Premium (TZS 15,000 / mo) |
| **Demo Parent 02** | `parent02@demo.learntz.test` | `ParentDemo1234!` | **TZ** | Baraka (Std 2), Neema (Std 6), Juma (Form 2) | Active Annual Pass (TZS 150,000 / yr) |
| **Demo Parent 03** | `parent03@demo.learntz.test` | `ParentDemo1234!` | **KE** | Zawadi (Grade 4), Kamau (Grade 7) | Pending Payment (KES 1,000 / mo) |
| **Demo Parent 04** | `parent04@demo.learntz.test` | `ParentDemo1234!` | **UG** | Kato (P5), Babirye (S2) | Expired Subscription (UGX 25,000 / mo) |
| **Demo Parent 05** | `parent05@demo.learntz.test` | `ParentDemo1234!` | **RW** | Mugisha (P4), Keza (S1) | Cancelled Subscription (RWF 8,000 / mo) |

---

## 3. Demo Learner Accounts

All demo learners use standard PIN **`1234`**.

| Learner Name | Learner Code | Username | PIN | Country | Grade / Level | Performance Persona | Access Mode | Linked Parent |
| :--- | :---: | :---: | :---: | :---: | :--- | :--- | :---: | :--- |
| **Amani Bakari** | `TZ-LRN-0101` | `amani_tz` | `1234` | **TZ** | Standard 4 (Primary) | **High Performing** (94% accuracy, mastered topics, Olympiad challenge) | Independent Device | Juma Bakari |
| **Baraka Mwangi** | `TZ-LRN-0201` | `baraka_tz` | `1234` | **TZ** | Standard 2 (Primary) | **Average** (72% accuracy, proficient, spaced repetition) | Parent-Managed | Rehema Mwangi |
| **Neema Mwangi** | `TZ-LRN-0202` | `neema_tz` | `1234` | **TZ** | Standard 6 (Primary) | **High Performing** (94% accuracy, mastered, Olympiad challenge) | Independent Device | Rehema Mwangi |
| **Juma Mwangi** | `TZ-LRN-0203` | `juma_tz` | `1234` | **TZ** | Form 2 (Secondary) | **Support Needed** (48% accuracy, remedial recommendations & flashcards) | Independent Device | Rehema Mwangi |
| **Zawadi Wanjiku** | `KE-LRN-0301` | `zawadi_ke` | `1234` | **KE** | Grade 4 (CBC Primary) | **Average** (72% accuracy, proficient, spaced review) | Parent-Managed | Grace Wanjiku |
| **Kamau Wanjiku** | `KE-LRN-0302` | `kamau_ke` | `1234` | **KE** | Grade 7 (CBC JSS) | **High Performing** (94% accuracy, mastered, Olympiad challenge) | Independent Device | Grace Wanjiku |
| **Kato Mukasa** | `UG-LRN-0401` | `kato_ug` | `1234` | **UG** | Primary 5 (NCDC) | **Support Needed** (48% accuracy, remedial recommendations) | Parent-Managed | Robert Mukasa |
| **Babirye Mukasa** | `UG-LRN-0402` | `babirye_ug` | `1234` | **UG** | Senior 2 (NCDC Sec) | **High Performing** (94% accuracy, mastered, Olympiad challenge) | Independent Device | Robert Mukasa |
| **Mugisha Habimana** | `RW-LRN-0501` | `mugisha_rw` | `1234` | **RW** | Primary 4 (REB CBC) | **Average** (72% accuracy, proficient, spaced repetition) | Parent-Managed | Jean Claude Habimana |
| **Keza Habimana** | `RW-LRN-0502` | `keza_rw` | `1234` | **RW** | Senior 1 (REB O-Level) | **Support Needed** (48% accuracy, remedial recommendations) | Independent Device | Jean Claude Habimana |

---

## 4. Demo Administrator Accounts

All demo administrators use password **`AdminDemo1234!`**.

| Administrator Role | Email | Password | Country Scope | Primary Capabilities & Dashboards |
| :--- | :--- | :--- | :---: | :--- |
| **Super Admin** | `superadmin@demo.learntz.test` | `AdminDemo1234!` | **Global** | Complete platform oversight, RBAC permissions, country management, audit trail, demo sandbox control |
| **Tanzania Admin** | `admin.tz@demo.learntz.test` | `AdminDemo1234!` | **TZ** | Tanzania curriculum, local school partners, mock exams, regional reports |
| **Kenya Admin** | `admin.ke@demo.learntz.test` | `AdminDemo1234!` | **KE** | Kenya CBC grades, junior secondary, KICD past papers, regional metrics |
| **Content Admin** | `admin.content@demo.learntz.test` | `AdminDemo1234!` | **Global** | Multi-country curriculum authoring, lesson publishing, review & approval workflows |
| **Finance Admin** | `admin.finance@demo.learntz.test` | `AdminDemo1234!` | **Global** | Multi-currency subscriptions, payment gateways (M-Pesa, Airtel Money, Tigo Pesa), transaction audits |
| **Support Admin** | `admin.support@demo.learntz.test` | `AdminDemo1234!` | **Global** | Customer support, ticket management, user verification, parent onboarding troubleshooting |

---

## 5. Provisioning & Reset Tooling

### CLI Provisioning
```bash
# Provision all demo accounts (idempotent, safe to rerun anytime)
python3 scripts/provision_demo_accounts.py

# View audit overview of all demo parents, learners, and administrators
python3 scripts/provision_demo_accounts.py --overview

# Reset activity and re-seed from scratch
python3 scripts/provision_demo_accounts.py --force-reset
```

### CLI Learner Activity Reset
```bash
# Reset progress, recommendations, and attempts for all demo learners without deleting accounts
python3 scripts/reset_demo_data.py --confirm
```

### SQL RPC Execution (via psql or Supabase Dashboard)
```sql
-- Provision demo data
SELECT public.provision_demo_data(false);

-- Reset demo learner activity
SELECT public.reset_demo_data();

-- Fetch demo accounts audit overview
SELECT public.get_demo_accounts_overview();
```
