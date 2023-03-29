import 'package:riverpod/riverpod.dart';

import '../adapter/process_adapter.dart';
import 'ssh_known_hosts_parser.dart';

// coverage:ignore-start
final sshKeyscanProvider = Provider(
  (ref) => SshKeyscan(
    ref.watch(processAdapterProvider),
    ref.watch(sshKnownHostsParserProvider),
  ),
);
// coverage:ignore-end

class SshKeyscan {
  final ProcessAdapter _processAdapter;
  final SshKnownHostsParser _sshKnownHostsParser;

  SshKeyscan(
    this._processAdapter,
    this._sshKnownHostsParser,
  );

  Future<Map<String, String>> scanHost(String host, [int? port]) async {
    final keyscanLines = _processAdapter.streamLines(
      'ssh-keyscan',
      [
        host,
        if (port != null) ...['-p', port.toString()],
      ],
    );
    return _sshKnownHostsParser.getHostKeysFromLines(keyscanLines, host, port);
  }
}
