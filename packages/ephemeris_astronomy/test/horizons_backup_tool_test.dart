// ZOD-TST-001: the request handling of the two Backup reference fetch tools
// (tool/fetch_horizons_reference.dart and fetch_horizons_tt_reference.dart).
// Nothing here reaches the network or runs a C tool: the HTTP GET and the
// library times are fakes, opening a connection fails, and every run writes
// into a temporary tree.
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../../ephemeris_swiss/tool/horizons/download.dart';
import '../tool/fetch_horizons_reference.dart' as ut;
import '../tool/fetch_horizons_tt_reference.dart' as tt;

const _commands = [
  '10',
  '301',
  '199',
  '299',
  '499',
  '599',
  '699',
  '799',
  '899',
  '999',
];

/// One request as the ZOD-EPH-004 tools sent it, written out.
String _url(String command, String timeType) =>
    'https://ssd.jpl.nasa.gov/api/horizons.api?format=text'
    '&COMMAND=%27$command%27&OBJ_DATA=%27NO%27&MAKE_EPHEM=%27YES%27'
    '&EPHEM_TYPE=%27OBSERVER%27&CENTER=%27500%40399%27&TLIST_TYPE=%27JD%27'
    '&TLIST=%272451545.000000000+2451546.000000000%27'
    '&TIME_TYPE=%27$timeType%27&TIME_DIGITS=%27SECONDS%27'
    '&QUANTITIES=%2731%27&ANG_FORMAT=%27DEG%27&EXTRA_PREC=%27YES%27'
    '&CSV_FORMAT=%27YES%27';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// An answer to [uri] in the format the tools ask for (calendar dates to the
/// second).
List<int> _answerTo(Uri uri) {
  String parameter(String name) =>
      uri.queryParameters[name]!.replaceAll("'", '');
  final command = parameter('COMMAND');
  final scale = parameter('TIME_TYPE');
  String two(int v) => '$v'.padLeft(2, '0');
  final rows = [
    for (final day in parameter('TLIST').split(' '))
      () {
        final t = DateTime.fromMillisecondsSinceEpoch(
          ((double.parse(day) - 2440587.5) * 86400e3).round(),
          isUtc: true,
        );
        return ' ${t.year}-${_months[t.month - 1]}-${two(t.day)} '
            '${two(t.hour)}:${two(t.minute)}:${two(t.second)}, , , '
            '${(int.parse(command) / 10 + 1).toStringAsFixed(7)},  0.0,\n';
      }(),
  ].join();
  return ('API VERSION: 1.2\n'
          'Target body name: Body ($command)    {source: DE441}\n'
          'Center body name: Earth (399)        {source: DE441}\n'
          'Center-site name: GEOCENTRIC\n'
          'Start time      : A.D. 1899-Dec-31 12:00:00 $scale      \n'
          'Stop  time      : A.D. 2100-Jan-01 12:00:00 $scale      \n'
          ' Date__($scale)__HR:MN:SS, , , ObsEcLon, ObsEcLat,\n'
          '\$\$SOE\n$rows\$\$EOE\n')
      .codeUnits;
}

typedef _Tool = Future<int> Function(
  List<String> arguments, {
  required Uri packageRoot,
  required Future<HorizonsResponse> Function(Uri uri) get,
  required Future<void> Function(Duration duration) pause,
  required StringSink out,
  required StringSink err,
});

Future<int> _runTt(
  List<String> arguments, {
  required Uri packageRoot,
  required Future<HorizonsResponse> Function(Uri uri) get,
  required Future<void> Function(Duration duration) pause,
  required StringSink out,
  required StringSink err,
}) => tt.runBackupTool(
  arguments,
  packageRoot: packageRoot,
  get: get,
  pause: pause,
  out: out,
  err: err,
  libraryTimes: (utDays) => [
    for (final day in utDays) (ut: day, tt: day + 69.184 / 86400),
  ],
);

/// A test during which opening a connection fails.
void _offlineTest(String name, Future<void> Function() body) {
  test(
    name,
    () => HttpOverrides.runZoned(
      body,
      createHttpClient: (_) =>
          throw StateError('a test tried to open a connection'),
    ),
  );
}

void main() {
  late Directory scratch;
  late Uri packageRoot;

  setUp(() {
    scratch = Directory.systemTemp.createTempSync('zod_tst_001_backup');
    packageRoot = (Directory(
      '${scratch.path}/repo/packages/ephemeris_astronomy',
    )..createSync(recursive: true)).uri;
    Directory.fromUri(packageRoot.resolve('test/fixtures/'))
        .createSync(recursive: true);
    Directory.fromUri(
      packageRoot.resolve('../../apps/astro_mobile/integration_test/'),
    ).createSync(recursive: true);
    File.fromUri(
        packageRoot.resolve('../astro_core/test/fixtures/reference_dates.json'),
      )
      ..createSync(recursive: true)
      ..writeAsStringSync(
        jsonEncode({
          'version': 2,
          'dates': [
            '2100-07-01T00:00:00Z',
            '1899-12-31T12:00:00Z',
            '2100-01-01T12:00:00Z',
            '2000-01-01T00:00:00Z',
          ],
        }),
      );
  });
  tearDown(() => scratch.deleteSync(recursive: true));

  String inScratch(String name) => '${scratch.path}/$name';

  test('the covered instants of the shared date set are the 61', () {
    final dates =
        ((jsonDecode(
                  File('../astro_core/test/fixtures/reference_dates.json')
                      .readAsStringSync(),
                ) as Map<String, Object?>)['dates']!
                as List<Object?>)
            .cast<String>();
    final covered = backupInstants(dates);

    expect(covered, hasLength(61));
    expect(covered.first, '1899-12-31T12:00:00Z');
    expect(covered.last, '2100-01-01T12:00:00Z');
    expect(dates.toSet().difference(covered.toSet()), {
      '2100-07-01T00:00:00Z',
      '2100-12-31T00:00:00Z',
      '2100-12-31T23:59:59Z',
    });
  });

  test('backupInstants sorts and keeps both boundaries', () {
    expect(
      backupInstants([
        '2100-01-01T12:00:01Z',
        '2100-01-01T12:00:00Z',
        '1899-12-31T11:59:59Z',
        '1899-12-31T12:00:00Z',
      ]),
      ['1899-12-31T12:00:00Z', '2100-01-01T12:00:00Z'],
    );
  });

  test('each tool asks with the parameters it always did', () {
    const times = ['2451545.000000000', '2451546.000000000'];
    expect(
      [for (final uri in ut.backupRequestUris(times)) '$uri'],
      [for (final command in _commands) _url(command, 'UT')],
    );
    expect(
      [for (final uri in tt.backupRequestUris(times)) '$uri'],
      [for (final command in _commands) _url(command, 'TT')],
    );
  });

  group('downloadHorizonsAnswer', () {
    _offlineTest('saves the bytes and returns them decoded', () async {
      final text = await downloadHorizonsAnswer(
        scratch,
        'a',
        Uri.parse('https://example.invalid/'),
        (_) async => (statusCode: 200, bytes: 'answer\n'.codeUnits),
      );
      expect(text, 'answer\n');
      expect(File(inScratch('a.txt')).readAsStringSync(), 'answer\n');
    });

    _offlineTest('saves a non-200 body and throws', () async {
      await expectLater(
        downloadHorizonsAnswer(
          scratch,
          'a',
          Uri.parse('https://example.invalid/'),
          (_) async => (statusCode: 503, bytes: 'busy\n'.codeUnits),
        ),
        throwsA(isA<HttpException>()),
      );
      expect(File(inScratch('a.http503.txt')).readAsStringSync(), 'busy\n');
      expect(File(inScratch('a.txt')).existsSync(), isFalse);
    });
  });

  group('checkHorizonsHeader', () {
    String sample(String scale) =>
        File('../ephemeris_swiss/test/fixtures/horizons_sample_$scale.txt')
            .readAsStringSync();

    test('accepts both pilot samples', () {
      checkHorizonsHeader(sample('tt'), command: '301', timeScale: 'TT');
      checkHorizonsHeader(sample('ut'), command: '301', timeScale: 'UT');
    });

    for (final (name, change) in <(String, String Function(String))>[
      (
        'another centre body',
        (s) => s.replaceFirst('Earth (399)', 'Mars (499)'),
      ),
      ('another site', (s) => s.replaceFirst('GEOCENTRIC', 'ELSEWHERE')),
      (
        'another scale at the stop',
        (s) => s.replaceFirst('00:01:08.1840 TT', '00:01:08.1840 UT'),
      ),
      (
        'another scale at the start',
        (s) => s.replaceFirst('12:00:00.0000 TT', '12:00:00.0000 UT'),
      ),
      (r'no $$SOE', (s) => s.replaceFirst(r'$$SOE', 'SOE')),
      (r'no $$EOE', (s) => s.replaceFirst(r'$$EOE', 'EOE')),
    ]) {
      test('refuses $name', () {
        final original = sample('tt');
        final changed = change(original);
        expect(changed, isNot(original));
        expect(
          () => checkHorizonsHeader(changed, command: '301', timeScale: 'TT'),
          throwsFormatException,
        );
      });
    }

    test('refuses another body', () {
      expect(
        () => checkHorizonsHeader(sample('tt'), command: '10', timeScale: 'TT'),
        throwsFormatException,
      );
    });
  });

  for (final (name, tool, scale, fixtureName, copyName)
      in <(String, _Tool, String, String, String)>[
        (
          'the UTC tool',
          ut.runBackupTool,
          'UT',
          'reference_longitudes.json',
          'astronomy_reference_longitudes.dart',
        ),
        (
          'the TT tool',
          _runTt,
          'TT',
          'reference_longitudes_tt.json',
          'astronomy_reference_longitudes_tt.dart',
        ),
      ]) {
    group(name, () {
      late List<Uri> requested;
      late List<String> events;
      late StringBuffer err;
      File fixture() =>
          File.fromUri(packageRoot.resolve('test/fixtures/$fixtureName'));
      File copy() => File.fromUri(
        packageRoot.resolve(
          '../../apps/astro_mobile/integration_test/$copyName',
        ),
      );
      setUp(() {
        requested = [];
        events = [];
        err = StringBuffer();
      });

      Future<int> run(
        List<String> arguments, {
        Future<HorizonsResponse> Function(Uri uri)? answer,
      }) => tool(
        arguments,
        packageRoot: packageRoot,
        get: (uri) {
          requested.add(uri);
          events.add('get');
          return answer?.call(uri) ??
              Future.value((statusCode: 200, bytes: _answerTo(uri)));
        },
        pause: (duration) async =>
            events.add('pause ${duration.inMilliseconds}'),
        out: StringBuffer(),
        err: err,
      );

      _offlineTest('needs a new --out outside the repository', () async {
        File(inScratch('kept.txt')).writeAsStringSync('kept');
        for (final arguments in [
          <String>[],
          ['--out'],
          ['--out', ''],
          ['--dir', inScratch('raw')],
          ['--out', inScratch('repo/raw')],
          ['--out', scratch.path],
        ]) {
          expect(await run(arguments), 64, reason: '$arguments');
        }
        expect(requested, isEmpty);
        expect(fixture().existsSync(), isFalse);
      });

      _offlineTest('writes both files after ten answers', () async {
        final existed = <bool>[];
        expect(
          await run(
            ['--out', inScratch('raw')],
            answer: (uri) async {
              existed.add(fixture().existsSync() || copy().existsSync());
              return (statusCode: 200, bytes: _answerTo(uri));
            },
          ),
          0,
        );

        expect(existed, List.filled(10, false));
        expect(events, [
          'get',
          for (var i = 1; i < 10; i++) ...['pause 1000', 'get'],
        ]);
        expect([
          for (final uri in requested) uri.queryParameters['TIME_TYPE'],
        ], List.filled(10, "'$scale'"));
        final json =
            jsonDecode(fixture().readAsStringSync()) as Map<String, Object?>;
        final entries = (json['entries']! as List<Object?>)
            .cast<Map<String, Object?>>();
        // Three covered instants: the one after the range is not asked.
        expect(entries, hasLength(30));
        expect(
          {for (final e in entries) e['utc']},
          {
            '1899-12-31T12:00:00Z',
            '2000-01-01T00:00:00Z',
            '2100-01-01T12:00:00Z',
          },
        );
        expect(
          json['instants'],
          'every instant of reference_dates.json within 1899-12-31T12:00Z to '
          '2100-01-01T12:00Z (3 at the time of the fetch)',
        );
        expect(entries.first['longitudeDegrees'], 2.0);
        expect(copy().readAsStringSync(), contains('longitudeDegrees: 2.0'));
        expect(Directory(inScratch('raw')).listSync(), hasLength(10));
        expect(
          File(inScratch('raw/01_10_$scale.txt')).readAsBytesSync(),
          _answerTo(requested.first),
        );
      });

      for (final (failure, third) in <(String, HorizonsResponse)>[
        ('a refused', (statusCode: 200, bytes: 'no data\n'.codeUnits)),
        ('a non-200', (statusCode: 503, bytes: 'busy\n'.codeUnits)),
      ]) {
        _offlineTest(
          '$failure third answer stops and writes nothing',
          () async {
            await expectLater(
              run(
                ['--out', inScratch('raw')],
                answer: (uri) async => requested.length == 3
                    ? third
                    : (statusCode: 200, bytes: _answerTo(uri)),
              ),
              throwsA(anything),
            );
            expect(requested, hasLength(3));
            expect(Directory(inScratch('raw')).listSync(), hasLength(3));
            expect(fixture().existsSync(), isFalse);
            expect(copy().existsSync(), isFalse);
          },
        );
      }

      _offlineTest('a wrong time scale stops the run', () async {
        await expectLater(
          run(
            ['--out', inScratch('raw')],
            answer: (uri) async => (
              statusCode: 200,
              bytes: _answerTo(
                uri.replace(
                  queryParameters: {
                    ...uri.queryParameters,
                    'TIME_TYPE': "'${scale == 'UT' ? 'TT' : 'UT'}'",
                  },
                ),
              ),
            ),
          ),
          throwsFormatException,
        );
        expect(requested, hasLength(1));
        expect(fixture().existsSync(), isFalse);
      });
    });
  }
}
