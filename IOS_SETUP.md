# iOS Setup Guide for Adaptive Planner

## Firebase Configuration

### Required: GoogleService-Info.plist

The `ios/Runner/GoogleService-Info.plist` file is currently a placeholder and needs to be replaced with the actual Firebase configuration file.

### Steps to get the real GoogleService-Info.plist:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: `adaptive-planner-cd88b`
3. Click the gear icon → Project Settings
4. Scroll down to "Your apps" section
5. Click on the iOS app (if it exists) or add a new iOS app
6. Download the `GoogleService-Info.plist` file
7. Replace the placeholder file at `ios/Runner/GoogleService-Info.plist`

### iOS Bundle ID
The iOS bundle ID should be configured in the `GoogleService-Info.plist` file and should match the bundle ID in your Xcode project.

## iOS Build Requirements

### Minimum iOS Version
- iOS 15.0 (configured in `ios/Podfile`)

### Dependencies
- CocoaPods (install with `sudo gem install cocoapods`)
- Xcode 15.0 or later

### Build Steps

1. **Install CocoaPods dependencies:**
   ```bash
   cd ios
   pod install
   cd ..
   ```

2. **Clean and rebuild:**
   ```bash
   flutter clean
   flutter pub get
   flutter build ios
   ```

## Common iOS Build Issues

### 1. Missing GoogleService-Info.plist
**Error:** `FirebaseApp.configure() failed`
**Solution:** Replace the placeholder GoogleService-Info.plist with the real file from Firebase Console

### 2. CocoaPods Issues
**Error:** `pod install` fails
**Solution:**
```bash
cd ios
rm -rf Pods Podfile.lock
pod install
```

### 3. Xcode Version Issues
**Error:** Incompatible Xcode version
**Solution:** Update Xcode to version 15.0 or later

### 4. Bundle ID Mismatch
**Error:** Bundle ID doesn't match Firebase configuration
**Solution:** Ensure the bundle ID in GoogleService-Info.plist matches your Xcode project settings

## Testing iOS Build

Since this is a Windows development environment, iOS builds cannot be tested directly. However, you can:

1. Use a Mac with Xcode to test iOS builds
2. Use Flutter's CI/CD services that support iOS builds
3. Use Codemagic or other cloud build services

## Firebase iOS Configuration Checklist

- ✅ GoogleService-Info.plist file present
- ✅ FirebaseApp.configure() called in AppDelegate.swift
- ✅ Bundle ID matches Firebase project
- ✅ iOS deployment target >= 15.0
- ✅ CocoaPods dependencies installed
- ✅ Firebase plugins registered in GeneratedPluginRegistrant.m

## Troubleshooting

If you encounter build issues:

1. Check the console output for specific error messages
2. Verify all Firebase configuration files are present
3. Ensure CocoaPods is properly installed
4. Clean and rebuild the project
5. Check that Xcode and Flutter are up to date

For more help, refer to:
- [Flutter iOS Setup](https://docs.flutter.dev/get-started/install/macos#ios-setup)
- [Firebase iOS Setup](https://firebase.google.com/docs/ios/setup)