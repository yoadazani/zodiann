// ZOD-EPH-004 D12 spike tooling (not part of any build, outside the Melos
// packages): measures delta T at the 53 reference instants for the three
// sources and prints a Markdown table. Run from the repository root, with
// network access and `gcc` on the PATH:
//
//   dart run docs/spikes/ZOD-EPH-004-delta-t/measure_delta_t.dart
//
// * Astronomy Engine: the fixture's `deltaTSeconds` (packages/
//   ephemeris_astronomy/test/fixtures/reference_longitudes_tt.json), which the
//   device test pins against the device's own hook.
// * Swiss Ephemeris: swiss_delta_t.c, compiled here from the vendored sources,
//   swe_deltat_ex with the ephemeris files.
// * Horizons: the printed quantity 30 (TDB-UT) of the Horizons observer table
//   at the same UT instants. Per the Horizons manual: before 1962 it is
//   TDB-UT1; from 1962 it is TDB-UTC with periodic terms under 1e-6 s ignored;
//   beyond the prediction interval (the next ~73 days) the last prediction is
//   taken as a constant for all future dates. The TDB-TT periodic term (at
//   most about 1.7 ms) is ignored in the comparison.
//
// The Moon column is a rule of thumb: the Moon moves about 0.55 arcsecond per
// second of time, so a delta T gap of g seconds moves its UTC-input longitude
// by about 0.55 g arcseconds.
import 'dart:convert';
import 'dart:io';

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

Future<void> main() async {
  final root = Platform.script.resolve('../../../');
  final fixture =
      jsonDecode(
            File.fromUri(
              root.resolve(
                'packages/ephemeris_astronomy/test/fixtures/'
                'reference_longitudes_tt.json',
              ),
            ).readAsStringSync(),
          )
          as Map<String, Object?>;
  final seen = <String>{};
  final rows = <({String utc, double utDays, double library})>[];
  for (final e in (fixture['entries']! as List<Object?>)
      .cast<Map<String, Object?>>()) {
    if (!seen.add(e['utc']! as String)) continue;
    rows.add((
      utc: e['utc']! as String,
      utDays: (e['utDays']! as num).toDouble(),
      library: (e['deltaTSeconds']! as num).toDouble(),
    ));
  }
  final jds = [for (final r in rows) (r.utDays + 2451545.0).toStringAsFixed(9)];

  // Swiss.
  final work = Directory.systemTemp.createTempSync('swiss_delta_t');
  final swissExe = '${work.path}${Platform.pathSeparator}swiss_delta_t';
  final upstream = root.resolve('native/swisseph/upstream/').toFilePath();
  final compile = Process.runSync('gcc', [
    '-O1',
    '-I$upstream',
    '-o',
    swissExe,
    Platform.script.resolve('swiss_delta_t.c').toFilePath(),
    for (final f in [
      'swedate',
      'swehouse',
      'swejpl',
      'swemmoon',
      'swemplan',
      'sweph',
      'swephlib',
      'swecl',
      'swehel',
    ])
      '$upstream$f.c',
    '-lm',
  ]);
  if (compile.exitCode != 0) throw StateError('gcc: ${compile.stderr}');
  final ephe = root
      .resolve('packages/ephemeris_swiss/assets/ephe')
      .toFilePath();
  final swissRun = Process.runSync(swissExe, [ephe, ...jds]);
  if (swissRun.exitCode != 0) throw StateError('swiss: ${swissRun.stderr}');
  final swiss = [
    for (final l in (swissRun.stdout as String).split('\n'))
      if (l.trim().isNotEmpty) double.parse(l.split(' ')[1]),
  ];
  work.deleteSync(recursive: true);

  // Horizons: quantity 30, the Sun, geocentric, UT input.
  final text = await _get(
    Uri.https('ssd.jpl.nasa.gov', '/api/horizons.api', {
      'format': 'text',
      'COMMAND': "'10'",
      'OBJ_DATA': "'NO'",
      'MAKE_EPHEM': "'YES'",
      'EPHEM_TYPE': "'OBSERVER'",
      'CENTER': "'500@399'",
      'TLIST_TYPE': "'JD'",
      'TLIST': "'${jds.join(' ')}'",
      'TIME_TYPE': "'UT'",
      'TIME_DIGITS': "'SECONDS'",
      'QUANTITIES': "'30'",
      'CSV_FORMAT': "'YES'",
    }),
  );
  final soe = text.indexOf(r'$$SOE');
  final eoe = text.indexOf(r'$$EOE');
  final horizonsRows = text
      .substring(soe + 5, eoe)
      .split('\n')
      .map((r) => r.trim())
      .where((r) => r.isNotEmpty)
      .toList();
  if (horizonsRows.length != rows.length) {
    throw StateError('${horizonsRows.length} Horizons rows');
  }
  final horizons = [
    for (final r in horizonsRows)
      double.parse(r.split(',').where((f) => f.trim().isNotEmpty).last),
  ];

  stdout.writeln(
    '| UTC instant | Astronomy Engine ΔT (s) | Swiss ΔT (s) | Horizons TDB-UT (s) '
    '| Library − Horizons (s) | Swiss − Horizons (s) | Moon effect of library − Horizons (arcsec) |',
  );
  stdout.writeln('|---|---|---|---|---|---|---|');
  for (var i = 0; i < rows.length; i++) {
    final lib = rows[i].library;
    stdout.writeln(
      '| ${rows[i].utc} | ${lib.toStringAsFixed(2)} | ${swiss[i].toStringAsFixed(2)} '
      '| ${horizons[i].toStringAsFixed(2)} | ${(lib - horizons[i]).toStringAsFixed(2)} '
      '| ${(swiss[i] - horizons[i]).toStringAsFixed(2)} '
      '| ${((lib - horizons[i]) * 0.55).toStringAsFixed(1)} |',
    );
  }
}
