// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'host_update.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
mixin _$HostUpdate {
  String get fqdn => throw _privateConstructorUsedError;
  String get ipAddress => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String fqdn, String ipAddress) ipv4,
    required TResult Function(String fqdn, String ipAddress) ipv6,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String fqdn, String ipAddress)? ipv4,
    TResult? Function(String fqdn, String ipAddress)? ipv6,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String fqdn, String ipAddress)? ipv4,
    TResult Function(String fqdn, String ipAddress)? ipv6,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_HostUpdateIpv4 value) ipv4,
    required TResult Function(_HostUpdateIpv6 value) ipv6,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_HostUpdateIpv4 value)? ipv4,
    TResult? Function(_HostUpdateIpv6 value)? ipv6,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_HostUpdateIpv4 value)? ipv4,
    TResult Function(_HostUpdateIpv6 value)? ipv6,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $HostUpdateCopyWith<HostUpdate> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HostUpdateCopyWith<$Res> {
  factory $HostUpdateCopyWith(
          HostUpdate value, $Res Function(HostUpdate) then) =
      _$HostUpdateCopyWithImpl<$Res, HostUpdate>;
  @useResult
  $Res call({String fqdn, String ipAddress});
}

/// @nodoc
class _$HostUpdateCopyWithImpl<$Res, $Val extends HostUpdate>
    implements $HostUpdateCopyWith<$Res> {
  _$HostUpdateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fqdn = null,
    Object? ipAddress = null,
  }) {
    return _then(_value.copyWith(
      fqdn: null == fqdn
          ? _value.fqdn
          : fqdn // ignore: cast_nullable_to_non_nullable
              as String,
      ipAddress: null == ipAddress
          ? _value.ipAddress
          : ipAddress // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_HostUpdateIpv4CopyWith<$Res>
    implements $HostUpdateCopyWith<$Res> {
  factory _$$_HostUpdateIpv4CopyWith(
          _$_HostUpdateIpv4 value, $Res Function(_$_HostUpdateIpv4) then) =
      __$$_HostUpdateIpv4CopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String fqdn, String ipAddress});
}

/// @nodoc
class __$$_HostUpdateIpv4CopyWithImpl<$Res>
    extends _$HostUpdateCopyWithImpl<$Res, _$_HostUpdateIpv4>
    implements _$$_HostUpdateIpv4CopyWith<$Res> {
  __$$_HostUpdateIpv4CopyWithImpl(
      _$_HostUpdateIpv4 _value, $Res Function(_$_HostUpdateIpv4) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fqdn = null,
    Object? ipAddress = null,
  }) {
    return _then(_$_HostUpdateIpv4(
      fqdn: null == fqdn
          ? _value.fqdn
          : fqdn // ignore: cast_nullable_to_non_nullable
              as String,
      ipAddress: null == ipAddress
          ? _value.ipAddress
          : ipAddress // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$_HostUpdateIpv4 implements _HostUpdateIpv4 {
  const _$_HostUpdateIpv4({required this.fqdn, required this.ipAddress});

  @override
  final String fqdn;
  @override
  final String ipAddress;

  @override
  String toString() {
    return 'HostUpdate.ipv4(fqdn: $fqdn, ipAddress: $ipAddress)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_HostUpdateIpv4 &&
            (identical(other.fqdn, fqdn) || other.fqdn == fqdn) &&
            (identical(other.ipAddress, ipAddress) ||
                other.ipAddress == ipAddress));
  }

  @override
  int get hashCode => Object.hash(runtimeType, fqdn, ipAddress);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_HostUpdateIpv4CopyWith<_$_HostUpdateIpv4> get copyWith =>
      __$$_HostUpdateIpv4CopyWithImpl<_$_HostUpdateIpv4>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String fqdn, String ipAddress) ipv4,
    required TResult Function(String fqdn, String ipAddress) ipv6,
  }) {
    return ipv4(fqdn, ipAddress);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String fqdn, String ipAddress)? ipv4,
    TResult? Function(String fqdn, String ipAddress)? ipv6,
  }) {
    return ipv4?.call(fqdn, ipAddress);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String fqdn, String ipAddress)? ipv4,
    TResult Function(String fqdn, String ipAddress)? ipv6,
    required TResult orElse(),
  }) {
    if (ipv4 != null) {
      return ipv4(fqdn, ipAddress);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_HostUpdateIpv4 value) ipv4,
    required TResult Function(_HostUpdateIpv6 value) ipv6,
  }) {
    return ipv4(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_HostUpdateIpv4 value)? ipv4,
    TResult? Function(_HostUpdateIpv6 value)? ipv6,
  }) {
    return ipv4?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_HostUpdateIpv4 value)? ipv4,
    TResult Function(_HostUpdateIpv6 value)? ipv6,
    required TResult orElse(),
  }) {
    if (ipv4 != null) {
      return ipv4(this);
    }
    return orElse();
  }
}

abstract class _HostUpdateIpv4 implements HostUpdate {
  const factory _HostUpdateIpv4(
      {required final String fqdn,
      required final String ipAddress}) = _$_HostUpdateIpv4;

  @override
  String get fqdn;
  @override
  String get ipAddress;
  @override
  @JsonKey(ignore: true)
  _$$_HostUpdateIpv4CopyWith<_$_HostUpdateIpv4> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$_HostUpdateIpv6CopyWith<$Res>
    implements $HostUpdateCopyWith<$Res> {
  factory _$$_HostUpdateIpv6CopyWith(
          _$_HostUpdateIpv6 value, $Res Function(_$_HostUpdateIpv6) then) =
      __$$_HostUpdateIpv6CopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String fqdn, String ipAddress});
}

/// @nodoc
class __$$_HostUpdateIpv6CopyWithImpl<$Res>
    extends _$HostUpdateCopyWithImpl<$Res, _$_HostUpdateIpv6>
    implements _$$_HostUpdateIpv6CopyWith<$Res> {
  __$$_HostUpdateIpv6CopyWithImpl(
      _$_HostUpdateIpv6 _value, $Res Function(_$_HostUpdateIpv6) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fqdn = null,
    Object? ipAddress = null,
  }) {
    return _then(_$_HostUpdateIpv6(
      fqdn: null == fqdn
          ? _value.fqdn
          : fqdn // ignore: cast_nullable_to_non_nullable
              as String,
      ipAddress: null == ipAddress
          ? _value.ipAddress
          : ipAddress // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$_HostUpdateIpv6 implements _HostUpdateIpv6 {
  const _$_HostUpdateIpv6({required this.fqdn, required this.ipAddress});

  @override
  final String fqdn;
  @override
  final String ipAddress;

  @override
  String toString() {
    return 'HostUpdate.ipv6(fqdn: $fqdn, ipAddress: $ipAddress)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_HostUpdateIpv6 &&
            (identical(other.fqdn, fqdn) || other.fqdn == fqdn) &&
            (identical(other.ipAddress, ipAddress) ||
                other.ipAddress == ipAddress));
  }

  @override
  int get hashCode => Object.hash(runtimeType, fqdn, ipAddress);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_HostUpdateIpv6CopyWith<_$_HostUpdateIpv6> get copyWith =>
      __$$_HostUpdateIpv6CopyWithImpl<_$_HostUpdateIpv6>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String fqdn, String ipAddress) ipv4,
    required TResult Function(String fqdn, String ipAddress) ipv6,
  }) {
    return ipv6(fqdn, ipAddress);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String fqdn, String ipAddress)? ipv4,
    TResult? Function(String fqdn, String ipAddress)? ipv6,
  }) {
    return ipv6?.call(fqdn, ipAddress);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String fqdn, String ipAddress)? ipv4,
    TResult Function(String fqdn, String ipAddress)? ipv6,
    required TResult orElse(),
  }) {
    if (ipv6 != null) {
      return ipv6(fqdn, ipAddress);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_HostUpdateIpv4 value) ipv4,
    required TResult Function(_HostUpdateIpv6 value) ipv6,
  }) {
    return ipv6(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_HostUpdateIpv4 value)? ipv4,
    TResult? Function(_HostUpdateIpv6 value)? ipv6,
  }) {
    return ipv6?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_HostUpdateIpv4 value)? ipv4,
    TResult Function(_HostUpdateIpv6 value)? ipv6,
    required TResult orElse(),
  }) {
    if (ipv6 != null) {
      return ipv6(this);
    }
    return orElse();
  }
}

abstract class _HostUpdateIpv6 implements HostUpdate {
  const factory _HostUpdateIpv6(
      {required final String fqdn,
      required final String ipAddress}) = _$_HostUpdateIpv6;

  @override
  String get fqdn;
  @override
  String get ipAddress;
  @override
  @JsonKey(ignore: true)
  _$$_HostUpdateIpv6CopyWith<_$_HostUpdateIpv6> get copyWith =>
      throw _privateConstructorUsedError;
}
