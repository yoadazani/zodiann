// ZOD-L10-001: the shared ARB files (app_en.arb / app_he.arb) generate
// ZodiannLocalizations, exported from package:shared_ui (PO decision N1).
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

Future<ZodiannLocalizations> _pump(WidgetTester tester, Locale locale) async {
  late BuildContext ctx;
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        ZodiannLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: ZodiannLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          ctx = context;
          return const SizedBox();
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return ZodiannLocalizations.of(ctx);
}

void main() {
  testWidgets('en resolves English strings', (tester) async {
    final l10n = await _pump(tester, const Locale('en'));
    expect(l10n.localeName, 'en');
    expect(l10n.appTitle, 'Zodiann');
  });

  testWidgets('he resolves Hebrew strings', (tester) async {
    final l10n = await _pump(tester, const Locale('he'));
    expect(l10n.localeName, 'he');
    expect(l10n.appTitle, 'Zodiann');
  });

  test('supportedLocales are en then he', () {
    expect(ZodiannLocalizations.supportedLocales, const [
      Locale('en'),
      Locale('he'),
    ]);
  });
}
