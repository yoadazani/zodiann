// ZOD-L10-001: ZodiannApp reads its strings, supported locales and window
// title from the generated ZodiannLocalizations (L-8), keeping the English
// fallback (L-2) and material_ui's Material delegates.
import 'package:astro_mobile/src/app.dart';
import 'package:astro_mobile/src/navigation/screen_stub.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

Future<BuildContext> _pumpShell(
  WidgetTester tester, {
  List<Locale>? locales,
}) async {
  if (locales != null) {
    tester.platformDispatcher.localesTestValue = locales;
  }
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  await tester.pumpWidget(const ProviderScope(child: ZodiannApp()));
  await tester.pumpAndSettle();
  return tester.element(find.byType(ScreenStub));
}

MaterialApp _app(WidgetTester tester) =>
    tester.widget<MaterialApp>(find.byType(MaterialApp));

void main() {
  testWidgets('English device: ZodiannLocalizations resolves to en', (
    tester,
  ) async {
    final ctx = await _pumpShell(tester, locales: const [Locale('en')]);
    final l10n = ZodiannLocalizations.of(ctx);
    expect(l10n.localeName, 'en');
    expect(l10n.appTitle, 'Zodiann');
  });

  testWidgets('Hebrew device: ZodiannLocalizations resolves to he', (
    tester,
  ) async {
    final ctx = await _pumpShell(tester, locales: const [Locale('he', 'IL')]);
    expect(ZodiannLocalizations.of(ctx).localeName, 'he');
  });

  testWidgets('unsupported device locale: falls back to en', (tester) async {
    final ctx = await _pumpShell(tester, locales: const [Locale('fr')]);
    expect(ZodiannLocalizations.of(ctx).localeName, 'en');
  });

  testWidgets('supportedLocales come from the ARB files', (tester) async {
    await _pumpShell(tester);
    expect(
      _app(tester).supportedLocales,
      ZodiannLocalizations.supportedLocales,
    );
  });

  testWidgets('the window title is the localized app title', (tester) async {
    final ctx = await _pumpShell(tester);
    final title = tester.widget<Title>(find.byType(Title)).title;
    expect(title, 'Zodiann');
    expect(title, ZodiannLocalizations.of(ctx).appTitle);
    expect(_app(tester).onGenerateTitle, isNotNull);
    expect(_app(tester).title, isNull);
  });

  testWidgets("the delegates are ZodiannLocalizations plus material_ui's "
      'Global delegates', (tester) async {
    await _pumpShell(tester);
    expect(_app(tester).localizationsDelegates, [
      ZodiannLocalizations.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ]);
  });
}
