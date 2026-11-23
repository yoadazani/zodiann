import 'package:material_ui/material_ui.dart';
import 'package:shared_storage/shared_storage.dart';
import 'package:shared_ui/shared_ui.dart';

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

/// Where the language is saved: the language code, `he` or `en`. Later
/// ZOD-L10-003 (the in-app override) and ZOD-SET-007 (`UserSettings`) read and
/// write the same key.
const SettingsKey<String> languageKey = SettingsKey<String>('language');

/// The language the app starts in (L-2): a valid saved language always wins,
/// otherwise the device language is detected, saved, and returned, so the
/// detection runs once and never overwrites a later choice.
///
/// An invalid saved value (outside [supported], or of the wrong type) is not a
/// choice: it is treated as a first launch. Storage failures never stop the
/// app: an unreadable store resolves from the device and writes nothing, and a
/// failed write still returns the detected language (the next launch detects
/// again, which is right because nothing was saved). `PrefsSettingsStore`
/// already reports failures; the banner is ZOD-NFR-014's. Other errors are
/// bugs and propagate.
Future<Locale> loadOrDetectLanguage({
  required SettingsStore store,
  required List<Locale> deviceLocales,
  List<Locale>? supported,
}) async {
  final languages = supported ?? ZodiannLocalizations.supportedLocales;
  String? saved;
  try {
    saved = await store.read(languageKey);
  } on StorageException catch (e) {
    switch (e.kind) {
      case StorageFailureKind.unavailable || StorageFailureKind.full:
        return resolveDeviceLanguage(deviceLocales, languages);
      case StorageFailureKind.corrupt || StorageFailureKind.unsupportedVersion:
        saved = null;
    }
  }
  if (saved != null) {
    for (final language in languages) {
      if (language.languageCode == saved) return language;
    }
  }
  final detected = resolveDeviceLanguage(deviceLocales, languages);
  try {
    await store.write(languageKey, detected.languageCode);
  } on StorageException {
    // Not saved; the next launch detects again.
  }
  return detected;
}
