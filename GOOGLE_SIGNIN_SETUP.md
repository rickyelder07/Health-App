# Google Sign In Setup Guide

## Overview

This guide walks you through configuring Google Sign In for your Health Tracker app using Supabase OAuth.

**Estimated Time**: 30-40 minutes

---

## Prerequisites

- ✅ Supabase project created and configured
- ✅ Health Tracker app code updated with Google Sign In
- ✅ Google account for Google Cloud Console access
- ✅ Xcode project open and ready

---

## Step 1: Google Cloud Console Setup

### 1.1 Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Sign in with your Google account
3. Click the project dropdown at the top
4. Click **"New Project"**
5. Enter project details:
   - **Project name**: `Health Tracker`
   - **Organization**: Leave as default (No organization)
6. Click **"Create"**
7. Wait for project creation (~30 seconds)
8. Select your new project from the dropdown

### 1.2 Enable Google+ API

1. In the left sidebar, go to **"APIs & Services"** → **"Library"**
2. Search for `Google+ API`
3. Click on **"Google+ API"**
4. Click **"Enable"**
5. Wait for API to be enabled

**Note**: If Google+ API is deprecated, use **"Google Identity"** or **"People API"** instead.

### 1.3 Configure OAuth Consent Screen

1. Go to **"APIs & Services"** → **"OAuth consent screen"**
2. Select **"External"** user type
3. Click **"Create"**
4. Fill in App Information:
   - **App name**: `Health Tracker`
   - **User support email**: Your email address
   - **App logo**: (Optional) Upload your app icon
5. Fill in App Domain (Optional):
   - **Application home page**: Your website or leave blank
   - **Application privacy policy link**: Leave blank for now
   - **Application terms of service link**: Leave blank for now
6. Fill in Developer Contact Information:
   - **Email addresses**: Your email address
7. Click **"Save and Continue"**

8. **Scopes** screen:
   - Click **"Add or Remove Scopes"**
   - Select these scopes:
     - `email` - View your email address
     - `profile` - See your personal info
     - `openid` - Authenticate using OpenID Connect
   - Click **"Update"**
   - Click **"Save and Continue"**

9. **Test users** screen:
   - Click **"Add Users"**
   - Add your email address for testing
   - Click **"Add"**
   - Click **"Save and Continue"**

10. **Summary** screen:
    - Review your settings
    - Click **"Back to Dashboard"**

### 1.4 Create OAuth 2.0 Credentials

1. Go to **"APIs & Services"** → **"Credentials"**
2. Click **"Create Credentials"** → **"OAuth 2.0 Client ID"**
3. If prompted to configure consent screen, you already did in 1.3
4. Select Application type:
   - Choose **"Web application"**
5. Enter Name:
   - **Name**: `Health Tracker Web Client`
6. Add Authorized Redirect URIs:
   - Click **"Add URI"**
   - Enter: `https://YOUR_PROJECT_REF.supabase.co/auth/v1/callback`
   - Replace `YOUR_PROJECT_REF` with your actual Supabase project reference
   
   **How to find your Supabase project reference**:
   - Go to your Supabase dashboard
   - Look at the URL: `https://supabase.com/dashboard/project/YOUR_PROJECT_REF`
   - Or go to **Settings** → **API** and look at **Project URL**
   - It looks like: `pomdsflvgabgblifgvsf`

7. Click **"Create"**
8. **Copy the credentials** that appear:
   - **Client ID**: `123456789-abc...googleusercontent.com`
   - **Client Secret**: `GOCSPX-abc...xyz`
9. Click **"OK"**

**⚠️ IMPORTANT**: Keep these credentials safe! Don't commit them to public repositories.

---

## Step 2: Supabase Configuration

### 2.1 Enable Google Provider

1. Go to your [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project: **Health Tracker**
3. Go to **Authentication** → **Providers**
4. Scroll down to find **Google**
5. Click to expand the Google provider section
6. Toggle **"Enable Sign in with Google"** to ON

### 2.2 Configure Google Credentials

1. In the Google provider section, paste your credentials:
   - **Client ID**: Paste the Client ID from Google Cloud Console
   - **Client Secret**: Paste the Client Secret from Google Cloud Console
2. **Authorized Client IDs**: Leave blank (not needed for web)
3. Click **"Save"**

### 2.3 Verify Callback URL

The callback URL should automatically be:
```
https://YOUR_PROJECT_REF.supabase.co/auth/v1/callback
```

This must match what you entered in Google Cloud Console.

---

## Step 3: iOS App Configuration

### 3.1 Add URL Scheme to Info.plist

**Option A: Using Xcode UI** (Recommended)

1. Open your project in Xcode
2. Select your app target (e.g., "Healthapp")
3. Go to the **Info** tab
4. Expand **URL Types**
5. Verify `healthapp` URL scheme exists:
   - **Identifier**: `com.yourname.healthapp`
   - **URL Schemes**: `healthapp`
   - **Role**: `Editor`

If it doesn't exist:
1. Click the **+** button under URL Types
2. Add the above details

**Option B: Edit Info.plist directly**

1. Open `Info.plist` file
2. Add or verify this exists:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>com.yourname.healthapp</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>healthapp</string>
        </array>
    </dict>
</array>
```

### 3.2 Verify OAuth Callback Handling

The code has already been added to `HealthApp.swift`:

```swift
.onOpenURL { url in
    // Handle OAuth callback from Google Sign In
    Task {
        do {
            try await SupabaseClient.shared.auth.session(from: url)
            print("✅ OAuth callback handled successfully")
        } catch {
            print("❌ OAuth callback error: \(error)")
        }
    }
}
```

This automatically handles the redirect from Google back to your app.

---

## Step 4: Testing

### 4.1 Build and Run

1. Clean build folder: `Cmd + Shift + K`
2. Build: `Cmd + B`
3. Run on simulator or device: `Cmd + R`

### 4.2 Test Google Sign In

1. **Launch the app**
2. **See the authentication screen** with:
   - Email/password fields
   - "Continue with Google" button
3. **Tap "Continue with Google"**
4. **Browser opens** with Google sign in page
5. **Select your Google account**
6. **Grant permissions** (email, profile)
7. **Redirect back to app** automatically
8. **App should navigate** to home screen

### 4.3 Verify in Supabase

1. Go to **Authentication** → **Users** in Supabase dashboard
2. You should see your new user with:
   - Email from Google account
   - Provider: `google`
   - ID: UUID
3. Go to **Table Editor** → **users**
4. Verify profile was auto-created with your user ID

### 4.4 Test Sign Out and Sign In Again

1. **Sign out** from Profile screen
2. **Tap "Continue with Google"** again
3. Should be **one-tap** (no password needed)
4. Should sign in immediately

---

## Step 5: Production Checklist

### 5.1 Security

- [ ] OAuth Client Secret stored securely (only in Supabase)
- [ ] Callback URL uses HTTPS
- [ ] Test users added during development
- [ ] URL scheme is unique and matches your app

### 5.2 Google Cloud Console

- [ ] OAuth consent screen completed
- [ ] Correct scopes added (email, profile, openid)
- [ ] Authorized redirect URI matches Supabase
- [ ] App verification submitted (required before public release)

### 5.3 Supabase

- [ ] Google provider enabled
- [ ] Client ID and Secret configured
- [ ] RLS policies working for Google sign in users
- [ ] User profile trigger creates profiles for OAuth users

### 5.4 iOS App

- [ ] URL scheme configured
- [ ] OAuth callback handler implemented
- [ ] Google Sign In button visible
- [ ] Error handling implemented
- [ ] Loading states working

---

## Troubleshooting

### Issue: "Invalid OAuth client" error

**Cause**: Client ID doesn't match or isn't configured correctly

**Fix**:
1. Verify Client ID in Supabase matches Google Cloud Console exactly
2. Check for extra spaces or characters
3. Re-create OAuth credentials if needed

### Issue: "Redirect URI mismatch" error

**Cause**: Callback URL in Google Cloud Console doesn't match Supabase

**Fix**:
1. Check the callback URL in Google Cloud Console
2. Should be: `https://YOUR_PROJECT_REF.supabase.co/auth/v1/callback`
3. Add the exact URL to Authorized redirect URIs

### Issue: App doesn't redirect back after Google sign in

**Cause**: URL scheme not configured or callback not handled

**Fix**:
1. Verify URL scheme `healthapp` in Info.plist
2. Check `.onOpenURL` is in HealthApp.swift
3. Check console for OAuth callback errors
4. Try removing and re-adding URL scheme in Xcode

### Issue: "Sign in with Google" button doesn't work

**Cause**: Network error, invalid configuration, or Supabase not configured

**Fix**:
1. Check internet connection
2. Verify Google provider is enabled in Supabase
3. Check console logs for detailed error
4. Test Supabase connection with regular sign in first

### Issue: Profile not created after Google sign in

**Cause**: Database trigger not firing or RLS policy blocking

**Fix**:
1. Check trigger exists:
   ```sql
   SELECT * FROM information_schema.triggers 
   WHERE trigger_name = 'on_auth_user_created';
   ```
2. Verify INSERT policy exists:
   ```sql
   SELECT * FROM pg_policies 
   WHERE tablename = 'users' AND cmd = 'INSERT';
   ```
3. Manually create profile if needed

### Issue: "This app has not been verified" warning

**Cause**: Google requires app verification before public release

**Fix** (for development):
- Click "Advanced" → "Go to Health Tracker (unsafe)"
- This warning only appears during development

**Fix** (for production):
- Submit app for Google verification
- Go to OAuth consent screen → "Publish App"
- Follow Google's verification process

---

## Advanced Configuration

### Custom OAuth Scopes

If you want additional Google data:

1. Go to Google Cloud Console → OAuth consent screen
2. Add more scopes:
   - `https://www.googleapis.com/auth/userinfo.profile` - Profile info
   - `https://www.googleapis.com/auth/userinfo.email` - Email
   - `https://www.googleapis.com/auth/user.birthday.read` - Birthday
   - `https://www.googleapis.com/auth/user.gender.read` - Gender
3. Update Supabase to request these scopes

### Multiple OAuth Providers

To add Apple, Facebook, etc.:

1. Follow similar setup for each provider
2. Enable in Supabase → Authentication → Providers
3. Add buttons to AuthenticationView
4. Add methods to AuthenticationService:
   ```swift
   func signInWithApple() async throws -> Session
   func signInWithFacebook() async throws -> Session
   ```

### Custom Redirect URL

If you want a different URL scheme:

1. Change `healthapp://oauth-callback` to your custom URL
2. Update Info.plist URL scheme
3. Update `AuthenticationService.signInWithGoogle()` redirect parameter

---

## Security Best Practices

### 1. Protect Credentials

- ✅ Never commit OAuth secrets to Git
- ✅ Store only in Supabase (server-side)
- ✅ Use environment variables for local testing
- ✅ Rotate secrets if compromised

### 2. Validate Users

```swift
// After Google sign in, verify user has valid email
if let email = session.user.email, !email.isEmpty {
    // Proceed
} else {
    // Handle missing email
    throw AuthError.invalidCredentials
}
```

### 3. Monitor Usage

- Check Google Cloud Console → APIs & Services → Dashboard
- Monitor daily OAuth requests
- Set up billing alerts
- Review OAuth consent logs

### 4. Rate Limiting

- Supabase has built-in rate limiting
- Configure in Dashboard → Authentication → Settings
- Default: 30 sign ins per hour per user

---

## Cost Considerations

### Google Cloud Platform

- **OAuth API calls**: FREE (unlimited)
- **Google+ API**: FREE for basic usage
- **People API**: FREE for basic usage

### Supabase

- **OAuth**: Included in all plans
- **Free tier**: 50,000 monthly active users
- **Pro tier**: Unlimited users ($25/month)

**No additional costs** for Google Sign In! 🎉

---

## Next Steps

After Google Sign In is working:

1. **Test thoroughly** on real devices
2. **Add analytics** to track sign in methods
3. **Consider Apple Sign In** (required for App Store)
4. **Submit for Google verification** before public release
5. **Add other OAuth providers** as needed

---

## Support Resources

- **Supabase Auth Docs**: https://supabase.com/docs/guides/auth
- **Google OAuth Docs**: https://developers.google.com/identity/protocols/oauth2
- **Google Cloud Console**: https://console.cloud.google.com
- **Supabase Dashboard**: https://supabase.com/dashboard

---

## Quick Reference

### Important URLs

- Google Cloud Console: https://console.cloud.google.com/
- OAuth Consent Screen: APIs & Services → OAuth consent screen
- Credentials: APIs & Services → Credentials
- Supabase Auth: Dashboard → Authentication → Providers
- Callback URL format: `https://PROJECT_REF.supabase.co/auth/v1/callback`
- App URL scheme: `healthapp://oauth-callback`

### Key Files Modified

- `AuthenticationService.swift` - Added `signInWithGoogle()` method
- `AuthenticationViewModel.swift` - Added `signInWithGoogle()` method
- `AuthenticationView.swift` - Added Google Sign In button
- `HealthApp.swift` - Added `.onOpenURL()` handler
- `Info.plist` - Added URL scheme `healthapp`

---

Last Updated: December 26, 2024

