// Dart-source helpers shared by the architecture scanners
// (dimension_literals.dart, text_literals.dart).

/// The argument list opened at [open] (a `(`), with every nested bracket's
/// contents blanked: (offset of the first argument character, text). Null
/// if the list never closes.
(int, String)? topLevelArguments(String code, int open) {
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
String cleanDartSource(String source) {
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
