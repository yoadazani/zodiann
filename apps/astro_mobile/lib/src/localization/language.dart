import 'package:material_ui/material_ui.dart';

/// The English locale: the fallback when the device asks for nothing the app
/// supports (L-2).
const Locale _fallback = Locale('en');

/// The supported language the device asks for (L-2): the device's languages
/// in the order the user listed them, the first one the app supports wins.
/// Region and script are ignored (`he_IL`, `en_GB`, `zh_Hans_CN`), and the
/// legacy Hebrew code `iw` counts as `he` (dart:ui maps it). Nothing supported
/// gives English.
///
/// [supported] is the app's list (`ZodiannLocalizations.supportedLocales`), so
/// adding a language is a new translation file, not a code change (L-1). The
/// result is always one of its entries.
Locale resolveDeviceLanguage(
  List<Locale> deviceLocales,
  List<Locale> supported,
) {
  for (final device in deviceLocales) {
    for (final candidate in supported) {
      if (candidate.languageCode == device.languageCode) return candidate;
    }
  }
  return supported.firstWhere(
    (l) => l.languageCode == _fallback.languageCode,
    orElse: () => _fallback,
  );
}
