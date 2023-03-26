import 'ssh_config_globals.dart';
import 'ssh_config_host.dart';
import 'ssh_config_section.dart';

class SshConfig {
  final SshConfigGlobals globals;

  final List<SshConfigHost> hosts;

  SshConfig(this.globals, this.hosts);

  void addGlobalEmptyLine() => globals.addEmptyLine();

  void addGlobalComment(String comment) => globals.addComment(comment);

  void addGlobalOption(String keyword, List<String> arguments) =>
      globals.addOption(keyword, arguments);

  SshConfigHost addHost(List<String> patterns) {
    final host = SshConfigHost(patterns);
    hosts.add(host);
    return host;
  }

  SshConfigHost? findHost(String pattern) =>
      hosts.cast<SshConfigHost?>().firstWhere(
            (host) => host!.patterns.contains(pattern),
            orElse: () => null,
          );

  Iterable<String> writeConfig() => [
        ...globals.writeSection(),
        ...hosts.expand((host) => host.writeSection()),
      ];
}
