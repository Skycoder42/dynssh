import 'package:riverpod/riverpod.dart';

// coverage:ignore-start
final sshConfigParserProvider = Provider(
  (ref) => SshConfigParser(),
);
// coverage:ignore-end

class SshConfigParser {}
