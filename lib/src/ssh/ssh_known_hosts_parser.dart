import 'dart:convert';
import 'dart:io';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

import '../config/config.dart';

// coverage:ignore-start
final sshKnownHostsParserProvider = Provider(
  (ref) => SshKnownHostsParser(
    ref.watch(configProvider),
  ),
);
// coverage:ignore-end

class SshKnownHostsParser {
  final Config _config;
  final _logger = Logger('$SshKnownHostsParser');

  SshKnownHostsParser(this._config);

  Future<Map<String, String>> getHostKeys(String host, [int? port]) async {
    final knownHostsFile = _knownHostsFile();
    if (!knownHostsFile.existsSync()) {
      _logger.warning(
        'SSH known_hosts file does not exist (path: ${knownHostsFile.path})',
      );
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

      hostMap[lineParts[1]] = lineParts.skip(2).join(' ');
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
      _logger.warning(
        'SSH known_hosts file does not exist (path: ${knownHostsFile.path})',
      );
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

  File _knownHostsFile() {
    final sshKnownHostsFile = _config.sshFile('known_hosts');
    _logger
        .finer('Detected SSH known_hosts file as: ${sshKnownHostsFile.path}');
    return sshKnownHostsFile;
  }

  String _origin(String host, int? port) =>
      port != null ? '[$host]:$port' : host;
}
