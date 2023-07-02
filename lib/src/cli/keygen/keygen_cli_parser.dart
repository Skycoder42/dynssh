import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

import '../../adapter/posix_adapter.dart';
import '../common/cli_parser_base.dart';
import 'keygen_options.dart';

// coverage:ignore-start
final keygenCliParserProvider = Provider(
  (ref) => KeygenCliParser(
    ref.watch(posixAdapterProvider),
  ),
);
// coverage:ignore-end

final class KeygenCliParser extends CliParserBase<KeygenOptions> {
  KeygenCliParser(PosixAdapter posixAdapter)
      : super(posixAdapter, Logger('$KeygenCliParser'));

  @override
  ArgParser buildArgParser(PosixAdapter posixAdapter) =>
      KeygenOptions.buildArgParser(posixAdapter);

  @override
  KeygenOptions parseOptions(ArgResults argResults) =>
      KeygenOptions.parseOptions(argResults);
}
