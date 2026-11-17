import 'package:feature_wheel/feature_wheel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ProviderContainer make() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  double read(ProviderContainer c) =>
      c.read(wheelStateProvider).pointerLongitude;

  void set(ProviderContainer c, double v) =>
      c.read(wheelStateProvider.notifier).setPointerLongitude(v);

  test('the pointer starts at 0°', () {
    expect(read(make()), 0);
  });

  test('longitudes are normalised into [0, 360)', () {
    final c = make();
    set(c, -10);
    expect(read(c), 350);
    set(c, 360);
    expect(read(c), 0);
    set(c, 725);
    expect(read(c), 5);
    set(c, -1e-15);
    expect(read(c), 0, reason: 'never 360');
  });

  test('a change notifies, the same value does not', () {
    final c = make();
    var notified = 0;
    c.listen(wheelStateProvider, (_, _) => notified++);
    set(c, 42);
    expect(notified, 1);
    set(c, 42);
    expect(notified, 1);
    set(c, 402);
    expect(notified, 1, reason: '402 normalises to 42');
  });

  test('NaN and infinity throw and leave the state unchanged', () {
    final c = make();
    set(c, 42);
    expect(() => set(c, double.nan), throwsArgumentError);
    expect(() => set(c, double.infinity), throwsArgumentError);
    expect(read(c), 42);
  });

  test('WheelState has value equality', () {
    expect(
      const WheelState(pointerLongitude: 3),
      const WheelState(pointerLongitude: 3),
    );
    expect(
      const WheelState(pointerLongitude: 3).hashCode,
      const WheelState(pointerLongitude: 3).hashCode,
    );
    expect(const WheelState(pointerLongitude: 3), isNot(const WheelState()));
  });
}
