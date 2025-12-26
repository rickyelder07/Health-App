# Project Structure Overview

This document provides a visual overview of the complete project structure and file organization.

## Directory Tree

```
Health App/
│
├── 📄 HealthApp.swift                    # Main app entry point (@main)
├── 📄 AppState.swift                     # Global app state (authentication, current user)
├── 📄 ContentView.swift                  # Root view (auth vs main app routing)
├── 📄 Package.swift                      # Swift Package Manager configuration
├── 📄 README.md                          # Complete project documentation
├── 📄 SETUP_GUIDE.md                     # Step-by-step setup instructions
├── 📄 PROJECT_STRUCTURE.md               # This file
├── 📄 Context.md                         # Original project context
├── 📄 .gitignore                         # Git ignore rules
│
├── 📁 Config/                            # Configuration and constants
│   └── 📄 Configuration.swift            # API keys, URLs, app constants
│
├── 📁 Models/                            # Data models and business logic
│   ├── 📄 User.swift                     # User profile with BMR/TDEE calculations
│   ├── 📄 FoodEntry.swift                # Food logging with macros
│   ├── 📄 Activity.swift                 # Strava activity (exercise calories)
│   ├── 📄 ProgressPhoto.swift            # Progress photo tracking
│   ├── 📄 DailySummary.swift             # Daily calorie summary
│   ├── 📄 StravaModels.swift             # Strava API response models
│   └── 📄 USDAModels.swift               # USDA API response models
│
├── 📁 Views/                             # SwiftUI views (UI layer)
│   ├── 📄 AuthenticationView.swift       # Login/signup screen
│   ├── 📄 MainTabView.swift              # Main tab navigation container
│   ├── 📄 HomeView.swift                 # Home screen with daily summary
│   ├── 📄 CalendarView.swift             # Calendar view for history
│   ├── 📄 AddFoodView.swift              # Food search and logging
│   ├── 📄 ActivitiesView.swift           # Strava activities list
│   └── 📄 ProfileView.swift              # User profile and settings
│
├── 📁 ViewModels/                        # ViewModels (MVVM pattern)
│   ├── 📄 AuthenticationViewModel.swift  # Authentication logic
│   └── 📄 HomeViewModel.swift            # Home screen logic
│
├── 📁 Services/                          # Business logic and API services
│   ├── 📄 SupabaseClient.swift           # Supabase singleton client
│   ├── 📄 AuthenticationService.swift    # User authentication service
│   ├── 📄 StravaService.swift            # Strava API integration
│   └── 📄 USDAService.swift              # USDA FoodData Central API
│
├── 📁 Utilities/                         # Helper utilities and extensions
│   ├── 📄 DateExtensions.swift           # Date helper methods
│   ├── 📄 NumberExtensions.swift         # Number formatting and conversions
│   ├── 📄 ColorExtensions.swift          # SwiftUI Color utilities
│   ├── 📄 ViewExtensions.swift           # SwiftUI View extensions
│   ├── 📄 NetworkMonitor.swift           # Network connectivity monitor
│   ├── 📄 KeychainHelper.swift           # Secure storage (tokens, keys)
│   └── 📄 Logger.swift                   # Structured logging utility
│
└── 📁 Resources/                         # Assets and resources
    ├── 📄 Info.plist                     # App configuration (privacy, URL schemes)
    └── 📁 Assets.xcassets/               # Images, colors, icons (to be added)
```

## File Descriptions

### Root Files

| File | Purpose | Key Features |
|------|---------|--------------|
| `HealthApp.swift` | App entry point | SwiftUI App protocol, initializes Supabase, injects AppState |
| `AppState.swift` | Global state | Authentication status, current user, sign out |
| `ContentView.swift` | Root view | Routes between auth and main app based on state |
| `Package.swift` | Dependencies | Supabase Swift SDK configuration |

### Config Folder

| File | Purpose |
|------|---------|
| `Configuration.swift` | Stores all API keys, URLs, and app constants. **Must be configured before running!** |

### Models Folder

| File | Represents | Key Properties |
|------|-----------|----------------|
| `User.swift` | User profile | Weight, height, age, gender, activity level, BMR, TDEE |
| `FoodEntry.swift` | Food log | Food name, macros (calories, protein, carbs, fat), meal type |
| `Activity.swift` | Exercise activity | Name, type, duration, distance, calories burned |
| `ProgressPhoto.swift` | Progress photo | Photo URL, weight, notes, date taken |
| `DailySummary.swift` | Daily summary | Target calories, consumed, burned, macros, counts |
| `StravaModels.swift` | Strava API models | Token response, athlete, activities |
| `USDAModels.swift` | USDA API models | Food search results, nutrients |

### Views Folder

| File | Screen | Features |
|------|--------|----------|
| `AuthenticationView.swift` | Login/Signup | Email/password fields, toggle mode, error handling |
| `MainTabView.swift` | Tab container | 5 tabs: Home, Calendar, Add, Activities, Profile |
| `HomeView.swift` | Home dashboard | Calorie summary card, macros, quick actions, recent entries |
| `CalendarView.swift` | Calendar | Date picker, daily summaries |
| `AddFoodView.swift` | Food logging | USDA search, quick add options |
| `ActivitiesView.swift` | Activities list | Strava connection, activity cards with stats |
| `ProfileView.swift` | Profile/Settings | User info, stats, integrations, sign out |

### ViewModels Folder

| File | Purpose | Published Properties |
|------|---------|---------------------|
| `AuthenticationViewModel.swift` | Auth logic | email, password, isLoading, errorMessage |
| `HomeViewModel.swift` | Home logic | dailySummary, foodEntries, activities |

### Services Folder

| File | Purpose | Key Methods |
|------|---------|-------------|
| `SupabaseClient.swift` | Supabase singleton | Access to auth, database, storage |
| `AuthenticationService.swift` | User authentication | signUp, signIn, signOut, getCurrentUser |
| `StravaService.swift` | Strava API | OAuth flow, get activities, token exchange |
| `USDAService.swift` | USDA API | Search foods, get food details |

### Utilities Folder

| File | Purpose | Key Features |
|------|---------|--------------|
| `DateExtensions.swift` | Date helpers | startOfDay, isToday, relativeString, currentWeekDates |
| `NumberExtensions.swift` | Number formatting | Unit conversions (kg/lbs, cm/inches), calorie/gram strings |
| `ColorExtensions.swift` | Color utilities | Hex init, app color palette, macro colors |
| `ViewExtensions.swift` | View modifiers | cardStyle, hideKeyboard, conditional modifiers |
| `NetworkMonitor.swift` | Network status | Monitor connectivity, connection type |
| `KeychainHelper.swift` | Secure storage | Save/retrieve tokens, clear all |
| `Logger.swift` | Logging | Structured logging with categories and levels |

## Architecture Overview

### MVVM Pattern

```
┌─────────────────┐
│     Views       │  SwiftUI views for UI
│   (UI Layer)    │
└────────┬────────┘
         │
         │ ObservableObject
         │ @Published
         │
┌────────▼────────┐
│   ViewModels    │  Presentation logic
│ (Logic Layer)   │  State management
└────────┬────────┘
         │
         │ Calls methods
         │
┌────────▼────────┐
│    Services     │  Business logic
│  (Data Layer)   │  API integration
└────────┬────────┘
         │
         │ Returns/updates
         │
┌────────▼────────┐
│     Models      │  Data structures
│  (Data Objects) │  Business logic
└─────────────────┘
```

### Data Flow

1. **User Action** → View captures user interaction
2. **View** → Calls ViewModel method
3. **ViewModel** → Calls Service for data/business logic
4. **Service** → Makes API call (Supabase, Strava, USDA)
5. **Service** → Returns Model objects
6. **ViewModel** → Updates @Published properties
7. **View** → Automatically re-renders with new data

### State Management

- **Local State**: `@State` in views for UI-only state
- **ViewModel State**: `@Published` properties in ViewModels
- **Global State**: `AppState` for authentication and user
- **Reactive**: Combine framework for data streams

## Key Features by File

### Authentication Flow
- `AuthenticationView.swift` → `AuthenticationViewModel.swift` → `AuthenticationService.swift` → Supabase Auth

### Food Logging Flow
- `AddFoodView.swift` → Search USDA API → Select food → Create `FoodEntry` → Save to Supabase

### Activity Sync Flow
- `ActivitiesView.swift` → Connect Strava → `StravaService.swift` → Fetch activities → Create `Activity` objects → Save to Supabase

### Daily Summary
- `HomeView.swift` → `HomeViewModel.swift` → Load `DailySummary` → Display calorie progress

### Profile & BMR/TDEE
- `ProfileView.swift` → Edit `User` stats → Auto-calculate BMR/TDEE → Update Supabase

## Dependencies

### External Packages (via SPM)

- **Supabase Swift SDK** (`https://github.com/supabase/supabase-swift`)
  - Auth: User authentication
  - Database (PostgrestClient): PostgreSQL queries
  - Storage: File uploads (progress photos)

### System Frameworks

- **SwiftUI**: UI framework
- **Combine**: Reactive programming
- **Foundation**: Core utilities
- **Network**: Network monitoring
- **Security**: Keychain access
- **os.log**: System logging

## Next Steps

1. **Open in Xcode**: Create a new iOS App project
2. **Copy Files**: Add all files to appropriate folders
3. **Add Dependencies**: Install Supabase Swift SDK via SPM
4. **Configure**: Update `Configuration.swift` with your API keys
5. **Set Up Supabase**: Create tables using SQL from README
6. **Build & Run**: Test the app!

## File Count Summary

- **Total Files**: 39 Swift files + config files
- **Models**: 7 files
- **Views**: 7 files
- **ViewModels**: 2 files
- **Services**: 4 files
- **Utilities**: 7 files
- **Config**: 1 file
- **Resources**: 1 file (+ assets folder)

## Code Statistics (Approximate)

- **Total Lines of Code**: ~3,500 lines
- **Average File Size**: ~90 lines
- **Largest Files**: 
  - `HomeView.swift` (~400 lines with components)
  - `User.swift` (~150 lines)
  - `USDAModels.swift` (~120 lines)

---

**Last Updated**: December 25, 2025
**Version**: 1.0.0

