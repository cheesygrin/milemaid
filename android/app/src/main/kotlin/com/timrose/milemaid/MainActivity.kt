package com.timrose.milemaid

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.pravera.flutter_foreground_task.FlutterForegroundTaskPlugin

/**
 * MainActivity for MileMaid.
 * flutter_foreground_task works with standard FlutterActivity in most cases (v6+).
 * If you encounter issues with background service, switch to FlutterFragmentActivity.
 */
class MainActivity : FlutterActivity() {
    // TODO: Replace with your Google Maps API Key in AndroidManifest.xml
    // Enable "Maps SDK for Android" in Google Cloud Console.

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Plugin is auto-registered via GeneratedPluginRegistrant
    }
}
