// ZOD-FND-004: the CI step timer (tool/ci/timed.dart): the pure formatting
// functions, and the wrapper end to end (exit codes, executable discovery,
// the timing and summary files).
import 'dart:io';

import 'package:test/test.dart';

import '../../tool/ci/timing.dart';

/// Runs `dart run tool/ci/timed.dart <args>` from the workspace root with the
/// given environment, using the Dart VM that runs this test (the pinned SDK).
ProcessResult runTimed(List<String> args, Map<String, String> environment) =>
    Process.runSync(Platform.resolvedExecutable, [
      'run',
      'tool/ci/timed.dart',
      ...args,
    ], environment: environment);

void main() {
  group('formatCsvRow', () {
    test('writes label, seconds with one decimal and the exit code', () {
      expect(
        formatCsvRow('core', const Duration(milliseconds: 12345), 0),
        'core,12.3,0\n',
      );
    });
  });

  group('formatSummaryRow', () {
    test('marks a zero exit code ok', () {
      expect(
        formatSummaryRow('core', const Duration(milliseconds: 12345), 0),
        '| core | 12.3 s | ok |\n',
      );
    });

    test('names a non-zero exit code', () {
      expect(
        formatSummaryRow('core', const Duration(milliseconds: 12345), 3),
        '| core | 12.3 s | FAILED (3) |\n',
      );
    });
  });

  group('budgetWarning', () {
    const label = 'core';

    test('is null with no budget', () {
      expect(budgetWarning(label, const Duration(seconds: 999), null), isNull);
    });

    test('is null under and exactly at the budget', () {
      expect(budgetWarning(label, const Duration(seconds: 59), 60), isNull);
      expect(budgetWarning(label, const Duration(seconds: 60), 60), isNull);
    });

    test('is a GitHub warning annotation over the budget', () {
      expect(
        budgetWarning(label, const Duration(seconds: 61), 60),
        '::warning title=CI runtime budget::core took 61.0 s, budget 60 s',
      );
    });
  });

  group('timed.dart', () {
    late Directory temp;
    late String csv;
    late String summary;
    late Map<String, String> env;

    setUp(() {
      temp = Directory.systemTemp.createTempSync('ci_timing_test');
      csv = '${temp.path}${Platform.pathSeparator}timing.csv';
      summary = '${temp.path}${Platform.pathSeparator}summary.md';
      env = {'CI_TIMING_FILE': csv, 'GITHUB_STEP_SUMMARY': summary};
    });

    tearDown(() => temp.deleteSync(recursive: true));

    String dart() => Platform.resolvedExecutable;

    File script(String name, String body) =>
        File('${temp.path}${Platform.pathSeparator}$name')
          ..writeAsStringSync(body);

    test('runs the command, exits 0 and records one CSV row', () {
      final result = runTimed(['ok-step', '--', dart(), '--version'], env);

      expect(result.exitCode, 0, reason: '${result.stderr}');
      final rows = File(csv).readAsLinesSync();
      expect(rows, hasLength(1));
      expect(rows.single, matches(RegExp(r'^ok-step,\d+\.\d,0$')));
    });

    test('propagates the exit code and still records the row', () {
      final fail = script(
        'fail.dart',
        "import 'dart:io';\nvoid main() => exit(7);\n",
      );

      final result = runTimed(['bad-step', '--', dart(), fail.path], env);

      expect(result.exitCode, 7);
      expect(
        File(csv).readAsLinesSync().single,
        matches(RegExp(r'^bad-step,\d+\.\d,7$')),
      );
      expect(File(summary).readAsStringSync(), contains('FAILED (7)'));
    });

    test('exits 127 when the executable is not on PATH', () {
      final result = runTimed([
        'missing',
        '--',
        'zodiann-no-such-executable',
      ], env);

      expect(result.exitCode, 127);
    });

    test('exits 2 without a command separator', () {
      expect(runTimed(['no-separator'], env).exitCode, 2);
      expect(runTimed(['no-command', '--'], env).exitCode, 2);
    });

    test('writes the summary header once, then only rows', () {
      runTimed(['one', '--', dart(), '--version'], env);
      runTimed(['two', '--', dart(), '--version'], env);

      final lines = File(summary).readAsLinesSync();
      expect(lines.where((l) => l.startsWith('| Step |')), hasLength(1));
      expect(lines.where((l) => l.startsWith('| one |')), hasLength(1));
      expect(lines.where((l) => l.startsWith('| two |')), hasLength(1));
    });

    test('prints a warning annotation over the budget', () {
      final slow = script(
        'slow.dart',
        "void main() => Future<void>.delayed(const Duration(milliseconds: 1500));\n",
      );

      final result = runTimed([
        'slow-step',
        '--budget-seconds',
        '1',
        '--',
        dart(),
        slow.path,
      ], env);

      expect(result.exitCode, 0, reason: '${result.stderr}');
      expect(
        result.stdout,
        contains('::warning title=CI runtime budget::slow-step took'),
      );
    });

    test(
      'propagates the exit code of a .bat shim and keeps a spaced argument',
      () {
        final bat = script(
          'shim.bat',
          '@echo off\r\nif "%~1"=="a b" exit /b 5\r\nexit /b 9\r\n',
        );

        final result = runTimed(['bat-step', '--', bat.path, 'a b'], env);

        expect(result.exitCode, 5, reason: '${result.stderr}');
      },
      skip: Platform.isWindows ? false : 'Windows batch shims only',
    );

    test('finds a .bat shim by bare name through PATH and PATHEXT', () {
      script('zodiann_shim.bat', '@echo off\r\nexit /b 6\r\n');
      final withShimOnPath = {
        ...env,
        'PATH': '${temp.path};${Platform.environment['PATH']}',
      };

      final result = runTimed([
        'path-step',
        '--',
        'zodiann_shim',
      ], withShimOnPath);

      expect(result.exitCode, 6, reason: '${result.stderr}');
    }, skip: Platform.isWindows ? false : 'Windows batch shims only');
  });
}
