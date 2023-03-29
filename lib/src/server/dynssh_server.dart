import 'dart:async';
import 'dart:io';

import 'package:riverpod/riverpod.dart';

import '../config/config.dart';
import 'dynssh_handler.dart';

// coverage:ignore-start
final dynsshServerProvider = Provider<DynsshServer>(
  (ref) {
    ref.onDispose(() => ref.state.stop());
    return DynsshServer(
      ref.watch(configProvider),
      ref.watch(dynsshHandlerProvider),
    );
  },
);
// coverage:ignore-end

class DynsshServer {
  final Config _config;
  final DynsshHandler _dynsshHandler;

  late final HttpServer _server;

  DynsshServer(this._config, this._dynsshHandler);

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
      if (_dynsshHandler.canHandle(request.uri)) {
        await _dynsshHandler(request);
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
