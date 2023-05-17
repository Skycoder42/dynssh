import 'package:dart_test_tools/test.dart';
import 'package:dynssh/src/adapter/process_adapter.dart';
import 'package:dynssh/src/ssh/ssh_keyscan.dart';
import 'package:dynssh/src/ssh/ssh_known_hosts_parser.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockProcessAdapter extends Mock implements ProcessAdapter {}

class MockSshKnownHostsParser extends Mock implements SshKnownHostsParser {}

void main() {
  setUpAll(() {
    registerFallbackValue(const Stream<String>.empty());
  });

  group('$SshKeyscan', () {
    const testHost = 'test.example.com';

    final mockProcessAdapter = MockProcessAdapter();
    final mockSshKnownHostsParser = MockSshKnownHostsParser();

    late SshKeyscan sut;

    setUp(() {
      reset(mockProcessAdapter);
      reset(mockSshKnownHostsParser);

      sut = SshKeyscan(mockProcessAdapter, mockSshKnownHostsParser);
    });

    testData<(int?, List<String>)>(
      'invokes ssh-keyscan with correct arguments and parses result',
      const [
        (null, [testHost]),
        (42, ['-p', '42', testHost]),
      ],
      (fixture) async {
        final testStream = Stream.value('');
        const testResult = {'a': '1', 'b': '2'};

        when(() => mockProcessAdapter.streamLines(any(), any()))
            .thenStream(testStream);
        when(
          () => mockSshKnownHostsParser.getHostKeysFromLines(
            any(),
            any(),
            any(),
          ),
        ).thenReturnAsync(testResult);

        final result = await sut.scanHost(testHost, fixture.$1);
        expect(result, testResult);

        verifyInOrder([
          () => mockProcessAdapter.streamLines(
                'ssh-keyscan',
                fixture.$2,
              ),
          () => mockSshKnownHostsParser.getHostKeysFromLines(
                any(that: same(testStream)),
                testHost,
                fixture.$1,
              ),
        ]);
      },
    );
  });
}
