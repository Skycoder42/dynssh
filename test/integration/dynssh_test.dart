import 'dart:io';

import 'package:dynssh/src/cli/options.dart';
import 'package:dynssh/src/config/config.dart';
import 'package:dynssh/src/server/dynssh_handler.dart';
import 'package:dynssh/src/server/http_server.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() async {
    Logger.root
      ..level = Level.ALL
      ..onRecord.listen(_printLogRecord);
  });

  late Directory testDir;
  late Options testOptions;
  late int port;

  setUp(() async {
    testDir = await Directory.systemTemp.createTemp();

    testOptions = Options(
      host: InternetAddress.loopbackIPv4.address,
      port: 0,
      apiKeyPath: testDir.uri.resolve('api-keys.json').toFilePath(),
      sshDirectory: testDir.uri.resolve('ssh').toFilePath(),
      logLevel: Level.ALL,
    );

    port = await _runDynssh(testOptions);
  });

  Future<int> get({String? path, bool post = true}) async {
    final url = Uri(
      scheme: 'http',
      host: InternetAddress.loopbackIPv4.address,
      port: port,
      path: path ?? '/dynssh/update',
    );

    final response = post ? await http.post(url) : await http.get(url);
    return response.statusCode;
  }

  test('can start server', () async {
    expect(port, isNot(0));
  });

  test('rejects unknown paths with 404', () async {
    expect(get(path: '/invalid/service'), completion(HttpStatus.notFound));
  });

  test('rejects correct path with invalid method with 405', () async {
    expect(get(post: false), completion(HttpStatus.methodNotAllowed));
  });

  test('rejects correct path with missing credentials with 401', () async {
    expect(get(), completion(HttpStatus.unauthorized));
  });
}

Future<int> _runDynssh(Options testOptions) async {
  final di = ProviderContainer();
  addTearDown(di.dispose);

  di.read(configProvider).initialize(testOptions);

  final server = di.read(httpServerProvider)
    ..registerHandler(dynsshHandlerProvider);
  await server.start(di);
  addTearDown(server.stop);

  return server.port;
}

void _printLogRecord(LogRecord logRecord) =>
    // ignore: avoid_print
    print('${logRecord.time.toIso8601String()} $logRecord');
