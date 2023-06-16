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

class TestSink extends StringBuffer implements IOSink {
  int flushed = 0;
  int closed = 0;

  @override
  Encoding encoding = utf8;

  @override
  void add(List<int> data) => throw UnimplementedError();

  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      throw UnimplementedError();

  @override
  Future addStream(Stream<List<int>> stream) => throw UnimplementedError();

  @override
  Future close() {
    ++closed;
    return Future.value();
  }

  @override
  Future get done => Future.value();

  @override
  Future flush() {
    ++flushed;
    return Future.value();
  }
}

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
        _configTestData.map((t) => (t.read, t.config)),
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

    group('update', () {
      testData<(SshConfig, String)>(
        'Creates SSH config from new configuration',
        _configTestData.map((t) => (t.config, t.write ?? t.read)),
        (fixture) async {
          final testSink = TestSink();
          when(() => mockSshConfigFile.openWrite()).thenReturn(testSink);

          await sut.update(fixture.$1);

          expect(testSink.flushed, 1);
          expect(testSink.closed, 1);
          expect(testSink.toString(), fixture.$2);
        },
      );

      testData<(String, String)>(
        'Updates SSH config from existing configuration',
        _configTestData.map((t) => (t.read, t.update ?? t.read)),
        (fixture) async {
          final testSink = TestSink();
          when(() => mockSshConfigFile.existsSync()).thenReturn(true);
          when(() => mockSshConfigFile.openRead())
              .thenStream(Stream.value(utf8.encode(fixture.$1)));
          when(() => mockSshConfigFile.openWrite()).thenReturn(testSink);

          final config = await sut.parse();
          await sut.update(config);

          expect(testSink.flushed, 1);
          expect(testSink.closed, 1);
          expect(testSink.toString(), fixture.$2);
        },
      );

      testData<(String, String)>(
        'Updates or creates config options in existing config',
        _configTestData.map((t) => (t.read, t.edit)),
        (fixture) async {
          final testSink = TestSink();
          when(() => mockSshConfigFile.existsSync()).thenReturn(true);
          when(() => mockSshConfigFile.openRead())
              .thenStream(Stream.value(utf8.encode(fixture.$1)));
          when(() => mockSshConfigFile.openWrite()).thenReturn(testSink);

          final config = await sut.parse();

          final key1 = config['Key1'];
          if (key1 != null) {
            config['Key1'] = const [];
          }
          config
            ..addComment('Very important')
            ..['Important'] = const ['a', 'b']
            ..addEmptyLine();

          final host =
              config.findHost(_testHost) ?? config.addHost([_testHost]);
          final key2 = host['Key2'];
          host
            ..['Key1'] = ['Value 111', if (key2 != null) 'extra']
            ..addEmptyLine()
            ..addComment('Value?')
            ..['Key42'] = const [];

          await sut.update(config);

          expect(testSink.flushed, 1);
          expect(testSink.closed, 1);
          expect(testSink.toString(), fixture.$2);
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

const _testHost = 'host1.example.com';
final _configTestData = [
  (
    read: '',
    config: SshConfig(SshConfigGlobals([]), []),
    write: null,
    update: null,
    edit: '''
# Very important
Important a b

Host $_testHost
    Key1 "Value 111"

    # Value?
    Key42
''',
  ),
  (
    read: 'Key',
    config: SshConfig(SshConfigGlobals([SshConfigOption('Key', [])]), []),
    write: 'Key\n',
    update: 'Key\n',
    edit: '''
Key
# Very important
Important a b

Host $_testHost
    Key1 "Value 111"

    # Value?
    Key42
''',
  ),
  (
    read: '''
Key1 Value11 Value12
#Key2 Value2
Key3 Value3

# Key 4 Value 4
Key5 Value51 # Value52
Host
Key6 "Value 61"   Value  "62"
''',
    config: SshConfig(
      SshConfigGlobals([
        SshConfigOption('key1', ['Value11', 'Value12']),
        SshConfigComment('Key2 Value2'),
        SshConfigOption('key3', ['Value3']),
        SshConfigComment.empty(),
        SshConfigComment('Key 4 Value 4'),
        SshConfigOption('key5', ['Value51', '#', 'Value52']),
        SshConfigOption('Host', []),
        SshConfigOption('key6', ['Value 61', 'Value', '62']),
      ]),
      [],
    ),
    write: '''
key1 Value11 Value12
# Key2 Value2
key3 Value3

# Key 4 Value 4
key5 Value51 # Value52
Host
key6 "Value 61" Value 62
''',
    update: null,
    edit: '''
Key1
#Key2 Value2
Key3 Value3

# Key 4 Value 4
Key5 Value51 # Value52
Host
Key6 "Value 61"   Value  "62"
# Very important
Important a b

Host $_testHost
    Key1 "Value 111"

    # Value?
    Key42
''',
  ),
  (
    read: '''
Key1 Value1

Host $_testHost
  Key1 Value1
  Key2 Value21
Host host2 host3
    Key2 Value22
#Host host23
Key3 Value3

Host host4
Host host5
Key5 Value5
''',
    config: SshConfig(
      SshConfigGlobals([
        SshConfigOption('Key1', ['Value1']),
        SshConfigComment.empty(),
      ]),
      [
        SshConfigHost([
          _testHost,
        ], [
          SshConfigOption('Key1', ['Value1']),
          SshConfigOption('Key2', ['Value21']),
        ]),
        SshConfigHost([
          'host2',
          'host3',
        ], [
          SshConfigOption('Key2', ['Value22']),
          SshConfigComment('Host host23'),
          SshConfigOption('Key3', ['Value3']),
          SshConfigComment.empty(),
        ]),
        SshConfigHost(
          [
            'host4',
          ],
          [],
        ),
        SshConfigHost([
          'host5',
        ], [
          SshConfigOption('Key5', ['Value5']),
        ]),
      ],
    ),
    write: '''
Key1 Value1

Host $_testHost
    Key1 Value1
    Key2 Value21
Host host2 host3
    Key2 Value22
    # Host host23
    Key3 Value3

Host host4
Host host5
    Key5 Value5
''',
    update: null,
    edit: '''
Key1

# Very important
Important a b

Host $_testHost
  Key1 "Value 111" extra
  Key2 Value21

  # Value?
  Key42
Host host2 host3
    Key2 Value22
#Host host23
Key3 Value3

Host host4
Host host5
Key5 Value5
''',
  ),
];
