import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:milemaid/app.dart';
import 'package:milemaid/core/services/database_service.dart';
import 'package:milemaid/core/services/tracking_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive local storage
  await Hive.initFlutter();
  await DatabaseService().init();

  // Background tracking engine
  await TrackingService().initialize();

  runApp(
    const ProviderScope(
      child: MileMaidApp(),
    ),
  );
}
