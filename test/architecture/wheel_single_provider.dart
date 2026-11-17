// The ZOD-WHL-001 scanner behind wheel_single_provider_test.dart (ARCH-3).
//
// It counts SCREEN-STATE providers. A dependency-injection provider (for
// example the EphemerisPort binding, FND-005 Notes) needs an explicit
// decision and a named allowlist entry here.

import 'dart_source.dart';

/// A provider constructor call: an identifier ending in `Provider` at a word
/// start (`Provider(`, `NotifierProvider<A, B>(`, `NotifierProvider.autoDispose(`),
/// optionally with type arguments. Lowercase provider variables,
/// `ProviderScope`, `ProviderContainer` and `ProviderObserver` never match.
final _providerCtor = RegExp(
  r'\b(?:[A-Z]\w*)?Provider\b(?:\s*\.\s*\w+)*\s*(?:<[^;{}()]*>)?\s*\(',
);

final _codegen = RegExp(r'@[Rr]iverpod\b');

/// How many provider declarations [source] holds (code generation counts).
int countProviderDeclarations(String source) {
  final code = cleanDartSource(source);
  return _providerCtor.allMatches(code).length +
      _codegen.allMatches(code).length;
}

/// How many `ProviderScope(` / `ProviderContainer(` constructions [source] has.
int countScopes(String source) =>
    RegExp(r'\bProvider(?:Scope|Container)\s*\(')
        .allMatches(cleanDartSource(source))
        .length;

/// Whether [source] mentions riverpod (an import or a `ref.` use).
bool mentionsRiverpod(String source) {
  // Imports are read from the raw text: cleanDartSource blanks string
  // contents, import URIs included.
  final imports = RegExp(r'''import\s+['"][^'"]*riverpod''').hasMatch(source);
  return imports || RegExp(r'\bref\.').hasMatch(cleanDartSource(source));
}
