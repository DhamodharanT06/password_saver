/// AdMob configuration for Password Manager app
///
/// Returns the correct ad unit ID depending on build mode.
/// - In debug builds the official test ad unit is used (safe for development).
/// - In release builds the production ad unit is returned (set to your real ID).

import 'package:flutter/foundation.dart';

class AdmobConfig {
  // Official Google test Banner Ad Unit ID (safe for development)
  static const String _testBannerAdId =
      'ca-app-pub-3940256099942544/6300978111';

  // Production Banner Ad Unit ID (replace with your real ID)
  static const String _prodBannerAdId =
      'ca-app-pub-5197112083845726/9146046326';

  /// Banner ad unit ID - selects test id in debug, production id otherwise.
  static String get bannerAdUnitId => kDebugMode ? _testBannerAdId : _prodBannerAdId;

  // Notes:
  // - Replace `_prodBannerAdId` with the real Ad Unit ID from AdMob console
  //   before publishing if it differs from the current value.
  // - Do NOT include test device registrations in release builds.
}
