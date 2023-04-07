// coverage:ignore-file

import 'package:posix/posix.dart' as posix;
import 'package:riverpod/riverpod.dart';

// coverage:ignore-start
final posixAdapterProvider = Provider(
  (ref) => const PosixAdapter(),
);
// coverage:ignore-end

class PosixAdapter {
  const PosixAdapter();
  bool get isRoot => posix.geteuid() == 0;
}
