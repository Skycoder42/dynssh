import 'dart:io';

import 'package:dynssh/src/cli/options.dart';
import 'package:test/test.dart';

void main() {
  group('$Options', () {
    final homeDir = Directory(Platform.environment['HOME']!);

    test('sets correct defaults', () {
      final argParser = Options.buildArgParser();

      expect(argParser.defaultFor('host'), InternetAddress.anyIPv4.address);
      expect(argParser.defaultFor('port'), '80');
      expect(
        argParser.defaultFor('api-key-path'),
        '${homeDir.path}/.config/dynssh/api-keys.json',
      );
      expect(argParser.defaultFor('ssh-directory'), '${homeDir.path}/.ssh');
      expect(argParser.defaultFor('log-level'), 'info');

      //TODO mock posix
    });
  });
}
