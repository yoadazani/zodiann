// ZOD-WHL-001 (ARCH-3): the wheel's state lives in exactly one Riverpod
// provider, the screen adds no scope of its own, and its derived geometry is
// pure (no riverpod under src/geometry/). Runs from the workspace root.
import 'dart:io';

import 'package:test/test.dart';

import 'wheel_single_provider.dart';

List<File> _dartFiles(String dir) => Directory(dir).existsSync()
    ? Directory(dir)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList()
    : [];

void main() {
  const lib = 'packages/feature_wheel/lib';
  final files = _dartFiles(lib);

  group('the scanner (controls)', () {
    test('counts constructors, not uses', () {
      expect(
        countProviderDeclarations(
          'final a = NotifierProvider<A, List<int>>(A.new);',
        ),
        1,
      );
      expect(countProviderDeclarations('final a = Provider((ref) => 1);'), 1);
      expect(
        countProviderDeclarations('final a = Provider<int>((ref) => 1);'),
        1,
      );
      expect(
        countProviderDeclarations(
          'final a = NotifierProvider.autoDispose<A, B>(A.new);',
        ),
        1,
      );
      expect(
        countProviderDeclarations(
          'ref.watch(wheelStateProvider.select((s) => s.pointerLongitude));',
        ),
        0,
      );
      expect(
        countProviderDeclarations('ref.read(wheelStateProvider.notifier);'),
        0,
      );
      expect(countProviderDeclarations('ProviderScope(child: x)'), 0);
      expect(countProviderDeclarations('ProviderContainer()'), 0);
      expect(
        countProviderDeclarations('class O extends ProviderObserver {}'),
        0,
      );
      expect(countProviderDeclarations('@riverpod\nint a(Ref ref) => 1;'), 1);
    });

    test('two providers count two', () {
      expect(
        countProviderDeclarations(
          'final a = Provider((r) => 1);\nfinal b = NotifierProvider<X, Y>(X.new);',
        ),
        2,
      );
    });

    test('scopes and riverpod mentions are found', () {
      expect(countScopes('ProviderScope(child: x)'), 1);
      expect(countScopes('ProviderContainer()'), 1);
      expect(countScopes('final x = 1;'), 0);
      expect(
        mentionsRiverpod("import 'package:flutter_riverpod/x.dart';"),
        isTrue,
      );
      expect(mentionsRiverpod('ref.watch(p)'), isTrue);
      expect(mentionsRiverpod('final x = 1;'), isFalse);
    });
  });

  test('the walk finds the wheel package', () {
    expect(files, isNotEmpty);
  });

  test('exactly one provider declaration in feature_wheel/lib', () {
    final count = files
        .map((f) => countProviderDeclarations(f.readAsStringSync()))
        .fold<int>(0, (a, b) => a + b);
    expect(count, 1, reason: 'expected 1 provider declaration, found $count');
  });

  test('no ProviderScope or ProviderContainer in feature_wheel/lib', () {
    final bad = [
      for (final f in files)
        if (countScopes(f.readAsStringSync()) > 0) f.path,
    ];
    expect(bad, isEmpty);
  });

  test('src/geometry/ is pure: it does not mention riverpod', () {
    final bad = [
      for (final f in files.where(
        (f) => f.path.replaceAll(r'\', '/').contains('/src/geometry/'),
      ))
        if (mentionsRiverpod(f.readAsStringSync())) f.path,
    ];
    expect(bad, isEmpty);
  });
}
