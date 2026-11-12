import 'package:astro_mobile/src/app.dart';
import 'package:astro_mobile/src/theme/theme_mode_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

Future<void> _pump(WidgetTester tester, Brightness device) async {
  tester.platformDispatcher.platformBrightnessTestValue = device;
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  await tester.pumpWidget(const ProviderScope(child: ZodiannApp()));
  await tester.pumpAndSettle();
}

BuildContext _ctx(WidgetTester tester) =>
    tester.element(find.byType(ShellHome));

ThemeModeController _controller(WidgetTester tester) =>
    ProviderScope.containerOf(
      _ctx(tester),
      listen: false,
    ).read(themeModeProvider.notifier);

ZodiannSurfaces? _surfaces(WidgetTester tester) =>
    Theme.of(_ctx(tester)).extension<ZodiannSurfaces>();

void main() {
  testWidgets('defaults to following the device', (tester) async {
    await _pump(tester, Brightness.dark);
    expect(_surfaces(tester), same(graphiteTokens.surfaces));
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();
    expect(_surfaces(tester), same(porcelainTokens.surfaces));
  });

  testWidgets(
    'setting dark/light switches brightness and extensions without restart',
    (tester) async {
      await _pump(tester, Brightness.light);

      _controller(tester).set(ThemeMode.dark);
      await tester.pumpAndSettle();
      expect(Theme.of(_ctx(tester)).brightness, Brightness.dark);
      expect(_surfaces(tester), same(graphiteTokens.surfaces));

      _controller(tester).set(ThemeMode.light);
      await tester.pumpAndSettle();
      expect(Theme.of(_ctx(tester)).brightness, Brightness.light);
      expect(_surfaces(tester), same(porcelainTokens.surfaces));

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      _controller(tester).set(ThemeMode.system);
      await tester.pumpAndSettle();
      expect(Theme.of(_ctx(tester)).brightness, Brightness.dark);
      expect(_surfaces(tester), same(graphiteTokens.surfaces));
    },
  );

  testWidgets('toggling at runtime runs the theme animation without errors', (
    tester,
  ) async {
    await _pump(tester, Brightness.light);
    _controller(tester).set(ThemeMode.dark);
    await tester.pump(); // animation starts at t = 0: no lerp yet
    await tester.pump(const Duration(milliseconds: 100)); // t = 0.5
    expect(tester.takeException(), isNull);
    final mid = _surfaces(tester);
    expect(mid, isNot(same(graphiteTokens.surfaces)));
    expect(mid, isNot(same(porcelainTokens.surfaces)));
    await tester.pumpAndSettle();
    expect(_surfaces(tester), same(graphiteTokens.surfaces));
  });
}
