// ignore_for_file: unnecessary_lambdas, discarded_futures

import 'dart:async';
import 'dart:io';

import 'package:dart_test_tools/test.dart';
import 'package:dynssh/src/dynssh/return_code.dart';
import 'package:dynssh/src/server/middlewares/dynssh_return_code_middleware.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

abstract class _Handler {
  FutureOr<Response> call(Request request);
}

class MockHandler extends Mock implements _Handler {}

class FakeRequest extends Fake implements Request {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeRequest());
  });

  group('ReturnCodeX', () {
    testData(
      'maps return code to response',
      [
        (ReturnCode.good, HttpStatus.ok),
        (ReturnCode.noChg, HttpStatus.ok),
        (ReturnCode.badAuth, HttpStatus.unauthorized),
        (ReturnCode.notFqdn, HttpStatus.badRequest),
        (ReturnCode.noHost, HttpStatus.badRequest),
        (ReturnCode.abuse, HttpStatus.badRequest),
        (ReturnCode.badAgent, HttpStatus.badRequest),
        (ReturnCode.dnsErr, HttpStatus.internalServerError),
        (ReturnCode.$911, HttpStatus.internalServerError),
      ],
      (fixture) {
        final response = fixture.$1.toResponse();
        expect(response.statusCode, fixture.$2);
        expect(response.readAsString(), completion(fixture.$1.raw));
        expect(
          response.context,
          containsPair(
            DynsshReturnCodeMiddleware.returnCodeContextKey,
            fixture.$1,
          ),
        );
      },
    );
  });

  group('$DynsshReturnCodeMiddleware', () {
    final mockHandler = MockHandler();

    late Handler sut;

    setUp(() {
      reset(mockHandler);

      final middleware = DynsshReturnCodeMiddleware();
      sut = middleware(mockHandler.call);
    });

    group('call', () {
      test(
        'calls handler and returns original response if it has a return code',
        () async {
          final testResponse = ReturnCode.abuse.toResponse();
          when(() => mockHandler(any())).thenReturn(testResponse);

          final request = FakeRequest();
          final response = await sut(request);
          expect(response, same(testResponse));

          verify(() => mockHandler(request));
        },
      );

      testData(
        'returns placeholder response if not present',
        [
          (Response.badRequest(), ReturnCode.notFqdn),
          (Response.internalServerError(), ReturnCode.$911),
          (Response.unauthorized('error'), null),
        ],
        (fixture) async {
          when(() => mockHandler(any())).thenReturn(fixture.$1);

          final response = await sut(FakeRequest());
          if (fixture.$2 case final ReturnCode code) {
            expect(
              response.context,
              containsPair(
                DynsshReturnCodeMiddleware.returnCodeContextKey,
                code,
              ),
            );
          } else {
            expect(
              response.context,
              isNot(contains(DynsshReturnCodeMiddleware.returnCodeContextKey)),
            );
          }
        },
      );

      test('returns 911 code if handler throws', () async {
        when(() => mockHandler(any())).thenThrow(Exception('test'));

        final request = FakeRequest();
        final response = await sut(request);

        expect(
          response.context,
          containsPair(
            DynsshReturnCodeMiddleware.returnCodeContextKey,
            ReturnCode.$911,
          ),
        );
      });
    });
  });
}
