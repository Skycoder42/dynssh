import 'dart:convert';
import 'dart:io';
import 'package:riverpod/riverpod.dart';

import 'ssh_file_resolver.dart';

// coverage:ignore-start
final sshKnownHostsParserProvider = Provider(
  (ref) => SshKnownHostsParser(
    ref.watch(sshFileResolverProvider),
  ),
);
// coverage:ignore-end

class SshKnownHostsParser {
  final SshFileResolver _sshFileResolver;

  SshKnownHostsParser(this._sshFileResolver);

  Future<Map<String, String>> getHostKeys(String host, [int? port]) async {
    final knownHostsFile = _knownHostsFile();
    if (!knownHostsFile.existsSync()) {
      return const {};
    }

    final hostLines = knownHostsFile
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    return getHostKeysFromLines(hostLines, host, port);
  }

  Future<Map<String, String>> getHostKeysFromLines(
    Stream<String> hostLines,
    String host, [
    int? port,
  ]) async {
    final origin = _origin(host, port);
    final hostMap = <String, String>{};
    await for (final line in hostLines) {
      if (line.startsWith('#')) {
        continue;
      }

      final lineParts = line.split(' ');
      if (lineParts.length < 3) {
        continue;
      }
      if (lineParts[0] != origin) {
        continue;
      }

      hostMap[lineParts[2]] = lineParts.skip(2).join(' ');
    }

    return hostMap;
  }

  Future<void> replaceHost({
    required String oldHost,
    int? oldPort,
    required String newHost,
    int? newPort,
  }) async {
    final knownHostsFile = _knownHostsFile();
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

  File _knownHostsFile() => _sshFileResolver.getSshFile('known_hosts');

  String _origin(String host, int? port) =>
      port != null ? '[$host]:$port' : host;
}
