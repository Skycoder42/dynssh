import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

// coverage:ignore-start
final processAdapterProvider = Provider(
  (ref) => ProcessAdapter(stderr),
);
// coverage:ignore-end

class ProcessFailed implements Exception {
  final String executable;
  final List<String> arguments;
  final int exitCode;

  ProcessFailed(this.executable, this.arguments, this.exitCode);

  // coverage:ignore-start
  @override
  String toString() => 'ProcessFailed: $executable ${arguments.join(' ')} '
      'failed with exit code $exitCode';
  // coverage:ignore-end
}

class ProcessAdapter {
  final IOSink _stderr;
  final _logger = Logger('$ProcessAdapter');

  ProcessAdapter(this._stderr);

  Stream<String> streamLines(
    String executable,
    List<String> arguments, {
    int? expectedExitCode = 0,
  }) async* {
    final logLine = _logLine(executable, arguments);
    _logger.finer('Streaming lines $logLine...');
    final proc = await Process.start(
      executable,
      arguments,
    );

    final stderrSub = proc.stderr
        .transform(systemEncoding.decoder)
        .transform(const LineSplitter())
        .listen(_stderr.writeln);

    try {
      yield* proc.stdout
          .transform(systemEncoding.decoder)
          .transform(const LineSplitter());

      final exitCode = await proc.exitCode;
      _logger.finer(
        '$logLine completed with exit code: $exitCode',
      );
      if (expectedExitCode != null) {
        if (exitCode != expectedExitCode) {
          throw ProcessFailed(executable, arguments, exitCode);
        }
      }
    } finally {
      await stderrSub.cancel();
    }
  }

  String _logLine(String executable, List<String> arguments) =>
      '<<$executable ${arguments.join(' ')}>>';
}
