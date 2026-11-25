// ZOD-FND-011 Task 7.3: every production binding of the ephemeris port wraps
// its source in `SupportedRangeEphemeris`, so the supported date range is
// enforced in front of every source (Q1). The guard fails closed: a binding,
// a second provider of the port, or a direct use of a source adapter that is
// not literally wrapped fails the build. No production binding exists yet
// (ZOD-EPH-002 adds the first), so the real-repository scan is clean today.
// Runs from the workspace root on every `melos run test`.
import 'dart:io';

import 'package:test/test.dart';

import 'port_binding.dart';

const _overrides = 'apps/astro_mobile/lib/src/di/app_overrides.dart';
const _consumer = 'packages/feature_wheel/lib/a.dart';

/// Two source adapters that exist in the scanned tree, so rule R3 can
/// discover them.
const _adapters = <String, String>{
  'packages/ephemeris_astronomy/lib/src/astronomy_ephemeris.dart': '''
final class AstronomyEphemeris with MeanAscendingNodeFormula implements EphemerisPort {
  AstronomyEphemeris({required this.source});
  final Object source;
}
''',
  'packages/swiss_like/lib/swiss_like.dart':
      'class SwissLike implements EphemerisPort {}\n',
};

Map<String, String> tree(String path, String text) => {
  ..._adapters,
  path: text,
};

List<BindingProblem> problems(String path, String text) =>
    findBindingProblems(tree(path, text));

void main() {
  group('passes (controls)', () {
    final ok = <String, (String, String)>{
      'a wrapped overrideWithValue': (
        _overrides,
        'final o = ephemerisPortProvider.overrideWithValue('
            'SupportedRangeEphemeris(AstronomyEphemeris(source: s)));',
      ),
      'a wrapped overrideWith closure': (
        _overrides,
        'final o = ephemerisPortProvider.overrideWith('
            '(ref) => SupportedRangeEphemeris(SwissLike()));',
      ),
      'the declaration in the declaring file': (
        bindingDeclarationFile,
        'final Provider<EphemerisPort> ephemerisPortProvider = '
            "Provider<EphemerisPort>((ref) => throw StateError('x'));",
      ),
      'ref.watch': (_consumer, 'final p = ref.watch(ephemerisPortProvider);'),
      'ref.read': (_consumer, 'final p = ref.read(ephemerisPortProvider);'),
      'ref.listen': (
        _consumer,
        'ref.listen(ephemerisPortProvider, (a, b) {});',
      ),
      'a multi-line read': (
        _consumer,
        'final p = ref.read(\n  ephemerisPortProvider,\n);',
      ),
      'a read with a type argument': (
        _consumer,
        'final p = ref.watch<EphemerisPort>(ephemerisPortProvider);',
      ),
      'a prefixed read': (
        _consumer,
        'final p = ref.watch(p.ephemerisPortProvider);',
      ),
      'a select': (
        _consumer,
        'final r = ref.watch(ephemerisPortProvider.select((p) => p.coveredRange));',
      ),
      'a show import': (
        _consumer,
        "import 'package:astro_mobile/src/di/ephemeris_providers.dart' show ephemerisPortProvider;",
      ),
      'a hide import': (
        _consumer,
        "import 'package:astro_mobile/src/di/ephemeris_providers.dart' hide ephemerisPortProvider;",
      ),
      'an export with show': (
        _consumer,
        "export 'package:x/y.dart' show ephemerisPortProvider;",
      ),
      'an import that shows an adapter': (
        _consumer,
        "import 'package:ephemeris_astronomy/ephemeris_astronomy.dart' show AstronomyEphemeris;",
      ),
      'mentions in comments and strings': (
        _consumer,
        "// ephemerisPortProvider.overrideWithValue(AstronomyEphemeris(source: s))\n"
            "final s = 'AstronomyEphemeris(x) ephemerisPortProvider.overrideWith';",
      ),
    };
    ok.forEach((label, c) {
      test('passes $label', () {
        expect(problems(c.$1, c.$2), isEmpty);
      });
    });

    test('the adapters themselves, in their own files, are fine', () {
      expect(findBindingProblems(_adapters), isEmpty);
    });
  });

  group('fails (controls)', () {
    final bad = <String, (String, String)>{
      'an unwrapped overrideWithValue': (
        _overrides,
        'final o = ephemerisPortProvider.overrideWithValue('
            'AstronomyEphemeris(source: s));',
      ),
      'an overrideWith that is not literally wrapped': (
        _overrides,
        'final o = ephemerisPortProvider.overrideWith('
            '(ref) => ref.watch(otherProvider));',
      ),
      'an unwrapped overrideWithBuild': (
        _overrides,
        'final o = ephemerisPortProvider.overrideWithBuild((ref, n) => raw);',
      ),
      'an invented member': (
        _overrides,
        'final o = ephemerisPortProvider.somethingNew(x);',
      ),
      'an override nested in a read': (
        _consumer,
        'ref.read(ephemerisPortProvider.overrideWithValue(raw));',
      ),
      'an alias': (_consumer, 'final p = ephemerisPortProvider;'),
      'a list element': (_consumer, 'final list = [ephemerisPortProvider];'),
      'a second Provider<EphemerisPort>': (
        _consumer,
        'final sourceProvider = Provider<EphemerisPort>('
            '(ref) => AstronomyEphemeris(source: s));',
      ),
      'a Provider.family of the port': (
        _consumer,
        'final f = Provider.family<EphemerisPort, int>((ref, i) => x);',
      ),
      'a Provider.autoDispose of the port': (
        _consumer,
        'final f = Provider.autoDispose<EphemerisPort>((ref) => x);',
      ),
      'a NotifierProvider of the port': (
        _consumer,
        'final f = NotifierProvider<N, EphemerisPort>(N.new);',
      ),
      'a NotifierProvider.autoDispose of the port': (
        _consumer,
        'final f = NotifierProvider.autoDispose<N, EphemerisPort>(N.new);',
      ),
      'a second port provider inside the declaring file': (
        bindingDeclarationFile,
        'final Provider<EphemerisPort> ephemerisPortProvider = '
            "Provider<EphemerisPort>((ref) => throw StateError('x'));\n"
            'final other = Provider<EphemerisPort>((ref) => x);',
      ),
      'the declaration in another file': (
        _overrides,
        'final Provider<EphemerisPort> ephemerisPortProvider = '
            "Provider<EphemerisPort>((ref) => throw StateError('x'));",
      ),
      'an adapter constructed in a consumer': (
        _consumer,
        'final port = AstronomyEphemeris(source: s);',
      ),
      'an adapter tear-off': (_consumer, 'final f = AstronomyEphemeris.new;'),
      'a const adapter outside a wrapper': (
        _consumer,
        'const port = SwissLike();',
      ),
      'an adapter created outside the wrapping expression': (
        _consumer,
        'final s = SwissLike();\nfinal w = SupportedRangeEphemeris(s);',
      ),
      'a wrapper only in a comment next to an unwrapped binding': (
        _overrides,
        '// SupportedRangeEphemeris(\n'
            'final o = ephemerisPortProvider.overrideWithValue(raw);',
      ),
      'an adapter used inside a string interpolation hole': (
        _consumer,
        r"final s = '${SwissLike()}';",
      ),
      'an unwrapped binding inside a string interpolation hole': (
        _consumer,
        r"final s = '${ephemerisPortProvider.overrideWithValue(raw)}';",
      ),
      'a look-alike class named like the decorator': (
        _consumer,
        'class SupportedRangeEphemeris { SupportedRangeEphemeris(Object o); }',
      ),
      'a look-alike function named like the decorator': (
        _consumer,
        'Object SupportedRangeEphemeris(Object o) => o;',
      ),
      'a wrapper only in a string next to an unwrapped binding': (
        _overrides,
        "final w = 'SupportedRangeEphemeris(';\n"
            'final o = ephemerisPortProvider.overrideWithValue(raw);',
      ),
    };
    bad.forEach((label, c) {
      test('fails $label', () {
        expect(problems(c.$1, c.$2), isNotEmpty);
      });
    });

    test('a problem carries its path, line and a message', () {
      final found = problems(
        _overrides,
        'void f() {}\n'
        'final o = ephemerisPortProvider.overrideWithValue(raw);\n',
      );

      expect(found, hasLength(1));
      expect(found.single.path, _overrides);
      expect(found.single.line, 2);
      expect(found.single.message, contains('SupportedRangeEphemeris'));
    });
  });

  group('adapter discovery', () {
    test('finds classes implementing the port, with modifiers and a with '
        'clause, and a prefixed interface', () {
      final names = discoverAdapterNames({
        'a.dart': 'final class A with M implements EphemerisPort {}',
        'b.dart': 'base class B implements Other, EphemerisPort {}',
        'c.dart': 'class C implements ac.EphemerisPort {}',
        'd.dart': 'mixin M implements EphemerisPort {}',
        'e.dart': 'abstract interface class EphemerisPort {}',
        'f.dart':
            'final class SupportedRangeEphemeris implements EphemerisPort {}',
      });

      expect(names, {'A', 'B', 'C'});
    });

    test('finds a class that gets the port from a mixin, and an enum', () {
      final names = discoverAdapterNames({
        'm.dart': 'mixin PortMix implements EphemerisPort {}',
        'z.dart': 'class Hidden with PortMix {}',
        'y.dart': 'final class Other with Unrelated, PortMix {}',
        'n.dart': 'class Plain with Unrelated {}',
        'e.dart': 'enum EnumPort implements EphemerisPort { a }',
      });

      expect(names, {'Hidden', 'Other', 'EnumPort'});
    });

    test('a hidden adapter is then caught outside a wrapper', () {
      final found = findBindingProblems({
        'm.dart': 'mixin PortMix implements EphemerisPort {}',
        'z.dart': 'class Hidden with PortMix {}',
        _consumer: 'final p = Hidden();',
      });

      expect(found, isNotEmpty);
    });
  });

  group('the decorator name has one definition', () {
    test('its home file may declare it', () {
      expect(
        findBindingProblems({
          decoratorDeclarationFile:
              'final class SupportedRangeEphemeris implements EphemerisPort {\n'
              '  const SupportedRangeEphemeris(this._s);\n'
              '  final EphemerisPort _s;\n'
              '}\n',
        }),
        isEmpty,
      );
    });
  });

  group('scanBindings on a temporary tree', () {
    late Directory root;
    setUp(() => root = Directory.systemTemp.createTempSync('port_binding_'));
    tearDown(() => root.deleteSync(recursive: true));

    void write(String relative, String text) {
      File(
          '${root.path}${Platform.pathSeparator}'
          '${relative.replaceAll('/', Platform.pathSeparator)}',
        )
        ..createSync(recursive: true)
        ..writeAsStringSync(text);
    }

    setUp(() {
      _adapters.forEach(write);
    });

    test('an unwrapped binding in app_overrides.dart is reported', () {
      write(
        _overrides,
        'final a = 1;\n'
        'final o = ephemerisPortProvider.overrideWithValue('
        'AstronomyEphemeris(source: s));\n',
      );

      final found = scanBindings(root);

      expect(found, isNotEmpty);
      expect(found.first.path, _overrides);
      expect(found.first.line, 2);
    });

    test('the wrapped binding is accepted', () {
      write(
        _overrides,
        'final o = ephemerisPortProvider.overrideWithValue('
        'SupportedRangeEphemeris(AstronomyEphemeris(source: s)));\n',
      );

      expect(scanBindings(root), isEmpty);
    });

    test('the same unwrapped binding in a test directory is not scanned', () {
      write(
        'apps/astro_mobile/test/b.dart',
        'final o = ephemerisPortProvider.overrideWithValue(raw);\n',
      );

      expect(scanBindings(root), isEmpty);
    });
  });

  group('the real repository', () {
    test(
      'every production binding of the port is wrapped (none exists yet)',
      () {
        final found = scanBindings(Directory('.'));

        expect(
          found,
          isEmpty,
          reason:
              'Bind the source as ephemerisPortProvider.overrideWithValue('
              'SupportedRangeEphemeris(<source>)), created inside the wrapper. '
              'Found: ${found.join('; ')}',
        );
      },
    );

    test('the declaring file exists and declares the provider', () {
      final text = File(bindingDeclarationFile).readAsStringSync();

      expect(text, contains('ephemerisPortProvider'));
      expect(text, contains('Provider<EphemerisPort>'));
    });

    test('adapter discovery sees AstronomyEphemeris and not the decorator', () {
      final names = discoverAdapterNames(productionSources(Directory('.')));

      expect(names, contains('AstronomyEphemeris'));
      expect(names, isNot(contains('SupportedRangeEphemeris')));
    });
  });
}
