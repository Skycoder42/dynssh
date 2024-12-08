// ignore_for_file: discarded_futures

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dart_test_tools/test.dart';
import 'package:dynssh/src/config/config.dart';
import 'package:dynssh/src/server/http_server.dart';
import 'package:http/http.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';

class MockConfig extends Mock implements Config {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri());
  });

  group('$HttpServer', () {
    final mockConfig = MockConfig();

    late ProviderContainer di;
    late HttpServer sut;

    Uri testBaseUrl() => Uri(
          scheme: 'http',
          host: InternetAddress.loopbackIPv4.address,
          port: sut.port,
        );

    setUp(() {
      reset(mockConfig);

      di = ProviderContainer();

      when(() => mockConfig.host).thenReturn(InternetAddress.loopbackIPv4);
      when(() => mockConfig.port).thenReturn(0);

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
          get(testBaseUrl()),
          completion(
            isA<Response>().having(
              (m) => m.statusCode,
              'statusCode',
              HttpStatus.notFound,
            ),
          ),
        );
      });

      test(
        'starts http server on specific port',
        retry: 5,
        () async {
          final testPort = 1024 + Random.secure().nextInt(65535 - 1024);
          when(() => mockConfig.port).thenReturn(testPort);

          await sut.start(di);

          expect(sut.port, testPort);
          expect(
            get(testBaseUrl()),
            completion(
              isA<Response>().having(
                (m) => m.statusCode,
                'statusCode',
                HttpStatus.notFound,
              ),
            ),
          );
        },
      );

      test(
        'starts http server on specific IP',
        onPlatform: const {
          'mac-os': Skip(
            'User other IPs then 127.0.0.1 is not supported on macos.',
          ),
        },
        () async {
          when(() => mockConfig.host).thenReturn(InternetAddress('127.1.2.3'));

          await sut.start(di);

          expect(
            get(testBaseUrl()),
            throwsA(isA<SocketException>()),
          );
          expect(
            get(testBaseUrl().replace(host: '127.1.2.3')),
            completion(
              isA<Response>().having(
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

          expect(
            get(testUrl),
            throwsA(isA<SocketException>()),
          );
        },
      );
    });

    group('handleRequest', () {
      const handler1Path = '/handle/1';
      const handler2Path = '/handle/2';

      setUp(() async {
        when(() => mockHandler1.canHandle(any())).thenAnswer((i) {
          final url = i.positionalArguments[0] as Uri;
          return url.path == handler1Path;
        });
        when(() => mockHandler2.canHandle(any())).thenAnswer((i) {
          final url = i.positionalArguments[0] as Uri;
          return url.path == handler2Path;
        });

        when(() => mockHandler1.call(any())).thenReturnAsync(true);
        when(() => mockHandler2.call(any())).thenReturnAsync(true);

        await sut.start(di);
      });

      tearDown(() {
        verifyNoMoreInteractions(mockHandler1);
        verifyNoMoreInteractions(mockHandler2);
      });

      test('returns 404 if no handler can handle the request', () async {
        await expectLater(
          get(testBaseUrl()),
          completion(
            isA<Response>().having(
              (m) => m.statusCode,
              'statusCode',
              HttpStatus.notFound,
            ),
          ),
        );

        verifyInOrder([
          () => mockHandler1.canHandle(Uri(path: '/')),
          () => mockHandler2.canHandle(Uri(path: '/')),
        ]);
      });

      test('returns 404 if no handler accepted the request', () async {
        when(() => mockHandler1.canHandle(any())).thenReturn(true);
        when(() => mockHandler2.canHandle(any())).thenReturn(true);

        when(() => mockHandler1.call(any())).thenReturnAsync(false);
        when(() => mockHandler2.call(any())).thenReturnAsync(false);

        await expectLater(
          get(testBaseUrl()),
          completion(
            isA<Response>().having(
              (m) => m.statusCode,
              'statusCode',
              HttpStatus.notFound,
            ),
          ),
        );

        verifyInOrder([
          () => mockHandler1.canHandle(Uri(path: '/')),
          () => mockHandler1.call(any()),
          () => mockHandler2.canHandle(Uri(path: '/')),
          () => mockHandler2.call(any()),
        ]);
      });

      test('only applies first matching handler', () async {
        when(() => mockHandler1.canHandle(any())).thenReturn(true);
        when(() => mockHandler2.canHandle(any())).thenReturn(true);

        when(() => mockHandler2.call(any())).thenReturnAsync(true);
        mockResponse(mockHandler1, (request, response) async {
          response.statusCode = HttpStatus.ok;
          await response.close();
          return true;
        });

        await expectLater(
          get(testBaseUrl()),
          completion(
            isA<Response>().having(
              (m) => m.statusCode,
              'statusCode',
              HttpStatus.ok,
            ),
          ),
        );

        verifyInOrder([
          () => mockHandler1.canHandle(Uri(path: '/')),
          () => mockHandler1.call(any()),
        ]);
      });

      test('returns 500 if handler throws', () async {
        when(() => mockHandler1.canHandle(any())).thenReturn(true);
        when(() => mockHandler1.call(any())).thenThrow(Exception('error'));

        await expectLater(
          get(testBaseUrl()),
          completion(
            isA<Response>().having(
              (m) => m.statusCode,
              'statusCode',
              HttpStatus.internalServerError,
            ),
          ),
        );

        verifyInOrder([
          () => mockHandler1.canHandle(Uri(path: '/')),
          () => mockHandler1.call(any()),
        ]);
      });
    });
  });
}

void mockResponse(
  MockHttpHandler handler,
  FutureOr<bool> Function(HttpRequest request, HttpResponse response) handle,
) =>
    when(() => handler.call(any())).thenAnswer((i) async {
      final request = i.positionalArguments.first as HttpRequest;
      return await handle(request, request.response);
    });
