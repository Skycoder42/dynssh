import 'package:shelf/shelf.dart';
import 'package:shelf_api/shelf_api.dart';

import 'endpoints/dynssh_endpoint.dart';
import 'middlewares/dynssh_auth_middleware.dart';
import 'middlewares/dynssh_return_code_middleware.dart';

@ShelfApi(
  [
    DynsshEndpoint,
  ],
  middleware: dynsshMiddleware,
)
// ignore: unused_element
class _DynsshApi {}

Middleware dynsshMiddleware() => (next) => const Pipeline()
    .addMiddleware(logRequests(logger: _logRequest))
    .addMiddleware(dynsshReturnCode())
    .addMiddleware(rivershelfContainer(_providerContainer))
    .addMiddleware(dynsshAuth())
    .addMiddleware(handleFormatExceptions())
    .addHandler(next);
