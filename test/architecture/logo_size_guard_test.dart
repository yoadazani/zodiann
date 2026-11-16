// ZOD-FND-008 (AC3): the logo never renders below 40 px. Every ZodiannLogo
// call passes a ZodiannSize.logo… token (no numeric literal), and only
// zodiann_logo.dart names the bundled marks. Runs from the workspace root on
// every `melos run test`.
import 'dart:io';

import 'package:test/test.dart';

import 'logo_calls.dart';

const _logoFile = 'packages/shared_ui/lib/src/widgets/zodiann_logo.dart';

void main() {
  final scanned = <String>[];
  final sizeHits = <String>[];
  final assetHits = <String>[];

  for (final top in ['apps', 'packages']) {
    for (final member in Directory(top).listSync().whereType<Directory>()) {
      final lib = Directory('${member.path}/lib');
      if (!lib.existsSync()) continue;
      for (final file in lib.listSync(recursive: true).whereType<File>()) {
        final path = file.path.replaceAll(r'\', '/');
        if (!path.endsWith('.dart')) continue;
        scanned.add(path);
        final text = file.readAsStringSync();
        for (final hit in findLogoSizeViolations(text)) {
          sizeHits.add('$path:$hit');
        }
        if (path != _logoFile && logoAsset.hasMatch(text)) {
          assetHits.add(path);
        }
      }
    }
  }

  test('every ZodiannLogo size is a ZodiannSize.logo token', () {
    expect(
      sizeHits,
      isEmpty,
      reason:
          'AC3: pass ZodiannSize.logoDrawer / logoAbout (never below 40).\n'
          '${sizeHits.join('\n')}',
    );
  });

  test('only zodiann_logo.dart names the bundled marks', () {
    expect(
      assetHits,
      isEmpty,
      reason: 'Use ZodiannLogo.\n${assetHits.join('\n')}',
    );
  });

  test('scans shared_ui and the app, including zodiann_logo.dart', () {
    expect(scanned, contains(_logoFile));
    expect(scanned, contains('apps/astro_mobile/lib/src/app.dart'));
  });

  test(
    'positive controls: a literal size and a raw asset name are flagged',
    () {
      expect(
        findLogoSizeViolations('x = ZodiannLogo(size: 24);'),
        hasLength(1),
      );
      expect(
        findLogoSizeViolations(
          'x = const ZodiannLogo(size: ZodiannSize.logoAbout);',
        ),
        isEmpty,
      );
      expect(findLogoSizeViolations('x = const ZodiannLogo();'), isEmpty);
      expect(
        logoAsset.hasMatch(
          "Image.asset('assets/logo/zodiann-logo-on-dark.png')",
        ),
        isTrue,
      );
    },
  );
}
