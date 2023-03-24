import 'dart:convert';
import 'dart:io';

import 'package:riverpod/riverpod.dart';

import '../config/config.dart';

// coverage:ignore-start
final dyndnsHandlerProvider = Provider(
  (ref) => DyndnsHandler(
    ref.watch(configProvider),
  ),
);
// coverage:ignore-end

class DyndnsHandler {
  final Config _config;

  DyndnsHandler(this._config);

  bool canHandle(Uri uri) => uri.path == '/dynssh/update';

  Future<void> call(HttpRequest request) async {
    final fqdn = request.uri.queryParameters['fqdn'];
    final ipv4 = request.uri.queryParameters['ipv4'];
    final ipv6 = request.uri.queryParameters['ipv6'];

    final authHeader = request.headers.value(HttpHeaders.authorizationHeader);
    final expectedAuthHeader = await _buildExpectedAuthHeader(fqdn);
    if (expectedAuthHeader == null ||
        authHeader == null ||
        authHeader != expectedAuthHeader) {
      request.response.statusCode = HttpStatus.unauthorized;
      request.response.writeln(
        '${HttpHeaders.authorizationHeader} header is missing '
        'or contains invalid credentials',
      );
      await request.response.close();
      return;
    }

    if (fqdn == null || (ipv4 == null && ipv6 == null)) {
      request.response.statusCode = HttpStatus.badRequest;
      request.response.writeln('Invalid query!');
      await request.response.close();
      return;
    }

    request.response.statusCode = HttpStatus.accepted;
    await request.response.close();
  }

  Future<String?> _buildExpectedAuthHeader(String? fqdn) async {
    if (fqdn == null) {
      return null;
    }

    final apiKey = await _config.findApiKey(fqdn);
    if (apiKey == null) {
      return null;
    }

    final authSecret = '$fqdn:$apiKey';
    final encodedSecret = base64Url.encode(utf8.encode(authSecret));
    return 'Basic $encodedSecret';
  }
}
