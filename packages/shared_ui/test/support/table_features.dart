// ZOD-UI-010, test only: reads a table's geometry the same way from the
// designer's PNGs and from a Flutter render, as runs of equal colour along a
// column or a row, so the two compare feature by feature.

/// A stretch of near-equal colour along a scan line.
typedef Run = ({int color, int length, int start});

/// Whether two 8-bit ARGB colours are within [tolerance] per channel.
bool near(int a, int b, [int tolerance = 1]) {
  for (final shift in [0, 8, 16]) {
    if ((((a >> shift) & 0xff) - ((b >> shift) & 0xff)).abs() > tolerance) {
      return false;
    }
  }
  return true;
}

/// The runs along `at(x, y)` for y from [from] to [to] (inclusive); a pixel
/// continues the current run when it is within [tolerance] of the run's first
/// colour.
List<Run> verticalRuns(
  int Function(int x, int y) at,
  int x,
  int from,
  int to, {
  int tolerance = 1,
}) => _runs((i) => at(x, i), from, to, tolerance);

/// The runs along a row, x from [from] to [to] (inclusive).
List<Run> horizontalRuns(
  int Function(int x, int y) at,
  int y,
  int from,
  int to, {
  int tolerance = 1,
}) => _runs((i) => at(i, y), from, to, tolerance);

List<Run> _runs(int Function(int) at, int from, int to, int tolerance) {
  final out = <Run>[];
  var color = at(from);
  var start = from;
  for (var i = from + 1; i <= to; i++) {
    final c = at(i);
    if (!near(c, color, tolerance)) {
      out.add((color: color, length: i - start, start: start));
      color = c;
      start = i;
    }
  }
  out.add((color: color, length: to - start + 1, start: start));
  return out;
}
