// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'options.dart';

// **************************************************************************
// CliGenerator
// **************************************************************************

T _$badNumberFormat<T extends num>(
  String source,
  String type,
  String argName,
) =>
    throw FormatException(
      'Cannot parse "$source" into `$type` for option "$argName".',
    );

Options _$parseOptionsResult(ArgResults result) => Options(
      host: result['host'] as String,
      port: int.tryParse(result['port'] as String) ??
          _$badNumberFormat(
            result['port'] as String,
            'int',
            'port',
          ),
      apiKeyPath: result['api-key-path'] as String,
      help: result['help'] as bool,
    );

ArgParser _$populateOptionsParser(
  ArgParser parser, {
  String? hostDefaultOverride,
  String? apiKeyPathDefaultOverride,
}) =>
    parser
      ..addOption(
        'host',
        abbr: 'H',
        help: 'The host address to listen to.',
        valueHelp: 'host',
        defaultsTo: hostDefaultOverride,
      )
      ..addOption(
        'port',
        abbr: 'p',
        help: 'The port to listen to.',
        valueHelp: 'port',
        defaultsTo: '23293',
      )
      ..addOption(
        'api-key-path',
        abbr: 'k',
        help: 'The path to the API-Key json file.',
        valueHelp: 'path',
        defaultsTo: apiKeyPathDefaultOverride,
      )
      ..addFlag(
        'help',
        abbr: 'h',
        help: 'Prints usage information.',
        negatable: false,
      );

final _$parserForOptions = _$populateOptionsParser(ArgParser());

Options parseOptions(List<String> args) {
  final result = _$parserForOptions.parse(args);
  return _$parseOptionsResult(result);
}
