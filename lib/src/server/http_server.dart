import 'dart:async';
import 'dart:io' as io;

import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:riverpod/riverpod.dart';

import '../config/config.dart';

// coverage:ignore-start
final httpServerProvider = Provider<HttpServer>(
  (ref) {
    ref.onDispose(() => ref.state.stop());
    return HttpServer(
      ref.watch(configProvider),
    );
  },
);
// coverage:ignore-end

abstract class HttpHandler {
  HttpHandler._();

  Future<bool> call(io.HttpRequest request);
}

// ignore: subtype_of_sealed_class
@sealed
class HttpHandlerProvider<T extends HttpHandler> extends Provider<T> {
  final bool Function(Uri url) canHandle;

  HttpHandlerProvider(
    super.createFn, {
    required this.canHandle,
    required String super.name,
    super.dependencies,
  });
}

class HttpServer {
  final Config _config;
  final _handlerProviders = <HttpHandlerProvider>[];
  final _logger = Logger('$HttpServer');

  late final ProviderContainer _di;
  late final io.HttpServer _server;
  var _open = false;

  HttpServer(this._config);

  int get port => _server.port;

  void registerHandler(HttpHandlerProvider provider) {
    _logger.config('Registering HTTP-Handler: ${provider.name}');
    _handlerProviders.add(provider);
  }

  Future<void> start(ProviderContainer di) async {
    _logger.info('Starting HTTP-Server...');
    _di = di;
    _server = await io.HttpServer.bind(
      _config.host,
      _config.port,
    );
    _open = true;

    _server.listen(
      _handleRequest,
      onError: _handleListenError,
      cancelOnError: true,
    );
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

  Future<void> _handleRequest(io.HttpRequest request) async {
    _logger
        .fine('Handling incoming request: ${_stringifyHttpRequest(request)}');
    final container = ProviderContainer(parent: _di);
    try {
      for (final provider in _handlerProviders) {
        if (provider.canHandle(request.uri)) {
          _logger.fine('Using handler: ${provider.name}');
          final handler = container.read(provider);
          final didHandle = await handler(request);
          if (didHandle) {
            return;
          }
        }
      }

      _logger.fine(
        '${io.HttpStatus.notFound} - '
        'No registered handler can handle this request!',
      );
      request.response.statusCode = io.HttpStatus.notFound;
      await request.response.close();

      // ignore: avoid_catches_without_on_clauses
    } catch (e, s) {
      _logger.severe(
        'Error of type ${e.runtimeType} occurred when processing '
        '${_stringifyHttpRequest(request)}:',
        e,
        s,
      );
      await _sendSeverError(request.response, e, s);
    } finally {
      container.dispose();
    }
  }

  Future<void> _sendSeverError(
    io.HttpResponse response,
    Object error,
    StackTrace stackTrace,
  ) async {
    response.statusCode = io.HttpStatus.internalServerError;

    assert(() {
      // add debugging info
      response
        ..writeln(error)
        ..writeln()
        ..writeln(stackTrace);
      return true;
    }());

    await response.close();
  }

  Future<void> _handleListenError(Object error, StackTrace stackTrace) async {
    _logger.shout(
      'HTTP-Server bind error (${error.runtimeType}):',
      error,
      stackTrace,
    );
    await stop(force: true);
  }

  String _stringifyHttpRequest(io.HttpRequest request) =>
      '${request.method} ${request.uri}';
}
