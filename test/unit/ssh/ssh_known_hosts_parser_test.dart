// ignore_for_file: unnecessary_lambdas

import 'dart:convert';
import 'dart:io';

import 'package:dart_test_tools/test.dart';
import 'package:dynssh/src/config/config.dart';
import 'package:dynssh/src/ssh/ssh_known_hosts_parser.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockConfig extends Mock implements Config {}

class MockFile extends Mock implements File {}

void main() {
  group('$SshKnownHostsParser', () {
    const testHost = 'test.example.com';
    const testPort = 1234;

    final mockConfig = MockConfig();

    late SshKnownHostsParser sut;

    setUp(() {
      reset(mockConfig);

      sut = SshKnownHostsParser(mockConfig);
    });

    group('getHostKeysFromLines', () {
      testData<(List<String>, bool, Map<String, String>)>(
        'extracts relevant host keys',
        const [
          ([], false, {}),
          (['# $testHost type key'], false, {}),
          ([testHost], false, {}),
          (['$testHost type'], false, {}),
          (['$testHost type key'], false, {'type': 'key'}),
          (['$testHost type key extra'], false, {'type': 'key extra'}),
          (
            ['$testHost type key   extra'],
            false,
            {'type': 'key   extra'},
          ),
          (['other.$testHost type key'], false, {}),
          (['$testHost type key'], true, {}),
          (['$testHost:$testPort type key'], true, {}),
          (['[$testHost]:$testPort type key'], true, {'type': 'key'}),
          (['[other.$testHost]:$testPort type key'], true, {}),
          (['$testHost type key'], false, {'type': 'key'}),
          (
            [
              '$testHost typeA key1',
              '$testHost typeB key2',
              '$testHost typeC key3',
            ],
            false,
            {
              'typeA': 'key1',
              'typeB': 'key2',
              'typeC': 'key3',
            },
          ),
          (
            [
              '$testHost typeA key1',
              'other.$testHost typeB key2',
              '[$testHost]:$testPort typeC key3',
            ],
            false,
            {'typeA': 'key1'},
          ),
        ],
        (fixture) async {
          expect(
            sut.getHostKeysFromLines(
              Stream.fromIterable(fixture.$1),
              testHost,
              fixture.$2 ? testPort : null,
            ),
            completion(fixture.$3),
          );
        },
      );
    });

    group('getHostKeys', () {
      final mockSshKnownHostsFile = MockFile();

      setUp(() {
        reset(mockSshKnownHostsFile);

        when(() => mockSshKnownHostsFile.path).thenReturn('path');

        when(() => mockConfig.sshFile(any())).thenReturn(mockSshKnownHostsFile);
      });

      test('returns empty map if file does not exist', () async {
        when(() => mockSshKnownHostsFile.existsSync()).thenReturn(false);

        final result = await sut.getHostKeys(testHost);

        expect(result, isEmpty);

        verifyInOrder([
          () => mockConfig.sshFile('known_hosts'),
          () => mockSshKnownHostsFile.path,
          () => mockSshKnownHostsFile.existsSync(),
          () => mockSshKnownHostsFile.path,
        ]);
        verifyNoMoreInteractions(mockSshKnownHostsFile);
        verifyNoMoreInteractions(mockConfig);
      });

      test('reads config from file', () async {
        const testContent = '''
$testHost typeA key1
$testHost typeB key2
other.$testHost typeC key3
[$testHost]:$testPort typeD key4
''';

        when(() => mockSshKnownHostsFile.existsSync()).thenReturn(true);
        when(() => mockSshKnownHostsFile.openRead())
            .thenStream(Stream.value(utf8.encode(testContent)));

        final result = await sut.getHostKeys(testHost);

        expect(result, const {'typeA': 'key1', 'typeB': 'key2'});

        verifyInOrder([
          () => mockConfig.sshFile('known_hosts'),
          () => mockSshKnownHostsFile.path,
          () => mockSshKnownHostsFile.existsSync(),
          () => mockSshKnownHostsFile.openRead(),
        ]);
        verifyNoMoreInteractions(mockSshKnownHostsFile);
        verifyNoMoreInteractions(mockConfig);
      });
    });

    group('replaceHost', () {
      const newHost = 'new.example.com';
      const newPort = 4321;

      final mockSshKnownHostsFile = MockFile();

      setUp(() async {
        reset(mockSshKnownHostsFile);

        when(() => mockSshKnownHostsFile.path).thenReturn('path');
        when(() => mockSshKnownHostsFile.writeAsString(any()))
            .thenReturnAsync(mockSshKnownHostsFile);

        when(() => mockConfig.sshFile(any())).thenReturn(mockSshKnownHostsFile);
      });

      test('does nothing if file does not exist', () async {
        when(() => mockSshKnownHostsFile.existsSync()).thenReturn(false);

        await sut.replaceHost(
          oldHost: testHost,
          newHost: newHost,
        );

        verifyInOrder([
          () => mockConfig.sshFile('known_hosts'),
          () => mockSshKnownHostsFile.path,
          () => mockSshKnownHostsFile.existsSync(),
          () => mockSshKnownHostsFile.path,
        ]);
        verifyNoMoreInteractions(mockSshKnownHostsFile);
        verifyNoMoreInteractions(mockConfig);
      });

      testData<(String, bool, String?)>(
        'replaces old with new host',
        const [
          ('', false, null),
          ('other.host type key', false, null),
          ('$testHost type key', false, '$newHost type key'),
          (
            '[$testHost]:$testPort type key',
            true,
            '[$newHost]:$newPort type key'
          ),
          ('$testHost type key', true, null),
          ('[$testHost]:$testPort type key', false, null),
          ('other.$testHost type key', false, null),
          ('[other.$testHost]:$testPort type key', true, null),
          (
            '''
$testHost typeA key1
other.$testHost typeB key2
$testHost.other typeC key3
$testHost typeD key4
''',
            false,
            '''
$newHost typeA key1
other.$testHost typeB key2
$testHost.other typeC key3
$newHost typeD key4
'''
          ),
          (
            '''
[$testHost]:$testPort typeA key1
$testHost typeB key2
[$testHost]:$testPort typeC key3
''',
            true,
            '''
[$newHost]:$newPort typeA key1
$testHost typeB key2
[$newHost]:$newPort typeC key3
'''
          ),
        ],
        (fixture) async {
          when(() => mockSshKnownHostsFile.existsSync()).thenReturn(true);
          when(() => mockSshKnownHostsFile.readAsString())
              .thenReturnAsync(fixture.$1);

          await sut.replaceHost(
            oldHost: testHost,
            oldPort: fixture.$2 ? testPort : null,
            newHost: newHost,
            newPort: fixture.$2 ? newPort : null,
          );

          verifyInOrder([
            () => mockConfig.sshFile('known_hosts'),
            () => mockSshKnownHostsFile.path,
            () => mockSshKnownHostsFile.existsSync(),
            () => mockSshKnownHostsFile.readAsString(),
            () => mockSshKnownHostsFile.writeAsString(fixture.$3 ?? fixture.$1),
          ]);
        },
      );
    });
  });
}
