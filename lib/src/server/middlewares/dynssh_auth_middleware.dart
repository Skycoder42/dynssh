import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_api/shelf_api.dart';

import '../../config/config.dart';
import '../../dynssh/return_code.dart';
import '../endpoints/dynssh_endpoint.dart';
import 'dynssh_return_code_middleware.dart';

Middleware dynsshAuth() => DynsshAuthMiddleware().call;

@visibleForTesting
class DynsshAuthMiddleware {
  final _logger = Logger('$DynsshAuthMiddleware');

  DynsshAuthMiddleware();

  Handler call(
    Handler next, {
    @visibleForTesting EndpointRef? refForTesting,
  }) => (request) async {
    final hostname =
        request.url.queryParameters[DynsshEndpoint.hostNameParameterKey];
    final authHeader = request.headers[HttpHeaders.authorizationHeader];

    _logger
      ..finest('hostname: $hostname')
      ..finest('${HttpHeaders.authorizationHeader}: $authHeader');

    if (hostname == null) {
      _logger.warning('hostname query parameter is missing in request');
      return ReturnCode.notFqdn.toResponse();
    }

    if (authHeader == null) {
      _logger.warning('Blocked request with missing credentials for $hostname');
      return ReturnCode.badAuth.toResponse();
    }

    final expectedAuthHeader = await _buildExpectedAuthHeader(
      refForTesting ?? request.ref,
      request,
      hostname,
    );
    if (expectedAuthHeader == null || authHeader != expectedAuthHeader) {
      _logger.warning('Blocked request with invalid credentials for $hostname');
      return ReturnCode.badAuth.toResponse();
    }

    return await next(request);
  };

  Future<String?> _buildExpectedAuthHeader(
    EndpointRef ref,
    Request request,
    String hostname,
  ) async {
    final config = ref.read(configProvider);

    final apiKey = await config.findApiKey(hostname);
    if (apiKey == null) {
      _logger.warning('Unable to find API-Key for hostname: $hostname');
      return null;
    }

    final authSecret = '$hostname:$apiKey';
    final encodedSecret = base64.encode(utf8.encode(authSecret));
    final authHeader = 'Basic $encodedSecret';
    _logger.finest('Expected ${HttpHeaders.authorizationHeader}: $authHeader');
    return authHeader;
  }
}
