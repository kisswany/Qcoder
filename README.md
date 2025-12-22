# Qcoder - QR Code Scanner & Generator

A modern, feature-rich QR code application built with Flutter.

## Features

- ✅ **QR Code Scanner** - Scan QR codes using your device camera
- ✅ **QR Code Generator** - Create QR codes from URLs or text
- ✅ **WiFi QR Detection** - Automatically detects and displays WiFi credentials
- ✅ **URL Opening** - Direct link opening from scanned QR codes
- ✅ **Share Functionality** - Share QR content easily
- ✅ **Premium Dark Theme** - Beautiful gradient UI with animations
- ✅ **AdMob Integration** - Monetization support

## Screenshots

[Add screenshots here]

## Getting Started

### Prerequisites

- Flutter SDK 3.0.0 or higher
- Android Studio (for Android development)
- Java JDK 21

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

### Building APK

```bash
flutter build apk --release
```

## Project Structure

```
lib/
├── main.dart           # App entry point
└── screens/
    └── home_screen.dart  # Main UI with scanner and generator
```

## Dependencies

- `qr_flutter` - QR code generation
- `mobile_scanner` - Camera-based QR scanning
- `share_plus` - Sharing functionality
- `url_launcher` - URL opening
- `google_mobile_ads` - AdMob integration

## Configuration

### AdMob

Replace test ad units in `AndroidManifest.xml` and `home_screen.dart` with your own AdMob IDs before publishing.

### App Icon

Custom app icon is generated using `flutter_launcher_icons`. Update `assets/icon.png` with your design, then run:

```bash
flutter pub run flutter_launcher_icons
```

## Contact

kissswanyzzz@gmail.com
