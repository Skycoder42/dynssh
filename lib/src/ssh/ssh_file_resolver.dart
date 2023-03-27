import 'dart:io';

import 'package:riverpod/riverpod.dart';

// coverage:ignore-start
final sshFileResolverProvider = Provider(
  (ref) => SshFileResolver(),
);
// coverage:ignore-end

class SshFileResolver {
  Directory get sshDirectory {
    final home = Platform.environment['HOME'];
    if (home == null) {
      throw Exception('HOME environment variable is not defined!');
    }
    final homeDir = Directory(home);
    return Directory.fromUri(homeDir.uri.resolve('.ssh'));
  }

  File getSshFile(String fileName) =>
      File.fromUri(sshDirectory.uri.resolve(fileName));
}
