# Testing & Debugging Guide

This guide covers all the testing and debugging tools available in the Netfuel app.

## Table of Contents

1. [Preview Data](#preview-data)
2. [Debug Menu](#debug-menu)
3. [Enhanced Logging](#enhanced-logging)
4. [Unit Tests](#unit-tests)
5. [UI Tests](#ui-tests)
6. [Test Scenarios](#test-scenarios)

---

## Preview Data

**File:** `Healthapp/Utilities/PreviewData.swift`

Mock data for SwiftUI previews and testing. All models have sample instances.

### Available Mock Data

```swift
// Users
PreviewData.sampleUser        // Complete male user profile
PreviewData.femaleUser        // Female user profile
PreviewData.incompleteUser    // User without profile data

// Food Logs
PreviewData.breakfastLog      // Oatmeal with banana
PreviewData.lunchLog          // Chicken salad
PreviewData.dinnerLog         // Salmon with rice
PreviewData.snackLog          // Greek yogurt
PreviewData.allFoodLogs       // Array of all meals

// Activities
PreviewData.morningRun        // 8km morning run
PreviewData.eveningCycle      // 25km bike ride
PreviewData.gymWorkout        // Strength training
PreviewData.allActivities     // Array of all activities

// Daily Summaries
PreviewData.todaySummary      // Today's summary
PreviewData.yesterdaySummary  // Yesterday's data
PreviewData.allSummaries      // Last 7 days

// Progress Photos
PreviewData.recentPhoto       // Recent progress photo
PreviewData.allPhotos         // All photos

// Settings
PreviewData.defaultSettings   // Default TDEE settings
PreviewData.customSettings    // Custom calorie target
```

### Generator Methods

```swift
// Generate multiple items for testing
PreviewData.generateFoodLogs(count: 10, for: userId)
PreviewData.generateActivities(count: 5, for: userId)
PreviewData.generateDailySummaries(days: 30, for: userId)
```

### Using in Previews

```swift
#Preview {
    HomeView(userId: PreviewData.sampleUser.id)
        .environmentObject(AppState(user: PreviewData.sampleUser))
}
```

---

## Debug Menu

**File:** `Healthapp/Views/DebugMenuView.swift`

In-app debugging interface (DEBUG builds only). Access via **Settings → Developer Tools → Debug Menu**.

### Features

#### 1. Data Management
- **Clear UserDefaults** - Reset all app preferences
- **Clear Keychain** - Remove stored tokens
- **Reset Onboarding** - See onboarding flow again
- **Clear Image Cache** - Free up cached images
- **Clear Offline Queue** - Remove pending sync actions
- **Clear ALL Data** - Nuclear option (cannot be undone)

#### 2. Sample Data
- **Add Sample Food Logs** - Populate with test food entries
- **Add Sample Activities** - Add test workouts
- **Add Sample Photos** - Add placeholder photos
- **Populate All** - Add complete test dataset

#### 3. Notifications
- **Trigger Test Notification** - Send immediate test notification
- **Trigger Daily Reminder** - Test daily logging reminder
- **Trigger Weekly Summary** - Test weekly progress notification
- **Clear All Notifications** - Remove pending and delivered

#### 4. Authentication
- **View User ID** - Display current user UUID
- **View Session Token** - See auth token (first 50 chars)
- **Refresh Session** - Force session refresh

#### 5. Network Simulation
- **Enable Network Logging** - Log all HTTP requests/responses
- **Mock Network Failures** - Simulate 500 errors
- **Simulate Slow Network** - Add 1-10s delay to requests

#### 6. Logging
- **Verbose Logging** - Enable detailed logs
- **Export Logs** - Save logs to file and share
- **Clear Logs** - Remove all logged entries
- **Log Count** - See number of log entries

#### 7. Environment Info
- App Version, Build Number
- Bundle ID
- Device Model, iOS Version
- Supabase URL

#### 8. Test Scenarios
- **First-Time User** - Clear all data, show onboarding
- **Returning User** - Set up with sample data
- **User Without Strava** - Remove Strava connection
- **Offline Mode** - Simulate no network

---

## Enhanced Logging

**File:** `Healthapp/Utilities/DebugLogger.swift`

Advanced logging with persistence and network tracking.

### Usage

```swift
// Basic logging
DebugLogger.shared.log(
    "User logged in",
    level: .info,
    category: .auth
)

// With metadata
DebugLogger.shared.log(
    "API request failed",
    level: .error,
    category: .network,
    metadata: ["statusCode": "500", "url": "/api/food"]
)

// Network request logging
DebugLogger.shared.logNetworkRequest(
    url: "https://api.example.com/users",
    method: "POST",
    headers: ["Content-Type": "application/json"],
    body: requestData
)

// Network response logging
DebugLogger.shared.logNetworkResponse(
    url: "https://api.example.com/users",
    statusCode: 200,
    data: responseData
)

// Error logging
DebugLogger.shared.logError(
    error,
    context: "Failed to fetch food logs",
    category: .database
)

// Performance timing
let timer = DebugLogger.shared.startPerformanceTimer(identifier: "calculateBMR")
// ... expensive operation ...
timer.stop()
```

### Features

- **Persistent Logs** - Saved to disk, survive app restarts
- **Network Logging** - Automatic request/response tracking
- **Performance Timing** - Measure operation duration
- **Export** - Share logs via email or files
- **Max 1000 entries** - Auto-cleanup old logs

### Log File Location

Logs saved to: `Documents/debug_logs.json`

---

## Unit Tests

**Files:** `HealthappTests/*.swift`

Test business logic, calculations, and data transformations.

### Running Tests

```bash
# In Xcode
CMD + U

# Via command line
xcodebuild test \
  -project Healthapp.xcodeproj \
  -scheme Healthapp \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Test Coverage

#### 1. BMR/TDEE Calculations (`BMRTDEECalculationTests.swift`)

```swift
// Tests the Mifflin-St Jeor equation
testBMRCalculation_Male()
testBMRCalculation_Female()
testBMRCalculation_Other()

// Tests TDEE multipliers
testTDEECalculation_Sedentary()       // 1.2x
testTDEECalculation_LightlyActive()   // 1.375x
testTDEECalculation_ModeratelyActive() // 1.55x
testTDEECalculation_VeryActive()      // 1.725x
testTDEECalculation_ExtraActive()     // 1.9x

// Edge cases
testBMRCalculation_IncompleteData()
testBMRCalculation_ExtremeWeight()
```

#### 2. Macro Calculations (`MacroCalculationTests.swift`)

```swift
// Food log calculations
testTotalCalories_SingleServing()
testTotalCalories_MultipleServings()
testServingDescription()

// Daily summary calculations
testDailySummary_TotalCaloriesBurned()
testDailySummary_NetCalories()
testDailySummary_IsInSurplus()
testDailySummary_CaloriesVsGoal()
testDailySummary_MetCalorieGoal()

// Activity formatting
testActivity_FormattedDuration()
testActivity_FormattedDistance()
testActivity_FormattedPace()
```

#### 3. Unit Conversions (`UnitConversionTests.swift`)

```swift
// Weight conversions
testWeightConversion_KgToLbs()
testWeightConversion_LbsToKg()
testWeightConversion_RoundTrip()

// Height conversions
testHeightConversion_CmToFeet()
testHeightConversion_FeetToCm()

// Distance conversions
testDistanceConversion_MetersToKm()
testDistanceConversion_MetersToMiles()

// Settings persistence
testUserSettings_SaveAndLoad()
testUserSettings_DefaultValues()
```

### Writing New Tests

```swift
import XCTest
@testable import Healthapp

final class MyFeatureTests: XCTestCase {

    override func setUpWithError() throws {
        // Setup before each test
    }

    override func tearDownWithError() throws {
        // Cleanup after each test
    }

    func testMyFeature() {
        // Given - Setup test data
        let user = PreviewData.sampleUser

        // When - Perform action
        let result = user.calculateBMR()

        // Then - Assert expectations
        XCTAssertNotNil(result)
        XCTAssertEqual(result, 1780.0, accuracy: 0.01)
    }
}
```

---

## UI Tests

**Files:** `HealthappUITests/*.swift`

Test complete user flows and interactions.

### Running UI Tests

```bash
# In Xcode
aaa (runs all tests including UI)

# Run only UI tests
xcodebuild test \
  -project Healthapp.xcodeproj \
  -scheme Healthapp \
  -only-testing:HealthappUITests
```

### Test Coverage

#### 1. Authentication Flow (`AuthenticationUITests.swift`)

```swift
// Sign up
testSignUpFlow_Success()
testSignUpFlow_ValidationErrors()
testSignUpFlow_InvalidEmail()

// Sign in
testSignInFlow_Success()
testSignInFlow_InvalidCredentials()
testSignInFlow_TogglePasswordVisibility()

// Navigation
testNavigation_SwitchBetweenSignInAndSignUp()

// Keyboard
testKeyboardHandling_DismissOnReturn()
testKeyboardHandling_DismissOnTapOutside()
```

#### 2. Food Logging Flow (`FoodLoggingUITests.swift`)

```swift
// Custom food entry
testAddCustomFood_Success()
testAddCustomFood_ValidationErrors()
testAddCustomFood_ServingsMultiplier()

// USDA search
testUSDAFoodSearch_SearchAndSelect()
testUSDAFoodSearch_NoResults()

// Meal types
testMealTypeSelection_AllTypes()

// Editing & deleting
testEditFoodLog()
testDeleteFoodLog()

// Summary display
testDailySummaryDisplay()
testPullToRefresh()
```

#### 3. Profile Setup Flow (`ProfileSetupUITests.swift`)

```swift
// Complete flow
testCompleteProfileSetup_Success()
testProfileSetup_ValidationErrors()
testProfileSetup_BMRTDEECalculation()

// Unit preferences
testProfileSetup_WeightUnitToggle()
testProfileSetup_HeightUnitToggle()

// Selections
testProfileSetup_ActivityLevelSelection()
testProfileSetup_GenderSelection()

// Validation
testProfileSetup_NumericFieldValidation()
testProfileSetup_ReasonableRanges()
```

### Writing UI Tests

```swift
import XCTest

final class MyUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launchEnvironment = ["TEST_MODE": "true"]
    }

    func testMyFeature() throws {
        app.launch()

        // Find and tap button
        let button = app.buttons["My Button"]
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        button.tap()

        // Enter text
        let textField = app.textFields["Name"]
        textField.tap()
        textField.typeText("John")

        // Verify navigation
        XCTAssertTrue(app.navigationBars["Next Screen"].exists)
    }
}
```

---

## Test Scenarios

**File:** `Healthapp/Utilities/TestScenarios.swift`

Configure app for different user states and testing conditions.

### Available Scenarios

#### 1. User States

```swift
// First-time user (onboarding required)
TestScenarios.shared.setupFirstTimeUser()

// Returning user with complete profile
TestScenarios.shared.setupReturningUser()

// User without Strava connection
TestScenarios.shared.setupUserWithoutStrava()

// User with no activities today
TestScenarios.shared.setupUserWithNoActivitiesToday()

// User with sample data
TestScenarios.shared.setupUserWithSampleData()
```

#### 2. Network Conditions

```swift
// Offline mode
TestScenarios.shared.setupOfflineMode()

// Slow network (3s delay)
TestScenarios.shared.setupSlowNetwork(delaySeconds: 3.0)

// Network failures (all requests fail)
TestScenarios.shared.setupNetworkFailures()

// Reset network simulation
TestScenarios.shared.resetNetworkSimulation()
```

#### 3. Data Population

```swift
// Add sample food logs
TestScenarios.shared.populateSampleFoodLogs(
    userId: user.id,
    count: 10
)

// Add sample activities
TestScenarios.shared.populateSampleActivities(
    userId: user.id,
    count: 5
)

// Add daily summaries
TestScenarios.shared.populateSampleDailySummaries(
    userId: user.id,
    days: 30
)
```

#### 4. Error Scenarios

```swift
// Simulate authentication error
TestScenarios.shared.simulateAuthenticationError()

// Simulate database error
TestScenarios.shared.simulateDatabaseError()

// Reset error simulations
TestScenarios.shared.resetErrorSimulations()
```

### Launch Arguments

Configure scenarios via launch arguments for UI testing:

```swift
// In XCTest
app.launchArguments = ["--uitesting", "--new-user"]
app.launchEnvironment = ["RESET_APP_STATE": "true"]

// Available arguments:
// --uitesting          - Enable UI testing mode
// --new-user           - First-time user scenario
// --authenticated      - Returning user scenario
// --offline            - Offline mode
// --slow-network       - Slow network simulation
// --with-sample-data   - Populate sample data

// Available environment variables:
// RESET_APP_STATE=true - Clear all data
// TEST_USER_ID=uuid    - Use specific user ID
```

### Network Simulation

The `NetworkSimulator` class provides network condition helpers:

```swift
// In your networking code
if NetworkSimulator.shared.shouldFailRequest {
    throw NetworkSimulator.shared.getSimulatedError()!
}

await NetworkSimulator.shared.simulateDelay()

// Then make actual request
let data = try await URLSession.shared.data(from: url)
```

---

## Best Practices

### 1. Use Preview Data for Development

```swift
#Preview("Complete Profile") {
    ProfileView(user: PreviewData.sampleUser)
}

#Preview("Incomplete Profile") {
    ProfileView(user: PreviewData.incompleteUser)
}

#Preview("With Food Logs") {
    FoodListView(foodLogs: PreviewData.allFoodLogs)
}
```

### 2. Test Early, Test Often

- Run unit tests before committing
- Run UI tests before major releases
- Use Debug Menu during development
- Check logs when debugging issues

### 3. Leverage Test Scenarios

```swift
// In your app initialization (DEBUG only)
#if DEBUG
override init() {
    super.init()
    TestScenarios.shared.configureFromLaunchArguments()
}
#endif
```

### 4. Monitor Performance

```swift
let timer = DebugLogger.shared.startPerformanceTimer(
    identifier: "fetchFoodLogs"
)

let logs = try await foodService.fetchFoodLogs(...)

timer.stop(metadata: ["count": "\(logs.count)"])
// Logs: "Performance: fetchFoodLogs | duration=234.567ms | count=15"
```

### 5. Export Logs for Bug Reports

1. Go to **Settings → Developer Tools → Debug Menu**
2. Tap **Export Logs**
3. Share via email or save to Files
4. Attach to bug report

---

## Troubleshooting

### Tests Failing

1. **Clean build folder**: CMD + Shift + K
2. **Reset simulator**: Device → Erase All Content and Settings
3. **Check test data**: Verify PreviewData is up to date
4. **Review logs**: Check DebugLogger for errors

### Debug Menu Not Showing

- Debug Menu only appears in DEBUG builds
- Check scheme is set to Debug (not Release)
- Rebuild app if necessary

### UI Tests Timing Out

- Increase timeout values in test assertions
- Check for network dependencies
- Use TestScenarios to mock data instead of real API

### Network Simulation Not Working

- Verify UserDefaults keys are set
- Check NetworkSimulator.shared properties
- Ensure your network code checks simulation flags

---

## Summary

The Netfuel app now has comprehensive testing infrastructure:

✅ **Preview Data** - Mock data for all models
✅ **Debug Menu** - In-app debugging tools (DEBUG only)
✅ **Enhanced Logging** - Persistent logs with network tracking
✅ **Unit Tests** - 25+ tests for business logic
✅ **UI Tests** - Complete flow testing
✅ **Test Scenarios** - Easy setup for different states

All tools work together to make development, testing, and debugging easier!
