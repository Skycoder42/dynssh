import 'dart:io';

import 'package:dynssh/src/adapter/process_adapter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockStdout extends Mock implements Stdout {}

void main() {
  group('$ProcessAdapter', () {
    final mockStderr = MockStdout();

    late ProcessAdapter sut;

    setUp(() {
      reset(mockStderr);

      sut = ProcessAdapter(mockStderr);
    });

    group('streamLines', () {
      test('streams lines of process output', () {
        final stream = sut.streamLines('bash', const [
          '-c',
          'echo line1; echo line2; echo; echo -n line3; echo line4',
        ]);

        expect(
          stream,
          emitsInOrder(<dynamic>[
            'line1',
            'line2',
            '',
            'line3line4',
            emitsDone,
          ]),
        );
      });

      test('forwards stderr to dart stderr', () async {
        final stream = sut.streamLines('bash', const [
          '-c',
          'echo out1; >&2 echo err1; echo out2; >&2 echo err2',
        ]);

        await stream.drain<void>();

        verifyInOrder([
          () => mockStderr.writeln('err1'),
          () => mockStderr.writeln('err2'),
        ]);
      });

      test('emits error on unexpected exit code', () {
        const arguments = ['-c', 'echo line1; exit 1'];
        final stream = sut.streamLines('bash', arguments);

        expect(
          stream,
          emitsInOrder(<dynamic>[
            'line1',
            emitsError(
              isA<ProcessFailed>()
                  .having((m) => m.executable, 'executable', 'bash')
                  .having((m) => m.arguments, 'arguments', arguments)
                  .having((m) => m.exitCode, 'exitCode', 1),
            ),
            emitsDone,
          ]),
        );
      });

      test('emits error on custom unexpected exit code', () {
        const arguments = ['-c', 'echo line1'];
        final stream = sut.streamLines(
          'bash',
          arguments,
          expectedExitCode: 42,
        );

        expect(
          stream,
          emitsInOrder(<dynamic>[
            'line1',
            emitsError(
              isA<ProcessFailed>()
                  .having((m) => m.executable, 'executable', 'bash')
                  .having((m) => m.arguments, 'arguments', arguments)
                  .having((m) => m.exitCode, 'exitCode', 0),
            ),
            emitsDone,
          ]),
        );
      });

      test('does not emit error if exit code validation is disabled', () {
        final stream = sut.streamLines(
          'bash',
          ['-c', 'echo line1; exit 12'],
          expectedExitCode: null,
        );

        expect(
          stream,
          emitsInOrder(<dynamic>[
            'line1',
            emitsDone,
          ]),
        );
      });
    });
  });
}
