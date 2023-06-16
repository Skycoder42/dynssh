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
        testOptions.logLevel.name,
      ],
      mode: ProcessStartMode.inheritStdio,
    );

    addTearDown(() async {
      dockerProc.kill();
      await dockerProc.exitCode;
    });

    return port;
  }
}
