# Privacy Manifest Guide

## What is a Privacy Manifest?

As of iOS 17 and Xcode 15, Apple requires apps to include a **Privacy Manifest** (`PrivacyInfo.xcprivacy`) that declares:
1. Data collection practices
2. Required Reasons API usage
3. Third-party SDK privacy information
4. Tracking practices

## ✅ Created: PrivacyInfo.xcprivacy

Location: `Healthapp/PrivacyInfo.xcprivacy`

This file has been created with Netfuel's privacy practices declared.

## What's Declared

### 1. Tracking

```xml
<key>NSPrivacyTracking</key>
<false/>
```

**Netfuel does NOT track users across apps/websites** for advertising purposes.

### 2. Data Collection

The manifest declares these data types collected by Netfuel:

#### Health & Fitness Data
- **What**: Calories, macros, weight, BMR, TDEE
- **Linked to user**: Yes
- **Used for tracking**: No
- **Purpose**: App functionality, analytics (internal only)

#### User ID
- **What**: Supabase authentication ID
- **Linked to user**: Yes
- **Used for tracking**: No
- **Purpose**: App functionality (authentication, data sync)

#### Email Address
- **What**: User's email for authentication
- **Linked to user**: Yes
- **Used for tracking**: No
- **Purpose**: App functionality (sign in, account management)

#### Photos/Videos
- **What**: Progress photos uploaded by user
- **Linked to user**: Yes
- **Used for tracking**: No
- **Purpose**: App functionality (progress tracking)

#### Name
- **What**: User's first name
- **Linked to user**: Yes
- **Used for tracking**: No
- **Purpose**: App functionality (personalization)

### 3. Required Reasons APIs

The manifest declares these API usages:

#### File Timestamp API
- **Reason Code**: C617.1
- **Why**: Accessing file modification times for cache management

#### User Defaults API
- **Reason Code**: CA92.1
- **Why**: Storing app preferences and settings

#### System Boot Time API
- **Reason Code**: 35F9.1
- **Why**: Measuring time intervals for analytics

#### Disk Space API
- **Reason Code**: E174.1
- **Why**: Checking available space before caching images

## How to Add to Xcode

1. **Open Xcode** project
2. **Right-click** on project folder in Navigator
3. **Add Files to "Healthapp"...**
4. Select `PrivacyInfo.xcprivacy`
5. Make sure **"Add to targets"** includes your app target
6. Click **Add**

OR

1. Drag `PrivacyInfo.xcprivacy` into Xcode
2. Choose to **copy items if needed**
3. Add to your app target

## Verify It's Included

1. Click on your **project** in Xcode
2. Select your **app target**
3. Go to **Build Phases**
4. Expand **Copy Bundle Resources**
5. Verify `PrivacyInfo.xcprivacy` is listed

## Customizing for Your App

### If You Add New Data Collection

If you add features that collect additional data:

1. Open `PrivacyInfo.xcprivacy` in Xcode
2. Add new data type under `NSPrivacyCollectedDataTypes`
3. Use Apple's data type identifiers:
   - `NSPrivacyCollectedDataTypeLocation` - Location data
   - `NSPrivacyCollectedDataTypeContacts` - Contact information
   - `NSPrivacyCollectedDataTypeBrowsingHistory` - Web browsing
   - etc.

Example:
```xml
<dict>
    <key>NSPrivacyCollectedDataType</key>
    <string>NSPrivacyCollectedDataTypeLocation</string>
    <key>NSPrivacyCollectedDataTypeLinked</key>
    <true/>
    <key>NSPrivacyCollectedDataTypeTracking</key>
    <false/>
    <key>NSPrivacyCollectedDataTypePurposes</key>
    <array>
        <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
    </array>
</dict>
```

### If You Add Tracking

If you add analytics or advertising (not recommended):

```xml
<key>NSPrivacyTracking</key>
<true/>
<key>NSPrivacyTrackingDomains</key>
<array>
    <string>analytics.example.com</string>
</array>
```

**Note**: This triggers App Tracking Transparency (ATT) prompt.

### Required Reasons API Codes

Common reason codes you might need:

**File Timestamp (NSPrivacyAccessedAPICategoryFileTimestamp)**:
- `C617.1` - Accessing user files or directories
- `3B52.1` - File access within app container

**User Defaults (NSPrivacyAccessedAPICategoryUserDefaults)**:
- `CA92.1` - App storing preferences
- `1C8F.1` - SDK storing data for app

**System Boot Time (NSPrivacyAccessedAPICategorySystemBootTime)**:
- `35F9.1` - Measuring time between events
- `8FFB.1` - Calculating absolute timestamp

**Disk Space (NSPrivacyAccessedAPICategoryDiskSpace)**:
- `E174.1` - Displaying to user or informing storage
- `85F4.1` - Checking for sufficient space

## Third-Party SDKs

### Current SDKs

Your app uses these third-party SDKs:

1. **Supabase Swift SDK**
   - Privacy manifest: Check if SDK includes one
   - Purpose: Authentication, database, storage

2. **Strava SDK** (if using official SDK)
   - Privacy manifest: Check if SDK includes one
   - Purpose: OAuth authentication, activity sync

### Adding SDK Privacy Info

If an SDK doesn't include a privacy manifest:

1. Document the SDK's data collection
2. Add it to your app's manifest
3. Or request SDK author to add one

## Testing Your Privacy Manifest

### In Xcode

1. **Archive your app**: Product → Archive
2. Check for warnings about missing privacy manifest
3. Xcode will flag any issues

### App Store Connect

1. Upload your build
2. Apple will review the privacy manifest
3. Any issues will appear in App Store Connect

### Privacy Nutrition Label

Your privacy manifest feeds into the **App Privacy** section in App Store Connect:

1. Go to App Store Connect
2. Select your app
3. Go to **App Privacy**
4. Review auto-filled information
5. Confirm or edit as needed

## Common Mistakes

### ❌ Don't

- Don't omit data types you actually collect
- Don't declare data you don't collect
- Don't use incorrect reason codes
- Don't forget to update when adding features

### ✅ Do

- Be accurate and complete
- Use correct reason codes from Apple's list
- Update when app changes
- Test on each submission
- Keep manifest in sync with privacy policy

## Resources

- [Apple Privacy Manifest Documentation](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files)
- [Required Reason API](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files/describing_use_of_required_reason_api)
- [Privacy Nutrition Labels](https://developer.apple.com/app-store/app-privacy-details/)

---

## Privacy Policy

Your privacy manifest should align with your **Privacy Policy**. See `PRIVACY_POLICY.md` for a template.

---

**Status**: Privacy Manifest created and ready to add to Xcode
**Next**: Info.plist Configuration (see INFO_PLIST_GUIDE.md)
