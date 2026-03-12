# Google AdMob Integration Guide

This guide explains how to integrate Google Mobile Ads into the Password Manager app.

## Overview

The app displays banner ads at the bottom of the password list. Ads are managed through Google AdMob, which requires:
1. A Google AdMob account
2. An AdMob app registration
3. Ad Unit IDs configuration

## Current Setup

- Package: `google_mobile_ads: ^5.1.0` (added to pubspec.yaml)
- App ID Configuration: Already in `android/app/src/main/AndroidManifest.xml`
- Ad Unit IDs: Configured in `lib/config/admob_config.dart`

## Development / Testing

The app is currently configured with **Google's test Ad Unit IDs**. These are safe to use for development and testing without any restrictions.

Test Banner Ad Unit ID: `ca-app-pub-3940256099942544/6300978111`

You can build, test, and publish with these test IDs - they won't affect your account.

## Before Publishing to Play Store

⚠️ **IMPORTANT**: Replace test Ad Unit IDs with your real IDs before submitting to Google Play Store.

### Steps to Setup Real AdMob Account:

1. **Create AdMob Account**
   - Go to https://admob.google.com
   - Sign in with your Google Account
   - Click "Sign up or login to AdMob"

2. **Register Your App**
   - In AdMob console, select "Apps" → "Add App"
   - Choose platform: Android
   - Enter app name (should match your app in Play Console)
   - Follow the setup wizard

3. **Get App ID**
   - After app registration, copy the AdMob App ID
   - It's already configured in: `android/app/src/main/AndroidManifest.xml`
   - Example: `ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy`

4. **Create Ad Units**
   - In AdMob console, go to "Ad Units" section
   - Create a new Banner ad unit
   - Set:
     - Name: "Password List Banner"
     - Size: Standard Banner (320x50)
     - Review and create

5. **Get Ad Unit IDs**
   - Copy the Banner Ad Unit ID (format: `ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy`)
   - Replace the test ID in `lib/config/admob_config.dart`:
     ```dart
     static const String bannerAdUnitId = 'your-real-ad-unit-id-here';
     ```

6. **Build and Test**
   - Run `flutter pub get` to ensure all packages are updated
   - Build the app: `flutter build apk` or `flutter build appbundle`
   - Test with your real Ad Unit IDs locally first
   - Verify ads display correctly

7. **Submit to Play Store**
   - Upload your signed APK/AAB to Google Play Console
   - Google Play will verify your AdMob integration
   - Your app may need AdMob approval (usually within 24 hours)

## File Locations

- **AdMob Config**: `lib/config/admob_config.dart`
- **Banner Widget**: `lib/main.dart` → `_BannerAdWidget` class (around line 900)
- **Banner Display**: Bottom of Scaffold in `_HomepageState.build()`
- **Android Manifest**: `android/app/src/main/AndroidManifest.xml`

## Troubleshooting

**Ads not showing?**
- Ensure you're not using test IDs in production (or vice versa with real IDs in development)
- Check AdMob console for errors/warnings
- Verify Ad Unit ID is correctly configured
- Allow 24-48 hours for AdMob to process your app

**Build errors after adding google_mobile_ads?**
```bash
flutter clean
flutter pub get
flutter pub upgrade
```

**App crashes on startup?**
- Make sure AdMob App ID is correct in AndroidManifest.xml
- Ensure `MobileAds.instance.initialize()` is called in `main()`
- Check logcat for specific error messages

## Revenue Notes

- You should not click your own ads
- Clicking invalid traffic, playing your app with ads on, or asking users to click ads can get your account suspended
- Use the following test device ID in development if needed (add to AdMob console under "Test devices")

## More Information

- AdMob Documentation: https://developers.google.com/admob
- Google Mobile Ads SDK for Flutter: https://pub.dev/packages/google_mobile_ads
- AdMob Policies: https://support.google.com/admob/answer/6128543
