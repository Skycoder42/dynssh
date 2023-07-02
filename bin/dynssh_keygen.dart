import 'dart:io';

import 'package:dynssh/src/cli/keygen/keygen_cli_parser.dart';
import 'package:dynssh/src/keygen/keygen_controller.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

Future<void> main(List<String> arguments) async {
  Logger.root
    ..level = Level.ALL
    ..onRecord.listen(stdout.writeln);

  final di = ProviderContainer();
  try {
    final cliParser = di.read(keygenCliParserProvider);
    final options = cliParser.parse(arguments);

    final keygenController = di.read(keygenControllerProvider);
    await keygenController.generateKeys(options);
  } finally {
    di.dispose();
  }
}
