# Launch Screen Setup Guide

## What is a Launch Screen?

The launch screen is the first thing users see when they tap your app icon. It should:
- Display instantly (static, no animations)
- Match your app's design
- Give users confidence the app is loading

## ✅ Created: LaunchScreenView.swift

A SwiftUI-based launch screen has been created at:
```
Healthapp/Views/LaunchScreenView.swift
```

### Current Design

- **Background**: Navy blue (#1A2332) matching app theme
- **Icon**: Flame icon (placeholder - replace with your logo)
- **App Name**: "Netfuel" in bold rounded font
- **Tagline**: "Fuel Your Fitness"

## How to Use This Launch Screen

### Option 1: SwiftUI Launch Screen (iOS 14+)

1. **In Xcode**, go to your project settings
2. Select your app target
3. Go to **Info** tab
4. Find **Launch Screen** section
5. Set:
   - **Launch Screen File**: Leave empty
   - **UILaunchScreen**: Add dictionary
   - **UIImageName**: Your logo asset name (optional)
   - **UIColorName**: Your background color (optional)

### Option 2: Use the SwiftUI View (Recommended for Complex Design)

If you need a custom design beyond simple image + color:

1. The `LaunchScreenView.swift` is already created
2. To make it the launch screen, you need to configure it in `Info.plist`

**However**, Apple recommends keeping launch screens simple (just logo + background color).

### Option 3: Storyboard (Traditional)

Create `LaunchScreen.storyboard`:

1. In Xcode: **File → New → File**
2. Choose **Launch Screen**
3. Design your launch screen visually
4. Use Auto Layout for all devices
5. Set in **Project Settings → General → Launch Screen File**

## Customizing the Launch Screen

### Replace the Placeholder Icon

Currently using `Image(systemName: "flame.fill")`. Replace with your actual logo:

```swift
// Replace this:
Image(systemName: "flame.fill")
    .font(.system(size: 80))
    .foregroundColor(.orange)

// With your logo image:
Image("AppLogo")  // Add AppLogo.png to Assets.xcassets
    .resizable()
    .scaledToFit()
    .frame(width: 120, height: 120)
```

### Adjust Colors

Match your brand colors:

```swift
// Background
Color(hex: "#1A2332")  // Navy blue

// Or use white background:
Color.white

// Or match your tab bar:
Color(UIColor.systemBackground)
```

### Add Your Branding

```swift
VStack(spacing: 24) {
    // Your logo
    Image("NetfuelLogo")
        .resizable()
        .scaledToFit()
        .frame(width: 100, height: 100)

    // App name
    Text("Netfuel")
        .font(.system(size: 42, weight: .bold, design: .rounded))
        .foregroundColor(.white)

    // Optional tagline
    Text("Fuel Your Fitness")
        .font(.system(size: 16, weight: .medium))
        .foregroundColor(.white.opacity(0.8))
}
```

## Design Guidelines

### Apple's Requirements

✅ **DO:**
- Keep it simple (logo + background)
- Make it fast to load (static only)
- Use your app's color scheme
- Center the design
- Support all device sizes

❌ **DON'T:**
- Animate anything (not allowed)
- Show progress indicators
- Include text that needs localization (unless you localize the launch screen)
- Use web views or dynamic content
- Show disclaimers or legal text

### Best Practices

1. **Match First Screen**: Launch screen should look similar to your app's first screen
2. **Center Content**: Works on all device sizes
3. **Dark Mode**: Consider dark mode support
4. **Simple**: Just logo + background is often best
5. **Fast**: Static images load faster than complex views

## Testing Your Launch Screen

### In Simulator

1. **Delete the app** from simulator (long press → Remove App)
2. **Clean build folder**: Product → Clean Build Folder (⌘⇧K)
3. **Run the app** again
4. The launch screen should appear briefly on first launch

### On Device

1. Delete app if previously installed
2. Install via Xcode or TestFlight
3. Launch screen appears on first tap

### Tips

- Launch screen is **cached** - delete the app to see changes
- It appears for a **very short time** on modern devices
- Test on both iPhone and iPad
- Test in light and dark mode

## Dark Mode Support

Make your launch screen adapt to dark mode:

```swift
struct LaunchScreenView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            // Dynamic background
            (colorScheme == .dark ? Color(hex: "#1A2332") : Color.white)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)

                Text("Netfuel")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
            }
        }
    }
}
```

## Alternative: Simple Info.plist Configuration

For a very simple launch screen (just background color and logo):

Add to `Info.plist`:

```xml
<key>UILaunchScreen</key>
<dict>
    <key>UIColorName</key>
    <string>LaunchScreenBackground</string>
    <key>UIImageName</key>
    <string>LaunchScreenLogo</string>
    <key>UIImageRespectsSafeAreaInsets</key>
    <true/>
</dict>
```

Then add to `Assets.xcassets`:
- Color set named "LaunchScreenBackground"
- Image set named "LaunchScreenLogo"

## Recommended Setup for Netfuel

Based on your branding, here's the recommended approach:

### Simple Version (Recommended)

1. **Background**: Navy blue (#1A2332)
2. **Logo**: Your flame + speedometer icon
3. **Name**: "Netfuel" text
4. **Tagline**: "Fuel Your Fitness"

This matches your app icon and sets user expectations.

### Minimal Version

1. **Background**: Navy blue
2. **Logo**: Flame + speedometer (centered)
3. No text (shows app icon at larger size)

Even simpler, loads faster.

## Next Steps

1. **Export your logo** as PNG:
   - 1024×1024 (large)
   - 512×512 (medium)
   - 256×256 (small)

2. **Add to Assets.xcassets**:
   - Create "AppLogo" image set
   - Drag in all 3 sizes

3. **Update LaunchScreenView.swift**:
   - Replace SF Symbol with `Image("AppLogo")`
   - Adjust sizes and spacing

4. **Test**:
   - Delete app from simulator
   - Clean build
   - Run and verify launch screen appears

5. **Configure in Xcode**:
   - Set launch screen in project settings
   - Test on multiple devices

---

**Status**: LaunchScreenView.swift created, ready to customize
**Next**: App Store Metadata (see APP_STORE_METADATA.md)
