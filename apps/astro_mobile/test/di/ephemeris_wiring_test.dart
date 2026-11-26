// ZOD-EPH-002: which position source startup binds. The primary source is
// Swiss Ephemeris; the astronomy-engine backup is chosen only if the Swiss
// library does not load; otherwise positions are unavailable. Whatever
// happens, the bound port is behind the supported date range and startup never
// throws.
import 'dart:io';
import 'dart:ui';

import 'package:astro_core/astro_core.dart';
import 'package:astro_mobile/src/bootstrap.dart';
import 'package:astro_mobile/src/di/ephemeris_providers.dart';
import 'package:astro_mobile/src/di/ephemeris_wiring.dart';
import 'package:astro_mobile/src/ephemeris/ephemeris_status.dart';
import 'package:astro_mobile/src/localization/app_locale_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../localization/support/memory_settings_store.dart';
import 'support/fake_ephemeris_dependencies.dart';

/// A failed native resolution throws an [Error]; a platform call or the file
/// system throws an [Exception]. Both must be survived.
final _failures = <String, Object>{
  'an Error': ArgumentError('no native function'),
  'an Exception': const FileSystemException('no directory'),
};

void main() {
  final utc = DateTime.utc(2000);

  /// Runs startup selection and checks what every outcome must satisfy.
  Future<ProviderContainer> bind(
    FakeEphemerisDependencies fake,
    ActiveEphemerisSource expected,
  ) async {
    final container = ProviderContainer.test(
      overrides: await ephemerisOverrides(fake.dependencies),
    );
    expect(container.read(ephemerisStatusProvider).source, expected);
    final port = container.read(ephemerisPortProvider);
    expect(port, isA<SupportedRangeEphemeris>());
    expect(
      port.position(Body.sun, DateTime.utc(1899, 6, 1)),
      isA<OutsideSupportedRange>(),
    );
    final sun = port.position(Body.sun, utc);
    switch (expected) {
      case ActiveEphemerisSource.primary:
        expect(
          (sun as EphemerisSuccess).position.longitude,
          fakeSwissLongitude,
        );
      case ActiveEphemerisSource.backup:
        expect(
          (sun as EphemerisSuccess).position.longitude,
          fakeBackupLongitude,
        );
      case ActiveEphemerisSource.none:
        expect(sun, isA<OutOfCoveredRange>());
    }
    return container;
  }

  group('the Swiss library loads', () {
    test('with the data installed the primary source is bound, and the backup '
        'is not probed', () async {
      final fake = FakeEphemerisDependencies(swiss: true, backup: true);

      await bind(fake, ActiveEphemerisSource.primary);

      expect(fake.openedDirectories, ['/fake/ephe']);
      expect(fake.preparations, 1);
      expect(fake.backupProbes, 0);
      expect(fake.backupOpens, 0);
    });

    test('with no installed data nothing is opened and there is no switch to '
        'the backup', () async {
      final fake = FakeEphemerisDependencies(
        swiss: true,
        backup: true,
        directory: null,
      );

      await bind(fake, ActiveEphemerisSource.none);

      expect(fake.openedDirectories, isEmpty);
      expect(fake.backupProbes, 0);
    });

    _failures.forEach((name, failure) {
      test('preparing the data throws $name', () async {
        final fake = FakeEphemerisDependencies(
          swiss: true,
          backup: true,
          prepareError: failure,
        );

        await bind(fake, ActiveEphemerisSource.none);

        expect(fake.openedDirectories, isEmpty);
        expect(fake.backupProbes, 0);
      });

      test('opening the source throws $name', () async {
        final fake = FakeEphemerisDependencies(
          swiss: true,
          backup: true,
          openSwissError: failure,
        );

        await bind(fake, ActiveEphemerisSource.none);

        expect(fake.backupProbes, 0);
      });
    });
  });

  group('the Swiss library does not load', () {
    for (final (name, probeError) in <(String, Object?)>[
      ('the probe says no', null),
      ('the probe throws', ArgumentError('no native function')),
    ]) {
      test('$name: the backup is bound and the data is not prepared', () async {
        final fake = FakeEphemerisDependencies(
          backup: true,
          swissProbeError: probeError,
        );

        await bind(fake, ActiveEphemerisSource.backup);

        expect(fake.preparations, 0);
        expect(fake.openedDirectories, isEmpty);
        expect(fake.backupOpens, 1);
      });
    }

    test('nor does the backup: unavailable', () async {
      final fake = FakeEphemerisDependencies();

      await bind(fake, ActiveEphemerisSource.none);

      expect(fake.preparations, 0);
      expect(fake.backupOpens, 0);
    });

    test('and the backup probe throws: unavailable', () async {
      await bind(
        FakeEphemerisDependencies(
          backupProbeError: ArgumentError('no native function'),
        ),
        ActiveEphemerisSource.none,
      );
    });

    _failures.forEach((name, failure) {
      test('and opening the backup throws $name: unavailable', () async {
        await bind(
          FakeEphemerisDependencies(backup: true, openBackupError: failure),
          ActiveEphemerisSource.none,
        );
      });
    });
  });

  test('on the host, where no native library is built, the production probes '
      'throw and the data is never prepared', () async {
    final production = productionEphemerisDependencies();
    expect(production.swissLoads, throwsA(anything));
    expect(production.backupLoads, throwsA(anything));
    var preparations = 0;

    final container = ProviderContainer.test(
      overrides: await ephemerisOverrides(
        EphemerisDependencies(
          swissLoads: production.swissLoads,
          prepareSwissData: () async {
            preparations++;
            return null;
          },
          openSwissSource: production.openSwissSource,
          backupLoads: production.backupLoads,
          openBackupSource: production.openBackupSource,
        ),
      ),
    );

    expect(
      container.read(ephemerisStatusProvider).source,
      ActiveEphemerisSource.none,
    );
    expect(preparations, 0);
  });

  _failures.forEach((name, failure) {
    test('startup still resolves the language when every dependency throws '
        '$name', () async {
      final fake = FakeEphemerisDependencies(
        swissProbeError: failure,
        prepareError: failure,
        openSwissError: failure,
        backupProbeError: failure,
        openBackupError: failure,
      );

      final container = ProviderContainer.test(
        overrides: await bootstrapOverrides(
          store: MemorySettingsStore(),
          deviceLocales: const [Locale('he')],
          ephemeris: fake.dependencies,
        ),
      );

      expect(container.read(appLocaleProvider), const Locale('he'));
      expect(
        container.read(ephemerisStatusProvider).source,
        ActiveEphemerisSource.none,
      );
    });
  });
}
