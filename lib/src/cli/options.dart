import 'dart:io';

import 'package:build_cli_annotations/build_cli_annotations.dart';
import 'package:meta/meta.dart';

part 'options.g.dart';

@CliOptions()
@immutable
class Options {
  @CliOption(
    abbr: 'H',
    valueHelp: 'host',
    provideDefaultToOverride: true,
    help: 'The host address to listen to.',
  )
  final String host;

  @CliOption(
    abbr: 'p',
    valueHelp: 'port',
    defaultsTo: 23293,
    help: 'The port to listen to.',
  )
  final int port;

  @CliOption(
    abbr: 'k',
    valueHelp: 'path',
    help: 'The path to the API-Key json file.',
    provideDefaultToOverride: true,
  )
  final String apiKeyPath;

  @CliOption(
    abbr: 'h',
    negatable: false,
    defaultsTo: false,
    help: 'Prints usage information.',
  )
  final bool help;

  const Options({
    required this.host,
    required this.port,
    required this.apiKeyPath,
    this.help = false,
  });

  static ArgParser buildArgParser() => _$populateOptionsParser(
        ArgParser(
          allowTrailingOptions: false,
          usageLineLength: stdout.hasTerminal ? stdout.terminalColumns : null,
        ),
        hostDefaultOverride: InternetAddress.anyIPv6.address,
        apiKeyPathDefaultOverride: _apiKeyPathDefault,
      );

  static Options parseOptions(ArgResults argResults) =>
      _$parseOptionsResult(argResults);

  static String get _apiKeyPathDefault {
    final homePath = Platform.environment['HOME'];
    if (homePath == null) {
      return Directory.current.path;
    }

    return Directory(homePath)
        .uri
        .resolve('.config/dynssh/api-keys.json')
        .toFilePath();
  }
}
