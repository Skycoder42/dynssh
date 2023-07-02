// ignore_for_file: avoid_print

@TestOn('linux')
library dynssh_docker_test;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dynssh/src/cli/dynssh/options.dart';
import 'package:test/test.dart';

import 'dynssh_test_case.dart';

void main() => _DynsshDockerTestCase().call();

final class _DynsshDockerTestCase extends DynsshTestCase {
  late String _containerName;

  @override
  Future<int> runDynssh(Options testOptions) async {
    final port = testOptions.port == 0 ? 8042 : testOptions.port;

    _containerName = 'dynssh_docker_test_${Random.secure().nextInt(100000)}';
    final dockerProc = await Process.start(
      'docker',
      [
        'run',
        '--rm',
        '--name',
        _containerName,
        '--add-host=host.docker.internal:host-gateway',
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
    );

    addTearDown(() async {
      dockerProc.kill();
      await dockerProc.exitCode;
    });

    dockerProc.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(print);
    dockerProc.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(print);

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
        await Future.delayed(const Duration(seconds: 1));
        continue;
      }
    }

    fail('Failed to connect to ${testOptions.host}:$port');
  }

  @override
  String getServerName() => 'host.docker.internal';

  @override
  Future<String> getServerIp() async {
    final result = await Process.run('docker', [
      'exec',
      _containerName,
      'getent',
      'hosts',
      getServerName(),
    ]);
    expect(
      result.exitCode,
      0,
      reason: result.stderr.toString(),
    );

    final lines = const LineSplitter().convert(result.stdout as String);
    expect(
      lines,
      hasLength(greaterThanOrEqualTo(1)),
      reason: result.stderr.toString(),
    );

    return lines.first.split(' ').first;
  }
}
