import 'package:material_ui/material_ui.dart';

// MASTER.md §4 (spacing, radius, controls, icons) and §6 (breakpoints):
// theme-independent layout constants (ZOD-UI-003). All values are logical
// pixels (ARCH-8).
//
// This directory is the only place layout literals are allowed (ARCH-7);
// feature code reads these names instead (guarded by
// test/architecture/no_magic_dimensions_test.dart).

/// The 4-based spacing scale (MASTER §4).
abstract final class ZodiannSpace {
  /// 4.
  static const double s1 = 4.0;

  /// 8.
  static const double s2 = 8.0;

  /// 12.
  static const double s3 = 12.0;

  /// 16. Also the phone gutter, panel gap and panel padding.
  static const double s4 = 16.0;

  /// 20. Also the panel gap and panel padding above phone width.
  static const double s5 = 20.0;

  /// 24. Also the gutter above phone width.
  static const double s6 = 24.0;

  /// 32.
  static const double s8 = 32.0;

  /// 40.
  static const double s10 = 40.0;

  /// 48.
  static const double s12 = 48.0;

  /// The whole scale, smallest first.
  static const List<double> scale = [s1, s2, s3, s4, s5, s6, s8, s10, s12];
}

/// The radius scale and its semantic uses (MASTER §4).
///
/// Square cells themselves have no radius (`BorderRadius.zero`); only their
/// outer frame is rounded ([cellFrame]).
abstract final class ZodiannRadius {
  /// 3.
  static const double xs = 3.0;

  /// 6.
  static const double sm = 6.0;

  /// 8.
  static const double md = 8.0;

  /// 12.
  static const double lg = 12.0;

  /// 16.
  static const double xl = 16.0;

  /// Fully rounded ends (CSS `999px`).
  static const double pill = 999.0;

  /// The square cells' outer frame (MASTER §4).
  static const BorderRadius cellFrame = BorderRadius.all(Radius.circular(xs));

  /// Legend swatches (MASTER §4).
  static const BorderRadius legendSwatch = BorderRadius.all(
    Radius.circular(xs),
  );

  /// Tags (MASTER §4).
  static const BorderRadius tag = BorderRadius.all(Radius.circular(sm));

  /// Segmented-control thumbs (MASTER §4).
  static const BorderRadius segmentThumb = BorderRadius.all(
    Radius.circular(sm),
  );

  /// Buttons and inputs (MASTER §4).
  static const BorderRadius control = BorderRadius.all(Radius.circular(md));

  /// Panels (MASTER §4).
  static const BorderRadius panel = BorderRadius.all(Radius.circular(lg));

  /// Dialogs (MASTER §4).
  static const BorderRadius dialog = BorderRadius.all(Radius.circular(xl));

  /// Chips (MASTER §4).
  static const BorderRadius chip = BorderRadius.all(Radius.circular(pill));
}

/// Control, row and icon sizes (MASTER §4).
abstract final class ZodiannSize {
  /// Buttons and inputs: height.
  static const double control = 40.0;

  /// Small buttons and inputs: height.
  static const double controlSmall = 32.0;

  /// Segmented-control thumb: height.
  static const double segmentThumb = 32.0;

  /// Segmented control: the gap between neighbouring segments (kit.css
  /// `.seg` `gap: 2px`).
  static const double segmentGap = 2.0;

  /// Segmented control: the gap between a segment's icon and its label
  /// (kit.css `.seg > span` `gap: 6px`).
  static const double segmentIconGap = 6.0;

  /// Segmented-control track: inset around the thumbs.
  static const double segmentTrackInset = 3.0;

  /// Table rows: height.
  static const double tableRow = 44.0;

  /// Table header: block padding above and below the label (kit.css
  /// `.tbl th` `padding: 10px var(--s4)`).
  static const double tableHeaderPadding = 10.0;

  /// Compact table density: inline padding of every cell and header label
  /// (wheel.html's `padding-inline: 10px` below 1100 px; regular is
  /// [ZodiannSpace.s4]).
  static const double tableCompactPadding = 10.0;

  /// The selected table row's accent bar on the start edge (kit.css
  /// `.tbl tr.on td:first-child`, an inset 3 px shadow).
  static const double tableSelectedBar = 3.0;

  /// Hamburger and icon buttons: width and height (the tap target).
  static const double iconButton = 46.0;

  /// Small icon buttons: width and height.
  static const double iconButtonSmall = 36.0;

  /// Play button: circle diameter.
  static const double playButton = 48.0;

  /// Switch: width.
  static const double switchWidth = 40.0;

  /// Switch: height.
  static const double switchHeight = 24.0;

  /// Switch: the thumb's diameter (kit.css `.switch::after`).
  static const double switchThumb = 16.0;

  /// Switch: the thumb's inset from the inside of the 1 px border (kit.css
  /// `.switch::after` `top: 3px`; the off thumb sits 3 px from the start).
  static const double switchThumbInset = 3.0;

  /// Orb stepper: height.
  static const double stepper = 36.0;

  /// Orb stepper: the width of each − and + button (kit.css
  /// `.stepper button`).
  static const double stepperButtonWidth = 34.0;

  /// Orb stepper: the least width of the value between the buttons (kit.css
  /// `.stepper .v`).
  static const double stepperValueMinWidth = 52.0;

  /// Body chip: height (kit.css `.chk`).
  static const double bodyChipHeight = 34.0;

  /// Body chip: padding on the start side, next to the glyph (kit.css `.chk`
  /// `padding-inline: 10px 12px`).
  static const double bodyChipPaddingStart = 10.0;

  /// Body chip: padding on the end side, after the label.
  static const double bodyChipPaddingEnd = 12.0;

  /// Body chip: the gap between the glyph and the label (kit.css `.chk`).
  static const double bodyChipGap = 8.0;

  /// Body chip: the glyph's font size (kit.css `.chk .glyph`).
  static const double bodyChipGlyph = 15.0;

  /// The 1 px rule of borders and head rules (MASTER §1, §4).
  static const double hairline = 1.0;

  /// Field: gap from the label to the input, and from the input to its
  /// error message, and inside the message row (kit.css `.field` gap 6).
  static const double fieldGap = 6.0;

  /// Field: the width of the focus and error halo painted outside the
  /// border (kit.css `0 0 0 3px`; MASTER §10).
  static const double fieldHalo = 3.0;

  /// Panel head: height above phone width, including its 1 px bottom rule.
  static const double panelHead = 56.0;

  /// Panel head: height at phone width, including its 1 px bottom rule.
  static const double panelHeadPhone = 52.0;

  /// Top bar: height above phone width, including its 1 px bottom rule
  /// (MASTER §5; kit.css `--topbar-h`).
  static const double topBar = 64.0;

  /// Top bar: height at phone width, including its 1 px bottom rule
  /// (MASTER §5).
  static const double topBarPhone = 60.0;

  /// Minimum touch target (MASTER §14), in both axes.
  static const double minTouchTarget = 44.0;

  /// Icons in controls.
  static const double icon = 20.0;

  /// Icons in small buttons and fields.
  static const double iconSmall = 16.0;

  /// The logo is never rendered smaller than this: its hairlines blur at
  /// small raster sizes (MASTER §11).
  static const double logoMin = 40.0;

  /// The logo in the drawer header (MASTER §5).
  static const double logoDrawer = 40.0;

  /// The logo in the About hero (MASTER §9).
  static const double logoAbout = 132.0;

  /// Tags: height (MASTER §10 "Tags", kit.css `.tag`).
  static const double tag = 24.0;

  /// Tags: the gap between the mark and the label (kit.css `.tag`).
  static const double tagGap = 6.0;

  /// Tags: the inset outline of the today and centre tags (kit.css
  /// `box-shadow: inset 0 0 0 1.5px`).
  static const double tagOutline = 1.5;

  /// The drawer's maximum width (MASTER §5; kit.css `.drawer`
  /// `width: min(320px, 86vw)`).
  static const double drawerMaxWidth = 320.0;

  /// The drawer's width as a share of the screen's, below which it is
  /// narrower than [drawerMaxWidth] (86 %).
  static const double drawerWidthFactor = 0.86;

  /// The drawer header's height, including its 1 px bottom rule (MASTER §5;
  /// kit.css `.drawer-head`).
  static const double drawerHead = 76.0;

  /// The dialog's width (MASTER §10; kit.css `.dialog`): never wider than the
  /// screen less 2 x [ZodiannSpace.s4] (`max-width: calc(100vw - 32px)`).
  static const double dialogWidth = 420.0;

  /// The drawer item's icon column (kit.css `.nav-item`
  /// `grid-template-columns: 24px 1fr`).
  static const double navIconColumn = 24.0;

  /// The drawer item's icon sits 1 px down (kit.css `.nav-item svg`
  /// `margin-top: 1px`).
  static const double navIconNudge = 1.0;

  /// The gap between the drawer list's children and between an item's name
  /// and description (kit.css `.drawer nav` and `.nav-item` `2px`).
  static const double navItemGap = 2.0;

  /// The active drawer item's bar: width (kit.css `.nav-item.on::before`).
  static const double navActiveBar = 3.0;

  /// The active drawer item's bar: inset from the item's top and bottom.
  static const double navActiveBarInset = 10.0;
}

/// The breakpoint widths (MASTER §6), in logical pixels.
///
/// These are the width constants; `ZodiannBreakpoint` is the resolved
/// layout class (phone / tablet / desktop) for a given width.
abstract final class ZodiannBreakpoints {
  /// Tablet starts here; phone is any width below it.
  static const double tablet = 700.0;

  /// Desktop starts here; tablet is any width below it.
  static const double desktop = 1100.0;

  /// The content area never grows wider than this.
  static const double contentMaxWidth = 1440.0;
}
