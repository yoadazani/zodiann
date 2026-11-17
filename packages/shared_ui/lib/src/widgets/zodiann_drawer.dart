import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../icons/zodiann_icon.dart';
import '../icons/zodiann_icon_data.dart';
import '../icons/zodiann_icons.g.dart';
import '../theme/tokens/zodiann_dimensions.dart';
import '../theme/zodiann_elevation.dart';
import '../theme/zodiann_surfaces.dart';
import '../theme/zodiann_text_styles.dart';
import 'zodiann_icon_button.dart';
import 'zodiann_logo.dart';
import 'zodiann_pressable.dart';

/// The header's text follows the system text size up to 1.5 ×, as the top
/// bar's does: 20 × 1.45 × 1.5 = 43.5 fits the header's 51 px row (76 less
/// 24 of padding and the 1 px rule), so it never overflows. The list and
/// the footer scale freely.
const double _maxHeaderTextScale = 1.5;

/// One entry in a [ZodiannDrawerGroup] (ZOD-NAV-002): a screen's icon, name,
/// description and whether it is the active one.
///
/// Route-independent data: the app maps its routes to items.
final class ZodiannDrawerItem {
  const ZodiannDrawerItem({
    required this.icon,
    required this.name,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  /// The item's icon (20 px, in the first column).
  final ZodiannIconData icon;

  /// The item's name (14/500) and accessible name.
  final String name;

  /// The short description (12, `text-2`) and accessible hint.
  final String description;

  /// Whether this is the active item: `accent-soft` fill, a 3 px `accent`
  /// bar on the start edge, `accent-strong` icon and name, and the
  /// accessibility "selected" state (NAV-3).
  final bool selected;

  /// Called when the item is activated.
  final VoidCallback onTap;
}

/// A labelled group of drawer items (D17: "Analysis", "Library and app").
final class ZodiannDrawerGroup {
  const ZodiannDrawerGroup({required this.label, required this.items});

  /// The group's label (12, `text-3`).
  final String label;

  /// The group's items, in order.
  final List<ZodiannDrawerItem> items;
}

/// The navigation drawer's panel (MASTER §5 "Drawer", NAV-2 / NAV-3;
/// ZOD-NAV-002), independent of routing and of the app version: the caller
/// supplies the groups and finished strings. Show it with
/// `showZodiannDrawer`, which owns the route, the scrim, the motion and the
/// swipe.
///
/// - Width `min(320, 86 %)` of the screen ([widthFor]), full height,
///   `surface`, a 1 px inner-edge `line`, the floating shadow and its outside
///   outline ring. The 1 px border is inside the width.
/// - Header 76 high (1 px `line-soft` rule): the logo (40), the [wordmark]
///   (20/600) and a close button at the end.
/// - A scrolling list, then the footer pinned to the bottom.
/// - Directional throughout, so it mirrors in Hebrew. It covers the status-bar
///   and bottom insets with its background while its content stays inside
///   them.
///
/// Items sit 2 px apart, so a focus ring (4 px outside the box) of one item
/// overlaps its neighbour's edge; accepted as the design draws it.
class ZodiannDrawer extends StatelessWidget {
  const ZodiannDrawer({
    super.key,
    required this.wordmark,
    required this.groups,
    required this.closeLabel,
    required this.onClose,
    required this.versionLabel,
    required this.offlineLabel,
  });

  /// The header's wordmark text ("Zodiann").
  final String wordmark;

  /// The item groups, in order.
  final List<ZodiannDrawerGroup> groups;

  /// The close button's accessible name.
  final String closeLabel;

  /// Called by the close button.
  final VoidCallback onClose;

  /// The footer's version line, finished ("Version 1.0.0"); the drawer owns
  /// no version.
  final String versionLabel;

  /// The footer's second line ("All data stays on this device").
  final String offlineLabel;

  /// The panel's width on a screen [screenWidth] wide:
  /// `min(drawerMaxWidth, drawerWidthFactor × screenWidth)`.
  static double widthFor(double screenWidth) => math.min(
    ZodiannSize.drawerMaxWidth,
    ZodiannSize.drawerWidthFactor * screenWidth,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.extension<ZodiannSurfaces>()!;
    final e = theme.extension<ZodiannElevation>()!;
    final styles = theme.extension<ZodiannTextStyles>()!;
    final pad = MediaQuery.paddingOf(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // The side inset on the start edge (a notch); the end side never reaches
    // an edge of the screen.
    final startInset = rtl ? pad.right : pad.left;
    final border = e.floatingOutline.width;

    final header = Container(
      height: pad.top + ZodiannSize.drawerHead,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: s.lineSoft)),
      ),
      padding: EdgeInsetsDirectional.only(
        top: pad.top + ZodiannSpace.s3,
        bottom: ZodiannSpace.s3,
        start: ZodiannSpace.s5 + startInset,
        end: ZodiannSpace.s3,
      ),
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: _maxHeaderTextScale,
        child: Row(
          children: [
            const ZodiannLogo(size: ZodiannSize.logoDrawer),
            const SizedBox(width: ZodiannSpace.s3),
            Expanded(
              child: Text(
                wordmark,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: styles.drawerWordmark,
              ),
            ),
            ZodiannIconButton(
              icon: const ZodiannIcon(ZodiannIcons.x),
              semanticLabel: closeLabel,
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );

    final children = <Widget>[
      for (var g = 0; g < groups.length; g++) ...[
        Padding(
          padding: EdgeInsetsDirectional.only(
            start: ZodiannSpace.s3,
            end: ZodiannSpace.s3,
            top: g == 0 ? ZodiannSpace.s2 : ZodiannSpace.s4,
            bottom: ZodiannSpace.s2,
          ),
          child: Text(
            groups[g].label,
            style: styles.label.copyWith(
              fontWeight: FontWeight.w400,
              color: s.text3,
            ),
          ),
        ),
        for (final item in groups[g].items) _DrawerItem(item: item),
      ],
    ];

    final list = SingleChildScrollView(
      padding: EdgeInsetsDirectional.only(
        top: ZodiannSpace.s3,
        bottom: ZodiannSpace.s3,
        start: ZodiannSpace.s3 + startInset,
        end: ZodiannSpace.s3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: ZodiannSize.navItemGap,
        children: children,
      ),
    );

    final footerStyle = styles.label.copyWith(
      fontWeight: FontWeight.w400,
      color: s.text3,
    );
    final footer = Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: s.lineSoft)),
      ),
      padding: EdgeInsetsDirectional.only(
        top: ZodiannSpace.s4,
        bottom: ZodiannSpace.s4 + pad.bottom,
        start: ZodiannSpace.s5 + startInset,
        end: ZodiannSpace.s5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: ZodiannSize.navItemGap,
        children: [
          Text(versionLabel, style: footerStyle),
          Text(offlineLabel, style: footerStyle),
        ],
      ),
    );

    return Material(
      type: MaterialType.transparency,
      child: SizedBox(
        width: widthFor(MediaQuery.sizeOf(context).width),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: s.surface,
            border: BorderDirectional(
              end: BorderSide(color: s.line, width: border),
            ),
            // The outline ring first, under the shadow (Flutter paints later
            // shadows on top; the reference's ring column sits under it).
            boxShadow: [
              BoxShadow(
                color: e.floatingOutline.color,
                spreadRadius: e.floatingOutline.width,
              ),
              ...e.floating,
            ],
          ),
          child: Padding(
            // The border is inside the width: the content box is width − 1.
            padding: EdgeInsetsDirectional.only(end: border),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                Expanded(child: list),
                footer,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({required this.item});

  final ZodiannDrawerItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.extension<ZodiannSurfaces>()!;
    final styles = theme.extension<ZodiannTextStyles>()!;
    final selected = item.selected;
    return ZodiannPressable(
      onPressed: item.onTap,
      semanticLabel: item.name,
      semanticHint: item.description,
      selected: selected,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? s.accentSoft : null,
          borderRadius: ZodiannRadius.control,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(ZodiannSpace.s3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: ZodiannSize.navIconColumn,
                    child: Align(
                      alignment: AlignmentDirectional.topStart,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: ZodiannSize.navIconNudge,
                        ),
                        child: IconTheme(
                          data: IconThemeData(
                            size: ZodiannSize.icon,
                            color: selected ? s.accentStrong : s.text2,
                          ),
                          child: ZodiannIcon(item.icon),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: ZodiannSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      spacing: ZodiannSize.navItemGap,
                      children: [
                        Text(
                          item.name,
                          style: styles.body.copyWith(
                            fontWeight: FontWeight.w500,
                            color: selected ? s.accentStrong : s.text,
                          ),
                        ),
                        Text(
                          item.description,
                          style: styles.label.copyWith(
                            fontWeight: FontWeight.w400,
                            color: s.text2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              PositionedDirectional(
                start: 0,
                top: ZodiannSize.navActiveBarInset,
                bottom: ZodiannSize.navActiveBarInset,
                width: ZodiannSize.navActiveBar,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: s.accent,
                    borderRadius: BorderRadius.circular(ZodiannRadius.xs),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
