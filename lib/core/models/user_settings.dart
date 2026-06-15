import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_settings.freezed.dart';

/// User profile + app preferences. Stored as JSON in Hive.
@freezed
class UserSettings with _$UserSettings {
  const UserSettings._();

  const factory UserSettings({
    @Default('') String name,
    @Default('') String email,
    @Default(0.72) double mileageRate, // IRS default
    @Default('Balanced') String trackingSensitivity, // High / Balanced / Battery Saver
    @Default(true) bool notificationsEnabled,
    @Default(true) bool tripEndConfirmation,
    @Default('') String defaultVehicleId,
    /// Onboarding completed flag
    @Default(false) bool hasCompletedOnboarding,
    /// Last time we synced or updated (for future)
    DateTime? lastUpdated,

    /// Whether the user has an active Pro / Premium subscription.
    /// For now this is local-only (unlocked via in-app purchase in a real release).
    @Default(false) bool isPro,

    /// Theme preference: "system", "light", or "dark"
    @Default('system') String themeMode,
  }) = _UserSettings;

  // Manual JSON
  static UserSettings fromJson(Map<String, dynamic> json) => UserSettings(
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        mileageRate: (json['mileageRate'] as num?)?.toDouble() ?? 0.72,
        trackingSensitivity: json['trackingSensitivity'] as String? ?? 'Balanced',
        notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
        tripEndConfirmation: json['tripEndConfirmation'] as bool? ?? true,
        defaultVehicleId: json['defaultVehicleId'] as String? ?? '',
        hasCompletedOnboarding: json['hasCompletedOnboarding'] as bool? ?? false,
        lastUpdated: json['lastUpdated'] != null ? DateTime.parse(json['lastUpdated'] as String) : null,
        isPro: json['isPro'] as bool? ?? false,
        themeMode: json['themeMode'] as String? ?? 'system',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'mileageRate': mileageRate,
        'trackingSensitivity': trackingSensitivity,
        'notificationsEnabled': notificationsEnabled,
        'tripEndConfirmation': tripEndConfirmation,
        'defaultVehicleId': defaultVehicleId,
        'hasCompletedOnboarding': hasCompletedOnboarding,
        'lastUpdated': lastUpdated?.toIso8601String(),
        'isPro': isPro,
        'themeMode': themeMode,
      };

  /// Returns the effective rate (global for v1)
  double get effectiveRate => mileageRate;
}
