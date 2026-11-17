// ZOD-FND-008 (AC1): the committed launcher icons are the ones the generator
// derives from the logo SVGs, and they satisfy the platforms' rules. Static
// checks only: no emulator, no Xcode. Runs from the workspace root on every
// `melos run test`; `melos run launcher:check` repeats the freshness part.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:test/test.dart';

import '../../tool/launcher/gen_launcher_icons.dart';
import '../../tool/launcher/launcher_spec.dart';

final _contents = File(iosContentsPath).readAsStringSync();
final _outputs = launcherOutputs(_contents);

Iterable<LauncherOutput> _of(LauncherKind kind) =>
    _outputs.where((o) => o.kind == kind);

Uint8List _bytes(String path) => File(path).readAsBytesSync();

/// (width, height, colour type) from a PNG's IHDR.
(int, int, int) _ihdr(Uint8List b) {
  int u32(int o) => b[o] << 24 | b[o + 1] << 16 | b[o + 2] << 8 | b[o + 3];
  return (u32(16), u32(20), b[25]);
}

/// The chunk types of a PNG, in order.
List<String> _chunks(Uint8List b) {
  final types = <String>[];
  var offset = 8;
  while (offset + 8 <= b.length) {
    final length =
        b[offset] << 24 |
        b[offset + 1] << 16 |
        b[offset + 2] << 8 |
        b[offset + 3];
    types.add(String.fromCharCodes(b.sublist(offset + 4, offset + 8)));
    offset += 12 + length;
  }
  return types;
}

img.Image _decode(String path) => img.decodePng(_bytes(path))!;

List<int> _rgb(img.Image image, int x, int y) {
  final p = image.getPixel(x, y);
  return [p.r.toInt(), p.g.toInt(), p.b.toInt()];
}

void _near(List<int> actual, List<int> expected, String reason) {
  for (var i = 0; i < 3; i++) {
    expect(
      actual[i],
      inInclusiveRange(expected[i] - 3, expected[i] + 3),
      reason: '$reason: $actual vs $expected',
    );
  }
}

/// A temp copy of everything --check reads: the SVGs, the manifest, the
/// generator spec, Contents.json and every output.
({Directory root, Directory sources}) _tempCopy() {
  final root = Directory.systemTemp.createTempSync('zod_launcher_check_');
  addTearDown(() => root.deleteSync(recursive: true));
  void copy(String path) {
    final to = File('${root.path}/$path')..parent.createSync(recursive: true);
    File(path).copySync(to.path);
  }

  copy(manifestPath);
  copy(specPath);
  copy(iosContentsPath);
  for (final o in _outputs) {
    copy(o.path);
  }
  final sources = Directory('${root.path}/svg')..createSync();
  for (final name in ['zodiann-logo.svg', 'zodiann-logo-on-dark.svg']) {
    File('$defaultSourceDir/$name').copySync('${sources.path}/$name');
  }
  return (root: root, sources: sources);
}

void main() {
  group('iOS', () {
    test('every AppIcon filename in Contents.json exists with its exact pixel size', () {
      final icons = iosIcons(_contents);
      expect(icons, hasLength(15));
      for (final icon in icons) {
        final file = '$iosIconDir/${icon.filename}';
        expect(File(file).existsSync(), isTrue, reason: file);
        final (w, h, _) = _ihdr(_bytes(file));
        expect((w, h), (icon.pixels, icon.pixels), reason: file);
      }
    });

    test('every iOS icon is RGB with no alpha channel', () {
      for (final o in _of(LauncherKind.iosIcon)) {
        final b = _bytes(o.path);
        expect(_ihdr(b).$3, 2, reason: '${o.path} colour type (2 = RGB)');
        expect(_chunks(b), isNot(contains('tRNS')), reason: o.path);
      }
    });

    test(
      'the 1024 and 167 iOS icons have the tile gradient in every corner',
      () {
        for (final name in [
          'Icon-App-1024x1024@1x.png',
          'Icon-App-83.5x83.5@2x.png',
        ]) {
          final image = _decode('$iosIconDir/$name');
          final s = image.width;
          _near(_rgb(image, 0, 0), [27, 27, 29], '$name top-left');
          _near(_rgb(image, s - 1, 0), [27, 27, 29], '$name top-right');
          _near(_rgb(image, 0, s - 1), [19, 19, 20], '$name bottom-left');
          _near(_rgb(image, s - 1, s - 1), [19, 19, 20], '$name bottom-right');
          _near(_rgb(image, s ~/ 2, 0), [35, 35, 37], '$name top-centre');
          for (final (x, y) in [
            (0, 0),
            (s - 1, 0),
            (0, s - 1),
            (s - 1, s - 1),
          ]) {
            expect(
              _rgb(image, x, y),
              isNot([0, 0, 0]),
              reason: '$name ($x, $y)',
            );
          }
        }
      },
    );
  });

  group('Android', () {
    test('legacy icons are RGBA with transparent corners, one per density', () {
      expect(_of(LauncherKind.androidLegacy), hasLength(5));
      for (final o in _of(LauncherKind.androidLegacy)) {
        final b = _bytes(o.path);
        final (w, h, type) = _ihdr(b);
        expect((w, h), (o.pixels, o.pixels), reason: o.path);
        expect(type, 6, reason: '${o.path} colour type (6 = RGBA)');
        final image = img.decodePng(b)!;
        for (final (x, y) in [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)]) {
          expect(
            image.getPixel(x, y).a.toInt(),
            0,
            reason: '${o.path} ($x, $y)',
          );
        }
      }
    });

    test('adaptive foregrounds are S x S, transparent at the corners, and '
        'every pixel with alpha > 8 lies inside the safe zone', () {
      expect(_of(LauncherKind.androidForeground), hasLength(5));
      for (final o in _of(LauncherKind.androidForeground)) {
        final image = _decode(o.path);
        final s = o.pixels;
        expect((image.width, image.height), (s, s), reason: o.path);
        for (final (x, y) in [(0, 0), (s - 1, 0), (0, s - 1), (s - 1, s - 1)]) {
          expect(
            image.getPixel(x, y).a.toInt(),
            0,
            reason: '${o.path} ($x, $y)',
          );
        }
        // 66 dp safe-zone circle on a 108 dp canvas; centre in pixel-centre
        // coordinates. Fix the geometry, never this tolerance.
        final limit = 33 * s / 108 + 1;
        final c = (s - 1) / 2;
        var farthest = 0.0;
        var ink = 0;
        for (var y = 0; y < s; y++) {
          for (var x = 0; x < s; x++) {
            if (image.getPixel(x, y).a.toInt() > 8) {
              ink++;
              farthest = math.max(
                farthest,
                math.sqrt((x - c) * (x - c) + (y - c) * (y - c)),
              );
            }
          }
        }
        expect(ink, greaterThan(s * s ~/ 20), reason: '${o.path} has a mark');
        expect(
          farthest,
          lessThanOrEqualTo(limit),
          reason: '${o.path} ink radius',
        );
        expect(
          farthest,
          greaterThan(limit - 2),
          reason: '${o.path} fills the safe zone',
        );
      }
    });

    test('the adaptive background is an opaque 432 px square', () {
      final o = _of(LauncherKind.androidBackground).single;
      expect(o.pixels, 432);
      final b = _bytes(o.path);
      expect(_ihdr(b), (432, 432, 2));
      expect(_chunks(b), isNot(contains('tRNS')));
    });

    test('the adaptive icon XML names the generated layers', () {
      const path = '$androidResDir/mipmap-anydpi-v26/ic_launcher.xml';
      expect(File(path).existsSync(), isTrue, reason: path);
      final xml = File(path).readAsStringSync();
      expect(xml, contains('<adaptive-icon'));
      expect(
        xml,
        contains(
          '<background android:drawable="@drawable/ic_launcher_background"/>',
        ),
      );
      expect(
        xml,
        contains(
          '<foreground android:drawable="@mipmap/ic_launcher_foreground"/>',
        ),
      );
    });

    test('AndroidManifest still points at @mipmap/ic_launcher', () {
      final manifest = File(
        'apps/astro_mobile/android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
      expect(manifest, contains('android:icon="@mipmap/ic_launcher"'));
    });
  });

  group('manifest', () {
    test(
      'names the live SHA-256 of the two SVGs and every output file',
      () async {
        expect(await checkLauncher(sourceDir: defaultSourceDir, root: '.'), 0);
      },
    );
  });

  group('--check', () {
    test('--check exits 0 on the committed tree', () async {
      final t = _tempCopy();
      expect(
        await checkLauncher(sourceDir: t.sources.path, root: t.root.path),
        0,
      );
    });

    test('--check exits 1 when a source SVG byte is changed', () async {
      final t = _tempCopy();
      final svg = File('${t.sources.path}/zodiann-logo-on-dark.svg');
      svg.writeAsStringSync('${svg.readAsStringSync()}\n<!-- changed -->');
      expect(
        await checkLauncher(sourceDir: t.sources.path, root: t.root.path),
        1,
      );
    });

    test('--check exits 1 when an output PNG is changed', () async {
      final t = _tempCopy();
      final png = File(
        '${t.root.path}/${_of(LauncherKind.androidLegacy).first.path}',
      );
      png.writeAsBytesSync([...png.readAsBytesSync(), 0]);
      expect(
        await checkLauncher(sourceDir: t.sources.path, root: t.root.path),
        1,
      );
    });

    test('--check exits 1 when an output PNG is missing', () async {
      final t = _tempCopy();
      File('${t.root.path}/${_of(LauncherKind.iosIcon).first.path}')
          .deleteSync();
      expect(
        await checkLauncher(sourceDir: t.sources.path, root: t.root.path),
        1,
      );
    });

    test(
      '--check exits 2 when the source SVG has two rx="230" rects',
      () async {
        final t = _tempCopy();
        final svg = File('${t.sources.path}/zodiann-logo.svg');
        svg.writeAsStringSync(
          svg.readAsStringSync().replaceFirst(
            '<rect ',
            '<rect rx="230" width="1" height="1"/><rect ',
          ),
        );
        expect(
          await checkLauncher(sourceDir: t.sources.path, root: t.root.path),
          2,
        );
      },
    );

    test('--check exits 64 on an unknown argument', () async {
      final result = await Process.run(Platform.resolvedExecutable, [
        'run',
        'tool/launcher/gen_launcher_icons.dart',
        '--bogus',
      ]);
      expect(result.exitCode, 64);
    });
  });
}
