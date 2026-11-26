// ZOD-EPH-002 device tests: the packaged Swiss Ephemeris files copied to a
// real directory, because the library needs a file-system path.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

const testSwissDataFiles = ['sepl_18.se1', 'semo_18.se1'];

/// A fresh copy of both packaged files under the application support directory,
/// apart from the one the app itself uses.
Future<Directory> installTestSwissData() async {
  final support = await getApplicationSupportDirectory();
  final directory = Directory('${support.path}/ephe_test')
    ..createSync(recursive: true);
  for (final name in testSwissDataFiles) {
    final bundled = await rootBundle.load(
      'packages/ephemeris_swiss/assets/ephe/$name',
    );
    await File('${directory.path}/$name').writeAsBytes(
      bundled.buffer.asUint8List(bundled.offsetInBytes, bundled.lengthInBytes),
      flush: true,
    );
  }
  return directory;
}
