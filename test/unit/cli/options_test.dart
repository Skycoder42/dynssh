import 'dart:io';

import 'package:dart_test_tools/test.dart';
import 'package:dynssh/src/adapter/posix_adapter.dart';
import 'package:dynssh/src/cli/dynssh/options.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockPosixAdapter extends Mock implements PosixAdapter {}

void main() {
  group('$Options', () {
    final homeDir = Directory(Platform.environment['HOME']!);

    final mockPosixAdapter = MockPosixAdapter();

    setUp(() {
      reset(mockPosixAdapter);

      when(() => mockPosixAdapter.isRoot).thenReturn(false);
    });

    test('sets correct defaults (non-root)', () {
      final argParser = Options.buildArgParser(mockPosixAdapter);

      expect(argParser.defaultFor('host'), InternetAddress.anyIPv4.address);
      expect(argParser.defaultFor('port'), '80');
      expect(
        argParser.defaultFor('api-key-path'),
        '${homeDir.path}/.config/dynssh/api-keys.json',
      );
      expect(argParser.defaultFor('ssh-directory'), '${homeDir.path}/.ssh');
      expect(argParser.defaultFor('log-level'), 'info');
    });

    test('sets correct defaults (root)', () {
      when(() => mockPosixAdapter.isRoot).thenReturn(true);

      final argParser = Options.buildArgParser(mockPosixAdapter);

      expect(argParser.defaultFor('host'), InternetAddress.anyIPv4.address);
      expect(argParser.defaultFor('port'), '80');
      expect(
        argParser.defaultFor('api-key-path'),
        '/etc/dynssh/api-keys.json',
      );
      expect(argParser.defaultFor('ssh-directory'), '/etc/ssh');
      expect(argParser.defaultFor('log-level'), 'info');
    });

    testData<Level?>(
      'can parse all log levels',
      const [null, ...Level.LEVELS],
      (fixture) {
        final args = [
          if (fixture != null) '-l${fixture.name.toLowerCase()}',
        ];

        final parser = Options.buildArgParser(mockPosixAdapter);
        final options = Options.parseOptions(parser.parse(args));

        expect(options.logLevel, fixture ?? Level.INFO);
      },
    );
  });
}
