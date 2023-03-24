import 'package:freezed_annotation/freezed_annotation.dart';

part 'host_update.freezed.dart';

@freezed
class HostUpdate with _$HostUpdate {
  const factory HostUpdate.ipv4({
    required String fqdn,
    required String ipAddress,
  }) = _HostUpdateIpv4;

  const factory HostUpdate.ipv6({
    required String fqdn,
    required String ipAddress,
  }) = _HostUpdateIpv6;
}
