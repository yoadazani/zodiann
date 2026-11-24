// ZOD-FND-011: the two range messages (R-2). The copy is not in kit.js; the
// owner approved these exact strings as an exception to the kit.js-only copy
// rule on 2026-11-25.
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  final en = lookupZodiannLocalizations(const Locale('en'));
  final he = lookupZodiannLocalizations(const Locale('he'));

  group('rangeOutsideSupported', () {
    test('English is the approved text with both bounds filled in', () {
      expect(
        en.rangeOutsideSupported('1.1.1900', '31.12.2100'),
        'This date is outside the supported range (1.1.1900 to 31.12.2100). '
        'Choose a date within it.',
      );
    });

    test('Hebrew is the approved text with both bounds filled in', () {
      expect(
        he.rangeOutsideSupported('1.1.1900', '31.12.2100'),
        'התאריך מחוץ לטווח הנתמך (1.1.1900 עד 31.12.2100). '
        'בחרו תאריך בתוך הטווח.',
      );
    });

    test('no raw placeholder is left in either language', () {
      for (final l in [en, he]) {
        final text = l.rangeOutsideSupported('A', 'B');
        expect(text, contains('A'));
        expect(text, contains('B'));
        expect(text, isNot(contains('{')));
        expect(text, isNot(contains('}')));
      }
    });
  });

  group('rangeDataUnavailable', () {
    test('English is the approved text', () {
      expect(
        en.rangeDataUnavailable,
        'Position data for this date is not available on this device.',
      );
    });

    test('Hebrew is the approved text', () {
      expect(
        he.rangeDataUnavailable,
        'נתוני המיקום לתאריך זה אינם זמינים במכשיר.',
      );
    });
  });

  test('the two messages are different failures with different text', () {
    expect(
      en.rangeOutsideSupported('a', 'b'),
      isNot(contains(en.rangeDataUnavailable)),
    );
    expect(en.rangeDataUnavailable, isNot(contains('range')));
  });
}
