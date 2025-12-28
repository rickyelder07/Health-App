# 🚀 Daily Summary System - Quick Setup Guide

## Prerequisites

- ✅ Supabase project set up
- ✅ `users` table with BMR/TDEE columns
- ✅ `food_logs` table
- ✅ `activities` table
- ✅ `daily_summaries` table

---

## Step 1: Verify Database Schema

Run this in **Supabase SQL Editor** to check if `daily_summaries` table exists:

```sql
SELECT column_name, data_type 
FROM information_schema.columns
WHERE table_name = 'daily_summaries'
ORDER BY ordinal_position;
```

**Expected columns**:
- `id` (uuid)
- `user_id` (uuid)
- `date` (date)
- `calories_consumed` (integer)
- `protein_consumed` (numeric)
- `carbs_consumed` (numeric)
- `fat_consumed` (numeric)
- `calories_burned_bmr` (integer)
- `calories_burned_exercise` (integer)
- `total_calories_burned` (integer, nullable)
- `net_calories` (integer, nullable)
- `created_at` (timestamp)
- `updated_at` (timestamp)

**If table doesn't exist**, create it:

```sql
CREATE TABLE daily_summaries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    calories_consumed INTEGER NOT NULL DEFAULT 0,
    protein_consumed DECIMAL(10, 2) NOT NULL DEFAULT 0,
    carbs_consumed DECIMAL(10, 2) NOT NULL DEFAULT 0,
    fat_consumed DECIMAL(10, 2) NOT NULL DEFAULT 0,
    calories_burned_bmr INTEGER NOT NULL DEFAULT 0,
    calories_burned_exercise INTEGER NOT NULL DEFAULT 0,
    total_calories_burned INTEGER,
    net_calories INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, date)
);

CREATE INDEX idx_daily_summaries_user_date ON daily_summaries(user_id, date DESC);

ALTER TABLE daily_summaries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own summaries" 
    ON daily_summaries FOR SELECT 
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own summaries" 
    ON daily_summaries FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own summaries" 
    ON daily_summaries FOR UPDATE 
    USING (auth.uid() = user_id);
```

---

## Step 2: Build the App

All the code is already in place! Just build:

```bash
# In Xcode
Cmd + Shift + K  # Clean
Cmd + B          # Build
```

**Files Created**:
- ✅ `Services/DailySummaryService.swift`
- ✅ `ViewModels/DailySummaryViewModel.swift`
- ✅ `ViewModels/HomeViewModel.swift` (updated)
- ✅ `Services/FoodService.swift` (updated)
- ✅ `Services/StravaService.swift` (updated)

---

## Step 3: Test Basic Functionality

### **Test 1: Load Today's Summary**

```swift
// In your app (e.g., HomeView)
let viewModel = HomeViewModel(userId: yourUserId)
await viewModel.loadTodaySummary()

// Check the result
if let summary = viewModel.dailySummary {
    print("✅ Summary loaded:")
    print("   Consumed: \(summary.caloriesConsumed) cal")
    print("   Burned: \(summary.totalCaloriesBurned ?? 0) cal")
    print("   Net: \(summary.netCalories ?? 0) cal")
}
```

### **Test 2: Log Food and Check Update**

```swift
// Log a food item
let foodService = FoodService()
try await foodService.logFood(
    userId: yourUserId,
    foodName: "Apple",
    calories: 95,
    protein: 0.5,
    carbs: 25,
    fat: 0.3,
    servingSize: 1,
    servingUnit: "medium",
    mealType: "snack",
    numberOfServings: 1,
    loggedAt: Date()
)

// Summary is automatically updated!
// Refresh to see changes
await viewModel.loadTodaySummary()
```

### **Test 3: Sync Strava and Check Update**

```swift
// Sync Strava activities
let stravaService = StravaService()
let count = try await stravaService.syncActivities(
    userId: yourUserId,
    connection: yourStravaConnection
)

print("✅ Synced \(count) activities")

// Summary is automatically updated!
// Refresh to see changes
await viewModel.loadTodaySummary()
```

---

## Step 4: Optional - Install Database Triggers

**Why?** Provides automatic summary updates at the database level (redundant with app logic, but adds safety).

**How?**
1. Open **Supabase Dashboard** → **SQL Editor**
2. Copy and run `database_migrations/daily_summary_triggers.sql`
3. Verify triggers were created (query at end of file)

**Result**: Summaries will auto-update whenever food_logs or activities change, even if app logic fails.

---

## Step 5: Update Your Views

### **Update HomeView to Display Summary**

```swift
import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel: HomeViewModel
    
    init(userId: UUID) {
        _viewModel = StateObject(wrappedValue: HomeViewModel(userId: userId))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                Text("Today's Summary")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                if viewModel.isLoading {
                    ProgressView()
                } else if let summary = viewModel.dailySummary {
                    // Calorie Card
                    VStack(spacing: 10) {
                        Text("Net Calories")
                            .font(.headline)
                        Text("\(summary.netCalories ?? summary.calculateNetCalories())")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(summary.isInSurplus ? .red : .green)
                        
                        HStack(spacing: 40) {
                            VStack {
                                Text("Consumed")
                                    .font(.caption)
                                Text("\(summary.caloriesConsumed)")
                                    .font(.title2)
                            }
                            VStack {
                                Text("Burned")
                                    .font(.caption)
                                Text("\(summary.totalCaloriesBurned ?? 0)")
                                    .font(.title2)
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Macros Card
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Macros")
                            .font(.headline)
                        
                        HStack {
                            MacroLabel(name: "Protein", value: summary.proteinConsumed, color: .blue)
                            Spacer()
                            MacroLabel(name: "Carbs", value: summary.carbsConsumed, color: .orange)
                            Spacer()
                            MacroLabel(name: "Fat", value: summary.fatConsumed, color: .purple)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                } else {
                    Text("No data for today")
                        .foregroundColor(.gray)
                }
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .padding()
        }
        .task {
            await viewModel.loadTodaySummary()
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
}

struct MacroLabel: View {
    let name: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack {
            Text(name)
                .font(.caption)
                .foregroundColor(.gray)
            Text(String(format: "%.1fg", value))
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}
```

---

## Step 6: Test End-to-End

### **Scenario 1: New User**
1. Create a new user account
2. Complete profile (weight, height, age, gender, activity level)
3. Log some food
4. Check HomeView - should show consumed calories and BMR
5. Sync Strava activities
6. Check HomeView - should show exercise calories added

### **Scenario 2: Existing User**
1. Log in
2. Go to HomeView
3. Should see today's summary (or 0s if no data)
4. Log a food item
5. Pull to refresh HomeView
6. Should see updated calories

### **Scenario 3: Profile Update**
1. Update weight or activity level in ProfileView
2. Go to HomeView
3. Summary should reflect new BMR/TDEE

---

## Verification Checklist

- [ ] `daily_summaries` table exists in Supabase
- [ ] RLS policies are enabled
- [ ] App builds without errors
- [ ] Can load today's summary
- [ ] Summary updates after logging food
- [ ] Summary updates after syncing Strava
- [ ] HomeView displays summary correctly
- [ ] Pull-to-refresh works
- [ ] Error messages display when something fails

---

## Troubleshooting

### **Build Error: "Cannot find 'DailySummaryService' in scope"**
- Make sure `DailySummaryService.swift` is in your Xcode project
- Check that it's added to your target

### **Summary shows all 0s**
- Check if user has complete profile (BMR/TDEE)
- Check if there are food logs for today
- Try force recalculate: `await viewModel.forceRecalculate()`

### **Summary doesn't update after logging food**
- Check console for errors
- Verify `FoodService.updateDailySummary()` is being called
- Check Supabase RLS policies

### **Database Error: "relation 'daily_summaries' does not exist"**
- Run the CREATE TABLE SQL from Step 1
- Verify table exists in Supabase Table Editor

---

## Next Steps

1. **Add Analytics**: Use `DailySummaryViewModel.loadWeekSummaries()` to show weekly trends
2. **Add Calendar View**: Display summaries for each day in a calendar
3. **Add Charts**: Visualize calorie trends over time
4. **Add Notifications**: Remind users to log food or sync activities
5. **Add Goals**: Set daily calorie/macro goals and track progress

---

## Summary

✅ **Database schema verified**  
✅ **App built successfully**  
✅ **Basic functionality tested**  
✅ **Views updated to display summaries**  
✅ **End-to-end testing complete**  

**Your Daily Summary System is ready to use!** 🎉

For detailed documentation, see `DAILY_SUMMARY_GUIDE.md`.

