// coverage:ignore-file

import 'package:posix/posix.dart' as posix;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'posix_adapter.g.dart';

// coverage:ignore-start
@riverpod
PosixAdapter posixAdapter(Ref ref) => const PosixAdapter();
// coverage:ignore-end

class PosixAdapter {
  const PosixAdapter();
  bool get isRoot => posix.geteuid() == 0;
}
