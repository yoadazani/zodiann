// ZOD-FND-008: the scanner behind logo_size_guard_test.dart.

import 'dart_source.dart';

final _call = RegExp(r'\bZodiannLogo\s*\(');
final _size = RegExp(r'^size\s*:\s*(.*)$', dotAll: true);

/// The bundled logo marks; only `zodiann_logo.dart` may name them.
final logoAsset = RegExp(r'zodiann-logo-on-(dark|light)\.png');

/// Every `ZodiannLogo(` call in [source] whose `size:` argument is not a
/// `ZodiannSize.logo…` token, as 1-based `line: size: expression`. A call
/// with no `size:` uses the default (`ZodiannSize.logoDrawer`) and is fine.
///
/// The source is cleaned first (comments removed, string contents blanked),
/// and only the call's own top-level argument list is read. The constructor
/// declaration's `({…})` is blanked, so it is never flagged.
List<String> findLogoSizeViolations(String source) {
  final code = cleanDartSource(source);
  final found = <String>[];
  for (final match in _call.allMatches(code)) {
    final top = topLevelArguments(code, match.end - 1);
    if (top == null) continue;
    for (final arg in top.$2.split(',').map((a) => a.trim())) {
      final named = _size.firstMatch(arg);
      if (named == null) continue;
      final value = named.group(1)!.trim();
      if (!value.startsWith('ZodiannSize.logo')) {
        final line = '\n'.allMatches(code.substring(0, match.start)).length + 1;
        found.add('$line: size: $value');
      }
    }
  }
  return found;
}
