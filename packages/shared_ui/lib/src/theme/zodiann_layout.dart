import 'package:material_ui/material_ui.dart';

import 'tokens/zodiann_dimensions.dart';

/// The layout class for a width (MASTER §6): phone below
/// [ZodiannBreakpoints.tablet], tablet below [ZodiannBreakpoints.desktop],
/// desktop from there up.
///
/// This is the resolved class; [ZodiannBreakpoints] holds the width
/// constants it is resolved from.
enum ZodiannBreakpoint {
  /// Below 700.
  phone,

  /// 700 to 1099.
  tablet,

  /// 1100 and up.
  desktop;

  /// The class of a logical-pixel width.
  static ZodiannBreakpoint forWidth(double logicalWidth) {
    if (logicalWidth < ZodiannBreakpoints.tablet) return phone;
    if (logicalWidth < ZodiannBreakpoints.desktop) return tablet;
    return desktop;
  }
}

/// MASTER §4's breakpoint-dependent layout values (ZOD-UI-003).
///
/// MASTER gives tablet and desktop the same values, so there are two
/// layouts: [phone] and [regular].
@immutable
final class ZodiannLayout {
  /// A layout with explicit values.
  const ZodiannLayout({
    required this.gutter,
    required this.panelGap,
    required this.panelPadding,
    required this.panelHeadHeight,
  });

  /// Space between the content and the screen edge.
  final double gutter;

  /// Space between neighbouring panels.
  final double panelGap;

  /// Space inside a panel's 1 px border, before its content.
  final double panelPadding;

  /// Panel head height, including its 1 px bottom rule.
  final double panelHeadHeight;

  /// Phone: gutter 16, panel gap 16, panel padding 16, panel head 52.
  static const ZodiannLayout phone = ZodiannLayout(
    gutter: ZodiannSpace.s4,
    panelGap: ZodiannSpace.s4,
    panelPadding: ZodiannSpace.s4,
    panelHeadHeight: ZodiannSize.panelHeadPhone,
  );

  /// Tablet and desktop: gutter 24, panel gap 20, panel padding 20, panel
  /// head 56.
  static const ZodiannLayout regular = ZodiannLayout(
    gutter: ZodiannSpace.s6,
    panelGap: ZodiannSpace.s5,
    panelPadding: ZodiannSpace.s5,
    panelHeadHeight: ZodiannSize.panelHead,
  );

  /// The layout for a logical-pixel width.
  static ZodiannLayout forWidth(double logicalWidth) =>
      ZodiannBreakpoint.forWidth(logicalWidth) == ZodiannBreakpoint.phone
      ? phone
      : regular;

  /// The layout for the current screen width.
  static ZodiannLayout of(BuildContext context) =>
      forWidth(MediaQuery.sizeOf(context).width);

  @override
  bool operator ==(Object other) =>
      other is ZodiannLayout &&
      other.gutter == gutter &&
      other.panelGap == panelGap &&
      other.panelPadding == panelPadding &&
      other.panelHeadHeight == panelHeadHeight;

  @override
  int get hashCode =>
      Object.hash(gutter, panelGap, panelPadding, panelHeadHeight);

  @override
  String toString() =>
      'ZodiannLayout(gutter: $gutter, panelGap: $panelGap, '
      'panelPadding: $panelPadding, panelHeadHeight: $panelHeadHeight)';
}
