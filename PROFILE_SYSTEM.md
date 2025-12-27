# Profile System Documentation

## Overview

The profile system manages user physical stats, calculates BMR/TDEE, and provides first-time user onboarding and ongoing profile management.

---

## Architecture

### Components

1. **ProfileService** - Handles all Supabase database operations
2. **ProfileViewModel** - Manages state, validation, and business logic
3. **ProfileSetupView** - First-time user onboarding
4. **EditProfileView** - Edit existing profile
5. **ProfileView** - Display profile and settings

---

## Features

### ✅ ProfileService (`Services/ProfileService.swift`)

Handles all profile-related database operations with Supabase.

#### Methods:

```swift
// Fetch user profile
func fetchProfile(userId: UUID) async throws -> User

// Create new profile (first-time setup)
func createProfile(
    userId: UUID,
    weight: Double,
    height: Double,
    age: Int,
    gender: Gender,
    activityLevel: ActivityLevel
) async throws -> User

// Update existing profile
func updateProfile(
    userId: UUID,
    weight: Double?,
    height: Double?,
    age: Int?,
    gender: Gender?,
    activityLevel: ActivityLevel?
) async throws -> User

// Quick weight update
func updateWeight(userId: UUID, weight: Double) async throws -> User

// Calculate BMR (Mifflin-St Jeor equation)
func calculateBMR(weight: Double, height: Double, age: Int, gender: Gender) -> Double

// Calculate TDEE
func calculateTDEE(bmr: Double, activityLevel: ActivityLevel) -> Double
```

#### Key Features:
- ✅ Full CRUD operations for user profiles
- ✅ Automatic BMR/TDEE calculation on create/update
- ✅ Proper error handling with `ProfileError` enum
- ✅ Console logging for debugging
- ✅ Matches database schema exactly

---

### ✅ ProfileViewModel (`ViewModels/ProfileViewModel.swift`)

Manages profile state and provides reactive UI updates.

#### Published Properties:

```swift
@Published var weight: String
@Published var height: String
@Published var age: String
@Published var gender: Gender
@Published var activityLevel: ActivityLevel
@Published var useMetric: Bool // Toggle between metric/imperial
@Published var isLoading: Bool
@Published var errorMessage: String?
@Published var successMessage: String?
@Published var calculatedBMR: Double?
@Published var calculatedTDEE: Double?
```

#### Key Methods:

```swift
// Load existing profile into form
func loadCurrentProfile()

// Create new profile (first-time)
func createProfile() async

// Update existing profile
func updateProfile() async

// Quick weight update
func updateWeight() async

// Toggle between metric/imperial
func toggleUnits()
```

#### Key Features:
- ✅ Real-time BMR/TDEE calculation as user types
- ✅ Automatic unit conversion (kg ↔ lbs, cm ↔ inches)
- ✅ Comprehensive input validation
- ✅ Loading states and error handling
- ✅ Debounced calculations (300ms) for performance
- ✅ Proper Combine integration

---

### ✅ ProfileSetupView (`Views/ProfileSetupView.swift`)

Beautiful onboarding flow for first-time users.

#### UI Components:
- **Header** with icon and description
- **Unit Toggle** (Metric ↔ Imperial)
- **Weight Input** with large, readable font
- **Height Input** with unit display
- **Age Input** with year label
- **Gender Picker** (segmented control)
- **Activity Level Selector** (custom list with descriptions)
- **Calculated Values Display** (BMR and TDEE cards)
- **Complete Setup Button** with loading state

#### UX Features:
- ✅ Keyboard focus management
- ✅ Auto-advance on field submission
- ✅ Dismiss keyboard on tap outside
- ✅ Real-time validation feedback
- ✅ Large, easy-to-read input fields
- ✅ Gradient colors for visual appeal
- ✅ Shadow effects for depth
- ✅ Cannot be dismissed until profile is complete
- ✅ Automatic dismissal on success

---

### ✅ EditProfileView (`Views/EditProfileView.swift`)

Enhanced profile editing with same features as ProfileSetupView.

#### Updates:
- ✅ Uses `ProfileViewModel` for state management
- ✅ Real Supabase database updates (no more TODO!)
- ✅ Unit toggle (metric ↔ imperial)
- ✅ Real-time BMR/TDEE calculation
- ✅ Beautiful, modern UI matching ProfileSetupView
- ✅ Proper keyboard management
- ✅ Success/error messages
- ✅ Auto-dismiss on successful save

---

### ✅ ContentView Integration (`Views/ContentView.swift`)

Automatic profile flow management.

```swift
if appState.isAuthenticated {
    if let user = appState.currentUser, user.hasCompleteProfile {
        MainTabView() // ← User has complete profile
    } else {
        ProfileSetupView(appState: appState) // ← First-time or incomplete
    }
} else {
    AuthenticationView() // ← Not signed in
}
```

#### Flow:
1. User signs up/in → `isAuthenticated = true`
2. Check `user.hasCompleteProfile`
3. If incomplete → Show `ProfileSetupView`
4. User completes profile → Saves to Supabase
5. `AppState.currentUser` updated → `hasCompleteProfile = true`
6. Automatically transitions to `MainTabView`

---

## User Flow

### First-Time User Journey

```
Sign Up
   ↓
[ProfileSetupView]
   ↓
Enter weight, height, age
   ↓
Select gender, activity level
   ↓
See calculated BMR/TDEE
   ↓
Tap "Complete Setup"
   ↓
Save to Supabase
   ↓
[MainTabView]
```

### Existing User Journey

```
Sign In
   ↓
Fetch profile from Supabase
   ↓
Check hasCompleteProfile
   ↓
[MainTabView]
   ↓
Navigate to Profile
   ↓
Tap "Edit Profile"
   ↓
[EditProfileView]
   ↓
Update stats
   ↓
Tap "Save"
   ↓
Update Supabase
   ↓
Back to Profile
```

---

## BMR/TDEE Calculations

### Mifflin-St Jeor Equation (BMR)

```
For Men:   BMR = (10 × weight_kg) + (6.25 × height_cm) - (5 × age) + 5
For Women: BMR = (10 × weight_kg) + (6.25 × height_cm) - (5 × age) - 161
For Other: BMR = (10 × weight_kg) + (6.25 × height_cm) - (5 × age) - 78
```

### Activity Level Multipliers (TDEE)

| Activity Level | Multiplier | Description |
|----------------|------------|-------------|
| Sedentary | 1.2 | Little or no exercise |
| Lightly Active | 1.375 | 1-3 days/week |
| Moderately Active | 1.55 | 3-5 days/week |
| Very Active | 1.725 | 6-7 days/week |
| Extra Active | 1.9 | Physical job + exercise |

```
TDEE = BMR × Activity Multiplier
```

### Example:
- Weight: 70 kg
- Height: 175 cm
- Age: 30
- Gender: Male
- Activity: Moderately Active

```
BMR = (10 × 70) + (6.25 × 175) - (5 × 30) + 5
    = 700 + 1093.75 - 150 + 5
    = 1648.75 cal/day

TDEE = 1648.75 × 1.55
     = 2555.56 cal/day
```

---

## Unit Conversions

### Weight
```swift
kg to lbs: weight_kg × 2.20462
lbs to kg: weight_lbs × 0.453592
```

### Height
```swift
cm to inches: height_cm / 2.54
inches to cm: height_inches × 2.54
```

### Toggle Behavior
When user taps unit toggle:
1. Current value is converted
2. TextField updates with new value
3. BMR/TDEE recalculated automatically
4. Unit labels update (kg/lbs, cm/in)

---

## Database Schema

### `users` Table

```sql
CREATE TABLE public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    weight DECIMAL(5,2),           -- kg
    height DECIMAL(5,2),           -- cm
    age INTEGER CHECK (age > 0 AND age < 150),
    gender TEXT CHECK (gender IN ('male', 'female', 'other')),
    activity_level TEXT CHECK (activity_level IN (
        'sedentary',
        'lightly_active',
        'moderately_active',
        'very_active',
        'extra_active'
    )),
    bmr DECIMAL(7,2),              -- Basal Metabolic Rate
    tdee DECIMAL(7,2),             -- Total Daily Energy Expenditure
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);
```

### Database Triggers

The database automatically calculates BMR/TDEE using triggers:

```sql
CREATE TRIGGER update_user_bmr_tdee
BEFORE INSERT OR UPDATE ON public.users
FOR EACH ROW
EXECUTE FUNCTION update_user_bmr_tdee();
```

This ensures:
- ✅ BMR/TDEE always calculated server-side
- ✅ Consistency between client and server calculations
- ✅ No manual calculation required on insert/update

---

## Validation

### Weight
- ✅ Required field
- ✅ Must be numeric
- ✅ Range: 0-500 kg (0-1100 lbs)
- ✅ Displayed with 1 decimal place

### Height
- ✅ Required field
- ✅ Must be numeric
- ✅ Range: 0-300 cm (0-120 inches)
- ✅ Displayed with 0 decimal places

### Age
- ✅ Required field
- ✅ Must be integer
- ✅ Range: 1-150 years

### Gender
- ✅ Required field
- ✅ Options: Male, Female, Other

### Activity Level
- ✅ Required field
- ✅ 5 predefined options with descriptions

---

## Error Handling

### ProfileService Errors

```swift
enum ProfileError: LocalizedError {
    case fetchFailed(String)
    case createFailed(String)
    case updateFailed(String)
    case invalidData
    case userNotFound
}
```

### User-Facing Messages
- ✅ Clear, actionable error messages
- ✅ Field-specific validation feedback
- ✅ Network error handling
- ✅ Success confirmation messages

---

## Testing

### Test Scenarios

#### 1. First-Time User Setup
```
1. Sign up new account
2. Verify ProfileSetupView appears
3. Fill in all fields
4. Verify BMR/TDEE calculate in real-time
5. Tap "Complete Setup"
6. Verify profile saved to Supabase
7. Verify MainTabView appears
```

#### 2. Profile Update
```
1. Sign in existing user
2. Go to Profile → Edit Profile
3. Change weight
4. Verify BMR/TDEE update
5. Tap "Save"
6. Verify Supabase updated
7. Verify ProfileView shows new values
```

#### 3. Unit Conversion
```
1. Open ProfileSetupView or EditProfileView
2. Enter weight: 70 kg
3. Tap unit toggle
4. Verify displays: 154.3 lbs
5. Tap toggle again
6. Verify displays: 70.0 kg
```

#### 4. Validation
```
1. Try to save empty weight → Error
2. Try to save negative age → Error
3. Try to save height 500 cm → Error
4. Fill all fields correctly → Success
```

#### 5. Incomplete Profile
```
1. Sign up but DON'T complete profile
2. Sign out
3. Sign in again
4. Verify ProfileSetupView appears (not MainTabView)
```

---

## API Reference

### ProfileService

```swift
// Initialize
let service = ProfileService()

// Fetch profile
let user = try await service.fetchProfile(userId: userUUID)

// Create profile
let newUser = try await service.createProfile(
    userId: userUUID,
    weight: 70.0,
    height: 175.0,
    age: 30,
    gender: .male,
    activityLevel: .moderatelyActive
)

// Update profile
let updatedUser = try await service.updateProfile(
    userId: userUUID,
    weight: 72.0  // Only update weight
)

// Calculate BMR
let bmr = service.calculateBMR(
    weight: 70.0,
    height: 175.0,
    age: 30,
    gender: .male
)

// Calculate TDEE
let tdee = service.calculateTDEE(
    bmr: 1648.75,
    activityLevel: .moderatelyActive
)
```

### ProfileViewModel

```swift
// Initialize
let viewModel = ProfileViewModel(appState: appState)

// Create profile (first-time)
await viewModel.createProfile()

// Update profile
await viewModel.updateProfile()

// Quick weight update
await viewModel.updateWeight()

// Toggle units
viewModel.toggleUnits()

// Check if form is complete
if viewModel.isProfileComplete {
    // Enable save button
}
```

---

## UI/UX Guidelines

### Design Principles
- ✅ **Clear & Simple** - Large input fields, obvious actions
- ✅ **Feedback** - Real-time calculations, immediate validation
- ✅ **Accessibility** - High contrast, readable fonts
- ✅ **Efficiency** - Smart defaults, keyboard shortcuts
- ✅ **Polish** - Shadows, gradients, smooth animations

### Typography
- Input fields: 28-32pt, semibold
- Labels: subheadline, medium weight
- Calculated values: 28-32pt, bold
- Units: title3, secondary color

### Colors
- BMR card: Blue gradient
- TDEE card: Green gradient
- Backgrounds: System background with shadows
- Errors: Red text
- Success: Green text

### Spacing
- Section padding: 16-20pt
- Input padding: 16pt
- Card padding: 16pt
- Vertical spacing: 8-16pt

---

## Future Enhancements

### Potential Features
- [ ] Goal weight tracking
- [ ] Weight history chart
- [ ] Export profile data
- [ ] Share profile with friends
- [ ] Profile photo upload
- [ ] Body fat percentage
- [ ] Macronutrient targets
- [ ] Calorie goal calculator (deficit/surplus)
- [ ] Weekly weight average
- [ ] Progress predictions

---

## Troubleshooting

### Issue: Profile not saving
**Check**:
1. Network connection
2. Supabase credentials in `Configuration.swift`
3. RLS policies on `users` table
4. Console logs for detailed error

### Issue: BMR/TDEE not calculating
**Check**:
1. All fields filled (weight, height, age, gender, activity level)
2. Values are valid numbers
3. User model's `calculateBMR()` method
4. Database trigger `update_user_bmr_tdee`

### Issue: Unit conversion incorrect
**Check**:
1. Conversion factors (kg ↔ lbs: 2.20462, cm ↔ in: 2.54)
2. `ProfileViewModel.toggleUnits()` logic
3. Display formatting (%.1f for weight, %.0f for height)

### Issue: ProfileSetupView doesn't appear
**Check**:
1. `User.hasCompleteProfile` property
2. `ContentView` logic
3. User profile in Supabase (may have incomplete data)

---

## Support Files

- `Models/User.swift` - User model with calculations
- `Services/ProfileService.swift` - Supabase operations
- `ViewModels/ProfileViewModel.swift` - State management
- `Views/ProfileSetupView.swift` - First-time onboarding
- `Views/EditProfileView.swift` - Profile editing
- `Views/ProfileView.swift` - Profile display
- `Views/ContentView.swift` - Root navigation

---

## Summary

✅ **Complete profile management system**
✅ **First-time user onboarding**
✅ **Real-time BMR/TDEE calculation**
✅ **Unit conversion (metric ↔ imperial)**
✅ **Supabase database integration**
✅ **Beautiful, polished UI**
✅ **Comprehensive validation**
✅ **Error handling**
✅ **Loading states**
✅ **Success feedback**

The profile system is production-ready and provides a smooth, professional user experience! 🎉

