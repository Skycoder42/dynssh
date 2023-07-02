import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

import '../../adapter/posix_adapter.dart';
import 'i_options.dart';

abstract base class CliParserBase<TOptions extends IOptions> {
  final PosixAdapter _posixAdapter;
  final Logger _logger;

  CliParserBase(this._posixAdapter, this._logger);

  @nonVirtual
  TOptions parse(List<String> arguments) {
    final argParser = buildArgParser(_posixAdapter);

    try {
      final argResults = argParser.parse(arguments);
      final options = parseOptions(argResults);

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

  @visibleForOverriding
  ArgParser buildArgParser(PosixAdapter posixAdapter);

  @visibleForOverriding
  TOptions parseOptions(ArgResults argResults);
}
