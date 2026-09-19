import 'package:dynssh/src/ssh/config/ssh_config_comment.dart';
import 'package:test/test.dart';

void main() {
  group('SshConfigEntry', () {
    group('write', () {
      test('returns raw content if set, ignoring indentation', () {
        final sut = SshConfigComment('test', 'raw content');

        expect(sut.write(indentation: 4), 'raw content');
      });

      test('indents with spaces for positive indentation', () {
        final sut = SshConfigComment('test');

        expect(sut.write(indentation: 3), '   # test');
      });

      test('indents with tabs for negative indentation', () {
        final sut = SshConfigComment('test');

        expect(sut.write(indentation: -2), '\t\t# test');
      });

      test('does not indent for zero indentation', () {
        final sut = SshConfigComment('test');

        expect(sut.write(), '# test');
      });
    });
  });
}
