import 'dart:async';
import 'dart:io';

import 'package:riverpod/riverpod.dart';

import '../config/config.dart';
import 'dyndns_handler.dart';

// coverage:ignore-start
final dyndnsServerProvider = Provider<DyndnsServer>(
  (ref) {
    ref.onDispose(() => ref.state.stop());
    return DyndnsServer(
      ref.watch(configProvider),
      ref.watch(dyndnsHandlerProvider),
    );
  },
);
// coverage:ignore-end

class DyndnsServer {
  final Config _config;
  final DyndnsHandler _dyndnsHandler;

  late final HttpServer _server;

  DyndnsServer(this._config, this._dyndnsHandler);

  Future<void> start() async {
    _server = await HttpServer.bind(
      _config.host,
      _config.port,
    );

    _server.listen(
      _handleRequest,
      onError: _handleError,
      cancelOnError: true,
    );
  }

  Future<void> stop({bool force = false}) async {
    await _server.close(force: force);
  }

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      if (_dyndnsHandler.canHandle(request.uri)) {
        await _dyndnsHandler(request);
        return;
      }

      request.response.statusCode = HttpStatus.badRequest;
      await request.response.close();

      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.writeln(e); // TODO debug mode only
      await request.response.close();
    }
  }

  Future<void> _handleError(Object error, StackTrace stackTrace) async {
    Zone.current.handleUncaughtError(error, stackTrace);
    await _server.close();
  }
}
