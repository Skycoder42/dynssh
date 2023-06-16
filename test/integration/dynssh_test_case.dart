import 'dart:convert';
import 'dart:io';

import 'package:dynssh/src/cli/options.dart';
import 'package:dynssh/src/models/api_key_config.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

abstract base class DynsshTestCase {
  void call() {
    const testFqdn = 'test.dynssh.skycoder42.de';
    const testUnauthorizedFqdn = 'unauthorized.$testFqdn';
    const testForbiddenFqdn = 'forbidden.$testFqdn';
    const testApiKey =
        'j8efu893pu8fsjifskjfo983u0f09ufe0suf093uf90uwu9eusfkdsf';
    const testAuthHeader =
        // ignore: lines_longer_than_80_chars
        'Basic dGVzdC5keW5zc2guc2t5Y29kZXI0Mi5kZTpqOGVmdTg5M3B1OGZzamlmc2tqZm85ODN1MGYwOXVmZTBzdWYwOTN1ZjkwdXd1OWV1c2ZrZHNm';
    const testForbiddenAuthHeader =
        // ignore: lines_longer_than_80_chars
        'Basic Zm9yYmlkZGVuLnRlc3QuZHluc3NoLnNreWNvZGVyNDIuZGU6ajhlZnU4OTNwdThmc2ppZnNramZvOTgzdTBmMDl1ZmUwc3VmMDkzdWY5MHV3dTlldXNma2RzZg==';

    late Directory testDir;
    late Options testOptions;
    late int port;

    setUpAll(() async {
      Logger.root
        ..level = Level.ALL
        ..onRecord.listen(_printLogRecord);

      testDir = await Directory.systemTemp.createTemp();

      final apiKeyFile = File.fromUri(testDir.uri.resolve('api-keys.json'));
      await apiKeyFile.writeAsString(
        json.encode(
          const ApiKeyConfig({
            testFqdn: testApiKey,
            testUnauthorizedFqdn: 'invalid API key',
            testForbiddenFqdn: testApiKey,
          }).toJson(),
        ),
      );

      testOptions = Options(
        host: InternetAddress.loopbackIPv4.address,
        port: 0,
        apiKeyPath: apiKeyFile.path,
        sshDirectory: '${Platform.environment['HOME']}/.ssh',
        logLevel: Level.ALL,
      );

      await File('${testOptions.sshDirectory}/config.template')
          .copy('${testOptions.sshDirectory}/config');

      port = await runDynssh(testOptions);
    });

    setUp(() {
      Logger.root
        ..clearListeners()
        ..onRecord.listen(_printLogRecord);
    });

    Future<int> sendUpdateRequest({
      String? path,
      bool post = true,
      String? authHeader = testAuthHeader,
      Map<String, String>? query,
    }) async {
      final url = Uri(
        scheme: 'http',
        host: InternetAddress.loopbackIPv4.address,
        port: port,
        path: path ?? '/dynssh/update',
        queryParameters: query ??
            const <String, String>{
              'fqdn': testFqdn,
              'ipv4': '127.0.0.1',
            },
      );

      final headers = {
        if (authHeader != null) HttpHeaders.authorizationHeader: authHeader
      };

      final response = post
          ? await http.post(url, headers: headers)
          : await http.get(url, headers: headers);
      return response.statusCode;
    }

    test('can start server', () async {
      expect(port, isNot(0));
    });

    test('rejects unknown paths with 404', () async {
      expect(
        sendUpdateRequest(path: '/invalid/service'),
        completion(HttpStatus.notFound),
      );
    });

    test('rejects invalid method with 405', () async {
      expect(
        sendUpdateRequest(post: false),
        completion(HttpStatus.methodNotAllowed),
      );
    });

    test('rejects missing credentials with 401', () async {
      expect(
        sendUpdateRequest(authHeader: null),
        completion(HttpStatus.unauthorized),
      );
    });

    test('rejects missing fqdn with 401', () async {
      expect(
        sendUpdateRequest(query: const {}),
        completion(HttpStatus.unauthorized),
      );
    });

    test('rejects invalid fqdn with 401', () async {
      expect(
        sendUpdateRequest(query: const {'fqdn': 'example.com'}),
        completion(HttpStatus.unauthorized),
      );
    });

    test('rejects valid fqdn with invalid api key with 401', () async {
      expect(
        sendUpdateRequest(query: const {'fqdn': testUnauthorizedFqdn}),
        completion(HttpStatus.unauthorized),
      );
    });

    test('rejects query without ip address with 400', () async {
      expect(
        sendUpdateRequest(query: const {'fqdn': testFqdn}),
        completion(HttpStatus.badRequest),
      );
    });

    test('rejects query without both ip addresses with 400', () async {
      expect(
        sendUpdateRequest(
          query: const {
            'fqdn': testFqdn,
            'ipv4': '127.0.0.1',
            'ipv6': '::',
          },
        ),
        completion(HttpStatus.badRequest),
      );
    });

    test('rejects update with host key mismatch with 403', () async {
      expect(
        sendUpdateRequest(
          query: {
            'fqdn': testForbiddenFqdn,
            'ipv4': '127.0.0.1',
          },
          authHeader: testForbiddenAuthHeader,
        ),
        completion(HttpStatus.forbidden),
      );
    });

    test('accepts update with correct data with 202', () async {
      await expectLater(
        sendUpdateRequest(),
        completion(HttpStatus.accepted),
      );

      final sshConfig = File('${Platform.environment['HOME']}/.ssh/config');
      expect(sshConfig.existsSync(), isTrue);
      expect(
        sshConfig.readAsString(),
        completion('''
Host test.dynssh.skycoder42.de
    HostName 127.0.0.1
    User ${Platform.environment['USER']}
    IdentityFile ~/.ssh/id_ed25519

Host forbidden.test.dynssh.skycoder42.de
    HostName aur.archlinux.org
'''),
      );
    });
  }

  @visibleForOverriding
  Future<int> runDynssh(Options testOptions);

  void _printLogRecord(LogRecord logRecord) =>
      // ignore: avoid_print
      print('${logRecord.time.toIso8601String()} $logRecord');
}