# Analytics & Trends Implementation Summary

## Overview
Complete analytics system for tracking health and fitness progress over time with interactive charts, statistics, and CSV export functionality.

## Files Created

### ViewModels/AnalyticsViewModel.swift
**Purpose**: Central data management and statistics calculation for all analytics views

**Key Features**:
- Fetches data for customizable time ranges (week, month, 3 months, year)
- Parallel async data loading for performance
- Comprehensive computed properties for statistics
- CSV export methods for all data types

**Time Ranges**:
```swift
enum TimeRange: String, CaseIterable {
    case week = "Week"           // 7 days
    case month = "Month"         // 30 days
    case threeMonths = "3 Months" // 90 days
    case year = "Year"           // 365 days
}
```

**Data Fetching**:
- `fetchDailySummaries()` - Weight, calories, macros from daily_summaries table
- `fetchFoodLogs()` - Individual food entries for detailed macro analysis
- `fetchActivities()` - Strava activities for exercise trends

**Weight Statistics**:
- `weightDataPoints` - Array of (date, weight) tuples
- `startingWeight` - First weight in range
- `currentWeight` - Most recent weight
- `weightChange` - Total change (kg)
- `averageWeeklyChange` - Weekly average change rate

**Calorie Statistics**:
- `netCalorieDataPoints` - Daily net calories
- `averageDailyNetCalories` - Mean net calories
- `totalNetCalories` - Sum of all net calories
- `daysInDeficit` - Count of deficit days
- `daysInSurplus` - Count of surplus days

**Macro Statistics**:
- `macroDataPoints` - Daily protein/carbs/fat
- `averageDailyProtein` - Mean protein intake
- `averageDailyCarbs` - Mean carb intake
- `averageDailyFat` - Mean fat intake

**Activity Statistics**:
- `totalActivitiesCount` - Total activities in range
- `totalExerciseCalories` - Sum of all exercise calories
- `activitiesByType` - Activities grouped by type
- `caloriesByType` - Calories grouped by type
- `mostActiveDay` - Day with most activities
- `activityFrequency` - Activities per day average

**CSV Export Methods**:
- `exportWeightCSV()` - Date, Weight (kg)
- `exportCaloriesCSV()` - Date, Net Calories, Consumed, Burned
- `exportMacrosCSV()` - Date, Protein, Carbs, Fat
- `exportActivitiesCSV()` - Date, Type, Name, Duration, Distance, Calories

---

### Views/AnalyticsView.swift
**Purpose**: Main container view with tab navigation

**Structure**:
```
AnalyticsView
  └─ AnalyticsContentView (@StateObject ViewModel)
      ├─ DateRangePicker (Week/Month/3 Months/Year)
      ├─ TabSelector (Weight/Calories/Macros/Activities)
      ├─ TabView (swipeable pages)
      │   ├─ WeightTrendView
      │   ├─ CalorieTrendView
      │   ├─ MacroTrendView
      │   └─ ActivityTrendView
      ├─ LoadingView (when fetching data)
      └─ EmptyAnalyticsView (no data state)
```

**Features**:
- ✅ Tab-based navigation with icons
- ✅ Swipeable pages with TabView
- ✅ Date range picker (4 options)
- ✅ Auto-refresh on range change
- ✅ Pull-to-refresh functionality
- ✅ Loading and empty states
- ✅ Error message display

**Usage**:
```swift
AnalyticsView(userId: userId)
```

---

### Views/WeightTrendView.swift
**Purpose**: Weight tracking with line chart visualization

**Components**:
1. **WeightStatsGrid** - 4 stat cards:
   - Starting Weight (kg)
   - Current Weight (kg)
   - Total Change (±kg)
   - Weekly Average (±kg/week)

2. **WeightChart** - Interactive line chart:
   - Line mark with gradient (blue to purple)
   - Area fill for visual depth
   - Point markers at each data point
   - Catmull-Rom interpolation for smooth curves
   - Formatted date axis (MMM d)
   - Weight axis with kg labels

3. **Export Functionality**:
   - CSV format: Date, Weight (kg)
   - Copy to clipboard
   - Share via ShareLink
   - Preview in modal sheet

**Empty State**:
Shows when no weight data exists with helpful message.

---

### Views/CalorieTrendView.swift
**Purpose**: Calorie tracking with bar chart visualization

**Components**:
1. **CalorieStatsGrid** - 4 stat cards:
   - Average Daily Net (cal)
   - Total Net (cal)
   - Days in Deficit (count)
   - Days in Surplus (count)

2. **NetCalorieChart** - Bar chart by day:
   - Green bars for deficit days
   - Red bars for surplus days
   - Zero reference line (dashed)
   - Date axis with formatted labels
   - Calorie axis with numeric values
   - Rounded bar corners

3. **WeeklySummary** - Weekly average chart:
   - Groups data by week
   - Bar chart of average net calories
   - Color-coded (green/red) by deficit/surplus
   - Week start dates as labels

4. **Export Functionality**:
   - CSV format: Date, Net Calories, Consumed, Burned
   - Copy to clipboard
   - Share via ShareLink

**Color Coding**:
- 🟢 Green = Calorie deficit (good for weight loss)
- 🔴 Red = Calorie surplus (weight gain)

---

### Views/MacroTrendView.swift
**Purpose**: Macronutrient tracking with multiple chart types

**Components**:
1. **MacroStatsGrid** - 3 stat cards + ratio card:
   - Average Protein (g)
   - Average Carbs (g)
   - Average Fat (g)
   - Macro Distribution (visual bar + percentages)

2. **ChartTypePicker** - Toggle between:
   - Line Chart (separate lines for each macro)
   - Stacked Chart (bars stacked by macro)

3. **MacroLineChart** - Multi-line visualization:
   - 🔴 Red line = Protein (circle markers)
   - 🔵 Blue line = Carbs (square markers)
   - 🟣 Purple line = Fat (triangle markers)
   - Catmull-Rom interpolation
   - Legend with color coding
   - Gram axis labels

4. **MacroStackedChart** - Stacked bar chart:
   - Each day shows total macros
   - Stacked by protein/carbs/fat
   - Color-coded sections
   - Visual breakdown of composition

5. **MacroRatioCard** - Distribution visualization:
   - Horizontal bar showing macro split
   - Percentage labels for each macro
   - Color-coded sections
   - Helps understand diet balance

6. **Export Functionality**:
   - CSV format: Date, Protein (g), Carbs (g), Fat (g)
   - Copy to clipboard
   - Share via ShareLink

**Macro Colors**:
- 🔴 Red = Protein
- 🔵 Blue = Carbs
- 🟣 Purple = Fat

---

### Views/ActivityTrendView.swift
**Purpose**: Activity tracking with distribution and frequency charts

**Components**:
1. **ActivityStatsGrid** - 4 stat cards:
   - Total Activities (count)
   - Total Calories (sum)
   - Average Frequency (activities/day)
   - Most Active Day (date + count)

2. **ActivityTypeChart** - Pie chart distribution:
   - Donut chart with inner radius
   - Color-coded by activity type
   - Legend with activity counts
   - Shows top 5 activity types
   - Hash-based color assignment for consistency

3. **CaloriesByTypeChart** - Horizontal bar chart:
   - Bars for each activity type
   - Gradient fill (orange to red)
   - Sorted by total calories
   - Shows calorie contribution per type

4. **ActivityFrequencySection** - Daily frequency chart:
   - Vertical bars for each day with activities
   - Shows count of activities per day
   - Identifies most active days
   - Gradient fill (blue to purple)

5. **Export Functionality**:
   - CSV format: Date, Type, Name, Duration (min), Distance (km), Calories
   - Copy to clipboard
   - Share via ShareLink

**Activity Types**:
Examples: Run, Ride, Swim, Walk, Hike, etc. (from Strava)

---

## Integration

### MainTabView.swift (Modified)
Added Analytics tab to main navigation:

```swift
// Analytics Tab
if let userId = appState.currentUser?.id {
    AnalyticsView(userId: userId)
        .tabItem {
            Label("Analytics", systemImage: "chart.line.uptrend.xyaxis")
        }
        .tag(Tab.analytics)
}
```

**Tab Order**:
1. Home
2. Calendar
3. Food (center)
4. Analytics ⭐ NEW
5. Activities
6. Profile

---

## Swift Charts Features Used

### Chart Types
- **LineMark** - Weight trends, macro trends
- **AreaMark** - Weight chart fill
- **BarMark** - Calorie bars, macro bars, frequency bars
- **SectorMark** - Activity type pie chart
- **PointMark** - Weight data points
- **RuleMark** - Zero reference lines

### Chart Customizations
- `.foregroundStyle()` - Colors and gradients
- `.interpolationMethod(.catmullRom)` - Smooth curves
- `.cornerRadius()` - Rounded bars
- `.innerRadius(.ratio(0.5))` - Donut charts
- `.symbol()` - Custom point shapes
- `.chartXAxis()` - Date formatting
- `.chartYAxis()` - Value formatting
- `.chartForegroundStyleScale()` - Legend colors

### Gradients
```swift
// Blue to purple gradient
LinearGradient(
    colors: [.blue, .purple],
    startPoint: .leading,
    endPoint: .trailing
)

// Orange to red gradient
LinearGradient(
    colors: [.orange, .red],
    startPoint: .leading,
    endPoint: .trailing
)
```

---

## Data Flow

```
User Opens Analytics Tab
    ↓
AnalyticsView loads
    ↓
AnalyticsViewModel.loadData()
    ↓
Parallel fetch (async let):
├─ fetchDailySummaries() → daily_summaries table
├─ fetchFoodLogs() → food_logs table
└─ fetchActivities() → activities table
    ↓
Data stored in @Published properties
    ↓
SwiftUI auto-updates all child views
    ↓
Charts render with data
```

**Refresh Flow**:
```
User pulls to refresh / changes time range
    ↓
viewModel.loadData()
    ↓
Re-fetch all data
    ↓
UI updates automatically
```

---

## Statistics Calculations

### Weight Trend
```swift
weightChange = currentWeight - startingWeight
averageWeeklyChange = weightChange / numberOfWeeks
```

### Calorie Trend
```swift
netCalories = caloriesConsumed - totalCaloriesBurned
averageDaily = sum(netCalories) / numberOfDays
```

### Macro Distribution
```swift
totalMacroGrams = protein + carbs + fat
proteinPercentage = (protein / totalMacroGrams) * 100
```

### Activity Frequency
```swift
activityFrequency = totalActivities / numberOfDays
```

---

## CSV Export Format

### Weight CSV
```csv
Date,Weight (kg)
2024-01-15,70.5
2024-01-16,70.3
```

### Calories CSV
```csv
Date,Net Calories,Consumed,Burned
2024-01-15,-500,2000,2500
2024-01-16,-350,2100,2450
```

### Macros CSV
```csv
Date,Protein (g),Carbs (g),Fat (g)
2024-01-15,150.0,200.0,65.0
2024-01-16,145.0,210.0,70.0
```

### Activities CSV
```csv
Date,Type,Name,Duration (min),Distance (km),Calories
2024-01-15,Run,Morning Run,30,5.00,300
2024-01-15,Ride,Evening Ride,45,15.50,450
```

---

## UI/UX Features

### Visual Design
- **Card-based layout** - Consistent throughout
- **Gradients** - Blue/purple for progress, orange/red for calories
- **Color coding** - Semantic colors (green=good, red=surplus)
- **Shadows** - Subtle depth (0.05 opacity, 8pt radius)
- **Rounded corners** - 12pt for cards, 4-8pt for elements
- **Icons** - SF Symbols for consistency

### Interactions
- ✅ Swipe between tabs
- ✅ Pull-to-refresh
- ✅ Tap to change date range
- ✅ Tap to switch chart types (macros)
- ✅ Tap export to open sheet
- ✅ Copy to clipboard
- ✅ Share via system sheet

### Responsive States
- **Loading** - Progress spinner with message
- **Empty** - Helpful icon and guidance text
- **Error** - Red text with error message
- **Data** - Full charts and statistics

### Accessibility
- SF Symbols for icons (auto-scaling)
- Semantic colors (red/green/blue)
- Clear labels and headers
- Readable font sizes (.caption to .title2)

---

## Performance Optimizations

1. **Parallel Data Loading**
   ```swift
   async let summariesTask = fetchDailySummaries(...)
   async let foodLogsTask = fetchFoodLogs(...)
   async let activitiesTask = fetchActivities(...)
   let (summaries, logs, acts) = try await (...)
   ```

2. **Computed Properties**
   - Calculate statistics on-demand
   - Cached by SwiftUI when data unchanged
   - No unnecessary recalculations

3. **Lazy Loading**
   - TabView only renders visible tab
   - Charts render on-demand
   - ScrollView lazy loads content

4. **Date Range Filtering**
   - Database-level filtering (WHERE clauses)
   - Only fetch necessary data
   - Reduces network transfer and memory

---

## Empty States

Each view includes an empty state when no data exists:

**WeightTrendView**: "No Weight Data - Start logging your daily weight..."
**CalorieTrendView**: "No Calorie Data - Start logging your food and activities..."
**MacroTrendView**: "No Macro Data - Start logging your food..."
**ActivityTrendView**: "No Activity Data - Sync your Strava activities..."

Each shows relevant icon and actionable guidance.

---

## Error Handling

- Network errors caught and displayed
- Database query errors shown to user
- Graceful degradation (missing data → empty state)
- Errors don't crash app or prevent other tabs from working

---

## Future Enhancements

Possible improvements:
- [ ] Goal weight tracking on weight chart
- [ ] Target macro lines on macro chart
- [ ] Comparison mode (this week vs last week)
- [ ] Custom date range picker
- [ ] Detailed activity breakdown (pace, heart rate)
- [ ] PDF export for comprehensive reports
- [ ] Trend predictions (linear regression)
- [ ] Achievement badges for milestones
- [ ] Weekly/monthly summary cards
- [ ] Annotations for significant events
- [ ] Zoom and pan on charts
- [ ] Export chart images

---

## Testing Checklist

Manual testing recommendations:

### Weight Tab
- [ ] Chart displays with at least 2 data points
- [ ] Statistics calculate correctly
- [ ] Empty state shows when no weight logged
- [ ] CSV export includes all weight entries
- [ ] Date range changes update chart

### Calories Tab
- [ ] Green bars show for deficit days
- [ ] Red bars show for surplus days
- [ ] Weekly summary groups correctly
- [ ] Statistics match data
- [ ] CSV includes consumed and burned

### Macros Tab
- [ ] Line chart shows all three macros
- [ ] Stacked chart displays correctly
- [ ] Chart type toggle works
- [ ] Macro ratio percentages sum to 100%
- [ ] Legend colors match lines

### Activities Tab
- [ ] Pie chart shows activity distribution
- [ ] Bar chart shows calories by type
- [ ] Frequency chart identifies active days
- [ ] Most active day is accurate
- [ ] CSV includes all activity details

### General
- [ ] Tab navigation works smoothly
- [ ] Swipe between tabs functional
- [ ] Date range picker updates all tabs
- [ ] Pull-to-refresh fetches new data
- [ ] Loading state appears during fetch
- [ ] Error messages display properly
- [ ] Export sheets open and close
- [ ] Copy to clipboard works
- [ ] Share sheet appears

---

## Database Dependencies

### Tables Used
- `daily_summaries` - Weight, calories, macros by date
- `food_logs` - Individual food entries
- `activities` - Strava activities

### Required Fields
**daily_summaries**:
- user_id, date, weight
- calories_consumed, total_calories_burned, net_calories
- protein_consumed, carbs_consumed, fat_consumed

**food_logs**:
- user_id, logged_at
- calories, protein, carbs, fat

**activities**:
- user_id, start_date, type, name
- duration, distance, calories

---

## Usage

### Navigate to Analytics
1. Open app
2. Tap "Analytics" tab (chart icon)
3. View defaults to Weight tab, Month range

### Change Time Range
1. Tap desired range (Week/Month/3 Months/Year)
2. All tabs update automatically

### Switch Between Tabs
1. Tap tab button (Weight/Calories/Macros/Activities)
2. Or swipe left/right to switch

### Export Data
1. Scroll to bottom of any tab
2. Tap "Export [Type] Data" button
3. Copy to clipboard or share

### Refresh Data
1. Pull down from top of screen
2. Data refreshes for current range

---

## Summary

The Analytics & Trends implementation provides:
- **Comprehensive tracking** - Weight, calories, macros, activities
- **Beautiful visualizations** - Line, bar, pie, stacked charts
- **Actionable statistics** - Averages, totals, trends
- **Flexible time ranges** - Week to year
- **Data export** - CSV format for all metrics
- **Great UX** - Loading states, empty states, smooth animations
- **Performance** - Parallel loading, efficient queries

The analytics system gives users deep insights into their health journey with professional-grade charts powered by Swift Charts framework.

---

Last Updated: December 28, 2024
