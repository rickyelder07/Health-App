# Netfuel

iOS calorie tracking app with Strava integration. Tracks food intake, exercise calories, and calculates BMR/TDEE for net calorie management.

**Stack**: SwiftUI · Supabase (PostgreSQL + Auth + Storage) · Strava API · USDA FoodData Central · MVVM + Combine

---

## Project Layout

```
Health App/
├── Healthapp/                  # Xcode project (all app source lives here)
│   ├── Healthapp.xcodeproj/
│   ├── Healthapp/              # App source
│   │   ├── Config/             # API keys (xcconfig + Configuration.swift)
│   │   ├── Models/             # Codable data models
│   │   ├── Views/              # SwiftUI views
│   │   ├── ViewModels/         # ObservableObject view models
│   │   ├── Services/           # Business logic & API clients
│   │   └── Utilities/          # Extensions and helpers
│   ├── NetfuelWidget/          # iOS widget extension
│   ├── HealthappTests/         # Unit tests
│   └── HealthappUITests/       # UI tests
├── supabase/
│   ├── migrations/             # Run these in order in Supabase SQL Editor
│   │   ├── 000_cleanup.sql
│   │   ├── 001_schema.sql      # Core tables + RLS
│   │   ├── 002_functions.sql   # Triggers + BMR/TDEE helpers
│   │   └── 003_storage.sql     # Storage bucket policies
│   └── README.md               # Full DB setup instructions
└── docs/
    ├── APP_STORE.md            # App Store submission guide + metadata
    ├── TESTING.md              # Testing and debugging guide
    ├── privacy-policy.html
    └── terms-of-service.html
```

---

## First-Time Setup

### 1. Open in Xcode

```bash
open "Healthapp/Healthapp.xcodeproj"
```

Supabase Swift SDK is managed via Xcode SPM — it resolves automatically on first open.

### 2. Configure API Keys

Copy the secrets template and fill in your values:

```bash
cd Healthapp/Healthapp/Config
cp Secrets.template.xcconfig Secrets.xcconfig
```

Edit `Secrets.xcconfig` with your keys:

```
SUPABASE_URL = https://your-project.supabase.co
SUPABASE_ANON_KEY = eyJ...
STRAVA_CLIENT_ID = 123456
STRAVA_CLIENT_SECRET = abc123...
USDA_API_KEY = your-key-here
```

`Secrets.xcconfig` is gitignored — never commit it.

**Getting keys:**
- **Supabase**: [supabase.com](https://supabase.com) → Settings → API
- **Strava**: [strava.com/settings/api](https://www.strava.com/settings/api) — set callback domain to `netfuel`
- **USDA**: [fdc.nal.usda.gov/api-key-signup.html](https://fdc.nal.usda.gov/api-key-signup.html)

### 3. Set Up the Database

Run the migration files in order via Supabase SQL Editor (or CLI):

```
supabase/migrations/000_cleanup.sql   ← if rebuilding from scratch
supabase/migrations/001_schema.sql    ← core tables + RLS
supabase/migrations/002_functions.sql ← triggers + BMR/TDEE
supabase/migrations/003_storage.sql   ← storage bucket policies
```

See `supabase/README.md` for full instructions and CLI usage.

### 4. Build and Run

Select a simulator or device, press `Cmd + R`.

---

## Key Features

| Feature | How it works |
|---------|-------------|
| Food logging | Search USDA FoodData Central (300k+ foods) or create custom foods |
| Activity tracking | OAuth with Strava; activities auto-sync and add to daily burn |
| BMR/TDEE | Mifflin-St Jeor equation; calculated in Swift and enforced by DB triggers |
| Daily summary | Auto-updated by DB triggers whenever food logs or activities change |
| Progress photos | Stored in private Supabase Storage bucket (`progress-photos`) |
| Widget | Home screen widget via `NetfuelWidget` extension |

---

## Architecture

```
View → ViewModel → Service → SupabaseClient
         ↑__________________________|
              @Published / Combine
```

- **AppState** (`HealthApp.swift`) — global auth state, injected as `@EnvironmentObject`
- **SupabaseClient.shared** — singleton; `client.from("table")` for all DB ops
- **DailySummaryService** — always call `updateDailySummary()` after food or activity changes

---

## Strava OAuth Note

The OAuth redirect uses `http://127.0.0.1:8080` (handled by `LocalWebServer.swift`). This works in Simulator; on a physical device you'll need to swap in a proper deep-link scheme. The redirect URI must match exactly what's registered in your Strava app settings.

---

## Docs

- `supabase/README.md` — database setup, schema overview, useful SQL queries
- `docs/APP_STORE.md` — App Store submission checklist, metadata, TestFlight guide
- `docs/TESTING.md` — testing and debugging guide
- `CLAUDE.md` — architecture reference for AI-assisted development
