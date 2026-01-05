# TestFlight Setup Guide

## What is TestFlight?

TestFlight is Apple's official beta testing platform for iOS apps. It allows you to:
- Distribute pre-release builds to up to 10,000 testers
- Get feedback before public release
- Test on real devices with real users
- Iterate quickly without App Store review (for most changes)

## Benefits of TestFlight

✅ **Internal Testing**: Up to 100 internal testers (your team)
✅ **External Testing**: Up to 10,000 external testers (beta users)
✅ **No Review for Internal**: Internal builds available immediately
✅ **Feedback Collection**: Built-in screenshot and feedback tools
✅ **Crash Reports**: Automatic crash reporting and diagnostics
✅ **Multiple Builds**: Test different versions simultaneously
✅ **Free**: No cost to use TestFlight

---

## Prerequisites

Before starting TestFlight beta testing:

- [ ] Apple Developer account ($99/year)
- [ ] App created in App Store Connect
- [ ] Valid provisioning profile and certificate
- [ ] Build uploaded to App Store Connect
- [ ] App icons configured (see APP_ICONS_GUIDE.md)
- [ ] Privacy manifest added (see PRIVACY_MANIFEST_GUIDE.md)
- [ ] Info.plist configured (see INFO_PLIST_GUIDE.md)

---

## Step 1: Create App in App Store Connect

1. **Go to App Store Connect**: https://appstoreconnect.apple.com
2. **Click "My Apps"** → **"+" button** → **"New App"**
3. **Fill in details**:
   - **Platform**: iOS
   - **Name**: Netfuel
   - **Primary Language**: English (U.S.)
   - **Bundle ID**: Select your bundle ID (e.g., `com.yourname.netfuel`)
   - **SKU**: Unique identifier (e.g., `netfuel-ios-001`)
   - **User Access**: Full Access

4. **Click "Create"**

---

## Step 2: Configure App Information

### App Information Tab

1. **Privacy Policy URL**: `https://rickyelder07.github.io/NetFuel/privacy-policy.html`
2. **Category**:
   - Primary: Health & Fitness
   - Secondary: Food & Drink
3. **Content Rights**: Check if your app contains third-party content

### Pricing and Availability

1. **Price**: Free (or set your price)
2. **Availability**: All countries/regions (or select specific)

---

## Step 3: Create Your First Build

### Archive Your App

1. **Open Xcode** with your Netfuel project
2. **Select device target**: Any iOS Device (arm64)
   - In toolbar, click the device dropdown
   - Select "Any iOS Device (arm64)"
3. **Clean build**: Product → Clean Build Folder (⌘⇧K)
4. **Archive**: Product → Archive
   - Wait for build to complete (can take 5-10 minutes)
   - Organizer window appears when done

### Validate Archive

Before uploading, validate your archive:

1. In **Organizer**, select your archive
2. Click **"Validate App"**
3. Choose signing options:
   - **Automatically manage signing** (recommended)
   - Or manually select provisioning profile
4. Click **"Validate"**
5. Fix any errors/warnings that appear

### Upload to App Store Connect

1. In **Organizer**, click **"Distribute App"**
2. Choose **"App Store Connect"**
3. Click **"Upload"**
4. Select signing options (same as validation)
5. Review app information
6. Click **"Upload"**
7. Wait for upload to complete (5-15 minutes)

### Verify Upload

1. Go to **App Store Connect** → **My Apps** → **Netfuel**
2. Click **"TestFlight"** tab
3. Under **"iOS"**, your build should appear with status:
   - **Processing** (yellow) - Apple is processing (15-60 min)
   - **Missing Compliance** (requires action)
   - **Ready to Submit** (ready for external testing)
   - **Ready to Test** (ready for internal testing)

---

## Step 4: Export Compliance

For first build, you'll need to provide export compliance info:

1. In **TestFlight** tab, click on your build
2. Click **"Provide Export Compliance Information"**
3. Answer questions:
   - **Does your app use encryption?**
     - If using HTTPS only: **No** (standard encryption exempt)
     - If using custom crypto: **Yes** (need more info)
   - For Netfuel: Select **"No"** (uses standard HTTPS)
4. Click **"Start Internal Testing"**

Build is now available to internal testers!

---

## Step 5: Add Internal Testers

Internal testers = Your development team (up to 100 people)

### Add Testers

1. Go to **App Store Connect** → **Users and Access**
2. Click **"+" button** → **"Add Users"**
3. Enter tester details:
   - Email address
   - First name, Last name
   - Roles: **App Manager** or **Developer** or **Marketing**
4. Assign them to your app

OR

1. Go to **TestFlight** tab in your app
2. Click **"Internal Testing"** → **"App Store Connect Users"**
3. Click **"+" button**
4. Select users to add as testers

### Tester Gets Email

1. Tester receives invitation email
2. Tester installs **TestFlight app** from App Store
3. Tester accepts invitation
4. App appears in TestFlight app
5. Tester clicks **"Install"**

---

## Step 6: External Testing (Beta Testers)

External testers = Public beta testers (up to 10,000 people)

### Create External Test Group

1. Go to **TestFlight** tab
2. Click **"External Testing"** (left sidebar)
3. Click **"+" button** → **"Create New Group"**
4. Enter group details:
   - **Group Name**: Public Beta (or Beta Testers)
   - **Enable automatic distribution**: Optional (auto-send new builds)
5. Click **"Create"**

### Add Build to External Group

1. Select your external test group
2. Click **"Builds"** section
3. Click **"+" button**
4. Select your build
5. Add **"What to Test"** notes for testers
6. Click **"Next"**

### Submit for Beta App Review

External builds require Apple review (first time only):

1. Fill in **"Beta App Description"** (what does your app do?)
2. Fill in **"Beta App Review Information"**:
   - **Contact Email**: ricky.elder07@gmail.com
   - **Phone Number**: Your phone
   - **Sign-In Required**: Yes
   - **Demo Account**: demo@netfuelapp.com / Demo123!
   - **Notes**: Any special instructions for reviewers
3. Click **"Submit for Review"**

**Review time**: 24-48 hours typically

### Add External Testers

After approval, add testers:

1. In external test group, click **"Testers"** tab
2. Click **"+" button** → **"Add New Testers"**
3. Enter tester emails (one per line)
4. Click **"Add"**

OR share public link:

1. Enable **"Public Link"** in group settings
2. Share link with testers
3. Anyone with link can join (up to 10,000)

---

## Step 7: What to Test - Beta Testing Checklist

Provide this checklist to your beta testers:

### Essential Features to Test

**Authentication & Onboarding**
- [ ] Sign up with email/password
- [ ] Sign in with existing account
- [ ] Password reset flow
- [ ] Profile setup (weight, height, age, gender, activity level)
- [ ] BMR/TDEE calculation appears correctly

**Food Logging**
- [ ] Search for food in USDA database
- [ ] Add food to today's log
- [ ] Edit food entry
- [ ] Delete food entry
- [ ] Add custom food
- [ ] Verify calorie/macro totals update

**Strava Integration**
- [ ] Connect Strava account (OAuth flow)
- [ ] Sync activities from Strava
- [ ] Verify calories burned appear in daily summary
- [ ] Disconnect Strava account

**Daily Summary & Calendar**
- [ ] View today's summary (calories consumed/burned, net)
- [ ] Navigate calendar to past dates
- [ ] Verify historical data displays correctly
- [ ] Check macro breakdown (protein, carbs, fat)

**Progress Tracking**
- [ ] Upload progress photo
- [ ] View progress photos in gallery
- [ ] Log weight update
- [ ] View weight chart/timeline

**Profile & Settings**
- [ ] Update weight
- [ ] Update height
- [ ] Update activity level
- [ ] Verify BMR/TDEE recalculates
- [ ] Update macro targets
- [ ] Sign out

### Edge Cases to Test

- [ ] Use app offline (no internet)
- [ ] Poor network conditions (slow 3G)
- [ ] Sign in on different device
- [ ] Delete and reinstall app (data persists?)
- [ ] Background app and return
- [ ] Receive push notification (if implemented)
- [ ] Large food logs (50+ entries in one day)
- [ ] Multiple Strava activity syncs

### UI/UX to Evaluate

- [ ] All screens render correctly on your device
- [ ] Text is readable (not too small)
- [ ] Buttons are tappable (not too small)
- [ ] Navigation is intuitive
- [ ] Loading states are clear
- [ ] Error messages are helpful
- [ ] Dark mode works correctly (if supported)
- [ ] Forms are easy to complete

### Performance

- [ ] App launches quickly
- [ ] No freezing or stuttering
- [ ] Images load promptly
- [ ] Smooth scrolling
- [ ] No crashes during testing

---

## Step 8: Collecting Feedback

### Built-in TestFlight Feedback

Testers can:
1. **Take screenshots**: Use TestFlight button overlay
2. **Send feedback**: Describe issue, attach screenshot
3. You receive feedback in App Store Connect → TestFlight → Feedback

### External Feedback Channels

Set up additional channels:

**Email**: support@netfuelapp.com
- Direct tester feedback here
- Respond to questions

**TestFlight "What to Test" Notes**
- Include in each build
- Tell testers what's new
- Ask for specific feedback

**Survey** (optional):
- Google Forms or TypeForm
- Ask structured questions
- Rate features, overall experience

Example questions:
- How easy was it to log your first meal? (1-5)
- Did Strava integration work smoothly? (Yes/No)
- What feature would you like to see next?
- Any bugs or issues encountered?

---

## Step 9: Managing Builds

### Uploading New Builds

When you fix bugs or add features:

1. **Increment build number** in Xcode:
   - General tab → Identity → Build
   - 1 → 2 → 3 (increment each upload)
   - Version can stay same (e.g., 1.0.0)

2. **Archive and upload** (same as Step 3)

3. **Add to test groups**:
   - Internal: Automatic
   - External: Add to group, no review needed (unless binary changes significantly)

4. **Update "What to Test"**:
   - Describe what's new/fixed
   - "Fixed crash when syncing Strava"
   - "Added ability to edit custom foods"

### Build Expiration

TestFlight builds expire after **90 days**

- Upload new build every 90 days to keep testing active
- Testers see expiration countdown in TestFlight app

### Managing Testers

**Remove testers**:
1. Go to test group
2. Click tester name
3. Click "Remove from Group"

**Resend invitations**:
1. Click tester name
2. Click "Resend Invitation"

**View tester sessions**:
1. Click tester name
2. See install history, sessions, feedback

---

## Step 10: Beta App Review Process

### What Apple Reviews

For external testing, Apple reviews:
- App functionality (does it work?)
- Privacy practices (privacy manifest correct?)
- Content (appropriate for App Store?)
- Metadata (description accurate?)

### Review Timeline

- **First submission**: 24-48 hours
- **Updates**: Most don't require review if binary is similar

### Common Rejection Reasons

❌ **Missing demo account** (provide test credentials)
❌ **Crashes during review** (test thoroughly first)
❌ **Missing privacy manifest or usage descriptions**
❌ **Misleading description** (be accurate)
❌ **Incomplete app** (core features must work)

### If Rejected

1. Read rejection reason carefully
2. Fix the issue
3. Upload new build
4. Resubmit for review
5. Add notes explaining what you fixed

---

## TestFlight Best Practices

### For Developers

1. **Start with internal testing** before external
2. **Test on multiple devices** (iPhone, iPad, different sizes)
3. **Provide clear "What to Test" notes** for each build
4. **Respond to feedback quickly** (acknowledge and thank testers)
5. **Upload builds regularly** (weekly during active development)
6. **Don't rush to App Store** (iterate in TestFlight first)
7. **Keep demo account working** (Apple uses it for each review)

### What to Tell Testers

**Welcome Email Template**:

```
Subject: Welcome to Netfuel Beta! 🔥

Hi [Name],

Thanks for joining the Netfuel beta! You're helping shape the future of calorie tracking.

GETTING STARTED:
1. Install TestFlight from the App Store
2. Accept the invitation email
3. Install Netfuel from TestFlight
4. Sign in with email: demo@netfuelapp.com, password: Demo123!
   (Or create your own account)

WHAT TO TEST:
- Log your meals using USDA food search
- Connect your Strava account to sync workouts
- Try the daily summary and calendar views
- Upload progress photos

FOUND A BUG?
- Use the TestFlight feedback button (top left)
- Or email: support@netfuelapp.com

Your feedback is invaluable! Thank you!

- The Netfuel Team
```

### Building a Good Beta Group

**Recruit testers from**:
- Friends and family (honest feedback)
- Fitness communities (target audience)
- Reddit (r/fitness, r/loseit)
- Social media (Instagram, Twitter)
- Running/cycling clubs (Strava users!)

**Ideal beta group**:
- 20-50 active testers
- Mix of technical and non-technical users
- Different devices (iPhone 12, 14, 15, SE)
- Different iOS versions (16, 17, 18)
- Your target audience (fitness enthusiasts)

---

## Metrics to Track

In **App Store Connect → TestFlight → Builds**, you can see:

- **Installs**: How many testers installed
- **Sessions**: How actively testers use the app
- **Crashes**: Crash reports with stack traces
- **Feedback**: Submitted feedback and screenshots

**Key metrics**:
- **Install rate**: % of invited testers who install
- **Session length**: How long testers use app
- **Crash rate**: Crashes per session (aim for <1%)
- **Feedback volume**: More feedback = more engaged testers

---

## Moving from TestFlight to App Store

When your app is ready for public release:

1. **Final TestFlight build** with no critical bugs
2. **Collect final feedback** from testers
3. **Prepare App Store submission** (see APP_STORE_SUBMISSION_CHECKLIST.md)
4. **Use same build** from TestFlight for App Store
5. **Thank your beta testers!** (email, in-app credit, etc.)

You can keep TestFlight running alongside App Store release:
- Test new features in TestFlight
- Release stable builds to App Store

---

## Troubleshooting

### Build stuck on "Processing"
- Wait 1-2 hours (normal)
- If >24 hours, contact Apple Developer Support

### Tester can't install
- Check email address is correct
- Resend invitation
- Ensure tester has iOS 16+ (your minimum version)
- Check TestFlight app is updated

### Build rejected
- Read rejection email carefully
- Fix issue and upload new build
- Add notes explaining changes

### Crash reports not appearing
- Wait 24 hours (reports are delayed)
- Ensure testers opted in to sharing diagnostics
- Check that build has symbols uploaded

### Export compliance keeps asking
- Save your answers (appears for each build)
- Or add ITSAppUsesNonExemptEncryption to Info.plist

---

## Resources

- [TestFlight Beta Testing (Apple)](https://developer.apple.com/testflight/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [TestFlight Public Link Best Practices](https://developer.apple.com/testflight/testers/)

---

## Checklist

Before starting TestFlight:

- [ ] Apple Developer account active
- [ ] App created in App Store Connect
- [ ] Build validated and uploaded
- [ ] Export compliance provided
- [ ] Internal testers added
- [ ] "What to Test" notes written
- [ ] Demo account created and working
- [ ] Feedback collection method set up

For external testing:

- [ ] Beta app description written
- [ ] Beta review information completed
- [ ] Demo account credentials provided
- [ ] Build submitted for beta review
- [ ] External test group created
- [ ] Testers invited or public link shared

---

**Status**: TestFlight guide complete
**Next**: App Store Submission Checklist (see APP_STORE_SUBMISSION_CHECKLIST.md)
