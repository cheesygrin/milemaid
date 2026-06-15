import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Result of the location permission flow.
enum LocationAccess {
  /// GPS off or user denied all access.
  denied,

  /// "While Using the App" or "Allow Once" — trips only work with app open.
  whenInUse,

  /// "Always" — required for automatic background mileage tracking.
  always,

  /// Location services disabled system-wide.
  servicesDisabled,
}

/// Thin service around Geolocator + PermissionHandler.
/// Provides clean API for the tracking service.
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<Position>? _positionSub;

  /// Current location access level (no prompts).
  Future<LocationAccess> getCurrentAccess() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationAccess.servicesDisabled;
    }

    final permission = await Geolocator.checkPermission();
    return _mapGeolocatorPermission(permission);
  }

  LocationAccess _mapGeolocatorPermission(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.always:
        return LocationAccess.always;
      case LocationPermission.whileInUse:
        return LocationAccess.whenInUse;
      case LocationPermission.denied:
      case LocationPermission.deniedForever:
      case LocationPermission.unableToDetermine:
        return LocationAccess.denied;
    }
  }

  /// iOS shows "Allow Once" / "While Using" first. "Always" is a second step
  /// (system dialog or Settings). Returns true if tracking can run at all.
  Future<bool> requestAlwaysPermission() async {
    final access = await requestFullLocationAccess();
    return access == LocationAccess.always || access == LocationAccess.whenInUse;
  }

  /// Full two-step flow: When In Use → Always (iOS) → Settings guide if needed.
  Future<LocationAccess> requestFullLocationAccess() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
      if (!await Geolocator.isLocationServiceEnabled()) {
        return LocationAccess.servicesDisabled;
      }
    }

    // Step 1: foreground access (first system dialog on iOS).
    var whenInUse = await Permission.locationWhenInUse.status;
    if (!whenInUse.isGranted && !whenInUse.isLimited) {
      whenInUse = await Permission.locationWhenInUse.request();
    }

    // Fallback for platforms / edge cases.
    if (!whenInUse.isGranted && !whenInUse.isLimited) {
      var geo = await Geolocator.checkPermission();
      if (geo == LocationPermission.denied) {
        geo = await Geolocator.requestPermission();
      }
      if (geo == LocationPermission.denied ||
          geo == LocationPermission.deniedForever) {
        return LocationAccess.denied;
      }
    }

    // Step 2: upgrade to Always (second dialog on some iOS versions).
    if (Platform.isIOS || Platform.isAndroid) {
      var always = await Permission.locationAlways.status;
      if (!always.isGranted) {
        always = await Permission.locationAlways.request();
      }
      if (always.isGranted) {
        return LocationAccess.always;
      }
    }

    return await getCurrentAccess();
  }

  /// Opens iOS Settings → MileMaid → Location so user can pick "Always".
  Future<bool> openAppLocationSettings() => openAppSettings();

  /// Explains why "Always" is not in the first dialog and how to enable it.
  static Future<void> showAlwaysPermissionGuide(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enable "Always" Location'),
        content: const Text(
          'iOS only shows "While Using" or "Allow Once" the first time — that\'s normal.\n\n'
          'For automatic mileage tracking when you\'re driving (app in background or locked), '
          'you need Always:\n\n'
          '1. Tap Open Settings below\n'
          '2. Tap Location\n'
          '3. Select Always\n'
          '4. Turn on Precise Location if you see it\n\n'
          'Then return to MileMaid.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  static String accessLabel(LocationAccess access) {
    switch (access) {
      case LocationAccess.always:
        return 'Always — background tracking enabled';
      case LocationAccess.whenInUse:
        return 'While Using — enable Always in Settings for auto-tracking';
      case LocationAccess.denied:
        return 'Not allowed — tap to enable location';
      case LocationAccess.servicesDisabled:
        return 'Location Services off — tap to open Settings';
    }
  }

  /// Current high accuracy position stream suitable for tracking.
  Stream<Position> get positionStream {
    if (Platform.isIOS) {
      return Geolocator.getPositionStream(
        locationSettings: AppleSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 50,
          activityType: ActivityType.automotiveNavigation,
          allowBackgroundLocationUpdates: true,
          pauseLocationUpdatesAutomatically: false,
          showBackgroundLocationIndicator: true,
        ),
      );
    }

    const LocationSettings settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 50,
    );
    return Geolocator.getPositionStream(locationSettings: settings);
  }

  Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  static double speedMpsToMph(double? speedMps) {
    if (speedMps == null || speedMps < 0) return 0;
    return speedMps * 2.23694;
  }

  Future<void> dispose() async {
    await _positionSub?.cancel();
    _positionSub = null;
  }
}
