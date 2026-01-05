# App Store Submission Checklist

Complete checklist for submitting Netfuel to the App Store. Follow this step-by-step to ensure a smooth submission and approval process.

---

## Pre-Submission Requirements

### Apple Developer Account

- [ ] Active Apple Developer Program membership ($99/year)
- [ ] Payment information up to date
- [ ] Tax forms completed (if selling paid app)
- [ ] Two-factor authentication enabled

### Legal Requirements

- [ ] Privacy Policy published at: https://rickyelder07.github.io/NetFuel/privacy-policy.html
- [ ] Terms of Service published at: https://rickyelder07.github.io/NetFuel/terms-of-service.html
- [ ] Support page available at: https://rickyelder07.github.io/NetFuel/support.html
- [ ] Contact email active: support@netfuelapp.com
- [ ] All URLs return 200 status (not 404)

---

## Code & Build Configuration

### Xcode Project Settings

- [ ] **Bundle Identifier** set correctly (e.g., `com.yourname.netfuel`)
  - Location: General tab → Identity → Bundle Identifier
  - Must be unique across App Store
  - Must match App Store Connect

- [ ] **Version Number** set to 1.0.0
  - Location: General tab → Identity → Version
  - Format: MAJOR.MINOR.PATCH
  - First release should be 1.0.0

- [ ] **Build Number** set to 1 (or higher)
  - Location: General tab → Identity → Build
  - Must increment for each upload
  - Simple incrementing: 1, 2, 3...

- [ ] **Display Name** set to "Netfuel"
  - Location: General tab → Identity → Display Name
  - Shows under app icon on home screen
  - Max ~15 characters

- [ ] **Deployment Target** set to iOS 16.0 (or your minimum)
  - Location: General tab → Deployment Info
  - Match your code requirements
  - Lower = more potential users, but more testing needed

- [ ] **Supported Devices** configured
  - iPhone only, iPad only, or Universal
  - Recommendation: iPhone for Netfuel (fitness tracking)

- [ ] **Supported Orientations** configured
  - Portrait recommended for Netfuel
  - Location: General tab → Deployment Info

### Signing & Capabilities

- [ ] **Automatic Signing** enabled (recommended)
  - Or manually manage with valid provisioning profile
  - Location: Signing & Capabilities tab

- [ ] **Team** selected
  - Your Apple Developer account team

- [ ] **Capabilities** added if needed:
  - [ ] Push Notifications (if implemented)
  - [ ] Associated Domains (if using universal links)
  - [ ] Background Modes (if using background refresh)

### Info.plist Configuration

See INFO_PLIST_GUIDE.md for complete details. Verify:

- [ ] **Privacy - Camera Usage Description** (NSCameraUsageDescription)
  ```xml
  <string>Netfuel needs access to your camera to take progress photos and track your fitness journey.</string>
  ```

- [ ] **Privacy - Photo Library Usage Description** (NSPhotoLibraryUsageDescription)
  ```xml
  <string>Netfuel needs access to your photo library to save and view your progress photos.</string>
  ```

- [ ] **Privacy - Photo Library Add Usage Description** (NSPhotoLibraryAddUsageDescription)
  ```xml
  <string>Netfuel needs permission to save your progress photos to your photo library.</string>
  ```

- [ ] **URL Schemes** configured for OAuth
  ```xml
  <key>CFBundleURLTypes</key>
  <array>
      <dict>
          <key>CFBundleURLSchemes</key>
          <array>
              <string>netfuel</string>
          </array>
      </dict>
  </array>
  ```

- [ ] **Launch Screen** configured
- [ ] All required keys present (no missing descriptions)

### Privacy Manifest

See PRIVACY_MANIFEST_GUIDE.md for details. Verify:

- [ ] **PrivacyInfo.xcprivacy** file exists in project
- [ ] File added to app target (appears in Build Phases → Copy Bundle Resources)
- [ ] **NSPrivacyTracking** set to `false` (or `true` if you track)
- [ ] **NSPrivacyCollectedDataTypes** lists all data you collect:
  - [ ] Health & Fitness data
  - [ ] User ID
  - [ ] Email Address
  - [ ] Photos/Videos
  - [ ] Name
- [ ] **NSPrivacyAccessedAPITypes** includes all required reason APIs:
  - [ ] File Timestamp API (C617.1)
  - [ ] User Defaults API (CA92.1)
  - [ ] System Boot Time API (35F9.1) - if used
  - [ ] Disk Space API (E174.1) - if used

---

## Assets & Media

### App Icons

See APP_ICONS_GUIDE.md for complete specifications.

- [ ] **App Icon Set** complete in Assets.xcassets
  - [ ] 1024×1024 (App Store)
  - [ ] 180×180 (iPhone @3x)
  - [ ] 120×120 (iPhone @2x)
  - [ ] 167×167 (iPad Pro @2x)
  - [ ] 152×152 (iPad @2x)
  - [ ] 76×76 (iPad)
  - And all other required sizes

- [ ] Icons follow Apple guidelines:
  - [ ] No alpha transparency
  - [ ] Square (not rounded - iOS adds corners)
  - [ ] RGB color space
  - [ ] PNG format
  - [ ] No text overlay (if possible)
  - [ ] Consistent with brand

- [ ] Test icons on device:
  - [ ] Look good on home screen
  - [ ] Recognizable at small size
  - [ ] Match app aesthetic

### Launch Screen

See LAUNCH_SCREEN_GUIDE.md for details.

- [ ] **Launch screen** configured (storyboard or Info.plist)
- [ ] Matches app's first screen aesthetic
- [ ] No loading indicators or animations
- [ ] Supports all device sizes
- [ ] Tested on simulator and device

### Screenshots

See APP_STORE_METADATA.md for requirements.

**Required Sizes:**
- [ ] **6.7" Display** (1290 × 2796) - iPhone 15 Pro Max
  - Minimum 3 screenshots, maximum 10
- [ ] **6.5" Display** (1242 × 2688) - iPhone 11 Pro Max (if supporting older devices)

**Optional but Recommended:**
- [ ] **12.9" iPad Pro** (2048 × 2732) - if supporting iPad

**Screenshot Content:**
- [ ] At least 5-7 screenshots prepared
- [ ] Show key features:
  - [ ] Home/Daily Summary
  - [ ] Food Logging
  - [ ] Strava Integration
  - [ ] Calendar View
  - [ ] Progress Tracking
  - [ ] Profile/Goals
- [ ] Use realistic data (not empty screens)
- [ ] Consistent status bar (9:41, full battery, signal)
- [ ] High quality (not blurry)
- [ ] No placeholder text
- [ ] Annotations/captions optional but helpful

**Screenshot Order:**
1. Most important feature first (home screen)
2. Core functionality (food logging)
3. Unique features (Strava)
4. Supporting features (calendar, progress)

### App Preview Video (Optional)

- [ ] 15-30 second video prepared
- [ ] Portrait orientation
- [ ] Shows app in action
- [ ] No music or voiceover (optional)
- [ ] Same device sizes as screenshots

---

## App Store Connect Setup

### App Information

- [ ] **App created in App Store Connect**
  - https://appstoreconnect.apple.com
  - My Apps → + → New App

- [ ] **App Name**: Netfuel
  - Or variant if taken: "Netfuel - Calorie Tracker"
  - Max 30 characters

- [ ] **Subtitle**: Track Calories & Macros
  - Max 30 characters
  - Appears below app name

- [ ] **Primary Language**: English (U.S.)

- [ ] **Bundle ID**: Matches Xcode project

- [ ] **SKU**: Unique identifier (e.g., netfuel-ios-001)

- [ ] **Categories**:
  - Primary: Health & Fitness
  - Secondary: Food & Drink

### Pricing & Availability

- [ ] **Price**: Free (or set price)
- [ ] **Availability**: All countries (or select specific)
- [ ] **Pre-Order**: No (for first release)

### App Privacy

- [ ] **Privacy Policy URL**: https://rickyelder07.github.io/NetFuel/privacy-policy.html
- [ ] **Privacy questionnaire** completed:
  - [ ] Data collection types declared
  - [ ] Linked to user identity
  - [ ] Used for tracking (No for Netfuel)
  - [ ] Data collection purposes

**Data Types to Declare:**
- [ ] Health & Fitness (calories, macros, weight)
- [ ] Contact Info (email)
- [ ] User Content (photos, name)
- [ ] Identifiers (user ID)

### Version Information

- [ ] **Version Number**: 1.0.0 (matches Xcode)

- [ ] **Copyright**: © 2024 Your Name / Netfuel

- [ ] **App Description**: (see APP_STORE_METADATA.md)
  - Max 4,000 characters
  - Netfuel template ~2,400 characters
  - Highlights key features
  - Includes call to action

- [ ] **Keywords**: (see APP_STORE_METADATA.md)
  - Max 100 characters
  - Comma-separated, no spaces
  - `calorie tracker,macro,nutrition,fitness,diet,food log,strava,bmr,tdee,weight loss,muscle gain`

- [ ] **Promotional Text**: (optional, updatable without new version)
  - Max 170 characters
  - Highlight new features or updates

- [ ] **Support URL**: https://rickyelder07.github.io/NetFuel/support.html

- [ ] **Marketing URL**: (optional) https://rickyelder07.github.io/NetFuel/

### Screenshots & Media

- [ ] Screenshots uploaded for all required device sizes
- [ ] Screenshots in correct order (most important first)
- [ ] App Preview video uploaded (optional)

### Age Rating

- [ ] **Age rating questionnaire** completed
  - Recommendation for Netfuel: **4+** (No Objectionable Content)
  - Medical/Treatment info: Infrequent/Mild (for BMR/TDEE)
  - All others: None

### App Review Information

Critical for approval:

- [ ] **Sign-in required**: Yes
- [ ] **Demo account credentials** provided:
  ```
  Username: demo@netfuelapp.com
  Password: Demo123!
  ```
- [ ] Demo account is working and has sample data
- [ ] **Contact Information**:
  - First Name, Last Name
  - Phone Number
  - Email: ricky.elder07@gmail.com

- [ ] **Notes for reviewer**:
  ```
  Thank you for reviewing Netfuel!

  FEATURES TO TEST:
  1. Food logging - Try adding a meal from the USDA database
  2. Strava integration - Demo account already connected
  3. Calendar view - See nutrition history
  4. Progress tracking - View charts and summaries

  DEMO CREDENTIALS:
  Email: demo@netfuelapp.com
  Password: Demo123!

  The app includes Strava integration for automatic activity syncing.
  API keys are configured and active.

  Contact: ricky.elder07@gmail.com for any questions.
  ```

- [ ] **Attachment** (if needed): None typically required

### Build Upload

- [ ] **Build uploaded** to App Store Connect
  - Via Xcode Organizer
  - Status: Processing → Missing Compliance → Ready to Submit

- [ ] **Export Compliance** provided:
  - Does your app use encryption? **No** (standard HTTPS exempt)
  - If asked, declare no custom encryption

- [ ] **Build selected** in App Store Connect:
  - Go to version → Build section
  - Click "+" to select build
  - Choose your uploaded build

---

## Quality Assurance

### Testing on Device

- [ ] **Test on real device** (not just simulator)
  - iPhone 13/14/15 recommended
  - Test on oldest supported iOS version (16.0)

- [ ] **All features working**:
  - [ ] Sign up / Sign in
  - [ ] Food logging (USDA search)
  - [ ] Custom food creation
  - [ ] Strava OAuth flow
  - [ ] Activity syncing
  - [ ] Daily summary calculations
  - [ ] Calendar navigation
  - [ ] Progress photos
  - [ ] Weight tracking
  - [ ] Profile updates
  - [ ] BMR/TDEE calculations
  - [ ] Sign out

- [ ] **No crashes**:
  - [ ] All screens load without crashing
  - [ ] No crashes during normal use
  - [ ] Graceful error handling

- [ ] **Network conditions**:
  - [ ] Works on WiFi
  - [ ] Works on cellular data
  - [ ] Handles offline gracefully (shows error)
  - [ ] Handles slow network (loading states)

- [ ] **Permissions**:
  - [ ] Camera permission prompt shows correct description
  - [ ] Photo library permission prompt shows correct description
  - [ ] App works if permissions denied (shows appropriate message)

- [ ] **UI/UX**:
  - [ ] All text readable (correct size, contrast)
  - [ ] Buttons tappable (not too small)
  - [ ] Navigation intuitive
  - [ ] Loading states clear
  - [ ] Error messages helpful
  - [ ] No typos or grammar errors
  - [ ] Consistent design throughout

### Performance

- [ ] **App launches quickly** (<3 seconds)
- [ ] **Smooth scrolling** (60 fps)
- [ ] **Images load promptly**
- [ ] **No memory leaks** (test with Instruments)
- [ ] **Battery usage reasonable** (not draining battery)

### TestFlight Beta Testing

See TESTFLIGHT_GUIDE.md for complete process.

- [ ] **Internal testing completed** (your team)
- [ ] **External beta testing completed** (20+ testers)
- [ ] **Feedback addressed** (critical bugs fixed)
- [ ] **Crash rate acceptable** (<1% per session)
- [ ] **Positive tester sentiment**

---

## Common Rejection Reasons (Avoid These)

### Technical Issues

❌ **Crashes or bugs**
- Solution: Test thoroughly, fix all crashes

❌ **Incomplete functionality**
- Solution: All advertised features must work

❌ **Poor performance**
- Solution: Optimize loading, scrolling, battery usage

❌ **Broken links**
- Solution: Test all URLs (privacy policy, support, terms)

### Privacy & Permissions

❌ **Missing usage descriptions**
- Solution: Add all NSUsageDescription keys to Info.plist

❌ **Privacy manifest errors**
- Solution: Ensure PrivacyInfo.xcprivacy is complete and accurate

❌ **Requesting unnecessary permissions**
- Solution: Only request permissions you actually use

### Content & Metadata

❌ **Misleading screenshots or description**
- Solution: Accurately represent app functionality

❌ **Placeholder content**
- Solution: Use real data in screenshots, no "Lorem ipsum"

❌ **Demo account doesn't work**
- Solution: Test credentials before submission

❌ **App doesn't match description**
- Solution: Ensure all described features work

### Design & UI

❌ **UI too similar to Apple apps**
- Solution: Use unique design, not Apple's system UI

❌ **Confusing user experience**
- Solution: Make navigation clear and intuitive

❌ **Text too small to read**
- Solution: Use minimum 11pt font, ensure readability

### Legal & Business

❌ **Missing privacy policy**
- Solution: Publish privacy policy at provided URL

❌ **In-app purchases not implemented correctly**
- Solution: Use StoreKit for all purchases (N/A for Netfuel free version)

❌ **Content rights issues**
- Solution: Only use content you own or have rights to

---

## Submission Process

### Final Checks

Before clicking "Submit for Review":

- [ ] All checklist items above completed
- [ ] Build tested one final time
- [ ] Demo account working
- [ ] All URLs returning 200
- [ ] No known critical bugs
- [ ] All metadata reviewed for accuracy
- [ ] Screenshots reviewed for quality

### Submit for Review

1. **Go to App Store Connect**
2. **Select your app** → **iOS App** → **Version 1.0.0**
3. **Verify all information**:
   - App information ✓
   - Pricing & Availability ✓
   - Privacy ✓
   - Version info ✓
   - Screenshots ✓
   - Build selected ✓
   - Age rating ✓
   - App Review info ✓
4. **Click "Submit for Review"**
5. **Confirm submission**

### Review Timeline

- **In Review**: 24-48 hours typically (can be up to 7 days)
- **Status updates**: Watch email and App Store Connect

**Possible Statuses:**
- **Waiting for Review**: In queue
- **In Review**: Apple is reviewing
- **Pending Developer Release**: Approved! (you control release)
- **Ready for Sale**: Live on App Store!
- **Rejected**: See rejection reason, fix, resubmit

### If Approved

1. **Celebrate!** 🎉
2. **App automatically goes live** (unless you chose manual release)
3. **Monitor for**:
   - Crash reports (App Store Connect → Analytics)
   - User reviews (respond to reviews)
   - Download numbers
4. **Thank beta testers**
5. **Promote your app**:
   - Social media
   - Personal network
   - Fitness communities

### If Rejected

1. **Read rejection reason carefully**
2. **Don't panic** - most apps are rejected at least once
3. **Fix the issue**:
   - If code fix needed: Update code, upload new build
   - If metadata fix: Update in App Store Connect (no new build needed)
4. **Respond in Resolution Center** (if applicable)
5. **Resubmit for review**
6. **Add notes** explaining what you fixed

---

## Post-Submission Monitoring

### First 24 Hours

- [ ] Monitor crash reports
- [ ] Check user reviews
- [ ] Test app downloaded from App Store (not TestFlight)
- [ ] Verify all features work in production
- [ ] Respond to any critical issues

### First Week

- [ ] Collect user feedback
- [ ] Monitor analytics (downloads, sessions)
- [ ] Plan first update (if needed)
- [ ] Engage with reviewers

### Ongoing

- [ ] Regular updates (bug fixes, features)
- [ ] Respond to reviews
- [ ] Monitor crash reports
- [ ] Update metadata (keywords, screenshots) as needed

---

## Quick Reference URLs

- **App Store Connect**: https://appstoreconnect.apple.com
- **Apple Developer**: https://developer.apple.com
- **TestFlight**: https://developer.apple.com/testflight/
- **App Review Guidelines**: https://developer.apple.com/app-store/review/guidelines/
- **Human Interface Guidelines**: https://developer.apple.com/design/human-interface-guidelines/

---

## Version 1.0.0 Submission Checklist Summary

Print this and check off as you go:

### Pre-Submission
- [ ] Xcode configuration complete
- [ ] Info.plist complete
- [ ] Privacy manifest added
- [ ] App icons complete
- [ ] Launch screen configured
- [ ] Privacy policy published
- [ ] Support page published

### Assets
- [ ] Screenshots prepared (6.7" required)
- [ ] App description written
- [ ] Keywords optimized
- [ ] Demo account created and tested

### Testing
- [ ] Tested on real device
- [ ] All features working
- [ ] No crashes
- [ ] Beta testing completed

### App Store Connect
- [ ] App created
- [ ] All metadata entered
- [ ] Build uploaded and selected
- [ ] Export compliance provided
- [ ] Review information complete
- [ ] Demo credentials provided

### Final
- [ ] One last device test
- [ ] Demo account verified
- [ ] Submit for review
- [ ] Monitor for updates

---

**You're ready to submit!** Good luck with your App Store submission! 🚀

**Status**: App Store submission checklist complete
**All PROMPT 17 items completed!**
