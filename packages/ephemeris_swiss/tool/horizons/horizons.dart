// ZOD-TST-001: the pure part of the JPL Horizons reference tool: the query and
// the checks on reference values. No network and no file access, so all of it
// is tested offline (test/horizons_tool_test.dart). The parameters are those of
// docs/superpowers/specs/2026-11-26-zod-tst-001-horizons-reference-design.md,
// section 8.

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
