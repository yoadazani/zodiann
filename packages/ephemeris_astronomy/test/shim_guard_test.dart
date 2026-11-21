// ZOD-EPH-004 Task 3 Step 1a: the project-authored native sources must not call
// anything that computes a velocity by differencing positions (owner decision
// 2026-11-21: no finite differences, including ones inherited from upstream).
import 'dart:io';

import 'package:test/test.dart';

import '../tool/shim_scan.dart';

void main() {
  group('bannedCalls', () {
    test('reports Astronomy_GeoMoonState', () {
      expect(bannedCalls('void f(void) { x = Astronomy_GeoMoonState(t); }'), [
        'Astronomy_GeoMoonState',
      ]);
    });

    test('reports Astronomy_GeoEmbState', () {
      expect(bannedCalls('y = Astronomy_GeoEmbState (t);'), [
        'Astronomy_GeoEmbState',
      ]);
    });

    test('reports Astronomy_HelioState with BODY_MOON', () {
      expect(bannedCalls('s = Astronomy_HelioState(BODY_MOON, t);'), [
        'Astronomy_HelioState',
      ]);
    });

    test('reports Astronomy_BaryState with BODY_EMB', () {
      expect(bannedCalls('s = Astronomy_BaryState(BODY_EMB, t);'), [
        'Astronomy_BaryState(BODY_EMB)',
      ]);
    });

    test('reports Astronomy_BaryState with BODY_MOON', () {
      expect(bannedCalls('s = Astronomy_BaryState( BODY_MOON , t);'), [
        'Astronomy_BaryState(BODY_MOON)',
      ]);
    });

    test('reports Astronomy_AddDays', () {
      expect(bannedCalls('t2 = Astronomy_AddDays(t, 1.0e-5);'), [
        'Astronomy_AddDays',
      ]);
    });

    test('ignores a block comment, a line comment and a string literal', () {
      const clean = r'''
/* never Astronomy_GeoMoonState(t) here */
// nor Astronomy_GeoEmbState(t)
const char* note = "Astronomy_AddDays(t, dt) is banned";
''';
      expect(bannedCalls(clean), isEmpty);
    });

    test('allows BaryState for the Earth and for a variable body', () {
      expect(
        bannedCalls(
          'a = Astronomy_BaryState(BODY_EARTH, t);'
          'b = Astronomy_BaryState(kShimBodies[body], t);',
        ),
        isEmpty,
      );
    });

    test('allows the mention of BODY_MOON outside a BaryState call', () {
      expect(
        bannedCalls('static const astro_body_t b[] = {BODY_MOON};'),
        isEmpty,
      );
    });
  });

  test('no project-authored native source calls a banned function', () {
    final dir = Directory('../../native/astronomy_c');
    final sources = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.uri.pathSegments.last.startsWith('zodiann_'))
        .where((f) => f.path.endsWith('.c') || f.path.endsWith('.h'))
        .toList();
    expect(sources, isNotEmpty);
    for (final file in sources) {
      expect(bannedCalls(file.readAsStringSync()), isEmpty, reason: file.path);
    }
  });
}
