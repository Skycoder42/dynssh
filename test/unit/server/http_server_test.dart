import 'dart:io';
import 'dart:math';

import 'package:dart_test_tools/test.dart';
import 'package:dynssh/src/config/config.dart';
import 'package:dynssh/src/server/dynssh_api.dart';
import 'package:dynssh/src/server/http_server.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

class MockConfig extends Mock implements Config {}

class MockDynsshApi extends Mock implements DynsshApiMirror {}

class FakeRequest extends Fake implements Request {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri());
    registerFallbackValue(FakeRequest());
  });

  group('$HttpServer', () {
    final mockConfig = MockConfig();
    final mockDynsshApi = MockDynsshApi();

    late ProviderContainer di;
    late HttpServer sut;

    Uri testBaseUrl() => Uri(
      scheme: 'http',
      host: InternetAddress.loopbackIPv4.address,
      port: sut.port,
    );

    setUp(() {
      reset(mockConfig);
      reset(mockDynsshApi);

      di = ProviderContainer(
        overrides: [
          configProvider.overrideWithValue(mockConfig),
          dynsshApiProvider.overrideWithValue(mockDynsshApi),
        ],
      );

      when(() => mockConfig.host).thenReturn(InternetAddress.loopbackIPv4);
      when(() => mockConfig.port).thenReturn(0);

      when(() => mockDynsshApi(any())).thenReturn(Response.notFound(null));

      sut = HttpServer(mockConfig);
    });

    tearDown(() async {
      await sut.stop(force: true);
      di.dispose();
    });

    group('start', () {
      test('starts http server on random port', () async {
        await sut.start(di);

        expect(
          http.get(testBaseUrl()),
          completion(
            isA<http.Response>().having(
              (m) => m.statusCode,
              'statusCode',
              HttpStatus.notFound,
            ),
          ),
        );
      });

      test('starts http server on specific port', retry: 5, () async {
        final testPort = 1024 + Random.secure().nextInt(65535 - 1024);
        when(() => mockConfig.port).thenReturn(testPort);

        await sut.start(di);

        expect(sut.port, testPort);
        expect(
          http.get(testBaseUrl()),
          completion(
            isA<http.Response>().having(
              (m) => m.statusCode,
              'statusCode',
              HttpStatus.notFound,
            ),
          ),
        );
      });

      test(
        'starts http server on specific IP',
        onPlatform: const {
          'mac-os': Skip(
            'User other IPs than 127.0.0.1 is not supported on macos.',
          ),
        },
        () async {
          when(() => mockConfig.host).thenReturn(InternetAddress('127.1.2.3'));

          await sut.start(di);

          expect(http.get(testBaseUrl()), throwsA(isA<SocketException>()));
          expect(
            http.get(testBaseUrl().replace(host: '127.1.2.3')),
            completion(
              isA<http.Response>().having(
                (m) => m.statusCode,
                'statusCode',
                HttpStatus.notFound,
              ),
            ),
          );
        },
      );
    });

    group('stop', () {
      setUp(() async {
        await sut.start(di);
      });

      testData<bool>(
        'stops the server',
        const [false, true],
        dataToString: (force) => force ? 'force' : 'normal',
        (fixture) async {
          final testUrl = testBaseUrl();

          await sut.stop(force: fixture);

          expect(http.get(testUrl), throwsA(isA<SocketException>()));
        },
      );
    });

    group('handleRequest', () {
      setUp(() async {
        await sut.start(di);
      });

      test('returns response of dynssh api', () async {
        when(() => mockDynsshApi(any())).thenReturn(Response.ok('test'));

        await expectLater(
          http.get(testBaseUrl()),
          completion(
            isA<http.Response>()
                .having((m) => m.statusCode, 'statusCode', HttpStatus.ok)
                .having((m) => m.body, 'body', 'test'),
          ),
        );

        verify(() => mockDynsshApi(any(that: isA<Request>()))).called(1);
      });
    });
  });
}
