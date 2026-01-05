# Secure API Key Setup Instructions

## 📋 Overview

This guide explains how to configure secure API keys using xcconfig files and Info.plist.

---

## 🚀 Quick Start

### Step 1: The xcconfig files are already created!

You now have:
- ✅ `Secrets.xcconfig` - Your actual API keys (already populated)
- ✅ `Secrets.template.xcconfig` - Template for others
- ✅ `Debug.xcconfig` - Debug configuration
- ✅ `Release.xcconfig` - Release configuration

### Step 2: Configure Xcode Project

1. **Open your Xcode project**
   ```
   open Healthapp.xcodeproj
   ```

2. **Add xcconfig files to project:**
   - In Xcode, right-click on the `Config` folder
   - Choose "Add Files to 'Healthapp'..."
   - Select all 4 `.xcconfig` files
   - Make sure "Copy items if needed" is UNCHECKED
   - Click "Add"

3. **Set configurations for your target:**
   - Select your project in the navigator (blue icon at top)
   - Select the project itself (not the target) in the main editor
   - Go to the "Info" tab
   - Under "Configurations", expand "Debug" and "Release"
   - For **Debug**:
     - Click the dropdown under your target name
     - Select `Debug`
   - For **Release**:
     - Click the dropdown under your target name
     - Select `Release`

   It should look like:
   ```
   Configurations
   ├── Debug
   │   └── Netfuel: Debug
   └── Release
       └── Netfuel: Release
   ```

### Step 3: Update Info.plist

Add these keys to your `Info.plist`:

**Using Xcode:**
1. Open `Info.plist` in Xcode
2. Right-click anywhere and choose "Add Row"
3. Add each of these keys:

```xml
<key>SUPABASE_URL</key>
<string>$(SUPABASE_URL)</string>
<key>SUPABASE_ANON_KEY</key>
<string>$(SUPABASE_ANON_KEY)</string>
<key>STRAVA_CLIENT_ID</key>
<string>$(STRAVA_CLIENT_ID)</string>
<key>STRAVA_CLIENT_SECRET</key>
<string>$(STRAVA_CLIENT_SECRET)</string>
<key>USDA_API_KEY</key>
<string>$(USDA_API_KEY)</string>
```

**Or manually edit Info.plist as XML:**
1. Right-click `Info.plist` → "Open As" → "Source Code"
2. Add these lines inside the `<dict>` tag:

```xml
<key>SUPABASE_URL</key>
<string>$(SUPABASE_URL)</string>
<key>SUPABASE_ANON_KEY</key>
<string>$(SUPABASE_ANON_KEY)</string>
<key>STRAVA_CLIENT_ID</key>
<string>$(STRAVA_CLIENT_ID)</string>
<key>STRAVA_CLIENT_SECRET</key>
<string>$(STRAVA_CLIENT_SECRET)</string>
<key>USDA_API_KEY</key>
<string>$(USDA_API_KEY)</string>
```

### Step 4: Update Configuration.swift

Replace the hardcoded values with Info.plist reads. I'll do this for you in the next step!

### Step 5: Update .gitignore

Add to your `.gitignore`:
```
# API Keys and Secrets
Config/Secrets.xcconfig
*.xcconfig
!*.template.xcconfig

# Don't ignore Debug/Release configs if you want to commit them
!Config/Debug.xcconfig
!Config/Release.xcconfig
```

---

## 🔍 How It Works

### Flow Diagram:
```
Secrets.xcconfig (gitignored)
    ↓
Debug.xcconfig / Release.xcconfig (includes Secrets.xcconfig)
    ↓
Xcode Build Settings
    ↓
Info.plist ($(VARIABLE_NAME) replaced at build time)
    ↓
Configuration.swift (reads from Bundle.main.infoDictionary)
    ↓
Your app code
```

### Example:
1. `Secrets.xcconfig` contains: `SUPABASE_URL = https://example.supabase.co`
2. `Info.plist` contains: `<string>$(SUPABASE_URL)</string>`
3. At build time, Xcode replaces `$(SUPABASE_URL)` with the actual value
4. `Configuration.swift` reads it via `Bundle.main.infoDictionary`

---

## 🛡️ Security Benefits

✅ **Secrets not in source code** - No hardcoded API keys
✅ **Gitignored** - Secrets.xcconfig is never committed
✅ **Different environments** - Separate Debug/Release keys possible
✅ **Team-friendly** - Template file for onboarding
✅ **CI/CD ready** - Secrets can be injected at build time

---

## 🔄 For Team Members

If someone clones the repo:

1. Copy the template:
   ```bash
   cd Config
   cp Secrets.template.xcconfig Secrets.xcconfig
   ```

2. Edit `Secrets.xcconfig` and add their API keys

3. Build and run!

---

## 🚨 Important Notes

- **Never commit `Secrets.xcconfig`** - It's in .gitignore for a reason
- **Do commit** `Secrets.template.xcconfig` - Others need to know what keys to add
- **Rotate keys** if they were previously committed to git
- **Use different keys** for Debug (development) and Release (production) builds

---

## 🧪 Testing

After setup, test that it works:

1. Build the app in Xcode (⌘B)
2. If you get errors about missing keys, double-check:
   - xcconfig files are added to project
   - Configurations are set correctly in Project Settings
   - Info.plist has the $(VARIABLE) references
3. Run the app and check that APIs work

---

## 📞 Troubleshooting

### "Could not read values from xcconfig"
- Make sure xcconfig files are in the `Config` folder
- Check that paths in `#include` statements are correct

### "API keys are empty/nil"
- Verify Info.plist keys match exactly (case-sensitive)
- Clean build folder: Product → Clean Build Folder (⌘⇧K)
- Rebuild

### "Configuration not found"
- Make sure you selected the xcconfig files in Project Settings → Info → Configurations

---

## 🎯 Next Steps

After I update `Configuration.swift`, you'll be able to:
- ✅ Remove hardcoded secrets from source
- ✅ Use different keys per environment
- ✅ Safely share code on GitHub
- ✅ Onboard team members securely
