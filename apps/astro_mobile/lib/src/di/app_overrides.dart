import 'package:flutter_riverpod/misc.dart' show Override;

/// The DI wiring: the single place that binds sources for the running app
/// (ARCH-4). `main()` passes it to the root `ProviderScope`.
///
/// The task that first ships a real adapter into the app adds its binding
/// here, e.g. `ephemerisPortProvider.overrideWithValue(...)`.
///
/// Deliberately not a `const` literal: `ProviderScope`'s default `overrides`
/// is `const <Override>[]`, and a const list here would be the same canonical
/// object, hiding a `main()` that forgets to pass `appOverrides`.
final List<Override> appOverrides = List<Override>.unmodifiable(
  const <Override>[],
);
