// ZOD-EPH-002: the packaged data files on the device are exactly the bundled
// bytes, or the install says no. Temporary directories and small fake bytes.
import 'dart:io';
import 'dart:typed_data';

import 'package:astro_mobile/src/ephemeris/swiss_data_installer.dart';
import 'package:flutter_test/flutter_test.dart';

final _bundled = {
  'sepl_18.se1': Uint8List.fromList([1, 2, 3, 4, 5]),
  'semo_18.se1': Uint8List.fromList([9, 8, 7]),
};

void main() {
  late Directory root;
  late Directory directory;

  setUp(() {
    root = Directory.systemTemp.createTempSync('swiss_install_');
    directory = Directory('${root.path}/ephe');
  });
  tearDown(() => root.deleteSync(recursive: true));

  File target(String name) => File('${directory.path}/$name');

  Future<bool> install({Set<String> failing = const {}}) => installSwissData(
    loadBundled: (name) async {
      if (failing.contains(name)) throw StateError('no asset $name');
      return _bundled[name]!;
    },
    directory: directory,
  );

  void write(String name, List<int> bytes) => target(name)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes);

  void expectInstalled(String name) =>
      expect(target(name).readAsBytesSync(), _bundled[name], reason: name);

  List<String> temporaryFiles() => [
    for (final entity in directory.listSync())
      if (entity.path.endsWith('.tmp')) entity.path,
  ];

  test('the names are the packaged files', () {
    final packaged = Directory('../../packages/ephemeris_swiss/assets/ephe')
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .toSet();

    expect(swissDataFileNames.toSet(), packaged);
    expect(swissDataAssetDirectory, 'packages/ephemeris_swiss/assets/ephe');
  });

  test('a fresh install creates the directory and writes both files', () async {
    expect(await install(), isTrue);

    swissDataFileNames.forEach(expectInstalled);
    expect(temporaryFiles(), isEmpty);
  });

  test('a file that is already right is not rewritten', () async {
    await install();
    final old = DateTime(2001, 2, 3);
    for (final name in swissDataFileNames) {
      target(name).setLastModifiedSync(old);
    }

    expect(await install(), isTrue);

    for (final name in swissDataFileNames) {
      expect(target(name).lastModifiedSync(), old, reason: name);
    }
  });

  test('different bytes of the same size are replaced', () async {
    write('sepl_18.se1', [5, 4, 3, 2, 1]);

    expect(await install(), isTrue);

    expectInstalled('sepl_18.se1');
  });

  test('a short file left by an interrupted copy is replaced', () async {
    write('semo_18.se1', [9]);

    expect(await install(), isTrue);

    expectInstalled('semo_18.se1');
  });

  test('a stray temporary file beside a correct one is removed', () async {
    await install();
    write('sepl_18.se1.tmp', [0, 0]);

    expect(await install(), isTrue);

    expect(temporaryFiles(), isEmpty);
    expectInstalled('sepl_18.se1');
  });

  test('an unusable directory gives false without throwing', () async {
    File(directory.path).writeAsStringSync('not a directory');

    expect(await install(), isFalse);
  });

  test('one file that cannot be written does not stop the other', () async {
    Directory('${directory.path}/sepl_18.se1').createSync(recursive: true);

    expect(await install(), isFalse);

    expectInstalled('semo_18.se1');
  });

  test('an asset that cannot be loaded gives false, and installs the other, '
      'even over an older copy', () async {
    write('sepl_18.se1', [1]);

    expect(await install(failing: {'sepl_18.se1'}), isFalse);

    expectInstalled('semo_18.se1');
    expect(target('sepl_18.se1').readAsBytesSync(), [1]);
  });
}
