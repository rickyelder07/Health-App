# Health Tracker - Setup Guide

This guide will walk you through setting up the Health Tracker iOS app from scratch.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Xcode Project Setup](#xcode-project-setup)
3. [API Configuration](#api-configuration)
4. [Supabase Setup](#supabase-setup)
5. [Strava Integration](#strava-integration)
6. [USDA API Setup](#usda-api-setup)
7. [Testing the App](#testing-the-app)

---

## Prerequisites

Before you begin, make sure you have:

- macOS 14+ (Sonoma or later)
- Xcode 15+ installed
- Apple Developer account (for device testing)
- Active internet connection

## Xcode Project Setup

### Step 1: Create Xcode Project

1. Open Xcode
2. Select "Create a new Xcode project"
3. Choose "iOS" → "App"
4. Configure your project:
   - Product Name: `Health Tracker` or `Health App`
   - Team: Select your development team
   - Organization Identifier: `com.yourname` (e.g., `com.johndoe`)
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: None
   - Uncheck "Include Tests" (optional)
5. Choose save location (use the "Health App" folder)

### Step 2: Add Swift Package Dependencies

1. In Xcode, go to **File** → **Add Package Dependencies**
2. In the search bar, enter: `https://github.com/supabase/supabase-swift`
3. Select the package and click "Add Package"
4. Select the target to add the package to (your app target)
5. Click "Add Package"

Wait for the package to download and resolve dependencies.

### Step 3: Organize Project Files

1. Delete the default `ContentView.swift` and `HealthApp.swift` files that Xcode created
2. Replace them with the files from this repository
3. Create the following groups (folders) in Xcode:
   - Config
   - Models
   - Views
   - ViewModels
   - Services
   - Utilities
   - Resources

4. Drag the corresponding `.swift` files into each group

### Step 4: Configure Info.plist

1. Open `Info.plist` in the Resources folder
2. Add the following privacy descriptions (already included if using the provided file):
   - Camera Usage Description
   - Photo Library Usage Description
   - Motion Usage Description

3. Add URL Scheme for Strava OAuth:
   - URL Schemes: `healthapp`

---

## API Configuration

### Update Configuration.swift

Open `Config/Configuration.swift` and update the placeholder values.

---

## Supabase Setup

### Step 1: Create Supabase Project

1. Go to [supabase.com](https://supabase.com)
2. Click "Start your project"
3. Sign in or create an account
4. Click "New Project"
5. Enter project details:
   - Name: `health-tracker`
   - Database Password: (generate a strong password)
   - Region: Choose closest to you
6. Click "Create new project"
7. Wait for project to be created (~2 minutes)

### Step 2: Get API Keys

1. In your Supabase dashboard, go to **Settings** → **API**
2. Copy the following values:
   - **Project URL** (e.g., `https://xxxxx.supabase.co`)
   - **anon/public key** (starts with `eyJ...`)
3. Update `Configuration.swift` with these values:

```swift
enum Supabase {
    static let url = "https://xxxxx.supabase.co"
    static let anonKey = "eyJ..."
}
```

### Step 3: Set Up Database Tables

1. In Supabase dashboard, go to **SQL Editor**
2. Click "New Query"
3. Copy and paste the SQL from `README.md` (Database Schema section)
4. Click "Run" to create all tables
5. Verify tables were created in **Table Editor**

### Step 4: Configure Storage

1. Go to **Storage** in Supabase dashboard
2. Click "Create a new bucket"
3. Name it: `progress-photos`
4. Make it **Private**
5. Click "Create bucket"

6. Add storage policies:
   - Go to **Policies** tab
   - Click "New Policy"
   - Select "For full customization"
   - Add the following policy:

```sql
-- Allow users to upload their own photos
CREATE POLICY "Users can upload own photos"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'progress-photos' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Allow users to view their own photos
CREATE POLICY "Users can view own photos"
ON storage.objects FOR SELECT
USING (bucket_id = 'progress-photos' AND auth.uid()::text = (storage.foldername(name))[1]);
```

---

## Strava Integration

### Step 1: Create Strava API Application

1. Go to [strava.com/settings/api](https://www.strava.com/settings/api)
2. Sign in with your Strava account
3. Fill in the application details:
   - **Application Name**: Health Tracker
   - **Category**: Health and Fitness
   - **Club**: (leave blank)
   - **Website**: Your website or `http://localhost`
   - **Application Description**: iOS calorie tracking app
   - **Authorization Callback Domain**: `healthapp` (no http://)
4. Agree to terms and click "Create"

### Step 2: Get API Credentials

1. After creating the app, you'll see:
   - **Client ID**: (numeric ID)
   - **Client Secret**: (alphanumeric string)
2. Copy these values to `Configuration.swift`:

```swift
enum Strava {
    static let clientId = "123456"
    static let clientSecret = "abc123def456..."
}
```

### Step 3: Configure OAuth Redirect

The app is already configured to handle the redirect URI: `healthapp://strava/callback`

Make sure your Xcode project has the URL scheme set up:
1. Select your project in Xcode
2. Go to **Info** tab
3. Expand **URL Types**
4. Verify `healthapp` is listed

---

## USDA API Setup

### Step 1: Get API Key

1. Go to [fdc.nal.usda.gov/api-key-signup.html](https://fdc.nal.usda.gov/api-key-signup.html)
2. Fill in the signup form:
   - Email
   - First Name
   - Last Name
   - Organization (optional)
3. Agree to terms
4. Click "Signup"
5. Check your email for the API key

### Step 2: Update Configuration

Add the API key to `Configuration.swift`:

```swift
enum USDA {
    static let apiKey = "YOUR_API_KEY_HERE"
}
```

### Step 3: Test the API (Optional)

You can test the API with curl:

```bash
curl "https://api.nal.usda.gov/fdc/v1/foods/search?api_key=YOUR_API_KEY&query=apple"

```

---

## Testing the App

### Step 1: Build and Run

1. Select a simulator or connected device
2. Press `Cmd + R` to build and run
3. Wait for the app to compile and launch

### Step 2: Test Authentication

1. On the authentication screen, try signing up:
   - Email: `test@example.com`
   - Password: `password123`
2. Check Supabase dashboard → **Authentication** → **Users** to verify user was created

### Step 3: Test Features

- **Profile Setup**: Add physical stats and verify BMR/TDEE calculations
- **Food Search**: Search for a food item using USDA database
- **Strava Connection**: Test the OAuth flow (optional)
- **Progress Photos**: Try uploading a photo (optional)

### Step 4: Debug Common Issues

**Build Errors:**
- Clean build folder: `Cmd + Shift + K`
- Delete derived data: `Cmd + Shift + Option + K`
- Restart Xcode

**Runtime Errors:**
- Check console logs in Xcode
- Verify API keys are correct in `Configuration.swift`
- Check network connectivity

**Supabase Errors:**
- Verify RLS policies are set up correctly
- Check API keys are valid
- Ensure tables exist in database

---

## Next Steps

Now that your app is set up, you can:

1. **Customize the UI**: Modify views to match your design preferences
2. **Add Features**: Implement additional functionality from the roadmap
3. **Test on Device**: Deploy to a physical iOS device
4. **Distribute**: Prepare for TestFlight or App Store submission

---

## Need Help?

- Check the main `README.md` for detailed documentation
- Review Supabase docs: [supabase.com/docs](https://supabase.com/docs)
- Review Strava API docs: [developers.strava.com](https://developers.strava.com)
- Review USDA API docs: [fdc.nal.usda.gov/api-guide.html](https://fdc.nal.usda.gov/api-guide.html)

---

## Security Reminder

⚠️ **IMPORTANT**: Never commit your `Configuration.swift` file with real API keys to a public repository!

Add it to `.gitignore`:

```bash
echo "Config/Configuration.swift" >> .gitignore
```

Happy coding! 🎉

