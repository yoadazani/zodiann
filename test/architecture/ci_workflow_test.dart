// ZOD-FND-004: pins the shape of .github/workflows/ci.yml so a later edit
// cannot quietly weaken the pipeline: triggers, required job names, pinned
// actions, read-only permissions, the core job's scope and strictness, and
// the pinned Flutter SDK. Runs from the workspace root on every
// `melos run test`.
import 'dart:io';

import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import 'pure_dart_test.dart' show corePackages;

const _workflowPath = '.github/workflows/ci.yml';

Map<String, Object?> _asMap(Object? node) => {
  for (final entry in (node! as YamlMap).entries)
    entry.key as String: entry.value,
};

List<Map<String, Object?>> _steps(Map<String, Object?> job) => [
  for (final step in job['steps']! as YamlList) _asMap(step),
];

/// Every `run:` script of the job, joined: the commands the job executes.
String _commands(Map<String, Object?> job) =>
    _steps(job).map((step) => (step['run'] as String?) ?? '').join('\n');

void main() {
  late Map<String, Object?> workflow;
  late Map<String, Object?> jobs;

  setUpAll(() {
    final file = File(_workflowPath);
    expect(file.existsSync(), isTrue, reason: '$_workflowPath must exist');
    workflow = _asMap(loadYaml(file.readAsStringSync()));
    jobs = _asMap(workflow['jobs']);
  });

  group('triggers (O4)', () {
    test('push and pull_request both target main only', () {
      final on = _asMap(workflow['on']);

      expect(on.keys, unorderedEquals(['push', 'pull_request']));
      for (final event in ['push', 'pull_request']) {
        final config = _asMap(on[event]);
        expect(config.keys, ['branches'], reason: '$event keys');
        expect(config['branches'], ['main'], reason: '$event branches');
      }
    });
  });

  group('workflow', () {
    test('permissions are read-only', () {
      expect(_asMap(workflow['permissions']), {'contents': 'read'});
    });

    test('concurrency groups by ref and never cancels main', () {
      final concurrency = _asMap(workflow['concurrency']);

      expect(concurrency['group'], r'ci-${{ github.ref }}');
      expect(
        concurrency['cancel-in-progress'],
        r"${{ github.ref != 'refs/heads/main' }}",
      );
    });

    test('every action is pinned to a full commit SHA', () {
      final sha = RegExp(r'^[\w.-]+/[\w.-]+@[0-9a-f]{40}$');
      final uses = [
        for (final job in jobs.values)
          for (final step in _steps(_asMap(job)))
            if (step['uses'] case final String action) action,
      ];

      expect(uses, isNotEmpty);
      for (final action in uses) {
        expect(action, matches(sha), reason: action);
      }
    });
  });

  group('jobs', () {
    test('Core, Lint and Full suite exist with their required names', () {
      expect(jobs.keys, unorderedEquals(['core', 'lint', 'full']));
      expect(_asMap(jobs['core'])['name'], 'Core');
      expect(_asMap(jobs['lint'])['name'], 'Lint');
      expect(_asMap(jobs['full'])['name'], 'Full suite');
    });

    test('every job runs on ubuntu-latest with a timeout (O1)', () {
      for (final entry in jobs.entries) {
        final job = _asMap(entry.value);
        expect(job['runs-on'], 'ubuntu-latest', reason: entry.key);
        expect(job['timeout-minutes'], isA<int>(), reason: entry.key);
      }
    });

    test('no job waits for another, so each check reports on its own', () {
      for (final entry in jobs.entries) {
        expect(_asMap(entry.value).containsKey('needs'), isFalse);
      }
    });

    test('every job pins Flutter from .fvmrc and points Melos at it', () {
      for (final entry in jobs.entries) {
        final job = _asMap(entry.value);
        final commands = _commands(job);
        final fvmrc = File('.fvmrc').readAsStringSync();
        final version = RegExp(r'"flutter":\s*"([^"]+)"').firstMatch(fvmrc)![1];

        expect(commands, contains('.fvmrc'), reason: entry.key);
        expect(commands, contains('MELOS_SDK_PATH'), reason: entry.key);
        expect(
          File(_workflowPath).readAsStringSync(),
          isNot(contains(version!)),
          reason: 'the version lives only in .fvmrc',
        );
      }
    });

    test('dependencies come from flutter pub get, then the l10n restore', () {
      for (final entry in jobs.entries) {
        final commands = _commands(_asMap(entry.value));

        expect(commands, isNot(contains('dart pub get')), reason: entry.key);
        expect(commands, contains('flutter pub get'), reason: entry.key);
        expect(
          commands.indexOf('flutter pub get'),
          lessThan(
            commands.indexOf('git checkout -- packages/shared_ui/lib/l10n'),
          ),
          reason: '${entry.key}: restore after pub get',
        );
        expect(commands, contains('git status --porcelain'));
      }
    });
  });

  group('core job (ARCH-2, L-8, O3)', () {
    late String commands;

    setUpAll(() => commands = _commands(_asMap(jobs['core'])));

    test('analyzes every core package with warnings fatal', () {
      final analyze = commands
          .split('\n')
          .firstWhere((line) => line.contains('dart analyze'));

      expect(analyze, contains('--fatal-warnings'));
      for (final package in corePackages) {
        expect(analyze, contains('packages/$package'));
      }
    });

    test('tests every core package and the architecture guards', () {
      final test = commands
          .split('\n')
          .firstWhere((line) => line.contains('dart test'));

      expect(test, contains(corePackages.join(',')));
      expect(commands, contains('dart test test/architecture'));
    });

    test('runs no Flutter tests', () {
      expect(commands, isNot(contains('flutter test')));
      expect(commands, isNot(contains('test:flutter')));
    });

    test('warns when the three timed steps exceed the 300 s budget', () {
      expect(commands, matches(RegExp(r'\bt > 300\b')));
      expect(commands, contains('budget 300 s'));
      expect(commands, contains('::warning title=CI runtime budget::'));
    });
  });

  group('lint and full jobs', () {
    test('lint runs melos run lint', () {
      expect(_commands(_asMap(jobs['lint'])), contains('melos run lint'));
    });

    test('full runs melos run test', () {
      expect(_commands(_asMap(jobs['full'])), contains('melos run test'));
    });
  });
}
