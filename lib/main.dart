import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:milemaid/app.dart';
import 'package:milemaid/core/config/firebase_config.dart';
import 'package:milemaid/core/services/auth_service.dart';
import 'package:milemaid/core/services/database_service.dart';
import 'package:milemaid/core/services/purchase_service.dart';
import 'package:milemaid/core/services/tracking_health_service.dart';
import 'package:milemaid/core/services/tracking_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive local storage
  await Hive.initFlutter();
  await DatabaseService().init();

  // Firebase (accounts + cloud sync). Config injected from
  // config/secrets.json; without it the app runs local-only instead of
  // crashing at launch.
  if (kFirebaseConfigured) {
    try {
      await Firebase.initializeApp(options: kFirebaseOptions);
      AuthService.available = true;
    } catch (e) {
      debugPrint('Firebase did not start; accounts and cloud sync are off: $e');
    }
  }

  // Subscription state: the cached answer applies immediately, the App Store
  // check finishes in the background.
  unawaited(PurchaseService.instance.init());

  // Background tracking engine
  await TrackingService().initialize();

  runApp(
    const ProviderScope(
      child: MileMaidApp(),
    ),
  );

  // Resume tracking straight away when permission is already granted. This
  // also covers iOS relaunching the app in the background after a significant
  // location change, when no frame is drawn and widget callbacks never run.
  unawaited(TrackingService().resumeIfAuthorized().then((_) {
    return TrackingHealthService.instance.checkAndAlert();
  }));
}
