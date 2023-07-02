// coverage:ignore-file

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

import '../../adapter/posix_adapter.dart';
import '../common/cli_parser_base.dart';
import 'options.dart';

// coverage:ignore-start
final cliParserProvider = Provider(
  (ref) => CliParser(
    ref.watch(posixAdapterProvider),
  ),
);
// coverage:ignore-end

final class CliParser extends CliParserBase<Options> {
  CliParser(PosixAdapter posixAdapter)
      : super(posixAdapter, Logger('$CliParser'));

  @override
  ArgParser buildArgParser(PosixAdapter posixAdapter) =>
      Options.buildArgParser(posixAdapter);

  @override
  Options parseOptions(ArgResults argResults) =>
      Options.parseOptions(argResults);
}
