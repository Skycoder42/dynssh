import 'package:dynssh/src/cli/options.dart';
import 'package:dynssh/src/config/config.dart';
import 'package:dynssh/src/server/dynssh_handler.dart';
import 'package:dynssh/src/server/http_server.dart';
import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';

import 'dynssh_test_case.dart';

void main() => _DynsshCliTestCase().call();

final class _DynsshCliTestCase extends DynsshTestCase {
  @override
  Future<int> runDynssh(Options testOptions) async {
    final di = ProviderContainer();
    addTearDown(di.dispose);

    di.read(configProvider).initialize(testOptions);

    final server = di.read(httpServerProvider)
      ..registerHandler(dynsshHandlerProvider);
    await server.start(di);
    addTearDown(server.stop);

    return server.port;
  }
}
