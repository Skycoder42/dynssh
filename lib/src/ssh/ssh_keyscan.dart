import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../adapter/process_adapter.dart';
import 'ssh_known_hosts_parser.dart';

part 'ssh_keyscan.g.dart';

// coverage:ignore-start
@riverpod
SshKeyscan sshKeyscan(Ref ref) => SshKeyscan(
  ref.watch(processAdapterProvider),
  ref.watch(sshKnownHostsParserProvider),
);
// coverage:ignore-end

class SshKeyscan {
  final ProcessAdapter _processAdapter;
  final SshKnownHostsParser _sshKnownHostsParser;

  SshKeyscan(this._processAdapter, this._sshKnownHostsParser);

  Future<Map<String, String>> scanHost(String host, [int? port]) async {
    final keyscanLines = _processAdapter.streamLines('ssh-keyscan', [
      if (port != null) ...['-p', port.toString()],
      host,
    ]);
    return await _sshKnownHostsParser.getHostKeysFromLines(
      keyscanLines,
      host,
      port,
    );
  }
}
