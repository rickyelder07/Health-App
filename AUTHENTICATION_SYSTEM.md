# Authentication System Documentation

## Overview

Complete authentication system using Supabase Auth with email/password authentication, password reset, and automatic session management.

---

## Components

### 1. AuthenticationService

**Location**: `Services/AuthenticationService.swift`

Handles all authentication operations with Supabase.

**Features**:
- ✅ Sign up with email/password
- ✅ Sign in with email/password
- ✅ Sign out
- ✅ Password reset
- ✅ Session management
- ✅ Token auto-refresh
- ✅ Auth state observation

**Methods**:

```swift
// Sign up new user
func signUp(email: String, password: String) async throws -> Session?

// Sign in existing user
func signIn(email: String, password: String) async throws -> Session

// Sign out current user
func signOut() async throws

// Send password reset email
func resetPassword(email: String) async throws

// Update user password
func updatePassword(newPassword: String) async throws

// Get current session
func getCurrentSession() async -> Session?

// Get current user ID
func getCurrentUserId() async -> UUID?

// Observe auth state changes
func observeAuthState(onStateChange: @escaping (Session?) -> Void) -> AnyCancellable

// Refresh session token
func refreshSession() async throws -> Session

// Check if session is expired
func isSessionExpired() async -> Bool
```

---

### 2. AuthenticationViewModel

**Location**: `ViewModels/AuthenticationViewModel.swift`

Manages authentication UI state and orchestrates auth operations.

**Published Properties**:
```swift
@Published var email: String
@Published var password: String
@Published var confirmPassword: String
@Published var isLoading: Bool
@Published var errorMessage: String?
@Published var successMessage: String?
@Published var isSignUpMode: Bool
@Published var showForgotPassword: Bool
```

**Key Methods**:
```swift
// Sign in user
func signIn() async

// Sign up new user
func signUp() async

// Send password reset email
func sendPasswordReset() async

// Toggle between sign in/sign up
func toggleMode()

// Dismiss keyboard
func dismissKeyboard()

// Clear form
func clearForm()
```

**Features**:
- ✅ Form validation
- ✅ Error handling
- ✅ Loading states
- ✅ Success/error messaging
- ✅ Auto-fetch user profile after auth
- ✅ Auth state monitoring

---

### 3. Views

#### AuthenticationView

**Location**: `Views/AuthenticationView.swift`

Main authentication screen with sign in and sign up modes.

**Features**:
- ✅ Email/password input fields
- ✅ Toggle between sign in/sign up
- ✅ Forgot password link
- ✅ Loading indicators
- ✅ Error/success messages
- ✅ Keyboard management
  - Focus states
  - Submit labels
  - Tap to dismiss
- ✅ Form validation
- ✅ Disabled state during loading

**UI Elements**:
- App logo and branding
- Email field (with email keyboard)
- Password field (secure entry)
- Confirm password (sign up only)
- Forgot password button (sign in only)
- Primary action button (Sign In/Sign Up)
- Mode toggle button
- Success/error message banners

#### ForgotPasswordView

**Location**: `Views/ForgotPasswordView.swift`

Dedicated password reset flow.

**Features**:
- ✅ Email input field
- ✅ Send reset link button
- ✅ Success confirmation
- ✅ Error handling
- ✅ Auto-focus on email field
- ✅ Loading indicators
- ✅ Back to sign in navigation
- ✅ Prevent dismiss during loading

**UI Elements**:
- Reset password header with icon
- Email input field
- Send reset link button
- Success/error banners
- Back to sign in button
- Cancel button

---

### 4. AppState

**Location**: `AppState.swift`

Global application state with session management.

**Features**:
- ✅ Current user tracking
- ✅ Authentication status
- ✅ Session monitoring
- ✅ Auto-refresh timer (every 5 minutes)
- ✅ Automatic session refresh
- ✅ Sign out handling

**Methods**:
```swift
// Check current auth status
func checkAuthenticationStatus()

// Setup periodic session checks
private func setupSessionRefreshTimer()

// Check and refresh if needed
func checkAndRefreshSession() async

// Set current user
func setUser(_ user: User?)

// Sign out user
func signOut() async
```

---

## Authentication Flow

### Sign Up Flow

1. **User enters email and password**
   - Email validation
   - Password strength check (min 6 characters)
   - Password confirmation match

2. **Tap "Sign Up" button**
   - Disable form during loading
   - Show loading indicator

3. **AuthenticationService.signUp()**
   - Create account in Supabase Auth
   - May return nil session if email confirmation required

4. **Handle response**:
   - **With session**: Auto-fetch user profile → Navigate to app
   - **Without session**: Show "Check your email" message

5. **Database trigger creates profile**
   - `on_auth_user_created` trigger fires
   - Creates row in `public.users`

6. **Fetch user profile**
   - Query `public.users` table
   - Decode and store in AppState
   - Update authentication status

---

### Sign In Flow

1. **User enters credentials**
   - Email validation
   - Required field checks

2. **Tap "Sign In" button**
   - Disable form during loading
   - Show loading indicator

3. **AuthenticationService.signIn()**
   - Authenticate with Supabase
   - Return session with user data

4. **Fetch user profile**
   - Query `public.users` for profile data
   - Include BMR/TDEE calculations

5. **Update AppState**
   - Store user object
   - Set authenticated = true
   - Navigate to home screen

---

### Password Reset Flow

1. **User clicks "Forgot Password?"**
   - Sheet presents ForgotPasswordView

2. **User enters email**
   - Email validation
   - Required field check

3. **Tap "Send Reset Link"**
   - AuthenticationService.resetPassword()
   - Supabase sends reset email

4. **Show success message**
   - "Password reset email sent!"
   - Auto-dismiss after 2 seconds

5. **User receives email**
   - Opens link in email
   - Redirected to Supabase reset page
   - Enters new password

6. **User signs in**
   - Use new password to sign in

---

### Sign Out Flow

1. **User taps "Sign Out"**
   - Confirmation alert appears

2. **User confirms**
   - AuthenticationService.signOut()
   - Clear session in Supabase

3. **Clear local state**
   - AppState.currentUser = nil
   - isAuthenticated = false

4. **Navigate to auth screen**
   - ContentView detects auth state
   - Shows AuthenticationView

---

## Session Management

### Auto-Refresh System

**Timer-based checking** (every 5 minutes):

1. Check if session is expired
2. If expiring soon (< 5 min), refresh token
3. If refresh fails, sign out user

**Implementation**:

```swift
// In AppState.swift
private func setupSessionRefreshTimer() {
    sessionRefreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
        Task {
            await self?.checkAndRefreshSession()
        }
    }
}
```

### Auth State Observer

**Real-time auth changes**:

```swift
authService.observeAuthState { session in
    if let session = session {
        // User signed in or token refreshed
        await fetchUserProfile(userId: session.user.id)
    } else {
        // User signed out
        appState.setUser(nil)
    }
}
```

**Events monitored**:
- `.signedIn` - User logged in
- `.signedOut` - User logged out
- `.tokenRefreshed` - Token auto-refreshed
- `.userUpdated` - User data changed

---

## Error Handling

### AuthError Enum

```swift
enum AuthError: LocalizedError {
    case emailConfirmationRequired
    case invalidCredentials
    case userNotFound
    case weakPassword
    case emailAlreadyInUse
    case passwordResetFailed
    case sessionExpired
    case noSession
    case networkError
}
```

### Error Display

**In Views**:
- Red banner with icon
- Clear error message
- Auto-dismiss after 5 seconds (optional)

**In Console**:
- Detailed logging with emojis
- Error type and description
- Stack trace for debugging

---

## Validation Rules

### Email Validation

- Not empty
- Valid email format (regex)
- Lowercase normalized
- Trim whitespace

```swift
let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
return emailPredicate.evaluate(with: email)
```

### Password Validation

**Sign In**:
- Not empty

**Sign Up**:
- Not empty
- Minimum 6 characters
- Matches confirmation field

---

## Keyboard Management

### Focus States

```swift
enum Field {
    case email
    case password
    case confirmPassword
}

@FocusState private var focusedField: Field?
```

### Submit Behavior

- **Email field**: Moves to password on Return
- **Password field (sign in)**: Submits form on Return
- **Password field (sign up)**: Moves to confirm on Return
- **Confirm password**: Submits form on Return

### Dismiss Methods

1. **Tap outside**: Tap gesture on ScrollView
2. **Submit**: Auto-dismiss after form submission
3. **Manual**: `dismissKeyboard()` method

---

## Security Features

### Password Storage

- ✅ Never stored locally
- ✅ Secure text entry fields
- ✅ Cleared after submission
- ✅ Not logged to console

### Session Tokens

- ✅ Stored securely by Supabase SDK
- ✅ Auto-refreshed before expiry
- ✅ Invalidated on sign out
- ✅ Short-lived (configurable in Supabase)

### Database Security

- ✅ Row Level Security (RLS) enabled
- ✅ Users can only access own data
- ✅ Profile auto-created via trigger
- ✅ API keys use anon role

---

## Configuration

### Supabase Dashboard Settings

**Authentication → Settings**:

1. **Email Auth**: Enabled
2. **Confirm email**: Optional (toggle based on needs)
   - `true`: User must confirm email before sign in
   - `false`: Immediate access after sign up

3. **Secure password change**: Enabled
4. **Minimum password length**: 6 characters

**Authentication → Email Templates**:

Customize email templates:
- Confirmation email
- Password reset email
- Magic link email (if used)

---

## Testing Checklist

### Sign Up

- [ ] Valid email and password creates account
- [ ] Invalid email shows error
- [ ] Weak password shows error
- [ ] Password mismatch shows error
- [ ] Duplicate email shows error
- [ ] Profile auto-created in database
- [ ] Session created successfully
- [ ] User navigates to home screen

### Sign In

- [ ] Valid credentials sign in successfully
- [ ] Invalid credentials show error
- [ ] User profile fetched from database
- [ ] BMR/TDEE loaded correctly
- [ ] Session persists on app restart
- [ ] "Remember me" works (default behavior)

### Password Reset

- [ ] Email validation works
- [ ] Reset email sent successfully
- [ ] Success message displays
- [ ] View auto-dismisses
- [ ] User receives email
- [ ] Reset link works
- [ ] Can sign in with new password

### Session Management

- [ ] Session persists on app restart
- [ ] Auto-refresh works before expiry
- [ ] Expired session signs out user
- [ ] Manual sign out works
- [ ] Sign out confirmation works

### UI/UX

- [ ] Loading states show correctly
- [ ] Error messages display properly
- [ ] Success messages display properly
- [ ] Keyboard dismisses on tap
- [ ] Form fields focus correctly
- [ ] Submit on Return key works
- [ ] Buttons disabled when empty
- [ ] Loading disables interactions

---

## Troubleshooting

### "Database error saving new user"

**Cause**: Trigger or RLS policy issue

**Fix**:
```sql
-- Ensure INSERT policy exists
CREATE POLICY "Allow trigger to insert users" 
ON public.users 
FOR INSERT 
WITH CHECK (true);

-- Verify trigger exists
SELECT * FROM information_schema.triggers 
WHERE trigger_name = 'on_auth_user_created';
```

### "No session found"

**Cause**: Email confirmation enabled but not confirmed

**Fix**: Check email for confirmation link, or disable email confirmation in Supabase dashboard

### "Failed to fetch user profile"

**Cause**: Profile not created or missing columns

**Fix**:
```sql
-- Check if profile exists
SELECT * FROM public.users WHERE id = 'USER_ID';

-- Manually create if missing
INSERT INTO public.users (id, created_at, updated_at)
VALUES ('USER_ID', NOW(), NOW());
```

### Session not refreshing

**Cause**: Timer not running or token already expired

**Fix**: Check AppState initialization and timer setup

---

## Best Practices

### Security

1. **Never log passwords** or sensitive data
2. **Always validate** user input
3. **Use HTTPS** for all API calls (automatic with Supabase)
4. **Implement rate limiting** in Supabase dashboard
5. **Monitor auth logs** for suspicious activity

### UX

1. **Show loading states** for all async operations
2. **Provide clear error messages** for failures
3. **Auto-focus** first input field
4. **Disable forms** during submission
5. **Auto-dismiss keyboard** when appropriate
6. **Remember user state** between sessions

### Code Quality

1. **Handle all error cases** explicitly
2. **Use async/await** consistently
3. **Cancel tasks** properly on view dismiss
4. **Log important events** for debugging
5. **Test edge cases** thoroughly

---

## Future Enhancements

### Planned Features

- [ ] Social auth (Apple, Google)
- [ ] Two-factor authentication (2FA)
- [ ] Biometric authentication (Face ID/Touch ID)
- [ ] Magic link sign in
- [ ] Remember me toggle
- [ ] Session timeout warnings
- [ ] Account deletion
- [ ] Email change flow
- [ ] Phone number auth

### Improvements

- [ ] Offline sign in (cached credentials)
- [ ] Better error recovery
- [ ] Retry failed requests
- [ ] Password strength indicator
- [ ] Email suggestions (typo detection)
- [ ] Rate limiting UI feedback
- [ ] Multi-device session management

---

## API Reference

### Supabase Auth Methods Used

```swift
// Sign up
await supabase.auth.signUp(email: email, password: password)

// Sign in
await supabase.auth.signIn(email: email, password: password)

// Sign out
await supabase.auth.signOut()

// Password reset
await supabase.auth.resetPasswordForEmail(email)

// Update password
await supabase.auth.update(user: UserAttributes(password: newPassword))

// Get session
await supabase.auth.session

// Refresh session
await supabase.auth.refreshSession()

// Auth state changes
supabase.auth.onAuthStateChange { event, session in ... }
```

---

## Support

For issues or questions:
1. Check Supabase docs: https://supabase.com/docs/guides/auth
2. Review console logs for error details
3. Verify Supabase dashboard settings
4. Test with Supabase SQL Editor

---

Last Updated: December 26, 2024
Version: 1.0.0

