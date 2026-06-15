// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vehicle.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$Vehicle {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get makeModel => throw _privateConstructorUsedError;
  int get year => throw _privateConstructorUsedError;
  String? get color => throw _privateConstructorUsedError;
  String? get licensePlate => throw _privateConstructorUsedError;

  /// Optional per-vehicle custom rate override (null = use global)
  double? get customRatePerMile => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $VehicleCopyWith<Vehicle> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VehicleCopyWith<$Res> {
  factory $VehicleCopyWith(Vehicle value, $Res Function(Vehicle) then) =
      _$VehicleCopyWithImpl<$Res, Vehicle>;
  @useResult
  $Res call(
      {String id,
      String name,
      String makeModel,
      int year,
      String? color,
      String? licensePlate,
      double? customRatePerMile});
}

/// @nodoc
class _$VehicleCopyWithImpl<$Res, $Val extends Vehicle>
    implements $VehicleCopyWith<$Res> {
  _$VehicleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? makeModel = null,
    Object? year = null,
    Object? color = freezed,
    Object? licensePlate = freezed,
    Object? customRatePerMile = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      makeModel: null == makeModel
          ? _value.makeModel
          : makeModel // ignore: cast_nullable_to_non_nullable
              as String,
      year: null == year
          ? _value.year
          : year // ignore: cast_nullable_to_non_nullable
              as int,
      color: freezed == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as String?,
      licensePlate: freezed == licensePlate
          ? _value.licensePlate
          : licensePlate // ignore: cast_nullable_to_non_nullable
              as String?,
      customRatePerMile: freezed == customRatePerMile
          ? _value.customRatePerMile
          : customRatePerMile // ignore: cast_nullable_to_non_nullable
              as double?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$VehicleImplCopyWith<$Res> implements $VehicleCopyWith<$Res> {
  factory _$$VehicleImplCopyWith(
          _$VehicleImpl value, $Res Function(_$VehicleImpl) then) =
      __$$VehicleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String makeModel,
      int year,
      String? color,
      String? licensePlate,
      double? customRatePerMile});
}

/// @nodoc
class __$$VehicleImplCopyWithImpl<$Res>
    extends _$VehicleCopyWithImpl<$Res, _$VehicleImpl>
    implements _$$VehicleImplCopyWith<$Res> {
  __$$VehicleImplCopyWithImpl(
      _$VehicleImpl _value, $Res Function(_$VehicleImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? makeModel = null,
    Object? year = null,
    Object? color = freezed,
    Object? licensePlate = freezed,
    Object? customRatePerMile = freezed,
  }) {
    return _then(_$VehicleImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      makeModel: null == makeModel
          ? _value.makeModel
          : makeModel // ignore: cast_nullable_to_non_nullable
              as String,
      year: null == year
          ? _value.year
          : year // ignore: cast_nullable_to_non_nullable
              as int,
      color: freezed == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as String?,
      licensePlate: freezed == licensePlate
          ? _value.licensePlate
          : licensePlate // ignore: cast_nullable_to_non_nullable
              as String?,
      customRatePerMile: freezed == customRatePerMile
          ? _value.customRatePerMile
          : customRatePerMile // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

/// @nodoc

class _$VehicleImpl extends _Vehicle {
  const _$VehicleImpl(
      {required this.id,
      required this.name,
      required this.makeModel,
      this.year = 2024,
      this.color,
      this.licensePlate,
      this.customRatePerMile})
      : super._();

  @override
  final String id;
  @override
  final String name;
  @override
  final String makeModel;
  @override
  @JsonKey()
  final int year;
  @override
  final String? color;
  @override
  final String? licensePlate;

  /// Optional per-vehicle custom rate override (null = use global)
  @override
  final double? customRatePerMile;

  @override
  String toString() {
    return 'Vehicle(id: $id, name: $name, makeModel: $makeModel, year: $year, color: $color, licensePlate: $licensePlate, customRatePerMile: $customRatePerMile)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VehicleImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.makeModel, makeModel) ||
                other.makeModel == makeModel) &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.licensePlate, licensePlate) ||
                other.licensePlate == licensePlate) &&
            (identical(other.customRatePerMile, customRatePerMile) ||
                other.customRatePerMile == customRatePerMile));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, name, makeModel, year, color,
      licensePlate, customRatePerMile);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$VehicleImplCopyWith<_$VehicleImpl> get copyWith =>
      __$$VehicleImplCopyWithImpl<_$VehicleImpl>(this, _$identity);
}

abstract class _Vehicle extends Vehicle {
  const factory _Vehicle(
      {required final String id,
      required final String name,
      required final String makeModel,
      final int year,
      final String? color,
      final String? licensePlate,
      final double? customRatePerMile}) = _$VehicleImpl;
  const _Vehicle._() : super._();

  @override
  String get id;
  @override
  String get name;
  @override
  String get makeModel;
  @override
  int get year;
  @override
  String? get color;
  @override
  String? get licensePlate;
  @override

  /// Optional per-vehicle custom rate override (null = use global)
  double? get customRatePerMile;
  @override
  @JsonKey(ignore: true)
  _$$VehicleImplCopyWith<_$VehicleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
