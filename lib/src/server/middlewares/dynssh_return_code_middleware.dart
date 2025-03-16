import 'dart:io';

import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_api/shelf_api.dart';

import '../../dynssh/return_code.dart';

Middleware dynsshReturnCode() => DynsshReturnCodeMiddleware().call;

extension ReturnCodeX on ReturnCode {
  TResponse<String> toResponse() {
    final httpStatusCode = switch (this) {
      ReturnCode.good => HttpStatus.ok,
      ReturnCode.noChg => HttpStatus.ok,
      ReturnCode.badAuth => HttpStatus.unauthorized,
      ReturnCode.notFqdn => HttpStatus.badRequest,
      ReturnCode.noHost => HttpStatus.badRequest,
      ReturnCode.abuse => HttpStatus.badRequest,
      ReturnCode.badAgent => HttpStatus.badRequest,
      ReturnCode.dnsErr => HttpStatus.internalServerError,
      ReturnCode.$911 => HttpStatus.internalServerError,
    };

    return TResponse(
      httpStatusCode,
      body: raw,
      context: {DynsshReturnCodeMiddleware.returnCodeContextKey: this},
    );
  }
}

@visibleForTesting
class DynsshReturnCodeMiddleware {
  static const returnCodeContextKey = 'returnCode';

  final _logger = Logger('$DynsshReturnCodeMiddleware');

  Handler call(Handler next) => (request) async {
    try {
      final response = await next(request);
      final returnCodeKey =
          response.context[returnCodeContextKey] as ReturnCode?;
      if (returnCodeKey != null) {
        return response;
      }

      return switch (response.statusCode) {
        400 => ReturnCode.notFqdn.toResponse(),
        >= 500 => ReturnCode.$911.toResponse(),
        _ => response,
      };
      // ignore: avoid_catches_without_on_clauses
    } catch (e, s) {
      _logger.severe('Internal server error', e, s);
      return ReturnCode.$911.toResponse();
    }
  };
}
