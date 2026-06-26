# App Store Submission Guide — Netfuel

End-to-end reference for submitting Netfuel to the App Store.

---

## App Metadata

### Listing Copy

| Field | Value | Limit |
|-------|-------|-------|
| **Name** | Netfuel | 30 chars |
| **Subtitle** | Track Calories & Macros | 30 chars |
| **Keywords** | `calorie tracker,macro,nutrition,fitness,diet,food log,strava,bmr,tdee,weight loss,muscle gain` | 100 chars |
| **Primary Category** | Health & Fitness | — |
| **Secondary Category** | Food & Drink | — |
| **Age Rating** | 4+ | — |
| **Privacy Policy** | https://rickyelder07.github.io/NetFuel/privacy-policy.html | required |
| **Support URL** | https://rickyelder07.github.io/NetFuel/support.html | required |

### Description

```
Netfuel is your complete calorie and macro tracking companion, designed to help you fuel your fitness journey. Whether you're building muscle, losing weight, or maintaining a healthy lifestyle, Netfuel makes nutrition tracking simple, accurate, and motivating.

🔥 KEY FEATURES

CALORIE & MACRO TRACKING
• Log meals with detailed nutritional information
• Search USDA FoodData Central database (300,000+ foods)
• Add custom foods and recipes
• Track protein, carbs, and fat
• Set personalized macro targets

AUTOMATIC ACTIVITY TRACKING
• Connect with Strava to sync workouts automatically
• Track calories burned from exercise
• See your net calorie balance in real-time
• Support for running, cycling, swimming, and more

SMART GOAL SETTING
• Calculate BMR (Basal Metabolic Rate) automatically
• Set TDEE (Total Daily Energy Expenditure) goals
• Choose between weight loss, maintenance, or muscle gain
• Customize macro ratios for your goals

PROGRESS TRACKING
• Visual calendar view of your nutrition history
• Daily calorie and macro summaries
• Track weight changes over time
• Progress photos to see your transformation
• Weekly and monthly analytics

PRIVACY FIRST
• Your data stays secure with Supabase
• No ads, no data selling
• Row-level security — only you can see your data

Download Netfuel today and take control of your nutrition.

Terms of Service: https://rickyelder07.github.io/NetFuel/terms-of-service.html
Privacy Policy: https://rickyelder07.github.io/NetFuel/privacy-policy.html
```

### App Review Demo Account

```
Email:    demo@netfuelapp.com
Password: Demo123!
```

Notes to include for reviewer:
```
Netfuel requires sign-in. Use the demo credentials above — the account
has sample food logs, activities, and progress photos loaded.

Strava integration requires user OAuth; demo account is pre-connected.

Contact: ricky.elder07@gmail.com
```

---

## App Icons

Apple requires icons exported as PNG in sRGB, no alpha, no rounded corners (iOS adds them).

| Size | Use |
|------|-----|
| 1024×1024 | App Store (required, no alpha) |
| 180×180 | iPhone @3x |
| 120×120 | iPhone @2x / Spotlight @3x |
| 167×167 | iPad Pro @2x |
| 152×152 | iPad @2x |
| 87×87 | Settings @3x |
| 58×58 | Settings @2x |
| 80×80 | Spotlight @2x |
| 60×60 | Notifications @3x |
| 40×40 | Notifications @2x |

**Shortcut**: Upload your 1024×1024 to [appicon.co](https://www.appicon.co/) and download the full set, then drag into `Assets.xcassets → AppIcon`.

Keep the main design within 80% of canvas (820px on a 1024px canvas) to account for iOS masking.

---

## Screenshots

**Required device sizes:**
- 6.7" (1290 × 2796 px) — iPhone 15 Pro Max *(required)*
- 6.5" (1242 × 2688 px) — iPhone 11 Pro Max *(required for older iOS support)*
- 12.9" iPad Pro (2048 × 2732 px) *(if supporting iPad)*

**Recommended order (5–7 shots):**
1. Home / daily calorie summary
2. Food logging (USDA search)
3. Strava activity sync
4. Calendar / history view
5. Analytics / trends
6. Progress photos
7. Goals / BMR setup

Use realistic data. Status bar: 9:41, full battery, full signal.

---

## Xcode Build Settings Checklist

Before archiving:

- [ ] Bundle ID matches App Store Connect (e.g. `com.yourname.netfuel`)
- [ ] Version: `1.0.0` (or next release version)
- [ ] Build number incremented
- [ ] Deployment target: iOS 16.0
- [ ] Signing: Automatic, correct team selected
- [ ] `Info.plist` has privacy usage descriptions:
  - `NSCameraUsageDescription`
  - `NSPhotoLibraryUsageDescription`
  - `NSPhotoLibraryAddUsageDescription`
  - URL scheme `netfuel` registered
- [ ] `PrivacyInfo.xcprivacy` present and added to target
  - `NSPrivacyTracking`: `false`
  - Data types declared: Health & Fitness, User ID, Email, Photos

---

## TestFlight Beta Process

1. **Archive** in Xcode → Organizer → Distribute → App Store Connect
2. **Wait for processing** (~10–15 min) in App Store Connect → TestFlight
3. **Internal testers** (up to 100, your team): available immediately after processing
4. **External testers** (up to 10,000): requires brief Beta App Review (~1 day first time)
   - Add group → invite by email or public link
   - External groups need: beta description, feedback email, privacy policy URL
5. Each build expires after **90 days**; upload a new build before then

---

## Submission Checklist

### Pre-submit
- [ ] Privacy policy live at the URL above
- [ ] Support URL returning 200
- [ ] Demo account credentials working with sample data
- [ ] App tested on real device (iPhone + oldest supported iOS 16)
- [ ] All features working: auth, food logging, Strava OAuth, activities, calendar, photos, BMR/TDEE
- [ ] No crashes on any screen

### App Store Connect
- [ ] App created, bundle ID linked
- [ ] All metadata fields filled (name, subtitle, description, keywords)
- [ ] Screenshots uploaded for required sizes
- [ ] Age rating questionnaire completed (4+)
- [ ] Privacy data questionnaire completed
- [ ] Build uploaded and selected
- [ ] Export compliance answered (standard HTTPS = No custom encryption)
- [ ] Review info: demo credentials + contact email entered

### Common rejection reasons to avoid
- Missing `NSUsageDescription` keys → add all three camera/photo descriptions
- Broken privacy policy / support URL → verify URLs return 200
- Demo account not working → test before submitting
- Incomplete `PrivacyInfo.xcprivacy` → Apple checks this strictly

### After approval
- Monitor crash reports (App Store Connect → Analytics → Crashes)
- Respond to user reviews
- Test the production download (not TestFlight build)
