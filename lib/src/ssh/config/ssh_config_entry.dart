import 'package:meta/meta.dart';

abstract class SshConfigEntry {
  final String? _raw;

  SshConfigEntry(this._raw);

  @nonVirtual
  String write({int indentation = 0}) =>
      _raw ?? create(indentation: indentation);

  @protected
  String create({required int indentation});
}
