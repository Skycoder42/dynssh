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
  canHandle: (url) => url.path == '/dynssh/update',
  (ref) => DynsshHandler(
    ref.watch(configProvider),
    ref.watch(dynsshControllerProvider),
  ),
);
// coverage:ignore-end

class DynsshHandler implements HttpHandler {
  final Config _config;
  final DynsshController _dynsshController;
  final _logger = Logger('$DynsshHandler');

  DynsshHandler(
    this._config,
    this._dynsshController,
  );

  @override
  Future<bool> call(HttpRequest request) async {
    if (request.method != 'POST') {
      request.response.statusCode = HttpStatus.methodNotAllowed;
      request.response.writeln('This endpoint only accepts POST-Requests');
      await request.response.close();
      return true;
    }

    final fqdn = request.uri.queryParameters['fqdn'];
    final ipv4 = request.uri.queryParameters['ipv4'];
    final ipv6 = request.uri.queryParameters['ipv6'];
    final authHeader = request.headers.value(HttpHeaders.authorizationHeader);

    _logger
      ..finest('fqdn: $fqdn')
      ..finest('ipv4: $ipv4')
      ..finest('ipv6: $ipv6')
      ..finest('${HttpHeaders.authorizationHeader}: $authHeader');

    final expectedAuthHeader = await _buildExpectedAuthHeader(fqdn);
    if (expectedAuthHeader == null ||
        authHeader == null ||
        authHeader != expectedAuthHeader) {
      _logger.warning('Blocked request with invalid credentials for $fqdn');
      request.response.statusCode = HttpStatus.unauthorized;
      request.response.writeln(
        '${HttpHeaders.authorizationHeader} header is missing '
        'or contains invalid credentials',
      );
      await request.response.close();
      return true;
    }

    final HostUpdate hostUpdate;
    if (fqdn == null || (ipv4 == null && ipv6 == null)) {
      request.response.statusCode = HttpStatus.badRequest;
      request.response
        ..writeln('Invalid Query!')
        ..writeln('"fqdn" and one of "ipv4" or "ipv6" must be provided!');
      await request.response.close();
      return true;
    } else if (ipv4 != null && ipv6 != null) {
      request.response.statusCode = HttpStatus.badRequest;
      request.response
        ..writeln('Invalid Query!')
        ..writeln('Only one of "ipv4" or "ipv6" can be used!');
      await request.response.close();
      return true;
    } else if (ipv6 != null) {
      hostUpdate = HostUpdate.ipv6(fqdn: fqdn, ipAddress: ipv6);
    } else if (ipv4 != null) {
      hostUpdate = HostUpdate.ipv4(fqdn: fqdn, ipAddress: ipv4);
    } else {
      throw StateError('Unreachable code reached!');
    }

    _logger.finest('Request validation succeeded. Start host update');
    final updateResult = await _dynsshController.updateHost(hostUpdate);
    request.response.statusCode =
        updateResult ? HttpStatus.accepted : HttpStatus.forbidden;
    await request.response.close();
    return true;
  }

  Future<String?> _buildExpectedAuthHeader(String? fqdn) async {
    if (fqdn == null) {
      return null;
    }

    final apiKey = await _config.findApiKey(fqdn);
    if (apiKey == null) {
      _logger.warning('Unable to find API-Key for fqdn: $fqdn');
      return null;
    }

    final authSecret = '$fqdn:$apiKey';
    final encodedSecret = base64Url.encode(utf8.encode(authSecret));
    final authHeader = 'Basic $encodedSecret';
    _logger.finest('Expected ${HttpHeaders.authorizationHeader}: $authHeader');
    return authHeader;
  }
}
