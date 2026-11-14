// ZOD-L10-001: unit tests for the Text() string-literal scanner.
import 'package:test/test.dart';

import 'text_literals.dart';

void main() {
  group('flagged', () {
    final cases = <String, (int, String)>{
      "Text('Save')": (1, 'Text'),
      'const Text("Save")': (1, 'Text'),
      "Text(\n  'Save',\n)": (1, 'Text'),
      "Text(r'x')": (1, 'Text'),
      "Text('''x''')": (1, 'Text'),
      r"Text('$n cells')": (1, 'Text'),
      "Text('a' 'b')": (1, 'Text'),
      "Text(key: k, 'Save')": (1, 'Text'),
      "m.Text('x')": (1, 'Text'),
      "SelectableText('x')": (1, 'SelectableText'),
      "TextSpan(text: 'x')": (1, 'TextSpan'),
      "TextSpan(style: s,\n text: 'x')": (1, 'TextSpan'),
      "Text.rich(TextSpan(text: 'x'))": (1, 'TextSpan'),
      "final a = 1;\nfinal w = Text('x');": (2, 'Text'),
    };
    cases.forEach((source, expected) {
      test(source.replaceAll('\n', r'\n'), () {
        final hits = findTextLiterals(source);
        expect(hits, hasLength(1));
        expect((hits.single.line, hits.single.call), expected);
      });
    });
  });

  group('not flagged', () {
    for (final source in [
      'Text(label)',
      'Text(ZodiannLocalizations.of(context).appTitle)',
      'Text(widget.label, maxLines: 1)',
      "TextStyle(fontFamily: 'Plex')",
      "MyText('x')",
      "// Text('x')",
      "/* Text('x') */",
      'final s = "Text(\'x\')";',
      "Text(label, semanticsLabel: 'x')",
      'TextSpan(children: [a])',
      "Row(children: [Text(label), Tooltip(message: 'x')])",
      "Text(label); foo('x');",
      'Text(rows.first)',
    ]) {
      test(source, () => expect(findTextLiterals(source), isEmpty));
    }
  });
}
