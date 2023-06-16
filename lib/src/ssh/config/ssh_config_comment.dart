import 'ssh_config_entry.dart';

class SshConfigComment extends SshConfigEntry {
  final String? comment;

  SshConfigComment(String this.comment, [super._raw]);

  SshConfigComment.empty([super._raw]) : comment = null;

  @override
  String create({required int indentation}) {
    if (comment == null) {
      return '';
    }

    final buffer = StringBuffer();
    writeIndentation(buffer, indentation);
    buffer.write('# $comment');
    return buffer.toString();
  }
}
