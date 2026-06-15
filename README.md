# Devs Project Manager

A cross-platform project management app with nested checklists, team collaboration, role-based access, gamification, and daily reminders.

Built with **Flutter** (web + Android + iOS) and **Supabase** (backend).

---

## Features

- **Projects** — Create and manage multiple projects with infinite-depth nested checklists (phases → tasks → subtasks → ...)
- **Team Collaboration** — Invite teammates and bosses to projects with role-based permissions:
  - **Member** — check/uncheck tasks, add subtasks
  - **Senior / Boss** — read-only view of team progress
- **Gamification** — Earn XP for completing leaf tasks, level up per project, earn badges, climb the global leaderboard
- **Daily Reminders** — Configure per-project notifications at specific times and days, with customizable sound presets
- **Platform-Adaptive UI** — Sidebar navigation on web, bottom navigation bar on mobile, same shared routes
- **Leaderboard** — Public teaser before login, full ranking with monthly resets after login

---

## Architecture

```
devs-project-manager/
├── app/                  # Flutter application
│   ├── lib/
│   │   ├── core/         # Theme, constants, routing
│   │   ├── features/     # Feature modules (auth, projects, checklists, etc.)
│   │   ├── shared/       # Reusable widgets and utilities
│   │   └── main.dart
│   ├── android/
│   ├── ios/
│   └── web/
├── supabase/
│   ├── migrations/       # SQL migrations
│   ├── seed.sql          # Development seed data
│   ├── functions/        # Edge Functions (reminders, badges)
│   └── config.toml
├── docs/
│   └── adr/              # Architecture Decision Records
└── README.md
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart) |
| Backend | Supabase (PostgreSQL, Auth, Realtime, Edge Functions) |
| State Management | Riverpod |
| Notifications | flutter_local_notifications (mobile) + Browser Notification API (web) |
| Sound Effects | audioplayers + custom preset assets |

---

## Getting Started

> Prerequisites: Flutter SDK, Supabase CLI, Docker

```bash
# Clone the repo
git clone https://github.com/your-org/devs-project-manager
cd devs-project-manager

# Start Supabase locally
cd supabase
supabase start

# Run the Flutter app
cd ../app
flutter pub get
flutter run -d chrome     # web
flutter run -d android    # android
```

---

## ADRs

See [docs/adr/ADR.md](docs/adr/ADR.md) for all Architecture Decision Records covering framework choice, database design, RLS policies, navigation patterns, and more.

---

## License

MIT
