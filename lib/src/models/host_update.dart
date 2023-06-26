// coverage:ignore-file

import 'package:freezed_annotation/freezed_annotation.dart';

part 'host_update.freezed.dart';

@freezed
class HostUpdate with _$HostUpdate {
  const factory HostUpdate({
    required String hostname,
    required String ipAddress,
  }) = _HostUpdate;
}
