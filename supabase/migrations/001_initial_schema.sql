-- ============================================================
-- Migration 001: Initial Schema — Devs Project Manager
-- Run this in Supabase SQL Editor
-- ============================================================

-- 0. Extensions
create extension if not exists "uuid-ossp";

-- ============================================================
-- 1. TABLES
-- ============================================================

-- 1a. Profiles (extends auth.users)
create table public.profiles (
  id            uuid primary key references auth.users on delete cascade,
  username      text unique not null,
  display_name  text,
  avatar_url    text,
  total_xp      integer not null default 0,
  created_at    timestamptz not null default now()
);

-- 1b. Projects
create table public.projects (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  description text,
  owner_id    uuid not null references public.profiles(id) on delete cascade,
  created_at  timestamptz not null default now()
);

-- 1c. Project Members
create type public.member_role as enum ('member', 'senior', 'boss');

create table public.project_members (
  id         uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  user_id    uuid not null references public.profiles(id) on delete cascade,
  role       public.member_role not null default 'member',
  unique(project_id, user_id)
);

-- 1d. Checklist Items (infinite nesting via parent_id)
create table public.checklist_items (
  id         uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  parent_id  uuid references public.checklist_items(id) on delete cascade,
  title      text not null,
  sort_order integer not null default 0,
  is_leaf    boolean not null default true,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now()
);

create index idx_checklist_items_project on public.checklist_items(project_id);
create index idx_checklist_items_parent on public.checklist_items(parent_id);

-- 1e. Task Completions
create table public.task_completions (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references public.profiles(id) on delete cascade,
  item_id      uuid not null references public.checklist_items(id) on delete cascade,
  project_id   uuid not null references public.projects(id) on delete cascade,
  completed_at timestamptz not null default now(),
  unique(user_id, item_id)
);

-- 1f. XP Earnings
create table public.xp_earnings (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles(id) on delete cascade,
  project_id uuid not null references public.projects(id) on delete cascade,
  amount     integer not null,
  source     text not null default 'task_completion',
  earned_at  timestamptz not null default now()
);

-- 1g. Per-Project User Stats
create table public.project_user_stats (
  user_id    uuid not null references public.profiles(id) on delete cascade,
  project_id uuid not null references public.projects(id) on delete cascade,
  xp         integer not null default 0,
  level      integer not null default 1,
  tasks_done integer not null default 0,
  primary key (user_id, project_id)
);

-- 1h. Reminders
create table public.reminders (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references public.profiles(id) on delete cascade,
  project_id   uuid not null references public.projects(id) on delete cascade,
  reminder_time time not null,
  days         boolean[7] not null default '{false,false,false,false,false,false,false}',
  sound_preset text not null default 'default',
  enabled      boolean not null default true,
  created_at   timestamptz not null default now()
);

-- 1i. Badges (static definitions)
create table public.badges (
  id          uuid primary key default gen_random_uuid(),
  key         text unique not null,
  name        text not null,
  icon        text not null,
  description text not null
);

-- 1j. User Badges (earned)
create table public.user_badges (
  user_id   uuid not null references public.profiles(id) on delete cascade,
  badge_id  uuid not null references public.badges(id) on delete cascade,
  earned_at timestamptz not null default now(),
  unique(user_id, badge_id)
);

-- ============================================================
-- 2. AUTO-CREATE PROFILE ON SIGNUP
-- ============================================================

create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, username, display_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'username', 'user_' || substr(new.id::text, 1, 8)),
    coalesce(new.raw_user_meta_data ->> 'display_name', new.email)
  );
  return new;
end;
$$ language plpgsql security definer;

create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ============================================================
-- 3. XP & LEVEL FUNCTIONS
-- ============================================================

-- Award XP when a leaf task is completed
create or replace function public.award_task_xp()
returns trigger as $$
declare
  v_project_xp integer := 10;
begin
  -- Record XP earning
  insert into public.xp_earnings (user_id, project_id, amount, source)
  values (new.user_id, new.project_id, v_project_xp, 'task_completion');

  -- Upsert project stats
  insert into public.project_user_stats (user_id, project_id, xp, level, tasks_done)
  values (
    new.user_id,
    new.project_id,
    v_project_xp,
    1,
    1
  )
  on conflict (user_id, project_id) do update set
    xp = project_user_stats.xp + v_project_xp,
    tasks_done = project_user_stats.tasks_done + 1,
    level = floor(sqrt((project_user_stats.xp + v_project_xp) / 100.0))::integer + 1;

  -- Update global XP
  update public.profiles
  set total_xp = total_xp + v_project_xp
  where id = new.user_id;

  return new;
end;
$$ language plpgsql security definer;

create trigger on_task_completion
  after insert on public.task_completions
  for each row execute function public.award_task_xp();

-- Undo XP when a task completion is deleted
create or replace function public.undo_task_xp()
returns trigger as $$
declare
  v_project_xp integer := 10;
begin
  delete from public.xp_earnings
  where user_id = old.user_id
    and project_id = old.project_id
    and source = 'task_completion'
    and earned_at = old.completed_at;

  update public.project_user_stats
  set
    xp = greatest(0, xp - v_project_xp),
    tasks_done = greatest(0, tasks_done - 1),
    level = floor(sqrt(greatest(0, xp - v_project_xp) / 100.0))::integer + 1
  where user_id = old.user_id and project_id = old.project_id;

  update public.profiles
  set total_xp = greatest(0, total_xp - v_project_xp)
  where id = old.user_id;

  return old;
end;
$$ language plpgsql security definer;

create trigger on_task_completion_delete
  after delete on public.task_completions
  for each row execute function public.undo_task_xp();

-- ============================================================
-- 4. ROW LEVEL SECURITY
-- ============================================================

-- 4a. Profiles
alter table public.profiles enable row level security;

create policy "Users can view own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id);

-- Public profiles are needed for leaderboard / teammate display
-- We'll add a separate read-only policy for that when leaderboard is built

-- 4b. Projects
alter table public.projects enable row level security;

create policy "Select own or member projects"
  on public.projects for select
  using (
    auth.uid() = owner_id
    or auth.uid() in (
      select user_id from public.project_members where project_id = id
    )
  );

create policy "Insert own projects"
  on public.projects for insert
  with check (auth.uid() = owner_id);

create policy "Update own projects"
  on public.projects for update
  using (auth.uid() = owner_id);

create policy "Delete own projects"
  on public.projects for delete
  using (auth.uid() = owner_id);

-- 4c. Project Members
alter table public.project_members enable row level security;

create policy "Select members of accessible projects"
  on public.project_members for select
  using (
    project_id in (
      select id from public.projects
      where auth.uid() = owner_id
         or auth.uid() in (
           select user_id from public.project_members pm where pm.project_id = projects.id
         )
    )
  );

create policy "Owner can manage members"
  on public.project_members for insert
  with check (
    project_id in (select id from public.projects where auth.uid() = owner_id)
  );

create policy "Owner can update members"
  on public.project_members for update
  using (
    project_id in (select id from public.projects where auth.uid() = owner_id)
  );

create policy "Owner can delete members"
  on public.project_members for delete
  using (
    project_id in (select id from public.projects where auth.uid() = owner_id)
  );

-- 4d. Checklist Items
alter table public.checklist_items enable row level security;

create policy "Select items in accessible projects"
  on public.checklist_items for select
  using (
    project_id in (
      select id from public.projects
      where auth.uid() = owner_id
         or auth.uid() in (
           select user_id from public.project_members pm where pm.project_id = projects.id
         )
    )
  );

create policy "Members can CRUD items"
  on public.checklist_items for insert
  with check (
    project_id in (
      select project_id from public.project_members
      where user_id = auth.uid() and role = 'member'
    )
    or project_id in (select id from public.projects where auth.uid() = owner_id)
  );

create policy "Members can update items"
  on public.checklist_items for update
  using (
    project_id in (
      select project_id from public.project_members
      where user_id = auth.uid() and role = 'member'
    )
    or project_id in (select id from public.projects where auth.uid() = owner_id)
  );

create policy "Members can delete items"
  on public.checklist_items for delete
  using (
    project_id in (
      select project_id from public.project_members
      where user_id = auth.uid() and role = 'member'
    )
    or project_id in (select id from public.projects where auth.uid() = owner_id)
  );

-- 4e. Task Completions
alter table public.task_completions enable row level security;

create policy "Select completions in accessible projects"
  on public.task_completions for select
  using (
    project_id in (
      select id from public.projects
      where auth.uid() = owner_id
         or auth.uid() in (
           select user_id from public.project_members pm where pm.project_id = projects.id
         )
    )
  );

create policy "Members can complete tasks"
  on public.task_completions for insert
  with check (
    auth.uid() = user_id
    and (
      project_id in (
        select project_id from public.project_members
        where user_id = auth.uid() and role = 'member'
      )
      or project_id in (select id from public.projects where auth.uid() = owner_id)
    )
  );

create policy "Members can undo their completions"
  on public.task_completions for delete
  using (
    auth.uid() = user_id
    and (
      project_id in (
        select project_id from public.project_members
        where user_id = auth.uid() and role = 'member'
      )
      or project_id in (select id from public.projects where auth.uid() = owner_id)
    )
  );

-- 4f. XP Earnings
alter table public.xp_earnings enable row level security;

create policy "Select XP from accessible projects"
  on public.xp_earnings for select
  using (
    project_id in (
      select id from public.projects
      where auth.uid() = owner_id
         or auth.uid() in (
           select user_id from public.project_members pm where pm.project_id = projects.id
         )
    )
  );

-- 4g. Project User Stats
alter table public.project_user_stats enable row level security;

create policy "Select stats from accessible projects"
  on public.project_user_stats for select
  using (
    project_id in (
      select id from public.projects
      where auth.uid() = owner_id
         or auth.uid() in (
           select user_id from public.project_members pm where pm.project_id = projects.id
         )
    )
  );

-- 4h. Reminders
alter table public.reminders enable row level security;

create policy "Users manage their own reminders"
  on public.reminders for all
  using (auth.uid() = user_id);

-- 4i. Badges (read-only, public)
alter table public.badges enable row level security;

create policy "Anyone can view badges"
  on public.badges for select
  using (true);

-- 4j. User Badges
alter table public.user_badges enable row level security;

create policy "Users view their own badges"
  on public.user_badges for select
  using (auth.uid() = user_id);

-- ============================================================
-- 5. SEED BADGES
-- ============================================================

insert into public.badges (key, name, icon, description) values
  ('first_task',    'First Step',       'star',           'Complete your first task'),
  ('ten_tasks',     'Getting Started',  'stars',          'Complete 10 tasks'),
  ('fifty_tasks',   'Workhorse',        'rocket',         'Complete 50 tasks'),
  ('hundred_tasks', 'Century',          'trophy',         'Complete 100 tasks'),
  ('level_5',       'Apprentice',       'shield',         'Reach level 5 in any project'),
  ('level_10',      'Expert',           'crown',          'Reach level 10 in any project'),
  ('level_25',      'Master',           'diamond',        'Reach level 25 in any project')
on conflict (key) do nothing;
