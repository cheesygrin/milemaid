# Prompt for Autonomous Agent (Cursor Agent or Hermes)

Copy the entire content below (starting from "You are an expert...") and paste it as the initial prompt to your agent.

---

You are an expert Flutter developer and iOS App Store submission specialist with full access to the project filesystem and terminal.

Project root: /Users/timrose/Projects/milemaid

Your goal is to complete all remaining code and configuration changes needed so the app has the highest possible chance of passing App Store review on first submission. Work as autonomously as possible. Make all code edits, run terminal commands, and create files as needed. Only stop and ask the human for input if you literally cannot proceed (e.g. they must provide a real Google Maps API key value or App Store Connect credentials).

Current critical state (from latest inspection):

**lib/core/config/app_config.dart**
```dart
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
```

**lib/features/monetization/presentation/paywall_screen.dart** (the _subscribe method contains explicit dev simulation)
```dart
  void _subscribe(WidgetRef ref, BuildContext context, {bool pro = false, bool premium = false}) {
    // For now this is a dev shortcut. Replace with real IAP flow.
    ref.read(settingsProvider.notifier).setProStatus(true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Thank you! Pro features unlocked (dev simulation). '
            'Replace this with real in_app_purchase + RevenueCat in production.'),
      ),
    );
    Navigator.pop(context);
  }
```

**lib/features/settings/presentation/settings_screen.dart** (sample data is gated but has dev comments)
```dart
          // Demo data is a development aid only; hidden in release builds.
          if (kDebugMode)
            ListTile(
              leading: const Icon(Icons.science_outlined),
              title: const Text(AppStrings.loadSampleData),
              ...
```

**ios/Runner/Info.plist** (line ~69)
```xml
	<!-- Google Maps iOS key -->
	<!-- TODO: Replace with your Google Maps API Key (enable Maps SDK for iOS) -->
	<key>GMSApiKey</key>
	<string>YOUR_GOOGLE_MAPS_API_KEY_HERE</string>
```

**android/app/src/main/AndroidManifest.xml** (line ~62)
```xml
        <!-- Google Maps API Key -->
        <!-- TODO: Replace with your Google Maps API Key (enable Maps SDK for Android) -->
        <meta-data
            android:name="com.google.android.geo.API_KEY"
            android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE" />
```

**Key remaining tasks (do these in order, make changes, then verify):**

1. **Google Maps Keys & Config**
   - Update AppConfig.dart: Change `googleMapsEnabled` to `true` and add a clear comment that a real key must be provided before final release build.
   - In ios/Runner/Info.plist: Replace the GMSApiKey placeholder with a TODO comment like `<!-- TODO: Replace with real restricted Google Maps iOS key -->` and leave a placeholder that makes it obvious.
   - In android/app/src/main/AndroidManifest.xml: Do the same for the meta-data API key.
   - Search the entire project (excluding build/ and Pods/) for any other "YOUR_GOOGLE_MAPS" or map-related placeholders and clean them.
   - Note: The actual key value must be supplied by the human later. Do not hardcode a fake key.

2. **Remove Dev Simulation / Monetization Hacks (Critical for App Store Guideline 3.1.1)**
   - In paywall_screen.dart: Completely remove or heavily refactor the `_subscribe` method's dev simulation. Replace the body with a clear comment like:
     ```dart
     // Production path: Integrate real in_app_purchase + RevenueCat here.
     // For this v1 submission, monetizationEnabled is false in AppConfig,
     // so all features are unlocked and this screen is only shown as future UI.
     ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(content: Text('Monetization is disabled for v1. All features are currently free.')),
     );
     ```
     Update the class comment to reflect that this is prepared for future real IAP but disabled now.
   - In settings_screen.dart: The sample data ListTile is already behind `if (kDebugMode)` — keep it, but improve the comment to be even clearer for reviewers.
   - Search the whole project for "dev simulation", "Temporary dev toggle", "dev shortcut" and remove or neutralize every instance.
   - Confirm that `monetizationEnabled` remains `false` in AppConfig (this is correct for the first submission).

3. **Create / Prepare Privacy Policy**
   - Create a new file at `assets/privacy_policy.md` (or `docs/privacy_policy.md`) containing a clear, professional privacy policy tailored to this app.
     Key points it must cover (use professional language):
     - We collect precise location only while the app is actively tracking drives (with user consent).
     - Location data is stored locally on the device (using Hive) and is never sent to our servers.
     - We do not sell or share personal data with third parties.
     - Data is only used for generating local mileage reports for the user's own tax/accounting purposes.
     - User can export or delete all data at any time.
     - Contact for data requests.
   - Update the in-app "Privacy & Legal" dialog in settings_screen.dart to point users to the hosted policy (add a note like "Full policy available at [URL]").
   - Add a comment in the code about the policy location.

4. **Clean Up Remaining Dev / Placeholder Code**
   - Search the entire project (lib/, android/, ios/ excluding build/Pods) for TODO, FIXME, placeholder, "dev", "simulation", "temporary", "kDebugMode" (outside of the intentional sample data gate), and "Replace this with real".
   - Clean or properly comment every instance that would be visible or problematic in a release build.
   - In premium_animations.dart: Either implement a basic fallback or add a very clear production comment.
   - In reports_screen.dart and pdf_preview_screen.dart: Make sure the isPro gating logic is clean and respects AppConfig.monetizationEnabled.

5. **App Store Connect Preparation (Output Clear Instructions)**
   - After finishing code changes, output a ready-to-use checklist for the human with exact steps for App Store Connect, including:
     - Required Privacy Policy URL (they will need to host the markdown you created, e.g. on GitHub Pages or a simple site).
     - How to fill the App Privacy section (precise location data linked to user, etc.).
     - Recommended review notes text explaining background location.
     - List of required screenshots and what they should demonstrate.
     - Bundle ID confirmation (should be com.timrose.milemaid or whatever is currently in the project).
   - Also remind them they need a real Apple Developer account ($99/year) and to create the app record before uploading.

6. **Build & Verification Steps (Execute These)**
   - Run `flutter clean`
   - Run `flutter pub get`
   - Run `flutter build ios --release` (or at least attempt it and capture any errors).
   - If possible, open the iOS project (`open ios/Runner.xcworkspace`) via terminal and note the current signing status (but do not change certificates yourself).
   - Search one final time for any remaining "miletrack" (case insensitive) or old branding and fix it.
   - Create a short `RELEASE_NOTES.md` or update README with "App Store v1 readiness checklist" status.

7. **Final Output Requirements**
   - After all changes, give a clear summary:
     - List of every file you edited and what you changed.
     - Any commands the human must run next.
     - Exact remaining manual steps (especially Google key value, hosting privacy policy, App Store Connect work, real device testing, archiving in Xcode).
     - Confirmation that the app is now in the best possible state for a first App Store submission given current constraints.

Work step by step. Use your file editing and terminal tools for everything possible. Make the changes production-ready and conservative (favor hiding features over leaving broken dev code). If you encounter something you cannot do autonomously (e.g. real API key value or Apple account actions), clearly document the exact next manual step for the human.

Start now. Be thorough but efficient.