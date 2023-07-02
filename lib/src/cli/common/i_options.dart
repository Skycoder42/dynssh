import 'dart:io';

import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

import '../../adapter/posix_adapter.dart';

abstract interface class IOptions {
  Level get logLevel;

  bool get help;

  void validate();

  void logAll(Logger logger);

  @internal
  static String apiKeyPathDefault(PosixAdapter posixAdapter) {
    const pathSuffix = 'dynssh/api-keys.json';
    if (posixAdapter.isRoot) {
      return '/etc/$pathSuffix';
    } else {
      final homePath = Platform.environment['HOME'];
      if (homePath == null) {
        return Directory.current.path;
      }

      return Directory(homePath)
          .uri
          .resolve('.config/$pathSuffix')
          .toFilePath();
    }
  }
}

@internal
Level logLevelFromString(String level) =>
    Level.LEVELS.singleWhere((element) => element.name == level.toUpperCase());
