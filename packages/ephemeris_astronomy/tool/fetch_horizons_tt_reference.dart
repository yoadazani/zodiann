// ZOD-EPH-004 D12 (Task 5 Step 7): fetches the JPL Horizons reference
// longitudes for ACC-2 at the TT instants that the adapter's own UTC-to-TT
// conversion assigns to the reference UTC instants, and writes two files. Run
// from this package's root, with network access and `gcc` on the PATH:
//
//   dart run tool/fetch_horizons_tt_reference.dart
//
// * test/fixtures/reference_longitudes_tt.json: the fixture.
// * ../../apps/astro_mobile/integration_test/astronomy_reference_longitudes_tt.dart:
//   a Dart const copy for the device test.
//
// How the TT of an instant is established (D12): for each of the 53 instants
// of packages/astro_core/test/fixtures/reference_dates.json, `utDays` is the
// adapter's own `daysSinceJ2000`, and `tool/tt_grid.c` (compiled here with
// gcc, linked with the vendored upstream astronomy.c) prints the UT and TT
// days that Astronomy_TimeFromDays assigns. The device test then pins both
// against the device's own hook, so a different conversion cannot hide.
//
// Horizons is asked with TIME_TYPE='TT' at JD_TT = ttDays + 2451545.0, nine
// decimals (about 86 microseconds). Horizons returns rows in chronological
// order whatever the order of the list (ZOD-FND-003 gotcha 6), so the instants
// are sorted and every returned row's printed date is checked against the TT
// requested. Limit of that check: with TIME_DIGITS='SECONDS' and a tolerance
// of 1.5 s the echo cannot tell TT from UT where |deltaT| is under about
// 1.5 s (about 1900 to 1905), so it validates the ordering and the second;
// the nine-decimal JD in the request carries the precision.
//
// One-off tool, not part of the app (the app never touches the network:
// test/architecture/no_network_test.dart).
import 'dart:convert';
import 'dart:io';

import 'package:ephemeris_astronomy/ephemeris_astronomy.dart';

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

/// ACC-2: one arcminute.
const _toleranceArcseconds = 60;

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

/// The UT and TT days the vendored library assigns to each of [utDays], from
/// the host-compiled `tool/tt_grid.c`.
List<({double ut, double tt})> _libraryTimes(
  Uri packageRoot,
  List<double> utDays,
) {
  final workDir = Directory.systemTemp.createTempSync('tt_grid');
  try {
    final exe = '${workDir.path}${Platform.pathSeparator}tt_grid';
    final compile = Process.runSync('gcc', [
      '-O0',
      '-ffp-contract=off',
      '-o',
      exe,
      packageRoot.resolve('tool/tt_grid.c').toFilePath(),
      '-lm',
    ]);
    if (compile.exitCode != 0) {
      throw StateError('gcc failed:\n${compile.stdout}\n${compile.stderr}');
    }
    final run = Process.runSync(exe, [for (final d in utDays) '$d']);
    if (run.exitCode != 0) throw StateError('tt_grid failed: ${run.stderr}');
    final lines = (run.stdout as String)
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();
    if (lines.length != utDays.length) {
      throw StateError('tt_grid printed ${lines.length} lines');
    }
    return [
      for (final line in lines)
        (
          ut: double.parse(line.split(' ')[0]),
          tt: double.parse(line.split(' ')[1]),
        ),
    ];
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
  final utDays = [for (final u in instants) daysSinceJ2000(u)];
  final library = _libraryTimes(packageRoot, utDays);
  for (var i = 0; i < utDays.length; i++) {
    if (library[i].ut != utDays[i]) {
      throw StateError(
        '${dateStrings[i]}: the library UT ${library[i].ut} differs from '
        'the adapter UT ${utDays[i]}',
      );
    }
  }
  final jdTt = [for (final t in library) (t.tt + 2451545.0).toStringAsFixed(9)];
  final timeList = jdTt.join(' ');

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
      final requestedMicros = ((double.parse(jdTt[i]) - 2440587.5) * 86400e6)
          .round();
      final requested = DateTime.fromMicrosecondsSinceEpoch(
        requestedMicros,
        isUtc: true,
      );
      final offset = printed.difference(requested).inMilliseconds.abs();
      if (offset > 1500) {
        throw StateError(
          '$body row $i: printed ${fields[0].trim()} but requested TT '
          '$requested (JD ${jdTt[i]})',
        );
      }
      entries.add({
        'body': body,
        'utc': dateStrings[i],
        'utDays': utDays[i],
        'ttDays': library[i].tt,
        'deltaTSeconds': (library[i].tt - library[i].ut) * 86400,
        'jdTt': jdTt[i],
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
        'Each entry is asked at the TT that the adapter\'s own conversion '
        'assigns to its UTC instant: ttDays is Astronomy_TimeFromDays(utDays).tt '
        'of the vendored astronomy-engine, jdTt = ttDays + 2451545.0. The '
        'device test pins ttDays and deltaTSeconds against the device\'s own '
        'hook within 1 millisecond. This comparison cannot see an error in '
        'the library\'s delta T (docs/spikes/ZOD-EPH-004-delta-t.md).',
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
    ..writeln('// ZOD-EPH-004 D12: GENERATED by')
    ..writeln(
      '// packages/ephemeris_astronomy/tool/fetch_horizons_tt_reference.dart from',
    )
    ..writeln(
      '// packages/ephemeris_astronomy/test/fixtures/reference_longitudes_tt.json',
    )
    ..writeln(
      '// (JPL Horizons, quantity 31, geocentric, apparent, asked at the',
    )
    ..writeln('// TT the adapter assigns to each UTC instant, retrieved')
    ..writeln(
      '// $retrievedOn). `test/astronomy_reference_longitudes_tt_match_test.dart`',
    )
    ..writeln(
      '// keeps this copy equal to the fixture. `utc` is an ISO-8601 string',
    )
    ..writeln('// because DateTime is not const.')
    ..writeln()
    ..writeln('/// Tolerance in arcseconds (ACC-2: one arcminute).')
    ..writeln(
      'const double astronomyTtToleranceArcseconds = $_toleranceArcseconds;',
    )
    ..writeln()
    ..writeln('typedef AstronomyTtReference = ({')
    ..writeln('  String body,')
    ..writeln('  String utc,')
    ..writeln('  double utDays,')
    ..writeln('  double ttDays,')
    ..writeln('  double deltaTSeconds,')
    ..writeln('  double longitudeDegrees,')
    ..writeln('});')
    ..writeln()
    ..writeln('const astronomyTtReferenceLongitudes = <AstronomyTtReference>[');
  for (final e in entries) {
    copy.writeln(
      "  (body: '${e['body']}', utc: '${e['utc']}', utDays: ${e['utDays']}, "
      'ttDays: ${e['ttDays']}, deltaTSeconds: ${e['deltaTSeconds']}, '
      'longitudeDegrees: ${e['longitudeDegrees']}),',
    );
  }
  copy.writeln('];');
  File.fromUri(
    packageRoot.resolve(
      '../../apps/astro_mobile/integration_test/astronomy_reference_longitudes_tt.dart',
    ),
  ).writeAsStringSync(copy.toString());
  stdout.writeln('wrote ${entries.length} entries');
}
