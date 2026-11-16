// ZOD-FND-008: the pure parts of the launcher-icon generator
// (tool/launcher/gen_launcher_icons.dart): SVG variants derived from the
// design reference's logo SVGs, the platform size tables, and the list of
// files the generator writes. No I/O and no Chrome here.
import 'dart:convert';

/// A source SVG is not in the shape the generator expects, or a
/// `Contents.json` is inconsistent.
class LauncherException implements Exception {
  LauncherException(this.message);

  final String message;

  @override
  String toString() => 'LauncherException: $message';
}

/// The workspace-relative roots the generator writes under (forward slashes).
const androidResDir = 'apps/astro_mobile/android/app/src/main/res';
const iosIconDir =
    'apps/astro_mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset';
const iosContentsPath = '$iosIconDir/Contents.json';

/// Legacy launcher icon sizes (px) per Android density.
const androidLegacy = {
  'mdpi': 48,
  'hdpi': 72,
  'xhdpi': 96,
  'xxhdpi': 144,
  'xxxhdpi': 192,
};

/// Adaptive-icon layer sizes (px): the 108 dp canvas per Android density.
const androidAdaptive = {
  'mdpi': 108,
  'hdpi': 162,
  'xhdpi': 216,
  'xxhdpi': 324,
  'xxxhdpi': 432,
};

const _tile = 'rx="230"';
const _rootSize = 'width="1024" height="1024"';
const _rootViewBox = 'viewBox="0 0 1024 1024"';

/// The outer ring is `r = 446` with a 4-unit stroke, so the mark's ink spans
/// 896 of the 1024 viewBox units.
const _markUnits = 896.0;

/// The adaptive-icon canvas and its safe-zone circle, in dp.
const _canvasDp = 108.0;
const _safeDp = 66.0;

String _openTag(String svg) {
  final end = svg.indexOf('>');
  if (!svg.startsWith('<svg') || end < 0) {
    throw LauncherException('The SVG does not start with an <svg> tag.');
  }
  return svg.substring(0, end + 1);
}

void _requireOnce(String within, String needle, String what) {
  if (needle.allMatches(within).length != 1) {
    throw LauncherException('Expected exactly one $needle in $what.');
  }
}

/// [tiledSvg] with the tile's corner rounding removed, so the rendering is a
/// full-bleed square (iOS applies its own mask).
String fullBleedSvg(String tiledSvg) {
  _requireOnce(tiledSvg, _tile, 'the tiled logo');
  return tiledSvg.replaceFirst(_tile, 'rx="0"');
}

/// The tiled logo's root `<svg>`, its `<defs>` and only the full-bleed tile
/// rect (the adaptive icon's background layer).
String backgroundSvg(String tiledSvg) {
  _requireOnce(tiledSvg, _tile, 'the tiled logo');
  final open = _openTag(tiledSvg);
  final defsStart = tiledSvg.indexOf('<defs>');
  final defsEnd = tiledSvg.indexOf('</defs>');
  if (defsStart < 0 || defsEnd < defsStart) {
    throw LauncherException('The tiled logo has no <defs> block.');
  }
  final at = tiledSvg.indexOf(_tile);
  final rectStart = tiledSvg.lastIndexOf('<rect', at);
  final rectEnd = tiledSvg.indexOf('/>', at);
  if (rectStart < 0 || rectEnd < 0) {
    throw LauncherException('The tile rect is not a self-closed <rect />.');
  }
  final rect = tiledSvg
      .substring(rectStart, rectEnd + 2)
      .replaceFirst(_tile, 'rx="0"');
  final defs = tiledSvg.substring(defsStart, defsEnd + '</defs>'.length);
  return '$open\n$defs\n$rect\n</svg>\n';
}

/// [svg] with its root width and height set to [px].
String sizedSvg(String svg, int px) {
  final open = _openTag(svg);
  _requireOnce(open, _rootSize, 'the root <svg>');
  return svg.replaceFirst(
    open,
    open.replaceFirst(_rootSize, 'width="$px" height="$px"'),
  );
}

/// The side, in px, of the mark inside an adaptive-icon foreground of
/// [canvasPx]: the mark's 896 units fill the 66 dp safe zone of the 108 dp
/// canvas.
double foregroundMarkSide(int canvasPx) =>
    canvasPx * _safeDp * 1024 / (_canvasDp * _markUnits);

/// [onDarkSvg] drawn on a transparent [canvasPx] square with the mark scaled
/// into the safe zone: the root `viewBox` is widened around the centre so the
/// mark spans [foregroundMarkSide] px.
String foregroundSvg(String onDarkSvg, int canvasPx) {
  final open = _openTag(onDarkSvg);
  _requireOnce(open, _rootSize, 'the root <svg>');
  _requireOnce(open, _rootViewBox, 'the root <svg>');
  final side = _canvasDp * _markUnits / _safeDp;
  final origin = (1024 - side) / 2;
  final box =
      '${origin.toStringAsFixed(2)} ${origin.toStringAsFixed(2)} '
      '${side.toStringAsFixed(2)} ${side.toStringAsFixed(2)}';
  return onDarkSvg.replaceFirst(
    open,
    open
        .replaceFirst(_rootViewBox, 'viewBox="$box"')
        .replaceFirst(_rootSize, 'width="$canvasPx" height="$canvasPx"'),
  );
}

/// One file of the iOS app-icon set.
class IosIcon {
  const IosIcon(this.filename, this.pixels);

  final String filename;
  final int pixels;
}

/// The icons `Contents.json` names: one per distinct filename, `pixels` =
/// `size × scale` (an iPhone and an iPad entry may share a file).
List<IosIcon> iosIcons(String contentsJson) {
  final images = (jsonDecode(contentsJson) as Map<String, Object?>)['images'];
  if (images is! List) {
    throw LauncherException('Contents.json has no "images" list.');
  }
  final byName = <String, int>{};
  for (final raw in images) {
    final image = raw as Map<String, Object?>;
    final filename = image['filename'] as String?;
    if (filename == null) continue; // an unfilled slot
    final side = double.parse((image['size']! as String).split('x').first);
    final scale = int.parse((image['scale']! as String).replaceAll('x', ''));
    final pixels = side * scale;
    if ((pixels - pixels.round()).abs() > 1e-9) {
      throw LauncherException(
        '$filename: ${image['size']} @${image['scale']} is not a whole pixel '
        'size.',
      );
    }
    final known = byName[filename];
    if (known != null && known != pixels.round()) {
      throw LauncherException(
        '$filename appears with $known px and ${pixels.round()} px.',
      );
    }
    byName[filename] = pixels.round();
  }
  return [for (final e in byName.entries) IosIcon(e.key, e.value)];
}

enum LauncherKind {
  iosIcon,
  androidLegacy,
  androidForeground,
  androidBackground,
}

/// A file the generator writes: workspace-relative path (forward slashes),
/// square pixel size, and how it is rendered.
class LauncherOutput {
  const LauncherOutput(this.path, this.pixels, this.kind);

  final String path;
  final int pixels;
  final LauncherKind kind;
}

/// Every file the generator writes, given the iOS `Contents.json`. The
/// hand-written adaptive-icon XML is not among them.
List<LauncherOutput> launcherOutputs(String contentsJson) => [
  for (final icon in iosIcons(contentsJson))
    LauncherOutput(
      '$iosIconDir/${icon.filename}',
      icon.pixels,
      LauncherKind.iosIcon,
    ),
  for (final e in androidLegacy.entries)
    LauncherOutput(
      '$androidResDir/mipmap-${e.key}/ic_launcher.png',
      e.value,
      LauncherKind.androidLegacy,
    ),
  for (final e in androidAdaptive.entries)
    LauncherOutput(
      '$androidResDir/mipmap-${e.key}/ic_launcher_foreground.png',
      e.value,
      LauncherKind.androidForeground,
    ),
  LauncherOutput(
    '$androidResDir/drawable-nodpi/ic_launcher_background.png',
    androidAdaptive['xxxhdpi']!,
    LauncherKind.androidBackground,
  ),
];
