// ZOD-FND-008: the pure parts of the launcher-icon generator: SVG variants,
// size tables, the output list.
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../../tool/launcher/launcher_spec.dart';

const _assets = 'design-reference/zodiann/assets';
const _contentsPath =
    'apps/astro_mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/'
    'Contents.json';

String _tiled() => File('$_assets/zodiann-logo.svg').readAsStringSync();
String _onDark() =>
    File('$_assets/zodiann-logo-on-dark.svg').readAsStringSync();
String _contents() => File(_contentsPath).readAsStringSync();

void main() {
  group('fullBleedSvg', () {
    test('drops the tile rounding and changes nothing else', () {
      final out = fullBleedSvg(_tiled());
      expect(out, isNot(contains('rx="230"')));
      expect(out, contains('rx="0"'));
      expect(out.replaceFirst('rx="0"', 'rx="230"'), _tiled());
    });

    test('throws unless exactly one rounded tile', () {
      expect(() => fullBleedSvg(_onDark()), throwsA(isA<LauncherException>()));
      final two = _tiled().replaceFirst(
        '<rect ',
        '<rect rx="230" width="1" height="1"/><rect ',
      );
      expect(() => fullBleedSvg(two), throwsA(isA<LauncherException>()));
    });
  });

  group('backgroundSvg', () {
    test('keeps the gradient definitions and only the tile rect', () {
      final out = backgroundSvg(_tiled());
      expect(out, contains('id="bg"'));
      expect('<rect'.allMatches(out), hasLength(1));
      expect(out, contains('rx="0"'));
      expect(out, contains('fill="url(#bg)"'));
      // `<line ` with its space: `<linearGradient` must stay.
      for (final gone in ['<circle', '<line ', '<path']) {
        expect(out, isNot(contains(gone)), reason: gone);
      }
      expect(out, startsWith('<svg'));
      expect(out.trimRight(), endsWith('</svg>'));
    });

    test('throws on zero or two tile rects', () {
      expect(() => backgroundSvg(_onDark()), throwsA(isA<LauncherException>()));
      final two = _tiled().replaceFirst(
        '<rect ',
        '<rect rx="230" width="1" height="1"/><rect ',
      );
      expect(() => backgroundSvg(two), throwsA(isA<LauncherException>()));
    });
  });

  group('sizedSvg and foregroundSvg', () {
    test('sizedSvg sets the root width and height', () {
      final out = sizedSvg(_tiled(), 60);
      expect(out, contains('width="60" height="60"'));
      expect(out, contains('viewBox="0 0 1024 1024"'));
    });

    test('foregroundSvg centres the mark at 66/108 of the canvas', () {
      final out = foregroundSvg(_onDark(), 108);
      expect(out, contains('width="108" height="108"'));
      expect(out, contains('viewBox="-221.09 -221.09 1466.18 1466.18"'));
    });

    test('both throw when the root size is not exactly one 1024 pair', () {
      expect(
        () => sizedSvg('<svg viewBox="0 0 1 1"></svg>', 10),
        throwsA(isA<LauncherException>()),
      );
      expect(
        () => foregroundSvg('<svg viewBox="0 0 1 1"></svg>', 10),
        throwsA(isA<LauncherException>()),
      );
    });
  });

  group('iosIcons', () {
    test('one entry per distinct filename, with size × scale pixels', () {
      final icons = iosIcons(_contents());
      expect(icons, hasLength(15));
      final images =
          (jsonDecode(_contents()) as Map<String, Object?>)['images']!
              as List<Object?>;
      expect(images, hasLength(19));
      for (final raw in images) {
        final image = raw! as Map<String, Object?>;
        final side = double.parse((image['size']! as String).split('x').first);
        final scale = int.parse(
          (image['scale']! as String).replaceAll('x', ''),
        );
        final match = icons.singleWhere((i) => i.filename == image['filename']);
        expect(match.pixels, (side * scale).round(), reason: match.filename);
      }
      int px(String f) => icons.singleWhere((i) => i.filename == f).pixels;
      expect(px('Icon-App-20x20@3x.png'), 60);
      expect(px('Icon-App-83.5x83.5@2x.png'), 167);
      expect(px('Icon-App-1024x1024@1x.png'), 1024);
      // Same pixel size, different files.
      expect(px('Icon-App-20x20@2x.png'), px('Icon-App-40x40@1x.png'));
      expect(px('Icon-App-40x40@3x.png'), px('Icon-App-60x60@2x.png'));
    });

    test('throws on a filename with two different pixel sizes', () {
      const conflicting = '''
{"images":[
 {"size":"20x20","scale":"2x","filename":"a.png"},
 {"size":"20x20","scale":"3x","filename":"a.png"}]}''';
      expect(() => iosIcons(conflicting), throwsA(isA<LauncherException>()));
    });

    test('throws on a non-integer size × scale', () {
      const fractional = '''
{"images":[{"size":"83.5x83.5","scale":"1x","filename":"a.png"}]}''';
      expect(() => iosIcons(fractional), throwsA(isA<LauncherException>()));
    });
  });

  group('Android sizes and the foreground geometry', () {
    test('density tables', () {
      expect(androidLegacy, {
        'mdpi': 48,
        'hdpi': 72,
        'xhdpi': 96,
        'xxhdpi': 144,
        'xxxhdpi': 192,
      });
      expect(androidAdaptive, {
        'mdpi': 108,
        'hdpi': 162,
        'xhdpi': 216,
        'xxhdpi': 324,
        'xxxhdpi': 432,
      });
    });

    test('foregroundMarkSide puts the mark in the 66 dp safe zone', () {
      expect(foregroundMarkSide(432), closeTo(301.714, 0.001));
      expect(foregroundMarkSide(108), closeTo(75.43, 0.01));
    });
  });

  group('launcherOutputs', () {
    test('lists every output once, with its pixel size', () {
      final outputs = launcherOutputs(_contents());
      expect(outputs, hasLength(15 + 5 + 5 + 1));
      expect({for (final o in outputs) o.path}, hasLength(outputs.length));
      for (final o in outputs) {
        expect(o.path, isNot(contains(r'\')));
        expect(o.path, startsWith('apps/astro_mobile/'));
      }
      LauncherOutput of(String suffix) =>
          outputs.singleWhere((o) => o.path.endsWith(suffix));
      expect(of('mipmap-hdpi/ic_launcher.png').pixels, 72);
      expect(of('mipmap-xxxhdpi/ic_launcher_foreground.png').pixels, 432);
      expect(of('drawable-nodpi/ic_launcher_background.png').pixels, 432);
      expect(of('Icon-App-60x60@3x.png').pixels, 180);
      expect(of('Icon-App-60x60@3x.png').kind, LauncherKind.iosIcon);
      expect(
        of('mipmap-mdpi/ic_launcher_foreground.png').kind,
        LauncherKind.androidForeground,
      );
    });
  });
}
