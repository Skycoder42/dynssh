import 'dart:convert';
import 'dart:io';

import 'package:riverpod/riverpod.dart';

import '../config/config.dart';
import '../dynssh/dynssh_controller.dart';
import '../models/host_update.dart';

// coverage:ignore-start
final dynsshHandlerProvider = Provider(
  (ref) => DynsshHandler(
    ref.watch(configProvider),
    ref.watch(dynsshControllerProvider),
  ),
);
// coverage:ignore-end

class DynsshHandler {
  final Config _config;
  final DynsshController _dynsshController;

  DynsshHandler(
    this._config,
    this._dynsshController,
  );

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

    final HostUpdate hostUpdate;
    if (fqdn == null || (ipv4 == null && ipv6 == null)) {
      request.response.statusCode = HttpStatus.badRequest;
      request.response
        ..writeln('Invalid Query!')
        ..writeln('"fdqn" and one of "ipv4" or "ipv6" must be provided!');
      await request.response.close();
      return;
    } else if (ipv4 != null && ipv6 != null) {
      request.response.statusCode = HttpStatus.badRequest;
      request.response
        ..writeln('Invalid Query!')
        ..writeln('Only one of "ipv4" or "ipv6" can be used!');
      await request.response.close();
      return;
    } else if (ipv6 != null) {
      hostUpdate = HostUpdate.ipv6(fqdn: fqdn, ipAddress: ipv6);
    } else if (ipv4 != null) {
      hostUpdate = HostUpdate.ipv4(fqdn: fqdn, ipAddress: ipv4);
    } else {
      throw StateError('Unreachable code reached!');
    }

    final updateResult = await _dynsshController.updateHost(hostUpdate);
    request.response.statusCode =
        updateResult ? HttpStatus.accepted : HttpStatus.forbidden; // TODO
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
