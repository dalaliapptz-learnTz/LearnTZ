# LearnTZ Database Cleanup & Hardening Report

**Document ID:** `LTZ-CLEANUP-DB-001`  
**Database Host:** Remote Hosted Supabase PostgreSQL (`jmllsuohmllklzhmhiva.supabase.co`)  
**Executed Migration:** `20261116000400_production_environment_hardening.sql`  
**Audit Date:** 2026-11-16  
**Auditor:** Senior Supabase Database Administrator  
**Status:** COMPLETED & VERIFIED  

---

## 1. Executive Summary

This report documents the structural hardening and data sanitization applied to the LearnTZ production database. All synthetic, demo, and test records have been purged using a dependency-ordered, cascading deletion process.

Critical security functions were refactored to enforce a fail-safe production baseline, preventing automated or accidental demo data re-provisioning.

### Key Outcomes
- **Production-First Default:** `is_demo_environment()` now returns `false` by default unless explicitly overridden by `app.environment = 'development'` or `'test'`.
- **Zero Orphaned Records:** Cascading deletions executed cleanly across 12 relational tables without foreign-key constraint violations.
- **100% Protection of Genuine Users:** Super Admin & Parent account `bonimwangi243@gmail.com` was verified as active and unaffected.
- **Curriculum Catalog Sanitized:** Legacy dummy subjects (`tie-hisabati`, `tie-kiswahili`, `tie-sayansi`, `tie-primary-english`) and unverified umbrella containers were deactivated; authoritative TIE English Standards III–VI remain active and accessible.

---

## 2. Environment Hardening & Stored Procedure Lockdown

### 2.1 Refactored Environment Detection Function
Previously, `is_demo_environment()` defaulted to `development` when the PostgreSQL setting `app.environment` was not set, allowing demo scripts to run on unconfigured production instances.

**Remediated Function:**
```sql
create or replace function public.is_demo_environment()
returns boolean
language plpgsql
stable
as $$
declare
  v_env text;
begin
  -- Fail-safe default: treats null or unconfigured as 'production'
  v_env := lower(coalesce(current_setting('app.environment', true), 'production'));
  if v_env in ('development', 'test', 'local') then
    return true;
  end if;
  return false;
end;
$$;
```

### 2.2 Stored Procedure Restrictions
- **`provision_demo_data()`**: Refactored to reject execution in production with exception `42501` (*Demo account provisioning is strictly disabled in production*).
- **`reset_demo_data()`**: Refactored to enforce strict environment verification, preventing unintended data deletion in non-development environments.

---

## 3. Entity Census: Pre-Cleanup vs. Post-Cleanup Record Counts

| Database Table | Pre-Cleanup Total | Demo Records Purged | Post-Cleanup Total | Notes / Integrity Check |
| :--- | :---: | :---: | :---: | :--- |
| `auth.users` | 12 | 11 | **1** | Only `bonimwangi243@gmail.com` retained |
| `public.admin_profiles` | 7 | 6 | **1** | Real Super Admin profile retained |
| `public.admin_roles` | 7 | 6 | **1** | Super Admin RBAC role retained |
| `public.parent_accounts` | 6 | 5 | **1** | Real Parent account retained |
| `public.learners` | 10 | 10 | **0** | Clean empty slate for genuine registrations |
| `public.parent_learner_relationships` | 10 | 10 | **0** | All demo parent-child links purged |
| `public.learner_progress` | Multiple | All Demo | **0** | Demo progress records purged |
| `public.learner_topic_mastery` | Multiple | All Demo | **0** | Demo topic mastery scores purged |
| `public.learner_assessment_attempts` | Multiple | All Demo | **0** | Demo exam attempts purged |
| `public.learner_sessions` | Multiple | All Demo | **0** | Demo session tokens purged |
| `public.learner_activation_tokens` | Multiple | All Demo | **0** | Demo 6-digit PIN tokens purged |
| `public.parent_subscriptions` | 5 | 5 | **0** | Clean subscription registry |
| `public.payment_transactions` | 3 | 3 | **0** | Clean financial ledger |
| `public.onboarding_events` | 5 | 5 | **0** | Demo parent onboarding events purged |

---

## 4. Curriculum Catalog Status

```
================================================================================
CURRICULUM REPOSITORY STATUS (POST-CLEANUP)
================================================================================
Active Verified Subjects:     4 (TIE English Standards III–VI)
Active Verified Topics:       28 Topics (7 per standard)
Active Verified Subtopics:    81 Subtopics (Competences)
Active Verified Periods:      852 Annual Periods (213 per standard)
Archived Dummy Subjects:      4 (tie-hisabati, tie-kiswahili, tie-sayansi, tie-primary-english)
Archived Umbrella Containers: 7 (tie-pri-arts, tie-pri-chinese, tie-pri-geography,
                                 tie-pri-history, tie-pri-kiswahili,
                                 tie-pri-mathematics, tie-pri-science)
================================================================================
```

### Verified Active Subjects List
1. `tie-pri-english-standard3`: English Language (Standard 3, TIE 2023) — `is_active: true`
2. `tie-pri-english-standard4`: English Language (Standard 4, TIE 2023) — `is_active: true`
3. `tie-pri-english-standard5`: English Language (Standard 5, TIE 2023) — `is_active: true`
4. `tie-pri-english-standard6`: English Language (Standard 6, TIE 2023) — `is_active: true`

---

## 5. Security & Verification Checks

The following automated integrity assertions were executed at the end of the cleanup migration:
1. **Registered Super Admin Verification:** Passed (`bonimwangi243@gmail.com` confirmed present).
2. **Authoritative Topic Count Verification:** Passed (exactly 28 English topics present).
3. **Demo User Absence Verification:** Passed (0 records matching `%@demo.learntz.test` remain).
4. **Demo Learner Absence Verification:** Passed (0 records with `is_demo = true` remain).
