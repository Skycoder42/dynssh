import 'dart:io';

import 'package:build_cli_annotations/build_cli_annotations.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:posix/posix.dart' as posix;

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
    defaultsTo: 80,
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
    abbr: 'd',
    valueHelp: 'path',
    help: 'The path to the ssh directory where configuration files are stored.',
    provideDefaultToOverride: true,
  )
  final String sshDirectory;

  @CliOption(
    convert: _logLevelFromString,
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
    required this.sshDirectory,
    required this.logLevel,
    this.help = false,
  });

  void logAll(Logger logger) => logger
    ..config('host: $host')
    ..config('port: $port')
    ..config('apiKeyPath: $apiKeyPath')
    ..config('sshConfigDir: $sshDirectory')
    ..config('logLevel: $logLevel');

  static ArgParser buildArgParser() => _$populateOptionsParser(
        ArgParser(
          allowTrailingOptions: false,
          usageLineLength: stdout.hasTerminal ? stdout.terminalColumns : null,
        ),
        hostDefaultOverride: InternetAddress.anyIPv4.address,
        apiKeyPathDefaultOverride: _apiKeyPathDefault,
        sshDirectoryDefaultOverride: _sshDirectoryDefault,
      );

  static Options parseOptions(ArgResults argResults) =>
      _$parseOptionsResult(argResults);

  static bool get _isRoot => posix.geteuid() == 0;

  static String get _apiKeyPathDefault {
    const pathSuffix = 'dynssh/api-keys.json';
    if (_isRoot) {
      return '/etc/$pathSuffix';
    } else {
      final homePath = Platform.environment['HOME'];
      if (homePath == null) {
        return Directory.current.path;
      }

      return Directory(homePath)
          .uri
          .resolve('.config/$pathSuffix')
          .toFilePath();
    }
  }

  static String get _sshDirectoryDefault {
    const globalSshDir = '/etc/ssh';
    if (_isRoot) {
      return globalSshDir;
    } else {
      final homePath = Platform.environment['HOME'];
      if (homePath == null) {
        return globalSshDir;
      }

      return Directory(homePath).uri.resolve('.ssh').toFilePath();
    }
  }
}

Level _logLevelFromString(String level) =>
    Level.LEVELS.singleWhere((element) => element.name == level.toUpperCase());
