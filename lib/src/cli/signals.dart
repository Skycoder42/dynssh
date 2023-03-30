import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
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
    final logger = Logger('signals.${arg.signal}');
    final sub = arg.signal.watch().listen(
      (signal) {
        // ignore: avoid_print
        logger.finer('signal received! - closing application');
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
    Logger('signals.$signal').finer('Registering signal handler');
    read(_signalProvider(_SignalInfo(signal, dispose)));
  }
}
