# Health Tracker - Calorie Tracking iOS App

A comprehensive iOS calorie tracking app with Strava integration, built using Swift, SwiftUI, and Supabase.

## Features

- 📊 **Calorie Tracking**: Log food entries with detailed macronutrient information
- 🏃 **Strava Integration**: Automatically sync activities and track exercise calories
- 📱 **BMR/TDEE Calculator**: Calculate daily calorie needs based on physical stats
- 🍎 **USDA Food Database**: Search and access nutrition data from USDA FoodData Central
- 📸 **Progress Photos**: Track visual progress with photo uploads to Supabase Storage
- 📅 **Calendar View**: View daily summaries and track progress over time
- 📈 **Analytics**: Daily, weekly, and monthly nutrition analytics

## Tech Stack

- **Platform**: iOS 16+
- **UI Framework**: SwiftUI
- **Backend**: Supabase (PostgreSQL, Auth, Storage)
- **APIs**: 
  - Strava API for activity data
  - USDA FoodData Central API for nutrition database
- **Architecture**: MVVM (Model-View-ViewModel)
- **Reactive Programming**: Combine framework

## Project Structure

```
Health App/
├── HealthApp.swift              # App entry point
├── AppState.swift               # Global app state management
├── ContentView.swift            # Root view
│
├── Config/                      # Configuration files
│   └── Configuration.swift      # API keys and constants
│
├── Models/                      # Data models
│   ├── User.swift              # User profile with BMR/TDEE
│   ├── FoodEntry.swift         # Food logging model
│   ├── Activity.swift          # Strava activity model
│   ├── ProgressPhoto.swift     # Progress photo model
│   ├── DailySummary.swift      # Daily calorie summary
│   ├── StravaModels.swift      # Strava API response models
│   └── USDAModels.swift        # USDA API response models
│
├── Views/                       # SwiftUI views
│   ├── AuthenticationView.swift
│   ├── MainTabView.swift
│   ├── HomeView.swift
│   ├── CalendarView.swift
│   ├── AddFoodView.swift
│   ├── ActivitiesView.swift
│   └── ProfileView.swift
│
├── ViewModels/                  # View models (MVVM)
│   ├── AuthenticationViewModel.swift
│   └── HomeViewModel.swift
│
├── Services/                    # API and business logic
│   ├── SupabaseClient.swift    # Supabase singleton
│   ├── AuthenticationService.swift
│   ├── StravaService.swift     # Strava API integration
│   └── USDAService.swift       # USDA API integration
│
├── Utilities/                   # Helper utilities
│   ├── DateExtensions.swift
│   ├── NumberExtensions.swift
│   ├── ColorExtensions.swift
│   ├── ViewExtensions.swift
│   ├── NetworkMonitor.swift
│   ├── KeychainHelper.swift    # Secure storage
│   └── Logger.swift            # Logging utility
│
└── Resources/                   # Assets and resources
    ├── Assets.xcassets
    └── Info.plist
```

## Setup Instructions

### Prerequisites

- macOS with Xcode 15+
- iOS 16+ device or simulator
- Active Supabase project
- Strava API credentials (optional)
- USDA FoodData Central API key (optional)

### 1. Clone the Repository

```bash
cd "Health App"
```

### 2. Configure API Keys

Edit `Config/Configuration.swift` and replace the placeholder values:

```swift
enum Supabase {
    static let url = "YOUR_SUPABASE_URL_HERE"
    static let anonKey = "YOUR_SUPABASE_ANON_KEY_HERE"
}

enum Strava {
    static let clientId = "YOUR_STRAVA_CLIENT_ID_HERE"
    static let clientSecret = "YOUR_STRAVA_CLIENT_SECRET_HERE"
}

enum USDA {
    static let apiKey = "YOUR_USDA_API_KEY_HERE"
}
```

#### Getting API Keys:

**Supabase:**
1. Create a project at [supabase.com](https://supabase.com)
2. Go to Settings → API
3. Copy the Project URL and anon/public key

**Strava:**
1. Register your app at [strava.com/settings/api](https://www.strava.com/settings/api)
2. Set the Authorization Callback Domain to: `healthapp`
3. Copy the Client ID and Client Secret

**USDA FoodData Central:**
1. Sign up at [fdc.nal.usda.gov](https://fdc.nal.usda.gov/api-key-signup.html)
2. Get your free API key

### 3. Add Swift Package Dependencies

In Xcode:
1. Open the project
2. Go to File → Add Package Dependencies
3. Add the following package:
   - **Supabase Swift SDK**: `https://github.com/supabase/supabase-swift`

Or use Swift Package Manager via command line:

```bash
swift package resolve
```

### 4. Configure URL Scheme (for Strava OAuth)

1. In Xcode, select your project
2. Go to Info tab
3. Add URL Types with:
   - Identifier: `com.healthapp.strava`
   - URL Schemes: `healthapp`

### 5. Set Up Supabase Database

Create the following tables in your Supabase project:

```sql
-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    weight FLOAT,
    height FLOAT,
    age INTEGER,
    gender TEXT,
    activity_level TEXT,
    strava_access_token TEXT,
    strava_refresh_token TEXT,
    strava_token_expires_at TIMESTAMP,
    strava_athlete_id TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Food entries table
CREATE TABLE food_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    food_name TEXT NOT NULL,
    brand_name TEXT,
    serving_size FLOAT NOT NULL,
    serving_unit TEXT NOT NULL,
    calories FLOAT NOT NULL,
    protein FLOAT NOT NULL,
    carbohydrates FLOAT NOT NULL,
    fat FLOAT NOT NULL,
    fiber FLOAT,
    sugar FLOAT,
    saturated_fat FLOAT,
    sodium FLOAT,
    meal_type TEXT NOT NULL,
    number_of_servings FLOAT NOT NULL,
    fdc_id TEXT,
    logged_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Activities table
CREATE TABLE activities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    strava_activity_id TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    activity_type TEXT NOT NULL,
    start_date TIMESTAMP NOT NULL,
    duration FLOAT NOT NULL,
    distance FLOAT,
    calories_burned FLOAT NOT NULL,
    average_heart_rate FLOAT,
    max_heart_rate FLOAT,
    elevation_gain FLOAT,
    average_speed FLOAT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Progress photos table
CREATE TABLE progress_photos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    photo_url TEXT NOT NULL,
    thumbnail_url TEXT,
    weight FLOAT,
    notes TEXT,
    taken_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Daily summaries table
CREATE TABLE daily_summaries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    target_calories FLOAT NOT NULL,
    consumed_calories FLOAT NOT NULL,
    burned_calories FLOAT NOT NULL,
    total_protein FLOAT NOT NULL,
    total_carbohydrates FLOAT NOT NULL,
    total_fat FLOAT NOT NULL,
    target_protein FLOAT,
    target_carbohydrates FLOAT,
    target_fat FLOAT,
    food_entries_count INTEGER NOT NULL,
    activities_count INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, date)
);

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE food_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE progress_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_summaries ENABLE ROW LEVEL SECURITY;

-- RLS Policies (users can only access their own data)
CREATE POLICY "Users can view own data" ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own data" ON users FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can view own food entries" ON food_entries FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own food entries" ON food_entries FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own food entries" ON food_entries FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own food entries" ON food_entries FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Users can view own activities" ON activities FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own activities" ON activities FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own activities" ON activities FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own activities" ON activities FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Users can view own photos" ON progress_photos FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own photos" ON progress_photos FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own photos" ON progress_photos FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own photos" ON progress_photos FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Users can view own summaries" ON daily_summaries FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own summaries" ON daily_summaries FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own summaries" ON daily_summaries FOR UPDATE USING (auth.uid() = user_id);
```

### 6. Configure Supabase Storage

1. Go to Storage in Supabase dashboard
2. Create a bucket named `progress-photos`
3. Set the bucket to private
4. Add storage policies for user access

### 7. Build and Run

1. Open the project in Xcode
2. Select your target device or simulator
3. Press `Cmd + R` to build and run

## Usage

### Authentication
- Sign up with email and password
- Sign in to existing account
- All authentication is handled by Supabase Auth

### Profile Setup
1. Navigate to Profile tab
2. Enter physical stats (weight, height, age, gender)
3. Select activity level
4. App automatically calculates BMR and TDEE

### Logging Food
1. Tap the "+" tab or "Log Food" on Home screen
2. Search for food using USDA database
3. Select serving size and meal type
4. Save entry

### Strava Integration
1. Go to Profile → Integrations → Strava
2. Connect your Strava account
3. Activities will sync automatically
4. Exercise calories are added to daily burn

### Progress Photos
1. Go to Profile → Progress Photos
2. Take or upload photo
3. Optionally add weight and notes
4. Photos are stored securely in Supabase Storage

## Architecture

### MVVM Pattern
- **Models**: Data structures and business logic
- **Views**: SwiftUI views for UI
- **ViewModels**: Presentation logic and state management

### Services Layer
- **SupabaseClient**: Singleton for database operations
- **AuthenticationService**: User authentication
- **StravaService**: Strava API integration
- **USDAService**: Food database searches

### State Management
- `@Published` properties for reactive updates
- Combine framework for data streams
- `AppState` for global app state

## Security

- API keys stored in Configuration.swift (add to .gitignore)
- Sensitive tokens stored in Keychain
- Row Level Security (RLS) in Supabase
- All network requests use HTTPS

## Contributing

This is a personal project, but suggestions and improvements are welcome!

## License

MIT License - feel free to use for personal projects

## Roadmap

- [ ] Barcode scanning for food entries
- [ ] Custom food creation and saving
- [ ] Meal planning and recipes
- [ ] Water intake tracking
- [ ] Weight trend charts
- [ ] Export data functionality
- [ ] Apple Health integration
- [ ] Widgets for iOS home screen
- [ ] Dark mode optimization

## Support

For issues or questions, please check the documentation or create an issue.

## Acknowledgments

- [Supabase](https://supabase.com) - Backend infrastructure
- [Strava API](https://developers.strava.com) - Activity data
- [USDA FoodData Central](https://fdc.nal.usda.gov) - Nutrition database

