import 'package:astro_core/astro_core.dart';
import 'package:astro_mobile/main.dart' as app;
import 'package:astro_mobile/src/app.dart';
import 'package:astro_mobile/src/di/app_overrides.dart';
import 'package:astro_mobile/src/di/ephemeris_providers.dart';
import 'package:astro_mobile/src/navigation/app_route.dart';
import 'package:astro_mobile/src/navigation/screen_stub.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_ui/shared_ui.dart';

import 'di/support/fake_ephemeris_dependencies.dart';

/// Identity is all these tests check; every member is unused.
class _FakePort implements EphemerisPort {
  @override
  UtcRange get coveredRange => throw UnimplementedError();

  @override
  EphemerisResult position(Body body, DateTime utc) =>
      throw UnimplementedError();

  @override
  EclipticPosition meanAscendingNode(DateTime utc) =>
      throw UnimplementedError();
}

Future<BuildContext> _pumpShell(
  WidgetTester tester, {
  Brightness? brightness,
  List<Locale>? locales,
}) async {
  if (brightness != null) {
    tester.platformDispatcher.platformBrightnessTestValue = brightness;
  }
  if (locales != null) {
    tester.platformDispatcher.localesTestValue = locales;
  }
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  await tester.pumpWidget(const ProviderScope(child: ZodiannApp()));
  await tester.pumpAndSettle();
  return tester.element(find.byType(ScreenStub));
}

void main() {
  testWidgets('boots with no overrides to a blank themed screen', (
    tester,
  ) async {
    await _pumpShell(tester);
    expect(tester.takeException(), isNull);
    expect(find.byType(ScreenStub), findsOneWidget);
    expect(
      tester.widget<ScreenStub>(find.byType(ScreenStub)).route,
      AppRoute.wheel,
    );
    expect(
      find.descendant(of: find.byType(ScreenStub), matching: find.byType(Text)),
      findsNothing,
    );
  });

  testWidgets('light device → light theme', (tester) async {
    final ctx = await _pumpShell(tester, brightness: Brightness.light);
    expect(Theme.of(ctx).brightness, Brightness.light);
  });

  testWidgets('dark device → dark theme', (tester) async {
    final ctx = await _pumpShell(tester, brightness: Brightness.dark);
    expect(Theme.of(ctx).brightness, Brightness.dark);
  });

  testWidgets('switching platform brightness re-themes the running app', (
    tester,
  ) async {
    await _pumpShell(tester, brightness: Brightness.light);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();
    final ctx = tester.element(find.byType(ScreenStub));
    expect(Theme.of(ctx).brightness, Brightness.dark);
  });

  testWidgets('the Scaffold paints the theme surface', (tester) async {
    for (final brightness in Brightness.values) {
      final ctx = await _pumpShell(tester, brightness: brightness);
      final material = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(Scaffold),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(
        material.color,
        Theme.of(ctx).scaffoldBackgroundColor,
        reason: '$brightness',
      );
    }
  });

  testWidgets('unsupported device locale falls back to English', (
    tester,
  ) async {
    final ctx = await _pumpShell(tester, locales: const [Locale('fr')]);
    expect(Localizations.localeOf(ctx), const Locale('en'));
    expect(Directionality.of(ctx), TextDirection.ltr);
    expect(
      MaterialLocalizations.of(ctx).openAppDrawerTooltip,
      'Open navigation menu',
    );
  });

  testWidgets('Hebrew device locale resolves to he and lays out RTL', (
    tester,
  ) async {
    final ctx = await _pumpShell(tester, locales: const [Locale('he', 'IL')]);
    expect(Localizations.localeOf(ctx).languageCode, 'he');
    expect(Directionality.of(ctx), TextDirection.rtl);
  });

  testWidgets('Hebrew device locale loads Hebrew Material localizations', (
    tester,
  ) async {
    final ctx = await _pumpShell(tester, locales: const [Locale('he', 'IL')]);
    // material_ui 1.11.0, MaterialLocalizationHe.openAppDrawerTooltip.
    expect(
      MaterialLocalizations.of(ctx).openAppDrawerTooltip,
      'פתיחה של תפריט הניווט',
    );
  });

  testWidgets('boots with a fake EphemerisPort bound by one override', (
    tester,
  ) async {
    final fake = _FakePort();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [ephemerisPortProvider.overrideWithValue(fake)],
        child: const ZodiannApp(),
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ScreenStub)),
      listen: false,
    );
    expect(container.read(ephemerisPortProvider), same(fake));
  });

  testWidgets('startup mounts ZodiannApp under a ProviderScope wired to the DI '
      'bindings, the position source and the launch language', (tester) async {
    // Startup builds the real settings store over the preferences
    // platform. main() itself uses the native position source, so the
    // function it calls is run here with fakes.
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    tester.platformDispatcher.localesTestValue = const [Locale('he', 'IL')];
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    await tester.runAsync(
      () =>
          app.startZodiann(ephemeris: FakeEphemerisDependencies().dependencies),
    );
    await tester.pump();
    expect(find.byType(ProviderScope), findsOneWidget);
    final overrides = tester
        .widget<ProviderScope>(find.byType(ProviderScope))
        .overrides;
    // Every DI binding, the position source and its status, and the
    // language resolved before the first frame.
    expect(overrides.length, appOverrides.length + 3);
    expect(find.byType(ZodiannApp), findsOneWidget);
    await tester.pumpAndSettle();
    expect(
      Localizations.localeOf(tester.element(find.byType(ScreenStub))),
      const Locale('he'),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ScreenStub)),
      listen: false,
    );
    expect(
      container.read(ephemerisPortProvider),
      isA<SupportedRangeEphemeris>(),
    );
  });

  group('ZOD-UI-002 typography by locale', () {
    String? family(BuildContext ctx) =>
        Theme.of(ctx).textTheme.bodyMedium!.fontFamily;
    String? extFamily(BuildContext ctx) =>
        Theme.of(ctx).extension<ZodiannTextStyles>()!.body.fontFamily;
    const latin = 'packages/shared_ui/IBM Plex Sans';
    const hebrew = 'packages/shared_ui/IBM Plex Sans Hebrew';

    testWidgets('English locale gets Plex Sans', (tester) async {
      final ctx = await _pumpShell(tester, locales: const [Locale('en')]);
      expect(family(ctx), latin);
      expect(extFamily(ctx), latin);
    });

    testWidgets('Hebrew locale gets Plex Sans Hebrew', (tester) async {
      final ctx = await _pumpShell(tester, locales: const [Locale('he', 'IL')]);
      expect(family(ctx), hebrew);
      expect(extFamily(ctx), hebrew);
    });

    testWidgets('changing the device locale re-resolves the typography without '
        'restart', (tester) async {
      await _pumpShell(tester, locales: const [Locale('en')]);
      expect(family(tester.element(find.byType(ScreenStub))), latin);
      tester.platformDispatcher.localesTestValue = const [Locale('he', 'IL')];
      await tester.pumpAndSettle();
      expect(family(tester.element(find.byType(ScreenStub))), hebrew);
    });

    testWidgets(
      'the theme-mode animation keeps the script and interpolates colour',
      (tester) async {
        await _pumpShell(
          tester,
          brightness: Brightness.light,
          locales: const [Locale('he', 'IL')],
        );
        tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
        await tester.pump(); // animation starts at t = 0
        await tester.pump(const Duration(milliseconds: 100)); // t = 0.5
        expect(tester.takeException(), isNull);
        final mid = Theme.of(tester.element(find.byType(ScreenStub)))
            .textTheme
            .bodyMedium!;
        expect(mid.fontFamily, hebrew);
        expect(mid.color, isNot(porcelainTokens.surfaces.text));
        expect(mid.color, isNot(graphiteTokens.surfaces.text));
        await tester.pumpAndSettle();
      },
    );
  });
}
