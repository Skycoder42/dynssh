import 'package:riverpod/riverpod.dart';

import 'ssh_file_resolver.dart';

// coverage:ignore-start
final sshKnownHostsUpdaterProvider = Provider(
  (ref) => SshKnownHostsUpdater(
    ref.watch(sshFileResolverProvider),
  ),
);
// coverage:ignore-end

class SshKnownHostsUpdater {
  final SshFileResolver _sshFileResolver;

  SshKnownHostsUpdater(this._sshFileResolver);

  Future<void> replaceHost({
    required String oldHost,
    int? oldPort,
    required String newHost,
    int? newPort,
  }) async {
    final knownHostsFile = _sshFileResolver.getSshFile('known_hosts');
    if (!knownHostsFile.existsSync()) {
      // nothing to be updated
      return;
    }

    final escapedOldOrigin = RegExp.escape(_origin(oldHost, oldPort));
    final newOrigin = _origin(newHost, newPort);

    final knownHostsContent = await knownHostsFile.readAsString();
    final updatedContent = knownHostsContent.replaceAll(
      RegExp('^$escapedOldOrigin ', multiLine: true),
      '$newOrigin ',
    );
    await knownHostsFile.writeAsString(updatedContent);
  }

  String _origin(String host, int? port) =>
      port != null ? '[$host]:$port' : host;
}
