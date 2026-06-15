-- ============================================================
-- Migration 002: Fix RLS infinite recursion
-- Run this in Supabase SQL Editor after migration 001
-- ============================================================

-- Create security definer function to check project membership
-- This bypasses RLS to prevent infinite recursion in policies
create or replace function public.is_project_member(project_id uuid)
returns boolean
language sql
security definer
stable
as $$
  select exists(
    select 1 from public.project_members
    where project_members.project_id = $1
      and project_members.user_id = auth.uid()
  );
$$;

-- Create security definer function to check if user has member role
create or replace function public.has_member_role(project_id uuid)
returns boolean
language sql
security definer
stable
as $$
  select exists(
    select 1 from public.project_members
    where project_members.project_id = $1
      and project_members.user_id = auth.uid()
      and project_members.role = 'member'
  );
$$;

-- ============================================================
-- Update policies for projects table
-- ============================================================

drop policy if exists "Select own or member projects" on public.projects;

create policy "Select own or member projects"
  on public.projects for select
  using (
    auth.uid() = owner_id
    or public.is_project_member(id)
  );

-- ============================================================
-- Update policies for project_members table
-- ============================================================

drop policy if exists "Select members of accessible projects" on public.project_members;

create policy "Select members of accessible projects"
  on public.project_members for select
  using (
    project_id in (
      select id from public.projects where auth.uid() = owner_id
    )
    or public.is_project_member(project_id)
  );

drop policy if exists "Owner can manage members" on public.project_members;

create policy "Owner can manage members"
  on public.project_members for insert
  with check (
    project_id in (select id from public.projects where auth.uid() = owner_id)
  );

drop policy if exists "Owner can update members" on public.project_members;

create policy "Owner can update members"
  on public.project_members for update
  using (
    project_id in (select id from public.projects where auth.uid() = owner_id)
  );

drop policy if exists "Owner can delete members" on public.project_members;

create policy "Owner can delete members"
  on public.project_members for delete
  using (
    project_id in (select id from public.projects where auth.uid() = owner_id)
  );

-- ============================================================
-- Update policies for checklist_items
-- ============================================================

drop policy if exists "Select items in accessible projects" on public.checklist_items;

create policy "Select items in accessible projects"
  on public.checklist_items for select
  using (
    project_id in (
      select id from public.projects
      where auth.uid() = owner_id or public.is_project_member(id)
    )
  );

drop policy if exists "Members can CRUD items" on public.checklist_items;

create policy "Members can CRUD items"
  on public.checklist_items for insert
  with check (
    project_id in (
      select id from public.projects where auth.uid() = owner_id
    )
    or public.has_member_role(project_id)
  );

drop policy if exists "Members can update items" on public.checklist_items;

create policy "Members can update items"
  on public.checklist_items for update
  using (
    project_id in (
      select id from public.projects where auth.uid() = owner_id
    )
    or public.has_member_role(project_id)
  );

drop policy if exists "Members can delete items" on public.checklist_items;

create policy "Members can delete items"
  on public.checklist_items for delete
  using (
    project_id in (
      select id from public.projects where auth.uid() = owner_id
    )
    or public.has_member_role(project_id)
  );

-- ============================================================
-- Update policies for task_completions
-- ============================================================

drop policy if exists "Select completions in accessible projects" on public.task_completions;

create policy "Select completions in accessible projects"
  on public.task_completions for select
  using (
    project_id in (
      select id from public.projects
      where auth.uid() = owner_id or public.is_project_member(id)
    )
  );

drop policy if exists "Members can complete tasks" on public.task_completions;

create policy "Members can complete tasks"
  on public.task_completions for insert
  with check (
    auth.uid() = user_id
    and (
      project_id in (select id from public.projects where auth.uid() = owner_id)
      or public.has_member_role(project_id)
    )
  );

drop policy if exists "Members can undo their completions" on public.task_completions;

create policy "Members can undo their completions"
  on public.task_completions for delete
  using (
    auth.uid() = user_id
    and (
      project_id in (select id from public.projects where auth.uid() = owner_id)
      or public.has_member_role(project_id)
    )
  );

-- ============================================================
-- Update policies for xp_earnings and project_user_stats
-- ============================================================

drop policy if exists "Select XP from accessible projects" on public.xp_earnings;

create policy "Select XP from accessible projects"
  on public.xp_earnings for select
  using (
    project_id in (
      select id from public.projects
      where auth.uid() = owner_id or public.is_project_member(id)
    )
  );

drop policy if exists "Select stats from accessible projects" on public.project_user_stats;

create policy "Select stats from accessible projects"
  on public.project_user_stats for select
  using (
    project_id in (
      select id from public.projects
      where auth.uid() = owner_id or public.is_project_member(id)
    )
  );
