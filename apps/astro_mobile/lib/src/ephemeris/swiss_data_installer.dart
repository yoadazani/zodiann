import 'dart:io';

import 'package:flutter/foundation.dart';

/// The asset directory of the packaged Swiss Ephemeris data files.
const String swissDataAssetDirectory = 'packages/ephemeris_swiss/assets/ephe';

/// The packaged data files (ZOD-FND-011: one 600-year block for the planets
/// and one for the Moon).
const List<String> swissDataFileNames = ['sepl_18.se1', 'semo_18.se1'];

/// Puts the packaged data files into [directory], where the native library can
/// read them (ZOD-EPH-002).
///
/// A file is written when it is missing or its bytes differ from the bundled
/// ones, through a temporary file that is renamed over the target, so an
/// interrupted copy never leaves a usable-looking wrong file in place.
///
/// True only when **both** files in [directory] hold exactly the bundled bytes.
/// It never throws: a file that cannot be installed makes the result false, and
/// the other is still attempted.
Future<bool> installSwissData({
  required Future<Uint8List> Function(String fileName) loadBundled,
  required Directory directory,
}) async {
  var installed = true;
  for (final name in swissDataFileNames) {
    try {
      final target = File('${directory.path}/$name');
      final temporary = File('${target.path}.tmp');
      if (await temporary.exists()) await temporary.delete();
      final bundled = await loadBundled(name);
      if (!await _holds(target, bundled)) {
        await directory.create(recursive: true);
        await temporary.writeAsBytes(bundled, flush: true);
        await temporary.rename(target.path);
      }
      if (!await _holds(target, bundled)) installed = false;
    } catch (error) {
      // Anything (a full disk, a missing asset) means "not installed".
      debugPrint('zodiann ephemeris data: $name not installed: $error');
      installed = false;
    }
  }
  return installed;
}

Future<bool> _holds(File file, Uint8List bytes) async =>
    await file.exists() &&
    await file.length() == bytes.length &&
    listEquals(await file.readAsBytes(), bytes);
