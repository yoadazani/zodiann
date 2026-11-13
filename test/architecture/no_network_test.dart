// ZOD-FND-007 (DATA-7, DATA-8): the release app declares no network
// permission, no workspace member depends on a network package at runtime,
// and no lib/ source opens a connection or fetches fonts. A standing
// regression guard; the full privacy audit and traffic capture are
// ZOD-DAT-011's. Runs from the workspace root on every `melos run test`.
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'dependency_closure.dart';

const _app = 'apps/astro_mobile';

/// Packages whose purpose is a network connection, or that fetch fonts,
/// assets or telemetry at runtime.
const networkPackages = {
  'http',
  'dio',
  'google_fonts',
  'web_socket',
  'web_socket_channel',
  'http2',
  'grpc',
  'cronet_http',
  'cupertino_http',
  'firebase_core',
  'sentry',
  'sentry_flutter',
  'cached_network_image',
  'flutter_cache_manager',
};

const _networkPermissions = [
  'android.permission.INTERNET',
  'android.permission.ACCESS_NETWORK_STATE',
  'android.permission.ACCESS_WIFI_STATE',
  'android.permission.CHANGE_NETWORK_STATE',
];

const _iosNetworkKeys = [
  'NSAppTransportSecurity',
  'NSAllowsArbitraryLoads',
  'NSLocalNetworkUsageDescription',
  'NSBonjourServices',
];

final _networkApis = [
  RegExp(r'\bHttpClient\b'),
  RegExp(r'\bHttpServer\b'),
  RegExp(r'\bWebSocket\b'),
  RegExp(r'\bRawDatagramSocket\b'),
  RegExp(r'\b\w*Socket\.(connect|startConnect|bind)\('),
  RegExp(r'\bNetworkImage\('),
  RegExp(r'\bImage\.network\('),
  RegExp(r'\bNetworkAssetBundle\('),
  RegExp(r'''['"]package:(http|google_fonts)/'''),
];

Iterable<File> _dartFiles(String dir) =>
    Directory(dir)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

void main() {
  test(
    'DATA-7: the release Android manifest declares no network permission',
    () {
      // Criterion 3 applies to the release manifest (product-owner decision,
      // 2026-11-13). src/debug and src/profile keep Flutter's tooling-only
      // INTERNET for hot reload and DevTools; the merged release APK is checked
      // with `aapt2 dump permissions` (see docs/PROGRESS.md).
      final manifest = File('$_app/android/app/src/main/AndroidManifest.xml')
          .readAsStringSync();
      final permissions = RegExp(r'<uses-permission[^>]*android:name="([^"]+)"')
          .allMatches(manifest)
          .map((m) => m.group(1)!);
      expect(permissions.where(_networkPermissions.contains), isEmpty);
    },
  );

  test('DATA-7: iOS declares no network capability', () {
    final entitlements = Directory('$_app/ios')
        .listSync(recursive: true)
        .where((e) => e.path.endsWith('.entitlements'))
        .map((e) => e.path);
    expect(entitlements, isEmpty);
    final plist = File('$_app/ios/Runner/Info.plist').readAsStringSync();
    expect(_iosNetworkKeys.where(plist.contains), isEmpty);
  });

  group('DATA-8', () {
    late Map<String, Object?> deps;

    setUpAll(() {
      final result = Process.runSync(Platform.resolvedExecutable, [
        'pub',
        'deps',
        '--json',
      ]);
      expect(result.exitCode, 0, reason: '${result.stderr}');
      deps = jsonDecode(result.stdout as String) as Map<String, Object?>;
    });

    test('no workspace member depends on a network package at runtime', () {
      final members = [
        for (final node
            in (deps['packages']! as List<Object?>)
                .cast<Map<String, Object?>>())
          if (node['kind'] == 'root' && node['name'] != deps['root'])
            node['name']! as String,
      ];
      expect(members, hasLength(10));
      for (final member in members) {
        final hits = findForbiddenDependencies(
          deps,
          member,
          forbidden: networkPackages,
          includeDevDependencies: false,
        );
        expect(
          hits,
          isEmpty,
          reason: hits.values.map((p) => p.join(' -> ')).join('\n'),
        );
      }
    });
  });

  test(
    'DATA-8: no lib/ source opens a network connection or fetches fonts',
    () {
      final roots = [
        for (final parent in ['apps', 'packages'])
          for (final dir in Directory(parent).listSync().whereType<Directory>())
            if (Directory('${dir.path}/lib').existsSync()) '${dir.path}/lib',
      ];
      expect(roots, isNotEmpty);
      final hits = <String>[];
      for (final root in roots) {
        for (final file in _dartFiles(root)) {
          final lines = file.readAsLinesSync();
          for (var i = 0; i < lines.length; i++) {
            var code = lines[i];
            final comment = code.indexOf('//');
            if (comment >= 0) code = code.substring(0, comment);
            for (final api in _networkApis) {
              final match = api.firstMatch(code);
              if (match != null) {
                hits.add(
                  '${file.path.replaceAll(r'\', '/')}:${i + 1}: ${match[0]}',
                );
              }
            }
          }
        }
      }
      expect(hits, isEmpty, reason: hits.join('\n'));
    },
  );
}
