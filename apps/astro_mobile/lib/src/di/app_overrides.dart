import 'package:flutter_riverpod/misc.dart' show Override;

/// The DI bindings that need no startup work (ARCH-4). `bootstrapOverrides`
/// includes them in the root `ProviderScope`.
///
/// A binding that depends on something resolved at startup is made there
/// instead: the position source is chosen and bound by `ephemerisOverrides`
/// (`ephemeris_wiring.dart`, ZOD-EPH-002).
///
/// Deliberately not a `const` literal: `ProviderScope`'s default `overrides`
/// is `const <Override>[]`, and a const list here would be the same canonical
/// object, hiding a `main()` that forgets to pass `appOverrides`.
final List<Override> appOverrides = List<Override>.unmodifiable(
  const <Override>[],
);
