/// Internal strict ISO-8601 parser for the data model.
///
/// `DateTime.parse` is lenient: it silently normalizes impossible fields
/// (`2026-02-30` → March 2, hour 25, offset minutes 75) and accepts comma
/// fractions, spaces and the basic format. A hand-edited backup (DATA-3) must
/// fail loudly instead of loading a different date, so only the canonical
/// extended form that this package itself writes is accepted:
///
/// `YYYY-MM-DDTHH:MM[:SS[.f{1,6}]](Z|±HH:MM)`, where the year is 4 digits or
/// a sign plus 6 digits (Dart's form outside 0…9999).
library;

final _canonical = RegExp(
  r'^(\d{4}|[+-]\d{6})-(\d{2})-(\d{2})T(\d{2}):(\d{2})'
  r'(?::(\d{2})(?:\.(\d{1,6}))?)?'
  r'(Z|([+-])(\d{2}):(\d{2}))$',
);

/// Parses [input] into its UTC instant and offset in minutes.
///
/// Throws [FormatException] if [input] is not canonical, any field is out of
/// range (e.g. February 30, hour 24, minute 60, offset minutes ≥ 60), or the
/// value is outside `DateTime`'s range. With [requireUtc], only a `Z` suffix
/// is accepted.
({DateTime instant, int offsetMinutes}) parseStrictIso8601(
  String input, {
  bool requireUtc = false,
}) {
  final m = _canonical.firstMatch(input);
  if (m == null) {
    throw FormatException('Expected canonical ISO-8601 date-time', input);
  }
  int field(int group) => int.parse(m.group(group) ?? '0');
  final year = int.parse(m.group(1)!);
  final month = field(2), day = field(3), hour = field(4), minute = field(5);
  final second = field(6);
  final fraction = (m.group(7) ?? '').padRight(6, '0');
  final millisecond = int.parse(fraction.substring(0, 3));
  final microsecond = int.parse(fraction.substring(3, 6));

  final isZ = m.group(8) == 'Z';
  if (requireUtc && !isZ) {
    throw FormatException('Expected a UTC date-time ending in Z', input);
  }
  var offsetMinutes = 0;
  if (!isZ) {
    final offsetMinutePart = field(11);
    if (offsetMinutePart >= 60) {
      throw FormatException('Offset minutes must be below 60', input);
    }
    offsetMinutes =
        (m.group(9) == '-' ? -1 : 1) * (field(10) * 60 + offsetMinutePart);
  }

  final DateTime wall;
  try {
    wall = DateTime.utc(
      year,
      month,
      day,
      hour,
      minute,
      second,
      millisecond,
      microsecond,
    );
  } on ArgumentError {
    throw FormatException('Date-time out of range', input);
  }
  // DateTime.utc normalizes overflow (Feb 30 → Mar 2, hour 24 → next day):
  // any mismatch means a field was out of range.
  if (wall.year != year ||
      wall.month != month ||
      wall.day != day ||
      wall.hour != hour ||
      wall.minute != minute ||
      wall.second != second) {
    throw FormatException('Date-time field out of range', input);
  }
  try {
    return (
      instant: wall.subtract(Duration(minutes: offsetMinutes)),
      offsetMinutes: offsetMinutes,
    );
  } on ArgumentError {
    throw FormatException('Date-time out of range', input);
  }
}
