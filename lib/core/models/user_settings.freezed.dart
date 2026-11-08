// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$UserSettings {
  String get name => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;

  /// Dollars per mile. 0 means "use the IRS standard rate for each trip's date".
  double get mileageRate => throw _privateConstructorUsedError;
  String get trackingSensitivity =>
      throw _privateConstructorUsedError; // High / Balanced / Battery Saver
  bool get notificationsEnabled => throw _privateConstructorUsedError;
  bool get tripEndConfirmation => throw _privateConstructorUsedError;

  /// Resolve start/end addresses from coordinates. Opt-in: it sends
  /// coordinates to a third-party geocoder (Nominatim).
  bool get geocodingEnabled => throw _privateConstructorUsedError;
  String get defaultVehicleId => throw _privateConstructorUsedError;

  /// Work-hours windows that auto-classify drives as Business.
  List<WorkHours> get workHours => throw _privateConstructorUsedError;

  /// Saved places that auto-classify drives starting near them as Business.
  List<NamedLocation> get namedLocations => throw _privateConstructorUsedError;

  /// User-defined category labels (label + color).
  List<CategoryLabel> get customCategories =>
      throw _privateConstructorUsedError;

  /// Onboarding completed flag
  bool get hasCompletedOnboarding => throw _privateConstructorUsedError;

  /// Last time we synced or updated (for future)
  DateTime? get lastUpdated => throw _privateConstructorUsedError;

  /// Whether the user has an active Pro / Premium subscription.
  /// For now this is local-only (unlocked via in-app purchase in a real release).
  bool get isPro => throw _privateConstructorUsedError;

  /// Theme preference: "system", "light", or "dark"
  String get themeMode => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $UserSettingsCopyWith<UserSettings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserSettingsCopyWith<$Res> {
  factory $UserSettingsCopyWith(
          UserSettings value, $Res Function(UserSettings) then) =
      _$UserSettingsCopyWithImpl<$Res, UserSettings>;
  @useResult
  $Res call(
      {String name,
      String email,
      double mileageRate,
      String trackingSensitivity,
      bool notificationsEnabled,
      bool tripEndConfirmation,
      bool geocodingEnabled,
      String defaultVehicleId,
      List<WorkHours> workHours,
      List<NamedLocation> namedLocations,
      List<CategoryLabel> customCategories,
      bool hasCompletedOnboarding,
      DateTime? lastUpdated,
      bool isPro,
      String themeMode});
}

/// @nodoc
class _$UserSettingsCopyWithImpl<$Res, $Val extends UserSettings>
    implements $UserSettingsCopyWith<$Res> {
  _$UserSettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? email = null,
    Object? mileageRate = null,
    Object? trackingSensitivity = null,
    Object? notificationsEnabled = null,
    Object? tripEndConfirmation = null,
    Object? geocodingEnabled = null,
    Object? defaultVehicleId = null,
    Object? workHours = null,
    Object? namedLocations = null,
    Object? customCategories = null,
    Object? hasCompletedOnboarding = null,
    Object? lastUpdated = freezed,
    Object? isPro = null,
    Object? themeMode = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      mileageRate: null == mileageRate
          ? _value.mileageRate
          : mileageRate // ignore: cast_nullable_to_non_nullable
              as double,
      trackingSensitivity: null == trackingSensitivity
          ? _value.trackingSensitivity
          : trackingSensitivity // ignore: cast_nullable_to_non_nullable
              as String,
      notificationsEnabled: null == notificationsEnabled
          ? _value.notificationsEnabled
          : notificationsEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      tripEndConfirmation: null == tripEndConfirmation
          ? _value.tripEndConfirmation
          : tripEndConfirmation // ignore: cast_nullable_to_non_nullable
              as bool,
      geocodingEnabled: null == geocodingEnabled
          ? _value.geocodingEnabled
          : geocodingEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      defaultVehicleId: null == defaultVehicleId
          ? _value.defaultVehicleId
          : defaultVehicleId // ignore: cast_nullable_to_non_nullable
              as String,
      workHours: null == workHours
          ? _value.workHours
          : workHours // ignore: cast_nullable_to_non_nullable
              as List<WorkHours>,
      namedLocations: null == namedLocations
          ? _value.namedLocations
          : namedLocations // ignore: cast_nullable_to_non_nullable
              as List<NamedLocation>,
      customCategories: null == customCategories
          ? _value.customCategories
          : customCategories // ignore: cast_nullable_to_non_nullable
              as List<CategoryLabel>,
      hasCompletedOnboarding: null == hasCompletedOnboarding
          ? _value.hasCompletedOnboarding
          : hasCompletedOnboarding // ignore: cast_nullable_to_non_nullable
              as bool,
      lastUpdated: freezed == lastUpdated
          ? _value.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isPro: null == isPro
          ? _value.isPro
          : isPro // ignore: cast_nullable_to_non_nullable
              as bool,
      themeMode: null == themeMode
          ? _value.themeMode
          : themeMode // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserSettingsImplCopyWith<$Res>
    implements $UserSettingsCopyWith<$Res> {
  factory _$$UserSettingsImplCopyWith(
          _$UserSettingsImpl value, $Res Function(_$UserSettingsImpl) then) =
      __$$UserSettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      String email,
      double mileageRate,
      String trackingSensitivity,
      bool notificationsEnabled,
      bool tripEndConfirmation,
      bool geocodingEnabled,
      String defaultVehicleId,
      List<WorkHours> workHours,
      List<NamedLocation> namedLocations,
      List<CategoryLabel> customCategories,
      bool hasCompletedOnboarding,
      DateTime? lastUpdated,
      bool isPro,
      String themeMode});
}

/// @nodoc
class __$$UserSettingsImplCopyWithImpl<$Res>
    extends _$UserSettingsCopyWithImpl<$Res, _$UserSettingsImpl>
    implements _$$UserSettingsImplCopyWith<$Res> {
  __$$UserSettingsImplCopyWithImpl(
      _$UserSettingsImpl _value, $Res Function(_$UserSettingsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? email = null,
    Object? mileageRate = null,
    Object? trackingSensitivity = null,
    Object? notificationsEnabled = null,
    Object? tripEndConfirmation = null,
    Object? geocodingEnabled = null,
    Object? defaultVehicleId = null,
    Object? workHours = null,
    Object? namedLocations = null,
    Object? customCategories = null,
    Object? hasCompletedOnboarding = null,
    Object? lastUpdated = freezed,
    Object? isPro = null,
    Object? themeMode = null,
  }) {
    return _then(_$UserSettingsImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      mileageRate: null == mileageRate
          ? _value.mileageRate
          : mileageRate // ignore: cast_nullable_to_non_nullable
              as double,
      trackingSensitivity: null == trackingSensitivity
          ? _value.trackingSensitivity
          : trackingSensitivity // ignore: cast_nullable_to_non_nullable
              as String,
      notificationsEnabled: null == notificationsEnabled
          ? _value.notificationsEnabled
          : notificationsEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      tripEndConfirmation: null == tripEndConfirmation
          ? _value.tripEndConfirmation
          : tripEndConfirmation // ignore: cast_nullable_to_non_nullable
              as bool,
      geocodingEnabled: null == geocodingEnabled
          ? _value.geocodingEnabled
          : geocodingEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      defaultVehicleId: null == defaultVehicleId
          ? _value.defaultVehicleId
          : defaultVehicleId // ignore: cast_nullable_to_non_nullable
              as String,
      workHours: null == workHours
          ? _value._workHours
          : workHours // ignore: cast_nullable_to_non_nullable
              as List<WorkHours>,
      namedLocations: null == namedLocations
          ? _value._namedLocations
          : namedLocations // ignore: cast_nullable_to_non_nullable
              as List<NamedLocation>,
      customCategories: null == customCategories
          ? _value._customCategories
          : customCategories // ignore: cast_nullable_to_non_nullable
              as List<CategoryLabel>,
      hasCompletedOnboarding: null == hasCompletedOnboarding
          ? _value.hasCompletedOnboarding
          : hasCompletedOnboarding // ignore: cast_nullable_to_non_nullable
              as bool,
      lastUpdated: freezed == lastUpdated
          ? _value.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isPro: null == isPro
          ? _value.isPro
          : isPro // ignore: cast_nullable_to_non_nullable
              as bool,
      themeMode: null == themeMode
          ? _value.themeMode
          : themeMode // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$UserSettingsImpl extends _UserSettings {
  const _$UserSettingsImpl(
      {this.name = '',
      this.email = '',
      this.mileageRate = 0.0,
      this.trackingSensitivity = 'Balanced',
      this.notificationsEnabled = true,
      this.tripEndConfirmation = true,
      this.geocodingEnabled = false,
      this.defaultVehicleId = '',
      final List<WorkHours> workHours = const [],
      final List<NamedLocation> namedLocations = const [],
      final List<CategoryLabel> customCategories = const [],
      this.hasCompletedOnboarding = false,
      this.lastUpdated,
      this.isPro = false,
      this.themeMode = 'system'})
      : _workHours = workHours,
        _namedLocations = namedLocations,
        _customCategories = customCategories,
        super._();

  @override
  @JsonKey()
  final String name;
  @override
  @JsonKey()
  final String email;

  /// Dollars per mile. 0 means "use the IRS standard rate for each trip's date".
  @override
  @JsonKey()
  final double mileageRate;
  @override
  @JsonKey()
  final String trackingSensitivity;
// High / Balanced / Battery Saver
  @override
  @JsonKey()
  final bool notificationsEnabled;
  @override
  @JsonKey()
  final bool tripEndConfirmation;

  /// Resolve start/end addresses from coordinates. Opt-in: it sends
  /// coordinates to a third-party geocoder (Nominatim).
  @override
  @JsonKey()
  final bool geocodingEnabled;
  @override
  @JsonKey()
  final String defaultVehicleId;

  /// Work-hours windows that auto-classify drives as Business.
  final List<WorkHours> _workHours;

  /// Work-hours windows that auto-classify drives as Business.
  @override
  @JsonKey()
  List<WorkHours> get workHours {
    if (_workHours is EqualUnmodifiableListView) return _workHours;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_workHours);
  }

  /// Saved places that auto-classify drives starting near them as Business.
  final List<NamedLocation> _namedLocations;

  /// Saved places that auto-classify drives starting near them as Business.
  @override
  @JsonKey()
  List<NamedLocation> get namedLocations {
    if (_namedLocations is EqualUnmodifiableListView) return _namedLocations;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_namedLocations);
  }

  /// User-defined category labels (label + color).
  final List<CategoryLabel> _customCategories;

  /// User-defined category labels (label + color).
  @override
  @JsonKey()
  List<CategoryLabel> get customCategories {
    if (_customCategories is EqualUnmodifiableListView)
      return _customCategories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_customCategories);
  }

  /// Onboarding completed flag
  @override
  @JsonKey()
  final bool hasCompletedOnboarding;

  /// Last time we synced or updated (for future)
  @override
  final DateTime? lastUpdated;

  /// Whether the user has an active Pro / Premium subscription.
  /// For now this is local-only (unlocked via in-app purchase in a real release).
  @override
  @JsonKey()
  final bool isPro;

  /// Theme preference: "system", "light", or "dark"
  @override
  @JsonKey()
  final String themeMode;

  @override
  String toString() {
    return 'UserSettings(name: $name, email: $email, mileageRate: $mileageRate, trackingSensitivity: $trackingSensitivity, notificationsEnabled: $notificationsEnabled, tripEndConfirmation: $tripEndConfirmation, geocodingEnabled: $geocodingEnabled, defaultVehicleId: $defaultVehicleId, workHours: $workHours, namedLocations: $namedLocations, customCategories: $customCategories, hasCompletedOnboarding: $hasCompletedOnboarding, lastUpdated: $lastUpdated, isPro: $isPro, themeMode: $themeMode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserSettingsImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.mileageRate, mileageRate) ||
                other.mileageRate == mileageRate) &&
            (identical(other.trackingSensitivity, trackingSensitivity) ||
                other.trackingSensitivity == trackingSensitivity) &&
            (identical(other.notificationsEnabled, notificationsEnabled) ||
                other.notificationsEnabled == notificationsEnabled) &&
            (identical(other.tripEndConfirmation, tripEndConfirmation) ||
                other.tripEndConfirmation == tripEndConfirmation) &&
            (identical(other.geocodingEnabled, geocodingEnabled) ||
                other.geocodingEnabled == geocodingEnabled) &&
            (identical(other.defaultVehicleId, defaultVehicleId) ||
                other.defaultVehicleId == defaultVehicleId) &&
            const DeepCollectionEquality()
                .equals(other._workHours, _workHours) &&
            const DeepCollectionEquality()
                .equals(other._namedLocations, _namedLocations) &&
            const DeepCollectionEquality()
                .equals(other._customCategories, _customCategories) &&
            (identical(other.hasCompletedOnboarding, hasCompletedOnboarding) ||
                other.hasCompletedOnboarding == hasCompletedOnboarding) &&
            (identical(other.lastUpdated, lastUpdated) ||
                other.lastUpdated == lastUpdated) &&
            (identical(other.isPro, isPro) || other.isPro == isPro) &&
            (identical(other.themeMode, themeMode) ||
                other.themeMode == themeMode));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      name,
      email,
      mileageRate,
      trackingSensitivity,
      notificationsEnabled,
      tripEndConfirmation,
      geocodingEnabled,
      defaultVehicleId,
      const DeepCollectionEquality().hash(_workHours),
      const DeepCollectionEquality().hash(_namedLocations),
      const DeepCollectionEquality().hash(_customCategories),
      hasCompletedOnboarding,
      lastUpdated,
      isPro,
      themeMode);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserSettingsImplCopyWith<_$UserSettingsImpl> get copyWith =>
      __$$UserSettingsImplCopyWithImpl<_$UserSettingsImpl>(this, _$identity);
}

abstract class _UserSettings extends UserSettings {
  const factory _UserSettings(
      {final String name,
      final String email,
      final double mileageRate,
      final String trackingSensitivity,
      final bool notificationsEnabled,
      final bool tripEndConfirmation,
      final bool geocodingEnabled,
      final String defaultVehicleId,
      final List<WorkHours> workHours,
      final List<NamedLocation> namedLocations,
      final List<CategoryLabel> customCategories,
      final bool hasCompletedOnboarding,
      final DateTime? lastUpdated,
      final bool isPro,
      final String themeMode}) = _$UserSettingsImpl;
  const _UserSettings._() : super._();

  @override
  String get name;
  @override
  String get email;
  @override

  /// Dollars per mile. 0 means "use the IRS standard rate for each trip's date".
  double get mileageRate;
  @override
  String get trackingSensitivity;
  @override // High / Balanced / Battery Saver
  bool get notificationsEnabled;
  @override
  bool get tripEndConfirmation;
  @override

  /// Resolve start/end addresses from coordinates. Opt-in: it sends
  /// coordinates to a third-party geocoder (Nominatim).
  bool get geocodingEnabled;
  @override
  String get defaultVehicleId;
  @override

  /// Work-hours windows that auto-classify drives as Business.
  List<WorkHours> get workHours;
  @override

  /// Saved places that auto-classify drives starting near them as Business.
  List<NamedLocation> get namedLocations;
  @override

  /// User-defined category labels (label + color).
  List<CategoryLabel> get customCategories;
  @override

  /// Onboarding completed flag
  bool get hasCompletedOnboarding;
  @override

  /// Last time we synced or updated (for future)
  DateTime? get lastUpdated;
  @override

  /// Whether the user has an active Pro / Premium subscription.
  /// For now this is local-only (unlocked via in-app purchase in a real release).
  bool get isPro;
  @override

  /// Theme preference: "system", "light", or "dark"
  String get themeMode;
  @override
  @JsonKey(ignore: true)
  _$$UserSettingsImplCopyWith<_$UserSettingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
