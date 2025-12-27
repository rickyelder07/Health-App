# Model Migration Notes

## Overview

All data models have been updated to match the Supabase PostgreSQL database schema exactly. This document summarizes the changes and what was affected.

---

## Models Updated

### 1. User Model
**Removed Fields:**
- `fullName` - Not in database schema
- `stravaAccessToken`, `stravaRefreshToken`, `stravaTokenExpiresAt`, `stravaAthleteId` - Moved to separate `strava_connections` table

**Field Changes:**
- `email` is now optional (fetched from auth, not always in public.users)
- `bmr` and `tdee` are now stored properties (calculated by database trigger)

**New Methods:**
- `hasCompleteProfile` - Check if all required fields are filled

---

### 2. DailySummary Model
**Removed Fields:**
- `id` (UUID) - Now uses composite key (userId + date)
- `targetCalories` - No longer stored
- `consumedCalories` → Renamed to `caloriesConsumed`
- `burnedCalories` - Split into two fields
- `totalProtein` → Renamed to `proteinConsumed`
- `totalCarbohydrates` → Renamed to `carbsConsumed`
- `totalFat` → Renamed to `fatConsumed`
- `targetProtein`, `targetCarbohydrates`, `targetFat` - No longer stored
- `foodEntriesCount`, `activitiesCount` - No longer stored

**New Fields:**
- `weight` (optional) - Daily weight entry
- `caloriesBurnedBmr` - BMR calories
- `caloriesBurnedExercise` - Exercise calories
- `totalCaloriesBurned` (computed) - BMR + Exercise
- `netCalories` (computed) - Consumed - Burned

**ID Strategy:**
- Composite ID: `"\(userId)-\(date)"` for `Identifiable` conformance
- Database uses composite primary key `(user_id, date)`

---

### 3. FoodLog Model (alias: FoodEntry)
**Field Changes:**
- `numberOfServings` → Renamed to `servings`
- `mealType` is now optional
- `fdcId` → Renamed to `usdaFdcId`
- `carbohydrates` → Renamed to `carbs`
- `calories` is now `Int` instead of `Double`
- `servingSize` is now `String` instead of `Double`
- Removed `updatedAt` field (not in database)

**Computed Properties:**
- `totalCalories`, `totalProtein`, `totalCarbs`, `totalFat` (all multiplied by servings)
- `servingDescription` - Formatted serving string

---

### 4. Activity Model
**Field Changes:**
- `stravaActivityId` → Renamed to `stravaId` (now `Int64`)
- `activityType` → Renamed to `type`
- `duration` is now `Int` instead of `TimeInterval`
- `caloriesBurned` → Renamed to `calories` (now `Int`)
- `averageHeartRate` → Renamed to `averageHeartrate` (lowercase r)
- `maxHeartRate` → Renamed to `maxHeartrate` (now `Int`)
- Removed `updatedAt` field (not in database)

**New Fields:**
- `maxSpeed` - Maximum speed during activity

---

### 5. ProgressPhoto Model
**Field Changes:**
- `takenAt` → Renamed to `dateTaken`
- Removed `thumbnailUrl` field (not in database)
- Removed `updatedAt` field (not in database)

---

### 6. StravaConnection Model (NEW)
**New Model** for storing Strava OAuth tokens and athlete info:
- Moved from User model to separate table
- Primary key is `user_id` (not a UUID)
- Contains OAuth tokens and expiration
- Contains athlete information

---

## Files Updated

### ViewModels
- **AuthenticationViewModel.swift**
  - Removed manual User creation
  - Added `fetchUserProfile()` to query database
  - Now properly fetches user after authentication

- **HomeViewModel.swift**
  - Updated `DailySummary` creation to use new fields
  - Removed old field references

### Views
- **HomeView.swift**
  - Updated `CalorieSummaryCard` to use new DailySummary fields
  - Changed display from "remaining" to "surplus/deficit"
  - Updated `MacrosSummaryView` to use new macro field names
  - Updated `FoodEntryRow` for optional mealType and new field names

- **ProfileView.swift**
  - Removed `fullName` display, now uses email username
  - Removed direct Strava token check (TODO: query strava_connections)

- **EditProfileView.swift**
  - Removed `fullName` input field
  - Updated User creation to match new model
  - Removed Strava field references

### Utilities
- **DateFormatters.swift** (NEW)
  - Provides reusable date formatters
  - Provides `supabaseDecoder` and `supabaseEncoder`

- **DateExtensions.swift**
  - Added Supabase-specific formatting methods
  - `dateOnlyString`, `iso8601String`, `displayString`, `displayDateTimeString`

---

## Database Alignment

All models now perfectly match the database schema:

| Model | Table | Primary Key | Notes |
|-------|-------|-------------|-------|
| User | `public.users` | `id` (UUID) | Extends auth.users |
| StravaConnection | `public.strava_connections` | `user_id` (UUID) | One-to-one with users |
| Activity | `public.activities` | `id` (UUID) | `strava_id` is unique |
| FoodLog | `public.food_logs` | `id` (UUID) | Nutritional data |
| ProgressPhoto | `public.progress_photos` | `id` (UUID) | Storage URLs |
| DailySummary | `public.daily_summaries` | `(user_id, date)` | Composite key |

---

## Breaking Changes

### Authentication Flow
**Before:**
```swift
// Manually created user with all fields
let user = User(id: ..., email: ..., fullName: ..., stravaAccessToken: ...)
appState.setUser(user)
```

**After:**
```swift
// Fetch from database (created by trigger)
await fetchUserProfile(userId: session.user.id)
```

### User Display Name
**Before:**
```swift
Text(user.fullName ?? "User")
```

**After:**
```swift
Text(user.email?.components(separatedBy: "@").first?.capitalized ?? "User")
```

### DailySummary Access
**Before:**
```swift
summary.targetCalories
summary.consumedCalories
summary.isWithinBudget
summary.remainingCalories
```

**After:**
```swift
summary.caloriesConsumed
summary.totalCaloriesBurned ?? summary.calculateTotalCaloriesBurned()
summary.isInSurplus
summary.netCalories ?? summary.calculateNetCalories()
```

### FoodEntry/FoodLog
**Before:**
```swift
entry.numberOfServings
entry.mealType.icon
```

**After:**
```swift
entry.servings
entry.mealType?.icon ?? "fork.knife"
```

---

## Migration Checklist

✅ All models updated to match database schema  
✅ ViewModels updated for new model structure  
✅ Views updated for new field names  
✅ Date formatting utilities created  
✅ No linter errors  
✅ Authentication flow uses database fetch  
✅ Backward compatibility maintained where possible (type aliases)  

---

## Testing Recommendations

1. **Authentication Flow**
   - Sign up new user → Verify profile created in database
   - Sign in existing user → Verify profile fetched correctly
   - Update profile → Verify BMR/TDEE calculated by trigger

2. **Data Display**
   - Home screen displays correct calorie summary
   - Macros display correctly
   - Food entries show proper serving information

3. **Database Queries**
   - All Codable encoding/decoding works correctly
   - Date formats parse properly from Supabase
   - Composite keys work for DailySummary

---

Last Updated: December 26, 2024

