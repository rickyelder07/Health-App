# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Health Tracker is an iOS calorie tracking app built with SwiftUI and Supabase. It integrates with Strava for activity syncing and USDA FoodData Central for nutrition database. The app tracks food intake, exercise calories, and calculates BMR/TDEE for comprehensive calorie management.

**Key Technologies:**
- iOS 16+, SwiftUI
- Supabase (PostgreSQL, Auth, Storage)
- Strava API (OAuth 2.0, activity syncing)
- USDA FoodData Central API
- MVVM architecture with Combine

## Development Commands

### Build & Run
```bash
# Open project in Xcode
open "Healthapp/Healthapp.xcodeproj"

# Build via command line
cd Healthapp
xcodebuild -project Healthapp.xcodeproj -scheme Healthapp -destination 'platform=iOS Simulator,name=iPhone 15' build

# Clean build
xcodebuild clean -project Healthapp.xcodeproj -scheme Healthapp
```

### Dependencies
```bash
# Resolve Swift Package dependencies
swift package resolve

# Update packages
swift package update
```

### Database Migrations
```bash
# Apply Supabase migrations (run SQL files manually in Supabase Dashboard)
# Files located in: supabase/migrations/
# - 001_initial_schema_safe.sql - Core tables (users, food_logs, activities, etc.)
# - 002_helper_functions.sql - Database functions and triggers
```

## Architecture

### Project Structure
The actual implementation is in `Healthapp/Healthapp/` directory (note the nested structure):
- **Config/** - API keys and configuration (Configuration.swift)
- **Models/** - Data models (User, FoodEntry, Activity, DailySummary, etc.)
- **Views/** - SwiftUI views (HomeView, ProfileView, AddFoodView, etc.)
  - **Components/** - Reusable view components
- **ViewModels/** - MVVM presentation logic
- **Services/** - Business logic and API integration
- **Utilities/** - Extensions and helpers

Root directory contains documentation and old placeholder files (Package.swift, HealthApp.swift in root are NOT used).

### Data Flow Pattern
All data operations follow this pattern:
1. **View** triggers action (button tap, load)
2. **ViewModel** handles UI state (`@Published` properties)
3. **Service** performs business logic and API calls
4. **SupabaseClient** (singleton) manages database/auth
5. Data flows back through `@Published` properties
6. SwiftUI automatically re-renders

### Key Services

**SupabaseService** (SupabaseClient.swift)
- Singleton: `SupabaseService.shared` or `SupabaseClient.shared`
- Access client: `SupabaseClient.shared.client`
- Auth: `SupabaseClient.shared.auth`
- Database queries: `SupabaseClient.shared.client.from("table_name")`
- Storage: `SupabaseClient.shared.client.storage`

**DailySummaryService** (DailySummaryService.swift)
- Calculates daily calorie/macro totals from food_logs and activities
- Auto-updates when food is logged or activities synced
- Uses `upsert` to create or update summaries
- Critical: Always call `updateDailySummary(userId:date:)` after modifying food_logs or activities

**StravaService** (StravaService.swift)
- OAuth flow: `startOAuthFlow()` → user authorizes → `exchangeToken(code:userId:)`
- Token stored in `strava_connections` table
- Auto-refreshes expired tokens (5-minute buffer)
- Syncs activities: `syncActivities(userId:connection:)`
- Rate limiting: 100 requests/15min, 1000/day

**FoodService** (FoodService.swift)
- Logs food to `food_logs` table
- Auto-triggers daily summary update
- Supports custom foods and USDA lookup

**USDAService** (USDAService.swift)
- Searches USDA FoodData Central API
- Returns nutrition info (calories, protein, carbs, fat)

### Database Schema

**Key Tables:**
- `users` - Extended auth.users with weight, height, age, gender, activity_level, bmr, tdee
- `food_logs` - Food entries with macros and meal_type
- `activities` - Strava activities with calories_burned
- `daily_summaries` - Calculated daily totals (calories consumed/burned, macros, net calories)
- `strava_connections` - OAuth tokens for Strava integration
- `progress_photos` - Photos stored in Supabase Storage bucket

**Important Functions:**
- `calculate_bmr()` - Mifflin-St Jeor equation (matches User.calculateBMR())
- `calculate_tdee()` - BMR * activity level multiplier
- `update_daily_summary_on_food_change()` - Trigger for food_logs changes
- `update_daily_summary_on_activity_change()` - Trigger for activities changes

### Configuration

**Config/Configuration.swift** contains all API keys:
- Supabase URL and anon key
- Strava client ID/secret and redirect URI
- USDA API key

**Important:** Uses localhost redirect for Strava OAuth: `http://127.0.0.1:8080`
- LocalWebServer.swift handles the callback
- Redirect URI must match Strava app settings

### Authentication Flow

1. User signs up/in via AuthenticationView
2. AuthenticationViewModel calls AuthenticationService
3. Supabase Auth creates session
4. AppState (global @EnvironmentObject) stores current user
5. ContentView routes to MainTabView if authenticated

Session persists via Supabase SDK (emitLocalSessionAsInitialSession: true)

### Strava Integration

**OAuth Flow:**
1. `StravaService.startOAuthFlow(userId)` opens Safari
2. User authorizes on Strava
3. Redirect to `http://127.0.0.1:8080` with code
4. LocalWebServer receives callback, posts NotificationCenter event
5. StravaViewModel.handleOAuthCallback(code) exchanges for tokens
6. Connection stored in `strava_connections`
7. Auto-syncs activities

**Activity Syncing:**
- Fetches from Strava API with pagination (30/page)
- Stores in `activities` table (upsert by strava_id)
- Estimates calories if not provided by Strava
- Updates daily_summaries with exercise calories

See STRAVA_INTEGRATION.md for complete details.

### Daily Summary System

**Critical Pattern:**
Always update daily summary after:
- Logging food: `FoodService.logFood()` → calls `DailySummaryService.updateDailySummary()`
- Syncing activities: `StravaService.syncActivities()` → calls `DailySummaryService.updateDailySummary()`
- Updating profile: BMR/TDEE changes → recalculate summaries

**Calculation:**
```
calories_consumed = SUM(food_logs.calories) for date
calories_burned_exercise = SUM(activities.calories) for date
calories_burned_bmr = user.bmr
total_calories_burned = bmr + exercise
net_calories = consumed - total_burned
```

See DAILY_SUMMARY_SETUP.md for setup and DAILY_SUMMARY_GUIDE.md for implementation details.

### BMR/TDEE Calculation

**Mifflin-St Jeor Equation:**
```
BMR = (10 × weight_kg) + (6.25 × height_cm) - (5 × age) + gender_offset
  Male: +5
  Female: -161
  Other: -78 (average)

TDEE = BMR × activity_level_multiplier
  Sedentary: 1.2
  Lightly Active: 1.375
  Moderately Active: 1.55
  Very Active: 1.725
  Extra Active: 1.9
```

Implemented in both Swift (User.swift) and database (calculate_bmr/calculate_tdee functions).

### Progress Photos

- Stored in Supabase Storage bucket: `progress-photos`
- PhotoService handles upload/download
- Bucket must be private with RLS policies
- URLs are signed (temporary access)

## Common Development Patterns

### Adding a New Model
1. Create struct in Models/ conforming to Codable, Identifiable
2. Add CodingKeys for snake_case mapping
3. Create corresponding Supabase table
4. Add RLS policies (user can only access own data)
5. Create Service class for CRUD operations

### Adding a New View
1. Create SwiftUI View in Views/
2. Create ViewModel in ViewModels/ if needed (ObservableObject with @Published)
3. Inject dependencies via init (userId, services)
4. Use @EnvironmentObject for AppState
5. Follow existing patterns: .task{} for loading, .refreshable{} for pull-to-refresh

### Working with Supabase
```swift
// Query
let users: [User] = try await SupabaseClient.shared.client
    .from("users")
    .select()
    .eq("id", value: userId)
    .execute()
    .value

// Insert
try await SupabaseClient.shared.client
    .from("food_logs")
    .insert(foodEntry)
    .execute()

// Update
try await SupabaseClient.shared.client
    .from("users")
    .update(["weight": newWeight])
    .eq("id", value: userId)
    .execute()

// Upsert (insert or update)
try await SupabaseClient.shared.client
    .from("daily_summaries")
    .upsert(summary)
    .execute()
```

### Error Handling
- Service methods throw errors
- ViewModels catch and set errorMessage: String?
- Views display error banners/alerts
- Use Logger.swift for structured logging: `Logger.log("message", category: .network, level: .error)`

## Testing Notes

No unit tests currently implemented. When adding:
- Create HealthappTests/ directory
- Use XCTest framework
- Mock SupabaseClient for testing services
- Test ViewModels independently of Views
- Test BMR/TDEE calculations match database functions

## Known Issues & Gotchas

1. **Nested directory structure:** Actual code is in `Healthapp/Healthapp/`, not root
2. **Package.swift in root is unused:** Real project is Xcode project in Healthapp/
3. **Strava localhost redirect:** Requires LocalWebServer running, may not work on physical device
4. **Token refresh timing:** 5-minute buffer before expiration, ensure it's checked before every API call
5. **Daily summary consistency:** Always update after food/activity changes to avoid stale data
6. **RLS policies required:** All tables need proper policies or queries will fail
7. **Date handling:** Use DateExtensions.swift for consistent timezone handling (startOfDay, etc.)

## Important Files to Reference

- **STRAVA_INTEGRATION.md** - Complete Strava OAuth and activity sync docs
- **DAILY_SUMMARY_SETUP.md** - Setup guide for daily summary system
- **PROFILE_SYSTEM.md** - User profile and BMR/TDEE calculation
- **README.md** - Setup instructions and feature overview
- **supabase/migrations/** - Database schema and functions

## API Rate Limits

- **Strava:** 100 requests/15min, 1000/day (handle 429 status)
- **USDA:** No strict limit but be reasonable with searches
- **Supabase:** Free tier limits (check dashboard)
