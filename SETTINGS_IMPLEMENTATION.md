# Settings & Preferences Implementation Summary

## Overview
Comprehensive settings screen with profile editing, goals management, unit preferences, integrations, account actions, and data export functionality.

## Files Created

### Models/UserSettings.swift
**Purpose**: User preference settings stored in UserDefaults

**Key Features**:
- Goals (calorie targets, macro targets, weight goal)
- Unit preferences (weight, height, distance)
- Codable for JSON persistence
- Automatic load/save to UserDefaults

**Settings Structure**:
```swift
struct UserSettings: Codable {
    // Goals
    var dailyCalorieTarget: Int?
    var proteinTargetGrams: Double?
    var carbsTargetGrams: Double?
    var fatTargetGrams: Double?
    var weightGoal: Double?

    // Units
    var weightUnit: WeightUnit = .kg
    var heightUnit: HeightUnit = .cm
    var distanceUnit: DistanceUnit = .km
}
```

**Unit Enums**:
- `WeightUnit`: kg, lbs (with conversion methods)
- `HeightUnit`: cm, feet+inches (with conversion methods)
- `DistanceUnit`: km, miles (with conversion methods)

**Persistence**:
```swift
// Load
let settings = UserSettings.load()

// Save
settings.save()

// Clear
UserSettings.clear()
```

---

### ViewModels/SettingsViewModel.swift
**Purpose**: Central state management for all settings

**Published Properties**:
- `settings: UserSettings` - User preferences
- `user: User?` - User profile from database
- `stravaConnection: StravaConnection?` - Strava integration status
- `lastStravaSync: Date?` - Last sync timestamp
- `isLoading: Bool` - Loading state
- `isSaving: Bool` - Saving state
- `errorMessage: String?` - Error display
- `successMessage: String?` - Success display

**Key Methods**:

**Data Loading**:
```swift
func loadData() async
// - Fetches user profile
// - Loads Strava connection
// - Gets last sync time
```

**Profile Management**:
```swift
func updateProfile(
    weight: Double? = nil,
    height: Double? = nil,
    age: Int? = nil,
    gender: User.Gender? = nil,
    activityLevel: User.ActivityLevel? = nil
) async
// - Updates user profile in Supabase
// - Recalculates BMR and TDEE
// - Shows success message
```

**Settings Management**:
```swift
func saveSettings()
// - Saves settings to UserDefaults
// - Shows success message
```

**Strava Integration**:
```swift
func disconnectStrava() async
func syncStravaActivities() async
```

**Account Actions**:
```swift
func changePassword(newPassword: String) async
func exportData() -> String // Returns CSV
func deleteAccount() async throws
func logOut() async
```

**Computed Properties**:
- `appVersion: String` - App version and build number
- `formattedLastSync: String` - Relative time string
- `calculatedBMR: Int` - From user profile
- `calculatedTDEE: Int` - From user profile
- `effectiveCalorieTarget: Int` - Custom or TDEE

---

### Views/SettingsView.swift
**Purpose**: Main settings container with navigation to all subsections

**Structure**:
```
SettingsView
  └─ Form
      ├─ Profile Section
      │   ├─ Edit Profile (NavigationLink)
      │   ├─ BMR Display
      │   └─ TDEE Display
      ├─ Goals Section
      │   └─ Goals & Targets (NavigationLink)
      ├─ Units Section
      │   └─ Units & Preferences (NavigationLink)
      ├─ Integrations Section
      │   └─ Strava Integration Row
      ├─ About Section
      │   ├─ Version
      │   ├─ Privacy Policy (Link)
      │   ├─ Terms of Service (Link)
      │   └─ Contact Support (Link)
      └─ Account Section
          ├─ Account & Security (NavigationLink)
          ├─ Export Data (Sheet)
          └─ Log Out (Button)
```

**Strava Integration Row**:
- Shows connection status
- Displays athlete name when connected
- Shows last sync time
- Sync Now button (with loading state)
- Disconnect button (with confirmation alert)
- Connect button when not connected

**Data Export Sheet**:
- Displays CSV preview
- Copy to clipboard button
- Share button (via ShareLink)
- Exports profile, settings, and Strava data

---

### Views/EditProfileSettingsView.swift
**Purpose**: Edit physical stats and activity level

**Form Fields**:
1. **Weight** (TextField with kg unit)
2. **Height** (TextField with cm unit)
3. **Age** (TextField with years unit)
4. **Gender** (Picker: Male, Female, Other)
5. **Activity Level** (Picker with descriptions)

**Activity Levels**:
- Sedentary: Little to no exercise
- Lightly Active: Exercise 1-3 days/week
- Moderately Active: Exercise 3-5 days/week
- Very Active: Exercise 6-7 days/week
- Extra Active: Very intense exercise daily

**Calculated Values Display**:
- BMR (auto-calculated)
- TDEE (auto-calculated)

**Validation**:
- All fields required
- Save button disabled until valid

**On Save**:
- Updates profile in Supabase
- Recalculates BMR/TDEE
- Shows success message
- Dismisses view

---

### Views/GoalsSettingsView.swift
**Purpose**: Set calorie and macro targets

**Calorie Target Section**:
- Toggle: Custom vs TDEE
- Custom: TextField for daily calories
- TDEE: Display calculated value

**Macro Targets Section**:
- Protein (grams + percentage)
- Carbs (grams + percentage)
- Fat (grams + percentage)
- Total calories from macros (with color coding)

**Percentages**:
- Auto-calculated based on grams and calorie target
- Green indicator when macros match target (±50 cal)

**Weight Goal Section**:
- Optional goal weight (kg)
- Shows difference from current weight
- Color coded (green if losing, red if gaining)

**Quick Presets**:
- Balanced (30/40/30)
- High Protein (40/30/30)
- Low Carb (35/20/45)
- Low Fat (30/50/20)

**Macro Calculations**:
```swift
// Protein: 4 cal/g
// Carbs: 4 cal/g
// Fat: 9 cal/g

proteinCal = proteinGrams * 4
carbsCal = carbsGrams * 4
fatCal = fatGrams * 9
totalMacroCalories = proteinCal + carbsCal + fatCal
```

---

### Views/UnitsSettingsView.swift
**Purpose**: Set unit preferences for weight, height, and distance

**Unit Sections**:

**Weight Unit**:
- Picker: Kilograms / Pounds
- Example conversion shown

**Height Unit**:
- Picker: Centimeters / Feet & Inches
- Example conversion shown

**Distance Unit**:
- Picker: Kilometers / Miles
- Example conversion shown (5000m = 5km or 3.11mi)

**Conversions**:
- All conversions handled by UserSettings model
- Examples use current user data when available
- Save updates UserDefaults immediately

---

### Views/AccountSettingsView.swift
**Purpose**: Account security and deletion

**Security Section**:
- Change Password (opens sheet)

**Danger Zone Section**:
- Delete Account (with double confirmation)

**Change Password Sheet**:
- New Password field (SecureField)
- Confirm Password field (SecureField)
- Requirements checklist:
  * At least 8 characters
  * Passwords match
- Save button (disabled until valid)
- Success message on completion

**Delete Account**:
- Alert with text confirmation
- Must type "DELETE" to confirm
- Permanently deletes:
  * User profile
  * Food logs
  * Activities
  * Progress photos
  * All settings
- Signs out user after deletion

---

## Integration

### ProfileView.swift (Modified)
Replaced placeholder "App Settings" with SettingsView:

```swift
Section("Settings") {
    if let userId = appState.currentUser?.id {
        NavigationLink {
            SettingsView(userId: userId)
        } label: {
            HStack {
                Image(systemName: "gear")
                    .foregroundColor(.gray)
                Text("Settings & Preferences")
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
```

Removed:
- "About" link (now in SettingsView)
- "Sign Out" button (now in SettingsView)
- `showingSignOutAlert` state (no longer needed)

---

### Services/ProfileService.swift (Modified)
Added account deletion method:

```swift
func deleteUserAccount(userId: UUID) async throws {
    try await supabase.client
        .from("users")
        .delete()
        .eq("id", value: userId.uuidString)
        .execute()
}
```

**Note**: Assumes database has CASCADE delete configured for foreign keys. All related records (food_logs, activities, etc.) should be deleted automatically via database constraints.

---

## Data Flow

### Settings Load
```
User opens Settings
    ↓
SettingsView appears
    ↓
SettingsViewModel.loadData()
    ↓
Parallel fetch:
├─ ProfileService.fetchProfile()
├─ StravaService.fetchConnection()
└─ StravaService.fetchActivitiesFromDatabase()
    ↓
Update @Published properties
    ↓
SwiftUI updates all UI
```

### Profile Update
```
User edits profile
    ↓
EditProfileSettingsView validates
    ↓
SettingsViewModel.updateProfile()
    ↓
Recalculate BMR & TDEE
    ↓
ProfileService.updateProfile()
    ↓
Update Supabase users table
    ↓
Show success message
    ↓
Dismiss view
```

### Settings Save
```
User changes preferences
    ↓
GoalsSettingsView/UnitsSettingsView
    ↓
Update viewModel.settings
    ↓
SettingsViewModel.saveSettings()
    ↓
UserSettings.save()
    ↓
Encode to JSON
    ↓
Store in UserDefaults
    ↓
Show success message
```

---

## Unit Conversions

### Weight Conversions
```swift
kg to lbs: kg * 2.20462
lbs to kg: lbs / 2.20462

Example:
70 kg = 154.3 lbs
154.3 lbs = 70 kg
```

### Height Conversions
```swift
cm to feet/inches:
totalInches = cm / 2.54
feet = totalInches / 12
inches = totalInches % 12

feet/inches to cm:
totalInches = (feet * 12) + inches
cm = totalInches * 2.54

Example:
175 cm = 5' 9"
5' 9" = 175 cm
```

### Distance Conversions
```swift
meters to km: meters / 1000
meters to miles: meters / 1609.34

Example:
5000 m = 5.00 km
5000 m = 3.11 mi
```

---

## CSV Export Format

```csv
Netfuel Data Export

PROFILE
Email,user@example.com
Weight,70.0 kg
Height,175.0 cm
Age,30
Gender,male
Activity Level,moderatelyActive
BMR,1650 cal
TDEE,2558 cal

SETTINGS
Daily Calorie Target,2200
Protein Target,165.0 g
Carbs Target,220.0 g
Fat Target,73.3 g
Weight Goal,68.0 kg
Weight Unit,Kilograms
Height Unit,Centimeters
Distance Unit,Kilometers

STRAVA
Connected,Yes
Athlete,John Doe
Connected At,January 15, 2024
```

---

## UI/UX Features

### Native iOS Design
- SwiftUI `Form` for settings layout
- Native pickers and text fields
- System colors and SF Symbols
- Standard list separators and grouping

### Input Validation
- Real-time validation feedback
- Disabled save buttons until valid
- Password strength indicators
- Field-specific keyboard types

### Loading States
- Progress spinners during saves
- Disabled buttons during operations
- Loading overlay for initial data fetch

### Success/Error Messages
- Auto-dismissing success messages (2 seconds)
- Persistent error messages with alerts
- Contextual error descriptions

### Confirmations
- Alert for Strava disconnect
- Double confirmation for account deletion
- Sign out moved to settings (removed from profile)

---

## Accessibility

### VoiceOver Support
- All buttons and links labeled
- Form fields with proper labels
- Meaningful icons with labels

### Dynamic Type
- All text supports Dynamic Type
- Layout adapts to text size changes

### Color Coding
- Not reliant on color alone
- Icons and text reinforce meaning
- Sufficient color contrast

---

## Performance

### Lazy Loading
- Settings load on-demand
- Subsections load when navigated to
- UserDefaults access is fast (cached)

### Efficient Updates
- Only save when user taps save
- Debounced success message clearing
- Minimal re-renders with @Published

### Database Queries
- Single query for profile load
- Batched updates where possible
- Proper error handling prevents crashes

---

## Future Enhancements

Possible improvements:
- [ ] Macro targets as percentages (not just grams)
- [ ] Custom calorie adjustment (±X from TDEE)
- [ ] Multiple weight goal milestones
- [ ] Notification preferences
- [ ] Data sync preferences
- [ ] Theme selection (light/dark/auto)
- [ ] Language selection
- [ ] Export to PDF (formatted report)
- [ ] Import data from CSV
- [ ] Backup to iCloud
- [ ] Two-factor authentication
- [ ] Biometric login
- [ ] Activity goal reminders

---

## Testing Checklist

### Profile Editing
- [ ] Weight field accepts decimal numbers
- [ ] Height field accepts whole numbers
- [ ] Age field accepts only positive integers
- [ ] Gender picker works correctly
- [ ] Activity level picker shows descriptions
- [ ] BMR recalculates on save
- [ ] TDEE recalculates on save
- [ ] Success message appears
- [ ] View dismisses after save

### Goals Setting
- [ ] Custom calorie toggle works
- [ ] TDEE display shows correct value
- [ ] Macro grams update percentages
- [ ] Percentages sum to ~100%
- [ ] Total calories match target (±50)
- [ ] Weight goal shows difference
- [ ] Quick presets calculate correctly
- [ ] Settings persist after app restart

### Units Preferences
- [ ] Weight unit picker works
- [ ] Height unit picker works
- [ ] Distance unit picker works
- [ ] Examples show correct conversions
- [ ] Settings persist after save

### Strava Integration
- [ ] Connection status displays correctly
- [ ] Athlete name shows when connected
- [ ] Last sync time formats correctly
- [ ] Sync button triggers refresh
- [ ] Sync button shows loading state
- [ ] Disconnect requires confirmation
- [ ] Connect button navigates correctly

### Account Actions
- [ ] Change password validates length
- [ ] Change password validates match
- [ ] Change password shows requirements
- [ ] Export data generates CSV
- [ ] Export data copies to clipboard
- [ ] Export data shares correctly
- [ ] Delete account requires "DELETE"
- [ ] Delete account removes data
- [ ] Delete account signs out user
- [ ] Log out signs out immediately

---

## Summary

The Settings & Preferences implementation provides:
- **Comprehensive profile editing** - Weight, height, age, gender, activity level
- **Flexible goal setting** - Custom calories, macro targets, weight goal
- **Unit preferences** - kg/lbs, cm/ft, km/mi with live conversions
- **Strava integration** - Connection status, sync, disconnect
- **Account security** - Password change, account deletion
- **Data export** - CSV export with all user data
- **Native iOS design** - Form-based layout with system components
- **Persistent storage** - UserDefaults for preferences, Supabase for profile
- **Great UX** - Validation, loading states, success/error messages

The settings system gives users complete control over their profile, goals, and preferences with a familiar iOS settings experience.

---

Last Updated: December 28, 2024
