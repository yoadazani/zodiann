// ZOD-FND-007 criterion 1: with the device in airplane mode, both UI
// families render all four weights from the bundled fonts, resolved through
// the app's real font manifest (no FontLoader). Run manually:
//   adb -s emulator-5554 shell cmd connectivity airplane-mode enable
//   fvm flutter test integration_test -d emulator-5554
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

const _weights = [
  FontWeight.w300,
  FontWeight.w400,
  FontWeight.w500,
  FontWeight.w600,
];

/// An unregistered family: the platform's system font.
const _system = 'zodiann-missing-family';

double _width(String text, String family, FontWeight weight) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: family,
        package: family == _system ? null : ZodiannFonts.package,
        fontSize: 40,
        fontWeight: weight,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

void _expectBundled(String family, String text) {
  final widths = <double>{};
  for (final w in _weights) {
    final width = _width(text, family, w);
    // (b) not the system font at this weight.
    expect(
      width,
      isNot(_width(text, _system, w)),
      reason: '$family w${w.value} renders as the system font',
    );
    widths.add(width);
  }
  // (a) four distinct faces.
  expect(widths, hasLength(4), reason: '$family widths $widths');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('IBM Plex Sans: four distinct weights, none the system font', () {
    _expectBundled(ZodiannFonts.plexSans, 'Zodiann 0123456789');
  });

  test('IBM Plex Sans Hebrew: four distinct weights, none the system font', () {
    _expectBundled(ZodiannFonts.plexSansHebrew, 'זודיאן 0123456789');
  });

  test('the device is offline', () async {
    try {
      final addresses = await InternetAddress.lookup('example.com')
          .timeout(const Duration(seconds: 5));
      expect(addresses, isEmpty, reason: 'DNS resolved: the device is online');
    } on SocketException {
      // Offline: the lookup failed.
    } on TimeoutException {
      fail('DNS lookup hung; offline state not confirmed');
    }
  });
}
