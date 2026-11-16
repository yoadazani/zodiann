import 'dart:ui' show ImageFilter;

import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:material_ui/material_ui.dart';

import '../icons/zodiann_icon.dart';
import '../icons/zodiann_icon_data.dart';
import '../icons/zodiann_icons.g.dart';
import '../theme/tokens/zodiann_dimensions.dart';
import '../theme/tokens/zodiann_states.dart';
import '../theme/zodiann_layout.dart';
import '../theme/zodiann_surfaces.dart';
import '../theme/zodiann_text_styles.dart';
import 'zodiann_button.dart';
import 'zodiann_button_colors.dart';
import 'zodiann_icon_button.dart';

/// The bar's backdrop: `bg` at 88 % (kit.css `.topbar`
/// `color-mix(in srgb, var(--bg) 88%, transparent)`).
const double _backdropAlpha = 0.88;

/// The backdrop blur: CSS `blur(10px)` is a Gaussian with σ = 10 px.
const double _blurSigma = 10.0;

/// The bar's text follows the system text size up to 1.5 ×:
/// (21.6 + 17.4) × 1.5 = 58.5 ≤ 59, the phone row, so it never overflows.
const double _maxTextScale = 1.5;

/// One screen action in a [ZodiannTopBar] (ZOD-NAV-001).
///
/// Above phone width it is a `ZodiannButton` with [icon] and [label]; at
/// phone width an icon-only `ZodiannIconButton` labelled [label] for screen
/// readers. A null [onPressed] shows it disabled.
final class ZodiannTopBarAction {
  const ZodiannTopBarAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.variant = ZodiannButtonVariant.secondary,
  });

  /// The action's icon (16 px in the button, 20 px as an icon button).
  final ZodiannIconData icon;

  /// The visible label, and the accessible name at phone width.
  final String label;

  /// Called on activation. Null disables the action.
  final VoidCallback? onPressed;

  /// The button variant above phone width.
  final ZodiannButtonVariant variant;
}

/// The sticky top bar every screen sits under (MASTER §5, NAV-1;
/// ZOD-NAV-001), independent of routing: the app shell supplies the screen's
/// [title], [subtitle] and [actions].
///
/// - 64 high (60 at phone width), including a 1 px `line-soft` bottom rule;
///   translucent `bg` (88 %) over a 10 px backdrop blur; it covers the
///   status-bar inset and sets the status-bar icon brightness.
/// - From the start side: a 46 × 46 hamburger ([menuLabel],
///   [onMenuPressed]), the title (18/600) over the subtitle (12/400,
///   `text-2`; MASTER §3 lists 500 for subtitles, but kit.css and the mockups
///   draw 400), then the actions. Everything uses logical layout, so the bar
///   mirrors in Hebrew.
/// - Place it as a `Scaffold` app bar sized with [heightFor]; with
///   `extendBodyBehindAppBar` the content scrolls beneath it.
class ZodiannTopBar extends StatelessWidget implements PreferredSizeWidget {
  const ZodiannTopBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.menuLabel,
    required this.onMenuPressed,
    this.actions = const [],
  });

  /// The screen title.
  final String title;

  /// The screen subtitle.
  final String subtitle;

  /// The hamburger's accessible name.
  final String menuLabel;

  /// Called by the hamburger. Null disables it.
  final VoidCallback? onMenuPressed;

  /// The screen's actions, in order from the start side.
  final List<ZodiannTopBarAction> actions;

  /// The bar's height (excluding any status-bar inset) at [width]:
  /// [ZodiannSize.topBarPhone] at phone width, else [ZodiannSize.topBar].
  static double heightFor(double width) =>
      ZodiannBreakpoint.forWidth(width) == ZodiannBreakpoint.phone
      ? ZodiannSize.topBarPhone
      : ZodiannSize.topBar;

  /// Nominal (the regular height); the shell sizes the bar with [heightFor],
  /// and a `Scaffold` lays its app bar out at the bar's actual height.
  @override
  Size get preferredSize => const Size.fromHeight(ZodiannSize.topBar);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.extension<ZodiannSurfaces>()!;
    final styles = theme.extension<ZodiannTextStyles>()!;
    final width = MediaQuery.sizeOf(context).width;
    final phone = ZodiannBreakpoint.forWidth(width) == ZodiannBreakpoint.phone;
    final top = MediaQuery.paddingOf(context).top;

    final titles = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: styles.screenTitle,
          ),
        ),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: styles.label.copyWith(
            fontWeight: FontWeight.w400,
            color: s.text2,
          ),
        ),
      ],
    );

    final actionWidgets = [
      for (final action in actions)
        phone
            ? ZodiannIconButton(
                icon: ZodiannIcon(action.icon),
                semanticLabel: action.label,
                onPressed: action.onPressed,
              )
            : ZodiannButton(
                label: action.label,
                variant: action.variant,
                icon: ZodiannIcon(action.icon),
                onPressed: action.onPressed,
              ),
    ];

    final endPadding = phone
        ? (actions.isEmpty ? ZodiannSpace.s4 : ZodiannSpace.s2)
        : ZodiannSpace.s6;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value:
          (theme.brightness == Brightness.light
                  ? SystemUiOverlayStyle.dark
                  : SystemUiOverlayStyle.light)
              .copyWith(statusBarColor: ZodiannStates.transparent),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
          // Border-box, as kit.css: Container adds the 1 px bottom border to
          // its padding, so the row gets heightFor(width) − 1.
          child: Container(
            height: top + heightFor(width),
            decoration: BoxDecoration(
              color: s.bg.withValues(alpha: _backdropAlpha),
              border: Border(bottom: BorderSide(color: s.lineSoft)),
            ),
            padding: EdgeInsetsDirectional.only(
              top: top,
              start: phone ? ZodiannSpace.s1 : ZodiannSpace.s3,
              end: endPadding,
            ),
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: _maxTextScale,
              // Side insets (a landscape notch) keep the controls clear; the
              // background above stays full-bleed. The top inset is the
              // Container's padding.
              child: SafeArea(
                top: false,
                bottom: false,
                child: Row(
                  children: [
                    ZodiannIconButton(
                      icon: const ZodiannIcon(ZodiannIcons.menu),
                      semanticLabel: menuLabel,
                      onPressed: onMenuPressed,
                    ),
                    const SizedBox(width: ZodiannSpace.s3),
                    Expanded(child: titles),
                    if (actionWidgets.isNotEmpty) ...[
                      const SizedBox(width: ZodiannSpace.s3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: ZodiannSpace.s2,
                        children: actionWidgets,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
