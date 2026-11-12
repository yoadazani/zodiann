/// Cell text in the Square of Nine (SQ-3, SQ-4; T-FMT-1; MASTER.md §8.2).
///
/// Dates are `d.m.yy`: **no leading zero on the day or month**, and the
/// **year always two digits** (2005 → `05`), matching `yy` in MASTER §8.2/§13
/// and Excel's `d.m.yy` (EX-1). Times are `HH:MM`, 24-hour, zero-padded.
///
/// This is the day-first form. English month-first order (L-12) is
/// ZOD-L10-010, which wraps this formatter.
library;

/// Formats a calendar date as `d.m.yy`, e.g. `4.1.24`, `14.11.24`, `5.1.05`.
/// [date] must be a UTC-flagged carrier (as returned by `cellDate` and
/// `localWallClock`); otherwise [ArgumentError].
String formatCellDate(DateTime date) {
  _requireUtc(date, 'date');
  final yy = (date.year % 100).toString().padLeft(2, '0');
  return '${date.day}.${date.month}.$yy';
}

/// Formats a wall clock as `HH:MM`, e.g. `04:00`, `23:59`. [wallClock] must
/// be a UTC-flagged carrier (as returned by `localWallClock`); otherwise
/// [ArgumentError].
String formatCellTime(DateTime wallClock) {
  _requireUtc(wallClock, 'wallClock');
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(wallClock.hour)}:${two(wallClock.minute)}';
}

void _requireUtc(DateTime value, String name) {
  if (!value.isUtc) throw ArgumentError.value(value, name, 'must be UTC');
}
