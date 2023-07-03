import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';

import '../config/config.dart';
import '../dynssh/dynssh_controller.dart';
import '../models/host_update.dart';
import 'http_server.dart';

// coverage:ignore-start
final dynsshHandlerProvider = HttpHandlerProvider(
  name: '$DynsshHandler',
  canHandle: DynsshHandler.canHandle,
  (ref) => DynsshHandler(
    ref.watch(configProvider),
    ref.watch(dynsshControllerProvider),
  ),
);
// coverage:ignore-end

class DynsshHandler implements HttpHandler {
  static const _allowedMethods = ['GET', 'POST'];

  final Config _config;
  final DynsshController _dynsshController;
  final _logger = Logger('$DynsshHandler');

  DynsshHandler(
    this._config,
    this._dynsshController,
  );

  static bool canHandle(Uri url) => url.path == '/dynssh/update';

  @override
  Future<bool> call(HttpRequest request) async {
    assert(canHandle(request.uri));

    if (!_allowedMethods.contains(request.method)) {
      _logger.warning(
        'Rejecting ${request.method} request, only GET and POST are allowed',
      );
      request.response.statusCode = HttpStatus.methodNotAllowed;
      request.response.writeln('This endpoint only accepts POST-Requests');
      await request.response.close();
      return true;
    }

    final hostname = request.uri.queryParameters['hostname'];
    final myIP = request.uri.queryParameters['myip'];
    final authHeader = request.headers.value(HttpHeaders.authorizationHeader);

    _logger
      ..finest('hostname: $hostname')
      ..finest('myip: $myIP')
      ..finest('${HttpHeaders.authorizationHeader}: $authHeader');

    final expectedAuthHeader = await _buildExpectedAuthHeader(hostname);
    if (expectedAuthHeader == null ||
        authHeader == null ||
        authHeader != expectedAuthHeader) {
      _logger.warning('Blocked request with invalid credentials for $hostname');
      request.response.statusCode = HttpStatus.unauthorized;
      request.response.writeln(
        '${HttpHeaders.authorizationHeader} header is missing '
        'or contains invalid credentials',
      );
      await request.response.close();
      return true;
    }

    if (hostname == null || myIP == null) {
      request.response.statusCode = HttpStatus.badRequest;
      request.response
        ..writeln('Invalid Query!')
        ..writeln('"hostname" and "myip" must be provided!');
      await request.response.close();
      return true;
    }

    final hostUpdate = HostUpdate(hostname: hostname, ipAddress: myIP);

    _logger.finest('Request validation succeeded. Start host update');
    final updateResult = await _dynsshController.updateHost(hostUpdate);
    request.response.statusCode =
        updateResult ? HttpStatus.accepted : HttpStatus.forbidden;
    await request.response.close();
    return true;
  }

  Future<String?> _buildExpectedAuthHeader(String? hostname) async {
    if (hostname == null) {
      return null;
    }

    final apiKey = await _config.findApiKey(hostname);
    if (apiKey == null) {
      _logger.warning('Unable to find API-Key for hostname: $hostname');
      return null;
    }

    final authSecret = '$hostname:$apiKey';
    final encodedSecret = base64Url.encode(utf8.encode(authSecret));
    final authHeader = 'Basic $encodedSecret';
    _logger.finest('Expected ${HttpHeaders.authorizationHeader}: $authHeader');
    return authHeader;
  }
}
