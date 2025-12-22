# App Icon Instructions for Qcoder

Since automatic icon generation hit a rate limit, please create the app icon manually using one of these methods:

## Option 1: Use an Icon Generator Website
1. Go to: https://www.appicon.co/ or https://icon.kitchen/
2. Upload a QR code image with gradient colors (purple #BB86FC to cyan #03DAC6)
3. Download the generated icons
4. Place them in the appropriate folders:
   - Android: `android/app/src/main/res/mipmap-*/ic_launcher.png`

## Option 2: Design Specifications
If you want to design it yourself:
- **Size**: 1024x1024px (adaptive icon)
- **Colors**: 
  - Gradient from Purple (#BB86FC) to Cyan (#03DAC6)
  - Dark background (#1E1E1E)
- **Design**: Modern, minimalist QR code pattern with scanner beam effect
- **Style**: Premium, professional, matches dark theme

## Option 3: Use flutter_launcher_icons Package
Add to pubspec.yaml:
```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: true
  ios: false
  image_path: "assets/icon.png"
  adaptive_icon_background: "#1E1E1E"
  adaptive_icon_foreground: "assets/icon_foreground.png"
```

Then run:
```
flutter pub get
flutter pub run flutter_launcher_icons
```

## Temporary Solution
For now, the app will use the default Flutter icon. The functionality improvements have been implemented!
