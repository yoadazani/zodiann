// ZOD-L10-007 (L-9) + ZOD-L10-013 (D20): sign, body, aspect and direction
// names come from ZodiannLocalizations, looked up by stable key. Expected
// values: the approved design's string tables, typed in below and read again
// from design-reference/zodiann/_source/kit.js (second source).
import 'dart:io';

import 'package:astro_core/astro_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gann_core/gann_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

const _signs = <ZodiacSign, (String, String)>{
  ZodiacSign.aries: ('Aries', 'טלה'),
  ZodiacSign.taurus: ('Taurus', 'שור'),
  ZodiacSign.gemini: ('Gemini', 'תאומים'),
  ZodiacSign.cancer: ('Cancer', 'סרטן'),
  ZodiacSign.leo: ('Leo', 'אריה'),
  ZodiacSign.virgo: ('Virgo', 'בתולה'),
  ZodiacSign.libra: ('Libra', 'מאזניים'),
  ZodiacSign.scorpio: ('Scorpio', 'עקרב'),
  ZodiacSign.sagittarius: ('Sagittarius', 'קשת'),
  ZodiacSign.capricorn: ('Capricorn', 'גדי'),
  ZodiacSign.aquarius: ('Aquarius', 'דלי'),
  ZodiacSign.pisces: ('Pisces', 'דגים'),
};

const _bodies = <Body, (String, String)>{
  Body.sun: ('Sun', 'שמש'),
  Body.moon: ('Moon', 'ירח'),
  Body.mercury: ('Mercury', 'כוכב חמה'),
  Body.venus: ('Venus', 'נוגה'),
  Body.mars: ('Mars', 'מאדים'),
  Body.jupiter: ('Jupiter', 'צדק'),
  Body.saturn: ('Saturn', 'שבתאי'),
  Body.uranus: ('Uranus', 'אורנוס'),
  Body.neptune: ('Neptune', 'נפטון'),
  Body.pluto: ('Pluto', 'פלוטו'),
  Body.node: ('Mean node', 'ראש הדרקון'),
};

const _aspects = <AspectKind, (String, String)>{
  AspectKind.conjunction: ('Conjunction', 'צמידות'),
  AspectKind.sextile: ('Sextile', 'סקסטייל'),
  AspectKind.square: ('Square', 'ריבוע'),
  AspectKind.trine: ('Trine', 'טריין'),
  AspectKind.opposition: ('Opposition', 'אופוזיציה'),
};

const _directions = <CompassDirection, (String, String)>{
  CompassDirection.west: ('west', 'מערב'),
  CompassDirection.northWest: ('north-west', 'צפון-מערב'),
  CompassDirection.north: ('north', 'צפון'),
  CompassDirection.northEast: ('north-east', 'צפון-מזרח'),
  CompassDirection.east: ('east', 'מזרח'),
  CompassDirection.southEast: ('south-east', 'דרום-מזרח'),
  CompassDirection.south: ('south', 'דרום'),
  CompassDirection.southWest: ('south-west', 'דרום-מערב'),
};

/// kit.js keys for the scalar entries, by enum.
const _kitAspectKeys = {
  AspectKind.conjunction: 'conj',
  AspectKind.sextile: 'sextile',
  AspectKind.square: 'sq',
  AspectKind.trine: 'trine',
  AspectKind.opposition: 'opp',
};
const _kitDirectionKeys = ['W', 'NW', 'N', 'NE', 'E', 'SE', 'S', 'SW'];

void main() {
  late ZodiannLocalizations en;
  late ZodiannLocalizations he;

  setUpAll(() async {
    en = await ZodiannLocalizations.delegate.load(const Locale('en'));
    he = await ZodiannLocalizations.delegate.load(const Locale('he'));
  });

  /// Every (set name, key, en lookup, he lookup, expected) row.
  Iterable<(String, Enum, String, String, (String, String))> rows() sync* {
    for (final e in _signs.entries) {
      yield ('sign', e.key, en.signName(e.key), he.signName(e.key), e.value);
    }
    for (final e in _bodies.entries) {
      yield ('body', e.key, en.bodyName(e.key), he.bodyName(e.key), e.value);
    }
    for (final e in _aspects.entries) {
      yield (
        'aspect',
        e.key,
        en.aspectName(e.key),
        he.aspectName(e.key),
        e.value,
      );
    }
    for (final e in _directions.entries) {
      yield (
        'direction',
        e.key,
        en.directionName(e.key),
        he.directionName(e.key),
        e.value,
      );
    }
  }

  test('the tables cover every key', () {
    expect(_signs.keys, ZodiacSign.values);
    expect(_bodies.keys, Body.values);
    expect(_aspects.keys, AspectKind.values);
    expect(_directions.keys, CompassDirection.values);
  });

  test('en and he names match the approved design, per key', () {
    for (final (_, key, enName, heName, (wantEn, wantHe)) in rows()) {
      expect(enName, wantEn, reason: '$key (en)');
      expect(heName, wantHe, reason: '$key (he)');
    }
  });

  test('names are distinct within each entity set, in both languages', () {
    final bySet = <String, List<(String, String)>>{};
    for (final (set, _, enName, heName, _) in rows()) {
      (bySet[set] ??= []).add((enName, heName));
    }
    bySet.forEach((set, names) {
      expect(
        names.map((n) => n.$1).toSet(),
        hasLength(names.length),
        reason: '$set (en)',
      );
      expect(
        names.map((n) => n.$2).toSet(),
        hasLength(names.length),
        reason: '$set (he)',
      );
    });
  });

  test('every Hebrew sign, body and node name is in Hebrew script', () {
    // Catches an untranslated Latin name; the literal table and kit.js pin
    // the traditional names (outer planets: the L10-013 exception).
    final hebrew = RegExp(r'^[א-ת\s-]+$');
    for (final s in ZodiacSign.values) {
      expect(he.signName(s), matches(hebrew), reason: '$s');
    }
    for (final b in Body.values) {
      expect(he.bodyName(b), matches(hebrew), reason: '$b');
    }
  });

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

    final kitEn = block('en');
    final kitHe = block('he');
    for (final e in _kitAspectKeys.entries) {
      expect(en.aspectName(e.key), scalar(kitEn, e.value), reason: e.value);
      expect(he.aspectName(e.key), scalar(kitHe, e.value), reason: e.value);
    }
    for (final d in CompassDirection.values) {
      final key = _kitDirectionKeys[d.index];
      expect(en.directionName(d), scalar(kitEn, key), reason: key);
      expect(he.directionName(d), scalar(kitHe, key), reason: key);
    }

    final rowsByKey = {
      for (final m in RegExp(
        r"\{ k: '(\w+)'.*?en: '([^']*)', he: '([^']*)'",
      ).allMatches(kit))
        m.group(1)!: (m.group(2)!, m.group(3)!),
    };
    for (final s in ZodiacSign.values) {
      expect((en.signName(s), he.signName(s)), rowsByKey[s.name], reason: '$s');
    }
    for (final b in Body.values) {
      expect((en.bodyName(b), he.bodyName(b)), rowsByKey[b.name], reason: '$b');
    }
  });
}
