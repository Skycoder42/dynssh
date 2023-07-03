// ignore_for_file: unnecessary_lambdas

import 'dart:async';

import 'package:dart_test_tools/test.dart';
import 'package:dynssh/src/dynssh/dynssh_controller.dart';
import 'package:dynssh/src/models/host_update.dart';
import 'package:dynssh/src/ssh/config/ssh_config.dart';
import 'package:dynssh/src/ssh/config/ssh_config_host.dart';
import 'package:dynssh/src/ssh/ssh_config_parser.dart';
import 'package:dynssh/src/ssh/ssh_keyscan.dart';
import 'package:dynssh/src/ssh/ssh_known_hosts_parser.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockSshConfigParser extends Mock implements SshConfigParser {}

class MockSshKnownHostsParser extends Mock implements SshKnownHostsParser {}

class MockSshKeyscan extends Mock implements SshKeyscan {}

class MockSshConfig extends Mock implements SshConfig {}

class MockSshConfigHost extends Mock implements SshConfigHost {}

void main() {
  setUpAll(() {
    registerFallbackValue(MockSshConfig());
  });

  group('$DynsshController', () {
    final mockSshConfigParser = MockSshConfigParser();
    final mockSshKnownHostsParser = MockSshKnownHostsParser();
    final mockSshKeyscan = MockSshKeyscan();
    final mockSshConfig = MockSshConfig();
    final mockSshConfigHost = MockSshConfigHost();

    late DynsshController sut;

    setUp(() async {
      reset(mockSshConfigParser);
      reset(mockSshKnownHostsParser);
      reset(mockSshKeyscan);
      reset(mockSshConfig);
      reset(mockSshConfigHost);

      when(() => mockSshConfigParser.parse()).thenReturnAsync(mockSshConfig);
      when(() => mockSshConfig.findHost(any())).thenReturn(mockSshConfigHost);

      when(() => mockSshConfigParser.update(any())).thenReturnAsync(null);
      when(
        () => mockSshKnownHostsParser.replaceHost(
          oldHost: any(named: 'oldHost'),
          oldPort: any(named: 'oldPort'),
          newHost: any(named: 'newHost'),
          newPort: any(named: 'newPort'),
        ),
      ).thenReturnAsync(null);

      sut = DynsshController(
        mockSshConfigParser,
        mockSshKnownHostsParser,
        mockSshKeyscan,
      );
    });

    tearDown(() {
      verifyNoMoreInteractions(mockSshConfigParser);
      verifyNoMoreInteractions(mockSshKnownHostsParser);
      verifyNoMoreInteractions(mockSshKeyscan);
      verifyNoMoreInteractions(mockSshConfig);
      verifyNoMoreInteractions(mockSshConfigHost);
    });

    group('updateHost', () {
      const testOldAddress = '2.4.6.8';
      const testHostUpdate = HostUpdate(
        hostname: 'test-hostname',
        ipAddress: '1.2.3.4',
      );

      test('runs update synchronized', () async {
        when(() => mockSshConfigParser.parse())
            .thenReturnAsync(Completer<SshConfig>().future);

        final f1 = sut.updateHost(testHostUpdate);
        final f2 = sut.updateHost(testHostUpdate);

        expect(f1, doesNotComplete);
        expect(f2, doesNotComplete);

        await Future.delayed(const Duration(seconds: 1));

        verify(() => mockSshConfigParser.parse()).called(1);
      });

      test('rejects update if host config cannot be found', () async {
        when(() => mockSshConfig.findHost(any())).thenReturn(null);

        final result = await sut.updateHost(testHostUpdate);

        expect(result, isFalse);

        verifyInOrder([
          () => mockSshConfigParser.parse(),
          () => mockSshConfig.findHost(testHostUpdate.hostname),
        ]);
      });

      test('rejects update if there are no known host keys for host', () async {
        when(() => mockSshConfigHost.patterns).thenReturn([testOldAddress]);
        when(() => mockSshKnownHostsParser.getHostKeys(any(), any()))
            .thenReturnAsync(const {});

        final result = await sut.updateHost(testHostUpdate);

        expect(result, isFalse);

        verifyInOrder([
          () => mockSshConfigParser.parse(),
          () => mockSshConfig.findHost(testHostUpdate.hostname),
          () => mockSshConfigHost['HostName'],
          () => mockSshConfigHost.patterns,
          () => mockSshConfigHost['Port'],
          () => mockSshKnownHostsParser.getHostKeys(testOldAddress),
        ]);
      });

      test('rejects update if host keys are not identical', () async {
        const oldHostKeys = {
          'a': 'key1',
          'b': 'key2',
        };
        const otherHostKeys = {
          'a': 'key1',
          'b': 'key-other',
        };

        when(() => mockSshConfigHost['HostName']).thenReturn([testOldAddress]);
        when(() => mockSshKnownHostsParser.getHostKeys(any(), any()))
            .thenReturnAsync(oldHostKeys);
        when(() => mockSshKeyscan.scanHost(any(), any()))
            .thenReturnAsync(otherHostKeys);

        final result = await sut.updateHost(testHostUpdate);

        expect(result, isFalse);

        verifyInOrder([
          () => mockSshConfigParser.parse(),
          () => mockSshConfig.findHost(testHostUpdate.hostname),
          () => mockSshConfigHost['HostName'],
          () => mockSshConfigHost['Port'],
          () => mockSshKnownHostsParser.getHostKeys(testOldAddress),
          () => mockSshKeyscan.scanHost(testHostUpdate.ipAddress),
        ]);
      });

      test('accepts update if host keys are identical', () async {
        const hostKeys = {
          'a': 'key1',
          'b': 'key2',
        };

        when(() => mockSshConfigHost['HostName']).thenReturn([testOldAddress]);
        when(() => mockSshConfigHost['Port']).thenReturn(['123']);
        when(() => mockSshKnownHostsParser.getHostKeys(any(), any()))
            .thenReturnAsync(hostKeys);
        when(() => mockSshKeyscan.scanHost(any(), any()))
            .thenReturnAsync(hostKeys);

        final result = await sut.updateHost(testHostUpdate);

        expect(result, isTrue);

        verifyInOrder([
          () => mockSshConfigParser.parse(),
          () => mockSshConfig.findHost(testHostUpdate.hostname),
          () => mockSshConfigHost['HostName'],
          () => mockSshConfigHost['Port'],
          () => mockSshKnownHostsParser.getHostKeys(testOldAddress, 123),
          () => mockSshKeyscan.scanHost(testHostUpdate.ipAddress, 123),
          () => mockSshConfigHost['HostName'] = [testHostUpdate.ipAddress],
          () => mockSshConfigParser.update(mockSshConfig),
          () => mockSshKnownHostsParser.replaceHost(
                oldHost: testOldAddress,
                oldPort: 123,
                newHost: testHostUpdate.ipAddress,
                newPort: 123,
              ),
        ]);
      });
    });
  });
}
