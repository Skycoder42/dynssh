import 'ssh_config_entry.dart';

class SshConfigOption extends SshConfigEntry {
  final String _keyword;

  final List<String> arguments;

  SshConfigOption(this._keyword, List<String> arguments, [super.raw])
      : arguments = List.unmodifiable(arguments);

  String get keyword => _keyword.toLowerCase();

  @override
  String create({required int indentation}) {
    final buffer = StringBuffer();
    writeIndentation(buffer, indentation);

    buffer.write(_keyword);
    for (final argument in arguments) {
      buffer.write(' ');
      if (argument.contains(RegExp(r'\s'))) {
        buffer
          ..write('"')
          ..write(argument)
          ..write('"');
      } else {
        buffer.write(argument);
      }
    }

    return buffer.toString();
  }
}
