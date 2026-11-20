// ZOD-FND-003 (Android half): runs the real Swiss Ephemeris C library through
// the FFI binding on a device, with data files that were bundled as package
// assets and copied to a real directory. Run on an Android device or emulator:
//   flutter test integration_test/swiss_ephemeris_spike_test.dart -d <device>
//
// A correct longitude alone proves nothing about the data files: the library
// falls back to its built-in Moshier ephemeris, which is close for the Sun.
// So every file-mode check also needs the Swiss Ephemeris flag, no warning,
// and a negative control must fall back.
import 'dart:io';

import 'package:ephemeris_swiss/ephemeris_swiss.dart';
import 'package:ephemeris_swiss/ephemeris_swiss_native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import 'reference_longitudes.dart';

const _assetDirectory = 'packages/ephemeris_swiss/assets/ephe';
const _dataFiles = ['sepl_18.se1', 'semo_18.se1'];

/// Smallest angle between two longitudes, in arcseconds.
double arcsecondsBetween(double a, double b) {
  var difference = (a - b).abs() % 360;
  if (difference > 180) difference = 360 - difference;
  return difference * 3600;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory dataDirectory;
  final binding = SwissEphemerisBinding();

  setUpAll(() async {
    // Swiss Ephemeris needs a real file-system path; assets live inside the
    // APK, so they are copied out once.
    final support = await getApplicationSupportDirectory();
    dataDirectory = Directory('${support.path}/ephe')
      ..createSync(recursive: true);
    for (final name in _dataFiles) {
      final bundled = await rootBundle.load('$_assetDirectory/$name');
      final bytes = bundled.buffer.asUint8List(
        bundled.offsetInBytes,
        bundled.lengthInBytes,
      );
      final target = File('${dataDirectory.path}/$name');
      await target.writeAsBytes(bytes, flush: true);
      expect(target.lengthSync(), bytes.length, reason: '$name copied whole');
    }
  });

  // The library keeps its ephemeris path in global state, so every test sets
  // it itself before its first calculation.
  void usePath(String path) => binding.setEphePath(path);

  test('the library reports a 2.10 version', () {
    expect(binding.version(), startsWith('2.10'));
  });

  test('file mode: Sun and Moon agree with Horizons within one arcsecond '
      'and really come from the data files', () {
    usePath(dataDirectory.path);
    for (final reference in referenceLongitudes) {
      final utc = DateTime.parse(reference.utc);
      expect(utc.isUtc, isTrue);
      final body = reference.body == 'sun' ? seSun : seMoon;
      final result = binding.calcUt(utc, body);
      final off = arcsecondsBetween(
        result.longitude,
        reference.longitudeDegrees,
      );
      final label = '${reference.body} ${reference.utc}';
      // ignore: avoid_print
      print(
        '$label: ${result.longitude} vs ${reference.longitudeDegrees} '
        '(off $off arcsec, flags ${result.returnFlags}, '
        'error "${result.error}")',
      );
      expect(off, lessThanOrEqualTo(toleranceArcseconds), reason: label);
      expect(result.usedSwissEphemerisFiles, isTrue, reason: label);
    }
  });

  test('negative control: an empty directory falls back to Moshier', () {
    final empty = Directory.systemTemp.createTempSync('swisseph_empty');
    addTearDown(() => empty.deleteSync(recursive: true));
    usePath(empty.path);
    final result = binding.calcUt(DateTime.utc(2000, 1, 1, 12), seSun);
    expect(result.returnFlags & seflgMoseph, isNot(0));
    expect(result.returnFlags & seflgSwieph, 0);
    expect(result.error, isNotEmpty);
    expect(result.usedSwissEphemerisFiles, isFalse);
  });

  test('out of file range: 1799-12-31 silently falls back (recorded, not '
      'fixed: the adapter must check the flags to honour R-2)', () {
    usePath(dataDirectory.path);
    final result = binding.calcUt(DateTime.utc(1799, 12, 31), seSun);
    // ignore: avoid_print
    print('1799-12-31: flags ${result.returnFlags}, error "${result.error}"');
    expect(result.usedSwissEphemerisFiles, isFalse);
  });
}
