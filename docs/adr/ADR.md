# Architecture Decision Records — Devs Project Manager

## ADR-001: Cross-Platform Framework

**Status:** Accepted

### Context
Need a single codebase targeting Web (desktop browser), Android, and iOS. The lead developer is comfortable with React Native but wants other Flutter devs to be able to contribute.

### Options Considered
1. **Flutter** — Dart, single codebase, strong UI consistency across platforms, growing web support
2. **Expo (React Native)** — TypeScript/JS, mature RN Web, familiar to lead dev
3. **Native separate** — Maintain web, Android, iOS independently (rejected — too much overhead)

### Decision
Flutter. The developer's React Native knowledge transfers conceptually (component lifecycle, state management, navigation patterns). Dart is easy to pick up for JS/TS devs. Flutter's widget system gives pixel-perfect control on both mobile and web, and the Flutter web target (canvaskit/HTML renderer) is production-ready for this type of app. The ability for other Flutter devs to contribute outweighs the lead's initial familiarity with React Native.

### Consequences
- Lead developer will need to learn Dart (but can leverage JS/TS knowledge)
- Flutter web is slightly heavier than a pure SPA, acceptable for this use case
- Access to Flutter's rich ecosystem of packages for local notifications, audio, etc.

---

## ADR-002: Backend — Supabase

**Status:** Accepted

### Context
Need managed auth, database, realtime subscriptions, file storage (sound presets), and scheduled jobs for reminders. Want to minimize DevOps overhead.

### Options Considered
1. **Supabase** — Postgres, built-in Auth, Realtime, Edge Functions, Storage, RLS
2. **Firebase** — Firestore (NoSQL), FCM, but vendor lock-in, no relational queries
3. **Custom backend** (Node.js + Postgres) — full control but requires building auth, realtime, etc.

### Decision
Supabase. PostgreSQL gives us relational data (projects, nested checklists, memberships) — a natural fit. RLS maps directly to our role-based permissions (member vs senior/boss). Realtime subscriptions let collaborators see live checklist updates. Edge Functions handle scheduled reminders. Free tier is generous for development.

### Consequences
- Schema migrations managed via Supabase CLI or plain SQL
- RLS policies must be carefully written for each table
- Realtime subscriptions need to be scoped to avoid over-fetching
- Local development via `supabase start` (Docker-based)

---

## ADR-003: Monorepo Structure

**Status:** Accepted

### Context
Single codebase for Flutter app, Supabase migrations, and shared configuration.

### Options Considered
1. **Monorepo** — all in one repo with separated packages
2. **Separate repos** — Flutter app repo + Supabase project repo

### Decision
Monorepo. Simplifies CI/CD, code reviews, and dependency management.

```
devs-project-manager/
├── app/                    # Flutter application (web + mobile)
│   ├── lib/
│   │   ├── core/           # theme, constants, routing
│   │   ├── features/       # feature modules
│   │   ├── shared/         # reusable widgets, utils
│   │   └── main.dart
│   ├── android/
│   ├── ios/
│   └── web/
├── supabase/
│   ├── migrations/         # SQL migrations
│   ├── seed.sql            # dev seed data
│   ├── functions/          # Edge Functions
│   └── config.toml
├── docs/
│   └── adr/               # ADR files
├── README.md
└── .github/
    └── workflows/          # CI/CD
```

### Consequences
- Single `git` workflow
- Flutter project follows feature-first organization
- Supabase config lives alongside app code

---

## ADR-004: Infinite Nested Checklists

**Status:** Accepted

### Context
Users need to break down projects into phases → tasks → subtasks → sub-subtasks, etc., with no artificial depth limit.

### Options Considered
1. **Adjacency list** (`parent_id`, nullable) — each item references its parent. Simple, supports arbitrary depth.
2. **Nested sets** (lft/rgt) — efficient subtree queries, complex inserts/updates
3. **Materialized path** (path string) — good for queries, path updates expensive on reorder
4. **Fixed depth** — simpler but limits user freedom

### Decision
Adjacency list (`parent_id UUID NULL REFERENCES checklist_items(id)`). Simplest to implement with Supabase/Postgres. Depth queries use recursive CTEs (`WITH RECURSIVE`) when needed. Drill-down navigation loads only one level at a time — no need to fetch full tree.

### Consequences
- Querying full tree depth requires recursive CTE (rare operation)
- Deleting parent must cascade or handle orphans
- Works well with drill-down UX (fetch children on tap)
- Index on `(project_id, parent_id)` for efficient child queries

---

## ADR-005: XP & Gamification

**Status:** Accepted

### Context
Leaf-level task completion awards XP. Per-project levels and global rank. Monthly leaderboard.

### Rules
- **Only leaf tasks** (`is_leaf = true`) award XP
- Fixed XP per task (default 10, configurable per project)
- **Per-project level**: calculated from XP in that project, following a progression curve (e.g., `level = floor(sqrt(xp / 100))`)
- **Global rank**: sum of all XP across projects → mapped to tiers (Bronze/Silver/Gold/Platinum/Diamond)
- **Monthly leaderboard**: XP earned in current month; resets monthly, history preserved
- **Badges**: awarded via `user_badges` table when conditions are met (Edge Function or DB trigger)

### Consequences
- XP awarded atomically on leaf task completion (DB trigger or app-level transaction)
- Level is computed, stored in `project_user_stats` for quick reads
- Leaderboard queries are read-only, cacheable
- Badges need a check/trigger mechanism

---

## ADR-006: Platform-Adaptive Navigation

**Status:** Accepted

### Context
Web users expect a sidebar; mobile users expect a bottom nav bar. Same app, same routes, different presentation.

### Approach
Use `LayoutBuilder` + platform detection to switch navigation shells:

```dart
Widget build(BuildContext context) {
  final isWide = MediaQuery.of(context).size.width > 768;
  return isWide ? SidebarShell() : BottomNavShell();
}
```

- **Web** (>768px): Sidebar (NavigationRail or custom Drawer) with content area
- **Mobile** (<768px or Platform.isAndroid/iOS): Scaffold with BottomNavigationBar
- Routes are shared — only the navigation container changes
- Drill-down checklist pages push onto Navigator stack on both platforms

### Consequences
- Two navigation widgets, same page content
- 768px breakpoint is a reasonable tablet cutoff
- Web also supports narrow-window fallback to bottom nav

---

## ADR-007: Notifications & Reminders

**Status:** Accepted

### Context
Users configure reminders per project (time + days + sound). Need to work on mobile (with sound) and web (browser notifications).

### Approach

| Platform | Solution |
|---|---|
| **Android** | `flutter_local_notifications` + WorkManager for scheduled exact alarms |
| **iOS** | `flutter_local_notifications` with UNNotificationRequest (calendar trigger) |
| **Web** | Browser Notification API via JS interop |
| **Cross-device** | Optional: Supabase Edge Function cron for FCM/APNs push |

**Primary strategy:** Local notifications scheduled on-device. Reminder config persisted to Supabase AND scheduled locally. On new device login, fetch reminders from Supabase and re-schedule.

**Sound effects:** Pre-bundled `.wav`/`.mp3` assets. Users pick from presets. `audioplayers` for in-app sounds. `flutter_local_notifications` supports custom sound URIs.

### Consequences
- Handle notification permissions per platform
- Android requires `SCHEDULE_EXACT_ALARM` permission
- iOS limit: 64 scheduled notifications (fine for this app)
- Web requires HTTPS and user permission

---

## ADR-008: Authorization — Row Level Security (RLS)

**Status:** Accepted

### Context
Three roles per project: owner, member (can edit), senior/boss (read-only). Only shared projects are visible.

### Approach
Supabase RLS policies on every table:

```sql
-- Users see only their projects
CREATE POLICY "select_project" ON projects
  FOR SELECT USING (
    auth.uid() = owner_id
    OR auth.uid() IN (
      SELECT user_id FROM project_members WHERE project_id = id
    )
  );

-- Only owner can update/delete
CREATE POLICY "update_project" ON projects
  FOR UPDATE USING (auth.uid() = owner_id);
```

- `checklist_items`: members can CRUD, senior/boss SELECT-only
- `task_completions`: members can insert/update, senior/boss SELECT-only
- Role fetched on project entry; UI disables checkboxes for senior/boss

### Consequences
- RLS must be tested thoroughly (Supabase local testing)
- Role metadata cached client-side per project
- Edge case: owner demotion — ensure at least one owner remains

---

## ADR-009: State Management — Riverpod

**Status:** Accepted

### Context
Flutter app needs auth state, Supabase realtime subscriptions, async data fetching, and cross-cutting concerns like XP updates and notifications.

### Options Considered
1. **Riverpod** — compile-safe, no BuildContext dependency, excellent for async data
2. **BLoC** — well-established but verbose for this project size
3. **Provider** — predecessor, less safe (runtime errors)
4. **GetX** — simple but controversial, poor for large projects

### Decision
Riverpod 2 with code generation (`riverpod_annotation`). Handles async data from Supabase naturally via `AsyncValue`, supports auto-disposal, plays well with Flutter's widget tree.

### Consequences
- Add `flutter_riverpod` + `riverpod_annotation` + `build_runner`
- Feature modules own their providers
- Supabase client is a singleton provider
- Auth state is a StreamProvider wrapping `supabase.auth.onAuthStateChange`
