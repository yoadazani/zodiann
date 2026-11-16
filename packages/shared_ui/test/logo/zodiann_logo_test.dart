// ZOD-FND-008: ZodiannLogo picks its mark from the app theme, lays out at its
// size, and never renders below ZodiannSize.logoMin.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_ui/shared_ui.dart';

const _dark = 'assets/logo/zodiann-logo-on-dark.png';
const _light = 'assets/logo/zodiann-logo-on-light.png';

Widget _app(Widget child, {ThemeMode mode = ThemeMode.light}) => MaterialApp(
  theme: ZodiannTheme.porcelain,
  darkTheme: ZodiannTheme.graphite,
  themeMode: mode,
  home: Scaffold(body: Center(child: child)),
);

AssetImage _asset(WidgetTester tester) =>
    tester.widget<Image>(find.byType(Image)).image as AssetImage;

void main() {
  testWidgets('uses the dark mark under the dark theme', (tester) async {
    await tester.pumpWidget(_app(const ZodiannLogo(), mode: ThemeMode.dark));
    expect(_asset(tester).assetName, _dark);
    expect(_asset(tester).package, 'shared_ui');
  });

  testWidgets('uses the light mark under the light theme', (tester) async {
    await tester.pumpWidget(_app(const ZodiannLogo()));
    expect(_asset(tester).assetName, _light);
  });

  testWidgets('follows the app theme, not the platform brightness', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(_app(const ZodiannLogo()));
    expect(_asset(tester).assetName, _light);
  });

  testWidgets('switches live when the theme changes', (tester) async {
    await tester.pumpWidget(_app(const ZodiannLogo()));
    expect(_asset(tester).assetName, _light);
    await tester.pumpWidget(_app(const ZodiannLogo(), mode: ThemeMode.dark));
    await tester.pumpAndSettle();
    expect(_asset(tester).assetName, _dark);
    await tester.pumpWidget(_app(const ZodiannLogo()));
    await tester.pumpAndSettle();
    expect(_asset(tester).assetName, _light);
  });

  testWidgets('drawer size 40 and About size 132 lay out exactly square', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const ZodiannLogo()));
    expect(tester.getSize(find.byType(ZodiannLogo)), const Size.square(40));
    await tester.pumpWidget(
      _app(const ZodiannLogo(size: ZodiannSize.logoAbout)),
    );
    expect(tester.getSize(find.byType(ZodiannLogo)), const Size.square(132));
  });

  test('size below ZodiannSize.logoMin throws an AssertionError', () {
    final tooSmall = ZodiannSize.logoMin - 16;
    expect(() => ZodiannLogo(size: tooSmall), throwsAssertionError);
  });

  testWidgets('a parent that forces it below its size is reported', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const SizedBox(width: 24, height: 24, child: ZodiannLogo())),
    );
    final error = tester.takeException();
    expect(error, isA<FlutterError>());
    expect(error.toString(), contains('ZodiannSize.logoMin'));
  });

  testWidgets('a larger tight parent is not reported', (tester) async {
    await tester.pumpWidget(
      _app(
        const SizedBox.square(
          dimension: ZodiannSize.logoAbout,
          child: ZodiannLogo(),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('lays out under an IntrinsicHeight ancestor', (tester) async {
    await tester.pumpWidget(
      _app(const IntrinsicHeight(child: Row(children: [ZodiannLogo()]))),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(ZodiannLogo)).height, 40);
  });

  testWidgets('is excluded from semantics without a label and exposes it '
      'with one', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_app(const ZodiannLogo()));
    expect(tester.widget<Image>(find.byType(Image)).excludeFromSemantics, true);
    expect(find.bySemanticsLabel('Zodiann logo'), findsNothing);
    await tester.pumpWidget(
      _app(const ZodiannLogo(semanticLabel: 'Zodiann logo')),
    );
    expect(find.bySemanticsLabel('Zodiann logo'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('renders the bundled mark through the package key', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const ZodiannLogo()));
    final provider = tester.widget<Image>(find.byType(Image)).image;
    await tester.runAsync(
      () => precacheImage(provider, tester.element(find.byType(Image))),
    );
    await tester.pump();
    final raw = tester.widget<RawImage>(find.byType(RawImage));
    expect(raw.image, isNotNull);
    expect((raw.image!.width, raw.image!.height), (1024, 1024));
  });
}
