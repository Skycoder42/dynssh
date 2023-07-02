import 'dart:io';

import 'package:dynssh/src/cli/dynssh/cli_parser.dart';
import 'package:dynssh/src/cli/signals.dart';
import 'package:dynssh/src/config/config.dart';
import 'package:dynssh/src/server/dynssh_handler.dart';
import 'package:dynssh/src/server/http_server.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

Future<void> main(List<String> arguments) async {
  Logger.root
    ..level = Level.ALL
    ..onRecord.listen(stdout.writeln);

  final di = ProviderContainer();
  try {
    final cliParser = di.read(cliParserProvider);
    final options = cliParser.parse(arguments);

    di
      ..registerTerminationFor(ProcessSignal.sigint)
      ..registerTerminationFor(ProcessSignal.sigterm)
      ..registerTerminationFor(ProcessSignal.sighup);

    di.read(configProvider).initialize(options);

    final server = di.read(httpServerProvider)
      ..registerHandler(dynsshHandlerProvider);
    await server.start(di);

    // ignore: avoid_catches_without_on_clauses
  } catch (e) {
    di.dispose();
    rethrow;
  }
}
