// ZOD-FND-008: the in-app logo mark.
import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/tokens/zodiann_dimensions.dart';

const _package = 'shared_ui';
const _onDark = 'assets/logo/zodiann-logo-on-dark.png';
const _onLight = 'assets/logo/zodiann-logo-on-light.png';

/// The Zodiann logo (MASTER §11): the 1024 px PNG without its tile, in the
/// variant that suits the app's theme, so a theme switch changes it live.
///
/// It is [size] square and never smaller than [ZodiannSize.logoMin]: a size
/// below the minimum asserts, and in debug a parent whose constraints would
/// squeeze it below [size] reports a [FlutterError]. Pass a token
/// ([ZodiannSize.logoDrawer], [ZodiannSize.logoAbout]).
///
/// The mark is decoded at `size × devicePixelRatio` (not the full 1024 px):
/// measured against Chrome's render of the SVG it keeps the hairlines and is
/// closer than a full decode (plan Task 2 calibration).
///
/// The logo sits beside the wordmark, so it is decorative (excluded from
/// semantics) unless [semanticLabel] is given; a caller passes a localized
/// string.
class ZodiannLogo extends StatelessWidget {
  const ZodiannLogo({
    super.key,
    this.size = ZodiannSize.logoDrawer,
    this.semanticLabel,
  }) : assert(
         size >= ZodiannSize.logoMin,
         'The logo is never rendered below ZodiannSize.logoMin.',
       );

  /// Width and height.
  final double size;

  /// The semantics label; null makes the logo decorative.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0;
    return _LogoBox(
      size: size,
      child: Image.asset(
        dark ? _onDark : _onLight,
        package: _package,
        cacheWidth: (size * dpr).round(),
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
        excludeFromSemantics: semanticLabel == null,
        semanticLabel: semanticLabel,
      ),
    );
  }
}

/// Sizes its child to exactly [size] (so intrinsics report [size]), and in
/// debug reports a parent that would squeeze it below that.
class _LogoBox extends SingleChildRenderObjectWidget {
  const _LogoBox({required this.size, super.child});

  final double size;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderLogoBox(size);

  @override
  void updateRenderObject(BuildContext context, _RenderLogoBox renderObject) {
    renderObject.logoSize = size;
  }
}

class _RenderLogoBox extends RenderConstrainedBox {
  _RenderLogoBox(double logoSize)
    : _logoSize = logoSize,
      super(
        additionalConstraints: BoxConstraints.tightFor(
          width: logoSize,
          height: logoSize,
        ),
      );

  double _logoSize;

  set logoSize(double value) {
    if (value == _logoSize) return;
    _logoSize = value;
    additionalConstraints = BoxConstraints.tightFor(
      width: value,
      height: value,
    );
  }

  @override
  void performLayout() {
    assert(() {
      if (constraints.maxWidth < _logoSize ||
          constraints.maxHeight < _logoSize) {
        // Reported, not thrown: a throw inside performLayout leaves the
        // parents without a size and cascades into unrelated errors.
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: FlutterError(
              'ZodiannLogo of size $_logoSize was given constraints '
              '${constraints.maxWidth} x ${constraints.maxHeight}, which '
              'would render it smaller than its size. The logo is never '
              'rendered below ZodiannSize.logoMin (MASTER §11).',
            ),
            library: 'zodiann_logo',
          ),
        );
      }
      return true;
    }());
    super.performLayout();
  }
}
