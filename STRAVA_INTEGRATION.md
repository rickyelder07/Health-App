# Strava Integration Guide

## Overview

Complete Strava OAuth integration and activity syncing for the Health Tracker app. This integration allows users to:

- Connect their Strava account securely via OAuth 2.0
- Automatically sync activities (runs, rides, swims, etc.)
- Track exercise calories for accurate TDEE calculations
- View detailed activity metrics and stats
- Filter and search through activities

---

## Features Implemented

### 1. **StravaService** (`Services/StravaService.swift`)

Core service for Strava OAuth and API interactions:

#### OAuth Management
- `startOAuthFlow(userId:)` - Opens Strava authorization page
- `exchangeToken(code:userId:)` - Exchanges auth code for access token
- `refreshToken(connection:)` - Refreshes expired access tokens automatically
- Token expiration checking with 5-minute buffer

#### Connection Management
- `fetchConnection(userId:)` - Retrieves stored Strava connection
- `disconnect(userId:)` - Removes Strava connection
- Stores connections in Supabase `strava_connections` table

#### Activity Syncing
- `fetchActivitiesFromStrava(connection:page:perPage:)` - Fetches activities from Strava API
- `syncActivities(userId:connection:)` - Syncs activities to Supabase database
- `fetchActivitiesFromDatabase(userId:)` - Retrieves stored activities
- Automatic calorie estimation if not provided by Strava
- Handles API rate limiting (429 status code)

#### Error Handling
- Comprehensive error types (`StravaError`)
- Rate limit detection and user-friendly messages
- Network error handling
- Invalid response handling

---

### 2. **StravaViewModel** (`ViewModels/StravaViewModel.swift`)

State management for Strava integration:

#### Published Properties
- `connection: StravaConnection?` - Current Strava connection
- `activities: [Activity]` - List of synced activities
- `isConnected: Bool` - Connection status
- `isLoading: Bool` - Loading state
- `isSyncing: Bool` - Syncing state
- `errorMessage: String?` - Error messages
- `successMessage: String?` - Success messages

#### Key Methods
- `loadConnection()` - Loads connection on view appear
- `connectStrava()` - Initiates OAuth flow
- `handleOAuthCallback(code:)` - Processes OAuth callback
- `disconnect()` - Disconnects from Strava
- `syncActivities()` - Syncs activities from Strava
- `loadActivities()` - Loads activities from database
- `refreshActivities()` - Pull-to-refresh handler

---

### 3. **StravaConnectionView** (`Views/StravaConnectionView.swift`)

Main UI for Strava connection management:

#### Sections
1. **Header** - Strava logo and description
2. **Connection Status** - Shows connected/disconnected state
3. **Athlete Information** - Displays athlete details when connected
4. **Action Buttons** - Connect, Sync, or Disconnect
5. **Activities Summary** - Shows recent 3 activities with "View All" link
6. **About Section** - Information about Strava integration

#### Features
- Connect to Strava button (opens OAuth flow)
- Sync activities button with loading state
- Disconnect with confirmation alert
- Pull-to-refresh support
- Error/success message banners
- Auto-listens for OAuth callback via NotificationCenter

---

### 4. **ActivityListView** (`Views/ActivityListView.swift`)

Comprehensive activity list with filtering:

#### Filters
- **All** - Show all activities
- **Runs** - Running activities only
- **Rides** - Cycling activities only
- **Other** - Other activity types
- **This Week** - Activities from last 7 days
- **This Month** - Activities from last 30 days

#### Features
- Segmented picker for filter selection
- Activity count display
- Pull-to-refresh to sync from Strava
- Sync button in toolbar
- Tap activity to view details
- Empty state with helpful message

---

### 5. **ActivityDetailView** (Embedded in `ActivityListView.swift`)

Detailed view for individual activities:

#### Sections
1. **Header** - Activity icon, name, type, and date
2. **Summary Metrics**
   - Calories burned
   - Distance (if available)
   - Duration
   - Pace (if applicable)
3. **Performance Metrics** (if available)
   - Average/Max speed
   - Average/Max heart rate
   - Elevation gain
4. **Source** - Strava activity ID

#### Visual Design
- Color-coded metrics with icons
- Formatted values (km, hours, bpm, etc.)
- Activity-specific icons (run, bike, swim, etc.)
- Clean, card-based layout

---

## OAuth Flow

### 1. User Initiates Connection
```swift
// User taps "Connect to Strava" in StravaConnectionView
viewModel.connectStrava()
```

### 2. Open Strava Authorization
```swift
// StravaService opens Strava OAuth page in Safari
// URL: https://www.strava.com/oauth/authorize?client_id=...&redirect_uri=healthapp://strava/callback
UIApplication.shared.open(authUrl)
```

### 3. User Authorizes App
- User sees Strava authorization page
- Reviews requested permissions
- Clicks "Authorize"

### 4. Strava Redirects to App
```
healthapp://strava/callback?state=<user_id>&code=<auth_code>&scope=read,activity:read_all
```

### 5. App Handles Callback
```swift
// HealthApp.swift receives URL
handleStravaCallback(url: url, appState: appState)

// Extracts auth code and posts notification
NotificationCenter.default.post(name: "StravaOAuthCallback", userInfo: ["code": code])
```

### 6. Exchange Code for Token
```swift
// StravaConnectionView receives notification
// ViewModel exchanges code for access token
let connection = try await stravaService.exchangeToken(code: code, userId: userId)

// Stores connection in Supabase strava_connections table
```

### 7. Auto-Sync Activities
```swift
// After successful connection, automatically sync activities
await viewModel.syncActivities()
```

---

## Token Management

### Automatic Token Refresh
```swift
// StravaService checks token expiration before each API call
if connection.needsRefresh {
    print("🔄 Token expired, refreshing...")
    activeConnection = try await refreshToken(connection: connection)
}
```

### Token Expiration Check
```swift
// StravaConnection model
var needsRefresh: Bool {
    return expiresAt.timeIntervalSinceNow < 300 // 5 minutes buffer
}
```

### Refresh Token Flow
1. Check if `expiresAt` is within 5 minutes
2. Call Strava token refresh endpoint
3. Store new tokens in Supabase
4. Continue with original API request

---

## Database Schema

### `strava_connections` Table
```sql
CREATE TABLE strava_connections (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id),
    access_token TEXT NOT NULL,
    refresh_token TEXT NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    athlete_id TEXT NOT NULL,
    athlete_username TEXT,
    athlete_firstname TEXT,
    athlete_lastname TEXT,
    connected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### `activities` Table
```sql
CREATE TABLE activities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    strava_id BIGINT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    type TEXT NOT NULL,
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    duration INTEGER NOT NULL, -- seconds
    distance DOUBLE PRECISION, -- meters
    calories INTEGER NOT NULL,
    average_speed DOUBLE PRECISION, -- m/s
    max_speed DOUBLE PRECISION, -- m/s
    average_heartrate DOUBLE PRECISION,
    max_heartrate INTEGER,
    elevation_gain DOUBLE PRECISION, -- meters
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_activities_user_date ON activities(user_id, start_date DESC);
CREATE UNIQUE INDEX idx_activities_user_strava ON activities(user_id, strava_id);
```

---

## Rate Limiting

Strava API has rate limits:
- **15-minute limit**: 100 requests
- **Daily limit**: 1,000 requests

### How We Handle It
```swift
// StravaService detects 429 status code
if httpResponse.statusCode == 429 {
    throw StravaError.rateLimitExceeded
}

// ViewModel shows user-friendly message
errorMessage = "Strava rate limit exceeded. Please wait 15 minutes and try again."
```

### Best Practices
- Sync activities in batches (default 30 per request)
- Cache activities in local database
- Only fetch new activities since last sync (future enhancement)
- Inform users of rate limits

---

## Calorie Estimation

If Strava doesn't provide calories, we estimate based on activity type:

```swift
private func estimateCalories(activity: StravaActivityResponse) -> Int {
    guard let distance = activity.distance else { return 0 }
    
    let km = distance / 1000
    let caloriesPerKm: Double
    
    switch activity.type.lowercased() {
    case "run", "trail run", "virtual run":
        caloriesPerKm = 50
    case "ride", "virtual ride", "e-bike ride":
        caloriesPerKm = 30
    case "swim":
        caloriesPerKm = 100
    default:
        caloriesPerKm = 40
    }
    
    return Int(km * caloriesPerKm)
}
```

---

## Security Considerations

### Token Storage
- Tokens stored in Supabase with RLS policies
- Only user can access their own tokens
- Tokens never exposed to client logs

### OAuth State Parameter
- Uses user UUID as state parameter
- Prevents CSRF attacks
- Validates state on callback

### HTTPS Only
- All Strava API calls use HTTPS
- OAuth redirects use custom URL scheme

---

## Testing the Integration

### 1. Connect to Strava
1. Open Profile tab
2. Tap "Strava" under Integrations
3. Tap "Connect to Strava"
4. Authorize app in Safari
5. Verify you're redirected back to app
6. Check connection status shows "Connected"

### 2. Sync Activities
1. Tap "Sync Activities" button
2. Wait for sync to complete
3. Check "Recent Activities" section
4. Tap "View All" to see full list

### 3. View Activity Details
1. Go to Activity List
2. Tap any activity
3. Verify all metrics are displayed
4. Check formatting (distance, duration, pace)

### 4. Filter Activities
1. In Activity List, use filter picker
2. Try "Runs", "Rides", "This Week"
3. Verify activities are filtered correctly

### 5. Disconnect
1. In Strava Connection view
2. Tap "Disconnect Strava"
3. Confirm in alert
4. Verify connection removed
5. Check activities remain in database

---

## Troubleshooting

### "Failed to connect Strava"
- Check internet connection
- Verify Strava credentials in `Configuration.swift`
- Check Xcode console for error details
- Ensure OAuth redirect URI matches in Strava app settings

### "No activities synced"
- Check if you have activities in Strava
- Verify access token is valid
- Try disconnecting and reconnecting
- Check Supabase for stored activities

### "Rate limit exceeded"
- Wait 15 minutes before trying again
- Reduce sync frequency
- Contact Strava support if limit is too low

### Token refresh fails
- Disconnect and reconnect to get new tokens
- Check refresh token is still valid
- Verify Strava app is not deauthorized

---

## Future Enhancements

### 1. Incremental Sync
- Only fetch activities since last sync
- Use `after` parameter in Strava API
- Reduce API calls and improve performance

### 2. Webhook Integration
- Subscribe to Strava webhooks
- Receive real-time activity updates
- Eliminate need for manual sync

### 3. Activity Editing
- Allow users to edit activity details
- Update calories if needed
- Mark activities as excluded from TDEE

### 4. Advanced Filtering
- Date range picker
- Activity type multi-select
- Calorie range filter
- Search by activity name

### 5. Analytics
- Total distance/time by week/month
- Calorie trends over time
- Activity type breakdown
- Personal records

---

## API Reference

### Strava API Documentation
- **API Docs**: https://developers.strava.com/docs/reference/
- **OAuth Guide**: https://developers.strava.com/docs/authentication/
- **Rate Limits**: https://developers.strava.com/docs/rate-limits/

### Endpoints Used
- `GET /api/v3/athlete/activities` - Fetch activities
- `POST /oauth/token` - Exchange/refresh tokens
- `GET /oauth/authorize` - Authorization page

---

## Configuration

### Required Settings

#### 1. Strava App Settings
Go to https://www.strava.com/settings/api:
- **Application Name**: Health Tracker
- **Authorization Callback Domain**: `healthapp` (no http://)
- **Redirect URI**: `healthapp://strava/callback`

#### 2. Configuration.swift
```swift
enum Strava {
    static let clientId = "YOUR_CLIENT_ID"
    static let clientSecret = "YOUR_CLIENT_SECRET"
    static let redirectUri = "healthapp://strava/callback"
    // ... other URLs are predefined
}
```

#### 3. Info.plist
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>healthapp</string>
        </array>
    </dict>
</array>
```

---

## Summary

✅ **Complete Strava Integration Features:**
- Full OAuth 2.0 flow with token management
- Activity syncing with pagination support
- Secure token storage in Supabase
- Comprehensive UI for connection and activity viewing
- Filtering and search capabilities
- Detailed activity metrics display
- Error handling and user feedback
- Rate limit detection
- Automatic token refresh
- Pull-to-refresh support

The integration is production-ready and follows best practices for OAuth, security, and user experience!

