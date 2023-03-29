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
  final SshConfigParser _sshConfigParser;
  final SshKnownHostsParser _knownHostsParser;
  final SshKeyscan _sshKeyscan;

  DynsshController(
    this._sshConfigParser,
    this._knownHostsParser,
    this._sshKeyscan,
  );

  Future<bool> updateHost(HostUpdate hostUpdate) async => false;
}
