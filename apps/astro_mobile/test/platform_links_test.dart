// ZOD-NAV-003: the OS knows the `zodiann://` link scheme (NAV-5, P2).
// Android registers it with one BROWSABLE intent filter on MainActivity; iOS
// declares it as a URL type. The app is offline, so the filter must not pull
// in the internet permission (the root no_network_test.dart guards the same).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  group('Android manifest', () {
    final manifest = _read('android/app/src/main/AndroidManifest.xml');
    final filters = RegExp(
      r'<intent-filter[^>]*>(.*?)</intent-filter>',
      dotAll: true,
    ).allMatches(manifest).map((m) => m.group(1)!).toList();

    // ZOD-L10-002 (decision D7): the saved language, and later every setting,
    // stays on the device (DATA-5, DATA-6). Android Auto Backup is on unless
    // the attribute says otherwise, and would upload it to the Google backup.
    test('turns Android Auto Backup off', () {
      expect(
        RegExp(r'<application[^>]*android:allowBackup="false"')
            .hasMatch(manifest),
        isTrue,
        reason: '<application android:allowBackup="false">',
      );
      expect(manifest, isNot(contains('android:fullBackupContent')));
      expect(manifest, isNot(contains('android:dataExtractionRules')));
    });

    test('has exactly one BROWSABLE intent filter, for the zodiann scheme', () {
      final browsable = [
        for (final f in filters)
          if (f.contains('android.intent.category.BROWSABLE')) f,
      ];
      expect(browsable, hasLength(1));
      final filter = browsable.single;
      expect(filter, contains('android.intent.action.VIEW'));
      expect(filter, contains('android.intent.category.DEFAULT'));
      expect(
        RegExp(r'android:scheme="([^"]*)"').allMatches(filter).map((m) => m[1]),
        ['zodiann'],
        reason: 'no http, https or other scheme',
      );
    });

    test('the launcher filter is still there', () {
      expect(
        filters.where((f) => f.contains('android.intent.action.MAIN')),
        hasLength(1),
      );
    });

    test('adds no internet permission', () {
      expect(manifest, isNot(contains('android.permission.INTERNET')));
    });

    test('does not turn Flutter deep linking off', () {
      expect(
        RegExp(r'flutter_deeplinking_enabled"\s*android:value="false"')
            .hasMatch(manifest),
        isFalse,
      );
    });
  });

  group('iOS Info.plist', () {
    final plist = _read('ios/Runner/Info.plist');

    test('declares the zodiann URL type', () {
      // From the key to the next top-level key (one tab of indentation), so
      // the nested arrays stay inside the slice.
      final types = RegExp(
        r'<key>CFBundleURLTypes</key>(.*?)(?:\r?\n\t<key>|\r?\n</dict>)',
        dotAll: true,
      ).firstMatch(plist);
      expect(types, isNotNull, reason: 'CFBundleURLTypes is missing');
      final body = types!.group(1)!;
      expect(
        RegExp(
          r'<key>CFBundleURLName</key>\s*<string>com\.zodiann\.app</string>',
        ).hasMatch(body),
        isTrue,
      );
      expect(
        RegExp(
          r'<key>CFBundleURLSchemes</key>\s*<array>\s*<string>zodiann</string>\s*</array>',
        ).hasMatch(body),
        isTrue,
      );
    });

    test('does not turn Flutter deep linking off', () {
      expect(
        RegExp(r'<key>FlutterDeepLinkingEnabled</key>\s*<false\s*/>')
            .hasMatch(plist),
        isFalse,
      );
    });
  });
}
