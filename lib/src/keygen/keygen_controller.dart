import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

import '../cli/keygen/keygen_options.dart';
import '../models/api_key_config.dart';
import 'key_generator.dart';

// coverage:ignore-start
final keygenControllerProvider = Provider(
  (ref) => KeygenController(
    ref.watch(keyGeneratorProvider),
  ),
);
// coverage:ignore-end

class KeygenController {
  final KeyGenerator _keyGenerator;
  final _logger = Logger('$KeygenController');

  KeygenController(this._keyGenerator);

  Future<void> generateKeys(KeygenOptions options) async {
    _logger.fine('Loading API-Keys from ${options.apiKeyPath}...');
    var apiKeyConfig = await _loadApiKeyConfig(options.apiKeyPath);

    for (final hostName in options.hostNames) {
      _logger.fine('Generating key for $hostName...');
      apiKeyConfig = await _generateKey(apiKeyConfig, hostName, options);
    }

    _logger.fine(
      'Successfully generated all keys! Saving to ${options.apiKeyPath}',
    );
    await _saveApiKeyConfig(options.apiKeyPath, apiKeyConfig);
    _logger.info('Key generation complete');
  }

  Future<ApiKeyConfig> _loadApiKeyConfig(String path) async {
    final apiKeyFile = File(path);
    if (!apiKeyFile.existsSync()) {
      throw Exception('NOT FOUND'); // TODO
    }

    return apiKeyFile
        .openRead()
        .transform(utf8.decoder)
        .transform(json.decoder)
        .cast<Map<String, dynamic>>()
        .map(ApiKeyConfig.fromJson)
        .single;
  }

  Future<void> _saveApiKeyConfig(
    String path,
    ApiKeyConfig apiKeyConfig,
  ) async {
    final apiKeyFile = File(path);

    const jsonEncoder = JsonEncoder.withIndent('  ');
    final apiKeyFileContent = jsonEncoder.convert(apiKeyConfig);
    await apiKeyFile.writeAsString(apiKeyFileContent);
  }

  Future<ApiKeyConfig> _generateKey(
    ApiKeyConfig apiKeyConfig,
    String hostName,
    KeygenOptions options,
  ) async {
    if (!options.overwrite && apiKeyConfig.apiKeys.containsKey(hostName)) {
      throw Exception('OVERWRITE'); // TODO
    }

    final key = _keyGenerator.generateKey(options.keyLength);

    if (options.printKeys) {
      _logger.info('Generated Key for $hostName: $key');
    } else {
      _logger.info('Generated key for $hostName');
    }

    return apiKeyConfig.copyWith(
      apiKeys: {
        ...apiKeyConfig.apiKeys,
        hostName: key,
      },
    );
  }
}
