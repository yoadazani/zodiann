// ZOD-L10-007: unit tests for the localization-reference scanner.
import 'package:test/test.dart';

import 'l10n_references.dart';

void main() {
  group('flagged', () {
    for (final source in [
      "import 'package:shared_ui/shared_ui.dart';",
      'import "package:shared_ui/shared_ui.dart";',
      "import 'package:flutter_localizations/flutter_localizations.dart';",
      "import 'package:shared_ui/l10n/zodiann_localizations.dart';",
      "export 'package:shared_ui/shared_ui.dart';",
      "import 'stub.dart' if (dart.library.ui) "
          "'package:shared_ui/shared_ui.dart';",
      "import\n  'package:shared_ui/shared_ui.dart';",
      'final t = ZodiannLocalizations.of(context);',
    ]) {
      test(source.replaceAll('\n', r'\n'), () {
        expect(l10nReferences(source), hasLength(1));
      });
    }
  });

  group('not flagged', () {
    for (final source in [
      "import 'package:astro_core/astro_core.dart';",
      '// ZodiannLocalizations',
      "/* import 'package:shared_ui/shared_ui.dart'; */",
      "final s = 'ZodiannLocalizations';",
    ]) {
      test(source, () => expect(l10nReferences(source), isEmpty));
    }
  });
}
