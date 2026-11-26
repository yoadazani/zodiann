// ZOD-EPH-002: every call into Swiss Ephemeris goes through the locked,
// project-authored functions in native/swisseph/zodiann_swiss_lock.c, over one
// shared library state (TLSOFF). The behaviour itself is proved on a device
// (apps/astro_mobile/integration_test/swiss_ephemeris_concurrency_test.dart);
// this text scan keeps the ways around the lock closed.
import 'dart:io';

import 'package:test/test.dart';

const _bindings = 'lib/src/ffi/swisseph_bindings.g.dart';
const _lockSource = '../../native/swisseph/zodiann_swiss_lock.c';
const _hook = 'hook/build.dart';
const _thisGuard = 'native_lock_guard_test.dart';

const _wrappers = {
  'zodiann_swiss_version',
  'zodiann_swiss_set_ephe_path',
  'zodiann_swiss_close',
  'zodiann_swiss_calc_ut',
  'zodiann_swiss_calc_tt',
};

/// An `external` declaration of an upstream symbol, or a string literal that
/// is entirely one (as in `symbol: 'swe_calc'` or a lookup by name). Messages
/// that merely mention a function do not match.
final _unlockedSymbol = RegExp(
  r'''\bexternal\b[^;{}]*\bswe_\w+\s*\(|['"]swe_\w+['"]''',
);

String _withoutComments(String c) => c
    .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), ' ')
    .replaceAll(RegExp(r'//[^\n]*'), ' ');

Iterable<File> _dartFiles(Directory directory) sync* {
  for (final entity in directory.listSync(followLinks: false)) {
    final name = entity.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
    if (entity is Directory) {
      if (name == 'build' || name.startsWith('.')) continue;
      yield* _dartFiles(entity);
    } else if (entity is File && name.endsWith('.dart')) {
      if (name != _thisGuard) yield entity;
    }
  }
}

void main() {
  group('the scan', () {
    test('reports an external upstream declaration and a symbol string', () {
      expect(_unlockedSymbol.hasMatch('external int swe_calc('), isTrue);
      expect(_unlockedSymbol.hasMatch("symbol: 'swe_calc_ut'"), isTrue);
    });

    test('allows messages and the locked names', () {
      expect(
        _unlockedSymbol.hasMatch(r"'swe_calc_ut failed: $error'"),
        isFalse,
      );
      expect(
        _unlockedSymbol.hasMatch('external int zodiann_swiss_calc_ut('),
        isFalse,
      );
    });
  });

  test('the bindings declare exactly the locked functions', () {
    final source = File(_bindings).readAsStringSync();
    final externals = [
      for (final m in RegExp(
        r'\bexternal\b[^;(]*?\b(\w+)\s*\(',
      ).allMatches(source))
        m.group(1)!,
    ];

    expect(externals, hasLength(_wrappers.length));
    expect(externals.toSet(), _wrappers);
  });

  test('no Dart file reaches an upstream symbol', () {
    var scanned = 0;
    final found = <String>[];
    for (final root in ['../../apps', '../../packages']) {
      for (final file in _dartFiles(Directory(root))) {
        scanned++;
        if (_unlockedSymbol.hasMatch(file.readAsStringSync())) {
          found.add(file.path);
        }
      }
    }

    expect(scanned, greaterThan(50));
    expect(found, isEmpty);
  });

  test('every wrapper locks, calls upstream once and unlocks, and calls no '
      'other wrapper', () {
    final code = _withoutComments(File(_lockSource).readAsStringSync());
    final functions = {
      for (final m in RegExp(
        r'\b(?:void|int)\s+(zodiann_swiss_\w+)\s*\([^)]*\)\s*\{(.*?)\n\}',
        dotAll: true,
      ).allMatches(code))
        m.group(1)!: m.group(2)!,
    };

    expect(functions.keys.toSet(), _wrappers);
    functions.forEach((name, body) {
      final calls = [
        for (final m in RegExp(
          r'\b(pthread_mutex_lock|pthread_mutex_unlock|swe_\w+|zodiann_swiss_\w+)\s*\(([^;]*?)\)',
        ).allMatches(body))
          (m.group(1)!, m.group(2)!),
      ];

      expect(calls, hasLength(3), reason: name);
      expect(calls[0], (
        'pthread_mutex_lock',
        '&zodiann_swiss_mutex',
      ), reason: name);
      expect(calls[1].$1, startsWith('swe_'), reason: name);
      expect(calls[2], (
        'pthread_mutex_unlock',
        '&zodiann_swiss_mutex',
      ), reason: name);
    });
  });

  test('the lock refuses to build without TLSOFF', () {
    expect(
      File(_lockSource).readAsStringSync(),
      matches(RegExp(r'#ifndef TLSOFF\s*\n\s*#error ')),
    );
  });

  test('the build hook compiles the lock and defines TLSOFF', () {
    final hook = File(_hook).readAsStringSync();

    expect(hook, contains('zodiann_swiss_lock.c'));
    expect(hook, matches(RegExp(r"defines:\s*\{\s*'TLSOFF'\s*:\s*null")));
  });
}
