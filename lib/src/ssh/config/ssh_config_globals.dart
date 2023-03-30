import 'ssh_config_entry.dart';
import 'ssh_config_section.dart';

class SshConfigGlobals with SshConfigSectionMixin implements SshConfigSection {
  @override
  final List<SshConfigEntry> entries;

  SshConfigGlobals(this.entries);

  @override
  Iterable<String> writeSection() => entries.map((e) => e.write());
}
