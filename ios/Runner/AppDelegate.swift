import CoreLocation
import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, CLLocationManagerDelegate {
  /// Significant-change monitoring is what makes iOS relaunch MileMaid in the
  /// background after it was terminated (by the system or by swiping it away),
  /// as soon as the phone moves a few hundred meters. main() then resumes the
  /// regular GPS tracking. The geolocator plugin's continuous updates alone stop
  /// for good once the app is terminated.
  private let relaunchLocationManager = CLLocationManager()

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

    relaunchLocationManager.delegate = self
    startRelaunchMonitoringIfAuthorized()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // UIScene lifecycle (required for apps built with the iOS 27 SDK): plugins
  // register on the implicit engine that FlutterSceneDelegate creates.
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private func startRelaunchMonitoringIfAuthorized() {
    guard CLLocationManager.significantLocationChangeMonitoringAvailable() else { return }
    let status: CLAuthorizationStatus
    if #available(iOS 14.0, *) {
      status = relaunchLocationManager.authorizationStatus
    } else {
      status = CLLocationManager.authorizationStatus()
    }
    // Background relaunch only happens with "Always" permission.
    if status == .authorizedAlways {
      relaunchLocationManager.startMonitoringSignificantLocationChanges()
    }
  }

  // Permission is usually granted during onboarding, after launch.
  @available(iOS 14.0, *)
  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    startRelaunchMonitoringIfAuthorized()
  }

  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    startRelaunchMonitoringIfAuthorized()
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    // Nothing to do: the relaunch itself is the point. Trip detection runs in Dart.
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    // Ignored: monitoring retries on its own.
  }
}
