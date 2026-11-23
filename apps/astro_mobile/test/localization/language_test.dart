// ZOD-L10-002: the first-launch language. Task 1: resolving the device's
// language list into a supported language (L-1, L-2).
import 'package:astro_mobile/src/localization/language.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

final _supported = ZodiannLocalizations.supportedLocales;

Locale _resolve(List<Locale> device) =>
    resolveDeviceLanguage(device, _supported);

void main() {
  group('resolveDeviceLanguage', () {
    test('a Hebrew device resolves to he', () {
      expect(_resolve(const [Locale('he', 'IL')]), const Locale('he'));
      expect(_resolve(const [Locale('he')]), const Locale('he'));
    });

    test('an English device resolves to en', () {
      expect(_resolve(const [Locale('en', 'GB')]), const Locale('en'));
      expect(_resolve(const [Locale('en', 'US')]), const Locale('en'));
    });

    test('an unsupported device resolves to en', () {
      expect(_resolve(const [Locale('fr')]), const Locale('en'));
      expect(_resolve(const [Locale('ar')]), const Locale('en'));
      expect(
        _resolve([
          Locale.fromSubtags(
            languageCode: 'zh',
            scriptCode: 'Hans',
            countryCode: 'CN',
          ),
        ]),
        const Locale('en'),
      );
    });

    test('the first supported language in the list wins', () {
      expect(_resolve(const [Locale('fr'), Locale('he')]), const Locale('he'));
      expect(_resolve(const [Locale('he'), Locale('en')]), const Locale('he'));
      expect(_resolve(const [Locale('en'), Locale('he')]), const Locale('en'));
      expect(
        _resolve(const [Locale('fr'), Locale('de'), Locale('he')]),
        const Locale('he'),
      );
    });

    test('the legacy Hebrew code iw resolves to he', () {
      expect(_resolve(const [Locale('iw')]), const Locale('he'));
    });

    test('an empty list resolves to en', () {
      expect(_resolve(const []), const Locale('en'));
    });

    test('the result is a supported locale, never a region variant', () {
      final got = _resolve(const [Locale('he', 'IL')]);
      expect(_supported, contains(got));
      expect(got.countryCode, isNull);
    });

    test('English is a supported language (the fallback)', () {
      expect(_supported, contains(const Locale('en')));
    });
  });
}
