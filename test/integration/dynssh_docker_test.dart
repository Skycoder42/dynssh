@TestOn('linux')
library dynssh_docker_test;

import 'dart:io';

import 'package:dynssh/src/cli/options.dart';
import 'package:test/test.dart';

import 'dynssh_test_case.dart';

void main() => _DynsshDockerTestCase().call();

final class _DynsshDockerTestCase extends DynsshTestCase {
  @override
  Future<int> runDynssh(Options testOptions) async {
    final port = testOptions.port == 0 ? 8042 : testOptions.port;

    final dockerProc = await Process.start(
      'docker',
      [
        'run',
        '--rm',
        '-v',
        '${testOptions.sshDirectory}:/etc/ssh',
        '-v',
        '${testOptions.apiKeyPath}:/etc/dynssh/api-keys.json:ro',
        '-p',
        '${testOptions.host}:$port:80',
        'local/dynssh',
        '-l',
        testOptions.logLevel.name.toLowerCase(),
      ],
      mode: ProcessStartMode.inheritStdio,
    );

    addTearDown(() async {
      dockerProc.kill();
      await dockerProc.exitCode;
    });

    for (var i = 0; i < 60; ++i) {
      try {
        final socket = await Socket.connect(
          testOptions.host,
          port,
          timeout: const Duration(seconds: 1),
        );
        await socket.close();

        return port;

        // ignore: avoid_catches_without_on_clauses
      } catch (e) {
        continue;
      }
    }

    fail('Failed to connect to ${testOptions.host}:$port');
  }

  @override
  String getServerName() => 'host.docker.internal';

  @override
  Future<InternetAddress> getServerIp() =>
      InternetAddress.lookup(getServerName()).then((a) => a.first);
}
