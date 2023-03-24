// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'api_key_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

ApiKeyConfig _$ApiKeyConfigFromJson(Map<String, dynamic> json) {
  return _ApiKeyConfig.fromJson(json);
}

/// @nodoc
mixin _$ApiKeyConfig {
  Map<String, String> get apiKeys => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ApiKeyConfigCopyWith<ApiKeyConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ApiKeyConfigCopyWith<$Res> {
  factory $ApiKeyConfigCopyWith(
          ApiKeyConfig value, $Res Function(ApiKeyConfig) then) =
      _$ApiKeyConfigCopyWithImpl<$Res, ApiKeyConfig>;
  @useResult
  $Res call({Map<String, String> apiKeys});
}

/// @nodoc
class _$ApiKeyConfigCopyWithImpl<$Res, $Val extends ApiKeyConfig>
    implements $ApiKeyConfigCopyWith<$Res> {
  _$ApiKeyConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? apiKeys = null,
  }) {
    return _then(_value.copyWith(
      apiKeys: null == apiKeys
          ? _value.apiKeys
          : apiKeys // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_ApiKeyConfigCopyWith<$Res>
    implements $ApiKeyConfigCopyWith<$Res> {
  factory _$$_ApiKeyConfigCopyWith(
          _$_ApiKeyConfig value, $Res Function(_$_ApiKeyConfig) then) =
      __$$_ApiKeyConfigCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Map<String, String> apiKeys});
}

/// @nodoc
class __$$_ApiKeyConfigCopyWithImpl<$Res>
    extends _$ApiKeyConfigCopyWithImpl<$Res, _$_ApiKeyConfig>
    implements _$$_ApiKeyConfigCopyWith<$Res> {
  __$$_ApiKeyConfigCopyWithImpl(
      _$_ApiKeyConfig _value, $Res Function(_$_ApiKeyConfig) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? apiKeys = null,
  }) {
    return _then(_$_ApiKeyConfig(
      null == apiKeys
          ? _value._apiKeys
          : apiKeys // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_ApiKeyConfig implements _ApiKeyConfig {
  const _$_ApiKeyConfig(final Map<String, String> apiKeys) : _apiKeys = apiKeys;

  factory _$_ApiKeyConfig.fromJson(Map<String, dynamic> json) =>
      _$$_ApiKeyConfigFromJson(json);

  final Map<String, String> _apiKeys;
  @override
  Map<String, String> get apiKeys {
    if (_apiKeys is EqualUnmodifiableMapView) return _apiKeys;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_apiKeys);
  }

  @override
  String toString() {
    return 'ApiKeyConfig(apiKeys: $apiKeys)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_ApiKeyConfig &&
            const DeepCollectionEquality().equals(other._apiKeys, _apiKeys));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_apiKeys));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_ApiKeyConfigCopyWith<_$_ApiKeyConfig> get copyWith =>
      __$$_ApiKeyConfigCopyWithImpl<_$_ApiKeyConfig>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_ApiKeyConfigToJson(
      this,
    );
  }
}

abstract class _ApiKeyConfig implements ApiKeyConfig {
  const factory _ApiKeyConfig(final Map<String, String> apiKeys) =
      _$_ApiKeyConfig;

  factory _ApiKeyConfig.fromJson(Map<String, dynamic> json) =
      _$_ApiKeyConfig.fromJson;

  @override
  Map<String, String> get apiKeys;
  @override
  @JsonKey(ignore: true)
  _$$_ApiKeyConfigCopyWith<_$_ApiKeyConfig> get copyWith =>
      throw _privateConstructorUsedError;
}
