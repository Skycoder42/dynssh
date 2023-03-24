import 'dart:async';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:riverpod/riverpod.dart';

@immutable
class _SignalInfo {
  final ProcessSignal signal;
  final void Function() callback;

  const _SignalInfo(this.signal, this.callback);
}

final _signalProvider = ProviderFamily<StreamSubscription, _SignalInfo>(
  (ref, arg) {
    final sub = arg.signal.watch().listen(
      (signal) {
        // ignore: avoid_print
        print('$signal requested - closing application');
        arg.callback();
      },
      cancelOnError: true,
    );
    ref.onDispose(sub.cancel);
    return sub;
  },
);

extension ProviderContainerX on ProviderContainer {
  void registerTerminationFor(ProcessSignal signal) {
    read(_signalProvider(_SignalInfo(signal, dispose)));
  }
}
