// The ZOD-L10-001 Text() string-literal scanner used by
// no_text_literals_test.dart.

import 'dart_source.dart';

/// A string literal passed directly to a text widget.
final class TextLiteral {
  const TextLiteral(this.line, this.call);

  /// 1-based line of the call name.
  final int line;

  /// `Text`, `SelectableText` or `TextSpan` (any import prefix dropped).
  final String call;

  @override
  String toString() => '$line: $call';
}

final _call = RegExp(r'\b(Text|SelectableText|TextSpan)\s*\(');
final _named = RegExp(r'^(\w+)\s*:');
final _literalStart = RegExp('^r?[\'"]');

/// Every `Text(` / `SelectableText(` call given a positional string literal,
/// and every `TextSpan(` given `text:` as a string literal, in [source].
///
/// The source is cleaned first (comments removed, string contents blanked),
/// and only the call's own top-level argument list is read, across lines.
/// So `const`, import prefixes, raw, triple-quoted, interpolated and
/// adjacent strings are all caught, while `TextStyle(`, `MyText(`,
/// `Text.rich(` (its `TextSpan` is found by its own match) and code after
/// the closing parenthesis are not.
///
/// Documented gaps: a literal that doesn't start the argument (conditional
/// `Text(c ? 'a' : 'b')`, `??` fallbacks `Text(x ?? 'Fallback')`), string
/// variables, and other user-visible named labels (`semanticsLabel:`,
/// `Semantics(label:)`, `Tooltip(message:)`, `hintText:`), which stay
/// review-enforced.
List<TextLiteral> findTextLiterals(String source) {
  final code = cleanDartSource(source);
  final found = <TextLiteral>[];
  for (final match in _call.allMatches(code)) {
    final top = topLevelArguments(code, match.end - 1);
    if (top == null) continue;
    final call = match.group(1)!;
    final flagged = top.$2.split(',').map((a) => a.trim()).any((arg) {
      final named = _named.firstMatch(arg);
      if (call == 'TextSpan') {
        return named != null &&
            named.group(1) == 'text' &&
            _literalStart.hasMatch(arg.substring(named.end).trim());
      }
      return named == null && _literalStart.hasMatch(arg);
    });
    if (flagged) {
      final line = '\n'.allMatches(source.substring(0, match.start)).length + 1;
      found.add(TextLiteral(line, call));
    }
  }
  return found;
}
