import 'ssh_config_entry.dart';
import 'ssh_config_option.dart';
import 'ssh_config_section.dart';

class SshConfigHost extends SshConfigOption implements SshConfigSection {
  @override
  final List<SshConfigEntry> entries;

  final int? _indentation;

  SshConfigHost(
    List<String> patterns, [
    List<SshConfigEntry>? entries,
    String? raw,
    this._indentation,
  ])  : entries = entries ?? [],
        super('Host', patterns, raw);

  List<String> get patterns => arguments;

  @override
  Iterable<String> writeSection() => [
        write(),
        ...entries.map((e) => e.write(indentation: _indentation ?? 0)),
      ];
}
