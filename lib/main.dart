import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:milemaid/app.dart';
import 'package:milemaid/core/config/firebase_config.dart';
import 'package:milemaid/core/services/database_service.dart';
import 'package:milemaid/core/services/tracking_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive local storage
  await Hive.initFlutter();
  await DatabaseService().init();

  // Firebase (auth + cloud sync). Config injected from config/secrets.json.
  await Firebase.initializeApp(options: kFirebaseOptions);

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
  unawaited(TrackingService().resumeIfAuthorized());
}
