// ignore_for_file: unnecessary_lambdas

import 'dart:io';

import 'package:dart_test_tools/test.dart';
import 'package:dynssh/src/config/config.dart';
import 'package:dynssh/src/dynssh/dynssh_controller.dart';
import 'package:dynssh/src/models/host_update.dart';
import 'package:dynssh/src/server/dynssh_handler.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:tuple/tuple.dart';

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

    testData<Tuple2<String, bool>>(
      'canHandle only allows specific path',
      const [
        Tuple2('/', false),
        Tuple2('/stuff', false),
        Tuple2('/dynssh', false),
        Tuple2('/dynssh/stuff', false),
        Tuple2('/dynssh/update', true),
        Tuple2('/dynssh/update/stuff', false),
      ],
      (fixture) {
        final testUrl = Uri.https('test.de', fixture.item1);
        expect(DynsshHandler.canHandle(testUrl), fixture.item2);
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

      testData<Tuple2<String, int>>(
        'disallows all methods except POST',
        const [
          Tuple2('GET', HttpStatus.methodNotAllowed),
          Tuple2('PUT', HttpStatus.methodNotAllowed),
          Tuple2('DELETE', HttpStatus.methodNotAllowed),
          Tuple2('PATCH', HttpStatus.methodNotAllowed),
          Tuple2('HEAD', HttpStatus.methodNotAllowed),
          Tuple2('POST', HttpStatus.unauthorized),
        ],
        (fixture) async {
          final request = FakeHttpRequest(
            fixture.item1,
            Uri.https('', '/dynssh/update'),
            FakeHttpHeaders(const {}),
            mockHttpResponse,
          );

          final result = await sut(request);

          expect(result, isTrue);

          verifyInOrder([
            () => mockHttpResponse.statusCode = fixture.item2,
            () => mockHttpResponse.close(),
          ]);
        },
      );

      testData<Tuple3<String?, String?, int>>(
        'rejects requests with invalid API-credentials',
        const [
          Tuple3(null, null, HttpStatus.unauthorized),
          Tuple3(testFqdn, null, HttpStatus.unauthorized),
          Tuple3(null, testAuthHeader, HttpStatus.unauthorized),
          Tuple3(testFqdn, 'invalid-auth-header', HttpStatus.unauthorized),
          Tuple3(
            testMissingFqdn,
            testAuthHeader,
            HttpStatus.unauthorized,
          ),
          Tuple3(
            testInvalidFqdn,
            testAuthHeader,
            HttpStatus.unauthorized,
          ),
          Tuple3(testFqdn, testAuthHeader, HttpStatus.badRequest),
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
                if (fixture.item1 != null) 'fqdn': fixture.item1!,
              },
            ),
            FakeHttpHeaders({
              if (fixture.item2 != null)
                HttpHeaders.authorizationHeader: fixture.item2!,
            }),
            mockHttpResponse,
          );

          final result = await sut(request);

          expect(result, isTrue);

          verifyInOrder([
            if (fixture.item1 != null)
              () => mockConfig.findApiKey(fixture.item1!),
            () => mockHttpResponse.statusCode = fixture.item3,
            () => mockHttpResponse.close(),
          ]);
          if (fixture.item1 == null) {
            verifyNever(() => mockConfig.findApiKey(any()));
          }
        },
      );

      testData<Tuple4<String?, String?, HostUpdate?, int>>(
        'runs host update with given parameters, if valid',
        const [
          Tuple4(null, null, null, HttpStatus.badRequest),
          Tuple4(
            null,
            testIpv6,
            HostUpdate.ipv6(fqdn: testFqdn, ipAddress: testIpv6),
            HttpStatus.forbidden,
          ),
          Tuple4(
            testIpv4,
            null,
            HostUpdate.ipv4(fqdn: testFqdn, ipAddress: testIpv4),
            HttpStatus.forbidden,
          ),
          Tuple4(testIpv4, testIpv6, null, HttpStatus.badRequest),
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
                if (fixture.item1 != null) 'ipv4': fixture.item1!,
                if (fixture.item2 != null) 'ipv6': fixture.item2!,
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
            if (fixture.item3 != null)
              () => mockDynsshController.updateHost(fixture.item3!),
            () => mockHttpResponse.statusCode = fixture.item4,
            () => mockHttpResponse.close(),
          ]);
          if (fixture.item1 == null) {
            verifyNever(() => mockDynsshController.updateHost(any()));
          }
        },
      );

      testData<Tuple2<bool, int>>(
        'sets result status based on host update result',
        const [
          Tuple2(false, HttpStatus.forbidden),
          Tuple2(true, HttpStatus.accepted),
        ],
        (fixture) async {
          when(() => mockConfig.findApiKey(testFqdn))
              .thenReturnAsync(testApiKey);
          when(() => mockDynsshController.updateHost(any()))
              .thenReturnAsync(fixture.item1);

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
            () => mockHttpResponse.statusCode = fixture.item2,
            () => mockHttpResponse.close(),
          ]);
        },
      );
    });
  });
}
