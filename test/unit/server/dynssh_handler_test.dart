// ignore_for_file: unnecessary_lambdas

import 'dart:io';

import 'package:dart_test_tools/test.dart';
import 'package:dynssh/src/config/config.dart';
import 'package:dynssh/src/dynssh/dynssh_controller.dart';
import 'package:dynssh/src/dynssh/return_code.dart';
import 'package:dynssh/src/models/host_update.dart';
import 'package:dynssh/src/server/dynssh_handler.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockConfig extends Mock implements Config {}

class MockDynsshController extends Mock implements DynsshController {}

class MockHttpResponse extends Mock implements HttpResponse {}

class FakeHttpHeaders extends Fake implements HttpHeaders {
  final Map<String, String> headers;

  FakeHttpHeaders(this.headers);

  @override
  String? value(String header) => headers[header];
}

class FakeHttpRequest extends Fake implements HttpRequest {
  @override
  final String method;
  @override
  final Uri uri;
  @override
  final HttpHeaders headers;
  @override
  final HttpResponse response;

  FakeHttpRequest(this.method, this.uri, this.headers, this.response);
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const HostUpdate(hostname: 'hostname', ipAddress: 'ipAddress'),
    );
  });

  group('$DynsshHandler', () {
    final mockConfig = MockConfig();
    final mockDynsshController = MockDynsshController();
    final mockHttpResponse = MockHttpResponse();

    late DynsshHandler sut;

    setUp(() async {
      reset(mockConfig);
      reset(mockDynsshController);
      reset(mockHttpResponse);

      when(() => mockConfig.findApiKey(any())).thenReturnAsync(null);
      when(() => mockHttpResponse.close()).thenReturnAsync(null);

      sut = DynsshHandler(mockConfig, mockDynsshController);
    });

    testData<(String, bool)>(
      'canHandle only allows specific path',
      const [
        ('/', false),
        ('/stuff', false),
        ('/dynssh', false),
        ('/dynssh/stuff', false),
        ('/dynssh/update', true),
        ('/dynssh/update/stuff', false),
      ],
      (fixture) {
        final testUrl = Uri.https('test.de', fixture.$1);
        expect(DynsshHandler.canHandle(testUrl), fixture.$2);
      },
    );

    group('call', () {
      const testHostname = 'test.example.com';
      const testMissingHostname = 'missing.example.com';
      const testInvalidHostname = 'invalid.example.com';
      const testApiKey = 'test-api-key';
      const testAuthHeader = 'Basic dGVzdC5leGFtcGxlLmNvbTp0ZXN0LWFwaS1rZXk=';
      const testMyIP = '12.23.34.45';

      testData<(String, int)>(
        'disallows all methods except GET and POST',
        const [
          ('GET', HttpStatus.unauthorized),
          ('PUT', HttpStatus.methodNotAllowed),
          ('DELETE', HttpStatus.methodNotAllowed),
          ('PATCH', HttpStatus.methodNotAllowed),
          ('HEAD', HttpStatus.methodNotAllowed),
          ('POST', HttpStatus.unauthorized),
        ],
        (fixture) async {
          final request = FakeHttpRequest(
            fixture.$1,
            Uri.https('', '/dynssh/update'),
            FakeHttpHeaders(const {}),
            mockHttpResponse,
          );

          final result = await sut(request);

          expect(result, isTrue);

          verifyInOrder([
            () => mockHttpResponse.statusCode = fixture.$2,
            () => mockHttpResponse.close(),
          ]);
        },
      );

      testData<(String?, String?, int, ReturnCode)>(
        'rejects requests with invalid API-credentials',
        const [
          (null, null, HttpStatus.unauthorized, ReturnCode.badAuth),
          (testHostname, null, HttpStatus.unauthorized, ReturnCode.badAuth),
          (null, testAuthHeader, HttpStatus.unauthorized, ReturnCode.badAuth),
          (
            testHostname,
            'invalid-auth-header',
            HttpStatus.unauthorized,
            ReturnCode.badAuth
          ),
          (
            testMissingHostname,
            testAuthHeader,
            HttpStatus.unauthorized,
            ReturnCode.badAuth,
          ),
          (
            testInvalidHostname,
            testAuthHeader,
            HttpStatus.unauthorized,
            ReturnCode.badAuth,
          ),
          (
            testHostname,
            testAuthHeader,
            HttpStatus.badRequest,
            ReturnCode.notFqdn,
          ),
        ],
        (fixture) async {
          when(() => mockConfig.findApiKey(testHostname))
              .thenReturnAsync(testApiKey);

          final request = FakeHttpRequest(
            'GET',
            Uri.https(
              '',
              '/dynssh/update',
              <String, String>{
                if (fixture.$1 != null) 'hostname': fixture.$1!,
              },
            ),
            FakeHttpHeaders({
              if (fixture.$2 != null)
                HttpHeaders.authorizationHeader: fixture.$2!,
            }),
            mockHttpResponse,
          );

          final result = await sut(request);

          expect(result, isTrue);

          verifyInOrder([
            if (fixture.$1 != null) () => mockConfig.findApiKey(fixture.$1!),
            () => mockHttpResponse.statusCode = fixture.$3,
            () => mockHttpResponse.writeln(fixture.$4.raw),
            () => mockHttpResponse.close(),
          ]);
          if (fixture.$1 == null) {
            verifyNever(() => mockConfig.findApiKey(any()));
          }
        },
      );

      testData<(String?, HostUpdate?, int, ReturnCode)>(
        'runs host update with given parameters, if valid',
        const [
          (
            null,
            null,
            HttpStatus.badRequest,
            ReturnCode.notFqdn,
          ),
          (
            testMyIP,
            HostUpdate(hostname: testHostname, ipAddress: testMyIP),
            HttpStatus.internalServerError,
            ReturnCode.dnsErr,
          ),
        ],
        (fixture) async {
          when(() => mockConfig.findApiKey(testHostname))
              .thenReturnAsync(testApiKey);
          when(() => mockDynsshController.updateHost(any()))
              .thenReturnAsync(ReturnCode.dnsErr);

          final request = FakeHttpRequest(
            'GET',
            Uri.https(
              '',
              '/dynssh/update',
              <String, String>{
                'hostname': testHostname,
                if (fixture.$1 != null) 'myip': fixture.$1!,
              },
            ),
            FakeHttpHeaders({
              HttpHeaders.authorizationHeader: testAuthHeader,
            }),
            mockHttpResponse,
          );

          final result = await sut(request);

          expect(result, isTrue);

          verifyInOrder([
            () => mockConfig.findApiKey(testHostname),
            if (fixture.$2 != null)
              () => mockDynsshController.updateHost(fixture.$2!),
            () => mockHttpResponse.statusCode = fixture.$3,
            () => mockHttpResponse.writeln(fixture.$4.raw),
            () => mockHttpResponse.close(),
          ]);
          if (fixture.$1 == null) {
            verifyNever(() => mockDynsshController.updateHost(any()));
          }
        },
      );

      testData<(ReturnCode, int)>(
        'sets result status based on host update result',
        const [
          (ReturnCode.good, HttpStatus.ok),
          (ReturnCode.noChg, HttpStatus.ok),
          (ReturnCode.badAuth, HttpStatus.unauthorized),
          (ReturnCode.notFqdn, HttpStatus.badRequest),
          (ReturnCode.noHost, HttpStatus.badRequest),
          (ReturnCode.abuse, HttpStatus.badRequest),
          (ReturnCode.badAgent, HttpStatus.badRequest),
          (ReturnCode.dnsErr, HttpStatus.internalServerError),
        ],
        (fixture) async {
          when(() => mockConfig.findApiKey(testHostname))
              .thenReturnAsync(testApiKey);
          when(() => mockDynsshController.updateHost(any()))
              .thenReturnAsync(fixture.$1);

          final request = FakeHttpRequest(
            'GET',
            Uri.https(
              '',
              '/dynssh/update',
              <String, String>{
                'hostname': testHostname,
                'myip': testMyIP,
              },
            ),
            FakeHttpHeaders({
              HttpHeaders.authorizationHeader: testAuthHeader,
            }),
            mockHttpResponse,
          );

          final result = await sut(request);

          expect(result, isTrue);

          verifyInOrder([
            () => mockConfig.findApiKey(testHostname),
            () => mockDynsshController.updateHost(
                  const HostUpdate(
                    hostname: testHostname,
                    ipAddress: testMyIP,
                  ),
                ),
            () => mockHttpResponse.statusCode = fixture.$2,
            () => mockHttpResponse.writeln(fixture.$1.raw),
            () => mockHttpResponse.close(),
          ]);
        },
      );
    });
  });
}
