// coverage:ignore-file

import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_key_config.freezed.dart';
part 'api_key_config.g.dart';

@freezed
class ApiKeyConfig with _$ApiKeyConfig {
  const factory ApiKeyConfig(Map<String, String> apiKeys) = _ApiKeyConfig;

  factory ApiKeyConfig.fromJson(Map<String, dynamic> json) =>
      _$ApiKeyConfigFromJson(json);
}
