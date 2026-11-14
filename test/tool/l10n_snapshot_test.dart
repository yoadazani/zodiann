// ZOD-L10-001: the helpers behind `melos run l10n:check`, which fails when
// the committed gen-l10n output is stale.
import 'dart:io';

import 'package:test/test.dart';

import '../../tool/l10n_snapshot.dart';

String _slashes(String path) => path.replaceAll(r'\', '/');

void main() {
  group('snapshotDiff', () {
    test('equal snapshots → no lines', () {
      expect(snapshotDiff({'a.dart': 'x'}, {'a.dart': 'x'}), isEmpty);
    });

    test('a changed file', () {
      expect(snapshotDiff({'a.dart': 'x'}, {'a.dart': 'y'}), [
        'changed: a.dart',
      ]);
    });

    test('an added file', () {
      expect(snapshotDiff({'a.dart': 'x'}, {'a.dart': 'x', 'b.dart': 'y'}), [
        'added: b.dart',
      ]);
    });

    test('a removed file', () {
      expect(snapshotDiff({'a.dart': 'x', 'b.dart': 'y'}, {'a.dart': 'x'}), [
        'removed: b.dart',
      ]);
    });

    test('lines are sorted by file', () {
      expect(
        snapshotDiff(
          {'c.dart': '1', 'a.dart': '1'},
          {'c.dart': '2', 'b.dart': '1'},
        ),
        ['removed: a.dart', 'added: b.dart', 'changed: c.dart'],
      );
    });
  });

  group('snapshotGenerated', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('l10n_snapshot'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('reads .dart files with line endings normalised, ignoring others', () {
      File('${dir.path}/a.dart').writeAsStringSync('x\r\ny\r\n');
      File('${dir.path}/app_en.arb').writeAsStringSync('{}');
      expect(snapshotGenerated(dir), {'a.dart': 'x\ny\n'});
    });

    test('a CRLF checkout equals the LF output of the generator', () {
      File('${dir.path}/a.dart').writeAsStringSync('x\r\ny\r\n');
      final crlf = snapshotGenerated(dir);
      File('${dir.path}/a.dart').writeAsStringSync('x\ny\n');
      expect(snapshotDiff(crlf, snapshotGenerated(dir)), isEmpty);
    });
  });

  group('flutterExecutable', () {
    test('MELOS_SDK_PATH wins', () {
      expect(
        flutterExecutable(
          environment: {'MELOS_SDK_PATH': '/sdk'},
          resolvedDartExecutable: '/x/bin/cache/dart-sdk/bin/dart',
          isWindows: false,
        ),
        '/sdk/bin/flutter',
      );
    });

    test('otherwise the SDK of the running Dart', () {
      expect(
        flutterExecutable(
          environment: {},
          resolvedDartExecutable: '/x/bin/cache/dart-sdk/bin/dart',
          isWindows: false,
        ),
        '/x/bin/flutter',
      );
    });

    test('Windows with MELOS_SDK_PATH', () {
      expect(
        _slashes(
          flutterExecutable(
            environment: {'MELOS_SDK_PATH': r'C:\sdk'},
            resolvedDartExecutable: r'C:\x\bin\cache\dart-sdk\bin\dart.exe',
            isWindows: true,
          ),
        ),
        'C:/sdk/bin/flutter.bat',
      );
    });

    test('Windows from the running Dart', () {
      expect(
        _slashes(
          flutterExecutable(
            environment: {},
            resolvedDartExecutable: r'C:\x\bin\cache\dart-sdk\bin\dart.exe',
            isWindows: true,
          ),
        ),
        'C:/x/bin/flutter.bat',
      );
    });
  });
}
