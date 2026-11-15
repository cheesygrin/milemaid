/// Build-time configuration for App Store / Play Store releases.
class AppConfig {
  AppConfig._();

  /// Flip to true after configuring a real Google Maps API key in
  /// `ios/Runner/Info.plist` (GMSApiKey) and
  /// `android/app/src/main/AndroidManifest.xml` (com.google.android.geo.API_KEY).
  /// While false, route maps are replaced with a graceful placeholder so
  /// reviewers never see a broken/blank map.
  /// On only in builds made with config/secrets.json (local, never committed),
  /// which must go together with GOOGLE_MAPS_IOS_API_KEY in ios/Flutter/Secrets.xcconfig.
  static const bool googleMapsEnabled = bool.fromEnvironment('GOOGLE_MAPS_ENABLED');

  /// Freemium is on by default: tracking and classification are free, while
  /// PDF/CSV reports and cloud sync need MileMaid Pro (a real StoreKit
  /// subscription, see PurchaseService). A build with
  /// `"MONETIZATION_ENABLED": "false"` in config/secrets.json unlocks
  /// everything and hides all upsell UI, for forks or personal builds made
  /// before the products below exist in App Store Connect.
  static const bool monetizationEnabled =
      bool.fromEnvironment('MONETIZATION_ENABLED', defaultValue: true);

  /// Auto-renewable subscriptions in one App Store Connect subscription
  /// group. These ids are permanent once created there.
  static const String proAnnualProductId = 'com.zerodelta.milemaid.pro.annual';
  static const String proMonthlyProductId = 'com.zerodelta.milemaid.pro.monthly';

  /// Shown on the paywall and in Settings; Apple requires both links wherever
  /// a subscription is sold (Guideline 3.1.2).
  static const String privacyPolicyUrl =
      'https://github.com/cheesygrin/milemaid/blob/main/PRIVACY.md';
  static const String termsOfUseUrl =
      'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';
  static const String manageSubscriptionsUrl =
      'https://apps.apple.com/account/subscriptions';
  static const String sourceCodeUrl = 'https://github.com/cheesygrin/milemaid';
}
