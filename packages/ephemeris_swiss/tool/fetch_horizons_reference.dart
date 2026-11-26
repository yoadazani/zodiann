// ZOD-TST-001: asks JPL Horizons for reference longitudes. Run from this
// package's root, with network access and `gcc` on the PATH:
//
//   dart run tool/fetch_horizons_reference.dart confirm-retrograde \
//       --out <new or empty directory outside the repository>
//   dart run tool/fetch_horizons_reference.dart dataset \
//       --baseline <previous reference json> \
//       --out <new or empty directory outside the repository>
//
// `confirm-retrograde` sends one request per body from Mercury to Pluto (eight
// in all), asking in TT at each candidate instant and 3 days either side, and
// reports which candidates Horizons shows retrograde.
//
// `dataset` sends the thirty requests of the reference dataset (design section
// 8.6) and writes ../astro_core/test/fixtures/horizons_reference.json once,
// only when every answer parses and every dataset gate passes. A reference row
// that changed or disappeared stops it; there is no override.
//
// Every answer is saved unchanged before it is read; `dataset` also saves each
// URI before sending it. The requests hold dates and body numbers only. Each
// request has 60 seconds in all; a timeout or any other failure stops the run,
// and nothing is retried or sent again.
//
// The only network code of the tool; a one-off host tool, never part of the app
// (the app never touches the network: test/architecture/no_network_test.dart).
// Design: docs/superpowers/specs/
// 2026-11-26-zod-tst-001-horizons-reference-design.md, sections 4 to 8.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:astro_core/astro_core.dart';
import 'package:ephemeris_swiss/ephemeris_swiss.dart';

import 'horizons/horizons.dart';
import 'horizons/swiss_host.dart';

/// An HTTP answer, its body as received.
typedef HorizonsResponse = ({int statusCode, List<int> bytes});

const _usage =
    'usage: dart run tool/fetch_horizons_reference.dart\n'
    '  confirm-retrograde --out <dir>\n'
    '  dataset --baseline <json> --out <dir>\n'
    '<dir> must be new or empty, and outside the repository';

/// The time between two requests.
const _pauseBetweenRequests = Duration(seconds: 1);

const _datesPath = '../astro_core/test/fixtures/reference_dates.json';
const _datasetPath = '../astro_core/test/fixtures/horizons_reference.json';

/// One request: what is sent, and what its answer must echo.
typedef _Request = ({
  String command,
  HorizonsTimeType timeType,
  List<String> julianDays,
  Map<String, String> query,
});

_Request _request(
  String command,
  HorizonsTimeType timeType,
  List<String> julianDays, {
  String quantities = '31',
}) => (
  command: command,
  timeType: timeType,
  julianDays: julianDays,
  query: horizonsQuery(
    command: command,
    julianDays: julianDays,
    timeType: timeType,
    quantities: quantities,
  ),
);

Uri _uriOf(_Request request) =>
    Uri.https('ssd.jpl.nasa.gov', '/api/horizons.api', request.query);

String _commandOf(List<RetrogradeCandidate> request) =>
    horizonsCommands[request.first.body]!;

_Request _confirmation(List<RetrogradeCandidate> candidates) => _request(
  _commandOf(candidates),
  HorizonsTimeType.tt,
  [for (final candidate in candidates) ...candidate.julianDays],
);

/// The URIs of the confirmation [requests]; [runHorizonsTool] requests exactly
/// these, in order.
List<Uri> retrogradeRequestUris(List<List<RetrogradeCandidate>> requests) => [
  for (final request in requests) _uriOf(_confirmation(request)),
];

bool _isHistorical(String utc) =>
    ephemerisTimeFor(DateTime.parse(utc)) is UniversalTime;

List<String> _chronological(List<String> instants) =>
    [...instants]
      ..sort((a, b) => DateTime.parse(a).compareTo(DateTime.parse(b)));

/// The dataset requests that can be built before any answer arrives, and the
/// times they hold.
typedef _DatasetPlan = ({
  List<String> instants,
  Map<String, String> ttDays,
  Map<String, double> ttMinusUtSeconds,
  List<_Request> entries,
  List<_Request> crossCheck,
  _Request controlUt,
  List<_Request> evidence,
});

/// Throws [ArgumentError] if a delta T before 1972 is missing, and
/// [StateError] if a declared retrograde instant is not one of [instants].
_DatasetPlan _datasetPlan(
  List<String> instants,
  Map<String, double> historicalDeltaTSeconds,
) {
  final sorted = _chronological(instants);
  for (final declaration in retrogradeDeclarations) {
    if (!sorted.contains(declaration.utc)) {
      throw StateError(
        'the declared instant ${declaration.utc} of ${declaration.body} is '
        'not in the date set',
      );
    }
  }
  final ttDays = {
    for (final utc in sorted)
      utc: ttJulianDay(
        DateTime.parse(utc),
        historicalDeltaTSeconds: historicalDeltaTSeconds[utc],
      ),
  };
  final ttMinusUtSeconds = {
    for (final utc in sorted)
      utc: switch (ephemerisTimeFor(DateTime.parse(utc))) {
        TerrestrialTime(:final ttMinusUtc) =>
          ttMinusUtc.inMicroseconds / Duration.microsecondsPerSecond,
        UniversalTime() => historicalDeltaTSeconds[utc]!,
      },
  };
  final from1972 = [
    for (final utc in sorted)
      if (!_isHistorical(utc)) DateTime.parse(utc),
  ];
  return (
    instants: sorted,
    ttDays: ttDays,
    ttMinusUtSeconds: ttMinusUtSeconds,
    entries: [
      for (final command in horizonsCommands.values)
        _request(command, HorizonsTimeType.tt, [
          for (final utc in sorted) ttDays[utc]!,
        ]),
    ],
    crossCheck: [
      for (final command in horizonsCommands.values)
        (
          command: command,
          timeType: HorizonsTimeType.ut,
          julianDays: [
            for (final utc in from1972) julianDayUt(utc).toStringAsFixed(9),
          ],
          query: utcCrossCheckQuery(command, from1972),
        ),
    ],
    controlUt: _request(horizonsCommands['moon']!, HorizonsTimeType.ut, [
      for (final utc in sorted)
        if (_isHistorical(utc))
          julianDayUt(DateTime.parse(utc)).toStringAsFixed(9),
    ], quantities: '30,31'),
    evidence: [
      for (final MapEntry(key: body, value: command)
          in horizonsCommands.entries)
        if (retrogradeDeclarations.any((d) => d.body == body))
          _request(
            command,
            HorizonsTimeType.tt,
            [
              for (final d in retrogradeDeclarations)
                if (d.body == body)
                  for (final shift in [-3, 3])
                    shiftJulianDay(ttDays[d.utc]!, shift),
            ]..sort((a, b) => double.parse(a).compareTo(double.parse(b))),
          ),
    ],
  );
}

/// The 29 dataset requests known before any answer, in order: all of design
/// section 8.6 but the control asked in TT, whose times come from the answer
/// before it. The `dataset` mode requests exactly these around it.
List<Uri> datasetRequestUris({
  required List<String> instants,
  required Map<String, double> historicalDeltaTSeconds,
}) {
  final plan = _datasetPlan(instants, historicalDeltaTSeconds);
  return [
    for (final request in [
      ...plan.entries,
      ...plan.crossCheck,
      plan.controlUt,
      ...plan.evidence,
    ])
      _uriOf(request),
  ];
}

/// The path segments of a file URI, normalised, and in one case on Windows.
List<String> _segments(Uri uri) => [
  for (final segment in uri.normalizePath().pathSegments)
    if (segment.isNotEmpty)
      Platform.isWindows ? segment.toLowerCase() : segment,
];

/// Why [path] cannot receive the answers, or null if it can: it must lie outside
/// the repository of [packageRoot], and not exist or be an empty directory, so
/// no earlier answer is ever overwritten.
String? _outputRefusal(Uri packageRoot, String path) {
  final root = _segments(packageRoot.resolve('../../'));
  final target = _segments(Directory(path).absolute.uri);
  var inside = target.length >= root.length;
  for (var i = 0; inside && i < root.length; i++) {
    inside = target[i] == root[i];
  }
  if (inside) return '$path is inside the repository';
  return switch (FileSystemEntity.typeSync(path)) {
    FileSystemEntityType.notFound => null,
    FileSystemEntityType.directory when Directory(path).listSync().isEmpty =>
      null,
    _ => '$path exists and is not an empty directory',
  };
}

/// Sends [request] once, saves the answer unchanged as [name] in [directory]
/// and then reads it. With [saveUri] the URI is saved before it is sent.
Future<HorizonsAnswer> _ask(
  _Request request, {
  required String name,
  required Directory directory,
  required Future<HorizonsResponse> Function(Uri uri) get,
  bool saveUri = false,
}) async {
  File fileNamed(String fileName) =>
      File.fromUri(directory.absolute.uri.resolve(fileName));
  final uri = _uriOf(request);
  if (saveUri) {
    fileNamed('$name.uri.txt').writeAsStringSync('$uri', flush: true);
  }
  final response = await get(uri);
  final suffix = response.statusCode == 200
      ? ''
      : '.http${response.statusCode}';
  final file = fileNamed('$name$suffix.txt')
    ..writeAsBytesSync(response.bytes, flush: true);
  if (response.statusCode != 200) {
    throw HttpException(
      'HTTP ${response.statusCode}; the answer is in ${file.path}',
      uri: uri,
    );
  }
  return parseHorizonsAnswer(
    utf8.decode(response.bytes),
    command: request.command,
    timeType: request.timeType,
    julianDays: request.julianDays,
    expectTdbMinusUt: request.query['QUANTITIES']!.contains('30'),
  );
}

/// Runs the tool with [arguments] and returns its exit code: 64 for a wrong
/// command line or output directory; 1 if the confirmation leaves a body
/// unresolved or the dataset fails a gate; else 0.
///
/// Nothing is requested and [deltaT] is not called for exit code 64, and every
/// input is read before the first request. A non-200 answer throws
/// [HttpException] and an answer the parser refuses throws [FormatException];
/// either way the answer is already saved. An error of [get] (a timeout, a
/// broken connection) propagates and nothing is saved for that request. After
/// any of these no further request is sent.
Future<int> runHorizonsTool(
  List<String> arguments, {
  required Uri packageRoot,
  required Future<HorizonsResponse> Function(Uri uri) get,
  required List<double> Function(List<DateTime> instants) deltaT,
  required Future<void> Function(Duration duration) pause,
  required StringSink out,
  required StringSink err,
}) async {
  int refuse(String reason) {
    err.writeln('$reason\n$_usage');
    return 64;
  }

  final String? baselinePath;
  final String path;
  switch (arguments) {
    case ['confirm-retrograde', '--out', final directory]
        when directory.isNotEmpty:
      baselinePath = null;
      path = directory;
    case ['dataset', '--baseline', final baseline, '--out', final directory]
        when baseline.isNotEmpty && directory.isNotEmpty:
      baselinePath = baseline;
      path = directory;
    default:
      return refuse('unrecognised arguments: ${arguments.join(' ')}');
  }
  final refusal = _outputRefusal(packageRoot, path);
  if (refusal != null) return refuse(refusal);

  /// The library delta T of each of [instants], keyed by it.
  Map<String, double> deltaTOf(List<String> instants) {
    final seconds = deltaT([for (final utc in instants) DateTime.parse(utc)]);
    if (seconds.length != instants.length) {
      throw StateError(
        '${seconds.length} delta T values for ${instants.length} instants',
      );
    }
    return {for (final (i, utc) in instants.indexed) utc: seconds[i]};
  }

  var sent = 0;

  /// Sends the next request, a second after the one before it.
  Future<HorizonsAnswer> send(
    _Request request,
    Directory directory, {
    bool saveUri = false,
  }) async {
    if (sent > 0) await pause(_pauseBetweenRequests);
    sent++;
    return _ask(
      request,
      name:
          '${'$sent'.padLeft(2, '0')}_${request.command}_'
          '${request.timeType.name.toUpperCase()}',
      directory: directory,
      get: get,
      saveUri: saveUri,
    );
  }

  // Everything that can fail without the network happens before the first
  // request.
  if (baselinePath == null) {
    final requests = retrogradeRequests(
      deltaTOf(retrogradeHistoricalInstants()),
    );
    final confirmations = [
      for (final candidates in requests) _confirmation(candidates),
    ];
    final directory = Directory(path)..createSync(recursive: true);
    final results = <RetrogradeResult>[];
    for (final (i, request) in confirmations.indexed) {
      final answer = await send(request, directory);
      for (final result in retrogradeResults(requests[i], answer.rows)) {
        out.writeln(retrogradeResultLine(result));
        results.add(result);
      }
    }
    final unresolved = retrogradeUnresolved(results);
    if (unresolved.isEmpty) return 0;
    err.writeln(
      'not confirmed, the owner must decide: ${unresolved.join(', ')}',
    );
    return 1;
  }

  Map<String, Object?> readJson(File file) =>
      jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
  final dates = readJson(File.fromUri(packageRoot.resolve(_datesPath)));
  final instants = (dates['dates']! as List<Object?>).cast<String>().toList();
  final referenceDatesVersion = dates['version']! as int;
  final baseline = readJson(File(baselinePath));
  if (baseline['entries'] is! List) {
    throw FormatException('$baselinePath has no entries');
  }
  final baselineRows = datasetLongitudeRows(baseline, 'entries');
  final crossCheckBaseline = datasetLongitudeRows(baseline, 'utcCrossCheck');
  // An existing dataset is always compared, whatever the baseline names.
  final datasetFile = File.fromUri(packageRoot.resolve(_datasetPath));
  final previous = datasetFile.existsSync() ? readJson(datasetFile) : null;
  if (previous != null) {
    previous['version']! as int;
    datasetLongitudeRows(previous, 'entries');
    datasetLongitudeRows(previous, 'utcCrossCheck');
  }
  final plan = _datasetPlan(
    instants,
    deltaTOf([
      for (final utc in _chronological(instants))
        if (_isHistorical(utc)) utc,
    ]),
  );
  final directory = Directory(path)..createSync(recursive: true);

  Future<List<HorizonsAnswer>> sendAll(List<_Request> requests) async => [
    for (final request in requests)
      await send(request, directory, saveUri: true),
  ];

  final entryAnswers = await sendAll(plan.entries);
  final crossCheckAnswers = await sendAll(plan.crossCheck);
  final controlUt = await send(plan.controlUt, directory, saveUri: true);
  // The same instants asked in TT, at Horizons' own TDB - UT.
  final derivedTt = [
    for (final row in controlUt.rows)
      (double.parse(row.julianDay) + row.tdbMinusUtSeconds! / 86400)
          .toStringAsFixed(9),
  ];
  final controlTt = await send(
    _request(plan.controlUt.command, HorizonsTimeType.tt, derivedTt),
    directory,
    saveUri: true,
  );
  final evidenceAnswers = await sendAll(plan.evidence);

  final bodies = horizonsCommands.keys.toList();
  final from1972 = [
    for (final utc in plan.instants)
      if (!_isHistorical(utc)) utc,
  ];
  final before1972 = [
    for (final utc in plan.instants)
      if (_isHistorical(utc)) utc,
  ];

  /// Horizons' longitude of [body] at the evidence Julian day [julianDay].
  double evidenceLongitude(String body, String julianDay) {
    for (final (i, request) in plan.evidence.indexed) {
      if (request.command != horizonsCommands[body]) continue;
      return evidenceAnswers[i].rows
          .firstWhere((row) => row.julianDay == julianDay)
          .longitudeDegrees;
    }
    throw StateError('no evidence request for $body');
  }

  final dataset = <String, Object?>{
    'version': 0,
    'referenceDatesVersion': referenceDatesVersion,
    'source': 'JPL Horizons API (https://ssd.jpl.nasa.gov/api/horizons.api)',
    'retrievedOn': DateTime.now().toUtc().toIso8601String().substring(0, 10),
    'apiVersion': {
      for (final answer in [
        ...entryAnswers,
        ...crossCheckAnswers,
        controlUt,
        controlTt,
        ...evidenceAnswers,
      ])
        answer.apiVersion,
    }.join(', '),
    'targetSources': {
      for (final (i, body) in bodies.indexed) body: entryAnswers[i].targetLine,
    },
    'quantity':
        '31 (Observer ecliptic longitude): per the Horizons manual, '
        'IAU76/80 ecliptic-of-date longitude of the apparent position with '
        'light-time, gravitational deflection and stellar aberration',
    'timeScale':
        'Each entry is asked in TT at the TT the app gives its instant, jdTt: '
        'from 1972 UTC + (TAI - UTC) + 32.184 s (astro_core '
        'ephemerisTimeFor); before 1972 the instant read as UT plus the delta '
        'T of the vendored Swiss Ephemeris (tool/tt_grid.c). ttMinusUtSeconds '
        'is that difference. utcCrossCheck asks Horizons at the UTC instant '
        'from 1972; timeScaleControl compares Horizons with itself before 1972.',
    'queryParameters': recordedQuery(plan.entries.first.query),
    'utcCrossCheckQueryParameters': recordedQuery(plan.crossCheck.first.query),
    'toleranceArcseconds': 1,
    'entries': [
      for (final (i, body) in bodies.indexed)
        for (final (j, utc) in plan.instants.indexed)
          {
            'body': body,
            'utc': utc,
            'jdTt': plan.ttDays[utc],
            'ttMinusUtSeconds': plan.ttMinusUtSeconds[utc],
            'longitudeDegrees': entryAnswers[i].rows[j].longitudeDegrees,
          },
    ],
    'utcCrossCheck': [
      for (final (i, body) in bodies.indexed)
        for (final (j, utc) in from1972.indexed)
          {
            'body': body,
            'utc': utc,
            'jdUt': crossCheckAnswers[i].rows[j].julianDay,
            'longitudeDegrees': crossCheckAnswers[i].rows[j].longitudeDegrees,
          },
    ],
    'timeScaleControl': [
      for (final (j, utc) in before1972.indexed)
        {
          'utc': utc,
          'jdUt': controlUt.rows[j].julianDay,
          'tdbMinusUtSeconds': controlUt.rows[j].tdbMinusUtSeconds,
          'jdTtDerived': derivedTt[j],
          'longitudeAtUt': controlUt.rows[j].longitudeDegrees,
          'longitudeAtTt': controlTt.rows[j].longitudeDegrees,
        },
    ],
    'retrogradeEvidence': [
      for (final (:body, :utc) in retrogradeDeclarations)
        {
          'body': body,
          'utc': utc,
          'jdTtBefore': shiftJulianDay(plan.ttDays[utc]!, -3),
          'longitudeBefore': evidenceLongitude(
            body,
            shiftJulianDay(plan.ttDays[utc]!, -3),
          ),
          'jdTtAfter': shiftJulianDay(plan.ttDays[utc]!, 3),
          'longitudeAfter': evidenceLongitude(
            body,
            shiftJulianDay(plan.ttDays[utc]!, 3),
          ),
        },
    ],
  };
  dataset['version'] = nextDatasetVersion(previous, dataset);

  final problems = datasetProblems(
    dataset,
    instants: plan.instants,
    baseline: baselineRows,
    crossCheckBaseline: crossCheckBaseline,
    previous: previous,
  );
  if (problems.isNotEmpty) {
    for (final problem in problems) {
      err.writeln(problem);
    }
    err.writeln('${problems.length} problem(s): nothing written');
    return 1;
  }
  datasetFile.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(dataset)}\n',
  );
  out
    ..writeln('${(dataset['entries']! as List<Object?>).length} entries')
    ..writeln('${baselineRows.length} baseline rows unchanged');
  return 0;
}

/// The longest one request may take, from connecting to the last byte.
const horizonsRequestTimeout = Duration(seconds: 60);

/// Sends one GET of [uri] and returns the status and the whole body. The request
/// is sent once: it is never retried, and a redirect is not followed.
///
/// Throws [TimeoutException] if the whole answer has not arrived within
/// [timeout], and [HttpException] if the connection ends before the answer is
/// complete. Either way the connection is closed and nothing of the incomplete
/// answer is returned.
Future<HorizonsResponse> horizonsHttpGet(
  Uri uri, {
  Duration timeout = horizonsRequestTimeout,
}) async {
  final client = HttpClient();
  Future<HorizonsResponse> get() async {
    final request = await client.getUrl(uri);
    request.followRedirects = false;
    final response = await request.close();
    final bytes = <int>[];
    await response.forEach(bytes.addAll);
    return (statusCode: response.statusCode, bytes: bytes);
  }

  try {
    return await get().timeout(
      timeout,
      onTimeout: () =>
          throw TimeoutException('no complete answer from $uri', timeout),
    );
  } finally {
    // Forced, so an abandoned request does not stay open.
    client.close(force: true);
  }
}

Future<void> main(List<String> arguments) async {
  final packageRoot = Platform.script.resolve('../');
  exitCode = await runHorizonsTool(
    arguments,
    packageRoot: packageRoot,
    get: horizonsHttpGet,
    deltaT: (instants) => libraryDeltaTSeconds(packageRoot, instants),
    pause: (duration) => Future<void>.delayed(duration),
    out: stdout,
    err: stderr,
  );
}
