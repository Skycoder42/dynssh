// coverage:ignore-file

import 'dart:io';

import 'package:build_cli_annotations/build_cli_annotations.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

import '../../adapter/posix_adapter.dart';
import '../common/i_options.dart';

part 'options.g.dart';

@CliOptions()
@immutable
class Options implements IOptions {
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

  const Options({
    required this.host,
    required this.port,
    required this.apiKeyPath,
    required this.sshDirectory,
    required this.logLevel,
    this.help = false,
  });

  @override
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
        apiKeyPathDefaultOverride: IOptions.apiKeyPathDefault(posixAdapter),
        sshDirectoryDefaultOverride: _sshDirectoryDefault(posixAdapter),
      );

  static Options parseOptions(ArgResults argResults) =>
      _$parseOptionsResult(argResults);

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
