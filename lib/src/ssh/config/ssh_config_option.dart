import 'ssh_config_entry.dart';

class SshConfigOption extends SshConfigEntry {
  final String keyword;

  final List<String> arguments;

  SshConfigOption(this.keyword, this.arguments, [super.raw]);

  @override
  String create({required int indentation}) {
    final buffer = StringBuffer();
    if (indentation > 0) {
      buffer.write(' ' * indentation);
    } else if (indentation < 0) {
      buffer.write('\t' * -1 * indentation);
    }

    buffer.write(keyword);
    for (final argument in arguments) {
      buffer.write(' ');
      if (argument.contains(RegExp(r'\w'))) {
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
