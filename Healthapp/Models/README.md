# Models Documentation

This directory contains all data models for the Health Tracker app. Each model corresponds to a table in the Supabase PostgreSQL database.

## Overview

All models conform to:
- `Codable` for JSON encoding/decoding with Supabase
- `Identifiable` for SwiftUI list rendering
- Use snake_case for database field mapping via `CodingKeys`

## Models

### 1. User

**File**: `User.swift`

Represents the user profile with physical stats and calculated metabolic values.

**Key Properties**:
- `id`: UUID (references `auth.users`)
- `email`: Optional email address
- `weight`, `height`, `age`, `gender`, `activityLevel`: Physical stats
- `bmr`, `tdee`: Calculated metabolic values (can be computed or stored)

**Methods**:
- `calculateBMR()`: Calculates Basal Metabolic Rate using Mifflin-St Jeor equation
- `calculateTDEE()`: Calculates Total Daily Energy Expenditure
- `hasCompleteProfile`: Checks if all required fields are filled

**Enums**:
- `Gender`: `.male`, `.female`, `.other`
- `ActivityLevel`: `.sedentary`, `.lightlyActive`, `.moderatelyActive`, `.veryActive`, `.extraActive`

**Usage**:
```swift
let user = User(
    id: UUID(),
    email: "user@example.com",
    weight: 70.0,
    height: 175.0,
    age: 30,
    gender: .male,
    activityLevel: .moderatelyActive,
    bmr: nil,
    tdee: nil,
    createdAt: Date(),
    updatedAt: Date()
)

if let bmr = user.calculateBMR() {
    print("BMR: \(bmr) calories/day")
}
```

---

### 2. StravaConnection

**File**: `StravaConnection.swift`

Stores Strava OAuth tokens and athlete information for activity syncing.

**Key Properties**:
- `userId`: UUID (primary key, references `users`)
- `accessToken`, `refreshToken`: OAuth tokens
- `expiresAt`: Token expiration timestamp
- `athleteId`, `athleteUsername`, `athleteFirstname`, `athleteLastname`: Strava athlete info

**Methods**:
- `needsRefresh`: Checks if token is expired or expiring soon
- `athleteFullName`: Returns formatted full name

**Usage**:
```swift
let connection = StravaConnection(
    userId: userId,
    accessToken: "token",
    refreshToken: "refresh",
    expiresAt: Date().addingTimeInterval(21600),
    athleteId: "12345",
    athleteUsername: "runner",
    athleteFirstname: "John",
    athleteLastname: "Doe",
    connectedAt: Date(),
    updatedAt: Date()
)

if connection.needsRefresh {
    // Refresh the token
}
```

---

### 3. Activity

**File**: `Activity.swift`

Represents an exercise activity synced from Strava.

**Key Properties**:
- `id`: UUID
- `userId`: UUID (references `users`)
- `stravaId`: Int64 (Strava activity ID)
- `name`, `type`: Activity details
- `duration`: Int (seconds)
- `distance`: Double? (meters)
- `calories`: Int
- `averageSpeed`, `maxSpeed`: Double? (m/s)
- `averageHeartrate`, `maxHeartrate`: Heart rate metrics
- `elevationGain`: Double? (meters)

**Computed Properties**:
- `formattedDuration`: Returns "HH:MM:SS" string
- `formattedDistance`: Returns "X.XX km" string
- `formattedPace`: Returns "M:SS /km" string
- `formattedSpeed`: Returns "X.X km/h" string

**Usage**:
```swift
let activity = Activity(
    id: UUID(),
    userId: userId,
    stravaId: 123456789,
    name: "Morning Run",
    type: "Run",
    startDate: Date(),
    duration: 1800,
    distance: 5000,
    calories: 300,
    averageSpeed: 2.78,
    maxSpeed: 3.5,
    averageHeartrate: 145.5,
    maxHeartrate: 165,
    elevationGain: 50.0,
    createdAt: Date()
)

print(activity.formattedDuration) // "30:00"
print(activity.formattedDistance) // "5.00 km"
```

---

### 4. FoodLog (alias: FoodEntry)

**File**: `FoodEntry.swift`

Represents a logged food item with nutritional information.

**Key Properties**:
- `id`: UUID
- `userId`: UUID (references `users`)
- `foodName`, `brandName`: Food identification
- `servingSize`, `servingUnit`: Serving information
- `calories`: Int (per serving)
- `protein`, `carbs`, `fat`: Double (macros in grams)
- `fiber`, `sugar`, `sodium`: Optional micronutrients
- `servings`: Double (multiplier, default 1.0)
- `mealType`: MealType? (breakfast, lunch, dinner, snack)
- `usdaFdcId`: String? (USDA FoodData Central ID)

**Computed Properties**:
- `totalCalories`, `totalProtein`, `totalCarbs`, `totalFat`: Values × servings
- `servingDescription`: Formatted serving string

**Enum**:
- `MealType`: `.breakfast`, `.lunch`, `.dinner`, `.snack`

**Usage**:
```swift
let foodLog = FoodLog(
    id: UUID(),
    userId: userId,
    foodName: "Brown Rice",
    brandName: nil,
    servingSize: "100",
    servingUnit: "g",
    calories: 110,
    protein: 2.6,
    carbs: 23.0,
    fat: 0.9,
    fiber: 1.8,
    sugar: 0.4,
    sodium: 5.0,
    servings: 1.5,
    mealType: .lunch,
    usdaFdcId: "168878",
    loggedAt: Date(),
    createdAt: Date()
)

print(foodLog.totalCalories) // 165.0
print(foodLog.servingDescription) // "1.5 × 100 g"
```

---

### 5. ProgressPhoto

**File**: `ProgressPhoto.swift`

Stores progress photos with metadata for tracking visual changes.

**Key Properties**:
- `id`: UUID
- `userId`: UUID (references `users`)
- `photoUrl`: String (Supabase Storage URL)
- `weight`: Double? (weight at time of photo)
- `notes`: String? (optional notes)
- `dateTaken`: Date (when photo was taken)

**Computed Properties**:
- `formattedDate`: Returns formatted date string

**Usage**:
```swift
let photo = ProgressPhoto(
    id: UUID(),
    userId: userId,
    photoUrl: "https://..../photo.jpg",
    weight: 70.5,
    notes: "Feeling great!",
    dateTaken: Date(),
    createdAt: Date()
)
```

---

### 6. DailySummary

**File**: `DailySummary.swift`

Aggregates daily nutrition and activity data.

**Key Properties**:
- `userId`: UUID (references `users`)
- `date`: Date (composite primary key with userId)
- `weight`: Double? (daily weight entry)
- `caloriesConsumed`, `proteinConsumed`, `carbsConsumed`, `fatConsumed`: Nutrition totals
- `caloriesBurnedBmr`, `caloriesBurnedExercise`: Calorie burn sources
- `totalCaloriesBurned`, `netCalories`: Computed fields (generated in DB)

**Methods**:
- `calculateTotalCaloriesBurned()`: Manual calculation if not from DB
- `calculateNetCalories()`: Manual calculation if not from DB

**Computed Properties**:
- `isInSurplus`, `isInDeficit`: Calorie balance status
- `formattedDate`: Returns formatted date string

**Usage**:
```swift
let summary = DailySummary(
    userId: userId,
    date: Date(),
    weight: 70.2,
    caloriesConsumed: 2000,
    proteinConsumed: 150.0,
    carbsConsumed: 200.0,
    fatConsumed: 65.0,
    caloriesBurnedBmr: 1650,
    caloriesBurnedExercise: 300,
    totalCaloriesBurned: 1950,
    netCalories: 50,
    createdAt: Date(),
    updatedAt: Date()
)

if summary.isInSurplus {
    print("Calorie surplus today")
}
```

---

## Date Handling

**File**: `Utilities/DateFormatters.swift`

All models use ISO8601 date formatting for Supabase compatibility.

**Custom Decoders/Encoders**:
```swift
// Decode from Supabase
let decoder = DateFormatters.supabaseDecoder
let user = try decoder.decode(User.self, from: jsonData)

// Encode for Supabase
let encoder = DateFormatters.supabaseEncoder
let jsonData = try encoder.encode(user)
```

**Date Extensions**:
```swift
let date = Date()
print(date.dateOnlyString) // "2024-01-15"
print(date.iso8601String) // "2024-01-15T10:30:45Z"
print(date.displayString) // "January 15, 2024"
print(date.isToday) // true/false
```

---

## Database Schema Alignment

All models are designed to match the Supabase database schema exactly:

| Model | Database Table | Primary Key | Notable Fields |
|-------|---------------|-------------|----------------|
| User | `public.users` | `id` (UUID) | Extends `auth.users` |
| StravaConnection | `public.strava_connections` | `user_id` (UUID) | OAuth tokens |
| Activity | `public.activities` | `id` (UUID) | `strava_id` unique |
| FoodLog | `public.food_logs` | `id` (UUID) | Nutrition data |
| ProgressPhoto | `public.progress_photos` | `id` (UUID) | Storage URLs |
| DailySummary | `public.daily_summaries` | `(user_id, date)` | Composite key |

---

## Best Practices

1. **Always use snake_case in CodingKeys** to match PostgreSQL naming convention
2. **Use DateFormatters.supabaseDecoder** when decoding from Supabase
3. **Handle optionals gracefully** - many fields are nullable in the database
4. **Computed properties should be pure** - no side effects
5. **Type aliases** (like `FoodEntry = FoodLog`) maintain backward compatibility

---

## Testing Models

```swift
import XCTest

class ModelTests: XCTestCase {
    func testUserBMRCalculation() {
        let user = User(/* ... */)
        let bmr = user.calculateBMR()
        XCTAssertEqual(bmr, 1650, accuracy: 10)
    }
    
    func testFoodLogServings() {
        let food = FoodLog(/* ... */)
        XCTAssertEqual(food.totalCalories, 165.0)
    }
}
```

---

## Migration Notes

If database schema changes:
1. Update the model's properties
2. Update `CodingKeys` enum
3. Run database migration SQL
4. Test encoding/decoding with new schema
5. Update this documentation

---

Last Updated: December 26, 2024

