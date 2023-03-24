import 'dart:io';

import 'package:dynssh/src/cli/cli_parser.dart';
import 'package:dynssh/src/cli/signals.dart';
import 'package:dynssh/src/config/config.dart';
import 'package:dynssh/src/dyndns/dyndns_server.dart';
import 'package:riverpod/riverpod.dart';

Future<void> main(List<String> arguments) async {
  final di = ProviderContainer()
    ..registerTerminationFor(ProcessSignal.sigint)
    ..registerTerminationFor(ProcessSignal.sigterm)
    ..registerTerminationFor(ProcessSignal.sighup);

  final cliParser = di.read(cliParserProvider);
  final options = cliParser.parse(arguments);

  di.read(configProvider).initialize(options);
  await di.read(dyndnsServerProvider).start();
}
