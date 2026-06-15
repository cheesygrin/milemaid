/// Build-time configuration for App Store / Play Store releases.
class AppConfig {
  AppConfig._();

  /// Flip to true after configuring a real Google Maps API key in
  /// `ios/Runner/Info.plist` (GMSApiKey) and
  /// `android/app/src/main/AndroidManifest.xml` (com.google.android.geo.API_KEY).
  /// While false, route maps are replaced with a graceful placeholder so
  /// reviewers never see a broken/blank map.
  static const bool googleMapsEnabled = false;

  /// v1 ships fully free. Flip to true only after real StoreKit/Play Billing
  /// subscriptions are implemented (App Store Guideline 3.1.1 forbids
  /// simulated purchases). While false, all Pro gating and upsell UI is hidden
  /// and every feature is unlocked.
  static const bool monetizationEnabled = false;
}
