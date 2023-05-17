// ignore_for_file: unnecessary_lambdas

import 'dart:io';

import 'package:dart_test_tools/test.dart';
import 'package:dynssh/src/config/config.dart';
import 'package:dynssh/src/dynssh/dynssh_controller.dart';
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
      const HostUpdate.ipv4(fqdn: 'fqdn', ipAddress: 'ipAddress'),
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
      const testFqdn = 'test.example.com';
      const testMissingFqdn = 'missing.example.com';
      const testInvalidFqdn = 'invalid.example.com';
      const testApiKey = 'test-api-key';
      const testAuthHeader = 'Basic dGVzdC5leGFtcGxlLmNvbTp0ZXN0LWFwaS1rZXk=';
      const testIpv4 = '12.23.34.45';
      const testIpv6 = '::';

      testData<(String, int)>(
        'disallows all methods except POST',
        const [
          ('GET', HttpStatus.methodNotAllowed),
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

      testData<(String?, String?, int)>(
        'rejects requests with invalid API-credentials',
        const [
          (null, null, HttpStatus.unauthorized),
          (testFqdn, null, HttpStatus.unauthorized),
          (null, testAuthHeader, HttpStatus.unauthorized),
          (testFqdn, 'invalid-auth-header', HttpStatus.unauthorized),
          (
            testMissingFqdn,
            testAuthHeader,
            HttpStatus.unauthorized,
          ),
          (
            testInvalidFqdn,
            testAuthHeader,
            HttpStatus.unauthorized,
          ),
          (testFqdn, testAuthHeader, HttpStatus.badRequest),
        ],
        (fixture) async {
          when(() => mockConfig.findApiKey(testFqdn))
              .thenReturnAsync(testApiKey);

          final request = FakeHttpRequest(
            'POST',
            Uri.https(
              '',
              '/dynssh/update',
              <String, String>{
                if (fixture.$1 != null) 'fqdn': fixture.$1!,
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
            () => mockHttpResponse.close(),
          ]);
          if (fixture.$1 == null) {
            verifyNever(() => mockConfig.findApiKey(any()));
          }
        },
      );

      testData<(String?, String?, HostUpdate?, int)>(
        'runs host update with given parameters, if valid',
        const [
          (null, null, null, HttpStatus.badRequest),
          (
            null,
            testIpv6,
            HostUpdate.ipv6(fqdn: testFqdn, ipAddress: testIpv6),
            HttpStatus.forbidden,
          ),
          (
            testIpv4,
            null,
            HostUpdate.ipv4(fqdn: testFqdn, ipAddress: testIpv4),
            HttpStatus.forbidden,
          ),
          (testIpv4, testIpv6, null, HttpStatus.badRequest),
        ],
        (fixture) async {
          when(() => mockConfig.findApiKey(testFqdn))
              .thenReturnAsync(testApiKey);
          when(() => mockDynsshController.updateHost(any()))
              .thenReturnAsync(false);

          final request = FakeHttpRequest(
            'POST',
            Uri.https(
              '',
              '/dynssh/update',
              <String, String>{
                'fqdn': testFqdn,
                if (fixture.$1 != null) 'ipv4': fixture.$1!,
                if (fixture.$2 != null) 'ipv6': fixture.$2!,
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
            () => mockConfig.findApiKey(testFqdn),
            if (fixture.$3 != null)
              () => mockDynsshController.updateHost(fixture.$3!),
            () => mockHttpResponse.statusCode = fixture.$4,
            () => mockHttpResponse.close(),
          ]);
          if (fixture.$1 == null) {
            verifyNever(() => mockDynsshController.updateHost(any()));
          }
        },
      );

      testData<(bool, int)>(
        'sets result status based on host update result',
        const [
          (false, HttpStatus.forbidden),
          (true, HttpStatus.accepted),
        ],
        (fixture) async {
          when(() => mockConfig.findApiKey(testFqdn))
              .thenReturnAsync(testApiKey);
          when(() => mockDynsshController.updateHost(any()))
              .thenReturnAsync(fixture.$1);

          final request = FakeHttpRequest(
            'POST',
            Uri.https(
              '',
              '/dynssh/update',
              <String, String>{
                'fqdn': testFqdn,
                'ipv4': testIpv4,
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
            () => mockConfig.findApiKey(testFqdn),
            () => mockDynsshController.updateHost(
                  const HostUpdate.ipv4(fqdn: testFqdn, ipAddress: testIpv4),
                ),
            () => mockHttpResponse.statusCode = fixture.$2,
            () => mockHttpResponse.close(),
          ]);
        },
      );
    });
  });
}
