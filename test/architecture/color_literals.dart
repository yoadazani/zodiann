// The ARCH-7 colour-literal scanner used by no_color_literals_test.dart.

/// A colour literal found in source code.
final class ColorLiteral {
  const ColorLiteral(this.line, this.text);

  /// 1-based line number.
  final int line;

  /// The matched text.
  final String text;

  @override
  String toString() => '$line: $text';
}

final _patterns = [
  // Color(0xFF112233), Color(4278190080)
  RegExp(r'\bColor\(\s*(0x[0-9a-fA-F]+|\d+)\s*\)'),
  // Color.fromARGB(, Color.fromRGBO(, Color.from(
  RegExp(r'\bColor\.from(ARGB|RGBO)?\('),
  // Material / Cupertino named colours. The word boundary keeps token use
  // such as `squareColors.axis` or `BodyColors.new` legal.
  RegExp(r'\b(?:Cupertino)?Colors\.\w+'),
  // '#RRGGBB' or '#RRGGBBAA' strings.
  RegExp(r'''['"]#[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?['"]'''),
];

/// Every colour literal in [source], ignoring text after `//` on a line.
///
/// Known false negative: a `//` inside a string literal hides the rest of
/// that line.
List<ColorLiteral> findColorLiterals(String source) {
  final found = <ColorLiteral>[];
  final lines = source.split('\n');
  for (var i = 0; i < lines.length; i++) {
    var code = lines[i];
    final comment = code.indexOf('//');
    if (comment >= 0) code = code.substring(0, comment);
    for (final pattern in _patterns) {
      for (final match in pattern.allMatches(code)) {
        found.add(ColorLiteral(i + 1, match.group(0)!));
      }
    }
  }
  return found;
}

/// Whether [repoRelativePath] may contain colour literals: only the token
/// files, which ZOD-UI-001 fills with MASTER.md §2's values. Accepts `\` or
/// `/` separators.
bool isColorLiteralAllowed(String repoRelativePath) => repoRelativePath
    .replaceAll(r'\', '/')
    .startsWith('packages/shared_ui/lib/src/theme/tokens/');
