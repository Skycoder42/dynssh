// coverage:ignore-file

import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

import '../adapter/posix_adapter.dart';
import 'options.dart';

// coverage:ignore-start
final cliParserProvider = Provider(
  (ref) => CliParser(
    ref.watch(posixAdapterProvider),
  ),
);
// coverage:ignore-end

class CliParser {
  final PosixAdapter _posixAdapter;
  final _logger = Logger('$CliParser');

  CliParser(this._posixAdapter);

  Options parse(List<String> arguments) {
    final argParser = Options.buildArgParser(_posixAdapter);

    try {
      final argResults = argParser.parse(arguments);
      final options = Options.parseOptions(argResults);

      Logger.root.level = options.logLevel;
      _logger.finest('Parsed arguments: $arguments');

      if (options.help) {
        stdout
          ..writeln('Usage:')
          ..writeln(argParser.usage);
        exit(0);
      }

      options.logAll(_logger);

      return options;
    } on ArgParserException catch (e) {
      stderr
        ..writeln(e)
        ..writeln()
        ..writeln('Usage:')
        ..writeln(argParser.usage);
      exit(127);
    }
  }
}
