import 'package:feature_wheel/feature_wheel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

/// A test-only layer that records what the painter hands every layer and
/// draws one mark at longitude 90 (9 o'clock when the pointer is at 0°), the
/// asymmetry the empty grid lacks.
final class OrientationProbeLayer implements WheelLayer {
  final directions = <TextDirection>[];
  final points = <Offset>[];
  final zodiacs = <ZodiacColors>[];
  final glyphStyles = <TextStyle>[];

  @override
  void paint(WheelPaintContext context) {
    directions.add(context.textDirection);
    zodiacs.add(context.zodiac);
    glyphStyles.add(context.glyphStyle);
    final point = context.geometry.offsetOf(
      90,
      1,
      pointerLongitude: context.pointerLongitude,
    );
    points.add(point);
    context.canvas.drawCircle(point, 4, Paint());
  }
}

/// The wheel canvas's own [CustomPaint].
Finder wheelPaint() => find.descendant(
  of: find.byType(WheelCanvas),
  matching: find.byWidgetPredicate(
    (w) => w is CustomPaint && w.painter is WheelPainter,
  ),
);

/// The wheel canvas's render object, for the `paints` matcher.
RenderBox wheelRenderObject(WidgetTester tester) =>
    tester.renderObject<RenderBox>(wheelPaint());

/// Mounts a [WheelCanvas] in a themed app, in a box of [size] (or inside
/// [wrap]'s own constraints when given).
///
/// The app registers the Zodiann and Material delegates, so `Locale('he')`
/// really resolves to RTL (without delegates the locale falls back to
/// English and the ambient direction stays LTR).
Future<void> pumpWheelCanvas(
  WidgetTester tester, {
  Size size = const Size(644, 656),
  WheelProportions proportions = WheelProportions.desktop,
  WheelState state = const WheelState(),
  List<WheelLayer> layers = const [SignRingLayer()],
  Locale locale = const Locale('en'),
  Brightness brightness = Brightness.dark,
  Widget Function(Widget canvas)? wrap,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1600, 1600);
  addTearDown(tester.view.reset);
  final canvas = WheelCanvas(
    proportions: proportions,
    state: state,
    layers: layers,
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: ZodiannTheme.porcelain,
      darkTheme: ZodiannTheme.graphite,
      themeMode: brightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      locale: locale,
      localizationsDelegates: const [
        ZodiannLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: ZodiannLocalizations.supportedLocales,
      home: Align(
        alignment: Alignment.topLeft,
        child: wrap != null
            ? wrap(canvas)
            : SizedBox(width: size.width, height: size.height, child: canvas),
      ),
    ),
  );
}
