// ZOD-L10-002 Task 3: the app opens in the detected language on the first
// launch, keeps the saved one afterwards, and main() runs the bootstrap.
// Acceptance: a Hebrew device opens in Hebrew; a French device in English;
// the detection never re-runs and overrides an explicit choice.
import 'dart:io';

import 'package:astro_mobile/src/app.dart';
import 'package:astro_mobile/src/bootstrap.dart';
import 'package:astro_mobile/src/localization/language.dart';
import 'package:astro_mobile/src/navigation/screen_stub.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_storage/shared_storage.dart';
import 'package:shared_ui/shared_ui.dart';

import 'support/memory_settings_store.dart';

/// One launch: a new store over the same in-memory platform, as a restart
/// reopens the same preferences.
PrefsSettingsStore _openStore() => PrefsSettingsStore(SharedPreferencesAsync());

Future<BuildContext> _launch(
  WidgetTester tester,
  SettingsStore store,
  List<Locale> device,
) async {
  final overrides = await tester.runAsync(
    () => bootstrapOverrides(store: store, deviceLocales: device),
  );
  await tester.pumpWidget(
    ProviderScope(overrides: overrides!, child: const ZodiannApp()),
  );
  await tester.pumpAndSettle();
  return tester.element(find.byType(ScreenStub));
}

void _expectLanguage(BuildContext context, String code, TextDirection dir) {
  expect(Localizations.localeOf(context).languageCode, code);
  expect(ZodiannLocalizations.of(context).localeName, code);
  expect(Directionality.of(context), dir);
}

void main() {
  late InMemorySharedPreferencesAsync backing;

  setUp(() {
    backing = InMemorySharedPreferencesAsync.empty();
    SharedPreferencesAsyncPlatform.instance = backing;
  });

  testWidgets('a Hebrew device opens the app in Hebrew on first launch', (
    tester,
  ) async {
    final ctx = await _launch(tester, _openStore(), const [Locale('he', 'IL')]);
    _expectLanguage(ctx, 'he', TextDirection.rtl);
  });

  testWidgets('a French device opens the app in English', (tester) async {
    final ctx = await _launch(tester, _openStore(), const [Locale('fr')]);
    _expectLanguage(ctx, 'en', TextDirection.ltr);
  });

  testWidgets('the second launch never re-runs the detection', (tester) async {
    await _launch(tester, _openStore(), const [Locale('he')]);
    // The device language changed to English; the app was restarted.
    final ctx = await _launch(tester, _openStore(), const [Locale('en')]);
    _expectLanguage(ctx, 'he', TextDirection.rtl);
  });

  testWidgets('an explicit choice stored before the launch survives', (
    tester,
  ) async {
    final seed = _openStore();
    await tester.runAsync(() => seed.write(languageKey, 'en'));
    final ctx = await _launch(tester, _openStore(), const [Locale('he')]);
    _expectLanguage(ctx, 'en', TextDirection.ltr);
  });

  testWidgets('a saved he with a French device stays Hebrew', (tester) async {
    final seed = _openStore();
    await tester.runAsync(() => seed.write(languageKey, 'he'));
    final ctx = await _launch(tester, _openStore(), const [Locale('fr')]);
    _expectLanguage(ctx, 'he', TextDirection.rtl);
  });

  testWidgets('a failing store still opens the app in the device language', (
    tester,
  ) async {
    final store = MemorySettingsStore()
      ..readError = StorageException(StorageFailureKind.unavailable, 'down');
    final ctx = await _launch(tester, store, const [Locale('he')]);
    _expectLanguage(ctx, 'he', TextDirection.rtl);
    expect(store.writes, 0);
  });

  testWidgets('ZodiannApp without overrides still follows the device', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = const [Locale('he', 'IL')];
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    await tester.pumpWidget(const ProviderScope(child: ZodiannApp()));
    await tester.pumpAndSettle();
    _expectLanguage(
      tester.element(find.byType(ScreenStub)),
      'he',
      TextDirection.rtl,
    );
  });

  test('main() runs the bootstrap before runApp', () {
    // A null appLocaleProvider would hide a main() that forgets it, so pin
    // the call itself, with comments stripped so a comment cannot satisfy it.
    final main = File('lib/main.dart')
        .readAsStringSync()
        .split('\n')
        .map((l) => l.replaceFirst(RegExp(r'//.*$'), ''))
        .join('\n');
    expect(main, contains('ensureInitialized'));
    expect(main, contains('await bootstrapOverrides('));
    expect(main, contains('overrides:'));
  });
}
