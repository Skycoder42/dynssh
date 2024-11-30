import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_api/shelf_api.dart';

import '../../dynssh/dynssh_controller.dart';
import '../../models/host_update.dart';
import '../middlewares/dynssh_auth_middleware.dart';
import '../middlewares/dynssh_return_code_middleware.dart';

@ApiEndpoint('/dynssh', middleware: DynsshEndpoint.dynsshMiddleware)
class DynsshEndpoint extends ShelfEndpoint {
  static const hostNameParameterKey = 'hostname';

  final _logger = Logger('$DynsshEndpoint');

  DynsshEndpoint(super.request);

  @Post('/update')
  Future<TResponse<String>> update({
    @QueryParam(name: hostNameParameterKey) required String hostname,
    @QueryParam(name: 'myip') required String myIP,
  }) async {
    _logger
      ..finest('hostname: $hostname')
      ..finest('myip: $myIP')
      ..finest('Request validation succeeded. Start host update');

    final hostUpdate = HostUpdate(hostname: hostname, ipAddress: myIP);
    final dynsshController = ref.read(dynsshControllerProvider);
    final updateResult = await dynsshController.updateHost(hostUpdate);
    return updateResult.toResponse();
  }

  @Get('/update')
  Future<void> updateViaGet({
    @QueryParam(name: hostNameParameterKey) required String hostName,
    @QueryParam(name: 'myip') required String myIP,
  }) =>
      update(hostname: hostName, myIP: myIP);

  static Middleware dynsshMiddleware() => (handler) => const Pipeline()
      .addMiddleware(dynsshReturnCode())
      .addMiddleware(dynsshAuth())
      .addHandler(handler);
}
