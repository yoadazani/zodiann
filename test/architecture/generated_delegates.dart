// ZOD-L10-001: finds uses of the generated delegate list, for
// no_generated_delegates_test.dart.

import 'dart_source.dart';

final _use = RegExp(r'\bZodiannLocalizations\s*\.\s*localizationsDelegates\b');

/// The 1-based lines of every `ZodiannLocalizations.localizationsDelegates`
/// in [source], comments and strings excluded.
List<int> findGeneratedDelegateUses(String source) => [
  for (final m in _use.allMatches(cleanDartSource(source)))
    '\n'.allMatches(source.substring(0, m.start)).length + 1,
];
