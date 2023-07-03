import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';
import 'package:synchronized/synchronized.dart';

import '../models/host_update.dart';
import '../ssh/config/ssh_config_host.dart';
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
  final SshKnownHostsParser _sshKnownHostsParser;
  final SshKeyscan _sshKeyscan;
  final _logger = Logger('$DynsshController');

  final _lock = Lock();

  DynsshController(
    this._sshConfigParser,
    this._sshKnownHostsParser,
    this._sshKeyscan,
  );

  Future<bool> updateHost(HostUpdate hostUpdate) =>
      _lock.synchronized(() async {
        _logger.info('Applying host update $hostUpdate...');

        final sshConfig = await _sshConfigParser.parse();
        final hostConfig = sshConfig.findHost(hostUpdate.hostname);
        if (hostConfig == null) {
          _logger.warning(
            'Unable to find configuration for host: ${hostUpdate.hostname}',
          );
          return false;
        }

        final (hostAddress, hostPort) = _getHostRecord(hostConfig, hostUpdate);
        final hostLog = _hostLog(hostAddress, hostPort);

        final knownHostKeys = await _sshKnownHostsParser.getHostKeys(
          hostAddress,
          hostPort,
        );
        if (knownHostKeys.isEmpty) {
          _logger.warning(
            'No known host keys saved for $hostLog. '
            'Unable to verify host update.',
          );
          return false;
        }
        _logHostKeys(hostLog, knownHostKeys);

        final newHostKeys = await _sshKeyscan.scanHost(
          hostUpdate.ipAddress,
          hostPort,
        );
        _logHostKeys(_hostLog(hostUpdate.ipAddress, hostPort), newHostKeys);

        final keysAreEqual = const MapEquality<String, String>().equals(
          newHostKeys,
          knownHostKeys,
        );
        if (!keysAreEqual) {
          _logger.severe(
            'Malicious host update detected! Public keys of '
            '${hostUpdate.ipAddress} do not match the saved keys of $hostLog! '
            'Rejecting update!',
          );
          return false;
        }

        hostConfig[_hostNameKey] = [hostUpdate.ipAddress];
        await _sshConfigParser.update(sshConfig);
        await _sshKnownHostsParser.replaceHost(
          oldHost: hostAddress,
          newHost: hostUpdate.ipAddress,
          oldPort: hostPort,
          newPort: hostPort,
        );

        _logger.info('Update successful!');
        return true;
      });

  (String, int?) _getHostRecord(
    SshConfigHost hostConfig,
    HostUpdate hostUpdate,
  ) {
    final hostAddress =
        hostConfig[_hostNameKey]?.single ?? hostConfig.patterns.first;
    final hostPort =
        int.tryParse(hostConfig[_portKey]?.single ?? '', radix: 10);
    return (hostAddress, hostPort);
  }

  String _hostLog(String hostAddress, int? hostPort) {
    final hostLog =
        hostPort != null ? '$hostAddress (port: $hostPort)' : hostAddress;
    return hostLog;
  }

  void _logHostKeys(String hostLog, Map<String, String> knownHostKeys) {
    _logger.fine('Detected known host keys for $hostLog as:');
    for (final entry in knownHostKeys.entries) {
      _logger.fine('  ${entry.key}: ${entry.value}');
    }
  }
}
