# App Icons Guide for Netfuel

## Required Icon Sizes

Apple requires multiple icon sizes for different devices and contexts. Here are all the sizes you need:

### iOS App Icon Sizes (Required)

| Size (pt) | Size (px @3x) | Size (px @2x) | Usage |
|-----------|---------------|---------------|-------|
| 1024×1024 | 1024×1024 | - | App Store |
| 60×60 | 180×180 | 120×120 | iPhone App |
| 76×76 | 228×228 | 152×152 | iPad App |
| 83.5×83.5 | - | 167×167 | iPad Pro |
| 40×40 | 120×120 | 80×80 | Spotlight Search |
| 29×29 | 87×87 | 58×58 | Settings |
| 20×20 | 60×60 | 40×40 | Notifications |

### Complete Export List

Export these exact sizes from your design:

```
✅ 1024×1024 px - App Store (PNG, no alpha, no rounding)
✅ 180×180 px - iPhone App @3x
✅ 120×120 px - iPhone App @2x
✅ 228×228 px - iPad App @3x
✅ 152×152 px - iPad App @2x
✅ 167×167 px - iPad Pro @2x
✅ 120×120 px - iPhone Spotlight @3x
✅ 80×80 px - iPhone Spotlight @2x
✅ 87×87 px - Settings @3x
✅ 58×58 px - Settings @2x
✅ 60×60 px - Notifications @3x
✅ 40×40 px - Notifications @2x
```

## Design Guidelines

### Apple's Requirements

1. **No Alpha Channel**: App Store icon (1024×1024) cannot have transparency
2. **No Rounded Corners**: iOS adds them automatically
3. **Square Canvas**: All icons must be perfectly square
4. **RGB Color Space**: Use sRGB or Display P3
5. **High Quality**: Use vector graphics when possible
6. **File Format**: PNG format required

### Design Recommendations

Based on your Netfuel logo (flame + speedometer):

#### ✅ DO:
- Use your existing flame and speedometer design
- Keep the design simple and recognizable at small sizes
- Use high contrast (black flame works well)
- Ensure the design is centered
- Test at smallest sizes (29×29) for clarity

#### ❌ DON'T:
- Don't add rounded corners (iOS does this)
- Don't include text (it won't be readable at small sizes)
- Don't use gradients that depend on transparency
- Don't make it too detailed (simplify for small sizes)

### Recommended Color Schemes

For Netfuel, consider these variations:

**Option 1: Black on White**
- Background: White (#FFFFFF)
- Icon: Black (#000000)
- Clean, professional, timeless

**Option 2: Orange/Red Flame**
- Background: Deep Blue/Navy (#1a2332)
- Flame: Orange to Red gradient (#ff6b35 to #ff0000)
- Speedometer: White outline
- Bold, energetic, represents "burning calories"

**Option 3: Minimalist**
- Background: Light Gray (#f5f5f5)
- Icon: Dark Gray (#333333)
- Modern, professional

## Export Settings

### From Design Tools

**Figma/Sketch:**
1. Create artboards for each size
2. Export as PNG
3. Settings:
   - Format: PNG
   - Scale: 1x (already at exact pixel size)
   - Color Profile: sRGB
   - No compression

**Adobe Illustrator:**
1. File → Export → Export for Screens
2. Choose iOS App Icon preset
3. Or manual export:
   - Format: PNG
   - Resolution: 72 PPI
   - Color Mode: RGB
   - Anti-aliasing: Art Optimized

**Photoshop:**
1. File → Export → Export As
2. Format: PNG
3. Settings:
   - Transparency: Off (for App Store icon)
   - Metadata: None
   - Color Space: sRGB

## Adding Icons to Xcode

### Method 1: Asset Catalog (Recommended)

1. Open Xcode project
2. Navigate to `Assets.xcassets`
3. Click on `AppIcon` in the sidebar
4. Drag and drop each icon size into the corresponding slot
5. Xcode shows which sizes are required vs. optional

### Method 2: Automated Tool

Use a tool to generate all sizes from 1024×1024:

**Online Tools:**
- https://www.appicon.co/
- https://makeappicon.com/
- https://appicon.build/

**macOS App:**
- Icon Set Creator (App Store)
- Asset Catalog Creator Pro

Just upload your 1024×1024 icon and download the complete set.

## Icon Design Template

Here's a recommended structure for your Netfuel icon:

```
┌─────────────────────────┐
│                         │
│     [Safe Area]         │
│   ┌───────────────┐     │
│   │               │     │
│   │   🔥 Flame    │     │
│   │      +        │     │
│   │  ⏲ Speedometer│     │
│   │               │     │
│   └───────────────┘     │
│                         │
└─────────────────────────┘

Keep main content within
80% of canvas (safe area)
to account for iOS masking
```

### Padding Guidelines

- **10% padding** from edges (102px on 1024×1024)
- **Safe zone**: 820×820px for main design
- This ensures nothing gets cut off on any device

## Testing Your Icons

### In Xcode
1. Build and run on simulator
2. Check all icon locations:
   - Home screen
   - App switcher
   - Settings
   - Spotlight search

### On Device
1. Install via TestFlight or direct install
2. Check on various devices:
   - iPhone SE (small screen)
   - iPhone 15 Pro Max (large screen)
   - iPad

### Quick Test Checklist

- [ ] Icon looks good at 40×40 (Settings size)
- [ ] Design is recognizable at smallest size
- [ ] Colors have good contrast
- [ ] No blurriness at any size
- [ ] Icon matches app's theme
- [ ] Icon stands out among other apps

## Marketing Assets (Additional)

Beyond the app icon, you may need:

**For App Store:**
- 1024×1024 - App Store icon ✅ (required)
- Screenshots (see APP_STORE_METADATA.md)

**For Marketing:**
- 512×512 - Website/social media
- 256×256 - Small web use
- 128×128 - Favicons, thumbnails
- 32×32 - Favicon

**For Promotional Materials:**
- Vector version (SVG/AI) for print
- High-res PNG (2048×2048+) for banners

## Color Values for Netfuel Branding

Based on your logo design:

```swift
// Primary Colors
let flameOrange = Color(hex: "#FF6B35")
let flameRed = Color(hex: "#FF0000")
let navyBlue = Color(hex: "#1A2332")
let backgroundWhite = Color(hex: "#FFFFFF")

// Accent Colors
let speedometerGray = Color(hex: "#333333")
let accentGreen = Color(hex: "#4CAF50") // For success/progress
```

## Next Steps

1. **Export all required sizes** using the list above
2. **Add to Xcode** in Assets.xcassets → AppIcon
3. **Test on simulator** and real device
4. **Submit with app** to App Store

## Resources

- [Apple Human Interface Guidelines - App Icons](https://developer.apple.com/design/human-interface-guidelines/app-icons)
- [App Store Connect Help - App Icons](https://help.apple.com/app-store-connect/#/devd274dd925)
- [iOS Icon Gallery](https://www.iosicongallery.com/) - Inspiration

---

**Status**: Ready to export icons once design is finalized
**Next**: Create Launch Screen (see LAUNCH_SCREEN_GUIDE.md)
