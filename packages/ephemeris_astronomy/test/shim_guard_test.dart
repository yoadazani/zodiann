// ZOD-EPH-004 Task 3 Step 1a: the project-authored native sources must not call
// anything that computes a velocity by differencing positions (owner decision
// 2026-11-21: no finite differences, including ones inherited from upstream).
import 'dart:io';

import 'package:ephemeris_astronomy/ephemeris_astronomy.dart';
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

  group('the UTC-to-TT conversion has one site (D12)', () {
    const helperDefinition =
        'static astro_time_t zodiann_time_from_ut(double ut_days)\n'
        '{ return Astronomy_TimeFromDays(ut_days); }\n';

    test('bans Astronomy_TimeFromTt, MakeTime and CurrentTime', () {
      expect(bannedTimeCalls('t = Astronomy_TimeFromTt(x);'), [
        'Astronomy_TimeFromTt',
      ]);
      expect(bannedTimeCalls('t = Astronomy_MakeTime (2000,1,1,0,0,0);'), [
        'Astronomy_MakeTime',
      ]);
      expect(bannedTimeCalls('t = Astronomy_CurrentTime();'), [
        'Astronomy_CurrentTime',
      ]);
    });

    test('bans every kind of assignment to a .tt or .ut field', () {
      for (final code in [
        't.tt = 1.0;',
        't.ut = x;',
        't.tt += 20/86400.0;',
        't.tt -= 1;',
        't.ut *= 2;',
        't.ut /= 2;',
        't.tt++;',
        '--t.ut;',
        'p->tt = 3;',
        't.tt   =   9;',
      ]) {
        expect(bannedTimeCalls(code), isNotEmpty, reason: code);
      }
    });

    test('allows reads and comparisons of .tt and .ut', () {
      for (final code in [
        'x = time.tt / 36525.0;',
        'if (a.tt == b.tt) return;',
        'y = t.ut + 1.0;',
        'if (a.ut <= b.ut) return;',
        'if (a.ut != b.ut) return;',
        'out[1] = t.tt;',
      ]) {
        expect(bannedTimeCalls(code), isEmpty, reason: code);
      }
    });

    test('ignores banned time calls inside comments and strings', () {
      expect(
        bannedTimeCalls('/* t.tt = 1; Astronomy_MakeTime(1) */ // t.ut += 2'),
        isEmpty,
      );
    });

    test('counts a call of a name, ignoring comments', () {
      expect(callCount('a = f(1); /* f(2) */ b = f (3); g(4);', 'f'), 2);
    });

    test('counts helper calls without its definition', () {
      const source =
          '$helperDefinition'
          'void a(void){ t = zodiann_time_from_ut(x); }\n'
          'void b(void){ t = zodiann_time_from_ut(y); }\n';
      expect(helperCallCount(source), 2);
      expect(helperDefinitionCount(source), 1);
    });

    test('a separate prototype counts as a second definition, which the '
        'guard rejects', () {
      const source =
          'static astro_time_t zodiann_time_from_ut(double ut_days);\n'
          '$helperDefinition';
      expect(helperDefinitionCount(source), 2);
    });

    test('the shim sources have one TimeFromDays call, five helper calls, '
        'one helper definition and no banned time call', () {
      var timeFromDays = 0;
      var helperCalls = 0;
      var helperDefinitions = 0;
      for (final file in _projectSources()) {
        final text = file.readAsStringSync();
        timeFromDays += callCount(text, 'Astronomy_TimeFromDays');
        helperCalls += helperCallCount(text);
        helperDefinitions += helperDefinitionCount(text);
        expect(bannedTimeCalls(text), isEmpty, reason: file.path);
      }
      expect(timeFromDays, 1);
      expect(helperDefinitions, 1);
      expect(helperCalls, 5);
    });

    test('the helper body holds the TimeFromDays call and is defined before '
        'its first use', () {
      final code = stripCommentsAndStrings(
        File('../../native/astronomy_c/zodiann_astronomy_shim.c')
            .readAsStringSync(),
      );
      final definition = RegExp(
        r'astro_time_t\s+zodiann_time_from_ut\s*\([^)]*\)\s*\{([^}]*)\}',
      ).firstMatch(code);
      expect(definition, isNotNull);
      expect(definition!.group(1), contains('Astronomy_TimeFromDays'));
      final mentions = RegExp(r'\bzodiann_time_from_ut\s*\(')
          .allMatches(code)
          .map((m) => m.start)
          .toList();
      // The definition is the first mention; every other one is a call after it.
      expect(mentions.first, lessThanOrEqualTo(definition.end));
      expect(mentions.where((i) => i > definition.end), hasLength(5));
    });
  });

  group('the hook lengths in the shim header equal the Dart constants', () {
    test('body state 8, Moon series 9, Moon state 12, time 2', () {
      final header = File('../../native/astronomy_c/zodiann_astronomy_shim.h')
          .readAsStringSync();
      int defined(String name) => int.parse(
        RegExp('#define $name (\\d+)').firstMatch(header)!.group(1)!,
      );
      expect(defined('ZODIANN_BODY_STATE_LENGTH'), bodyStateLength);
      expect(defined('ZODIANN_MOON_SERIES_LENGTH'), moonSeriesLength);
      expect(defined('ZODIANN_MOON_STATE_LENGTH'), moonStateLength);
      expect(defined('ZODIANN_TIME_STATE_LENGTH'), timeStateLength);
      expect(
        [bodyStateLength, moonSeriesLength, moonStateLength, timeStateLength],
        [8, 9, 12, 2],
      );
    });
  });

  group('the Dart UT-days conversion has one site (D12)', () {
    test('daysSinceJ2000 is called once, inside _utDays, which bodyState, '
        'rawBufferForTesting and timeForTesting all use', () {
      final source = File('lib/src/native_body_state_source.dart')
          .readAsStringSync();
      expect(callCount(source, 'daysSinceJ2000'), 1);
      // The definition, then the three entry points.
      expect(callCount(source, '_utDays'), 4);
    });
  });

  test('no project-authored native source calls a banned function', () {
    final sources = _projectSources();
    expect(sources, isNotEmpty);
    for (final file in sources) {
      expect(bannedCalls(file.readAsStringSync()), isEmpty, reason: file.path);
    }
  });
}

List<File> _projectSources() =>
    Directory('../../native/astronomy_c')
        .listSync()
        .whereType<File>()
        .where((f) => f.uri.pathSegments.last.startsWith('zodiann_'))
        .where((f) => f.path.endsWith('.c') || f.path.endsWith('.h'))
        .toList();
