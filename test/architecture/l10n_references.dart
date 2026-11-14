// The ZOD-L10-007 localization-reference scanner used by
// no_l10n_in_core_test.dart.

import 'dart_source.dart';

/// Storage and computation packages: they hold and compute keys only and
/// never reach localization (L-9). Add new persistence or core packages here.
const keyOnlyPackages = [
  'astro_core',
  'gann_core',
  'ephemeris_swiss',
  'ephemeris_astronomy',
  'shared_storage',
];

final _statement = RegExp(r'^\s*(import|export)\s[^;]*;', multiLine: true);
final _forbiddenUri = RegExp('[\'"]package:(shared_ui|flutter_localizations)/');
final _localizations = RegExp(r'\bZodiannLocalizations\b');

/// Every import or export statement in [source] naming `shared_ui` or
/// `flutter_localizations` (conditional alternatives, either quote, any line
/// breaks), and every `ZodiannLocalizations` mention outside comments and
/// strings.
///
/// Statements are found in the cleaned source (comments removed, string
/// contents blanked, same length) and read back from [source] at the same
/// offsets, so a commented-out import is skipped while the URI stays
/// readable.
List<String> l10nReferences(String source) {
  final clean = cleanDartSource(source);
  return [
    for (final m in _statement.allMatches(clean))
      if (_forbiddenUri.hasMatch(source.substring(m.start, m.end)))
        source.substring(m.start, m.end).trim(),
    for (final m in _localizations.allMatches(clean)) m.group(0)!,
  ];
}
