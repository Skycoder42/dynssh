import 'ssh_config_entry.dart';
import 'ssh_config_option.dart';
import 'ssh_config_section.dart';

class SshConfigHost extends SshConfigOption
    with SshConfigSectionMixin
    implements SshConfigSection {
  @override
  final List<SshConfigEntry> entries;

  SshConfigHost(
    List<String> patterns, [
    List<SshConfigEntry>? entries,
    String? raw,
  ])  : entries = entries ?? [],
        super('Host', patterns, raw);

  List<String> get patterns => arguments;

  @override
  Iterable<String> writeSection() => [
        write(),
        ...entries.map((e) => e.write(indentation: _findIndentation())),
      ];

  int _findIndentation() {
    for (final entry in entries) {
      final entryLine = entry.write();
      final firstNonWhitespace = entryLine.indexOf(RegExp(r'\S'));
      if (firstNonWhitespace > 0) {
        return firstNonWhitespace;
      }
    }

    return 4;
  }
}
