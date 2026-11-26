// ZOD-EPH-002: fetches the JPL Horizons reference longitudes for the
// matched-TT accuracy gate, and writes two files. Run from this package's root,
// with network access and `gcc` on the PATH:
//
//   dart run tool/fetch_horizons_tt_reference.dart
//
// * test/fixtures/reference_longitudes_tt.json: the fixture.
// * ../../apps/astro_mobile/integration_test/swiss_reference_longitudes_tt.dart:
//   a Dart const copy for the device test.
//
// The TT of each of the 53 instants of
// packages/astro_core/test/fixtures/reference_dates.json is the TT the app's
// conversion gives: from 1972, `ephemerisTimeFor` (astro_core); before 1972,
// the instant as UT plus the delta T of the vendored Swiss Ephemeris, printed
// by tool/tt_grid.c (compiled here with gcc). The device test pins this against
// the device's own conversion, so the device cannot convert differently from
// this tool unnoticed. Neither can see an error in the conversion itself,
// which both share: from 1972 that is checked by
// test/reference_tt_fixture_test.dart, which compares these longitudes with
// the ZOD-EPH-004 reference asked at UTC.
//
// Horizons is asked with TIME_TYPE='TT' at that Julian day, nine decimals
// (about 86 microseconds). It returns rows in chronological order, so the
// instants are sorted and every row's printed date is checked against the TT
// requested. The request holds dates and body numbers only.
//
// One-off tool, not part of the app (the app never touches the network:
// test/architecture/no_network_test.dart).
import 'dart:convert';
import 'dart:io';

import 'package:astro_core/astro_core.dart';
import 'package:ephemeris_swiss/ephemeris_swiss.dart';

const _commands = {
  'sun': '10',
  'moon': '301',
  'mercury': '199',
  'venus': '299',
  'mars': '499',
  'jupiter': '599',
  'saturn': '699',
  'uranus': '799',
  'neptune': '899',
  'pluto': '999',
};

const _months = {
  'Jan': 1,
  'Feb': 2,
  'Mar': 3,
  'Apr': 4,
  'May': 5,
  'Jun': 6,
  'Jul': 7,
  'Aug': 8,
  'Sep': 9,
  'Oct': 10,
  'Nov': 11,
  'Dec': 12,
};

/// The nine library objects named by upstream's `Makefile`.
const _librarySources = [
  'swedate.c',
  'swehouse.c',
  'swejpl.c',
  'swemmoon.c',
  'swemplan.c',
  'sweph.c',
  'swephlib.c',
  'swecl.c',
  'swehel.c',
];

/// Owner decision 2026-11-26: one arcsecond for all ten bodies.
const _toleranceArcseconds = 1;

/// A printed Horizons date, `2026-Jan-01 00:00:00`, as an instant (the scale
/// is the one requested: here TT).
DateTime _parsePrinted(String text) {
  final m = RegExp(r'^\s*(\d{4})-([A-Za-z]{3})-(\d{2}) (\d{2}):(\d{2}):(\d{2})')
      .firstMatch(text);
  if (m == null) throw FormatException('unrecognised Horizons date', text);
  return DateTime.utc(
    int.parse(m.group(1)!),
    _months[m.group(2)!]!,
    int.parse(m.group(3)!),
    int.parse(m.group(4)!),
    int.parse(m.group(5)!),
    int.parse(m.group(6)!),
  );
}

Future<String> _get(Uri uri) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(uri);
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode != 200) {
      throw HttpException('HTTP ${response.statusCode}: $body', uri: uri);
    }
    return body;
  } finally {
    client.close();
  }
}

/// The delta T, in seconds, the vendored library applies to each UT Julian day,
/// from the host-compiled `tool/tt_grid.c`.
List<double> _libraryDeltaT(Uri packageRoot, List<double> julianDaysUt) {
  final workDir = Directory.systemTemp.createTempSync('swiss_tt_grid');
  try {
    final upstream = packageRoot.resolve('../../native/swisseph/upstream/');
    final exe = '${workDir.path}${Platform.pathSeparator}tt_grid';
    final compile = Process.runSync('gcc', [
      '-O1',
      '-std=gnu99',
      '-I',
      upstream.toFilePath(),
      '-o',
      exe,
      packageRoot.resolve('tool/tt_grid.c').toFilePath(),
      for (final source in _librarySources)
        upstream.resolve(source).toFilePath(),
      '-lm',
    ]);
    if (compile.exitCode != 0) {
      throw StateError('gcc failed:\n${compile.stdout}\n${compile.stderr}');
    }
    final run = Process.runSync(exe, [
      packageRoot.resolve('assets/ephe').toFilePath(),
      for (final day in julianDaysUt) '$day',
    ]);
    if (run.exitCode != 0) throw StateError('tt_grid failed: ${run.stderr}');
    final lines = (run.stdout as String)
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();
    if (lines.length != julianDaysUt.length) {
      throw StateError('tt_grid printed ${lines.length} lines');
    }
    return [for (final line in lines) double.parse(line.trim())];
  } finally {
    workDir.deleteSync(recursive: true);
  }
}

Future<void> main() async {
  final packageRoot = Platform.script.resolve('../');
  final datesFile = File.fromUri(
    packageRoot.resolve('../astro_core/test/fixtures/reference_dates.json'),
  );
  final dateStrings =
      ((jsonDecode(datesFile.readAsStringSync())
                  as Map<String, Object?>)['dates']!
              as List<Object?>)
          .cast<String>()
          .toList()
        ..sort((a, b) => DateTime.parse(a).compareTo(DateTime.parse(b)));
  final instants = [for (final s in dateStrings) DateTime.parse(s)];

  final universal = [
    for (final utc in instants)
      if (ephemerisTimeFor(utc) is UniversalTime) utc,
  ];
  final deltaT = _libraryDeltaT(packageRoot, [
    for (final utc in universal) julianDayUt(utc),
  ]);
  final universalDeltaT = {
    for (var i = 0; i < universal.length; i++) universal[i]: deltaT[i],
  };

  final times = [
    for (final utc in instants)
      switch (ephemerisTimeFor(utc)) {
        TerrestrialTime(:final ttMinusUtc) => (
          jdTt: julianDayUt(utc.add(ttMinusUtc)).toStringAsFixed(9),
          seconds: ttMinusUtc.inMicroseconds / 1000000,
        ),
        UniversalTime() => (
          jdTt: (julianDayUt(utc) + universalDeltaT[utc]! / 86400)
              .toStringAsFixed(9),
          seconds: universalDeltaT[utc]!,
        ),
      },
  ];
  final timeList = [for (final t in times) t.jdTt].join(' ');

  final entries = <Map<String, Object?>>[];
  for (final MapEntry(key: body, value: command) in _commands.entries) {
    final text = await _get(
      Uri.https('ssd.jpl.nasa.gov', '/api/horizons.api', {
        'format': 'text',
        'COMMAND': "'$command'",
        'OBJ_DATA': "'NO'",
        'MAKE_EPHEM': "'YES'",
        'EPHEM_TYPE': "'OBSERVER'",
        'CENTER': "'500@399'",
        'TLIST_TYPE': "'JD'",
        'TLIST': "'$timeList'",
        'TIME_TYPE': "'TT'",
        'TIME_DIGITS': "'SECONDS'",
        'QUANTITIES': "'31'",
        'ANG_FORMAT': "'DEG'",
        'EXTRA_PREC': "'YES'",
        'CSV_FORMAT': "'YES'",
      }),
    );
    final start = text.indexOf(r'$$SOE');
    final end = text.indexOf(r'$$EOE');
    if (start < 0 || end < 0) {
      throw StateError('no ephemeris in the answer for $body:\n$text');
    }
    final rows = text
        .substring(start + 5, end)
        .split('\n')
        .map((r) => r.trim())
        .where((r) => r.isNotEmpty)
        .toList();
    if (rows.length != instants.length) {
      throw StateError(
        '$body: ${rows.length} rows for ${instants.length} instants',
      );
    }
    for (var i = 0; i < rows.length; i++) {
      final fields = rows[i].split(',');
      final printed = _parsePrinted(fields[0]);
      final requested = DateTime.fromMicrosecondsSinceEpoch(
        ((double.parse(times[i].jdTt) - 2440587.5) * 86400e6).round(),
        isUtc: true,
      );
      if (printed.difference(requested).inMilliseconds.abs() > 1500) {
        throw StateError(
          '$body row $i: printed ${fields[0].trim()} but requested TT '
          '$requested (JD ${times[i].jdTt})',
        );
      }
      entries.add({
        'body': body,
        'utc': dateStrings[i],
        'jdTt': times[i].jdTt,
        'ttMinusUtSeconds': times[i].seconds,
        'longitudeDegrees': double.parse(fields[3].trim()),
      });
    }
    stdout.writeln('$body: ${rows.length} rows');
    await Future<void>.delayed(const Duration(seconds: 1));
  }

  final retrievedOn = DateTime.now().toUtc().toIso8601String().substring(0, 10);
  final fixture = {
    'source': 'JPL Horizons API (https://ssd.jpl.nasa.gov/api/horizons.api)',
    'retrievedOn': retrievedOn,
    'quantity':
        '31 (Observer ecliptic longitude): per the Horizons manual, '
        'IAU76/80 ecliptic-of-date longitude of the apparent position with '
        'light-time, gravitational deflection and stellar aberration; '
        'ZOD-FND-003 found it agrees with the true equinox of date',
    'timeScale':
        'Each entry is asked at the TT the app gives its UTC instant: from '
        '1972 UTC + (TAI - UTC) + 32.184 s (astro_core ephemerisTimeFor); '
        'before 1972 UT + the delta T of the vendored Swiss Ephemeris '
        '(tool/tt_grid.c). ttMinusUtSeconds is that difference.',
    'queryParameters': {
      'COMMAND': _commands,
      'CENTER': '500@399',
      'EPHEM_TYPE': 'OBSERVER',
      'QUANTITIES': '31',
      'TLIST_TYPE': 'JD',
      'TIME_TYPE': 'TT',
      'TIME_DIGITS': 'SECONDS',
      'ANG_FORMAT': 'DEG',
      'EXTRA_PREC': 'YES',
      'CSV_FORMAT': 'YES',
      'OBJ_DATA': 'NO',
    },
    'instants':
        'every instant of packages/astro_core/test/fixtures/reference_dates.json '
        '(${instants.length} at the time of the fetch)',
    'toleranceArcseconds': _toleranceArcseconds,
    'entries': entries,
  };
  File.fromUri(
    packageRoot.resolve('test/fixtures/reference_longitudes_tt.json'),
  ).writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(fixture)}\n',
  );

  final copy = StringBuffer()
    ..writeln('// ZOD-EPH-002: GENERATED by')
    ..writeln(
      '// packages/ephemeris_swiss/tool/fetch_horizons_tt_reference.dart from',
    )
    ..writeln(
      '// packages/ephemeris_swiss/test/fixtures/reference_longitudes_tt.json',
    )
    ..writeln(
      '// (JPL Horizons, quantity 31, geocentric, apparent, asked at TT,',
    )
    ..writeln(
      '// retrieved $retrievedOn). `test/swiss_reference_longitudes_tt_match_test.dart`',
    )
    ..writeln(
      '// keeps this copy equal to the fixture. `utc` is an ISO-8601 string',
    )
    ..writeln('// because DateTime is not const.')
    ..writeln()
    ..writeln('/// Tolerance in arcseconds (owner decision 2026-11-26).')
    ..writeln(
      'const double swissTtToleranceArcseconds = $_toleranceArcseconds;',
    )
    ..writeln()
    ..writeln('typedef SwissTtReference = ({')
    ..writeln('  String body,')
    ..writeln('  String utc,')
    ..writeln('  String jdTt,')
    ..writeln('  double ttMinusUtSeconds,')
    ..writeln('  double longitudeDegrees,')
    ..writeln('});')
    ..writeln()
    ..writeln('const swissTtReferenceLongitudes = <SwissTtReference>[');
  for (final e in entries) {
    copy.writeln(
      "  (body: '${e['body']}', utc: '${e['utc']}', jdTt: '${e['jdTt']}', "
      'ttMinusUtSeconds: ${e['ttMinusUtSeconds']}, '
      'longitudeDegrees: ${e['longitudeDegrees']}),',
    );
  }
  copy.writeln('];');
  File.fromUri(
    packageRoot.resolve(
      '../../apps/astro_mobile/integration_test/swiss_reference_longitudes_tt.dart',
    ),
  ).writeAsStringSync(copy.toString());
  stdout.writeln('wrote ${entries.length} entries');
}
