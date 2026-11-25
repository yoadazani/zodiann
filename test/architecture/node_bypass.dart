// The ZOD-FND-011 scanner behind node_bypass_test.dart.
//
// `EphemerisPort.meanAscendingNode()` returns a plain position and cannot
// report the supported date range, so the range is enforced through
// `position()` by `SupportedRangeEphemeris`. This scanner closes the other
// door: production code must never name the raw mean-node API.

import 'dart:io';

import 'dart_source.dart';
import 'production_sources.dart';

export 'production_sources.dart' show normalizeScanPath;

/// One use of the raw mean-node API found in production code.
class NodeBypass {
  const NodeBypass(this.path, this.line, this.name);

  final String path;
  final int line;
  final String name;

  @override
  String toString() => '$path:$line $name';
}

/// The only files that may name the raw API, each with the reason. Any other
/// production file fails the guard. **ZOD-EPH-002 must add its Swiss adapter
/// file here with a justification** (every class implementing `EphemerisPort`
/// declares `meanAscendingNode`); so must any later source or wrapper.
const Map<String, String> nodeBypassAllowlist = {
  'packages/astro_core/lib/src/ephemeris/mean_node.dart':
      'Defines the formula, meanAscendingNodeAt and the '
      'MeanAscendingNodeFormula mixin: the single implementation (ZOD-EPH-001).',
  'packages/astro_core/lib/src/ephemeris/ephemeris_port.dart':
      'Declares the interface method meanAscendingNode (ZOD-FND-002).',
  'packages/astro_core/lib/src/ephemeris/supported_range_ephemeris.dart':
      'The product-range decorator delegates the raw primitive unchanged and '
      'documents why position() is the limited entry point (ZOD-FND-011).',
  'packages/ephemeris_astronomy/lib/src/astronomy_ephemeris.dart':
      'A source adapter: its own position() node branch uses the shared '
      'formula (ZOD-EPH-004).',
};

/// The raw API: the two names and the mixin that exposes the method. Whole
/// words only, so `meanAscendingNodeFoo` and `xmeanAscendingNode` never match.
final _rawNodeApi = RegExp(
  r'\b(meanAscendingNode(?:At)?|MeanAscendingNodeFormula)\b',
);

int _lineOf(String text, int offset) {
  var line = 1;
  for (var i = 0; i < offset && i < text.length; i++) {
    if (text.codeUnitAt(i) == 0x0A) line++;
  }
  return line;
}

/// Every use of the raw API in [source], including inside `${...}` holes of
/// string literals (which [cleanDartSource] blanks).
///
/// [path] is only recorded in the findings. Comments and plain string text
/// never match.
List<NodeBypass> findNodeBypasses(String source, {required String path}) {
  final found = <NodeBypass>[];
  void scan(String text, int? stringLine) {
    final code = cleanDartSource(text);
    for (final m in _rawNodeApi.allMatches(code)) {
      found.add(
        NodeBypass(path, stringLine ?? _lineOf(code, m.start), m.group(1)!),
      );
    }
  }

  scan(source, null);
  for (final (line, body) in interpolationBodies(source)) {
    scan(body, line);
  }
  return found;
}

/// The body of every `${ ... }` hole of every non-raw string literal in
/// [source], with the line of the string's opening quote. String-aware (a `//`
/// inside a string is not a comment), brace-balanced (a `}` inside a nested
/// string does not end a hole), and recursive (each body is itself scanned for
/// strings with holes; nested holes report the outer string's line).
List<(int, String)> interpolationBodies(String source) {
  final out = <(int, String)>[];
  _scanRegion(source, out, null);
  return out;
}

void _scanRegion(String s, List<(int, String)> out, int? forcedLine) {
  var i = 0;
  while (i < s.length) {
    if (s.startsWith('//', i)) {
      final end = s.indexOf('\n', i);
      i = end < 0 ? s.length : end;
    } else if (s.startsWith('/*', i)) {
      final end = s.indexOf('*/', i + 2);
      i = end < 0 ? s.length : end + 2;
    } else if (s[i] == "'" || s[i] == '"') {
      final raw = i > 0 && s[i - 1] == 'r';
      i = _readString(s, i, raw, out, forcedLine ?? _lineOf(s, i));
    } else {
      i++;
    }
  }
}

/// Reads the string literal opened at [open]; returns the index after it.
/// Holes are reported to [out] with [line].
int _readString(
  String s,
  int open,
  bool raw,
  List<(int, String)> out,
  int line,
) {
  final q = s[open];
  final triple = s.startsWith(q * 3, open);
  final quote = triple ? q * 3 : q;
  var i = open + quote.length;
  while (i < s.length) {
    if (s.startsWith(quote, i)) return i + quote.length;
    final c = s[i];
    if (!raw && c == r'\') {
      i += 2;
    } else if (!triple && c == '\n') {
      return i; // an unterminated string ends at the line end
    } else if (!raw && c == r'$' && i + 1 < s.length && s[i + 1] == '{') {
      final end = _holeEnd(s, i + 2);
      if (end < 0) return s.length;
      final body = s.substring(i + 2, end);
      out.add((line, body));
      _scanRegion(body, out, line);
      i = end + 1;
    } else {
      i++;
    }
  }
  return i;
}

/// The index of the `}` closing a hole whose body starts at [from], skipping
/// nested string literals; -1 if it never closes.
int _holeEnd(String s, int from) {
  var depth = 1;
  var i = from;
  while (i < s.length) {
    final c = s[i];
    if (s.startsWith('//', i)) {
      final end = s.indexOf('\n', i);
      i = end < 0 ? s.length : end;
    } else if (s.startsWith('/*', i)) {
      final end = s.indexOf('*/', i + 2);
      i = end < 0 ? s.length : end + 2;
    } else if (c == "'" || c == '"') {
      final raw = i > 0 && s[i - 1] == 'r';
      i = _readString(s, i, raw, <(int, String)>[], 0);
    } else {
      if (c == '{') depth++;
      if (c == '}') {
        depth--;
        if (depth == 0) return i;
      }
      i++;
    }
  }
  return -1;
}

/// Every use of the raw API in the production code under [root] that is not in
/// [nodeBypassAllowlist].
List<NodeBypass> scanProduction(Directory root) {
  final found = <NodeBypass>[];
  productionSources(root).forEach((path, text) {
    if (nodeBypassAllowlist.containsKey(path)) return;
    found.addAll(findNodeBypasses(text, path: path));
  });
  return found;
}
