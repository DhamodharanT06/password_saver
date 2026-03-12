/// AdMob configuration for Password Manager app
/// 
/// This file contains Ad Unit IDs for Google Mobile Ads integration.
/// Replace test IDs with your real Ad Unit IDs from Google AdMob console before publishing.

class AdmobConfig {
  // ─────────────────────────────────────────────────────────────────────────
  // TEST ADS (Safe for development & testing)
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Test Banner Ad Unit ID for Android
  /// Safe to use during development without getting disabled
  static const String _testBannerAdId =
      'ca-app-pub-3940256099942544/6300978111';

  // ─────────────────────────────────────────────────────────────────────────
  // ACTIVE AD UNIT IDS (Replace these before publishing)
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Banner ad unit ID - shown at the bottom of password list
  /// TODO: Replace with your real Ad Unit ID from AdMob console
  static const String bannerAdUnitId = _testBannerAdId;
  
  // To get your Ad Unit IDs:
  // 1. Go to https://admob.google.com
  // 2. Sign in with your Google Account
  // 3. Select your app
  // 4. In the left menu, go to "Ad Units"
  // 5. Create a new Banner ad unit or use existing one
  // 6. Copy the Ad Unit ID and paste it here
  
  // Example of how it should look when you add your real ID:
  // static const String bannerAdUnitId = 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy';
}
