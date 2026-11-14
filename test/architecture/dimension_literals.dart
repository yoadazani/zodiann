// The ZOD-UI-003 layout-dimension scanner used by
// no_magic_dimensions_test.dart.

import 'dart_source.dart';

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
  RegExp(r'\bEdgeInsets(?:Directional|Geometry)?(?:\.\w+)?\('),
  RegExp(r'\bSizedBox(?:\.\w+)?\('),
  RegExp(r'\bRadius\.\w+\('),
  RegExp(r'\bBorderRadius(?:Directional|Geometry)?\.circular\('),
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
  final code = cleanDartSource(source);
  final found = <DimensionLiteral>[];

  void scan(RegExp pattern, List<String>? names) {
    for (final match in pattern.allMatches(code)) {
      final open = match.end - 1;
      final top = topLevelArguments(code, open);
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

/// Whether [repoRelativePath] may contain layout literals: only the token
/// files. Accepts `\` or `/` separators.
bool isDimensionLiteralAllowed(String repoRelativePath) => repoRelativePath
    .replaceAll(r'\', '/')
    .startsWith('packages/shared_ui/lib/src/theme/tokens/');
