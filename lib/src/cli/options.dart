// coverage:ignore-file

import 'dart:io';

import 'package:build_cli_annotations/build_cli_annotations.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

import '../adapter/posix_adapter.dart';

part 'options.g.dart';

@CliOptions()
@immutable
class const Options({
  @CliOption(
    abbr: 'H',
    valueHelp: 'host',
    provideDefaultToOverride: true,
    help: 'The host address to listen to.',
  )
  required final String host,
  @CliOption(
    abbr: 'p',
    valueHelp: 'port',
    defaultsTo: 80,
    help: 'The port to listen to.',
  )
  required final int port,
  @CliOption(
    abbr: 'k',
    valueHelp: 'path',
    help: 'The path to the API-Key json file.',
    provideDefaultToOverride: true,
  )
  required final String apiKeyPath,
  @CliOption(
    abbr: 'd',
    valueHelp: 'path',
    help: 'The path to the ssh directory where configuration files are stored.',
    provideDefaultToOverride: true,
  )
  required final String sshDirectory,
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
    help:
        'Customize the logging level. '
        'Listed from most verbose (all) to least verbose (off)',
  )
  required final Level logLevel,
  @CliOption(
    abbr: 'h',
    negatable: false,
    defaultsTo: false,
    help: 'Prints usage information.',
  )
  final bool help = false,
}) {
  void logAll(Logger logger) => logger
    ..config('host: $host')
    ..config('port: $port')
    ..config('apiKeyPath: $apiKeyPath')
    ..config('sshConfigDir: $sshDirectory')
    ..config('logLevel: $logLevel');

  static ArgParser buildArgParser(PosixAdapter posixAdapter) =>
      _$populateOptionsParser(
        ArgParser(
          allowTrailingOptions: false,
          usageLineLength: stdout.hasTerminal ? stdout.terminalColumns : null,
        ),
        hostDefaultOverride: InternetAddress.anyIPv4.address,
        apiKeyPathDefaultOverride: _apiKeyPathDefault(posixAdapter),
        sshDirectoryDefaultOverride: _sshDirectoryDefault(posixAdapter),
      );

  static Options parseOptions(ArgResults argResults) =>
      _$parseOptionsResult(argResults);

  static String _apiKeyPathDefault(PosixAdapter posixAdapter) {
    const pathSuffix = 'dynssh/api-keys.json';
    if (posixAdapter.isRoot) {
      return '/etc/$pathSuffix';
    } else {
      final homePath = Platform.environment['HOME'];
      if (homePath == null) {
        return Directory.current.path;
      }

      return Directory(homePath).uri
          .resolve('.config/$pathSuffix')
          .toFilePath();
    }
  }

  static String _sshDirectoryDefault(PosixAdapter posixAdapter) {
    const globalSshDir = '/etc/ssh';
    if (posixAdapter.isRoot) {
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
