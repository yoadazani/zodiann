// ZOD-EPH-002: the one place the running app chooses and binds its position
// source. It is also the only file of the app library that may import the
// astronomy-engine backup (test/di/astronomy_swap_test.dart).
import 'dart:io';

import 'package:astro_core/astro_core.dart';
import 'package:ephemeris_astronomy/ephemeris_astronomy.dart';
import 'package:ephemeris_astronomy/ephemeris_astronomy_native.dart';
import 'package:ephemeris_swiss/ephemeris_swiss.dart';
import 'package:ephemeris_swiss/ephemeris_swiss_native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:path_provider/path_provider.dart';

import '../ephemeris/ephemeris_status.dart';
import '../ephemeris/swiss_data_installer.dart';
import 'ephemeris_providers.dart';

/// What startup needs from the platform to choose a position source. Tests
/// supply their own. It provides **calculation sources and probe results,
/// never a port**, so every port is built by [ephemerisOverrides], behind the
/// supported date range.
///
/// Any member may throw: [ephemerisOverrides] is the one place that catches.
final class EphemerisDependencies {
  const EphemerisDependencies({
    required this.swissLoads,
    required this.prepareSwissData,
    required this.openSwissSource,
    required this.backupLoads,
    required this.openBackupSource,
  });

  /// Whether the Swiss Ephemeris library can be used.
  final bool Function() swissLoads;

  /// The directory holding the installed data files, or null if they are not
  /// installed.
  final Future<String?> Function() prepareSwissData;

  /// The calculation source over the files in a directory. It sets the data
  /// path, once for the whole process.
  final SwissCalculationSource Function(String directory) openSwissSource;

  /// Whether the astronomy-engine library can be used.
  final bool Function() backupLoads;

  /// The backup's state source.
  final BodyStateSource Function() openBackupSource;
}

/// The dependencies of the running app: the native libraries, the application
/// support directory and the packaged assets.
EphemerisDependencies productionEphemerisDependencies() =>
    EphemerisDependencies(
      swissLoads: () {
        // The first call resolves the native symbol; it throws if the library
        // cannot be loaded.
        SwissEphemerisBinding().version();
        return true;
      },
      prepareSwissData: _prepareSwissData,
      openSwissSource: (directory) => NativeSwissCalculationSource(
        SwissEphemerisBinding()..setEphePath(directory),
      ),
      backupLoads: () {
        const NativeBodyStateSource().bodyState(Body.sun, DateTime.utc(2000));
        return true;
      },
      openBackupSource: () => const NativeBodyStateSource(),
    );

Future<String?> _prepareSwissData() async {
  final support = await getApplicationSupportDirectory();
  final directory = Directory('${support.path}/ephe');
  final installed = await installSwissData(
    loadBundled: (name) async {
      final data = await rootBundle.load('$swissDataAssetDirectory/$name');
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    },
    directory: directory,
  );
  return installed ? directory.path : null;
}

/// Chooses the position source once and returns the bindings of the port and
/// of its status. It never throws.
///
/// * The Swiss library loads and its data files are installed: the primary
///   source.
/// * It does not load and the backup does: the backup. This is the only
///   automatic switch; missing files or unsupported dates never switch.
/// * Otherwise: the Swiss adapter over a source that cannot calculate, so every
///   physical body is reported unavailable instead of the app failing.
Future<List<Override>> ephemerisOverrides(
  EphemerisDependencies dependencies,
) async {
  var active = ActiveEphemerisSource.none;
  SwissCalculationSource swiss = const UnavailableSwissCalculationSource();
  BodyStateSource? backup;

  if (_loads('primary', dependencies.swissLoads)) {
    try {
      final directory = await dependencies.prepareSwissData();
      if (directory != null) {
        swiss = dependencies.openSwissSource(directory);
        active = ActiveEphemerisSource.primary;
      }
    } catch (error) {
      debugPrint('zodiann ephemeris: primary source unusable: $error');
    }
  } else if (_loads('backup', dependencies.backupLoads)) {
    try {
      backup = dependencies.openBackupSource();
      active = ActiveEphemerisSource.backup;
    } catch (error) {
      debugPrint('zodiann ephemeris: backup source unusable: $error');
    }
  }
  debugPrint('zodiann ephemeris source: ${active.name}');

  return [
    ephemerisPortProvider.overrideWithValue(
      SupportedRangeEphemeris(
        backup == null
            ? SwissEphemeris(source: swiss)
            : AstronomyEphemeris(source: backup),
      ),
    ),
    ephemerisStatusProvider.overrideWithValue(EphemerisStatus(active)),
  ];
}

bool _loads(String name, bool Function() probe) {
  try {
    return probe();
  } catch (error) {
    // A failed native resolution is an Error, not an Exception.
    debugPrint('zodiann ephemeris: $name library not loaded: $error');
    return false;
  }
}
