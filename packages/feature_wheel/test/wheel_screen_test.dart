import 'dart:io';
import 'dart:ui' as ui;

import 'package:feature_wheel/feature_wheel.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

import 'support/wheel_harness.dart';

final class CountingObserver extends ProviderObserver {
  final added = <Object>[];

  @override
  void didAddProvider(ProviderObserverContext context, Object? value) {
    added.add(context.provider);
  }
}

Future<void> pumpWheelScreen(
  WidgetTester tester, {
  Size size = const Size(1200, 1000),
  Brightness brightness = Brightness.dark,
  CountingObserver? observer,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      observers: [?observer],
      child: MaterialApp(
        theme: ZodiannTheme.porcelain,
        darkTheme: ZodiannTheme.graphite,
        themeMode: brightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light,
        home: const WheelScreen(),
      ),
    ),
  );
}

WheelPainter painterOf(WidgetTester tester) =>
    tester.widget<CustomPaint>(wheelPaint()).painter! as WheelPainter;

void main() {
  testWidgets('ARCH-3: one provider, and no scope of its own', (tester) async {
    final observer = CountingObserver();
    await pumpWheelScreen(tester, observer: observer);
    expect(observer.added, [wheelStateProvider]);
    expect(find.byType(ProviderScope), findsOneWidget);
  });

  testWidgets('the state reaches the painter, and only the state', (
    tester,
  ) async {
    await pumpWheelScreen(tester);
    final proportions = painterOf(tester).proportions;
    final container = ProviderScope.containerOf(
      tester.element(find.byType(WheelScreen)),
    );
    container.read(wheelStateProvider.notifier).setPointerLongitude(42);
    await tester.pump();
    final painter = painterOf(tester);
    expect(painter.state, const WheelState(pointerLongitude: 42));
    expect(painter.proportions, proportions);
  });

  testWidgets('1100 and wider uses the desktop table, narrower the compact', (
    tester,
  ) async {
    await pumpWheelScreen(tester, size: const Size(1100, 1000));
    expect(painterOf(tester).proportions, WheelProportions.desktop);
    await pumpWheelScreen(tester, size: const Size(1099, 1000));
    expect(painterOf(tester).proportions, WheelProportions.compact);
  });

  testWidgets('resizing across 1100 keeps the state and repaints', (
    tester,
  ) async {
    await pumpWheelScreen(tester, size: const Size(1200, 1000));
    ProviderScope.containerOf(tester.element(find.byType(WheelScreen)))
        .read(wheelStateProvider.notifier)
        .setPointerLongitude(42);
    await tester.pump();
    tester.view.physicalSize = const Size(800, 1000);
    await tester.pump();
    expect(painterOf(tester).proportions, WheelProportions.compact);
    expect(painterOf(tester).state.pointerLongitude, 42);
    // The compact band is at 240/300 of R, narrower than the desktop 250/300.
    expect(
      tester.renderObject<RenderBox>(wheelPaint()),
      paints..something((method, args) {
        if (method != #drawCircle) return false;
        final r = tester.getSize(wheelPaint());
        final radius = (r.width / (2 * 322 / 300)) < (r.height / (656 / 300))
            ? r.width / (2 * 322 / 300)
            : r.height / (656 / 300);
        return ((args[1] as double) - radius * 240 / 300).abs() < 1e-6;
      }),
    );
  });

  testWidgets('switching dark to light repaints with the light colours', (
    tester,
  ) async {
    await pumpWheelScreen(tester);
    final dark = painterOf(tester).surfaces.line;
    await pumpWheelScreen(tester, brightness: Brightness.light);
    await tester.pumpAndSettle();
    expect(painterOf(tester).surfaces.line, isNot(dark));
  });

  // A visual check, not an assertion: set WHEEL_PNG_DIR to write the grids.
  final dir = Platform.environment['WHEEL_PNG_DIR'];
  for (final (name, size) in [
    ('desktop', const Size(1200, 1000)),
    ('compact', const Size(700, 760)),
  ]) {
    for (final brightness in Brightness.values) {
      testWidgets('render check: $name ${brightness.name}', skip: dir == null, (
        tester,
      ) async {
        await pumpWheelScreen(tester, size: size, brightness: brightness);
        await tester.runAsync(() async {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find
                .descendant(
                  of: find.byType(WheelCanvas),
                  matching: find.byType(RepaintBoundary),
                )
                .first,
          );
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File('$dir/wheel_grid_${name}_${brightness.name}.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      });
    }
  }
}
