// ZOD-TST-001: the pure part of the JPL Horizons reference tool: the query, the
// answer parser, the checks on reference values, and the retrograde candidates.
// No network and no file access, so all of it is tested offline
// (test/horizons_tool_test.dart). The candidates, the parameters and the answer
// format are those of
// docs/superpowers/specs/2026-11-26-zod-tst-001-horizons-reference-design.md,
// sections 5, 6 and 8.
import 'dart:convert';

import 'package:astro_core/astro_core.dart';
import 'package:ephemeris_swiss/ephemeris_swiss.dart';

/// The time scale Horizons reads a request's Julian days in.
enum HorizonsTimeType { tt, ut }

/// The Horizons body number (`COMMAND`) of each of the ten bodies.
const Map<String, String> horizonsCommands = {
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

/// One reference longitude, identified by its body and shared instant.
typedef LongitudeRow = ({String body, String utc, double longitudeDegrees});

final _requestedJulianDay = RegExp(r'^\d+\.\d{9}$');

/// The parameters of one request: quantity 31 (observer ecliptic longitude),
/// geocentric and apparent, at the given Julian days of [timeType].
///
/// Throws [ArgumentError] unless [julianDays] is a non-empty, strictly
/// ascending list of Julian days with nine decimals: Horizons answers in
/// chronological order, and the answer is matched to the request row by row.
Map<String, String> horizonsQuery({
  required String command,
  required List<String> julianDays,
  required HorizonsTimeType timeType,
  String quantities = '31',
}) {
  var valid =
      julianDays.isNotEmpty && julianDays.every(_requestedJulianDay.hasMatch);
  for (var i = 1; valid && i < julianDays.length; i++) {
    valid = double.parse(julianDays[i - 1]) < double.parse(julianDays[i]);
  }
  if (!valid) {
    throw ArgumentError.value(
      julianDays,
      'julianDays',
      'must be strictly ascending Julian days with nine decimals',
    );
  }
  String quoted(String value) => "'$value'";
  return {
    'format': 'text',
    'COMMAND': quoted(command),
    'OBJ_DATA': quoted('NO'),
    'MAKE_EPHEM': quoted('YES'),
    'EPHEM_TYPE': quoted('OBSERVER'),
    'CENTER': quoted('500@399'),
    'TLIST_TYPE': quoted('JD'),
    'TLIST': quoted(julianDays.join(' ')),
    'TIME_TYPE': quoted(timeType.name.toUpperCase()),
    'TIME_DIGITS': quoted('FRACSEC'),
    'CAL_FORMAT': quoted('BOTH'),
    'QUANTITIES': quoted(quantities),
    'ANG_FORMAT': quoted('DEG'),
    'EXTRA_PREC': quoted('YES'),
    'CSV_FORMAT': quoted('YES'),
    'APPARENT': quoted('AIRLESS'),
  };
}

/// The shortest angle from [from] to [to] in degrees, in [-180, 180).
double signedDegrees(double from, double to) => (to - from + 180) % 360 - 180;

/// Whether the longitude moves backward both from [before] to [at] and from
/// [at] to [after].
bool isRetrograde({
  required double before,
  required double at,
  required double after,
}) => signedDegrees(before, at) < 0 && signedDegrees(at, after) < 0;

/// One line for every row of [baseline] that is missing from [next], or whose
/// longitude differs there by more than [toleranceArcseconds]. Rows only in
/// [next] are additions, not changes.
List<String> changedRows(
  Iterable<LongitudeRow> baseline,
  Iterable<LongitudeRow> next, {
  double toleranceArcseconds = 0.001,
}) {
  final longitudes = {
    for (final row in next) (row.body, row.utc): row.longitudeDegrees,
  };
  final changes = <String>[];
  for (final row in baseline) {
    final longitude = longitudes[(row.body, row.utc)];
    if (longitude == null) {
      changes.add('${row.body} ${row.utc}: missing');
      continue;
    }
    final arcseconds =
        signedDegrees(row.longitudeDegrees, longitude).abs() * 3600;
    if (arcseconds > toleranceArcseconds) {
      changes.add(
        '${row.body} ${row.utc}: changed by '
        '${arcseconds.toStringAsFixed(6)} arcseconds '
        '(${row.longitudeDegrees} to $longitude)',
      );
    }
  }
  return changes;
}

/// One row of an answer. [julianDay] is the requested string the row was matched
/// to; [tdbMinusUtSeconds] is quantity 30, when it was expected.
typedef HorizonsRow = ({
  String julianDay,
  double longitudeDegrees,
  double? tdbMinusUtSeconds,
});

/// A checked answer: its API version, its target line, and its rows in request
/// order.
typedef HorizonsAnswer = ({
  String apiVersion,
  String targetLine,
  List<HorizonsRow> rows,
});

final _decimalNumber = RegExp(r'^-?\d+\.\d+$');

/// A printed calendar time, `1899-Dec-31 12:00:00.000`.
final _calendarTime = RegExp(
  r'^(\d{4})-([A-Z][a-z]{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})\.(\d{3})$',
);

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// The Julian day of 1970-01-01T00:00 (2440587.5), in microseconds.
const _unixEpochJulianMicroseconds =
    2440587 * Duration.microsecondsPerDay + Duration.microsecondsPerDay ~/ 2;

/// Both echoed times of a row must be this close to the requested one.
const _timeToleranceMicroseconds = Duration.microsecondsPerMillisecond;

/// The decimals the pilot confirmed; fewer is refused.
const _longitudeDecimals = 7;
const _tdbMinusUtDecimals = 3;

Never _refuse(String check, String detail) =>
    throw FormatException('$check: $detail');

/// The instant of a Julian day string in microseconds since Julian day 0. Whole
/// days and the fraction are converted separately, so no precision is lost.
int _julianDayMicroseconds(String julianDay) {
  final parts = julianDay.split('.');
  return int.parse(parts[0]) * Duration.microsecondsPerDay +
      (double.parse('0.${parts[1]}') * Duration.microsecondsPerDay).round();
}

/// A printed calendar time in microseconds since Julian day 0, or null if it is
/// not in the expected form.
int? _calendarMicroseconds(String text) {
  final match = _calendarTime.firstMatch(text);
  if (match == null) return null;
  final month = _months.indexOf(match.group(2)!) + 1;
  if (month == 0) return null;
  int field(int group) => int.parse(match.group(group)!);
  return DateTime.utc(
        field(1),
        month,
        field(3),
        field(4),
        field(5),
        field(6),
        field(7),
      ).microsecondsSinceEpoch +
      _unixEpochJulianMicroseconds;
}

/// Reads the text answer to a request for [command] at [julianDays] of
/// [timeType], with quantity 30 as well when [expectTdbMinusUt].
///
/// Throws [FormatException] unless every check passes; the message starts with
/// the name of the check that refused and a colon. Columns are located by their
/// header names, never by position, and each row's two echoed times must match
/// the requested Julian day, in order.
HorizonsAnswer parseHorizonsAnswer(
  String text, {
  required String command,
  required HorizonsTimeType timeType,
  required List<String> julianDays,
  bool expectTdbMinusUt = false,
}) {
  final lines = const LineSplitter().convert(text);

  List<int> linesEqualTo(String marker) => [
    for (var i = 0; i < lines.length; i++)
      if (lines[i].trim() == marker) i,
  ];
  final starts = linesEqualTo(r'$$SOE');
  final ends = linesEqualTo(r'$$EOE');
  if (starts.length != 1 || ends.length != 1 || starts.single > ends.single) {
    _refuse('markers', r'expected one $$SOE line, then one $$EOE line');
  }
  final preamble = lines.sublist(0, starts.single);
  String? lineStarting(String start) =>
      preamble.where((line) => line.startsWith(start)).firstOrNull;

  const versionLabel = 'API VERSION:';
  final apiVersion =
      lineStarting(versionLabel)?.substring(versionLabel.length).trim() ?? '';
  if (apiVersion.isEmpty) _refuse('API version', 'no $versionLabel line');

  final scale = timeType.name.toUpperCase();
  for (final label in ['Start time', 'Stop  time']) {
    final line = lineStarting(label)?.trimRight();
    if (line == null || !line.endsWith(' $scale')) {
      _refuse('time scale', '"$label" does not end in $scale: $line');
    }
  }

  final targetLine = lineStarting('Target body name:')?.trim() ?? '';
  if (!targetLine.contains('($command)')) {
    _refuse('target', 'expected body $command: $targetLine');
  }

  const siteLabel = 'Center-site name:';
  final centre = lineStarting('Center body name:');
  final site = lineStarting(siteLabel)?.substring(siteLabel.length).trim();
  if (centre == null ||
      !centre.contains('Earth (399)') ||
      site != 'GEOCENTRIC') {
    _refuse('centre', 'expected the geocentre: $centre; site $site');
  }

  List<String> fieldsOf(String line) => [
    for (final field in line.split(',')) field.trim(),
  ];
  final header = fieldsOf(
    preamble.lastWhere((line) => line.contains('Date__('), orElse: () => ''),
  );
  int column(String name) {
    final index = header.indexOf(name);
    if (index < 0) _refuse('column', 'no "$name" column in $header');
    return index;
  }

  final calendarColumn = column('Date__($scale)__HR:MN:SC.fff');
  final julianDayColumn = column('Date_________JD$scale');
  final longitudeColumn = column('ObsEcLon');
  final tdbMinusUtColumn = expectTdbMinusUt ? column('TDB-UT') : null;

  final rowLines = lines.sublist(starts.single + 1, ends.single);
  if (rowLines.length != julianDays.length) {
    _refuse('rows', '${rowLines.length} rows for ${julianDays.length} times');
  }

  final rows = <HorizonsRow>[];
  for (var i = 0; i < rowLines.length; i++) {
    final fields = fieldsOf(rowLines[i]);
    if (fields.length != header.length) {
      _refuse(
        'fields',
        'row $i has ${fields.length} fields, the header ${header.length}',
      );
    }
    String number(int index) {
      final value = fields[index];
      if (!_decimalNumber.hasMatch(value)) {
        _refuse('number', 'row $i: "$value" is not a decimal number');
      }
      return value;
    }

    final julianDay = number(julianDayColumn);
    final longitude = number(longitudeColumn);
    final tdbMinusUt = tdbMinusUtColumn == null
        ? null
        : number(tdbMinusUtColumn);
    final calendar = _calendarMicroseconds(fields[calendarColumn]);
    if (calendar == null) {
      _refuse('number', 'row $i: unrecognised time ${fields[calendarColumn]}');
    }

    final requested = _julianDayMicroseconds(julianDays[i]);
    for (final echoed in [_julianDayMicroseconds(julianDay), calendar]) {
      if ((echoed - requested).abs() > _timeToleranceMicroseconds) {
        _refuse(
          'time',
          'row $i: ${fields[calendarColumn]} (JD $julianDay) is not the '
              'requested JD ${julianDays[i]}',
        );
      }
    }

    int decimals(String value) => value.length - value.indexOf('.') - 1;
    if (decimals(longitude) < _longitudeDecimals ||
        (tdbMinusUt != null && decimals(tdbMinusUt) < _tdbMinusUtDecimals)) {
      _refuse('precision', 'row $i: ${rowLines[i].trim()}');
    }
    final degrees = double.parse(longitude);
    if (longitude.startsWith('-') || degrees >= 360) {
      _refuse('longitude', 'row $i: $longitude is outside [0, 360)');
    }
    rows.add((
      julianDay: julianDays[i],
      longitudeDegrees: degrees,
      tdbMinusUtSeconds: tdbMinusUt == null ? null : double.parse(tdbMinusUt),
    ));
  }
  return (apiVersion: apiVersion, targetLine: targetLine, rows: rows);
}

/// One body declared retrograde at one instant.
typedef Declaration = ({String body, String utc});

/// Design section 5.1: the instant or instants proposed for each body from
/// Mercury to Pluto. Proposals only until Horizons confirms them; never edited,
/// so the confirmation requests stay what they were.
const List<Declaration> retrogradePrimaries = [
  (body: 'mercury', utc: '1953-11-18T00:00:00Z'),
  (body: 'mercury', utc: '2049-05-11T00:00:00Z'),
  (body: 'venus', utc: '2012-06-12T00:00:00Z'),
  (body: 'mars', utc: '1956-09-10T00:00:00Z'),
  (body: 'jupiter', utc: '2023-10-15T00:00:00Z'),
  (body: 'saturn', utc: '2023-08-01T00:00:00Z'),
  (body: 'uranus', utc: '2023-10-15T00:00:00Z'),
  (body: 'neptune', utc: '2023-08-01T00:00:00Z'),
  (body: 'pluto', utc: '2023-08-01T00:00:00Z'),
];

/// The pairs the dataset uses. Changed only if the confirmation replaces a
/// primary by its backup.
const List<Declaration> retrogradeDeclarations = retrogradePrimaries;

/// The one backup instant of each body, used if a primary is not retrograde.
const Map<String, String> retrogradeBackups = {
  'mercury': '2016-05-13T00:00:00Z',
  'venus': '2004-06-14T00:00:00Z',
  'mars': '2003-08-28T00:00:00Z',
  'jupiter': '2024-10-20T00:00:00Z',
  'saturn': '2024-08-01T00:00:00Z',
  'uranus': '2024-10-20T00:00:00Z',
  'neptune': '2024-08-01T00:00:00Z',
  'pluto': '2024-08-01T00:00:00Z',
};

/// The Julian day string, nine decimals, sent as TT for [utc]: the TT the app
/// assigns it (design section 6). From the start of the leap-second table that
/// is `ephemerisTimeFor`'s offset; before it, [utc] read as UT plus
/// [historicalDeltaTSeconds].
///
/// Throws [ArgumentError] before the table without a finite delta T, or if
/// [utc] is not UTC.
String ttJulianDay(DateTime utc, {double? historicalDeltaTSeconds}) {
  final double julianDay;
  switch (ephemerisTimeFor(utc)) {
    case TerrestrialTime(:final ttMinusUtc):
      julianDay = julianDayUt(utc.add(ttMinusUtc));
    case UniversalTime():
      final deltaT = historicalDeltaTSeconds;
      if (deltaT == null || !deltaT.isFinite) {
        throw ArgumentError.value(
          deltaT,
          'historicalDeltaTSeconds',
          'a finite delta T is needed for $utc',
        );
      }
      julianDay = julianDayUt(utc) + deltaT / 86400;
  }
  return julianDay.toStringAsFixed(9);
}

/// [julianDay] moved by whole [days]; the fraction digits are unchanged.
String shiftJulianDay(String julianDay, int days) {
  final [whole, fraction] = julianDay.split('.');
  return '${int.parse(whole) + days}.$fraction';
}

/// One instant under test, with the three Julian days asked for it: 3 days
/// before, the instant, 3 days after.
typedef RetrogradeCandidate = ({
  String body,
  String utc,
  bool isBackup,
  List<String> julianDays,
});

/// Every primary and backup instant under test.
List<({String body, String utc, bool isBackup})> _instantsUnderTest() => [
  for (final p in retrogradePrimaries)
    (body: p.body, utc: p.utc, isBackup: false),
  for (final MapEntry(key: body, value: utc) in retrogradeBackups.entries)
    (body: body, utc: utc, isBackup: true),
];

/// The candidate instants before the leap-second table, ascending: those whose
/// TT needs a delta T.
List<String> retrogradeHistoricalInstants() => {
  for (final instant in _instantsUnderTest())
    if (ephemerisTimeFor(DateTime.parse(instant.utc)) is UniversalTime)
      instant.utc,
}.toList()..sort();

/// The candidates of the confirmation requests: one list per request, Mercury to
/// Pluto, ascending by instant within it. [historicalDeltaTSeconds] holds the
/// delta T of each instant of [retrogradeHistoricalInstants].
///
/// Throws [ArgumentError] if one of those is missing.
List<List<RetrogradeCandidate>> retrogradeRequests(
  Map<String, double> historicalDeltaTSeconds,
) {
  RetrogradeCandidate candidate(
    ({String body, String utc, bool isBackup}) instant,
  ) {
    final at = ttJulianDay(
      DateTime.parse(instant.utc),
      historicalDeltaTSeconds: historicalDeltaTSeconds[instant.utc],
    );
    return (
      body: instant.body,
      utc: instant.utc,
      isBackup: instant.isBackup,
      julianDays: [shiftJulianDay(at, -3), at, shiftJulianDay(at, 3)],
    );
  }

  final instants = _instantsUnderTest()..sort((a, b) => a.utc.compareTo(b.utc));
  return [
    // horizonsCommands lists the bodies from the Sun outward.
    for (final body in horizonsCommands.keys)
      if (retrogradeBackups.containsKey(body))
        [
          for (final instant in instants)
            if (instant.body == body) candidate(instant),
        ],
  ];
}

/// The three longitudes Horizons gave for one candidate.
typedef RetrogradeResult = ({
  String body,
  String utc,
  bool isBackup,
  double before,
  double at,
  double after,
});

/// Pairs the rows of one answer with its request's candidates, three rows each,
/// in request order.
///
/// Throws [ArgumentError] unless there are three rows per candidate.
List<RetrogradeResult> retrogradeResults(
  List<RetrogradeCandidate> candidates,
  List<HorizonsRow> rows,
) {
  if (rows.length != 3 * candidates.length) {
    throw ArgumentError.value(
      rows.length,
      'rows',
      'expected three for each of ${candidates.length} candidates',
    );
  }
  return [
    for (final (i, candidate) in candidates.indexed)
      (
        body: candidate.body,
        utc: candidate.utc,
        isBackup: candidate.isBackup,
        before: rows[3 * i].longitudeDegrees,
        at: rows[3 * i + 1].longitudeDegrees,
        after: rows[3 * i + 2].longitudeDegrees,
      ),
  ];
}

bool _passes(RetrogradeResult r) =>
    isRetrograde(before: r.before, at: r.at, after: r.after);

/// One report line: body, instant, primary or backup, the three longitudes,
/// both signed steps, and PASS or FAIL.
String retrogradeResultLine(RetrogradeResult result) {
  String degrees(double value) => value.toStringAsFixed(7);
  String step(double from, double to) {
    final value = signedDegrees(from, to);
    return '${value < 0 ? '' : '+'}${degrees(value)}';
  }

  final (:body, :utc, :isBackup, :before, :at, :after) = result;
  return '$body $utc ${isBackup ? 'backup' : 'primary'}: '
      '${degrees(before)} ${degrees(at)} ${degrees(after)}, '
      'steps ${step(before, at)} ${step(at, after)}, '
      '${_passes(result) ? 'PASS' : 'FAIL'}';
}

/// The bodies the rule of design section 5.1 cannot settle: more of their
/// primaries fail than they have passing backups. A body has one backup, so two
/// failing Mercury primaries are unresolved even if it passes.
List<String> retrogradeUnresolved(Iterable<RetrogradeResult> results) {
  final failingPrimaries = <String, int>{};
  final passingBackups = <String, int>{};
  for (final result in results) {
    if (_passes(result) == result.isBackup) {
      final counts = result.isBackup ? passingBackups : failingPrimaries;
      counts[result.body] = (counts[result.body] ?? 0) + 1;
    }
  }
  return [
    for (final MapEntry(key: body, value: failing) in failingPrimaries.entries)
      if (failing > (passingBackups[body] ?? 0)) body,
  ];
}
