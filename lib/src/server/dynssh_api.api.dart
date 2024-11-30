// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// EndpointGenerator
// **************************************************************************

// ignore_for_file: invalid_use_of_protected_member, type=lint, unused_import

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i4;

import 'package:dynssh/src/server/endpoints/dynssh_endpoint.dart' as _i3;
import 'package:shelf/shelf.dart' as _i2;
import 'package:shelf_api/builder_utils.dart';
import 'package:shelf_router/shelf_router.dart' as _i1;
import 'package:shelf_router/shelf_router.dart' show RouterParams;

class DynsshApi {
  DynsshApi() {
    _$handler = _i1.Router()
      ..mount(
        r'/dynssh',
        const _i2.Pipeline()
            .addMiddleware(_i3.DynsshEndpoint.dynsshMiddleware())
            .addHandler(_i1.Router()
              ..add(
                'POST',
                r'/update',
                _handler$DynsshEndpoint$update,
              )
              ..add(
                'GET',
                r'/update',
                _handler$DynsshEndpoint$updateViaGet,
              )),
      );
  }

  late final _i2.Handler _$handler;

  _i4.FutureOr<_i2.Response> call(_i2.Request request) => _$handler(request);

  Future<_i2.Response> _handler$DynsshEndpoint$update(
      _i2.Request $request) async {
    final $endpoint = _i3.DynsshEndpoint($request);
    await $endpoint.init();
    try {
      final $query = $request.url.queryParametersAll;
      final $query$hostname = $query[r'hostname']?.firstOrNull;
      if ($query$hostname == null) {
        return _i2.Response.badRequest(
            body: r'Missing required query parameter hostname');
      }
      final $query$myIP = $query[r'myip']?.firstOrNull;
      if ($query$myIP == null) {
        return _i2.Response.badRequest(
            body: r'Missing required query parameter myip');
      }
      return await $endpoint.update(
        hostname: $query$hostname,
        myIP: $query$myIP,
      );
    } finally {
      await $endpoint.dispose();
    }
  }

  Future<_i2.Response> _handler$DynsshEndpoint$updateViaGet(
      _i2.Request $request) async {
    final $endpoint = _i3.DynsshEndpoint($request);
    await $endpoint.init();
    try {
      final $query = $request.url.queryParametersAll;
      final $query$hostName = $query[r'hostname']?.firstOrNull;
      if ($query$hostName == null) {
        return _i2.Response.badRequest(
            body: r'Missing required query parameter hostname');
      }
      final $query$myIP = $query[r'myip']?.firstOrNull;
      if ($query$myIP == null) {
        return _i2.Response.badRequest(
            body: r'Missing required query parameter myip');
      }
      await $endpoint.updateViaGet(
        hostName: $query$hostName,
        myIP: $query$myIP,
      );
      return _i2.Response(204);
    } finally {
      await $endpoint.dispose();
    }
  }
}
