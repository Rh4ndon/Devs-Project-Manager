# Devs Project Manager — Status

## Phase 1: Foundation ✅

- [x] ADR written (9 architecture decisions)
- [x] Flutter project created & SDK 3.32.3 installed
- [x] Supabase migrations 001–002 applied (schema, RLS, auth triggers, XP functions, seed badges)
- [x] Auth: email/password + Google OAuth (both platforms)
- [x] Platform-adaptive shell (sidebar web > 768px, bottom nav mobile)
- [x] GoRouter with auth guard + error builder
- [x] AuthNotifier with `isReady` guard (prevents redirect flicker)
- [x] Projects CRUD (list, create, edit, delete)
- [x] Project detail screen placeholder → now shows checklist

## Phase 2: Nested Checklists ✅

- [x] ChecklistItem model + Supabase CRUD providers
- [x] Tree view UI: all items fetched at once, rendered inline with expand/collapse
- [x] Groups (▶) expand/collapse in place — no page navigation
- [x] Leaf tasks toggle completion (check circle ✔)
- [x] **Add sub-item** from group popup menu (nest at any depth)
- [x] Collapse all button in app bar
- [x] Project name as app bar title (ellipsis on overflow)

## What's Been Added Along the Way

- **Deadline** field on projects (date picker, clear button, overdue/upcoming display) — *has a re-selection bug on mobile & web, deferred*
- **Project card** shows created date + deadline with colour-coded urgency
- **Right overflow** on project card fixed (Flexible + ellipsis, SizedBox wrapped trailing)

## Known Issues (Deferred)

- Date picker: re-selecting a previously picked date in the same session doesn't update the field (both `showDatePicker` and `showDialog` + custom picker affected; workaround: close & reopen dialog)
- XP trigger exists in DB but no UI for XP display yet
- No team member management UI yet

## Next Phases (Planned)

### Phase 3: Team & Sharing
- Invite members by email
- Role picker (member / senior / boss)
- Project members list
- RLS already in place

### Phase 4: Dashboard & Stats
- Personal XP, level, progress bars
- Per-project stats
- Global rank

### Phase 5: Leaderboard
- Monthly ranking
- Public teaser
- Badge display

### Phase 6: Reminders & Notifications
- Daily reminder config (time + day picker)
- Local notification scheduling
- Sound preset picker

### Phase 7: Sound Effects
- Sound on task completion
- Sound on level up
- User-selectable presets

## Tech Stack
- **Framework:** Flutter (Dart) 3.32.3
- **Backend:** Supabase (Postgres, RLS, Edge Functions)
- **State:** Riverpod
- **Routing:** GoRouter
- **Auth:** Supabase Auth (email/password + Google OAuth)
- **DB:** PostgreSQL with adjacency list for nested checklists

## Relevant Files
- `app/lib/` — Flutter application
- `supabase/migrations/` — Database migrations (001, 002, 003, 004)
- `docs/adr/ADR.md` — Architecture Decision Records
