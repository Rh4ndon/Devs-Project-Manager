-- ============================================================
-- Migration 003: Simplified RLS — no recursion
-- Run this ENTIRE script in Supabase SQL Editor
-- ============================================================

-- 1. Drop all existing policies to start clean
drop policy if exists "Select own or member projects" on public.projects;
drop policy if exists "Insert own projects" on public.projects;
drop policy if exists "Update own projects" on public.projects;
drop policy if exists "Delete own projects" on public.projects;

drop policy if exists "Select members of accessible projects" on public.project_members;
drop policy if exists "Owner can manage members" on public.project_members;
drop policy if exists "Owner can update members" on public.project_members;
drop policy if exists "Owner can delete members" on public.project_members;

drop policy if exists "Select items in accessible projects" on public.checklist_items;
drop policy if exists "Members can CRUD items" on public.checklist_items;
drop policy if exists "Members can update items" on public.checklist_items;
drop policy if exists "Members can delete items" on public.checklist_items;

drop policy if exists "Select completions in accessible projects" on public.task_completions;
drop policy if exists "Members can complete tasks" on public.task_completions;
drop policy if exists "Members can undo their completions" on public.task_completions;

drop policy if exists "Select XP from accessible projects" on public.xp_earnings;

drop policy if exists "Select stats from accessible projects" on public.project_user_stats;

-- 2. Security definer helper functions (bypass RLS)
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

-- 3. Projects
alter table public.projects enable row level security;

create policy "projects_select"
  on public.projects for select
  using (
    auth.uid() = owner_id or public.is_project_member(id)
  );

create policy "projects_insert"
  on public.projects for insert
  with check (auth.uid() = owner_id);

create policy "projects_update"
  on public.projects for update
  using (auth.uid() = owner_id);

create policy "projects_delete"
  on public.projects for delete
  using (auth.uid() = owner_id);

-- 4. Project Members
alter table public.project_members enable row level security;

create policy "members_select"
  on public.project_members for select
  using (public.is_project_member(project_id));

create policy "members_insert"
  on public.project_members for insert
  with check (
    project_id in (select id from public.projects where auth.uid() = owner_id)
  );

create policy "members_update"
  on public.project_members for update
  using (
    project_id in (select id from public.projects where auth.uid() = owner_id)
  );

create policy "members_delete"
  on public.project_members for delete
  using (
    project_id in (select id from public.projects where auth.uid() = owner_id)
  );

-- 5. Checklist Items
alter table public.checklist_items enable row level security;

create policy "items_select"
  on public.checklist_items for select
  using (
    public.is_project_member(project_id) or auth.uid() in (
      select owner_id from public.projects where id = project_id
    )
  );

create policy "items_insert"
  on public.checklist_items for insert
  with check (
    public.has_member_role(project_id) or auth.uid() in (
      select owner_id from public.projects where id = project_id
    )
  );

create policy "items_update"
  on public.checklist_items for update
  using (
    public.has_member_role(project_id) or auth.uid() in (
      select owner_id from public.projects where id = project_id
    )
  );

create policy "items_delete"
  on public.checklist_items for delete
  using (
    public.has_member_role(project_id) or auth.uid() in (
      select owner_id from public.projects where id = project_id
    )
  );

-- 6. Task Completions
alter table public.task_completions enable row level security;

create policy "completions_select"
  on public.task_completions for select
  using (
    public.is_project_member(project_id) or auth.uid() in (
      select owner_id from public.projects where id = project_id
    )
  );

create policy "completions_insert"
  on public.task_completions for insert
  with check (
    auth.uid() = user_id
    and (
      public.has_member_role(project_id) or auth.uid() in (
        select owner_id from public.projects where id = project_id
      )
    )
  );

create policy "completions_delete"
  on public.task_completions for delete
  using (
    auth.uid() = user_id
    and (
      public.has_member_role(project_id) or auth.uid() in (
        select owner_id from public.projects where id = project_id
      )
    )
  );

-- 7. XP Earnings
alter table public.xp_earnings enable row level security;

create policy "xp_select"
  on public.xp_earnings for select
  using (
    public.is_project_member(project_id) or auth.uid() in (
      select owner_id from public.projects where id = project_id
    )
  );

-- 8. Project User Stats
alter table public.project_user_stats enable row level security;

create policy "stats_select"
  on public.project_user_stats for select
  using (
    public.is_project_member(project_id) or auth.uid() in (
      select owner_id from public.projects where id = project_id
    )
  );

-- 9. Profiles
-- Keep existing policies for profiles (already correct)
