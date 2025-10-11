import 'dart:async';
import 'dart:io' as io;

import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_api/shelf_api.dart';

import '../config/config.dart';
import 'dynssh_api.dart';

part 'http_server.g.dart';

// coverage:ignore-start
@Riverpod(keepAlive: true)
HttpServer httpServer(Ref ref) {
  final server = HttpServer(ref.watch(configProvider), ref.container);
  ref.onDispose(server.stop);
  return server;
}
// coverage:ignore-end

class HttpServer {
  final Config _config;
  final ProviderContainer _di;
  final _logger = Logger('$HttpServer');

  late final io.HttpServer _server;
  var _open = false;

  HttpServer(this._config, this._di);

  int get port => _server.port;

  Future<void> start() async {
    _logger.info('Starting HTTP-Server...');
    _server = await serve(
      _requestHandler,
      _config.host,
      _config.port,
      poweredByHeader: null,
    );
    _open = true;

    _logger.info(
      'Server ready and listening on '
      '${_server.address.address}:${_server.port}',
    );
  }

  Future<void> stop({bool force = false}) async {
    if (!_open && !force) {
      return;
    }

    _logger.info('Stopping server (force: $force)...');
    await _server.close(force: force);
    _open = false;
    _logger.info('Server stopped');
  }

  Handler get _requestHandler => const Pipeline()
      .addMiddleware(handleFormatExceptions())
      .debugAddMiddleware(_handleSeverError())
      .addMiddleware(logRequests(logger: _logRequest))
      .addMiddleware(rivershelfContainer(_di))
      .addHandler(_di.read(dynsshApiProvider).call);

  void _logRequest(String message, bool isError) =>
      isError ? _logger.severe(message) : _logger.fine(message);

  Middleware _handleSeverError() =>
      (next) => (request) async {
        try {
          return await next(request);
          // ignore: avoid_catches_without_on_clauses
        } catch (e, s) {
          final buffer = StringBuffer()
            ..writeln(e)
            ..writeln()
            ..writeln(s);
          return Response.internalServerError(body: buffer.toString());
        }
      };
}

extension on Pipeline {
  Pipeline debugAddMiddleware(Middleware middleware) {
    var result = this;
    assert(() {
      result = addMiddleware(middleware);
      return true;
    }());
    return result;
  }
}
