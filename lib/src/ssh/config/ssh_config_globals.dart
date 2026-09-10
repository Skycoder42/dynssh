import 'ssh_config_entry.dart';
import 'ssh_config_section.dart';

class SshConfigGlobals(@override final List<SshConfigEntry> entries)
    with SshConfigSectionMixin
    implements SshConfigSection {
  @override
  Iterable<String> writeSection() => entries.map((e) => e.write());
}
