// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trip.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$Trip {
  String get id => throw _privateConstructorUsedError;
  DateTime get startTime => throw _privateConstructorUsedError;
  DateTime get endTime => throw _privateConstructorUsedError;
  double get distanceMiles => throw _privateConstructorUsedError;
  int get durationMinutes => throw _privateConstructorUsedError;
  List<LatLngPoint> get routePoints => throw _privateConstructorUsedError;
  TripCategory get category => throw _privateConstructorUsedError;

  /// Optional user-defined category label (overrides the enum name in UI).
  String? get customCategoryLabel => throw _privateConstructorUsedError;

  /// ARGB color for the custom category label.
  int? get customCategoryColor => throw _privateConstructorUsedError;
  String? get purpose => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;

  /// Human-readable start/end addresses (resolved via optional geocoding).
  String? get startAddress => throw _privateConstructorUsedError;
  String? get endAddress => throw _privateConstructorUsedError;

  /// Tolls, parking, and other out-of-pocket expenses attached to the trip.
  List<TripExpense> get expenses => throw _privateConstructorUsedError;
  String? get vehicleId => throw _privateConstructorUsedError;
  double? get startOdometer => throw _privateConstructorUsedError;
  double? get endOdometer => throw _privateConstructorUsedError;
  bool get isConfirmed => throw _privateConstructorUsedError;
  String? get startLocationId => throw _privateConstructorUsedError;
  String? get endLocationId => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $TripCopyWith<Trip> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TripCopyWith<$Res> {
  factory $TripCopyWith(Trip value, $Res Function(Trip) then) =
      _$TripCopyWithImpl<$Res, Trip>;
  @useResult
  $Res call(
      {String id,
      DateTime startTime,
      DateTime endTime,
      double distanceMiles,
      int durationMinutes,
      List<LatLngPoint> routePoints,
      TripCategory category,
      String? customCategoryLabel,
      int? customCategoryColor,
      String? purpose,
      String? notes,
      String? startAddress,
      String? endAddress,
      List<TripExpense> expenses,
      String? vehicleId,
      double? startOdometer,
      double? endOdometer,
      bool isConfirmed,
      String? startLocationId,
      String? endLocationId});
}

/// @nodoc
class _$TripCopyWithImpl<$Res, $Val extends Trip>
    implements $TripCopyWith<$Res> {
  _$TripCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? startTime = null,
    Object? endTime = null,
    Object? distanceMiles = null,
    Object? durationMinutes = null,
    Object? routePoints = null,
    Object? category = null,
    Object? customCategoryLabel = freezed,
    Object? customCategoryColor = freezed,
    Object? purpose = freezed,
    Object? notes = freezed,
    Object? startAddress = freezed,
    Object? endAddress = freezed,
    Object? expenses = null,
    Object? vehicleId = freezed,
    Object? startOdometer = freezed,
    Object? endOdometer = freezed,
    Object? isConfirmed = null,
    Object? startLocationId = freezed,
    Object? endLocationId = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endTime: null == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      distanceMiles: null == distanceMiles
          ? _value.distanceMiles
          : distanceMiles // ignore: cast_nullable_to_non_nullable
              as double,
      durationMinutes: null == durationMinutes
          ? _value.durationMinutes
          : durationMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      routePoints: null == routePoints
          ? _value.routePoints
          : routePoints // ignore: cast_nullable_to_non_nullable
              as List<LatLngPoint>,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as TripCategory,
      customCategoryLabel: freezed == customCategoryLabel
          ? _value.customCategoryLabel
          : customCategoryLabel // ignore: cast_nullable_to_non_nullable
              as String?,
      customCategoryColor: freezed == customCategoryColor
          ? _value.customCategoryColor
          : customCategoryColor // ignore: cast_nullable_to_non_nullable
              as int?,
      purpose: freezed == purpose
          ? _value.purpose
          : purpose // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      startAddress: freezed == startAddress
          ? _value.startAddress
          : startAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      endAddress: freezed == endAddress
          ? _value.endAddress
          : endAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      expenses: null == expenses
          ? _value.expenses
          : expenses // ignore: cast_nullable_to_non_nullable
              as List<TripExpense>,
      vehicleId: freezed == vehicleId
          ? _value.vehicleId
          : vehicleId // ignore: cast_nullable_to_non_nullable
              as String?,
      startOdometer: freezed == startOdometer
          ? _value.startOdometer
          : startOdometer // ignore: cast_nullable_to_non_nullable
              as double?,
      endOdometer: freezed == endOdometer
          ? _value.endOdometer
          : endOdometer // ignore: cast_nullable_to_non_nullable
              as double?,
      isConfirmed: null == isConfirmed
          ? _value.isConfirmed
          : isConfirmed // ignore: cast_nullable_to_non_nullable
              as bool,
      startLocationId: freezed == startLocationId
          ? _value.startLocationId
          : startLocationId // ignore: cast_nullable_to_non_nullable
              as String?,
      endLocationId: freezed == endLocationId
          ? _value.endLocationId
          : endLocationId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TripImplCopyWith<$Res> implements $TripCopyWith<$Res> {
  factory _$$TripImplCopyWith(
          _$TripImpl value, $Res Function(_$TripImpl) then) =
      __$$TripImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      DateTime startTime,
      DateTime endTime,
      double distanceMiles,
      int durationMinutes,
      List<LatLngPoint> routePoints,
      TripCategory category,
      String? customCategoryLabel,
      int? customCategoryColor,
      String? purpose,
      String? notes,
      String? startAddress,
      String? endAddress,
      List<TripExpense> expenses,
      String? vehicleId,
      double? startOdometer,
      double? endOdometer,
      bool isConfirmed,
      String? startLocationId,
      String? endLocationId});
}

/// @nodoc
class __$$TripImplCopyWithImpl<$Res>
    extends _$TripCopyWithImpl<$Res, _$TripImpl>
    implements _$$TripImplCopyWith<$Res> {
  __$$TripImplCopyWithImpl(_$TripImpl _value, $Res Function(_$TripImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? startTime = null,
    Object? endTime = null,
    Object? distanceMiles = null,
    Object? durationMinutes = null,
    Object? routePoints = null,
    Object? category = null,
    Object? customCategoryLabel = freezed,
    Object? customCategoryColor = freezed,
    Object? purpose = freezed,
    Object? notes = freezed,
    Object? startAddress = freezed,
    Object? endAddress = freezed,
    Object? expenses = null,
    Object? vehicleId = freezed,
    Object? startOdometer = freezed,
    Object? endOdometer = freezed,
    Object? isConfirmed = null,
    Object? startLocationId = freezed,
    Object? endLocationId = freezed,
  }) {
    return _then(_$TripImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endTime: null == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      distanceMiles: null == distanceMiles
          ? _value.distanceMiles
          : distanceMiles // ignore: cast_nullable_to_non_nullable
              as double,
      durationMinutes: null == durationMinutes
          ? _value.durationMinutes
          : durationMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      routePoints: null == routePoints
          ? _value._routePoints
          : routePoints // ignore: cast_nullable_to_non_nullable
              as List<LatLngPoint>,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as TripCategory,
      customCategoryLabel: freezed == customCategoryLabel
          ? _value.customCategoryLabel
          : customCategoryLabel // ignore: cast_nullable_to_non_nullable
              as String?,
      customCategoryColor: freezed == customCategoryColor
          ? _value.customCategoryColor
          : customCategoryColor // ignore: cast_nullable_to_non_nullable
              as int?,
      purpose: freezed == purpose
          ? _value.purpose
          : purpose // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      startAddress: freezed == startAddress
          ? _value.startAddress
          : startAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      endAddress: freezed == endAddress
          ? _value.endAddress
          : endAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      expenses: null == expenses
          ? _value._expenses
          : expenses // ignore: cast_nullable_to_non_nullable
              as List<TripExpense>,
      vehicleId: freezed == vehicleId
          ? _value.vehicleId
          : vehicleId // ignore: cast_nullable_to_non_nullable
              as String?,
      startOdometer: freezed == startOdometer
          ? _value.startOdometer
          : startOdometer // ignore: cast_nullable_to_non_nullable
              as double?,
      endOdometer: freezed == endOdometer
          ? _value.endOdometer
          : endOdometer // ignore: cast_nullable_to_non_nullable
              as double?,
      isConfirmed: null == isConfirmed
          ? _value.isConfirmed
          : isConfirmed // ignore: cast_nullable_to_non_nullable
              as bool,
      startLocationId: freezed == startLocationId
          ? _value.startLocationId
          : startLocationId // ignore: cast_nullable_to_non_nullable
              as String?,
      endLocationId: freezed == endLocationId
          ? _value.endLocationId
          : endLocationId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$TripImpl extends _Trip {
  const _$TripImpl(
      {required this.id,
      required this.startTime,
      required this.endTime,
      required this.distanceMiles,
      required this.durationMinutes,
      required final List<LatLngPoint> routePoints,
      required this.category,
      this.customCategoryLabel,
      this.customCategoryColor,
      this.purpose,
      this.notes,
      this.startAddress,
      this.endAddress,
      final List<TripExpense> expenses = const [],
      this.vehicleId,
      this.startOdometer,
      this.endOdometer,
      this.isConfirmed = false,
      this.startLocationId,
      this.endLocationId})
      : _routePoints = routePoints,
        _expenses = expenses,
        super._();

  @override
  final String id;
  @override
  final DateTime startTime;
  @override
  final DateTime endTime;
  @override
  final double distanceMiles;
  @override
  final int durationMinutes;
  final List<LatLngPoint> _routePoints;
  @override
  List<LatLngPoint> get routePoints {
    if (_routePoints is EqualUnmodifiableListView) return _routePoints;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_routePoints);
  }

  @override
  final TripCategory category;

  /// Optional user-defined category label (overrides the enum name in UI).
  @override
  final String? customCategoryLabel;

  /// ARGB color for the custom category label.
  @override
  final int? customCategoryColor;
  @override
  final String? purpose;
  @override
  final String? notes;

  /// Human-readable start/end addresses (resolved via optional geocoding).
  @override
  final String? startAddress;
  @override
  final String? endAddress;

  /// Tolls, parking, and other out-of-pocket expenses attached to the trip.
  final List<TripExpense> _expenses;

  /// Tolls, parking, and other out-of-pocket expenses attached to the trip.
  @override
  @JsonKey()
  List<TripExpense> get expenses {
    if (_expenses is EqualUnmodifiableListView) return _expenses;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_expenses);
  }

  @override
  final String? vehicleId;
  @override
  final double? startOdometer;
  @override
  final double? endOdometer;
  @override
  @JsonKey()
  final bool isConfirmed;
  @override
  final String? startLocationId;
  @override
  final String? endLocationId;

  @override
  String toString() {
    return 'Trip(id: $id, startTime: $startTime, endTime: $endTime, distanceMiles: $distanceMiles, durationMinutes: $durationMinutes, routePoints: $routePoints, category: $category, customCategoryLabel: $customCategoryLabel, customCategoryColor: $customCategoryColor, purpose: $purpose, notes: $notes, startAddress: $startAddress, endAddress: $endAddress, expenses: $expenses, vehicleId: $vehicleId, startOdometer: $startOdometer, endOdometer: $endOdometer, isConfirmed: $isConfirmed, startLocationId: $startLocationId, endLocationId: $endLocationId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TripImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.distanceMiles, distanceMiles) ||
                other.distanceMiles == distanceMiles) &&
            (identical(other.durationMinutes, durationMinutes) ||
                other.durationMinutes == durationMinutes) &&
            const DeepCollectionEquality()
                .equals(other._routePoints, _routePoints) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.customCategoryLabel, customCategoryLabel) ||
                other.customCategoryLabel == customCategoryLabel) &&
            (identical(other.customCategoryColor, customCategoryColor) ||
                other.customCategoryColor == customCategoryColor) &&
            (identical(other.purpose, purpose) || other.purpose == purpose) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.startAddress, startAddress) ||
                other.startAddress == startAddress) &&
            (identical(other.endAddress, endAddress) ||
                other.endAddress == endAddress) &&
            const DeepCollectionEquality().equals(other._expenses, _expenses) &&
            (identical(other.vehicleId, vehicleId) ||
                other.vehicleId == vehicleId) &&
            (identical(other.startOdometer, startOdometer) ||
                other.startOdometer == startOdometer) &&
            (identical(other.endOdometer, endOdometer) ||
                other.endOdometer == endOdometer) &&
            (identical(other.isConfirmed, isConfirmed) ||
                other.isConfirmed == isConfirmed) &&
            (identical(other.startLocationId, startLocationId) ||
                other.startLocationId == startLocationId) &&
            (identical(other.endLocationId, endLocationId) ||
                other.endLocationId == endLocationId));
  }

  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        startTime,
        endTime,
        distanceMiles,
        durationMinutes,
        const DeepCollectionEquality().hash(_routePoints),
        category,
        customCategoryLabel,
        customCategoryColor,
        purpose,
        notes,
        startAddress,
        endAddress,
        const DeepCollectionEquality().hash(_expenses),
        vehicleId,
        startOdometer,
        endOdometer,
        isConfirmed,
        startLocationId,
        endLocationId
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TripImplCopyWith<_$TripImpl> get copyWith =>
      __$$TripImplCopyWithImpl<_$TripImpl>(this, _$identity);
}

abstract class _Trip extends Trip {
  const factory _Trip(
      {required final String id,
      required final DateTime startTime,
      required final DateTime endTime,
      required final double distanceMiles,
      required final int durationMinutes,
      required final List<LatLngPoint> routePoints,
      required final TripCategory category,
      final String? customCategoryLabel,
      final int? customCategoryColor,
      final String? purpose,
      final String? notes,
      final String? startAddress,
      final String? endAddress,
      final List<TripExpense> expenses,
      final String? vehicleId,
      final double? startOdometer,
      final double? endOdometer,
      final bool isConfirmed,
      final String? startLocationId,
      final String? endLocationId}) = _$TripImpl;
  const _Trip._() : super._();

  @override
  String get id;
  @override
  DateTime get startTime;
  @override
  DateTime get endTime;
  @override
  double get distanceMiles;
  @override
  int get durationMinutes;
  @override
  List<LatLngPoint> get routePoints;
  @override
  TripCategory get category;
  @override

  /// Optional user-defined category label (overrides the enum name in UI).
  String? get customCategoryLabel;
  @override

  /// ARGB color for the custom category label.
  int? get customCategoryColor;
  @override
  String? get purpose;
  @override
  String? get notes;
  @override

  /// Human-readable start/end addresses (resolved via optional geocoding).
  String? get startAddress;
  @override
  String? get endAddress;
  @override

  /// Tolls, parking, and other out-of-pocket expenses attached to the trip.
  List<TripExpense> get expenses;
  @override
  String? get vehicleId;
  @override
  double? get startOdometer;
  @override
  double? get endOdometer;
  @override
  bool get isConfirmed;
  @override
  String? get startLocationId;
  @override
  String? get endLocationId;
  @override
  @JsonKey(ignore: true)
  _$$TripImplCopyWith<_$TripImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
