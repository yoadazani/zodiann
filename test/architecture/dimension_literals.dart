// The ZOD-UI-003 layout-dimension scanner used by
// no_magic_dimensions_test.dart.

/// A numeric layout literal found in source code.
final class DimensionLiteral {
  const DimensionLiteral(this.line, this.call, this.text);

  /// 1-based line number of the literal.
  final int line;

  /// The call the literal is an argument of, e.g. `EdgeInsets.all(`.
  final String call;

  /// The literal itself, e.g. `8`.
  final String text;

  @override
  String toString() => '$line: $call … $text';
}

/// Calls in which any numeric literal other than 0 at the top level of the
/// argument list is flagged. `\b` keeps `fromSize(`, `BorderRadius.` and the
/// like from matching the shorter patterns.
final _unrestricted = [
  RegExp(r'\bEdgeInsets(?:Directional)?(?:\.\w+)?\('),
  RegExp(r'\bSizedBox(?:\.\w+)?\('),
  RegExp(r'\bRadius\.\w+\('),
  RegExp(r'\bBorderRadius\.circular\('),
  RegExp(r'\bBoxShadow\('),
  RegExp(r'\bSize(?:\.\w+)?\('),
  RegExp(r'\bBorderSide\('),
  RegExp(r'\bBoxConstraints(?:\.\w+)?\('),
];

/// Calls in which only the named arguments listed are checked.
final _named = <RegExp, List<String>>{
  RegExp(r'\bIcon\('): ['size'],
  RegExp(r'\bIconButton\('): ['iconSize'],
  RegExp(r'\b(?:Row|Column|Wrap|Flex)\('): ['spacing', 'runSpacing'],
};

final _number = RegExp(r'(?<![\w.$])\d+(?:\.\d+)?(?![\w])');

/// Every numeric layout literal in [source].
///
/// The source is first cleaned: comments are removed and string contents
/// (interpolations included) are blanked, keeping every offset and newline.
/// For each pattern match, the call's argument list is read across lines,
/// tracking depth over `()`, `[]` and `{}` together; only literals at the
/// list's top level count, so closures, collection literals and nested
/// constructors are skipped (a nested constructor is found by its own
/// pattern).
///
/// Documented gaps: `Container(width:/height:)`, `Divider`, flex factors,
/// `Offset(...)` (shadow offsets, transforms) and numeric default parameter
/// values are not scanned. Arithmetic on tokens (`ZodiannSpace.s2 * 1.5`)
/// flags the `1.5`, deliberately: it fails loudly.
List<DimensionLiteral> findDimensionLiterals(String source) {
  final code = _clean(source);
  final found = <DimensionLiteral>[];

  void scan(RegExp pattern, List<String>? names) {
    for (final match in pattern.allMatches(code)) {
      final open = match.end - 1;
      final top = _topLevel(code, open);
      if (top == null) continue;
      final (start, text) = top;
      if (names == null) {
        _report(found, source, match.group(0)!, start, text, 0, text.length);
        continue;
      }
      for (final name in names) {
        for (final arg in RegExp('\\b$name\\s*:').allMatches(text)) {
          var end = text.indexOf(',', arg.end);
          if (end < 0) end = text.length;
          _report(found, source, match.group(0)!, start, text, arg.end, end);
        }
      }
    }
  }

  for (final pattern in _unrestricted) {
    scan(pattern, null);
  }
  _named.forEach(scan);
  found.sort((a, b) => a.line.compareTo(b.line));
  return found;
}

void _report(
  List<DimensionLiteral> found,
  String source,
  String call,
  int base,
  String text,
  int from,
  int to,
) {
  for (final m in _number.allMatches(text.substring(from, to))) {
    final literal = m.group(0)!;
    if (double.parse(literal) == 0) continue;
    final offset = base + from + m.start;
    final line = '\n'.allMatches(source.substring(0, offset)).length + 1;
    found.add(DimensionLiteral(line, call, literal));
  }
}

/// The argument list opened at [open] (a `(`), with every nested bracket's
/// contents blanked: (offset of the first argument character, text). Null
/// if the list never closes.
(int, String)? _topLevel(String code, int open) {
  final out = StringBuffer();
  var depth = 0;
  for (var i = open + 1; i < code.length; i++) {
    final c = code[i];
    if (c == '(' || c == '[' || c == '{') {
      depth++;
      out.write(' ');
    } else if (c == ')' || c == ']' || c == '}') {
      if (depth == 0) return (open + 1, out.toString());
      depth--;
      out.write(' ');
    } else {
      out.write(depth == 0 || c == '\n' ? c : ' ');
    }
  }
  return null;
}

/// [source] with comments removed and string contents blanked, same length.
String _clean(String source) {
  final out = StringBuffer();
  var i = 0;
  final n = source.length;
  void blank(int count) {
    for (var k = 0; k < count && i < n; k++, i++) {
      out.write(source[i] == '\n' ? '\n' : ' ');
    }
  }

  while (i < n) {
    final c = source[i];
    if (source.startsWith('//', i)) {
      final end = source.indexOf('\n', i);
      blank((end < 0 ? n : end) - i);
    } else if (source.startsWith('/*', i)) {
      final end = source.indexOf('*/', i + 2);
      blank((end < 0 ? n : end + 2) - i);
    } else if (c == "'" || c == '"') {
      final raw = i > 0 && source[i - 1] == 'r';
      final triple = source.startsWith(c * 3, i);
      final quote = triple ? c * 3 : c;
      out.write(quote);
      i += quote.length;
      while (i < n && !source.startsWith(quote, i)) {
        if (!raw && source[i] == r'\') {
          blank(2);
        } else if (!triple && source[i] == '\n') {
          break;
        } else {
          blank(1);
        }
      }
      if (source.startsWith(quote, i)) {
        out.write(quote);
        i += quote.length;
      }
    } else {
      out.write(c);
      i++;
    }
  }
  return out.toString();
}

/// Whether [repoRelativePath] may contain layout literals: only the token
/// files. Accepts `\` or `/` separators.
bool isDimensionLiteralAllowed(String repoRelativePath) => repoRelativePath
    .replaceAll(r'\', '/')
    .startsWith('packages/shared_ui/lib/src/theme/tokens/');
