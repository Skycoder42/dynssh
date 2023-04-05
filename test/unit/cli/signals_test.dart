import 'dart:async';
import 'dart:io';

import 'package:dart_test_tools/test.dart';
import 'package:dynssh/src/cli/signals.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';

class MockProcessSignal extends Mock implements ProcessSignal {}

void main() {
  group('ProviderContainerX', () {
    final mockProcessSignal = MockProcessSignal();

    var disposed = false;
    final disposedProvider = Provider<void>(
      (ref) => ref.onDispose(() => disposed = true),
    );

    late ProviderContainer sut;

    setUp(() {
      reset(mockProcessSignal);
      disposed = false;

      sut = ProviderContainer()..read(disposedProvider);
    });

    test('signal causes the container to be dispose', () async {
      when(mockProcessSignal.watch).thenStream(Stream.value(mockProcessSignal));
      sut.registerTerminationFor(mockProcessSignal);

      await Future<void>.delayed(Duration.zero);

      expect(disposed, isTrue);
    });
  });
}
