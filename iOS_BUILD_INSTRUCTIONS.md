# iOS Build Instructions

## Problem Fixed: iOS Deployment Target

The issue you encountered was that `cloud_firestore` requires iOS 15.0+ as the minimum deployment target, but your project was set to iOS 13.0.

## Changes Made:

### 1. Updated iOS Deployment Target
- Updated `ios/Runner.xcodeproj/project.pbxproj` to use iOS 15.0 instead of 13.0
- This affects Debug, Release, and Profile configurations

### 2. Created Podfile
- Added `ios/Podfile` with proper platform specification
- Set minimum iOS version to 15.0
- Included post-install script to ensure all pods use iOS 15.0+

## Building for iOS (Requires macOS):

### Option 1: Local Build (on Mac)
```bash
# Clean previous builds
flutter clean
flutter pub get

# Build for iOS device
flutter build ios

# Or build for iOS simulator
flutter build ios --debug
```

### Option 2: GitHub Actions (Recommended for Windows users)
Create `.github/workflows/ios-build.yml`:

```yaml
name: Build iOS
on:
  workflow_dispatch:
  push:
    branches: [ main ]

jobs:
  build-ios:
    runs-on: macos-latest
    steps:
    - uses: actions/checkout@v4
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.24.0'
    - run: flutter pub get
    - run: flutter build ios --release --no-codesign
```

### Option 3: Firebase Test Lab (for testing)
The iOS deployment target fix will also resolve Firebase Test Lab issues.

## Next Steps:

1. **Commit the changes**:
   ```bash
   git add .
   git commit -m "fix: Update iOS deployment target to 15.0 for cloud_firestore compatibility"
   git push
   ```

2. **Test on macOS** or use GitHub Actions for iOS builds

3. **For APK** (Android), use:
   ```bash
   flutter build apk --release
   ```

The deployment target issue should now be resolved! 🎉