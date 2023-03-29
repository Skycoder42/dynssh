import 'dart:async';
import 'dart:io' as io;

import 'package:meta/meta.dart';
import 'package:riverpod/riverpod.dart';

import '../config/config.dart';

// coverage:ignore-start
final httpServerProvider = Provider(
  (ref) => HttpServer(
    ref.watch(configProvider),
  ),
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
    super.name,
    super.dependencies,
  });
}

class HttpServer {
  final Config _config;
  final _handlerProviders = <HttpHandlerProvider>[];

  late final ProviderContainer _di;
  late final io.HttpServer _server;

  HttpServer(this._config);

  void registerHandler(HttpHandlerProvider provider) =>
      _handlerProviders.add(provider);

  Future<void> start(ProviderContainer di) async {
    _di = di;
    _server = await io.HttpServer.bind(
      _config.host,
      _config.port,
    );

    _server.listen(
      _handleRequest,
      onError: _handleListenError,
      cancelOnError: true,
    );
  }

  Future<void> stop({bool force = false}) async {
    await _server.close(force: force);
  }

  Future<void> _handleRequest(io.HttpRequest request) async {
    final container = ProviderContainer(parent: _di);
    try {
      for (final provider in _handlerProviders) {
        if (provider.canHandle(request.uri)) {
          final handler = container.read(provider);
          final didHandle = await handler(request);
          if (didHandle) {
            return;
          }
        }
      }

      request.response.statusCode = io.HttpStatus.notFound;
      await request.response.close();

      // ignore: avoid_catches_without_on_clauses
    } catch (e, s) {
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
    Zone.current.handleUncaughtError(error, stackTrace);
    await _server.close();
  }
}
