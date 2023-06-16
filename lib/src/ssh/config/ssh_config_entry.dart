import 'package:meta/meta.dart';

abstract class SshConfigEntry {
  final String? _raw;

  SshConfigEntry(this._raw);

  @nonVirtual
  String write({int indentation = 0}) =>
      _raw ?? create(indentation: indentation);

  @protected
  String create({required int indentation});

  @protected
  void writeIndentation(StringBuffer buffer, int indentation) {
    if (indentation > 0) {
      buffer.write(' ' * indentation);
    } else if (indentation < 0) {
      buffer.write('\t' * -1 * indentation);
    }
  }
}
