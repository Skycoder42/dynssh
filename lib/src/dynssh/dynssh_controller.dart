import 'package:collection/collection.dart';
import 'package:riverpod/riverpod.dart';

import '../models/host_update.dart';
import '../ssh/ssh_config_parser.dart';
import '../ssh/ssh_keyscan.dart';
import '../ssh/ssh_known_hosts_parser.dart';

// coverage:ignore-start
final dynsshControllerProvider = Provider(
  (ref) => DynsshController(
    ref.watch(sshConfigParserProvider),
    ref.watch(sshKnownHostsParserProvider),
    ref.watch(sshKeyscanProvider),
  ),
);
// coverage:ignore-end

class DynsshController {
  static const _hostNameKey = 'HostName';
  static const _portKey = 'Port';

  final SshConfigParser _sshConfigParser;
  final SshKnownHostsParser _knownHostsParser;
  final SshKeyscan _sshKeyscan;

  DynsshController(
    this._sshConfigParser,
    this._knownHostsParser,
    this._sshKeyscan,
  );

  Future<bool> updateHost(HostUpdate hostUpdate) async {
    final sshConfig = await _sshConfigParser.parse();
    final hostConfig = sshConfig.findHost(hostUpdate.fqdn);
    if (hostConfig == null) {
      return false;
    }
    final hostAddress =
        hostConfig[_hostNameKey]?.single ?? hostConfig.patterns.first;
    final hostPort =
        int.tryParse(hostConfig[_portKey]?.single ?? '', radix: 10);

    final knownHostKeys = await _knownHostsParser.getHostKeys(
      hostAddress,
      hostPort,
    );
    if (knownHostKeys.isEmpty) {
      return false;
    }

    final newHostKeys = await _sshKeyscan.scanHost(
      hostUpdate.ipAddress,
      hostPort,
    );

    final keysAreEqual = const MapEquality<String, String>().equals(
      newHostKeys,
      knownHostKeys,
    );
    if (!keysAreEqual) {
      return false;
    }

    hostConfig[_hostNameKey] = [hostUpdate.ipAddress];
    await _sshConfigParser.update(sshConfig);
    await _knownHostsParser.replaceHost(
      oldHost: hostAddress,
      newHost: hostUpdate.ipAddress,
      oldPort: hostPort,
      newPort: hostPort,
    );
    return true;
  }
}
