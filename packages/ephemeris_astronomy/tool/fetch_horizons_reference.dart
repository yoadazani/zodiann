// ZOD-EPH-004 Task 5: fetches the JPL Horizons reference longitudes for ACC-2
// and writes two files. Run from this package's root, with network access:
//
//   dart run tool/fetch_horizons_reference.dart --out <directory for answers>
//
// * test/fixtures/reference_longitudes.json: the fixture (all ten physical
//   bodies at every instant of reference_dates.json within 1899-12-31T12:00Z to
//   2100-01-01T12:00Z, the Backup's covered range; ZOD-TST-001).
// * ../../apps/astro_mobile/integration_test/astronomy_reference_longitudes.dart:
//   a Dart const copy for the device test (the fixture is not an app asset).
//
// This is a one-off tool, not part of the app: the app never touches the
// network (test/architecture/no_network_test.dart). Horizons returns rows in
// chronological order whatever the order of the time list (ZOD-FND-003 gotcha
// 6), so the instants are sorted and every returned row's printed date is
// checked against the instant requested.
import 'dart:convert';
import 'dart:io';

import '../../ephemeris_swiss/tool/horizons/download.dart';

/// Horizons command ids: the Sun, the Moon, the planet centres and Pluto.
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

/// The Julian day of the UTC instant [utc], with nine decimals (about 86
/// microseconds).
String _julianDay(DateTime utc) =>
    (utc.microsecondsSinceEpoch / 86400000000 + 2440587.5).toStringAsFixed(9);

/// A printed Horizons date, `2026-Jan-01 00:00:00`, as a UTC instant.
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

/// The ten requests, one per body, at the Julian days [times] (UT).
List<Uri> backupRequestUris(List<String> times) => [
  for (final command in _commands.values)
    Uri.https('ssd.jpl.nasa.gov', '/api/horizons.api', {
      'format': 'text',
      'COMMAND': "'$command'",
      'OBJ_DATA': "'NO'",
      'MAKE_EPHEM': "'YES'",
      'EPHEM_TYPE': "'OBSERVER'",
      'CENTER': "'500@399'",
      'TLIST_TYPE': "'JD'",
      'TLIST': "'${times.join(' ')}'",
      'TIME_TYPE': "'UT'",
      'TIME_DIGITS': "'SECONDS'",
      'QUANTITIES': "'31'",
      'ANG_FORMAT': "'DEG'",
      'EXTRA_PREC': "'YES'",
      'CSV_FORMAT': "'YES'",
    }),
];

const _usage =
    'usage: dart run tool/fetch_horizons_reference.dart '
    '--out <new or empty directory outside the repository>';

/// Sends the ten requests one at a time, a second apart, saving each answer in
/// the `--out` directory before reading it, and writes the two files only after
/// all ten. Returns 64, before any request, for a wrong command line or output
/// directory. A request that fails or an answer that does not match throws, and
/// nothing further is sent.
Future<int> runBackupTool(
  List<String> arguments, {
  required Uri packageRoot,
  required Future<HorizonsResponse> Function(Uri uri) get,
  required Future<void> Function(Duration duration) pause,
  required StringSink out,
  required StringSink err,
}) async {
  final String? refusal = switch (arguments) {
    ['--out', final path] when path.isNotEmpty => horizonsOutputRefusal(
      packageRoot.resolve('../../'),
      path,
    ),
    _ => 'unrecognised arguments: ${arguments.join(' ')}',
  };
  if (refusal != null) {
    err.writeln('$refusal\n$_usage');
    return 64;
  }
  final datesFile = File.fromUri(
    packageRoot.resolve('../astro_core/test/fixtures/reference_dates.json'),
  );
  final dateStrings = backupInstants(
    ((jsonDecode(datesFile.readAsStringSync())
                as Map<String, Object?>)['dates']!
            as List<Object?>)
        .cast<String>(),
  );
  final instants = [for (final s in dateStrings) DateTime.parse(s)];
  final uris = backupRequestUris([for (final t in instants) _julianDay(t)]);
  final directory = Directory(arguments[1])..createSync(recursive: true);

  final entries = <Map<String, Object?>>[];
  for (final (index, MapEntry(key: body, value: command))
      in _commands.entries.indexed) {
    if (index > 0) await pause(const Duration(seconds: 1));
    final text = await downloadHorizonsAnswer(
      directory,
      '${'${index + 1}'.padLeft(2, '0')}_${command}_UT',
      uris[index],
      get,
    );
    checkHorizonsHeader(text, command: command, timeScale: 'UT');
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
      final offset = printed.difference(instants[i]).inMilliseconds.abs();
      if (offset > 1500) {
        throw StateError(
          '$body row $i: printed ${fields[0].trim()} but requested ${instants[i]}',
        );
      }
      entries.add({
        'body': body,
        'utc': dateStrings[i],
        'longitudeDegrees': double.parse(fields[3].trim()),
      });
    }
    out.writeln('$body: ${rows.length} rows');
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
    'queryParameters': {
      'COMMAND': _commands,
      'CENTER': '500@399',
      'EPHEM_TYPE': 'OBSERVER',
      'QUANTITIES': '31',
      'TLIST_TYPE': 'JD',
      'TIME_TYPE': 'UT',
      'TIME_DIGITS': 'SECONDS',
      'ANG_FORMAT': 'DEG',
      'EXTRA_PREC': 'YES',
      'CSV_FORMAT': 'YES',
      'OBJ_DATA': 'NO',
    },
    'instants':
        'every instant of reference_dates.json within 1899-12-31T12:00Z to '
        '2100-01-01T12:00Z (${instants.length} at the time of the fetch)',
    'toleranceArcseconds': _toleranceArcseconds,
    'entries': entries,
  };
  File.fromUri(packageRoot.resolve('test/fixtures/reference_longitudes.json'))
      .writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(fixture)}\n',
      );

  final const_ = StringBuffer()
    ..writeln('// ZOD-EPH-004: GENERATED by')
    ..writeln(
      '// packages/ephemeris_astronomy/tool/fetch_horizons_reference.dart from',
    )
    ..writeln(
      '// packages/ephemeris_astronomy/test/fixtures/reference_longitudes.json',
    )
    ..writeln('// (JPL Horizons, quantity 31, geocentric, apparent, retrieved')
    ..writeln(
      '// $retrievedOn). `test/astronomy_reference_longitudes_match_test.dart`',
    )
    ..writeln(
      '// keeps this copy equal to the fixture. `utc` is an ISO-8601 string',
    )
    ..writeln('// because DateTime is not const.')
    ..writeln()
    ..writeln('/// Tolerance in arcseconds (ACC-2: one arcminute).')
    ..writeln(
      'const double astronomyToleranceArcseconds = $_toleranceArcseconds;',
    )
    ..writeln()
    ..writeln('const astronomyReferenceLongitudes =')
    ..writeln('    <({String body, String utc, double longitudeDegrees})>[');
  for (final e in entries) {
    const_.writeln(
      "      (body: '${e['body']}', utc: '${e['utc']}', "
      'longitudeDegrees: ${e['longitudeDegrees']}),',
    );
  }
  const_.writeln('    ];');
  File.fromUri(
    packageRoot.resolve(
      '../../apps/astro_mobile/integration_test/astronomy_reference_longitudes.dart',
    ),
  ).writeAsStringSync(const_.toString());
  out.writeln('wrote ${entries.length} entries');
  return 0;
}

Future<void> main(List<String> arguments) async {
  final packageRoot = Platform.script.resolve('../');
  exitCode = await runBackupTool(
    arguments,
    packageRoot: packageRoot,
    get: horizonsHttpGet,
    pause: (duration) => Future<void>.delayed(duration),
    out: stdout,
    err: stderr,
  );
}
