import 'package:astro_core/astro_core.dart';
import 'package:astro_mobile/src/di/app_overrides.dart';
import 'package:astro_mobile/src/di/ephemeris_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderException;
import 'package:flutter_test/flutter_test.dart';

/// Identity is all these tests check; every member is unused.
class _FakePort implements EphemerisPort {
  @override
  UtcRange get coveredRange => throw UnimplementedError();

  @override
  EphemerisResult position(Body body, DateTime utc) =>
      throw UnimplementedError();

  @override
  EclipticPosition meanAscendingNode(DateTime utc) =>
      throw UnimplementedError();
}

void main() {
  test('unbound ephemerisPortProvider throws a StateError naming '
      'bootstrapOverrides', () {
    final container = ProviderContainer.test();
    expect(
      () => container.read(ephemerisPortProvider),
      throwsA(
        isA<ProviderException>().having(
          (e) => e.exception,
          'exception',
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('bootstrapOverrides'),
          ),
        ),
      ),
    );
  });

  test('one override binds the port', () {
    final fake = _FakePort();
    final container = ProviderContainer.test(
      overrides: [ephemerisPortProvider.overrideWithValue(fake)],
    );
    expect(container.read(ephemerisPortProvider), same(fake));
  });

  test('unbound ephemerisStatusProvider throws too', () {
    final container = ProviderContainer.test();
    expect(
      () => container.read(ephemerisStatusProvider),
      throwsA(isA<ProviderException>()),
    );
  });

  test('the port is bound at bootstrap, not in appOverrides', () {
    // The source depends on startup results (ZOD-EPH-002), so
    // bootstrapOverrides binds it; see ephemeris_wiring_test.dart.
    expect(appOverrides, isEmpty);
  });
}
