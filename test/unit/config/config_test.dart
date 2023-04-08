// ignore_for_file: discarded_futures

import 'dart:convert';
import 'dart:io';

import 'package:dynssh/src/cli/options.dart';
import 'package:dynssh/src/config/config.dart';
import 'package:dynssh/src/models/api_key_config.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

void main() {
  group('$Config', () {
    final testHost = InternetAddress('127.0.0.1');
    const testPort = 8080;

    late Directory testDir;
    late Options testOptions;
    late Config sut;

    setUp(() async {
      testDir = await Directory.systemTemp.createTemp();

      testOptions = Options(
        host: testHost.address,
        port: testPort,
        apiKeyPath: '${testDir.path}/apiKeyPath',
        sshDirectory: '${testDir.path}/sshDirectory',
        logLevel: Level.INFO,
      );

      sut = Config()..initialize(testOptions);
    });

    tearDown(() async {
      await testDir.delete(recursive: true);
    });

    test('host returns options host', () {
      expect(sut.host, testHost);
    });

    test('port returns options port', () {
      expect(sut.port, testPort);
    });

    test('sshFile returns file within the ssh directory', () {
      const testFileName = 'test-file';

      final result = sut.sshFile(testFileName);

      expect(result.path, '${testDir.path}/sshDirectory/$testFileName');
    });

    group('findApiKey', () {
      const testHostName = 'test-host';
      const testApiKey = 'test-api-key';

      test('returns null if file does not exist', () {
        expect(sut.findApiKey(testHostName), completion(isNull));
      });

      test('returns null if file does not contain host', () async {
        await File(testOptions.apiKeyPath).writeAsString(
          json.encode(
            const ApiKeyConfig({
              'other-host-name': testApiKey,
            }),
          ),
        );

        expect(sut.findApiKey(testHostName), completion(isNull));
      });

      test('returns key if file does contain host', () async {
        await File(testOptions.apiKeyPath).writeAsString(
          json.encode(
            const ApiKeyConfig({
              testHostName: testApiKey,
            }),
          ),
        );

        expect(sut.findApiKey(testHostName), completion(testApiKey));
      });

      test('throws exception if file content is not valid', () async {
        await File(testOptions.apiKeyPath).writeAsString('invalid content');

        expect(
          sut.findApiKey(testHostName),
          throwsException,
        );
      });
    });
  });
}
