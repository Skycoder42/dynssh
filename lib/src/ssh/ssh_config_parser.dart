import 'dart:convert';
import 'dart:io';

import 'package:riverpod/riverpod.dart';

import 'config/ssh_config.dart';
import 'config/ssh_config_comment.dart';
import 'config/ssh_config_globals.dart';
import 'config/ssh_config_host.dart';
import 'config/ssh_config_option.dart';
import 'config/ssh_config_section.dart';
import 'ssh_file_resolver.dart';

// coverage:ignore-start
final sshConfigParserProvider = Provider(
  (ref) => SshConfigParser(
    ref.watch(sshFileResolverProvider),
  ),
);
// coverage:ignore-end

class SshConfigParser {
  final SshFileResolver _sshFileResolver;

  SshConfigParser(this._sshFileResolver);

  Future<SshConfig> parse() async {
    final sshConfigFile = _getSshConfigFile();
    if (!sshConfigFile.existsSync()) {
      return SshConfig(SshConfigGlobals([]), []);
    }

    final configStream = sshConfigFile
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    return _parseConfigLines(configStream);
  }

  Future<void> update(SshConfig config) async {
    final sshConfigFile = _getSshConfigFile();
    final sshConfigFileSink = sshConfigFile.openWrite();
    try {
      config.writeConfig().forEach(sshConfigFileSink.writeln);
    } finally {
      await sshConfigFileSink.flush();
      await sshConfigFileSink.close();
    }
  }

  File _getSshConfigFile() => _sshFileResolver.getSshFile('config');

  Future<SshConfig> _parseConfigLines(Stream<String> configStream) async {
    final globals = SshConfigGlobals([]);
    final hosts = <SshConfigHost>[];

    SshConfigSection currentSection = globals;
    await for (final rawLine in configStream) {
      final trimmedLine = rawLine.trim();

      // handle whitespace only lines
      if (trimmedLine.isEmpty) {
        currentSection.entries.add(SshConfigComment.empty(rawLine));
        continue;
      }

      // handle comment lines
      if (trimmedLine.startsWith('#')) {
        currentSection.entries.add(
          SshConfigComment(
            trimmedLine.substring(1).trimLeft(),
            rawLine,
          ),
        );
        continue;
      }

      // handle single keyword lines
      final firstWhitespace = trimmedLine.indexOf(RegExp(r'\s'));
      if (firstWhitespace == -1) {
        currentSection.entries.add(SshConfigOption(trimmedLine, [], rawLine));
        continue;
      }

      // extract keyword and arguments
      final keyword = trimmedLine.substring(0, firstWhitespace);
      final arguments = _collectArguments(trimmedLine, firstWhitespace);

      // check if host or option
      if (keyword.toLowerCase() == 'host') {
        final hostSection = SshConfigHost(arguments, [], rawLine);
        hosts.add(hostSection);
        currentSection = hostSection;
      } else {
        currentSection.entries.add(
          SshConfigOption(keyword, arguments, rawLine),
        );
      }
    }

    return SshConfig(globals, hosts);
  }

  List<String> _collectArguments(String trimmedLine, int firstWhitespace) {
    final arguments = <String>[];

    var isQuoted = false;
    StringBuffer? currentArgument;
    for (var i = firstWhitespace + 1; i < trimmedLine.length; ++i) {
      final char = trimmedLine[i];

      if (currentArgument == null) {
        if (char.trim().isEmpty) {
          // skip
        } else if (char == '"') {
          isQuoted = true;
          currentArgument = StringBuffer();
        } else {
          isQuoted = false;
          currentArgument = StringBuffer(char);
        }
      } else {
        if ((char.trim().isEmpty && !isQuoted) || (char == '"' && isQuoted)) {
          arguments.add(currentArgument.toString());
          currentArgument = null;
        } else {
          currentArgument.write(char);
        }
      }
    }

    if (currentArgument != null) {
      arguments.add(currentArgument.toString());
    }

    return arguments;
  }
}
