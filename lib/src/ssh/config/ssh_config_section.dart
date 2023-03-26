import 'ssh_config_comment.dart';
import 'ssh_config_entry.dart';
import 'ssh_config_option.dart';

abstract class SshConfigSection {
  List<SshConfigEntry> get entries;

  Iterable<String> writeSection();
}

extension SshConfigSectionX on SshConfigSection {
  void addEmptyLine() => entries.add(SshConfigComment.empty());

  void addComment(String comment) => entries.add(SshConfigComment(comment));

  void addOption(String keyword, List<String> arguments) =>
      entries.add(SshConfigOption(keyword, arguments));
}
