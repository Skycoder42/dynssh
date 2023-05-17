// ignore_for_file: unnecessary_lambdas

import 'dart:convert';
import 'dart:io';

import 'package:dart_test_tools/test.dart';
import 'package:dynssh/src/config/config.dart';
import 'package:dynssh/src/ssh/config/ssh_config.dart';
import 'package:dynssh/src/ssh/config/ssh_config_comment.dart';
import 'package:dynssh/src/ssh/config/ssh_config_entry.dart';
import 'package:dynssh/src/ssh/config/ssh_config_globals.dart';
import 'package:dynssh/src/ssh/config/ssh_config_host.dart';
import 'package:dynssh/src/ssh/config/ssh_config_option.dart';
import 'package:dynssh/src/ssh/config/ssh_config_section.dart';
import 'package:dynssh/src/ssh/ssh_config_parser.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockConfig extends Mock implements Config {}

class MockFile extends Mock implements File {}

void main() {
  group('$SshConfigParser', () {
    final mockConfig = MockConfig();
    final mockSshConfigFile = MockFile();

    late SshConfigParser sut;

    setUp(() {
      reset(mockConfig);
      reset(mockSshConfigFile);

      when(() => mockSshConfigFile.path).thenReturn('path');

      when(() => mockConfig.sshFile(any())).thenReturn(mockSshConfigFile);

      sut = SshConfigParser(mockConfig);
    });

    group('parse', () {
      test('returns empty config if file does not exist', () async {
        when(() => mockSshConfigFile.existsSync()).thenReturn(false);

        final result = await sut.parse();

        expect(result.globals.entries, isEmpty);
        expect(result.hosts, isEmpty);

        verifyInOrder([
          () => mockConfig.sshFile('config'),
          () => mockSshConfigFile.path,
          () => mockSshConfigFile.existsSync(),
          () => mockSshConfigFile.path,
        ]);
      });

      testData<(String, SshConfig)>(
        'correctly parses ssh config',
        [
          ('', SshConfig(SshConfigGlobals([]), [])),
          (
            'Key',
            SshConfig(SshConfigGlobals([SshConfigOption('Key', [])]), [])
          ),
          (
            '''
Key1 Value11 Value12
#Key2 Value2
Key3 Value3

# Key 4 Value 4
''',
            SshConfig(
              SshConfigGlobals([
                SshConfigOption('key1', ['Value11', 'Value12']),
                SshConfigComment('Key2 Value2'),
                SshConfigOption('key3', ['Value3']),
                SshConfigComment.empty(),
                SshConfigComment('Key 4 Value 4'),
              ]),
              [],
            )
          ),
        ],
        (fixture) async {
          when(() => mockSshConfigFile.existsSync()).thenReturn(true);
          when(() => mockSshConfigFile.openRead())
              .thenStream(Stream.value(utf8.encode(fixture.$1)));

          final result = await sut.parse();

          expect(result, _sshConfigEquals(fixture.$2));

          verifyInOrder([
            () => mockConfig.sshFile('config'),
            () => mockSshConfigFile.path,
            () => mockSshConfigFile.existsSync(),
            () => mockSshConfigFile.openRead(),
          ]);
        },
      );
    });
  });
}

Matcher _sshConfigEquals(SshConfig config) => isA<SshConfig>()
    .having((m) => m.globals, 'globals', _sshGlobalsEquals(config.globals))
    .having(
      (m) => m.hosts,
      'hosts',
      orderedEquals(config.hosts.map(_sshHostEquals)),
    );

Matcher _sshGlobalsEquals(SshConfigGlobals globals) => allOf(
      isA<SshConfigGlobals>(),
      _sshConfigSectionEquals(globals),
    );

Matcher _sshHostEquals(SshConfigHost host) => allOf(
      isA<SshConfigHost>(),
      _sshOptionEquals(host),
      _sshConfigSectionEquals(host),
    );

Matcher _sshConfigSectionEquals(SshConfigSection section) =>
    isA<SshConfigSection>().having(
      (m) => m.entries,
      'entries',
      orderedEquals(section.entries.map(_sshEntryEquals)),
    );

Matcher _sshOptionEquals(SshConfigOption option) => isA<SshConfigOption>()
    .having((m) => m.keyword, 'keyword', option.keyword)
    .having((m) => m.arguments, 'arguments', option.arguments);

Matcher _sshCommentEquals(SshConfigComment comment) => isA<SshConfigComment>()
    .having((m) => m.comment, 'comment', comment.comment);

Matcher _sshEntryEquals(SshConfigEntry entry) => switch (entry) {
      SshConfigOption() => _sshOptionEquals(entry),
      SshConfigComment() => _sshCommentEquals(entry),
      _ => isNot(anything)
    };
