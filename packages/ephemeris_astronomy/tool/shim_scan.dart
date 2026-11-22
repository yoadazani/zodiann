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

// ZOD-EPH-004 D12: the UTC-to-TT conversion has one site. The shim converts
// through `zodiann_time_from_ut` only, so the test hook converts the way the
// production path does. These scans make that a structural fact for the
// project-authored sources. Residual limit (stated, not hidden): upstream's
// own Astronomy_AddDays re-derives TT from UT internally; that is upstream
// behaviour and is not guarded here.

final _bannedTimeCall = RegExp(
  r'\b(Astronomy_(?:TimeFromTt|MakeTime|CurrentTime))\s*\(',
);
const _assignOp = r'(?:[-+*/%&|^]|<<|>>)?=(?!=)';
final _fieldAssign = RegExp(r'(?:\.|->)(?:tt|ut)\s*' + _assignOp);
final _fieldIncrement = RegExp(r'(?:\.|->)(?:tt|ut)\s*(?:\+\+|--)');
final _fieldPrefixIncrement = RegExp(
  r'(?:\+\+|--)\s*[A-Za-z_]\w*(?:\s*(?:\.|->)\s*\w+)*\s*(?:\.|->)\s*(?:tt|ut)\b',
);

/// The time calls and field writes found in [cSource] that would change the
/// TT after the single conversion, after comments and strings are removed:
/// `Astronomy_TimeFromTt`, `Astronomy_MakeTime`, `Astronomy_CurrentTime`, and
/// any assignment (`=`, `+=`, `-=`, `*=`, `/=`, `%=`, `&=`, `|=`, `^=`,
/// `<<=`, `>>=`, `++`, `--`) to a `.tt` or `.ut` field. Reads and `==`
/// comparisons are allowed (`zodiann_moon_rate.c` reads `time.tt`).
List<String> bannedTimeCalls(String cSource) {
  final code = stripCommentsAndStrings(cSource);
  return [
    for (final m in _bannedTimeCall.allMatches(code)) m.group(1)!,
    for (final m in _fieldAssign.allMatches(code)) m.group(0)!.trim(),
    for (final m in _fieldIncrement.allMatches(code)) m.group(0)!.trim(),
    for (final m in _fieldPrefixIncrement.allMatches(code)) m.group(0)!.trim(),
  ];
}

/// How many times [name] is called (followed by an opening parenthesis) in
/// [cSource], after comments and strings are removed.
int callCount(String cSource, String name) =>
    RegExp(r'\b' + RegExp.escape(name) + r'\s*\(')
        .allMatches(stripCommentsAndStrings(cSource))
        .length;

final _helperDefinition = RegExp(r'\bastro_time_t\s+zodiann_time_from_ut\s*\(');

/// How many times `zodiann_time_from_ut` is defined (or declared, which is
/// counted the same way, so a separate prototype is rejected: the helper is
/// defined before its first use).
int helperDefinitionCount(String cSource) =>
    _helperDefinition.allMatches(stripCommentsAndStrings(cSource)).length;

/// How many times `zodiann_time_from_ut` is called, its definition excluded.
int helperCallCount(String cSource) =>
    callCount(cSource, 'zodiann_time_from_ut') - helperDefinitionCount(cSource);
