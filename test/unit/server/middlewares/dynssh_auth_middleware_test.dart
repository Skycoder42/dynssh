import 'dart:async';
import 'dart:io';

import 'package:dart_test_tools/test.dart';
import 'package:dynssh/src/config/config.dart';
import 'package:dynssh/src/dynssh/return_code.dart';
import 'package:dynssh/src/server/middlewares/dynssh_auth_middleware.dart';
import 'package:dynssh/src/server/middlewares/dynssh_return_code_middleware.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_api/shelf_api.dart';
import 'package:test/test.dart';

class MockConfig extends Mock implements Config {}

abstract class _Handler {
  FutureOr<Response> call(Request request);
}

class MockHandler extends Mock implements _Handler {}

class MockRequest extends Mock implements Request {}

class MockEndpointRef extends Mock implements EndpointRef {}

void main() {
  setUpAll(() {
    registerFallbackValue(MockRequest());
  });

  group('$DynsshAuthMiddleware', () {
    final mockConfig = MockConfig();
    final mockHandler = MockHandler();
    final mockRequest = MockRequest();
    final mockEndpointRef = MockEndpointRef();

    late Handler sut;

    setUp(() {
      reset(mockConfig);
      reset(mockHandler);
      reset(mockRequest);
      reset(mockEndpointRef);

      when(() => mockHandler(any())).thenReturn(ReturnCode.good.toResponse());
      when(() => mockEndpointRef.read(configProvider)).thenReturn(mockConfig);

      final middleware = DynsshAuthMiddleware();
      sut = middleware(mockHandler.call, refForTesting: mockEndpointRef);
    });

    group('call', () {
      const testHostname = 'test.example.com';
      const testUnknownHostname = 'unknown.example.com';
      const testApiKey = 'test-api-key';
      const testAuthHeader = 'Basic dGVzdC5leGFtcGxlLmNvbTp0ZXN0LWFwaS1rZXk=';
      const testInvalidAuthHeader =
          'Basic XXXzdC5leGFtcGxlLmNvbTp0ZXN0LWFwaS1rZXk=';

      testData<(String?, String?, int, ReturnCode)>(
        'rejects requests with invalid API-credentials',
        const [
          (null, null, HttpStatus.badRequest, ReturnCode.notFqdn),
          (testHostname, null, HttpStatus.unauthorized, ReturnCode.badAuth),
          (null, testAuthHeader, HttpStatus.badRequest, ReturnCode.notFqdn),
          (
            testUnknownHostname,
            testAuthHeader,
            HttpStatus.unauthorized,
            ReturnCode.badAuth,
          ),
          (
            testHostname,
            testInvalidAuthHeader,
            HttpStatus.unauthorized,
            ReturnCode.badAuth,
          ),
          (testHostname, testAuthHeader, HttpStatus.ok, ReturnCode.good),
        ],
        (fixture) async {
          when(() => mockConfig.findApiKey(any())).thenReturnAsync(null);
          when(
            () => mockConfig.findApiKey(testHostname),
          ).thenReturnAsync(testApiKey);

          when(() => mockRequest.url).thenReturn(
            Uri.https('', '/dynssh/update', <String, String>{
              if (fixture.$1 != null) 'hostname': fixture.$1!,
            }),
          );
          when(() => mockRequest.headers).thenReturn({
            if (fixture.$2 != null)
              HttpHeaders.authorizationHeader: fixture.$2!,
          });

          final result = await sut(mockRequest);

          expect(result.statusCode, fixture.$3);
          expect(result.readAsString(), completion(fixture.$4.raw));

          if (fixture.$1 case final String host when fixture.$2 != null) {
            verify(() => mockConfig.findApiKey(host));
          } else {
            verifyNever(() => mockConfig.findApiKey(any()));
          }
        },
      );
    });
  });
}
