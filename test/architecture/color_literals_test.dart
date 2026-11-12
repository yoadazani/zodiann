// Unit tests for the ARCH-7 colour-literal scanner (color_literals.dart).
import 'package:test/test.dart';

import 'color_literals.dart';

void main() {
  test('flags every colour-literal form, on the right line', () {
    const flagged = [
      'Color(0xFF112233)',
      'const Color(0x80FFFFFF)',
      'Color.fromARGB(255, 1, 2, 3)',
      'Color.fromRGBO(1, 2, 3, 1)',
      'Color.from(alpha: 1, red: 0, green: 0, blue: 0)',
      'Colors.white',
      'Colors.transparent',
      "'#1A2B3C'",
      '"#1A2B3CFF"',
      'Color(4278190080)',
      'CupertinoColors.white',
    ];
    final source = ['// header', ...flagged.map((f) => 'x($f);')].join('\n');
    final found = findColorLiterals(source);
    expect(found.map((l) => l.line), [for (var i = 2; i <= 12; i++) i]);
    for (final (i, literal) in found.indexed) {
      expect(flagged[i], contains(literal.text), reason: flagged[i]);
    }
  });

  test('ignores comments, token use and non-colour code', () {
    const ignored = [
      '// Color(0xFF000000)',
      '/// see Colors.white',
      'colorScheme.primary',
      'surfaces.bg',
      'Color.lerp(a, b, t)',
      "'#tag'",
      'ThemeData(brightness: Brightness.dark)',
      'squareColors.axisFill',
      'bodyColors.of(b)',
      'ZodiacColors.new',
    ];
    for (final source in ignored) {
      expect(findColorLiterals(source), isEmpty, reason: source);
    }
  });

  test('only the token directory is allowed, with either separator', () {
    expect(
      isColorLiteralAllowed(
        'packages/shared_ui/lib/src/theme/tokens/graphite_tokens.dart',
      ),
      isTrue,
    );
    expect(
      isColorLiteralAllowed(
        r'packages\shared_ui\lib\src\theme\tokens\graphite_tokens.dart',
      ),
      isTrue,
    );
    expect(
      isColorLiteralAllowed(
        'packages/shared_ui/lib/src/theme/zodiann_theme.dart',
      ),
      isFalse,
    );
    expect(
      isColorLiteralAllowed('apps/astro_mobile/lib/src/app.dart'),
      isFalse,
    );
  });
}
