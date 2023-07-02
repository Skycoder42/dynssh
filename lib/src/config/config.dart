import 'dart:convert';
import 'dart:io';

import 'package:riverpod/riverpod.dart';

import '../cli/dynssh/options.dart';
import '../models/api_key_config.dart';

// coverage:ignore-start
final configProvider = Provider(
  (ref) => Config(),
);
// coverage:ignore-end

class Config {
  late final Options _cliOptions;

  Config();

  InternetAddress get host => InternetAddress(_cliOptions.host);

  int get port => _cliOptions.port;

  File sshFile(String name) =>
      File.fromUri(Directory(_cliOptions.sshDirectory).uri.resolve(name));

  Future<String?> findApiKey(String host) async {
    final apiKeyFile = File(_cliOptions.apiKeyPath);
    if (!apiKeyFile.existsSync()) {
      return null;
    }

    final apiKeyConfig = await apiKeyFile
        .openRead()
        .transform(utf8.decoder)
        .transform(json.decoder)
        .cast<Map<String, dynamic>>()
        .map(ApiKeyConfig.fromJson)
        .single;

    return apiKeyConfig.apiKeys[host];
  }

  // ignore: use_setters_to_change_properties
  void initialize(Options cliOptions) {
    _cliOptions = cliOptions;
  }
}
