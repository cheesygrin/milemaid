import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Google Maps key is configured in Info.plist (GMSApiKey).
    // Set AppConfig.googleMapsEnabled = true in lib/core/config/app_config.dart
    // once a real key is in place.
    if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String,
       !apiKey.isEmpty, !apiKey.hasPrefix("YOUR_") {
      GMSServices.provideAPIKey(apiKey)
    }

    GeneratedPluginRegistrant.register(with: self)

    // flutter_foreground_task and geolocator handle most iOS background via Info.plist
    // CLLocationManager is configured by the geolocator + flutter_foreground_task plugins.

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
