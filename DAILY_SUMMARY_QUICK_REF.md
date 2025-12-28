# 📋 Daily Summary System - Quick Reference

## 🚀 Quick Start

```swift
// Load today's summary
let viewModel = HomeViewModel(userId: yourUserId)
await viewModel.loadTodaySummary()

// Display in UI
if let summary = viewModel.dailySummary {
    Text("Net: \(summary.netCalories ?? 0) cal")
}
```

---

## 📊 Calculation Formula

```
Net Calories = Calories Consumed - (TDEE + Exercise)
```

---

## 🔄 Auto-Update Triggers

| Action | Trigger | Method |
|--------|---------|--------|
| Log food | ✅ Automatic | `FoodService.updateDailySummary()` |
| Delete food | ✅ Automatic | `FoodService.updateDailySummary()` |
| Sync Strava | ✅ Automatic | `StravaService.syncActivities()` |
| Update profile | ⚠️ Manual | `viewModel.recalculateAfterProfileUpdate()` |

---

## 📁 Files

| File | Purpose |
|------|---------|
| `DailySummaryService.swift` | Core calculation logic |
| `DailySummaryViewModel.swift` | SwiftUI state management |
| `HomeViewModel.swift` | Display today's summary |
| `daily_summary_triggers.sql` | Optional DB triggers |

---

## 🎯 Common Tasks

### Load Today
```swift
await viewModel.loadTodaySummary()
```

### Load Week
```swift
await viewModel.loadWeekSummaries()
```

### Force Recalculate
```swift
await viewModel.forceRecalculate()
```

### Refresh After Food Change
```swift
await viewModel.recalculateAfterFoodChange()
```

### Refresh After Strava Sync
```swift
await viewModel.recalculateAfterActivitySync(dates: [Date()])
```

---

## 🗄️ Database

**Table**: `daily_summaries`

**Key Columns**:
- `user_id` + `date` (composite unique)
- `calories_consumed`
- `calories_burned_bmr`
- `calories_burned_exercise`
- `net_calories`

**Query**:
```sql
SELECT * FROM daily_summaries 
WHERE user_id = 'YOUR_ID' 
AND date = CURRENT_DATE;
```

---

## 🐛 Troubleshooting

| Issue | Fix |
|-------|-----|
| Summary shows 0 | Check user profile (BMR/TDEE) |
| Not updating | Check console for errors |
| Exercise missing | Sync Strava activities |
| Build error | Verify files in Xcode project |

---

## 📚 Full Documentation

- **DAILY_SUMMARY_GUIDE.md** - Complete guide
- **DAILY_SUMMARY_SETUP.md** - Setup instructions
- **DAILY_SUMMARY_COMPLETE.md** - Implementation summary

---

## ✅ Checklist

- [ ] Database schema created
- [ ] App builds successfully
- [ ] Can load today's summary
- [ ] Summary updates after food log
- [ ] Summary updates after Strava sync
- [ ] HomeView displays summary

---

**Need help?** See full documentation in `DAILY_SUMMARY_GUIDE.md`

