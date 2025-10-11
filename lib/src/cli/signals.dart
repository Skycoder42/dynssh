import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'signals.g.dart';

typedef _SignalInfo = ({ProcessSignal signal, void Function() callback});

@Riverpod(keepAlive: true)
StreamSubscription<ProcessSignal> _signal(Ref ref, _SignalInfo info) {
  final logger = Logger('signals.${info.signal}');
  final sub = info.signal.watch().listen((signal) {
    logger.finer('signal received! - closing application');
    info.callback();
  }, cancelOnError: true);
  ref.onDispose(sub.cancel);
  return sub;
}

extension ProviderContainerX on ProviderContainer {
  void registerTerminationFor(ProcessSignal signal) {
    Logger('signals.$signal').finer('Registering signal handler');
    read(_signalProvider((signal: signal, callback: dispose)));
  }
}
