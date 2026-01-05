# Info.plist Configuration Guide

Required and recommended Info.plist entries for Netfuel app.

---

## Required Privacy Usage Descriptions

These are **REQUIRED** by Apple if your app uses these features. Missing these will cause App Store rejection.

### Camera Usage (Progress Photos)

```xml
<key>NSCameraUsageDescription</key>
<string>Netfuel needs access to your camera to take progress photos and track your fitness journey.</string>
```

### Photo Library Usage (Progress Photos)

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Netfuel needs access to your photo library to save and view your progress photos.</string>
```

**Alternative wording** (choose what fits best):
- "Access photos to track your fitness transformation over time."
- "Save progress photos to document your fitness journey."
- "View and manage your fitness progress photos."

### Photo Library Add Only (iOS 11+)

```xml
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Netfuel needs permission to save your progress photos to your photo library.</string>
```

---

## URL Schemes (OAuth)

Required for Strava OAuth and deep linking.

### Strava OAuth Callback

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.netfuel.oauth</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>netfuel</string>
        </array>
    </dict>
</array>
```

This allows URLs like `netfuel://callback` to open your app.

### Universal Links (Optional but Recommended)

For better deep linking support:

```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:netfuelapp.com</string>
</array>
```

Requires:
1. Associated domain entitlement in Xcode
2. `.well-known/apple-app-site-association` file on your server

---

## Background Modes (Optional)

If you want to fetch data in the background:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

**When to use**:
- `fetch` - Periodic background refresh (sync activities)
- `remote-notification` - Push notifications for reminders

**Note**: Only add if you implement background functionality. Unused modes may be questioned by Apple.

---

## App Transport Security (ATS)

Your app uses HTTPS for all network requests, which is good! However, if you need to allow specific domains:

### Allow Specific Domains

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoadsInWebContent</key>
    <true/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>yourdomain.com</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
            <key>NSIncludesSubdomains</key>
            <true/>
        </dict>
    </dict>
</dict>
```

**For Netfuel**: You probably don't need this since:
- Supabase uses HTTPS
- Strava API uses HTTPS
- USDA API uses HTTPS

---

## App Capabilities

Enable these in Xcode (not Info.plist):

### Push Notifications

1. Go to **Signing & Capabilities**
2. Click **+ Capability**
3. Add **Push Notifications**

### Associated Domains (for Universal Links)

1. Go to **Signing & Capabilities**
2. Click **+ Capability**
3. Add **Associated Domains**
4. Add: `applinks:netfuelapp.com`

---

## Version and Build Numbers

### Version Number (CFBundleShortVersionString)

```xml
<key>CFBundleShortVersionString</key>
<string>1.0.0</string>
```

**Format**: MAJOR.MINOR.PATCH
- MAJOR: Breaking changes (2.0.0)
- MINOR: New features (1.1.0)
- PATCH: Bug fixes (1.0.1)

**For initial release**: `1.0.0`

### Build Number (CFBundleVersion)

```xml
<key>CFBundleVersion</key>
<string>1</string>
```

**Rules**:
- Must increment for each upload to App Store Connect
- Can be just a number: 1, 2, 3, etc.
- Or match version: 1.0.0, 1.0.1, 1.1.0

**Recommended**: Simple incrementing number (1, 2, 3...)

---

## Bundle Identifier

```xml
<key>CFBundleIdentifier</key>
<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
```

**Should be**: `com.yourname.netfuel` or `com.netfuel.app`

**Requirements**:
- Unique across App Store
- Reverse domain notation
- Lowercase, no spaces
- Can include hyphens

**Setting**:
1. Set in Xcode → **General** tab
2. Must match App Store Connect

---

## Display Name

```xml
<key>CFBundleDisplayName</key>
<string>Netfuel</string>
```

This is the name shown under the app icon on the home screen.

**Max length**: ~13-15 characters (longer names get truncated)

---

## Supported Interface Orientations

### iPhone

```xml
<key>UISupportedInterfaceOrientations</key>
<array>
    <string>UIInterfaceOrientationPortrait</string>
    <string>UIInterfaceOrientationPortraitUpsideDown</string>
</array>
```

**Recommendation for Netfuel**: Portrait only (users typically use fitness apps in portrait)

### iPad

```xml
<key>UISupportedInterfaceOrientations~ipad</key>
<array>
    <string>UIInterfaceOrientationPortrait</string>
    <string>UIInterfaceOrientationPortraitUpsideDown</string>
    <string>UIInterfaceOrientationLandscapeLeft</string>
    <string>UIInterfaceOrientationLandscapeRight</string>
</array>
```

iPad supports all orientations by default.

---

## Requires Full Screen (iPhone X+)

```xml
<key>UIRequiresFullScreen</key>
<true/>
```

**Set to true** if your app doesn't support multitasking on iPad.
**Set to false** (or omit) to support Split View and Slide Over on iPad.

**Recommendation**: `false` for better iPad experience

---

## Status Bar Style

```xml
<key>UIStatusBarStyle</key>
<string>UIStatusBarStyleDefault</string>
```

Or for SwiftUI, control programmatically:
```swift
.preferredColorScheme(.dark) // or .light
```

---

## Launch Screen

```xml
<key>UILaunchScreen</key>
<dict>
    <key>UIColorName</key>
    <string>LaunchScreenBackground</string>
    <key>UIImageName</key>
    <string>LaunchScreenLogo</string>
</dict>
```

Alternative: Use `UILaunchStoryboardName` for storyboard-based launch screen.

---

## Minimum OS Version

```xml
<key>MinimumOSVersion</key>
<string>16.0</string>
```

**Current**: iOS 16.0 (based on your SwiftUI usage)

**Consider**:
- iOS 16+ required for latest SwiftUI features
- iOS 17+ for new APIs (but smaller audience)
- Check your deployment target in Xcode

---

## Complete Info.plist Template

Here's a complete Info.plist with all Netfuel requirements:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- App Identity -->
    <key>CFBundleDisplayName</key>
    <string>Netfuel</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>

    <!-- Privacy - Camera -->
    <key>NSCameraUsageDescription</key>
    <string>Netfuel needs access to your camera to take progress photos and track your fitness journey.</string>

    <!-- Privacy - Photo Library -->
    <key>NSPhotoLibraryUsageDescription</key>
    <string>Netfuel needs access to your photo library to save and view your progress photos.</string>
    <key>NSPhotoLibraryAddUsageDescription</key>
    <string>Netfuel needs permission to save your progress photos to your photo library.</string>

    <!-- URL Schemes for OAuth -->
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLName</key>
            <string>com.netfuel.oauth</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>netfuel</string>
            </array>
        </dict>
    </array>

    <!-- Supported Orientations - iPhone -->
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
    </array>

    <!-- Supported Orientations - iPad -->
    <key>UISupportedInterfaceOrientations~ipad</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationPortraitUpsideDown</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>

    <!-- Launch Screen -->
    <key>UILaunchScreen</key>
    <dict>
        <key>UIColorName</key>
        <string>LaunchScreenBackground</string>
        <key>UIImageName</key>
        <string>LaunchScreenLogo</string>
    </dict>

    <!-- Minimum OS Version -->
    <key>MinimumOSVersion</key>
    <string>16.0</string>

    <!-- Requires Full Screen -->
    <key>UIRequiresFullScreen</key>
    <false/>
</dict>
</plist>
```

---

## How to Edit Info.plist in Xcode

### Method 1: Property List Editor (Recommended)

1. Click on **Info.plist** in Project Navigator
2. Right-click in editor → **Add Row**
3. Select key from dropdown (or type custom key)
4. Enter value

### Method 2: Source Code

1. Right-click Info.plist → **Open As → Source Code**
2. Edit XML directly
3. Be careful with XML syntax

### Method 3: Project Settings

Some settings available in:
1. Select project in Navigator
2. Select target
3. **General** tab (version, bundle ID, deployment target)
4. **Info** tab (custom settings)

---

## Testing Info.plist

### Verify Usage Descriptions

1. Run app on simulator
2. Trigger camera or photo library access
3. Permission alert should show your description
4. If description is missing, iOS shows generic text (warning sign)

### Verify URL Scheme

```bash
# Test deep link
xcrun simctl openurl booted "netfuel://test"
```

App should open if URL scheme is configured correctly.

---

## Common Mistakes

### ❌ Don't

- Don't use generic/default usage descriptions
- Don't add unused permissions (Apple may question)
- Don't forget to increment build number
- Don't use spaces in bundle identifier

### ✅ Do

- Write clear, user-friendly usage descriptions
- Only request permissions you actually use
- Increment build for each upload
- Test all permission prompts

---

## Checklist

Before submitting:

- [ ] All usage descriptions are present and clear
- [ ] Bundle identifier matches App Store Connect
- [ ] Version and build numbers are correct
- [ ] URL schemes configured for OAuth
- [ ] Launch screen configured
- [ ] Minimum OS version is set correctly
- [ ] Tested all permission prompts
- [ ] No unused permissions declared

---

**Status**: Info.plist guide ready
**Next**: TestFlight Setup (see TESTFLIGHT_GUIDE.md)
