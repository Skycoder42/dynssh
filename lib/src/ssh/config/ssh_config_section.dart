import 'ssh_config_comment.dart';
import 'ssh_config_entry.dart';
import 'ssh_config_option.dart';

abstract class SshConfigSection {
  List<SshConfigEntry> get entries; // TODO make private?

  Iterable<String> writeSection();
}

extension SshConfigSectionX on SshConfigSection {
  void addEmptyLine() => entries.add(SshConfigComment.empty());

  void addComment(String comment) => entries.add(SshConfigComment(comment));

  List<String>? operator [](String keyword) => entries
      .whereType<SshConfigOption>()
      .cast<SshConfigOption?>()
      .firstWhere(
        (option) => option!.keyword == keyword.toLowerCase(),
        orElse: () => null,
      )
      ?.arguments;

  void operator []=(String keyword, List<String> arguments) {
    final entryIndex = entries.indexWhere(
      (option) =>
          option is SshConfigOption && option.keyword == keyword.toLowerCase(),
    );
    if (entryIndex == -1) {
      entries.add(SshConfigOption(keyword, arguments));
    } else {
      entries[entryIndex] = SshConfigOption(keyword, arguments);
    }
  }
}
