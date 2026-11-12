// Shape of the shared reference date set (ZOD-TST-002; reused by ZOD-TST-001
// for T-EPH-1 / ACC-1). The fixture is add-only: TST-001 may add instants and
// increment `version`, but must never drop or change a v1 instant.
//
// Run from `packages/astro_core` (as `melos exec` / `melos run test` do): the
// fixture path is relative to the package.
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

/// The 53 version-1 instants (chronological). Must stay in the fixture.
const _v1Instants = [
  '1899-12-31T12:00:00Z',
  '1900-01-01T00:00:00Z',
  '1905-01-01T00:00:00Z',
  '1910-01-01T00:00:00Z',
  '1912-06-30T06:00:00Z',
  '1915-01-01T00:00:00Z',
  '1920-01-01T00:00:00Z',
  '1925-01-01T00:00:00Z',
  '1930-01-01T00:00:00Z',
  '1935-01-01T00:00:00Z',
  '1940-01-01T00:00:00Z',
  '1945-01-01T00:00:00Z',
  '1950-01-01T00:00:00Z',
  '1950-12-31T23:59:59Z',
  '1955-01-01T00:00:00Z',
  '1960-01-01T00:00:00Z',
  '1965-01-01T00:00:00Z',
  '1969-07-20T20:17:00Z',
  '1970-01-01T00:00:00Z',
  '1975-01-01T00:00:00Z',
  '1980-01-01T00:00:00Z',
  '1985-01-01T00:00:00Z',
  '1990-01-01T00:00:00Z',
  '1995-01-01T00:00:00Z',
  '1999-12-31T23:59:59Z',
  '2000-01-01T00:00:00Z',
  '2000-01-01T12:00:00Z',
  '2000-12-31T23:59:59Z',
  '2005-01-01T00:00:00Z',
  '2010-01-01T00:00:00Z',
  '2015-01-01T00:00:00Z',
  '2020-01-01T00:00:00Z',
  '2024-12-31T23:59:59Z',
  '2025-01-01T00:00:00Z',
  '2026-11-12T00:00:00Z',
  '2030-01-01T00:00:00Z',
  '2035-01-01T00:00:00Z',
  '2040-01-01T00:00:00Z',
  '2045-01-01T00:00:00Z',
  '2050-01-01T00:00:00Z',
  '2055-01-01T00:00:00Z',
  '2060-01-01T00:00:00Z',
  '2061-07-28T18:30:00Z',
  '2065-01-01T00:00:00Z',
  '2070-01-01T00:00:00Z',
  '2075-01-01T00:00:00Z',
  '2080-01-01T00:00:00Z',
  '2085-01-01T00:00:00Z',
  '2090-01-01T00:00:00Z',
  '2095-01-01T00:00:00Z',
  '2099-12-31T23:59:59Z',
  '2100-01-01T00:00:00Z',
  '2100-01-01T12:00:00Z',
];

final _canonical = RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$');

String _two(int n) => n.toString().padLeft(2, '0');

/// Re-formats a parsed instant into the canonical pattern, so a string that
/// `DateTime.parse` silently normalized (e.g. Feb 30) no longer matches.
String _format(DateTime t) =>
    '${t.year.toString().padLeft(4, '0')}-${_two(t.month)}-${_two(t.day)}'
    'T${_two(t.hour)}:${_two(t.minute)}:${_two(t.second)}Z';

void main() {
  group('reference_dates.json', () {
    late Map<String, Object?> json;
    late List<String> dates;

    setUpAll(() {
      json = jsonDecode(
        File('test/fixtures/reference_dates.json').readAsStringSync(),
      ) as Map<String, Object?>;
      dates = (json['dates'] as List<dynamic>).cast<String>();
    });

    test('has an integer version ≥ 1', () {
      expect(json['version'], isA<int>());
      expect(json['version'] as int, greaterThanOrEqualTo(1));
    });

    test('contains every v1 shared instant unchanged', () {
      expect(_v1Instants, hasLength(53));
      expect(dates.toSet().containsAll(_v1Instants), isTrue);
    });

    test('has at least 50 unique instants', () {
      expect(dates.length, greaterThanOrEqualTo(50));
      expect(dates.toSet(), hasLength(dates.length));
    });

    test('every entry is a canonical UTC instant', () {
      for (final s in dates) {
        expect(_canonical.hasMatch(s), isTrue, reason: s);
        final parsed = DateTime.parse(s);
        expect(parsed.isUtc, isTrue, reason: s);
        expect(_format(parsed), s, reason: 'not canonical / normalized: $s');
      }
    });

    test('stays within the T = ±1 window', () {
      final start = DateTime.utc(1899, 12, 31, 12);
      final end = DateTime.utc(2100, 1, 1, 12);
      for (final s in dates) {
        final t = DateTime.parse(s);
        expect(t.isBefore(start) || t.isAfter(end), isFalse, reason: s);
      }
    });

    test('is in strictly chronological order', () {
      for (var i = 1; i < dates.length; i++) {
        expect(
          DateTime.parse(dates[i]).isAfter(DateTime.parse(dates[i - 1])),
          isTrue,
          reason: '${dates[i - 1]} then ${dates[i]}',
        );
      }
    });
  });
}
