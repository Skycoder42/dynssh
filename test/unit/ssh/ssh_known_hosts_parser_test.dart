import 'dart:io';

import 'package:dart_test_tools/test.dart';
import 'package:dynssh/src/config/config.dart';
import 'package:dynssh/src/ssh/ssh_known_hosts_parser.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:tuple/tuple.dart';

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

    group('getHostKeysFromLines', () {});

    group('getHostKeys', () {
      final mockSshKnownHostsFile = MockFile();

      setUp(() {
        reset(mockSshKnownHostsFile);

        when(() => mockConfig.sshFile(any())).thenReturn(mockSshKnownHostsFile);
      });

      testData<Tuple3<List<String>, bool, Map<String, String>>>(
        'extracts relevant host keys',
        const [
          Tuple3([], false, {}),
          Tuple3(['# $testHost type key'], false, {}),
          Tuple3(['other.$testHost type key'], false, {}),
          Tuple3(['$testHost type'], false, {}),
          Tuple3(['$testHost type key'], false, {'type': 'key'}),
          Tuple3(['$testHost type key extra'], false, {'type': 'key extra'}),
          Tuple3(['$testHost type key'], true, {}),
          Tuple3(['$testHost:$testPort type key'], true, {}),
          Tuple3(['[$testHost]:$testPort type key'], true, {'type': 'key'}),
          Tuple3(['$testHost type key'], false, {'type': 'key'}),
          Tuple3(
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
          // TODO add more cases
        ],
        (fixture) async {
          expect(
            sut.getHostKeysFromLines(
              Stream.fromIterable(fixture.item1),
              testHost,
              fixture.item2 ? testPort : null,
            ),
            completion(fixture.item3),
          );
        },
      );
    });
  });
}
