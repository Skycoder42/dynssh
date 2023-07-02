import 'dart:io';

import 'package:args/args.dart';
import 'package:build_cli_annotations/build_cli_annotations.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

import '../../adapter/posix_adapter.dart';
import '../common/i_options.dart';

part 'keygen_options.g.dart';

@CliOptions()
@immutable
class KeygenOptions implements IOptions {
  @CliOption(
    name: 'host-name',
    abbr: 'n',
    valueHelp: 'host-name',
    help: 'The host names to generate new API keys for.',
  )
  final List<String> hostNames;

  @CliOption(
    abbr: 'o',
    negatable: true,
    defaultsTo: false,
    help: 'Allow existing API-Keys to be overwritten.',
  )
  final bool overwrite;

  @CliOption(
    abbr: 'L',
    defaultsTo: 64,
    valueHelp: 'bytes',
    help: 'The length (in bytes) each generate key should have.',
  )
  final int keyLength;

  @CliOption(
    abbr: 'k',
    valueHelp: 'path',
    help: 'The path to the API-Key json file.',
    provideDefaultToOverride: true,
  )
  final String apiKeyPath;

  @CliOption(
    abbr: 'p',
    defaultsTo: true,
    negatable: true,
    help: 'Print the newly generated keys.',
  )
  final bool printKeys;

  @override
  @CliOption(
    convert: logLevelFromString,
    abbr: 'l',
    allowed: [
      'all',
      'finest',
      'finer',
      'fine',
      'config',
      'info',
      'warning',
      'severe',
      'shout',
      'off',
    ],
    defaultsTo: 'info',
    valueHelp: 'level',
    help: 'Customize the logging level. '
        'Listed from most verbose (all) to least verbose (off)',
  )
  final Level logLevel;

  @override
  @CliOption(
    abbr: 'h',
    negatable: false,
    defaultsTo: false,
    help: 'Prints usage information.',
  )
  final bool help;

  const KeygenOptions({
    required this.hostNames,
    required this.overwrite,
    required this.keyLength,
    required this.apiKeyPath,
    required this.printKeys,
    required this.logLevel,
    this.help = false,
  });

  @override
  void validate() {
    if (hostNames.isEmpty) {
      throw ArgParserException('At least one host name must be given!');
    }
  }

  @override
  void logAll(Logger logger) => logger
    ..config('hostNames: $hostNames')
    ..config('overwrite: $overwrite')
    ..config('keyLength: $keyLength')
    ..config('apiKeyPath: $apiKeyPath')
    ..config('printKeys: $printKeys')
    ..config('logLevel: $logLevel');

  static ArgParser buildArgParser(PosixAdapter posixAdapter) =>
      _$populateKeygenOptionsParser(
        ArgParser(
          allowTrailingOptions: false,
          usageLineLength: stdout.hasTerminal ? stdout.terminalColumns : null,
        ),
        apiKeyPathDefaultOverride: IOptions.apiKeyPathDefault(posixAdapter),
      );

  static KeygenOptions parseOptions(ArgResults argResults) =>
      _$parseKeygenOptionsResult(argResults);
}
