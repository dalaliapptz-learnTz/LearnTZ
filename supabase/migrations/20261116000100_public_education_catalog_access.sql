-- ============================================================================
-- LearnTZ — Public Read Access for Education Catalog & Curriculum Explorer
-- Migration: 20261116000100_public_education_catalog_access.sql
--
-- Grants anonymous (unauthenticated) and authenticated users read access to
-- non-sensitive educational catalog metadata (education systems, curricula,
-- education levels, education grades, schools, calendars, and sources).
--
-- This resolves the "The request could not be completed. Please try again."
-- error when prospective parents or visitors browse the Curriculum Explorer
-- or Onboarding flows before signing in.
-- ============================================================================

-- 1. Grant SELECT privilege to anon and authenticated
grant select on public.education_systems to anon, authenticated;
grant select on public.curricula to anon, authenticated;
grant select on public.education_levels to anon, authenticated;
grant select on public.education_grades to anon, authenticated;
grant select on public.schools to anon, authenticated;
grant select on public.academic_calendars to anon, authenticated;
grant select on public.curriculum_sources to anon, authenticated;
grant select on public.curriculum_versions to anon, authenticated;

-- 2. RLS policies allowing public reading of enabled catalog reference data
drop policy if exists "Anyone can read enabled education systems" on public.education_systems;
create policy "Anyone can read enabled education systems"
  on public.education_systems
  for select
  using (is_enabled);

drop policy if exists "Anyone can read enabled curricula" on public.curricula;
create policy "Anyone can read enabled curricula"
  on public.curricula
  for select
  using (is_enabled);

drop policy if exists "Anyone can read enabled education levels" on public.education_levels;
create policy "Anyone can read enabled education levels"
  on public.education_levels
  for select
  using (is_enabled);

drop policy if exists "Anyone can read enabled education grades" on public.education_grades;
create policy "Anyone can read enabled education grades"
  on public.education_grades
  for select
  using (is_enabled);

drop policy if exists "Anyone can read enabled schools" on public.schools;
create policy "Anyone can read enabled schools"
  on public.schools
  for select
  using (is_enabled);

drop policy if exists "Anyone can read enabled academic calendars" on public.academic_calendars;
create policy "Anyone can read enabled academic calendars"
  on public.academic_calendars
  for select
  using (is_enabled);

drop policy if exists "Anyone can read curriculum sources" on public.curriculum_sources;
create policy "Anyone can read curriculum sources"
  on public.curriculum_sources
  for select
  using (true);

drop policy if exists "Anyone can read curriculum versions" on public.curriculum_versions;
create policy "Anyone can read curriculum versions"
  on public.curriculum_versions
  for select
  using (true);
