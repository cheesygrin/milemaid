import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:milemaid/core/constants/irs_rates.dart';
import 'package:milemaid/core/models/named_location.dart';
import 'package:milemaid/core/models/work_hours.dart';

part 'user_settings.freezed.dart';

/// User profile + app preferences. Stored as JSON in Hive.
@freezed
class UserSettings with _$UserSettings {
  const UserSettings._();

  const factory UserSettings({
    @Default('') String name,
    @Default('') String email,
    /// Dollars per mile. 0 means "use the IRS standard rate for each trip's date".
    @Default(0.0) double mileageRate,
    @Default('Balanced') String trackingSensitivity, // High / Balanced / Battery Saver
    @Default(true) bool notificationsEnabled,
    @Default(true) bool tripEndConfirmation,
    @Default('') String defaultVehicleId,
    /// Work-hours windows that auto-classify drives as Business.
    @Default([]) List<WorkHours> workHours,
    /// Saved places that auto-classify drives starting near them as Business.
    @Default([]) List<NamedLocation> namedLocations,
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
        mileageRate: _migrateRate((json['mileageRate'] as num?)?.toDouble()),
        trackingSensitivity: json['trackingSensitivity'] as String? ?? 'Balanced',
        notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
        tripEndConfirmation: json['tripEndConfirmation'] as bool? ?? true,
        defaultVehicleId: json['defaultVehicleId'] as String? ?? '',
        workHours: (json['workHours'] as List<dynamic>? ?? [])
            .map((e) => WorkHours.fromJson(e as Map<String, dynamic>))
            .toList(),
        namedLocations: (json['namedLocations'] as List<dynamic>? ?? [])
            .map((e) => NamedLocation.fromJson(e as Map<String, dynamic>))
            .toList(),
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
        'workHours': workHours.map((e) => e.toJson()).toList(),
        'namedLocations': namedLocations.map((e) => e.toJson()).toList(),
        'hasCompletedOnboarding': hasCompletedOnboarding,
        'lastUpdated': lastUpdated?.toIso8601String(),
        'isPro': isPro,
        'themeMode': themeMode,
      };

  /// Earlier builds stored a hard-coded 0.72 as the default, which was never an
  /// actual IRS rate. Treat it as "follow the IRS rate".
  static double _migrateRate(double? stored) {
    if (stored == null || stored == 0.72) return 0.0;
    return stored;
  }

  /// True when the rate follows the IRS standard rate by trip date.
  bool get usesIrsRate => mileageRate <= 0;

  /// The rate that applies to a trip on [date].
  double rateFor(DateTime date) =>
      usesIrsRate ? IrsRates.rateFor(date) : mileageRate;

  /// The rate that applies today.
  double get effectiveRate => rateFor(DateTime.now());
}