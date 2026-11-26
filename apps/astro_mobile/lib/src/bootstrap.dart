import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:material_ui/material_ui.dart';
import 'package:shared_storage/shared_storage.dart';

import 'di/app_overrides.dart';
import 'di/ephemeris_wiring.dart';
import 'localization/app_locale_provider.dart';
import 'localization/language.dart';

/// Everything `main()` resolves before the first frame, as the overrides for
/// the root `ProviderScope`: the DI bindings ([appOverrides]), the position
/// source chosen from [ephemeris] (ZOD-EPH-002) and the language the app starts
/// in (ZOD-L10-002: saved, or detected from [deviceLocales] and saved on the
/// first launch).
///
/// Awaited before `runApp`, so the app never shows the wrong language first and
/// never asks an unbound source for a position.
Future<List<Override>> bootstrapOverrides({
  required SettingsStore store,
  required List<Locale> deviceLocales,
  required EphemerisDependencies ephemeris,
}) async {
  final locale = await loadOrDetectLanguage(
    store: store,
    deviceLocales: deviceLocales,
  );
  return [
    ...appOverrides,
    ...await ephemerisOverrides(ephemeris),
    appLocaleProvider.overrideWithValue(locale),
  ];
}
