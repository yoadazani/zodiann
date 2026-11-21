// ZOD-EPH-004 Task 3 Step 1a: scans the project-authored native sources for
// calls that would put a finite difference into the speed (owner decision
// 2026-11-21: no finite differences of any origin, including those inherited
// from the upstream library).
//
// Limit (stated, not hidden): a `BaryState` call whose first argument is a
// variable cannot be recognised as a Moon call here. The real protection is
// that the Moon branch of the shim returns before any `BaryState` call.

/// Replaces C comments, string literals and character literals with spaces
/// (keeping newlines), so that text inside them cannot trigger a match.
String stripCommentsAndStrings(String source) {
  final out = StringBuffer();
  var i = 0;
  final n = source.length;
  while (i < n) {
    final c = source[i];
    final next = i + 1 < n ? source[i + 1] : '';
    if (c == '/' && next == '*') {
      out.write('  ');
      i += 2;
      while (i < n &&
          !(source[i] == '*' && i + 1 < n && source[i + 1] == '/')) {
        out.write(source[i] == '\n' ? '\n' : ' ');
        i++;
      }
      if (i < n) {
        out.write('  ');
        i += 2;
      }
    } else if (c == '/' && next == '/') {
      while (i < n && source[i] != '\n') {
        out.write(' ');
        i++;
      }
    } else if (c == '"' || c == "'") {
      final quote = c;
      out.write(' ');
      i++;
      while (i < n && source[i] != quote) {
        if (source[i] == r'\' && i + 1 < n) {
          out.write('  ');
          i += 2;
        } else {
          out.write(source[i] == '\n' ? '\n' : ' ');
          i++;
        }
      }
      if (i < n) {
        out.write(' ');
        i++;
      }
    } else {
      out.write(c);
      i++;
    }
  }
  return out.toString();
}

final _bannedOutright = RegExp(
  r'\b(Astronomy_(?:GeoMoonState|GeoEmbState|HelioState|AddDays))\s*\(',
);
final _baryMoonOrEmb = RegExp(
  r'\bAstronomy_BaryState\s*\(\s*(BODY_MOON|BODY_EMB)\b',
);

/// The banned calls found in [cSource], after comments and string literals are
/// removed: `Astronomy_GeoMoonState`, `Astronomy_GeoEmbState`,
/// `Astronomy_HelioState` and `Astronomy_AddDays` (banned outright; the Sun
/// and planet path needs none of them), and `Astronomy_BaryState(BODY_MOON)` /
/// `Astronomy_BaryState(BODY_EMB)`. An empty list means the source is clean.
List<String> bannedCalls(String cSource) {
  final code = stripCommentsAndStrings(cSource);
  return [
    for (final m in _bannedOutright.allMatches(code)) m.group(1)!,
    for (final m in _baryMoonOrEmb.allMatches(code))
      'Astronomy_BaryState(${m.group(1)})',
  ];
}
