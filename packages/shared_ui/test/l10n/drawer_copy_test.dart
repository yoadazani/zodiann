// ZOD-NAV-002: the drawer's copy (group labels, item descriptions, version
// and offline lines) is the design kit's, verbatim, in English and Hebrew.
// One string has no kit.js source: the close button's label ("Close menu" /
// "סגירת תפריט"), an intentional, documented exception to NAV-001's
// "copy from kit.js only" rule (product-owner decision, 2026-11-17),
// mirroring `openMenu`.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

/// kit.js key → the generated getter, per language.
final _keys = <String, String Function(ZodiannLocalizations)>{
  'wheelDesc': (l) => l.drawerDescWheel,
  'squareDesc': (l) => l.drawerDescSquare,
  'savedDesc': (l) => l.drawerDescSaved,
  'settingsDesc': (l) => l.drawerDescSettings,
  'aboutDesc': (l) => l.drawerDescAbout,
  'tools': (l) => l.drawerGroupAnalysis,
  'library': (l) => l.drawerGroupLibrary,
  'offline': (l) => l.drawerOffline,
  // kit.js writes the whole line; the ARB takes the version as a parameter.
  'version': (l) => l.drawerVersion('1.0.0'),
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

  test('the close label is the documented exception, not from kit.js', () {
    expect(
      lookupZodiannLocalizations(const Locale('en')).closeMenu,
      'Close menu',
    );
    expect(
      lookupZodiannLocalizations(const Locale('he')).closeMenu,
      'סגירת תפריט',
    );
    // It really has no kit.js source (the exemption is real, not stale).
    final kit = File('../../design-reference/zodiann/_source/kit.js')
        .readAsStringSync();
    expect(kit, isNot(contains('Close menu')));
    expect(kit, isNot(contains('closeMenu')));
  });

  test('the drawer keys exist in both languages', () {
    Set<String> keys(String file) =>
        (jsonDecode(File(file).readAsStringSync()) as Map<String, dynamic>).keys
            .where((k) => !k.startsWith('@'))
            .toSet();
    final en = keys('lib/l10n/app_en.arb');
    final he = keys('lib/l10n/app_he.arb');
    expect(en, he);
    for (final key in [
      'closeMenu',
      'drawerGroupAnalysis',
      'drawerGroupLibrary',
      'drawerDescWheel',
      'drawerDescSquare',
      'drawerDescSaved',
      'drawerDescSettings',
      'drawerDescAbout',
      'drawerVersion',
      'drawerOffline',
    ]) {
      expect(en, contains(key));
    }
  });
}
