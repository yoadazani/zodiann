// ZOD-NAV-001: the top bar's copy (screen titles and subtitles, the
// hamburger's label, the Square actions) is the design kit's, verbatim, in
// English and Hebrew (product-owner decision: copy from kit.js only).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

/// kit.js key → the generated getter, per language.
final _keys = <String, String Function(ZodiannLocalizations)>{
  'wheel': (l) => l.screenWheelTitle,
  'wheelSub': (l) => l.screenWheelSubtitle,
  'square': (l) => l.screenSquareTitle,
  'squareSub': (l) => l.screenSquareSubtitle,
  'saved': (l) => l.screenSavedTitle,
  'savedSub': (l) => l.screenSavedSubtitle,
  'settings': (l) => l.screenSettingsTitle,
  'settingsSub': (l) => l.screenSettingsSubtitle,
  'about': (l) => l.screenAboutTitle,
  'aboutSub': (l) => l.screenAboutSubtitle,
  'openMenu': (l) => l.openMenu,
  'save': (l) => l.actionSave,
  'exportXlsx': (l) => l.actionExportXlsx,
};

void main() {
  test('kit.js agrees', () {
    final kit = File('../../design-reference/zodiann/_source/kit.js')
        .readAsStringSync();
    String block(String lang) {
      final start = RegExp('^  $lang: \\{', multiLine: true).firstMatch(kit)!;
      final end = RegExp(
        r'^\};',
        multiLine: true,
      ).allMatches(kit).firstWhere((m) => m.start > start.end);
      final body = kit.substring(start.end, end.start);
      if (lang == 'en') {
        final he = RegExp(r'^  he: \{', multiLine: true).firstMatch(body);
        return he == null ? body : body.substring(0, he.start);
      }
      return body;
    }

    String scalar(String block, String key) =>
        RegExp("(?<![A-Za-z])$key: '([^']*)'").firstMatch(block)!.group(1)!;

    for (final (lang, locale) in [
      ('en', const Locale('en')),
      ('he', const Locale('he')),
    ]) {
      final kitBlock = block(lang);
      final l = lookupZodiannLocalizations(locale);
      _keys.forEach((key, getter) {
        expect(getter(l), scalar(kitBlock, key), reason: '$lang $key');
      });
    }
  });
}
