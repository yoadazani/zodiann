// ZOD-UI-004, test only: pumps widgets inside a MaterialApp with a Zodiann
// theme (keyboard shortcuts come from WidgetsApp), optionally in Hebrew.
//
// shared_ui has no flutter_localizations, so `locale: Locale('he')` alone
// would resolve to en_US / LTR; the Hebrew harness sets RTL explicitly.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

/// Pumps [child] centred in a `Material` under [theme] (default Graphite).
Future<void> pumpInApp(
  WidgetTester tester,
  Widget child, {
  ThemeData? theme,
  bool hebrew = false,
}) => tester.pumpWidget(
  MaterialApp(
    theme: theme ?? ZodiannTheme.graphite,
    builder: hebrew
        ? (context, w) => Theme(
            data: withZodiannScript(Theme.of(context), ZodiannScript.hebrew),
            child: Directionality(textDirection: TextDirection.rtl, child: w!),
          )
        : null,
    home: Material(child: Center(child: child)),
  ),
);

/// The single button's drawn (decorated) box.
Finder drawnBox([Finder? of]) => find
    .descendant(
      of: of ?? find.byType(ZodiannButton),
      matching: find.byType(DecoratedBox),
    )
    .first;

/// The single button's label.
Finder labelText([Finder? of]) => find.descendant(
  of: of ?? find.byType(ZodiannButton),
  matching: find.byType(Text),
);
